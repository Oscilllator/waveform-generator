import time
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image, ImageDraw, ImageFont

import awglib

def rasterize_text(text, font_path=None, font_size=40):
    # Convert text to a binary image
    font = ImageFont.truetype(font_path, font_size)

    left, top, right, bottom = font.getbbox(text)   # getbbox returns (x0, y0, x1, y1)
    w, h = right - left, bottom - top

    img = Image.new("1", (w,h), 0)
    draw = ImageDraw.Draw(img)
    draw.text((-left, -top), text, fill=1, font=font)  # <-- shift so full glyph fits

    bin_array = np.array(img, dtype=np.uint8)
    return bin_array

def serialize_image(mat: np.ndarray):
    # in: 2D binary image
    # The output is sent in a number of sweeps. The maximum number of sweeps needed is
    # equal to the maximum number of vertical edges in a letter, which is 4 for B.
    # Each pixel of the image is pwm'd between two values for a certain amount of time
    # (the expansion)
    # out: 3D array of shape (MAX_VERTS, image_width, expansion)
    assert mat.ndim == 2
    mat = np.flipud(mat)
    image_width = mat.shape[1]
    expansion = 10
    MAX_NUM_SWEEPS = 4
    square_wave = np.arange(expansion) % 2
    out = np.zeros((MAX_NUM_SWEEPS, image_width, expansion))
    for col_idx in range(image_width):
        col = mat[:, col_idx]
        vert_starts = np.argwhere(np.diff(col, prepend=0) > 0)
        vert_stops = np.argwhere(np.diff(col, append=0) < 0)
        assert vert_starts.size == vert_stops.size
        assert vert_starts.size <= MAX_NUM_SWEEPS
        for vert_idx in range(vert_starts.size):
            start = vert_starts[vert_idx]
            stop = vert_stops[vert_idx] + 1
            out[vert_idx, col_idx, :] = start + square_wave * (stop - start)
    return out

if __name__ == "__main__":
    text = "Can your waveform generator do this?"
    arr = rasterize_text(
        text,
        font_path="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        font_size=50
    )
    time_series = serialize_image(arr)


    out_analog = 1 - time_series.flatten() / np.max(time_series)
    out_digital = np.zeros(time_series.size, dtype=np.uint8)
    out_digital[0::(time_series.shape[1]*time_series.shape[2])] = 1

    # Add animation by repeatedly shifting the offset at which the waveform is triggered:
    text_len_samples = out_analog.size
    text_len_sec = out_analog.size / 10e6
    desired_len_sec = 20
    total_frames = int(desired_len_sec / text_len_sec)

    triggers = np.zeros(out_analog.size * total_frames, dtype=np.uint8)
    sz = out_digital.size
    roll_per_frame = out_digital.size // total_frames
    for f_idx in range(total_frames):
        triggers[f_idx*sz:(f_idx+1)*sz] = np.roll(out_digital, int(f_idx * sz / total_frames))
    out_analog = np.tile(out_analog, total_frames)
    out_digital = triggers
        
    print(f"final size: {out_analog.size=}, {out_digital.size=}")

    awg = awglib.awg()
    awg.send_volts(out_analog[0:10], [out_digital[0:10]], continuous=False)
    awg.send_volts(out_analog, [out_digital], continuous=True)

    # visualise what is being sent out over the wire:
    for i in range(time_series.shape[0]):
        plt.plot(time_series[i].flatten(), label=f"waveform {i}")
    plt.legend()
    plt.show()
    time.sleep(1e6)



    # plt.imshow(arr, cmap="gray", interpolation=None)
    # plt.show()
    # plt.imshow(arr, cmap="gray", interpolation=None)
    # plt.show()