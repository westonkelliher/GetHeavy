extends StaticBody3D

@export var amplitude: float  = 12.0                  # ± height (metres)
@export var size:      Vector2i = Vector2i(256, 256)  # height‑map resolution

signal terrain_ready

const VERTICE_SPACING := 0.5

func noise_init_heights(s: float = amplitude) -> void:
	# 1. Build noise → Image --------------------------------------------------
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency  = 0.01
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
	$Shape.scale = Vector3.ONE*VERTICE_SPACING

	# 3. Build CPU mesh that reuses the material set in the editor ------------
	$Mesh.mesh = build_heightmap_mesh(img, -s, s)
	const sconch := 0.5*VERTICE_SPACING
	$Mesh.position = Vector3((size.x - 1) * sconch, 0.0, (size.y - 1) * sconch)*-1
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

	for z_i in range(d - 1):
		for x_i in range(w - 1):
			var z := z_i*VERTICE_SPACING
			var x := x_i*VERTICE_SPACING
			var VS := VERTICE_SPACING
			# sample heights --------------------------------------------------
			var h00: float = h_min + (h_max - h_min) * img.get_pixel(x_i,     z_i).r
			var h10: float = h_min + (h_max - h_min) * img.get_pixel(x_i + 1, z_i).r
			var h01: float = h_min + (h_max - h_min) * img.get_pixel(x_i,     z_i + 1).r
			var h11: float = h_min + (h_max - h_min) * img.get_pixel(x_i + 1, z_i + 1).r

			# vertices --------------------------------------------------------
			var v00 := Vector3(x,     h00*VS, z)
			var v10 := Vector3(x + VS, h10*VS, z)
			var v01 := Vector3(x,     h01*VS, z + VS)
			var v11 := Vector3(x + VS, h11*VS, z + VS)

			# UVs -------------------------------------------------------------
			var uv00 := Vector2(float(x)       * inv_w, float(z)       * inv_d)
			var uv10 := Vector2(float(x + VS)   * inv_w, float(z)       * inv_d)
			var uv01 := Vector2(float(x)       * inv_w, float(z + VS)   * inv_d)
			var uv11 := Vector2(float(x + VS)   * inv_w, float(z + VS)   * inv_d)

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
