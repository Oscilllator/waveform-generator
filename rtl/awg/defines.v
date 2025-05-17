`ifndef DEFINES
`define DEFINES

`define SAMPLE_RATE 10_000_000

// Bit width of the AD9744
`define DAC_BIT_WIDTH 14

// Bit width of the word sent to the awg
`define BIT_WIDTH 16
`define CMD_BIT 7
`define CMD_MASK 16'b1000_0000

// When the command TRIGGER_MODE_EDGE is set, the device will be idle (TRIG_IDLE)
// and then begin transmitting data
// on the rising edge of the trigger signal. It will then continue transmitting until a 
// RESET_EDGE command is received, whereapon it will return to the 
// continuously triggered state. This is to prevent the device being stalled waiting for a trigger.
`define TRIGGER_CMD_BIT   6
`define TRIGGER_MODE_NONE 7'b100_0000
`define TRIGGER_MODE_EDGE 7'b100_0001
`define RESET_EDGE        7'b100_0010

// since each waveform generator sample is 8 bits and only 7 are available for each
// word, we need to store some intermediary state. This resets that state.
`define STATE_CMD_BIT      5
`define RESET_TRANSMISSION 7'b010_0000

`endif
