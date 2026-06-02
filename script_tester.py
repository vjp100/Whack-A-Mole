from PIL import Image

COE_FILE = "hole_with_mole.coe"
OUTPUT_IMAGE = "test_reconstructed.png"

WIDTH = 160
HEIGHT = 160

with open(COE_FILE, "r") as f:
    text = f.read()

# Remove header
data = text.split("memory_initialization_vector=")[1]

# Remove semicolon and whitespace
data = data.replace(";", "")
values = data.replace("\n", "").split(",")

# Remove empty values
values = [v.strip() for v in values if v.strip()]

print("Number of values:", len(values))
print("Expected:", WIDTH * HEIGHT)

pixels = []

for hex_val in values:
    value = int(hex_val, 16)

    r4 = (value >> 8) & 0xF
    g4 = (value >> 4) & 0xF
    b4 = value & 0xF

    # Convert 4-bit back to 8-bit for viewing
    r8 = r4 * 17
    g8 = g4 * 17
    b8 = b4 * 17

    pixels.append((r8, g8, b8))

img = Image.new("RGB", (WIDTH, HEIGHT))
img.putdata(pixels)
img.save(OUTPUT_IMAGE)

print("Saved reconstructed image as ",OUTPUT_IMAGE)