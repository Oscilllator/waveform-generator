`ifndef TEST_DATA_GENERATION_V
`define TEST_DATA_GENERATION_V

`default_nettype none
`include "defines.v"
`timescale 1ns/1ps

module generate_alternating_test_vector;
    parameter BW = 8;
    parameter PAYLOAD_LEN = 0;  // Must provide

    
    // Actual command stream being sent to the fpga.
    reg [BW - 1:0] byte_stream [0:PAYLOAD_LEN - 1];
    // Ground truth of the awg samples intended to be sent.
    reg [BW - 1:0] awg_stream [0:PAYLOAD_LEN - 1];
    
    // Internal variables for generation
    integer bit_idx;
    integer data_byte_idx;
    // integer awg_byte_idx;
    reg [BW - 1:0] awg_byte_idx;
    
    initial begin
        for (awg_byte_idx = 0; awg_byte_idx < PAYLOAD_LEN; awg_byte_idx = awg_byte_idx + 1) begin
            awg_stream[awg_byte_idx] = (awg_byte_idx % 2 == 0) ? 16'hFFFF : 16'h0000;
            // awg_stream[awg_byte_idx] = (awg_byte_idx % 2 == 0) ? awg_byte_idx : 8'h00;
            // awg_stream[awg_byte_idx] = 8'h10 + awg_byte_idx;
        end


        byte_stream[0] = `TRIGGER_MODE_NONE | `CMD_MASK;
        
        for (bit_idx = 0; bit_idx < PAYLOAD_LEN * (BW - 1); bit_idx = bit_idx + 1) begin
            data_byte_idx = bit_idx / (BW - 1);
            byte_stream[1 + data_byte_idx][BW - 1] = 0;
            byte_stream[1 + data_byte_idx][(BW - 2) - bit_idx % (BW - 1)] = awg_stream[bit_idx / BW][BW - 1 - bit_idx % BW];
        end
        
        byte_stream[PAYLOAD_LEN - 1] = `RESET_TRANSMISSION | `CMD_MASK;
        
        // Debug output
        for (data_byte_idx = 0; data_byte_idx < PAYLOAD_LEN; data_byte_idx = data_byte_idx + 1) begin
            $display("byte_stream[%0d] = %b", data_byte_idx, byte_stream[data_byte_idx]);
        end
    end
endmodule

`endif // TEST_DATA_GENERATION_V