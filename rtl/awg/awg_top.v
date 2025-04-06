`default_nettype none
`include "defines.v"
`timescale 1ns/1ps

module awg_top (
    input  wire         clk16,
    
    // USB2.0 HS (FT232H chip) interface
    input  wire         ftdi_rxf_n,
    input  wire         ftdi_txe_n,
    output wire         ftdi_rd_n,
    output wire         ftdi_wr_n,
    output wire         ftdi_siwu,
    input  wire         ftdi_clk,
    output wire         ftdi_oe_n,
    output wire         ftdi_pwrsav,
    inout  wire  [7:0]  ftdi_data,
    input wire          ftdi_acbus8,
    input wire          ftdi_acbus9,

    input wire trigger,

    // Output bus
    output wire  [13:0]  awg_ad9744,
    output wire  awg_ad9744_clk,
    output wire  awg_ad9744_mode,
    output wire  awg_ad9744_sleep,

    output wire [15:0] logic_out,
    output wire [7:0] led,

    output wire [1:0] dout,

    output wire clk12,
);
    assign awg_ad9744_mode = 1'b0;
    assign awg_ad9744_sleep = 1'b0;

    wire err_latched;
    assign err_latched = led[0];

    wire clk100;
    wire pll_100_locked = led[2];

    // PLL instantiation (assuming you have a PLL module)
    pll_100 pll_100_inst (
        .clkin      ( clk16     ),
        .clkout0    ( clk100    ),
        .locked     ( pll_100_locked )
    );

    wire pll_12_locked = led[1];
    pll_12 pll_12_inst (
        .clkin      ( clk16     ),
        .clkout0    ( clk12    ),
        .locked     ( pll_12_locked )
    );

    wire ftdi_fsm_ready;
    wire ftdi_fsm_valid;
    wire [8 - 1:0] ftdi_fsm_data;

    wire        rx_tlast;
    wire [0:0]  rx_tkeep;
    assign ftdi_pwrsav = 1'b1;
    assign ftdi_siwu   = 1'b1;

    // FTDI USB chip's 245fifo mode controller
    ftdi_245fifo_top #(
        .TX_EW                 ( 0                  ),
        .TX_EA                 ( 8                 ),
        .RX_EW                 ( 0                  ),
        // The depth of the rx fifo is critical, it determines the amount of time the host computer
        // can wait between commands.
        .RX_EA                 ( 15                 ),
        .CHIP_TYPE             ( "FTx232H"          )
    ) u_ftdi_245fifo_top (
        .rstn_async            ( 1'b1               ),
        .tx_clk                ( clk100             ),
        .tx_tready             (                    ),
        .tx_tvalid             ( 1'b0               ),
        .tx_tdata              ( 8'h00              ),
        .tx_tkeep              ( 1'b0               ),
        .tx_tlast              ( 1'b0               ),
        .rx_clk                ( clk100             ),
        .rx_tready             ( ftdi_fsm_ready          ),
        .rx_tvalid             ( ftdi_fsm_valid          ),
        .rx_tdata              ( ftdi_fsm_data           ),
        .rx_tkeep              ( rx_tkeep           ),
        .rx_tlast              ( rx_tlast           ),
        .ftdi_clk              ( ftdi_clk           ),
        .ftdi_rxf_n            ( ftdi_rxf_n         ),
        .ftdi_txe_n            ( ftdi_txe_n         ),
        .ftdi_oe_n             ( ftdi_oe_n          ),
        .ftdi_rd_n             ( ftdi_rd_n          ),
        .ftdi_wr_n             ( ftdi_wr_n          ),
        .ftdi_data             ( ftdi_data          ),
        .ftdi_be               (                    )
    );

    // reg [14:0] counter_ad9444 = 14'h0;
    // reg [15:0] counter_logic = 16'h0;
    // reg [27:0] counter_led = 8'h0;
    // assign awg_ad9744 = counter_ad9444[14:1];
    // assign awg_ad9744_clk = counter_ad9444[0];

    // assign logic_out[0] = ftdi_rxf_n;
    // assign logic_out[1] = ftdi_txe_n;
    // assign logic_out[2] = ftdi_rd_n;
    // assign logic_out[3] = ftdi_wr_n;
    // assign logic_out[4] = ftdi_siwu;
    // assign logic_out[5] = ftdi_clk;
    // assign logic_out[6] = ftdi_oe_n;
    // assign logic_out[7] = ftdi_pwrsav;

    // assign logic_out[8] = ftdi_fsm_ready;
    // assign logic_out[9] = ftdi_fsm_valid;
    // assign logic_out[10] = ftdi_fsm_data;

    // assign logic_out[8] = ftdi_data[0];
    // assign logic_out[9] = ftdi_data[1];
    // assign logic_out[10] = ftdi_data[2];
    // assign logic_out[11] = ftdi_data[3];
    // assign logic_out[12] = ftdi_data[4];
    // assign logic_out[13] = ftdi_data[5];
    // assign logic_out[14] = ftdi_data[6];
    // assign logic_out[15] = ftdi_data[7];
    // assign logic_out[15:8] = ftdi_data;
    // assign logic_out[15:8] = awg_ad9744[7:0];

    // assign led[7] = counter_led[25];
    // always @(posedge clk100) begin
    //     counter_ad9444 <= counter_ad9444 + 1;
    //     counter_logic <= counter_logic + 1;
    //     counter_led <= counter_led + 1;

    // end

    assign led[3] = 1'b0;
    assign led[4] = 1'b0;
    assign led[5] = 1'b0;
    assign led[6] = 1'b1;
    assign led[7] = 1'b1;

    
    wire awg_valid;
    wire [`BIT_WIDTH - 1:0] awg_out;
    assign awg_ad9744 = awg_out[13:0];
    assign dout = awg_out[15:14];

    wire [15:0] logic_out2;
    // assign logic_out[7:0] = logic_out2[7:0];
    // assign logic_out2[7:0] = logic_out[7:0];
    top_sans_ftdi # (
        .BIT_WIDTH(`BIT_WIDTH)
    ) u_top_sans_ftdi (
        .clk100         ( clk100          ),
        .fsm_tvalid     ( ftdi_fsm_valid  ),
        .fsm_tready     ( ftdi_fsm_ready  ),
        .fsm_tdata      ( ftdi_fsm_data   ),
        .trigger        ( trigger         ),
        .awg_out        ( awg_out         ),
        .awg_clk        ( awg_ad9744_clk         ),
        .awg_valid      ( awg_valid       ),
        .err_latched    ( err_latched     ),
        .logic_out      ( logic_out          )
        // .logic_out      ( logic_out2          )
        // .logic_out      (           )
    );


endmodule