#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <assert.h>

// Constants (matching verilog_consts)
#define CMD_MASK 0x80
#define RESET_TRANSMISSION 0x01
#define RESET_EDGE 0x02
#define TRIGGER_MODE_EDGE 0x01
#define TRIGGER_MODE_LEVEL 0x00
#define BIT_WIDTH 16  // Change to 8 if needed

// ------------------------------------------------------------------
// pack_bits_inplace:
// Given an array of 16-bit samples, pack their bits (MSB first)
// into an output buffer where each byte holds 7 bits (the MSB is 0).
// out_capacity must be at least ceil(n*16/7) bytes.
// Returns the number of bytes written.
size_t pack_bits_inplace(const uint16_t *input, size_t n, uint8_t *output, size_t out_capacity) {
    size_t total_bits = n * 16;
    size_t required_bytes = (total_bits + 6) / 7;  // ceiling division
    if (required_bytes > out_capacity) {
        fprintf(stderr, "pack_bits_inplace: insufficient output capacity. Required %zu, got %zu\n",
                required_bytes, out_capacity);
        exit(1);
    }
    size_t out_index = 0;
    int bits_in_current = 0;
    uint8_t current_byte = 0;
    for (size_t i = 0; i < n; i++) {
        for (int bit = 15; bit >= 0; bit--) {
            uint8_t b = (input[i] >> bit) & 1;
            current_byte |= (b << (6 - bits_in_current));
            bits_in_current++;
            if (bits_in_current == 7) {
                output[out_index++] = current_byte;
                bits_in_current = 0;
                current_byte = 0;
            }
        }
    }
    if (bits_in_current > 0) {
        output[out_index++] = current_byte;
    }
    return out_index;
}

// ------------------------------------------------------------------
// unpack_bits_inplace:
// Given a packed array (each byte has 7 data bits, MSB zero),
// unpack the bits into 16-bit integers. Only full 16-bit groups are
// reconstructed. out_capacity must be at least floor(packed_len*7/16).
// Returns the number of uint16_t values written.
size_t unpack_bits_inplace(const uint8_t *packed, size_t packed_len, uint16_t *output, size_t out_capacity) {
    size_t total_bits = packed_len * 7;
    size_t num_ints = total_bits / 16; // only complete 16-bit groups
    if (num_ints > out_capacity) {
        fprintf(stderr, "unpack_bits_inplace: insufficient output capacity. Required %zu, got %zu\n",
                num_ints, out_capacity);
        exit(1);
    }
    size_t bit_index = 0;
    for (size_t i = 0; i < num_ints; i++) {
        uint16_t value = 0;
        for (int j = 0; j < 16; j++) {
            size_t byte_index = bit_index / 7;
            int bit_in_byte = bit_index % 7;
            uint8_t b = (packed[byte_index] >> (6 - bit_in_byte)) & 1;
            value |= (b << (15 - j));
            bit_index++;
        }
        output[i] = value;
    }
    return num_ints;
}

// ------------------------------------------------------------------
// samples_to_wire_format:
// Constructs a payload that begins with a trigger byte, then the packed
// sample bits, then a stop byte, and if trigger_mode equals TRIGGER_MODE_EDGE,
// an extra edge-reset byte.
// The output buffer must be large enough; its capacity must be at least:
//    1 + ceil(n*16/7) + 1 + (trigger_mode==TRIGGER_MODE_EDGE ? 1 : 0)
// Returns the total number of bytes written.
size_t samples_to_wire_format(const uint16_t *samples, size_t n, uint8_t trigger_mode,
                              uint8_t *output, size_t out_capacity) {
    if (trigger_mode >= CMD_MASK) {
        fprintf(stderr, "samples_to_wire_format: invalid trigger mode\n");
        exit(1);
    }
    uint8_t trigger_byte = trigger_mode | CMD_MASK;
    uint8_t stop_byte = RESET_TRANSMISSION | CMD_MASK;
    size_t pack_bytes_required = (n * 16 + 6) / 7; // worst-case pack size
    size_t required = 1 + pack_bytes_required + 1 + ((trigger_mode == TRIGGER_MODE_EDGE) ? 1 : 0);
    if (required > out_capacity) {
        fprintf(stderr, "samples_to_wire_format: insufficient output capacity. Required %zu, got %zu\n",
                required, out_capacity);
        exit(1);
    }
    size_t pos = 0;
    output[pos++] = trigger_byte;
    size_t pack_bytes = pack_bits_inplace(samples, n, output + pos, pack_bytes_required);
    pos += pack_bytes;
    output[pos++] = stop_byte;
    if (trigger_mode == TRIGGER_MODE_EDGE) {
        output[pos++] = CMD_MASK | RESET_EDGE;
    }
    return pos;
}

// ------------------------------------------------------------------
// Fuzz test: pack/unpack
// For 1000 random tests, generate a random uint16_t array,
// pack it, then unpack and compare with the original.
// Uses preallocated buffers to avoid per‐call malloc.
void fuzz_test_pack_unpack() {
    const size_t max_n = 10000;
    uint16_t *input_buffer = malloc(max_n * sizeof(uint16_t));
    if (!input_buffer) { perror("malloc"); exit(1); }
    // Maximum packed size: ceil(max_n * 16 / 7)
    size_t pack_buf_size = (max_n * 16 + 6) / 7;
    uint8_t *pack_buffer = malloc(pack_buf_size);
    if (!pack_buffer) { perror("malloc"); exit(1); }
    uint16_t *unpack_buffer = malloc(max_n * sizeof(uint16_t));
    if (!unpack_buffer) { perror("malloc"); exit(1); }

    for (int t = 0; t < 1000; t++) {
        size_t n = (rand() % max_n) + 1;
        for (size_t i = 0; i < n; i++) {
            input_buffer[i] = (uint16_t)(rand() & 0xFFFF);
        }
        size_t packed_len = pack_bits_inplace(input_buffer, n, pack_buffer, pack_buf_size);
        size_t unpacked_n = unpack_bits_inplace(pack_buffer, packed_len, unpack_buffer, n);
        if (unpacked_n != n) {
            fprintf(stderr, "Test %d: Unpacked length mismatch: expected %zu, got %zu\n", t, n, unpacked_n);
            exit(1);
        }
        for (size_t i = 0; i < n; i++) {
            if (input_buffer[i] != unpack_buffer[i]) {
                fprintf(stderr, "Test %d: Mismatch at index %zu: expected %u, got %u\n",
                        t, i, input_buffer[i], unpack_buffer[i]);
                exit(1);
            }
        }
    }
    printf("Fuzz tests passed.\n");
    free(input_buffer);
    free(pack_buffer);
    free(unpack_buffer);
}

// ------------------------------------------------------------------
// Wire format test (no crash):
// For each trigger mode, generate a sample array and construct a payload.
// Uses a preallocated buffer for the wire format.
void to_wire_format_notcrash() {
    uint8_t trigger_modes[2] = {TRIGGER_MODE_LEVEL, TRIGGER_MODE_EDGE};
    const char *mode_names[2] = {"TRIGGER_MODE_LEVEL", "TRIGGER_MODE_EDGE"};
    const size_t max_n = 10000;
    uint16_t *sample_buffer = malloc(max_n * sizeof(uint16_t));
    if (!sample_buffer) { perror("malloc"); exit(1); }
    // Preallocate worst-case output: 1 + ceil(max_n*16/7) + 1 + 1
    size_t wire_buf_size = 1 + ((max_n * 16 + 6) / 7) + 1 + 1;
    uint8_t *wire_buffer = malloc(wire_buf_size);
    if (!wire_buffer) { perror("malloc"); exit(1); }

    for (int i = 0; i < 2; i++) {
        uint8_t mode = trigger_modes[i];
        printf("Testing trigger mode: %s: 0b", mode_names[i]);
        for (int bit = 7; bit >= 0; bit--) {
            printf("%d", (mode >> bit) & 1);
        }
        printf("\n");

        size_t n = (rand() % max_n) + 1;
        // Fill sample_buffer with random values in [0, 2^BIT_WIDTH)
        for (size_t j = 0; j < n; j++) {
            sample_buffer[j] = (uint16_t)(rand() % (1 << BIT_WIDTH));
        }
        size_t payload_len = samples_to_wire_format(sample_buffer, n, mode, wire_buffer, wire_buf_size);
        // (Optionally, you could examine wire_buffer[0 .. payload_len-1])
    }
    free(sample_buffer);
    free(wire_buffer);
}

// ------------------------------------------------------------------
// Benchmark:
// For several sample sizes, preallocate the output buffer once and measure
// the time taken by samples_to_wire_format (excluding allocation).
void benchmark() {
    int sizes[] = {10, 100, 1000, 10000, 100000, 1000000, 10000000};
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    for (int i = 0; i < num_sizes; i++) {
        size_t s = sizes[i];
        // Allocate sample array.
        uint16_t *signal = malloc(s * sizeof(uint16_t));
        if (!signal) { perror("malloc"); exit(1); }
        // Fill with random numbers in [0, 2^14 - 1]
        for (size_t j = 0; j < s; j++) {
            signal[j] = (uint16_t)(rand() % ((1 << 14) - 1));
        }
        // Preallocate output buffer: 1 + ceil(s*16/7) + 1 (+1 for edge mode, but we use LEVEL here)
        size_t out_capacity = 1 + ((s * 16 + 6) / 7) + 1 + 1;
        uint8_t *output_buffer = malloc(out_capacity);
        if (!output_buffer) { perror("malloc"); exit(1); }

        clock_t start = clock();
        size_t payload_len = samples_to_wire_format(signal, s, TRIGGER_MODE_LEVEL, output_buffer, out_capacity);
        clock_t end = clock();
        double duration = (double)(end - start) / CLOCKS_PER_SEC;
        double samples_per_sec = (double)s / duration;
        printf("Sent %zu samples in %f seconds (%f samples/s, payload length %zu)\n", s, duration, samples_per_sec, payload_len);
        free(signal);
        free(output_buffer);
    }
}

// ------------------------------------------------------------------
// Main
// ------------------------------------------------------------------
int main(void) {
    srand((unsigned) time(NULL));

    to_wire_format_notcrash();
    fuzz_test_pack_unpack();
    benchmark();

    return 0;
}
