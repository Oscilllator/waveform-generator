import numpy as np

import wire_format
import verilog_consts as vc

def emit_verilog_module(samples: np.ndarray, trigger_mode: int):
    bytes_out = wire_format.samples_to_wire_format(samples, trigger_mode)
    module = f"""

module test_vector_{vc.const_to_string(trigger_mode)} # (
   parameter NUM_TEST_SAMPLES = {len(samples)},
   parameter NUM_TEST_BYTES = {len(bytes_out)}
) ();
   reg[15:0] sample_stream[0:{len(samples)-1}];

   reg[7:0] byte_stream[0:{len(bytes_out)-1}];
   initial begin
   
"""
    for i, byte in enumerate(bytes_out):
        module += f"       byte_stream[{i:02d}] = 8'b{byte:08b};\n"
    for i, sample in enumerate(samples):
        module += f"       sample_stream[{i:02d}] = 16'b{sample:016b};\n"

    suffix = """
    end
endmodule

"""
    module += suffix
    return module

def gen_test_data():
    samples = (np.arange(1, 6) % 2).astype(np.uint16)
    samples = samples * 0xFFFF
    assert samples.dtype == np.uint16
    filename = "../rtl/awg/test_data.gen.v"
    test_none = emit_verilog_module(samples, vc.TRIGGER_MODE_NONE)

    samples = np.array([0xF00F, 0x0FF0]* 3, dtype=np.uint16)
    test_edge = emit_verilog_module(samples, vc.TRIGGER_MODE_EDGE)
    test_data = """
`ifndef TEST_VECTOR_V
`define TEST_VECTOR_V

// DO NOT MODIFY: Generated from gen_test_data.py

`default_nettype none
`timescale 1ns/1ps

""" + test_none + test_edge + """
`endif // TEST_VECTOR_V
"""

    print(test_data)
    with open(filename, "w") as f:
        f.write(test_data)

if __name__ == "__main__":
    gen_test_data()