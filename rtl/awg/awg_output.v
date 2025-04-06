// `include "defines.v"
// `default_nettype none
// `timescale 1ns/1ps

// module awg_output # (
//     parameter BIT_WIDTH = 8
// ) (
//     input  wire         clk100,

//     input  wire         in_tvalid,
//     output reg          in_tready,
//     input  wire  [BIT_WIDTH - 1:0]  in_tdata,

//     input wire trigger,

//     output wire         awg_valid,
//     output reg clkout = 0,
//     output reg [BIT_WIDTH - 1:0]   awg_out = 0
// );

//     // Rate control
//     localparam CLK_FREQ = 100_000_000;
//     localparam OUTPUT_FREQ = 10_000_000;
//     localparam CLKOUT_RATIO = CLK_FREQ / OUTPUT_FREQ - 1;

//     reg [15:0] time_since_last_sample = 16'hFFFF;
//     assign awg_valid = time_since_last_sample <= CLKOUT_RATIO;

//     reg [8*22-1:0] awg_state_name; // Debugging

//     always @(posedge clk100) begin


//         if (time_since_last_sample >= CLKOUT_RATIO) begin
//             in_tready <= trigger;
//             if (in_tvalid && trigger) begin
//                 awg_state_name <= "RDY_SAMPLE";
//                 awg_out <= in_tdata;
//                 clkout <= 1;
//                 time_since_last_sample <= 0;
//             end else begin
//                 awg_state_name <= "RDY_NO_SAMPLE";
//                 if (time_since_last_sample < 16'hFFFF) begin
//                     time_since_last_sample <= time_since_last_sample + 1;
//                 end
//             end
//         end else begin
//             if (time_since_last_sample < 16'hFFFF) begin
//                 time_since_last_sample <= time_since_last_sample + 1;
//             end
//             if (time_since_last_sample >= CLKOUT_RATIO / 2) begin
//                 clkout <= 0;
//             end

//             awg_state_name <= "NO_SAMPLE";
//             in_tready <= 0;
//         end
//     end

// endmodule  


`include "defines.v"
`default_nettype none
`timescale 1ns/1ps

module awg_output # (
    parameter BIT_WIDTH = 8
) (
    input  wire         clk100,

    input  wire         in_tvalid,
    output reg          in_tready,
    input  wire  [BIT_WIDTH - 1:0]  in_tdata,

    input wire trigger,

    output wire         awg_valid,
    output reg clkout = 0,
    output reg [BIT_WIDTH - 1:0]   awg_out = 0
);

    // Rate control
    localparam CLK_FREQ = 100_000_000;
    localparam OUTPUT_FREQ = 10_000_000;
    localparam CLKOUT_RATIO = CLK_FREQ / OUTPUT_FREQ - 1;

    reg [15:0] time_since_last_sample = 16'hFFFF;
    assign awg_valid = time_since_last_sample <= CLKOUT_RATIO;

    reg [8*22-1:0] awg_state_name; // Debugging

    always @(posedge clk100) begin


        if (time_since_last_sample >= CLKOUT_RATIO) begin
            in_tready <= trigger;
            if (in_tvalid && trigger) begin
                awg_state_name <= "RDY_SAMPLE";
                awg_out <= in_tdata;
                // clkout <= 1;
                time_since_last_sample <= 0;
            end else begin
                awg_state_name <= "RDY_NO_SAMPLE";
                if (time_since_last_sample < 16'hFFFF) begin
                    time_since_last_sample <= time_since_last_sample + 1;
                end
            end
        end else begin
            if (time_since_last_sample < 16'hFFFF) begin
                time_since_last_sample <= time_since_last_sample + 1;
            end
            // if (time_since_last_sample >= CLKOUT_RATIO / 2) begin
            if (time_since_last_sample == CLKOUT_RATIO / 4) begin
                // clkout <= 0;
                clkout <= 1;
            end
            if (time_since_last_sample == 3 * CLKOUT_RATIO / 4) begin
                clkout <= 0;
            end

            awg_state_name <= "NO_SAMPLE";
            in_tready <= 0;
        end
    end

endmodule  