extends StaticBody3D

@export var amplitude: float  = 8.0                  # ± height (metres)
@export var size:      Vector2i = Vector2i(256, 256)  # height‑map resolution

signal terrain_ready

const VERTICE_SPACING := 2.0

func noise_init_heights(s: float = amplitude) -> void:
	# 1. Build noise → Image --------------------------------------------------
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency  = 0.002
	noise.seed       = randi()

	var tex := NoiseTexture2D.new()
	tex.width      = size.x
	tex.height     = size.y
	tex.normalize  = true
	tex.noise      = noise
	await tex.changed

	var img := tex.get_image()
	img.convert(Image.FORMAT_RF)

	# 2. Feed heights into existing HeightMapShape3D --------------------------
	$Shape.shape.update_map_data_from_image(img, -s, s)

	# 3. Build CPU mesh that reuses the material set in the editor ------------
	$Mesh.mesh = build_heightmap_mesh(img, -s, s)
	$Mesh.position = Vector3((size.x - 1) * 0.5, 0.0, (size.y - 1) * 0.5)*-1
	# (material_override stays whatever you set in the Inspector)

	# 4. Signal that terrain is ready after physics has the collider ----------
	await get_tree().physics_frame
	emit_signal("terrain_ready")


func build_heightmap_mesh(img: Image, h_min: float, h_max: float) -> ArrayMesh:
	var w: int = img.get_width()
	var d: int = img.get_height()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var inv_w: float = 1.0 / float(w - 1)
	var inv_d: float = 1.0 / float(d - 1)

	for z_ in range(d - 1):
		for x_ in range(w - 1):
			var z := z_*VERTICE_SPACING
			var x := x_*VERTICE_SPACING
			# sample heights --------------------------------------------------
			var h00: float = h_min + (h_max - h_min) * img.get_pixel(x,     z).r
			var h10: float = h_min + (h_max - h_min) * img.get_pixel(x + 1, z).r
			var h01: float = h_min + (h_max - h_min) * img.get_pixel(x,     z + 1).r
			var h11: float = h_min + (h_max - h_min) * img.get_pixel(x + 1, z + 1).r

			# vertices --------------------------------------------------------
			var v00 := Vector3(x,     h00, z)
			var v10 := Vector3(x + 1, h10, z)
			var v01 := Vector3(x,     h01, z + 1)
			var v11 := Vector3(x + 1, h11, z + 1)

			# UVs -------------------------------------------------------------
			var uv00 := Vector2(float(x)       * inv_w, float(z)       * inv_d)
			var uv10 := Vector2(float(x + 1)   * inv_w, float(z)       * inv_d)
			var uv01 := Vector2(float(x)       * inv_w, float(z + 1)   * inv_d)
			var uv11 := Vector2(float(x + 1)   * inv_w, float(z + 1)   * inv_d)

			# first triangle (v00, v10, v01) ----------------------------------
			st.set_uv(uv00); st.add_vertex(v00)
			st.set_uv(uv10); st.add_vertex(v10)
			st.set_uv(uv01); st.add_vertex(v01)

			# second triangle (v10, v11, v01) ---------------------------------
			st.set_uv(uv10); st.add_vertex(v10)
			st.set_uv(uv11); st.add_vertex(v11)
			st.set_uv(uv01); st.add_vertex(v01)

	st.generate_normals()
	return st.commit()
