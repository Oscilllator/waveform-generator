import os
import sys
import time
import signal
import numpy as np
import wire_format
from ctypes import CDLL

import verilog_consts as vc
import libawg
print(vc.TRIGGER_CMD_BIT)

# def setup_environment():
#     script_dir = os.path.dirname(os.path.abspath(__file__))
#     lib_dir = os.path.join(script_dir, "release", "build")
#     os.environ['LD_LIBRARY_PATH'] = lib_dir + ":" + os.environ.get('LD_LIBRARY_PATH', '')
#     sys.path.append(lib_dir)
    
#     try:
#         CDLL(os.path.join(lib_dir, "libftd2xx.so"))
#     except OSError as e:
#         print(f"Error loading libftd2xx.so: {e}")
#         sys.exit(1)

def signal_handler(signum, frame):
    print("Received interrupt, terminating...")
    sys.exit(0)

def main():
    # setup_environment()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # awg = libawg.awg(transmit_size=int(0))
    awg = libawg.awg()
    # samples = np.frombuffer(bytes([0xFF]) * 100 + bytes([0x00]) * 100, dtype=np.uint8)
    # samples = np.tile(np.array([0xFFFF, 0x00], dtype=np.uint16), 10000).astype(np.uint16)
    # offset = 2**13
    # amplitude =  2**10  #2**13 - 1
    # amplitude =  int(10e4 // 2)
    # samples = offset - amplitude // 2 + np.arange(amplitude, dtype=np.uint16)
    # samples = np.zeros(int(10e5 // 2)) + 2**14 - 1
    # samples[0::2] = 0
    # samples = samples.astype(np.uint16)
    # import matplotlib.pyplot as plt; plt.plot(samples); plt.show()
    # samples = np.tile(samples, 10)


    # bytes_ = wire_format.samples_to_wire_format(samples, vc.TRIGGER_MODE_NONE)
    # bytes_ = bytes_ * 10

    # samples = np.tile(samples, 1000)
    # print(samples.tolist())
    # samples = samples.repeat(100)
    # samples = np.array([-1])

    theta = np.linspace(0, 2 * np.pi, 1000)
    samples = np.sin(theta)
    # samples = np.repeat(np.array([-1, 1]), 1)
    # samples = np.linspace(-10, 10, 100000)
    d0 = samples > 0.8
    d1 = samples < -0.5

    last_time = time.time()
    while True:
        # start = time.time()
        print("sending")
        awg.send_volts(samples, digital=[d0, d1], trigger_mode=vc.TRIGGER_MODE_NONE, continuous=True)
        time.sleep(30000)
        # awg.stop()
        # time.sleep(3)
        # result = awg.send_lsbs(samples, trigger_mode=vc.TRIGGER_MODE_NONE)
        # print("sending bytes")
        # result = awg.send_bytes(bytes_)
        # print("done sending bytes")
        # stop = time.time()

        # if time.time() - last_time > 1:
        #     dt = stop - start
        #     mbps = 1e-6 * result / dt
        #     # print(f"write took {dt:.5f}s, {mbps:.5f} MB/s | {(1e-6*samples.size / dt):.5f} MS/s")
        #     print(f"write took {dt:.5f}s, {mbps:.5f} MB/s ")
        #     last_time = time.time()

if __name__ == "__main__":
    main()
