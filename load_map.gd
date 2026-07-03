# load_map.gd — Godot 4.x
# Attach to a Node2D scene containing a TileMapLayer named "Ground".
# Reads map.json produced by geojson_to_tilemap.py and paints the campus.
#
# TileSet setup (one-time, in the editor):
#   1. Create a TileSet with tile size 16x16 on the "Ground" TileMapLayer.
#   2. Add an atlas source (id 0) pointing at your tileset PNG where the
#      first 6 tiles (left to right on row 0) are:
#      grass, building, path, road, water, field.
#   3. On the building (col 1) and water (col 4) tiles, add a physics
#      layer collision rectangle so the player collides with them.
# Later you can swap flat tiles for autotiled terrain without touching
# this script — only TILE_COORDS changes.

extends Node2D

const TILE_COORDS := {
	0: Vector2i(0, 0),  # grass
	1: Vector2i(1, 0),  # building
	2: Vector2i(2, 0),  # path
	3: Vector2i(3, 0),  # road
	4: Vector2i(4, 0),  # water
	5: Vector2i(5, 0),  # field
}
const ATLAS_SOURCE_ID := 0

@onready var ground: TileMapLayer = $Ground

func _ready() -> void:
	load_map("res://data/map.json")
	spawn_building_markers("res://data/buildings.json")

func load_map(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("map.json not found at " + path)
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	var tiles: Array = data["tiles"]
	for y in range(tiles.size()):
		var row: Array = tiles[y]
		for x in range(row.size()):
			var id := int(row[x])
			ground.set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, TILE_COORDS[id])
	print("Map loaded: %d x %d tiles" % [data["width"], data["height"]])

func spawn_building_markers(path: String) -> void:
	# Places an Area2D interaction zone at each named building centroid.
	# Connect these to your action system (the JS `doAction` equivalent).
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var buildings: Array = JSON.parse_string(file.get_as_text())
	var tile_px := ground.tile_set.tile_size.x
	for b in buildings:
		var area := Area2D.new()
		area.name = str(b["name"]).replace(" ", "_")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(tile_px * 6, tile_px * 6)
		shape.shape = rect
		area.add_child(shape)
		area.position = Vector2(
			(float(b["tile_x"]) + 0.5) * tile_px,
			(float(b["tile_y"]) + 0.5) * tile_px
		)
		area.set_meta("building_name", b["name"])
		add_child(area)
	print("Spawned %d building interaction zones" % buildings.size())
