
# world3d.gd — Godot 4.x (v4)
# Same campus builder as v3, now editor-friendly:
#   - Tick "Rebuild In Editor" in the Inspector to build the campus
#     inside the editor so you can hand-place walls/gates against it.
#   - Everything generated lives under a "Generated" child node.
#     Rebuilding wipes ONLY that node. Player3D, Handmade, and anything
#     else you add by hand are never touched.

@tool
extends Node3D

@export var rebuild_in_editor: bool = false:
	set(_v):
		rebuild_in_editor = false
		if Engine.is_editor_hint() and is_inside_tree():
			_full_build()

const COL := {
	"ground": Color(0.34, 0.53, 0.26),
	"field":  Color(0.47, 0.72, 0.36),
	"road":   Color(0.16, 0.16, 0.175),
	"path":   Color(0.72, 0.70, 0.66),
}
const WALLS := [
	Color("#C96F4A"), Color("#D98E5F"), Color("#B96A50"),
	Color("#D4A55E"), Color("#C25B4E"), Color("#D9B380"),
]
const ROOF_DARKEN := 0.55
const TREE_COUNT := 350

var _gen: Node3D
var _window_tex: ImageTexture
var _noise_tex: NoiseTexture2D
var _bpolys: Array = []
var _wpolys: Array = []
var _ribbons: Array = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		_full_build()

func _full_build() -> void:
	var old := get_node_or_null("Generated")
	if old != null:
		remove_child(old)
		old.free()
	_gen = Node3D.new()
	_gen.name = "Generated"
	add_child(_gen)
	_window_tex = _make_window_texture()
	_noise_tex = _make_noise_texture()
	_bpolys.clear()
	_wpolys.clear()
	_ribbons.clear()
	_add_ground_and_light()
	_build_campus("res://data/campus3d.json")

# ------------------------------ textures ------------------------------
func _make_window_texture() -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, true, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1))
	var win := Color(0.18, 0.24, 0.34)
	var sill := Color(0.75, 0.75, 0.75)
	for wy in range(2):
		for wx in range(2):
			var x0 := 8 + wx * 32
			var y0 := 6 + wy * 32
			for py in range(y0, y0 + 16):
				for px in range(x0, x0 + 14):
					img.set_pixel(px, py, win)
			for px in range(x0 - 1, x0 + 15):
				img.set_pixel(px, y0 + 16, sill)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _make_noise_texture() -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.frequency = 0.06
	var nt := NoiseTexture2D.new()
	nt.noise = n
	nt.seamless = true
	nt.width = 256
	nt.height = 256
	return nt

# ------------------------------ materials -----------------------------
func _flat_mat(c: Color, noisy := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if noisy:
		m.albedo_texture = _noise_tex
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.06, 0.06, 0.06)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	return m

func _wall_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.albedo_texture = _window_tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.25, 0.25, 0.25)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	return m

func _water_mat() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float w1 = sin(wpos.x * 0.55 + TIME * 1.3);
	float w2 = sin(wpos.z * 0.42 - TIME * 0.9);
	float w3 = sin((wpos.x + wpos.z) * 0.9 + TIME * 0.6);
	float m = 0.5 + 0.5 * (w1 + w2 + w3) / 3.0;
	vec3 deep = vec3(0.13, 0.35, 0.58);
	vec3 shallow = vec3(0.30, 0.62, 0.84);
	ALBEDO = mix(deep, shallow, m);
	ROUGHNESS = 0.12;
	SPECULAR = 0.65;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

func _ground_blend_mat() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

group_uniforms layers;
uniform sampler2D mud_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D brick_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D brick_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D brick_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaves_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaves_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaves_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_rough : hint_default_white, filter_linear_mipmap, repeat_enable;

group_uniforms tint;
uniform vec4 mud_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 brick_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 leaves_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rock_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

group_uniforms patches;
uniform float texture_scale = 0.15;
uniform float macro_scale = 80.0;
uniform float mid_scale = 14.0;
uniform float mid_influence : hint_range(0.0, 1.0) = 0.28;
uniform float brick_threshold : hint_range(0.0, 1.0) = 0.52;
uniform float leaves_threshold : hint_range(0.0, 1.0) = 0.70;
uniform float rock_threshold : hint_range(0.0, 1.0) = 0.86;
uniform float blend_width : hint_range(0.001, 0.3) = 0.06;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// smooth bilinear value noise, period-free (not tileable but continuous everywhere)
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 wxz = world_pos.xz;

	// macro noise picks the biome patch, mid noise roughs up its edges
	float macro_n = value_noise(wxz / macro_scale);
	float mid_n = value_noise(wxz / mid_scale + vec2(31.7, 5.2));
	float n = clamp(macro_n + (mid_n - 0.5) * mid_influence, 0.0, 1.0);

	vec2 uv = wxz * texture_scale;

	vec4 mud_a = texture(mud_albedo, uv) * mud_tint;
	vec4 brick_a = texture(brick_albedo, uv) * brick_tint;
	vec4 leaves_a = texture(leaves_albedo, uv) * leaves_tint;
	vec4 rock_a = texture(rock_albedo, uv) * rock_tint;

	vec3 mud_n = texture(mud_normal, uv).rgb;
	vec3 brick_n = texture(brick_normal, uv).rgb;
	vec3 leaves_n = texture(leaves_normal, uv).rgb;
	vec3 rock_n = texture(rock_normal, uv).rgb;

	float mud_r = texture(mud_rough, uv).r;
	float brick_r = texture(brick_rough, uv).r;
	float leaves_r = texture(leaves_rough, uv).r;
	float rock_r = texture(rock_rough, uv).r;

	float w_brick = smoothstep(brick_threshold - blend_width, brick_threshold + blend_width, n);
	float w_leaves = smoothstep(leaves_threshold - blend_width, leaves_threshold + blend_width, n);
	float w_rock = smoothstep(rock_threshold - blend_width, rock_threshold + blend_width, n);

	vec4 albedo = mix(mud_a, brick_a, w_brick);
	albedo = mix(albedo, leaves_a, w_leaves);
	albedo = mix(albedo, rock_a, w_rock);

	vec3 nrm = mix(mud_n, brick_n, w_brick);
	nrm = mix(nrm, leaves_n, w_leaves);
	nrm = mix(nrm, rock_n, w_rock);

	float rough = mix(mud_r, brick_r, w_brick);
	rough = mix(rough, leaves_r, w_leaves);
	rough = mix(rough, rock_r, w_rock);

	ALBEDO = albedo.rgb;
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = 1.0;
	ROUGHNESS = rough;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh

	var base := "res://assets/ground/"
	var layers := ["mud", "brick_earth", "leaves", "rock"]
	var params := ["mud", "brick", "leaves", "rock"]
	for i in range(layers.size()):
		var dir: String = base + layers[i] + "/"
		var prefix: String = params[i]
		if ResourceLoader.exists(dir + "diff.jpg"):
			m.set_shader_parameter(prefix + "_albedo", load(dir + "diff.jpg"))
		if ResourceLoader.exists(dir + "normal.jpg"):
			m.set_shader_parameter(prefix + "_normal", load(dir + "normal.jpg"))
		if ResourceLoader.exists(dir + "rough.jpg"):
			m.set_shader_parameter(prefix + "_rough", load(dir + "rough.jpg"))

	return m

# ------------------------------ custom textures ------------------------------
func _pbr_mat(albedo_path: String, normal_path: String, rough_path: String, uv_scale: float = 0.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	
	if ResourceLoader.exists(albedo_path):
		m.albedo_texture = load(albedo_path)
	
	if ResourceLoader.exists(normal_path):
		m.normal_enabled = true
		m.normal_texture = load(normal_path)
		
	if ResourceLoader.exists(rough_path):
		m.roughness_texture = load(rough_path)
	
	# Triplanar mapping is required for generated CSGPolygons so textures tile properly
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	return m

# ------------------------------ geometry ------------------------------
func _flat_poly(points: Array, y: float, mat: Material) -> void:
	var node := CSGPolygon3D.new()
	var pts := PackedVector2Array()
	for p in points:
		pts.append(Vector2(p[0], p[1]))
	node.polygon = pts
	node.depth = 0.15
	node.material = mat
	node.rotation_degrees = Vector3(90, 0, 0)
	node.position = Vector3(0, y, 0)
	_gen.add_child(node)

func _build_campus(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("campus3d.json not found at " + path)
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())

	var water_material := _water_mat()
	var ground_blend_material := _ground_blend_mat()
	for fld in data.get("fields", []):
		_flat_poly(fld, 0.03, ground_blend_material)
	for w in data.get("water", []):
		_flat_poly(w, 0.06, water_material)
		_wpolys.append(w)
		
	# Create the materials using the exact paths from your FileSystem dock
	var asphalt_mat = _pbr_mat(
		"res://assets/asphalt/asphalt_02_diff_1k.jpg",
		"res://assets/asphalt/asphalt_02_nor_gl_1k.jpg",
		"res://assets/asphalt/asphalt_02_rough_1k.jpg",
		0.2 # Adjust this number to scale the asphalt texture up or down
	)
	
	var brick_mat = _pbr_mat(
		"res://assets/brkpavement/brick_pavement_03_diff_1k.jpg",
		"res://assets/brkpavement/brick_pavement_03_nor_gl_1k.jpg",
		"res://assets/brkpavement/brick_pavement_03_rough_1k.jpg",
		0.3 # Adjust this number to scale the brick texture up or down
	)

	# Apply custom materials to ribbons
	for r in data.get("ribbons", []):
		var kind: String = r["kind"]
		var mat: Material
		
		if kind == "road":
			mat = asphalt_mat
		elif kind == "path":
			mat = brick_mat
		else:
			mat = _flat_mat(COL.get(kind, Color.WHITE), true)
			
		_flat_poly(r["points"], 0.10 if kind == "road" else 0.08, mat)
		_ribbons.append(r["points"])

	var count := 0
	for b in data.get("buildings", []):
		var h := float(b["height"])
		_bpolys.append(b["points"])

		var model_path := "res://models/%s.glb" % str(b["name"]).replace(" ", "_")
		if b["name"] == "Aurobindo Bhavan":
			pass # placed by hand under Handmade — no auto model, no placeholder box
		elif b["name"] != "" and ResourceLoader.exists(model_path):
			var scene: PackedScene = load(model_path)
			var inst := scene.instantiate()
			var c := _centroid(b["points"])
			inst.position = Vector3(c.x, 0, c.y)
			_gen.add_child(inst)
		else:
			var pts := PackedVector2Array()
			for p in b["points"]:
				pts.append(Vector2(p[0], p[1]))
			var wall_color: Color = WALLS[hash(str(b["name"]) + str(count)) % WALLS.size()]

			var body := CSGPolygon3D.new()
			body.polygon = pts
			body.depth = h
			body.material = _wall_mat(wall_color)
			body.rotation_degrees = Vector3(90, 0, 0)
			body.position = Vector3.ZERO
			body.use_collision = true
			_gen.add_child(body)

			var roof := CSGPolygon3D.new()
			roof.polygon = pts
			roof.depth = 0.5
			roof.material = _flat_mat(wall_color.darkened(ROOF_DARKEN))
			roof.rotation_degrees = Vector3(90, 0, 0)
			roof.position = Vector3(0, h, 0)
			_gen.add_child(roof)
		count += 1

		if b["name"] != "":
			var c2 := _centroid(b["points"])
			var area := Area3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(18, 8, 18)
			shape.shape = box
			area.add_child(shape)
			area.position = Vector3(c2.x, 2, c2.y)
			var building_name: String = b["name"]
			area.set_meta("building_name", building_name)
			area.body_entered.connect(func(body: Node3D) -> void:
				if body.has_method("set_current_building"):
					body.set_current_building(building_name)
			)
			area.body_exited.connect(func(body: Node3D) -> void:
				if body.has_method("clear_current_building"):
					body.clear_current_building(building_name)
			)
			_gen.add_child(area)

			var label := Label3D.new()
			label.text = b["name"]
			label.font_size = 96
			label.pixel_size = 0.02
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = Color(1, 1, 0.9)
			label.outline_size = 24
			label.position = Vector3(c2.x, h + 3.0, c2.y)
			_gen.add_child(label)
	print("Built %d buildings" % count)

	_scatter_trees(data.get("bounds", {}))
	_scatter_grass(data.get("fields", []))
	
const GRASS_PER_FIELD := 4000

func _scatter_grass(fields: Array) -> void:
	var mesh_path := "res://assets/grass_blades/grass.res"
	var shader_path := "res://assets/grass_blades/grass.gdshader"
	if not ResourceLoader.exists(mesh_path):
		push_warning("grass.res not found — skipping grass")
		return
	var blade_mesh: Mesh = load(mesh_path)

	var mat: Material
	if ResourceLoader.exists(shader_path):
		var sm := ShaderMaterial.new()
		sm.shader = load(shader_path)
		sm.set_shader_parameter("color", Color(0.18, 0.42, 0.16))
		sm.set_shader_parameter("color2", Color(0.56, 0.75, 0.30))
		mat = sm
	else:
		var stdm := StandardMaterial3D.new()
		stdm.albedo_color = Color(0.30, 0.55, 0.22)
		stdm.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat = stdm

	var total := 0
	for poly in fields:
		if poly.size() < 3:
			continue
		var minx := INF
		var maxx := -INF
		var minz := INF
		var maxz := -INF
		for p in poly:
			minx = min(minx, p[0]); maxx = max(maxx, p[0])
			minz = min(minz, p[1]); maxz = max(maxz, p[1])

		var spots: Array[Vector3] = []
		var attempts := 0
		while spots.size() < GRASS_PER_FIELD and attempts < GRASS_PER_FIELD * 8:
			attempts += 1
			var x := randf_range(minx, maxx)
			var z := randf_range(minz, maxz)
			if _point_in_poly(x, z, poly) and not _blocked(x, z):
				spots.append(Vector3(x, 0.05, z))
		if spots.is_empty():
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = blade_mesh
		mm.instance_count = spots.size()
		for i in range(spots.size()):
			var yaw := randf() * TAU
			var s := randf_range(0.8, 1.3)
			var b := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
			mm.set_instance_transform(i, Transform3D(b, spots[i]))

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		_gen.add_child(mmi)
		total += spots.size()
	print("Planted %d grass blades" % total)
	
	
func _centroid(points: Array) -> Vector2:
	var cx := 0.0
	var cz := 0.0
	for p in points:
		cx += p[0]
		cz += p[1]
	return Vector2(cx / points.size(), cz / points.size())

# ------------------------------- trees --------------------------------
func _point_in_poly(x: float, z: float, poly: Array) -> bool:
	var inside := false
	var j := poly.size() - 1
	for i in range(poly.size()):
		var xi: float = poly[i][0]
		var zi: float = poly[i][1]
		var xj: float = poly[j][0]
		var zj: float = poly[j][1]
		if ((zi > z) != (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi):
			inside = not inside
		j = i
	return inside

func _blocked(x: float, z: float) -> bool:
	for poly in _bpolys:
		if _point_in_poly(x, z, poly):
			return true
	for poly in _wpolys:
		if _point_in_poly(x, z, poly):
			return true
	for quad in _ribbons:
		if _point_in_poly(x, z, quad):
			return true
	return false

const TREE_SCALE := 5.0
const TREE_MODELS := [
	"res://assets/nature/tree_default.glb",
	"res://assets/nature/tree_oak.glb",
	"res://assets/nature/tree_detailed.glb",
	"res://assets/nature/tree_tall.glb",
]

func _extract_mesh(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path)
	var inst := scene.instantiate()
	var found: Mesh = null
	var stack: Array = [inst]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh != null:
			found = n.mesh
			break
		for child in n.get_children():
			stack.append(child)
	inst.free()
	return found

func _scatter_trees(bounds: Dictionary) -> void:
	if bounds.is_empty():
		return
	var min_x: float = bounds["min_x"]
	var max_x: float = bounds["max_x"]
	var min_z: float = bounds["min_z"]
	var max_z: float = bounds["max_z"]

	# load available tree meshes
	var meshes: Array = []
	for p in TREE_MODELS:
		var m := _extract_mesh(p)
		if m != null:
			meshes.append(m)
	if meshes.is_empty():
		push_warning("no tree models found in assets/nature — check filenames")
		return

	# one bucket of positions per mesh
	var buckets: Array = []
	for i in range(meshes.size()):
		buckets.append([])

	var placed := 0
	var attempts := 0
	while placed < TREE_COUNT and attempts < TREE_COUNT * 12:
		attempts += 1
		var x := randf_range(min_x, max_x)
		var z := randf_range(min_z, max_z)
		if not _blocked(x, z):
			var s := randf_range(0.8, 1.6) * TREE_SCALE
			var yaw := randf() * TAU
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
			buckets[randi() % meshes.size()].append(
				Transform3D(basis, Vector3(x, 0, z)))
			placed += 1

	for i in range(meshes.size()):
		var list: Array = buckets[i]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[i]
		mm.instance_count = list.size()
		for j in range(list.size()):
			mm.set_instance_transform(j, list[j])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		_gen.add_child(mmi)
		print("Planted %d of %s" % [list.size(), TREE_MODELS[i].get_file()])

# --------------------------- ground & light ---------------------------
func _add_ground_and_light() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3000, 3000)
	ground.mesh = plane
	ground.material_override = _ground_blend_mat()
	ground.position = Vector3(600, 0, 600)
	_gen.add_child(ground)

	var gbody := StaticBody3D.new()
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(3000, 1, 3000)
	gshape.shape = gbox
	gbody.add_child(gshape)
	gbody.position = Vector3(600, -0.5, 600)
	_gen.add_child(gbody)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	_gen.add_child(sun)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.70, 0.84, 0.96)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.97, 0.92)
	e.ambient_light_energy = 0.6
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.12
	e.adjustment_contrast = 1.03
	e.fog_enabled = true
	e.fog_light_color = Color(0.76, 0.83, 0.92)
	e.fog_density = 0.0001
	env.environment = e
	_gen.add_child(env)
