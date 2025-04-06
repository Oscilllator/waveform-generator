`timescale 1ns/1ps

`default_nettype none
`include "defines.v"
`include "test_data.gen.v"

`timescale 1ns/1ps

module sequential_tb;
    reg start_streaming = 0;
    reg start_trigger = 0;
    reg end_signal = 0;

    // Instantiate both test modules
    streaming_tb stream_test();
    trigger_tb trig_test();

    // Main test sequencer
    initial begin
        $display("\n==================================== Starting Streaming Mode Test ====================================");
        start_streaming = 1;
        #10000;  // Your original delay
        
        $display("\n==================================== Starting Trigger Mode Test ====================================");
        start_streaming = 0;
        start_trigger = 1;
        #10000;  // Your original delay
        
        end_signal = 1;
        $display("\n=== All Tests Completed ===");
        $finish;
    end

endmodule

module streaming_tb;
    initial begin
        wait(sequential_tb.start_streaming);
    end

    reg clk100;
    reg fsm_tvalid = 0;
    wire fsm_tready;
    reg [7:0] fsm_tdata;
    reg trigger = 1'b1;
    wire [`BIT_WIDTH - 1:0] awg_out;
    wire awg_valid;
    wire awg_clk;
    wire err_latched;

    top_sans_ftdi #(
        .BIT_WIDTH(`BIT_WIDTH)
        ) uut (
        .clk100         ( clk100 ),
        .fsm_tvalid     ( fsm_tvalid ),
        .fsm_tready     ( fsm_tready ),
        .fsm_tdata        ( fsm_tdata ),
        .trigger       ( trigger ),
        .awg_out        ( awg_out ),
        .awg_clk       ( awg_clk ),
        .awg_valid     ( awg_valid ),
        .err_latched    ( err_latched ),
        .logic_out     (  )
    );

    initial begin
        $dumpfile("streaming_tb.vcd");
        $dumpvars(0, streaming_tb);
        $display("%d",  uut.BIT_WIDTH);

        clk100 = 0;
        forever #5 clk100 = (~clk100 & sequential_tb.start_streaming); // 100 MHz clock -> period of 10 ns
    end

    initial begin
        $display("Testing streaming mode");
        #10000;
        // #1000;
        $display("Streaming mode ended.");
        // $display("############FINISHED############\n\n");
        // $finish;
    end

    test_vector_TRIGGER_MODE_NONE td();

    // Running of the test.
    integer cooldown_counter = 0;
    integer data_index = 0;
    reg [8*22-1:0] tb_state = "UNINITIALIZED";
    initial begin
        fsm_tdata <= td.byte_stream[data_index];
        fsm_tvalid <= 1;
        data_index = 1;
        tb_state <= "Begin transmission";
        forever begin
            @(posedge clk100);
            // Loop through the state machine twice:

            if (fsm_tready && data_index < td.NUM_TEST_BYTES) begin
                fsm_tdata <= td.byte_stream[data_index];
                data_index <= data_index + 1;
                tb_state <= "Transmitting data";
            end

            if (data_index == td.NUM_TEST_BYTES) begin
                tb_state <= "cooldown";
                cooldown_counter = cooldown_counter + 1;
            end

            if (fsm_tready && data_index == td.NUM_TEST_BYTES && cooldown_counter > 1) begin
                fsm_tvalid <= 0;
                $display("added delays");
                #800
                fsm_tvalid <= 1;
                data_index = 0;
            end


        end
    end

    // Checking the output.
    reg [`BIT_WIDTH - 1:0] waveform_out[0:999];
    integer wf_idx = 0;
    reg[`BIT_WIDTH - 1:0] expected_wf = 0;
    initial begin
        $display("td.NUM_TEST_SAMPLES = %0d", td.NUM_TEST_SAMPLES);
        // forever begin @(posedge clk100);
        forever begin @(posedge awg_clk);
            waveform_out[wf_idx] <= awg_out;
            wf_idx <= wf_idx + 1;
            $display("storing waveform_out[%0d] = %b", wf_idx, awg_out);
            if (wf_idx == td.NUM_TEST_SAMPLES - 1) begin
                // check all the waveform samples:
                $display("Checking waveform samples");
                for (integer w_idx = 0; w_idx < td.NUM_TEST_SAMPLES; w_idx = w_idx + 1) begin
                    $display("waveform_out[%0d] = %b", w_idx, waveform_out[w_idx]);
                    expected_wf = td.sample_stream[w_idx];
                    if (waveform_out[w_idx] != expected_wf) begin
                        $error("waveform_out[%0d] = %b, expected %b", w_idx, waveform_out[w_idx], expected_wf);
                    end
                end
                wf_idx <= 0;
            end
        end
    end
    initial begin
        forever begin @(posedge err_latched);
            $display("Error latched");
        end
    end
endmodule



module trigger_tb;
    initial begin
        wait(sequential_tb.start_trigger);
    end

    reg clk100;
    reg fsm_tvalid = 0;
    wire fsm_tready;
    reg [7:0] fsm_tdata;
    wire [`BIT_WIDTH - 1:0] awg_out;
    wire awg_clk;
    wire awg_valid;
    wire err_latched;

    localparam TRIGGER_INTERVAL = 150;
    integer trigger_counter = (TRIGGER_INTERVAL * 7) / 10;
    // wire trigger = trigger_counter >= TRIGGER_INTERVAL - 5;
    wire trigger = trigger_counter == TRIGGER_INTERVAL;

    top_sans_ftdi #(
        .BIT_WIDTH(`BIT_WIDTH)
        ) uut (
        .clk100         ( clk100 ),
        .fsm_tvalid     ( fsm_tvalid ),
        .fsm_tready     ( fsm_tready ),
        .fsm_tdata        ( fsm_tdata ),
        .trigger       ( trigger ),
        .awg_out        ( awg_out ),
        .awg_clk       ( awg_clk ),
        .awg_valid     ( awg_valid ),
        .err_latched    ( err_latched ),
        .logic_out     (  )
    );

    initial begin
        // wait(sequential_tb.start_trigger);
        $display("BIT_WIDTH = %0d", `BIT_WIDTH);
        // $dumpfile("trigger_tb.vcd");
        $dumpvars(0, trigger_tb);

        clk100 = 0;
        forever #5 clk100 = ~clk100; // 100 MHz clock -> period of 10 ns
    end

    initial begin
        // wait(sequential_tb.start_trigger);
        $display("Testing trigger mode");
        #10000;
        $display("Trigger mode ended.");
        // $finish;
    end

    test_vector_TRIGGER_MODE_EDGE td();


    // Running of the test.
    integer data_index = 0;
    integer num_triggers = 0;
    reg [8*22-1:0] tb_state = "UNINITIALIZED";
    initial begin
        wait(sequential_tb.start_trigger);
        fsm_tdata <= td.byte_stream[data_index];
        fsm_tvalid <= 1;
        data_index = 1;
        tb_state <= "Begin transmission";

        forever begin
            @(posedge clk100);
            // Loop through the state machine twice:

            if (fsm_tready && data_index < td.NUM_TEST_BYTES) begin
                fsm_tdata <= td.byte_stream[data_index];
                data_index <= (data_index + 1) % td.NUM_TEST_BYTES;
                tb_state <= "Transmitting data";
            end

            if (num_triggers <= 1) begin
                // At the beginning of the test do things "properly" and send a single trigger pulse
                if (trigger_counter >= TRIGGER_INTERVAL) begin
                    trigger_counter = 0;
                    num_triggers++;
                end else begin
                    trigger_counter = trigger_counter + 1;
                end
            end else begin
                // Now slam on the gas. We should only send out one waveform since the trigger is
                // edge triggered not level triggered.
                trigger_counter = TRIGGER_INTERVAL;
            end



        end
    end

    // Checking the output.
    reg [`BIT_WIDTH - 1:0] waveform_out[0:999];
    integer total_samples = 0;
    integer wf_idx = 0;
    reg [`BIT_WIDTH - 1:0] expected_wf = 0;
    // integer NUM_TEST_SAMPLES = (NUM_TEST_SAMPLES - 2) * (`BIT_WIDTH - 1) / `BIT_WIDTH;
    initial begin
        wait(sequential_tb.start_trigger);
        $display("td.NUM_TEST_SAMPLES = %0d", td.NUM_TEST_SAMPLES);
        $display("waveform bit width = %0d", `BIT_WIDTH);
        forever begin @(posedge awg_clk);
            waveform_out[wf_idx] <= awg_out;
            wf_idx <= wf_idx + 1;
            total_samples <= total_samples + 1;
            $display("storing waveform_out[%0d] = %b", wf_idx, awg_out);
            if (wf_idx == td.NUM_TEST_SAMPLES - 1) begin
                // check all the waveform samples:
                $display("Checking waveform samples");
                for (integer w_idx = 0; w_idx < td.NUM_TEST_SAMPLES; w_idx = w_idx + 1) begin
                    $display("waveform_out[%0d] = %b", w_idx, waveform_out[w_idx]);
                    // expected_wf = (w_idx % 2 == 0) ? 8'h00 : 8'hFF;
                    expected_wf = td.sample_stream[w_idx];
                    if (waveform_out[w_idx] != expected_wf) begin
                        $error("waveform_out[%0d] = %b, expected %b", w_idx, waveform_out[w_idx], expected_wf);
                    end
                end
                wf_idx <= 0;
            end
        end
    end

    initial begin
        wait(sequential_tb.end_signal);
        if (total_samples < td.NUM_TEST_SAMPLES * 3) begin
            $error("Total number of samples sent %d < %d", total_samples, td.NUM_TEST_SAMPLES);
        end

    end

    initial begin
        forever begin @(posedge err_latched);
            $display("Error latched");
        end
    end

endmodule