
import numpy as np
import verilog_consts as vc

def to_bin(data: np.ndarray):
    if data.dtype == np.uint8:
        out = [f"{byte:08b}" for byte in data.tolist()]
    elif data.dtype == np.uint16:
        out = [f"{byte:016b}" for byte in data.tolist()]
    out = "\n".join(out)
    return out

def to_bin7(data: np.ndarray):
    out = [f"{byte:08b}" for byte in data.tolist()]
    out = [o[1:] for o in out]
    out = " ".join(out)
    return out

def gen_bit_vec(bit_width, dtype):
    bit_vec = np.flip(np.left_shift(np.ones(bit_width, dtype=dtype), np.arange(bit_width, dtype=dtype)))
    bit_vec = bit_vec.reshape((1, -1))
    return bit_vec

def pack_bits(input_array):
    """
    Take an array of integers and pack them into a new byte array with the MSB cleared.
    """
    assert input_array.dtype == np.uint16 and input_array.ndim == 1
    bit_width_in = 16
    bit_width_out = 8
    bpwb = bit_width_out - 1  # bits per wire byte

    bit_vec = gen_bit_vec(bit_width_in, np.uint16).astype(np.uint16)
    # input_bits = ((bit_vec & input_array.reshape(-1, 1)) > 0).astype(np.uint16).flatten()
    input_bits = ((bit_vec & input_array.reshape(-1, 1)) > 0).flatten()
    # assert input_bits.dtype == np.uint16

    num_wire_bytes = int(np.ceil(input_bits.size / bpwb))
    num_whole_bytes = input_bits.size // bpwb
    out = np.zeros(num_wire_bytes, dtype=np.uint8)

    # You would think numpy.pack/unpack bits would work here bit it doesn't as it doesn't support
    # 16 bit integers.
    bit_vec = gen_bit_vec(bpwb, np.uint8)

    asdf = (input_bits[0:num_whole_bytes * bpwb].reshape(num_whole_bytes, bpwb) * bit_vec).sum(axis=1, dtype=np.uint8)
    out[0:num_whole_bytes] = asdf

    if num_whole_bytes != num_wire_bytes:
        remainder = input_bits[num_whole_bytes*bpwb:]
        assert remainder.size < bpwb
        remainder = (remainder * bit_vec.squeeze()[0:remainder.size]).sum(dtype=np.uint8)
        out[-1] = remainder
    return out

def unpack_bits(packed_array):
    assert packed_array.dtype == np.uint8
    bit_width = 16 
    bit_vec = gen_bit_vec(8, np.uint8)
    unpacked = ((bit_vec & packed_array.reshape(-1, 1)) > 0).astype(np.uint16)
    bits_out = unpacked[:, 1:].flatten()
    if bits_out.size % bit_width != 0:
        bits_out = bits_out[0:bits_out.size - bits_out.size % bit_width]
    bits_out = bits_out.reshape(-1, bit_width)
    bit_vec = gen_bit_vec(bit_width, np.uint16)
    out = (bits_out * bit_vec).sum(axis=1, dtype=bits_out.dtype)
    return out

def int_to_bytes(n: int, dtype: np.dtype):
    return bytes(np.array([n], dtype=dtype))

def samples_to_wire_format(samples: np.ndarray, trigger_mode: int) -> np.ndarray:
    assert samples.dtype == np.uint16
    assert trigger_mode in vc.all_triggers
    trigger_byte = trigger_mode | vc.CMD_MASK
    stop_byte = vc.RESET_TRANSMISSION | vc.CMD_MASK
    payload = pack_bits(samples)
    payload = bytes(payload)
    payload = int_to_bytes([trigger_byte], np.uint8) + payload + int_to_bytes([stop_byte], np.uint8)
    if trigger_mode == vc.TRIGGER_MODE_EDGE:
        payload += int_to_bytes([vc.CMD_MASK | vc.RESET_EDGE], np.uint8)
    return payload

def fuzz_test_pack_unpack():
    for _ in range(1000):  # Number of random tests
        size = np.random.randint(1, int(1e4))
        input_array = np.random.randint(0, 2**16, size, dtype=np.uint16)
        packed_array = pack_bits(input_array)
        unpacked_array = unpack_bits(packed_array)
        assert np.array_equal(input_array, unpacked_array)
    print("Fuzz tests passed.")

def to_wire_format_notcrash():
    commands = {k:v for k,v in vc.__dict__.items() if "TRIGGER_MODE" in k}
    # commands['RESET_EDGE'] = vc.RESET_EDGE

    for name, trigger_mode in commands.items():  # Number of random tests
        print(f"testing trigger mode: {name}: {bin(trigger_mode)}")
        # Generate random input data of random length between 1 and 100 bytes
        # input_array = np.random.randint(0, 2**vc.BIT_WIDTH, dtype=np.uint16 if vc.BIT_WIDTH == 15 else np.uint8)
        if vc.BIT_WIDTH == 8:
            input_array = np.linspace(0xF,0xFF,10).astype(np.uint8)
        else:
            input_array = np.linspace(0xFFF,0xFFFF,10).astype(np.uint16)
        size = np.random.randint(1, int(1e4))
        input_array = np.random.randint(0, 2**vc.BIT_WIDTH, size, dtype=np.uint16 if vc.BIT_WIDTH == 16 else np.uint8)
        _ = samples_to_wire_format(input_array, trigger_mode)

def benchmark():
    import matplotlib.pyplot as plt
    import  time
    # Test increasing waveform sizes from 10 samples to 1e6 samples
    sizes = [10, 100, 1_000, 10_000, 100_000, 1_000_000]
    samples_per_sec = []
    
    for s in sizes:
        # Create a random signal of size s in the range [vmin, vmax]
        signal = np.random.randint(0, 2**14 -1 , dtype=np.uint16)

        start_time = time.time()
        _ = samples_to_wire_format()
        end_time = time.time()

        duration = end_time - start_time
        samples_per_sec.append(s / duration)
        print(f"Sent {s} samples in {duration:.6f} seconds ({s/duration:.1f} samples/s)")

    plt.figure(figsize=(10,6))
    plt.semilogx(sizes, samples_per_sec, 'bo-')
    plt.grid(True)
    plt.xlabel('Number of Samples')
    plt.ylabel('Samples per Second')
    plt.title('AWG Performance: Samples/s vs Signal Size')
    plt.show()



if __name__ == "__main__":
    to_wire_format_notcrash()
    # Run the fuzzing test
    fuzz_test_pack_unpack()
    # benchmark()