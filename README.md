Molde — Godot 3D Starter

This repository contains a Godot 3D project with procedural terrain generation.

Included files:

- project.godot — project configuration
- scenes/Main.tscn — main scene with Camera3D
- scenes/Player.tscn — player scene (CharacterBody3D)
- scripts/main.gd — main scene script
- scripts/player.gd — player script
- scripts/terrain.gd — procedural terrain generation with plateau creation and height clamping
- .gitignore — recommended Git ignores for Godot

Features:

- Procedural terrain generation using FastNoiseLite
- Flat plateau areas for walkable zones
- Height clamping to prevent underground clipping
- Chunk-based terrain loading for performance
- Basic shader support

Quick start:

1. Open Godot and import the project folder
2. Open `scenes/Main.tscn` to view/edit the main scene
3. Run the project to see procedurally generated terrain

Terrain Parameters (in scripts/terrain.gd):

- CHUNK_SIZE: Size of terrain chunks (32)
- RESOLUTION: Vertex resolution per chunk (32)
- HEIGHT_SCALE: Overall terrain height variation (12.0)
- PLATEAU_HEIGHT: Height of flat plateau areas (2.0)
- MIN_HEIGHT: Minimum terrain height to prevent clipping (-4.0)
