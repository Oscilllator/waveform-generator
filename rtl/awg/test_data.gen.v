
`ifndef TEST_VECTOR_V
`define TEST_VECTOR_V

// DO NOT MODIFY: Generated from gen_test_data.py

`default_nettype none
`timescale 1ns/1ps



module test_vector_TRIGGER_MODE_NONE # (
   parameter NUM_TEST_SAMPLES = 5,
   parameter NUM_TEST_BYTES = 14
) ();
   reg[15:0] sample_stream[0:4];

   reg[7:0] byte_stream[0:13];
   initial begin
   
       byte_stream[00] = 8'b11000000;
       byte_stream[01] = 8'b01111111;
       byte_stream[02] = 8'b01111111;
       byte_stream[03] = 8'b01100000;
       byte_stream[04] = 8'b00000000;
       byte_stream[05] = 8'b00000111;
       byte_stream[06] = 8'b01111111;
       byte_stream[07] = 8'b01111110;
       byte_stream[08] = 8'b00000000;
       byte_stream[09] = 8'b00000000;
       byte_stream[10] = 8'b00111111;
       byte_stream[11] = 8'b01111111;
       byte_stream[12] = 8'b01110000;
       byte_stream[13] = 8'b10100000;
       sample_stream[00] = 16'b1111111111111111;
       sample_stream[01] = 16'b0000000000000000;
       sample_stream[02] = 16'b1111111111111111;
       sample_stream[03] = 16'b0000000000000000;
       sample_stream[04] = 16'b1111111111111111;

    end
endmodule



module test_vector_TRIGGER_MODE_EDGE # (
   parameter NUM_TEST_SAMPLES = 6,
   parameter NUM_TEST_BYTES = 17
) ();
   reg[15:0] sample_stream[0:5];

   reg[7:0] byte_stream[0:16];
   initial begin
   
       byte_stream[00] = 8'b11000001;
       byte_stream[01] = 8'b01111000;
       byte_stream[02] = 8'b00000011;
       byte_stream[03] = 8'b01100001;
       byte_stream[04] = 8'b01111111;
       byte_stream[05] = 8'b00000111;
       byte_stream[06] = 8'b01000000;
       byte_stream[07] = 8'b00011110;
       byte_stream[08] = 8'b00001111;
       byte_stream[09] = 8'b01111000;
       byte_stream[10] = 8'b00111100;
       byte_stream[11] = 8'b00000001;
       byte_stream[12] = 8'b01110000;
       byte_stream[13] = 8'b01111111;
       byte_stream[14] = 8'b01000000;
       byte_stream[15] = 8'b10100000;
       byte_stream[16] = 8'b11000010;
       sample_stream[00] = 16'b1111000000001111;
       sample_stream[01] = 16'b0000111111110000;
       sample_stream[02] = 16'b1111000000001111;
       sample_stream[03] = 16'b0000111111110000;
       sample_stream[04] = 16'b1111000000001111;
       sample_stream[05] = 16'b0000111111110000;

    end
endmodule


`endif // TEST_VECTOR_V
