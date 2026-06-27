import os
import shutil

src = os.path.join(os.path.dirname(__file__), "..", "data", "visuals", "default_module_visuals.tres")
dst_dir = os.path.join(os.path.dirname(__file__), "..", "data", "visuals")
os.makedirs(dst_dir, exist_ok=True)

ships = ["vanguard", "phantom", "goliath"]

for ship in ships:
    for i in range(3):
        filename = f"{ship}_{i}_visuals.tres"
        dst = os.path.join(dst_dir, filename)
        shutil.copy2(src, dst)
        print(f"Created: {filename}")

print(f"\nDone! Copied {len(ships) * 3} files.")