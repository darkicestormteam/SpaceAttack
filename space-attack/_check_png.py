from PIL import Image
import os

paths = [
    r"D:/github/SpaceAttack/space-attack/assets/sprites/ui/moduls/Laser.png",
    r"D:/github/SpaceAttack/space-attack/assets/sprites/ui/moduls/Shotgun.png",
    r"D:/github/SpaceAttack/space-attack/assets/sprites/ui/moduls/Rocet.png",
]

for path in paths:
    img = Image.open(path)
    print(f"\n{os.path.basename(path)}: mode={img.mode}, size={img.size}")
    rgba = img.convert("RGBA")
    pixels = list(rgba.getdata())
    non_transparent = [p for p in pixels if p[3] > 0]
    print(f"  total={len(pixels)}  non_transparent={len(non_transparent)}")
    if non_transparent:
        sample = non_transparent[len(non_transparent) // 2]
        print(f"  sample RGBA: {sample}")
        # Find most opaque pixel
        max_a = max(p[3] for p in pixels)
        max_a_pixel = next(p for p in pixels if p[3] == max_a)
        print(f"  most opaque: {max_a_pixel}")
