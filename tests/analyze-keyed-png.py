import json
import struct
import sys
import zlib


with open(sys.argv[1]) as f:
    data = bytes(json.load(f))

if len(sys.argv) > 2:
    with open(sys.argv[2], "wb") as f:
        f.write(data)

assert data.startswith(b"\x89PNG\r\n\x1a\n"), "output is not a PNG"

pos = 8
width = height = bit_depth = color_type = None
compressed = bytearray()

while pos < len(data):
    length = struct.unpack(">I", data[pos:pos + 4])[0]
    kind = data[pos + 4:pos + 8]
    chunk = data[pos + 8:pos + 8 + length]
    pos += 12 + length

    if kind == b"IHDR":
        width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
    elif kind == b"IDAT":
        compressed.extend(chunk)
    elif kind == b"IEND":
        break

assert (width, height, bit_depth, color_type) == (2, 1, 8, 6), "unexpected PNG shape"
raw = zlib.decompress(bytes(compressed))
assert raw[0] == 0, "test fixture should use no PNG row filter"

pixels = list(raw[1:])
expected = [255, 255, 255, 0, 0, 0, 0, 255]
assert pixels == expected, f"unexpected keyed pixels: {pixels}"
