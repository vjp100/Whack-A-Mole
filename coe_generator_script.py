import math
from PIL import Image


def convert_to_4bit(colour):
    # scaling from 8 bit to 4bit
    scaled_col = round(colour * (15 / 255))
    col_4bit = min(max(scaled_col,0),15)

    return col_4bit


def generate_coe(image_path, output_path, rom_width, rom_height):
    img = Image.open(image_path)
    img = img.resize((rom_width, rom_height))
    img = img.convert('RGB')

    pixels = []
    hex_values = []

    for pixel in img.getdata():
        pixels.append(pixel)

    for r, g, b in pixels:
        r_4bit = convert_to_4bit(r)
        g_4bit = convert_to_4bit(g)
        b_4bit = convert_to_4bit(b)

        val_12bit = f"{r_4bit:04b}{g_4bit:04b}{b_4bit:04b}"
        hex_values.append(f"{int(val_12bit, 2):03X}")

    with open(output_path, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        for value in hex_values[:-1]:
            f.write(value + ",\n")

        f.write(hex_values[-1] + ";\n")

    f.close()
    print(f"Generated COE file: {output_path}")
    print(f"Width: {rom_width}, Height: {rom_height}")
    print(f"Depth: {rom_width * rom_height}")


# --- Configuration ---
INPUT_IMAGE = "hole_with_mole.png"
OUTPUT_COE = "hole_with_mole.coe"

ROM_WIDTH = 160
ROM_HEIGHT = 160

if __name__ == "__main__":
    generate_coe(INPUT_IMAGE, OUTPUT_COE, ROM_WIDTH, ROM_HEIGHT)