module fpga_top_latch (
    input  wire         clk25,
    
    // USB2.0 HS (FT232H chip) interface
    output wire         ftdi_pwrsav,
    output wire         ftdi_siwu,
    input  wire         ftdi_clk,
    input  wire         ftdi_rxf_n,
    input  wire         ftdi_txe_n,
    output wire         ftdi_oe_n,
    output wire         ftdi_rd_n,
    output wire         ftdi_wr_n,
    inout  wire  [7:0]  ftdi_data,

    // These are high z because I soldered on top of them
    input  wire  [7:0]  logic_x,
    // This is high z because the dac is actually 10 bits but I haven't implemented that yet.
    input wire [1:0] dacx,

    input wire usr_btn,

    // Output bus
    output wire  [7:0]  dac,  // Goest to R2R DAC
    output wire  [7:0]  logic,     // Debugging to logic analyzer
);

    wire pll_locked;
    wire clk100;

    pll pll_inst (
        .clkin(clk25),
        .clkout0(clk100),
        .locked(pll_locked)
    );

    assign ftdi_pwrsav = 1'b1;
    assign ftdi_siwu   = 1'b1;

    // FTDI interface signals
    wire        rx_tvalid;
    wire [7:0]  rx_tdata;
    wire [0:0]  rx_tkeep;
    wire        rx_tlast;
    wire        rx_tready;

    // Rate control
    localparam CLK_FREQ = 100_000_000;
    localparam OUTPUT_FREQ = 10_000_000;
    localparam COUNTER_MAX = CLK_FREQ / OUTPUT_FREQ - 1;
    // localparam COUNTER_MAX = 65535;

    reg [31:0] rate_counter = 0;
    reg output_tick = 0;

    // FIFO signals
    localparam FIFO_SIZE = 16384; // 16k entries for over 1ms buffer at 10MSa/s
    reg [13:0] write_ptr = 0;
    reg [13:0] read_ptr = 0;
    reg [7:0] fifo [0:FIFO_SIZE-1];

    reg error = 0;

    // FTDI USB chip's 245fifo mode controller
    ftdi_245fifo_top #(
        .TX_EW                 ( 0                  ),
        .TX_EA                 ( 10                 ),
        .RX_EW                 ( 0                  ),
        .RX_EA                 ( 10                 ),
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
        .rx_tready             ( rx_tready          ),
        .rx_tvalid             ( rx_tvalid          ),
        .rx_tdata              ( rx_tdata           ),
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

    localparam [2:0] S_IDLE       = 3'b10,
                     S_SET_LENGTH = 3'b01,
                     S_TRANSFER   = 3'b11;
    // reg [2:0] state = S_IDLE;
    reg [2:0] state = S_TRANSFER;

    reg [7:0] trigger_mode = 0;
    reg [31:0] data_len = 0;
    reg [31:0] data_cnt = 0;

    // Rate control logic
    always @(posedge clk100) begin
        if (rate_counter == COUNTER_MAX) begin
            rate_counter <= 0;
            output_tick <= 1;
        end else begin
            rate_counter <= rate_counter + 1;
            output_tick <= 0;
        end
    end

    reg [7:0] dac_reg;
    reg dac_valid_reg;

    // State control logic
    always @(posedge clk100) begin
        // always @(posedge usr_btn) begin
        if (~usr_btn) begin
            error <= 0;
            // state <= S_IDLE;
            // trigger_mode <= 0;
            // data_len <= 0;
            // data_cnt <= 0;
            // write_ptr <= 0;
            // read_ptr <= 0;
            // dac_reg <= 0;
            // dac_valid_reg <= 0;

        end else if (rx_tvalid && !fifo_full) begin
            case (state)
                S_IDLE: begin
                    trigger_mode <= fifo[read_ptr];
                    // read_ptr <= read_ptr + 1;
                    state <= S_SET_LENGTH;
                end

                S_SET_LENGTH: begin
                    data_len[8*data_cnt +: 8] <= fifo[read_ptr];
                    read_ptr <= read_ptr + 1;
                    if (data_cnt < 4) begin
                        data_cnt <= data_cnt + 1;
                    end else begin
                        data_cnt <= 0;
                        state <= S_TRANSFER;
                    end
                end
                S_TRANSFER: begin
                    // Do nothing
                end
                default: begin
                    error <= 1'b1;
                end

            endcase
        end else if (output_tick && !fifo_empty && (state == S_TRANSFER)) begin

            // FIFO read and output logic
            if (output_tick && !fifo_empty) begin
                dac_reg <= fifo[read_ptr];
                read_ptr <= read_ptr + 1;
                dac_valid_reg <= 1;
            end else begin
                dac_valid_reg <= 0;
            end

            // data_cnt <= data_cnt + 1;
            // if (data_cnt == data_len) begin
            //     data_cnt <= 0;
            //     state <= S_IDLE;
            // end

        end
    end

    wire fifo_empty = (write_ptr == read_ptr);
    wire [13:0] next_write_ptr = write_ptr + 1;
    wire fifo_full = (next_write_ptr == read_ptr);

    // FIFO write logic without masking pointers
    always @(posedge clk100) begin
        if (rx_tvalid && !fifo_full) begin
            fifo[write_ptr] <= rx_tdata;
            write_ptr <= write_ptr + 1;
        end
    end

    // // FIFO read and output logic
    // reg [7:0] dac_reg;
    // reg dac_valid_reg;
    // always @(posedge clk100) begin
    //     if (output_tick && !fifo_empty) begin
    //         dac_reg <= fifo[read_ptr];
    //         read_ptr <= read_ptr + 1;
    //         dac_valid_reg <= 1;
    //     end else begin
    //         dac_valid_reg <= 0;
    //     end
    // end

    assign dac = dac_reg;
    // assign dac = rate_counter[15:8];

    assign rx_tready = !fifo_full;

    assign logic[0] = error;
    // assign logic[1] = 1'b1;
    // assign logic[2] = 1'b1;
    // assign logic[3] = output_tick;
    assign logic[3:1] = state;
    assign logic[4] = usr_btn;
    // assign logic[4] = rx_tvalid;
    assign logic[5] = rx_tready;
    assign logic[6] = fifo_empty;
    assign logic[7] = fifo_full;

endmodule
