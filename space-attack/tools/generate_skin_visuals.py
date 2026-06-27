import os

visuals_dir = os.path.join(os.path.dirname(__file__), "..", "data", "visuals", "skins")
visuals_dir = os.path.normpath(visuals_dir)
os.makedirs(visuals_dir, exist_ok=True)

ships = [
    ("vanguard", "Vanguard"),
    ("phantom", "Phantom"),
    ("goliath", "Goliath")
]

skin_names = {
    0: "Стиль 1",
    1: "Стиль 2",
    2: "Стиль 3"
}

# accent colors per skin
accent_colors = {
    0: (1, 1, 1, 1),       # white
    1: (0.7, 0.85, 1, 1),  # light blue
    2: (1, 0.8, 0.3, 1)    # gold
}

template = '''[gd_resource type="Resource" script_class="ShipSkinVisuals" format=3]

[resource]
script = ExtResource("uid://ddw0e5ax22n6j")
animated_frames = null
texture = null
sprite_scale = 2.0
animation_speed = 1.0
fallback_text = "{ship_name} {skin_name}"
background_color = Color(1, 1, 1, 1)
accent_color = Color({r}, {g}, {b}, {a})
'''

for ship_id, ship_name in ships:
    for i in range(3):
        filename = f"{ship_id}_{i}_visuals.tres"
        filepath = os.path.join(visuals_dir, filename)
        r, g, b, a = accent_colors.get(i, (1, 1, 1, 1))
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(template.format(
                ship_name=ship_name,
                skin_name=skin_names.get(i, f"Стиль {i+1}"),
                r=r, g=g, b=b, a=a
            ))
        print(f"Created: {filename}")

print(f"\nDone! Created {len(ships) * 3} ShipSkinVisuals resources in: {visuals_dir}")