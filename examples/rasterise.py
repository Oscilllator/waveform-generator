import matplotlib.pyplot as plt
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from numpy.lib.stride_tricks import sliding_window_view

# def zhang_suen_skeletonize(bin_img):
#     """Thin a binary 2D NumPy array using Zhang-Suen skeletonization."""
#     out = bin_img.copy()
#     changed = True

#     def neighbors(x, y):
#         return [out[x-1, y],   out[x-1, y+1], out[x, y+1],   out[x+1, y+1],
#                 out[x+1, y], out[x+1, y-1], out[x, y-1],   out[x-1, y-1]]

#     while changed:
#         changed = False
#         # Step 1
#         remove = []
#         for i in range(1, out.shape[0]-1):
#             for j in range(1, out.shape[1]-1):
#                 if out[i,j] == 1:
#                     nb = neighbors(i,j)
#                     transitions = sum(nb[k] == 0 and nb[(k+1)%8] == 1 for k in range(8))
#                     count = sum(nb)
#                     if (2 <= count <= 6 and transitions == 1
#                         and nb[0]*nb[2]*nb[4] == 0
#                         and nb[2]*nb[4]*nb[6] == 0):
#                         remove.append((i,j))
#         for i,j in remove:
#             out[i,j] = 0
#         if remove:
#             changed = True

#         # Step 2
#         remove = []
#         for i in range(1, out.shape[0]-1):
#             for j in range(1, out.shape[1]-1):
#                 if out[i,j] == 1:
#                     nb = neighbors(i,j)
#                     transitions = sum(nb[k] == 0 and nb[(k+1)%8] == 1 for k in range(8))
#                     count = sum(nb)
#                     if (2 <= count <= 6 and transitions == 1
#                         and nb[0]*nb[2]*nb[6] == 0
#                         and nb[0]*nb[4]*nb[6] == 0):
#                         remove.append((i,j))
#         for i,j in remove:
#             out[i,j] = 0
#         if remove:
#             changed = True

#     return out

def rasterize_text(text, font_path=None, font_size=40):
    # 1) Pick a font; if you omit font_path, load_default is used (smaller).
    if font_path is not None:
        font = ImageFont.truetype(font_path, font_size)
    else:
        font = ImageFont.load_default()

    # 2) Render solid text in 1-bit mode (no anti-alias).
    w, h = font.getsize(text)
    img = Image.new("1", (w, h), 0)
    draw = ImageDraw.Draw(img)
    draw.text((0, 0), text, fill=1, font=font)

    bin_array = np.array(img, dtype=np.uint8)
    return bin_array

def vectorise(mat: np.ndarray):
    # in: 2D binary image
    # The output is sent in a number of sweeps. The maximum number of sweeps needed is
    # equal to the maximum number of vertical edges in a letter, which is 4 for B.
    # Each pixel of the image is pwm'd between two values for a certain amount of time
    # (the expansion)
    # out: 3D array of shape (MAX_VERTS, image_width, expansion)
    assert mat.ndim == 2
    mat = np.flipud(mat)
    image_width = mat.shape[1]
    expansion = 100
    MAX_NUM_SWEEPS = 4
    square_wave = np.arange(expansion) % 2
    out = np.zeros((MAX_NUM_SWEEPS, image_width, expansion))
    for col_idx in range(image_width):
        col = mat[:, col_idx]
        vert_starts = np.argwhere(np.diff(col, prepend=0) > 0)
        vert_stops = np.argwhere(np.diff(col, append=0) < 0)
        assert vert_starts.size == vert_stops.size
        print(f"{col_idx=}, {vert_starts=}, {vert_stops=}")
        assert vert_starts.size <= MAX_NUM_SWEEPS
        for vert_idx in range(vert_starts.size):
            start = vert_starts[vert_idx]
            stop = vert_stops[vert_idx] + 1
            out[vert_idx, col_idx, :] = start + square_wave * (stop - start)
    return out

def scrollify(arr: np.ndarray, window_size):
    # in: 3D array of shape (num_sweeps, image_width, expansion)
    num_sweeps, image_width, expansion = arr.shape
    # window_size = 128
    step_per_frame = 3
    num_windows = (image_width - window_size) // step_per_frame

    out = np.zeros((num_sweeps, num_windows, window_size, expansion))

    for sweep_idx in range(num_sweeps):
        for window_idx in range(num_windows):
            start = window_idx * step_per_frame
            stop = start + window_size
            out[sweep_idx, window_idx] = arr[sweep_idx, start:stop]

    # print(arr.shape)
    # out = sliding_window_view(arr, (1, window_size, 1))
    print(out.shape)


def test_scrollify():
    test = np.zeros((2, 5, 3))
    for i in range(2):
        for j in range(5):
            for k in range(3):
                test[i, j, k] = 100 * (i+1) + 10 * (j+1) + (k+1)
    measured = scrollify(test, 2)
    print("asdf")




if __name__ == "__main__":
    test_scrollify()

    arr = rasterize_text(
        # "R",
        # "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "The quick brown fox jumped over the lazy dog",
        font_path="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        font_size=100
    )
    print(arr)
    time_series = vectorise(arr)
    out = scrollify(time_series)
    for i in range(time_series.shape[0]):
        plt.plot(time_series[i].flatten())
    plt.show()


    # plt.imshow(arr, cmap="gray", interpolation=None)
    # plt.show()
    # plt.imshow(arr, cmap="gray", interpolation=None)
    # plt.show()