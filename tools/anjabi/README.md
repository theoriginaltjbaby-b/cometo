# Anjabi tileset pipeline

Turns the supplied art in `art/source/anjabi_v0.1/` (never edited) into the TileSet
library in `art/tilesets/anjabi/` and the test scene.

```bash
python3 tools/anjabi/prepare.py . [preview_folder]        # needs Pillow and numpy
$GODOT --headless --path . --import
$GODOT --headless --path . -s tools/build_anjabi_tileset.gd
```

- `manifest.py`: every sprite's name, category, source box, size and footprint. Edit
  this to add, rename, resize or re-flag a piece.
- `prepare.py`: seamless 32 px ground tiles, sprite extraction, grid alignment, atlas
  packing, palette reduction. Writes the PNGs and `anjabi_tiles.json`.
- `components.py`: finds sprite boxes in a new atlas:
  `python3 tools/anjabi/components.py atlas.png labelled.png 3`
- `tools/build_anjabi_tileset.gd`: builds the six `.tres` TileSets and
  `world2d/maps/Anjabi_Tileset_Test.tscn`. It overwrites both; hand edits made in the
  Godot editor to those files are lost on a rebuild, so copy the scene before painting.
