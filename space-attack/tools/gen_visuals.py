import os

d = os.path.join(os.path.dirname(__file__), "..", "data", "visuals", "skins")
os.makedirs(d, exist_ok=True)

items = [
    ("vanguard_0", "Vanguard Стиль 1", 1, 1, 1),
    ("vanguard_1", "Vanguard Стиль 2", 0.7, 0.85, 1),
    ("vanguard_2", "Vanguard Стиль 3", 1, 0.8, 0.3),
    ("phantom_0", "Phantom Стиль 1", 1, 1, 1),
    ("phantom_1", "Phantom Стиль 2", 0.7, 0.85, 1),
    ("phantom_2", "Phantom Стиль 3", 1, 0.8, 0.3),
    ("goliath_0", "Goliath Стиль 1", 1, 1, 1),
    ("goliath_1", "Goliath Стиль 2", 0.7, 0.85, 1),
    ("goliath_2", "Goliath Стиль 3", 1, 0.8, 0.3),
]

template = '''[gd_resource type="Resource" script_class="ShipSkinVisuals" format=3]

[resource]
script = preload("res://data/visuals/skins/ShipSkinVisuals.gd")
fallback_text = "{txt}"
sprite_scale = 2.0
accent_color = Color({r}, {g}, {b}, 1)
'''

for fn, txt, r, g, b in items:
    p = os.path.join(d, fn + "_visuals.tres")
    with open(p, "w", encoding="utf-8") as f:
        f.write(template.format(txt=txt, r=r, g=g, b=b))
    print(f"OK  {fn}_visuals.tres")

print("Done! 9 files created.")