import os, sys, threading
import numpy as np
from ctypes import CDLL

import wire_format
import verilog_consts as vc

def setup_environment():
    lib_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    so_dir = os.path.join(lib_dir, "libftdi")
    os.environ['LD_LIBRARY_PATH'] = so_dir + ":" + os.environ.get('LD_LIBRARY_PATH', '')
    sys.path.append(so_dir)
    print(f"so_dir: {so_dir}")    
    try:
        CDLL(os.path.join(so_dir, "libftd2xx.so"))
    except OSError as e:
        print(f"Error loading libftd2xx.so: {e}")
        sys.exit(1)

class awg:
    def __init__(self, transmit_size: int = int(10e5)):
        self.transmit_size = transmit_size
        setup_environment()
        import ftd2xx
        self.vmin = -10
        self.vmax = 10
        self.sample_rate = 10e6
        print(dir(ftd2xx))
        # Set VID/PID before opening
        ftd2xx.setVIDPID(0x1337, 0x0001)
        self.usb = ftd2xx.open(0)
        self.usb.setFlowControl(0, 0, 0)
        self.usb.purge(ftd2xx.defines.PURGE_TX | ftd2xx.defines.PURGE_RX)
        BITMODE_SYNC_FIFO = 0x40
        self.usb.setBitMode(0xFF, BITMODE_SYNC_FIFO)
        self.cont_thread = None
        self.stop_event = None

    def send_volts(self,
                signal: np.ndarray,
                digital: list[np.ndarray],
                trigger_mode: int = vc.TRIGGER_MODE_NONE,
                continuous: bool = False):
        """
        Send a waveform to the awg, alongside some optional digital outputs.
        If sending just the waveform, signal_in is a 1D array
        If also sending digital signals, signal_in is a 2D array where the first dimension
        is [signal, d0, d1 (optional)].
        """
        assert signal.ndim == 1
        signal = np.clip(signal, self.vmin, self.vmax)
        signal = (signal - self.vmin) / (self.vmax - self.vmin) * (2**vc.DAC_BIT_WIDTH - 1)
        signal = signal.astype(np.uint8 if vc.BIT_WIDTH == 8 else np.uint16)

        for i, d in enumerate(digital):
            assert set(np.unique(digital)).issubset(set([0, 1]))
            signal |= (d.astype(signal.dtype) << (vc.DAC_BIT_WIDTH + i))
        return self.send_bits(signal, trigger_mode, continuous)

    def send_bits(self, signal: np.ndarray, trigger_mode: int, continuous: bool):
        """
        Send a waveform to the awg.
        Top two bits of signal are the auxillary digital outputs, bottom 14 bits are the real signal.
        To be explicit, the format is:
        msb                                               lsb
        [d1 d0 a13 a12 a11 a10 a9 a8 a7 a6 a5 a4 a3 a2 a1 a0]
        """
        assert (signal.dtype == np.uint16) and (signal.ndim == 1)
        bytes_to_send = wire_format.samples_to_wire_format(signal, trigger_mode)
        bytes_to_send = self.expand_to_transmit_size(bytes_to_send)
        if continuous:
            self.stop_event = threading.Event()
            def _worker():
                while not self.stop_event.is_set():
                    sent = self.usb.write(bytes_to_send)
                    assert sent == len(bytes_to_send), print(f"{sent=} !- {bytes_to_send=}")
            self.cont_thread = threading.Thread(target=_worker)
            self.cont_thread.daemon = True
            self.cont_thread.start()
        else:
            return self.usb.write(bytes_to_send)

    def expand_to_transmit_size(self, signal: bytes):
        expansion_factor = 1 + self.transmit_size // len(signal)
        return signal * expansion_factor

    def stop(self):
        if self.cont_thread:
            self.stop_event.set()
            self.cont_thread.join()
            self.cont_thread = None


if __name__ == "__main__":
    import matplotlib.pyplot as plt

    # Mock USB class that does nothing
    class MockUSB:
        def write(self, data):
            return 0  # do nothing, pretend write succeeds

    # Instantiate AWG and replace its USB interface with the mock
    a = awg()
    a.usb = MockUSB()

    # Test increasing waveform sizes from 10 samples to 1e6 samples
    sizes = [10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 20_000_000]
    samples_per_sec = []
    
    for s in sizes:
        # Create a random signal of size s in the range [vmin, vmax]
        signal = np.random.uniform(a.vmin, a.vmax, s)

        start_time = time.time()
        a.send(signal)
        end_time = time.time()

        duration = end_time - start_time
        samples_per_sec.append(s / duration)
        print(f"Sent {s} samples in {duration:.6f} seconds ({1e-6*s/duration:.1f} samples/s)")

    # plt.figure(figsize=(10,6))
    # plt.semilogx(sizes, samples_per_sec, 'bo-')
    # plt.grid(True)
    # plt.xlabel('Number of Samples')
    # plt.ylabel('Samples per Second')
    # plt.title('AWG Performance: Samples/s vs Signal Size')
    # plt.show()
