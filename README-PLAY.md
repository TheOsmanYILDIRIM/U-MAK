# UÇMAK — Godot 4 first playable combat slice

Prototype stage, not full game. Godot 4.4.1, 2D renderer, offline player against enemy AI.

## Controls
- Select **SOL** or **SAĞ** then **HAT**; drag a line on the battlefield. Companies assume their slots.
- Select one blue company by tapping; choose **YÜRÜ** or **HÜCUM**, then tap destination.
- **TUT** holds the company in place; **GERİ** returns it to wing control and reserve.
- **İLERLE** shifts the selected wing's line and reserve positions in formation.
- One finger drags the camera normally; when HAT is active, it draws a line. Two fingers pan and pinch, mouse wheel zooms.
- **BİLGİ** shows a rolling field report. **⏸** pauses the battle in offline mode.

## Verification
```
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_sim.gd
godot --headless --path . --quit-after 30
```

CI workflow runs headless checks on pushed experiment branches. This first slice does not include networking, Android APK export, full logistics, espionage, weather or verified 1402 unit catalog. Those remain required for the larger UÇMAK game.
