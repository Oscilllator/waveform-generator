`default_nettype none
`timescale 1ns/1ps

module top_sans_ftdi # (
    parameter BIT_WIDTH = 8
) (
    input  wire         clk100,

    input  wire         fsm_tvalid,
    output  wire         fsm_tready,
    input  wire [7:0]   fsm_tdata,

    input wire trigger,

    output wire [BIT_WIDTH - 1:0]   awg_out,
    output wire awg_clk,
    output wire         awg_valid,

    output wire err_latched,

    // output reg [BIT_WIDTH - 1:0] logic_out,
    output wire [15:0] logic_out
);

    wire fsm_to_awg_ready;
    wire fsm_to_awg_valid;
    wire [BIT_WIDTH - 1:0] fsm_to_awg_data;
    wire [6:0] trigger_mode;
    wire [7:0] fsm_dbg;

    state_machine #(
        .BW_OUT(BIT_WIDTH),
        .BW_IN(8)
    ) fsm_inst (
        .clk100         ( clk100         ),
        .in_tvalid      ( fsm_tvalid     ),
        .in_tready      ( fsm_tready     ),
        .in_tdata       ( fsm_tdata      ),
        .awg_valid      ( fsm_to_awg_valid ),
        .awg_ready      ( fsm_to_awg_ready ),
        .awg_out        ( fsm_to_awg_data ),
        .trigger_mode   ( trigger_mode   ),
        .err_latched    ( err_latched    ),
        .dbg            ( fsm_dbg        )
    );

    wire trig_out;

    // Instantiate awg Interface
    awg_output #(
        .BIT_WIDTH(BIT_WIDTH)
    ) awg_inst (
        .clk100         ( clk100         ),
        .in_tvalid      ( fsm_to_awg_valid ),
        .in_tready      ( fsm_to_awg_ready ),
        .in_tdata       ( fsm_to_awg_data  ),
        .trigger        ( trig_out       ),
        .awg_valid      ( awg_valid      ),
        .clkout         ( awg_clk        ),
        .awg_out        ( awg_out        )
    );

    wire [7:0] trigger_mode_dbg;
    trigger_mode trigger_inst (
        .clk100     ( clk100 ),
        .cmd        ( trigger_mode ),
        .trig_in    ( trigger ),
        .trig_out   ( trig_out),
        .debug  ( trigger_mode_dbg )
    );
    // assign logic_out = 16'hffff;

    // assign logic_out[8] = fsm_tvalid;
    // assign logic_out[9] = fsm_tready;
    // assign logic_out[10] = fsm_to_awg_valid;
    // assign logic_out[11] = fsm_to_awg_ready;
    // assign logic_out[12] = fsm_to_awg_data[0];
    // assign logic_out[13] = trig_out;
    // assign logic_out[14] = trigger_mode_dbg[2];
    // assign logic_out[15] = trigger_mode_dbg[1];

    // assign logic_out[7] = trigger;
    // assign logic_out[6] = trig_out;
    assign logic_out[7:0] = trigger_mode_dbg;
    // assign logic_out[2:0] = 2'b11;
    // assign logic_out[7:0] = fsm_dbg;


endmodule

module trigger_mode (

    input wire clk100,
    input wire[6:0] cmd,
    input wire trig_in,
    output reg trig_out = 1'b1,
    output wire [7:0] debug
);
    `ifdef TESTBENCH reg [8*22-1:0] state_name = "INIT"; `endif

    localparam [2:0] UNTRIGGERABLE = 3'b100;
    localparam [2:0] TRIGGERED = 3'b110;
    localparam [2:0] EDGE_IDLE = 3'b001;
    localparam [2:0] EDGE_TRIGD = 3'b010;
    localparam [2:0] GATED = 3'b011;
    reg [2:0] state = TRIGGERED;


    reg trig_latched = 1'b1;
    reg trig_in_del = 1'b0;
    // assign trig_edge = trig_in & ~trig_in_del;
    reg trig_edge = 1'b0;

    assign debug[2:0] = state;
    assign debug[3] = trig_in;
    assign debug[4] = trig_in_del;
    assign debug[5] = trig_edge;
    assign debug[6] = clk100;


    always @(posedge clk100) begin
        trig_latched <= trig_in;
        trig_edge <= trig_latched & ~trig_in_del;
        trig_in_del <= trig_latched;

        if (cmd == `TRIGGER_MODE_NONE) begin
            `ifdef TESTBENCH state_name <= "UNTRIGGERABLE"; `endif
            trig_out <= 1'b1;
            state <= TRIGGERED;

        end else if (cmd == `TRIGGER_MODE_EDGE) begin
            if (state != EDGE_IDLE && state != EDGE_TRIGD) begin
                `ifdef TESTBENCH state_name <= "EDGE_IDLE"; `endif
                state <= EDGE_IDLE;
                trig_out <= 1'b0;
            end else begin
                if (trig_edge) begin
                    `ifdef TESTBENCH state_name <= "EDGE_TRIGD"; `endif
                    trig_out <= 1'b1;
                    state <= EDGE_TRIGD;
                end else begin
                    `ifdef TESTBENCH state_name <= "~EDGE_TRIGD"; `endif
                end
            end
        end else if (cmd == `RESET_EDGE) begin
            `ifdef TESTBENCH state_name <= "RESET_EDGE"; `endif
            if (state == EDGE_TRIGD) begin
                trig_out <= 1'b0;
                state <= EDGE_IDLE;
            
            // If we didn't transition from EDGE_IDLE to TRIGGERED here, we would
            // never read in another byte and hence deadlock. So go to TRIGGERED
            // so we can proceed.
            end else if (state == EDGE_IDLE) begin
                if (trig_in) begin
                    trig_out <= 1'b1;
                    state <= TRIGGERED;
                end
                
            end

        // end else if (cmd == `TRIGGER_MODE_GATE) begin
        //     `ifdef TESTBENCH state_name <= "GATED"; `endif
        //     state <= GATED;
        //     trig_out <= trig_in;
        end
    end
endmodule