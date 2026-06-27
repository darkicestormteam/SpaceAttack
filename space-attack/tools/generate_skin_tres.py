import os

skins_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "skins")
skins_dir = os.path.normpath(skins_dir)
os.makedirs(skins_dir, exist_ok=True)

ships = ["vanguard", "phantom", "goliath"]
skin_count = 3

tres_template = '''[gd_resource type="SpriteFrames" format=3]

[resource]
animations = [{
"frames": [],
"loop": true,
"name": "default",
"speed": 5.0
}]
'''

for ship in ships:
    for i in range(skin_count):
        filename = f"{ship}_{i}.tres"
        filepath = os.path.join(skins_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(tres_template)
        print(f"Created: {filename}")

print(f"\nDone! Created {len(ships) * skin_count} SpriteFrames resources in: {skins_dir}")