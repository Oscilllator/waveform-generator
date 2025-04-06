`default_nettype none
`timescale 1ns/1ps
`include "defines.v"

module state_machine # (
    parameter BW_OUT = 8,
    // Not guaranteed to work for other values of BW_IN
    parameter BW_IN = 8
) (
    input  wire         clk100,

    input  wire         in_tvalid,
    output reg          in_tready = 1,
    input  wire  [BW_IN -  1:0]  in_tdata,

    output reg         awg_valid = 0,
    input wire         awg_ready,
    output reg [BW_OUT -  1:0]   awg_out,

    output reg [6:0] trigger_mode,
    output reg err_latched = 0,

    output wire [7:0] dbg
);
    localparam BPB = BW_IN - 1; // AWG bits per byte

    wire [BW_OUT - 2:0] wire_payload = in_tdata[BW_IN - 2:0]; // Debugging
    wire cmd_bit = in_tdata[BW_IN -  1]; // Debugging

    reg [BW_OUT -  1:0] new_bits_in_sample = 0;
    reg [BW_OUT -  1:0] awg_partial = 0;
    reg [7:0] bits_in_sample = 0;
    `ifdef TESTBENCH reg [8*22-1:0] state_name; `endif


    reg [7:0] state = 0;
    assign dbg = state;
    // assign dbg = bits_in_sample;

    always @(posedge clk100) begin


        // Putting the awg sample out in this if/else chain here means that we don't need to reason
        // about simultaneously reading and writing to awg_out, but slows us down by one cycle.
        if (awg_ready && awg_valid) begin
            `ifdef TESTBENCH state_name <= "SHIPPED"; `endif
            awg_valid <= 0;
            in_tready <= 1;

        // New commands should not be read whilst awg_valid is high because they could terminate an already
        // pending waveform sample.
        end else if (in_tvalid && !awg_valid) begin
            if (in_tdata[`CMD_BIT] == 1) begin
                in_tready <= 1;

                if (wire_payload[`TRIGGER_CMD_BIT]) begin
                    state <= 8'b1000_0001;
                    trigger_mode <= wire_payload;
                    `ifdef TESTBENCH state_name <= "CMD_TRIG"; `endif

                    // This is only needed for catching errors: TODO: move check to trigger block.
                    if (   (wire_payload != `TRIGGER_MODE_NONE)
                        && (wire_payload != `TRIGGER_MODE_EDGE)
                        && (wire_payload != `RESET_EDGE)) begin
                        state <= 8'b0000_0011;
                        err_latched <= 1;
                    end

                end else if (wire_payload[`STATE_CMD_BIT]) begin
                    `ifdef TESTBENCH state_name <= "CMD_RST"; `endif
                    bits_in_sample <= 0;
                    awg_partial <= 0;

                    if (wire_payload != `RESET_TRANSMISSION) begin
                        state <= 8'b0000_0111;
                        err_latched <= 1;
                    end else begin state <= 8'b0000_1111; end
                end else begin
                    err_latched <= 1;
                    state <= 8'b0001_1111;
                    `ifdef TESTBENCH $error("Unknown trigger mode: %b", wire_payload); `endif
                end

            end else begin

                    if  (!awg_valid && (bits_in_sample + 7 >= BW_OUT)) begin
                        state <= 8'b0011_1111;

                        `ifdef TESTBENCH state_name <= "GOT NEW SAMPLE"; `endif
                        awg_out <= awg_partial | (in_tdata >> (BW_IN - BW_OUT + bits_in_sample - 1));
                        new_bits_in_sample = (bits_in_sample + BPB) % BW_OUT;
                        awg_partial <= in_tdata << (BW_OUT - new_bits_in_sample);
                        bits_in_sample <= new_bits_in_sample;

                        awg_valid <= 1;
                        in_tready <= 0;
                        if (!in_tready) begin
                            `ifdef TESTBENCH $error("new: in_tready should be high when we have a partial sample"); `endif
                            err_latched <= 1;
                        end
                    end else if (~awg_valid || (awg_valid && (bits_in_sample < (BW_OUT - 2 * BPB)))) begin
                        state <= 8'b0111_1111;
                        `ifdef TESTBENCH state_name <= "PARTIAL SAMPLE"; `endif
                        in_tready <= 1;
                        awg_partial <= awg_partial | (in_tdata << (BW_OUT - BPB - bits_in_sample));
                        bits_in_sample <= bits_in_sample + BPB;
                    end else begin
                        state <= 8'b1111_1111;
                        `ifdef TESTBENCH state_name <= "WAITING"; `endif
                        in_tready <= 0;
                    end

                end

            end
    end

endmodule
