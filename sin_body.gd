@tool
class_name SinBody
extends StaticBody3D

#const VERTICE_SPACING := 0.5
const AMPLITUDE := 3.0
const WIDTH := 32
const SIZE: Vector2i = Vector2i(WIDTH+1, WIDTH+1)
const STITCH_DIST: int = 10
#
const MESH_OFFSET_Y := 0

func _ready() -> void:
	$Shape.shape = build_collision_shape(position.x, position.z)
	build_mesh($Shape.shape.map_data)

func build_collision_shape(offset_x: float, offset_y: float) -> HeightMapShape3D:
	var heights := PackedFloat32Array()
	heights.resize(SIZE.x*SIZE.y)
	#
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			heights[y * SIZE.x + x] = height_equation(x + offset_x, y + offset_y) * AMPLITUDE
	#
	var new_shape := HeightMapShape3D.new()
	new_shape.map_width = SIZE.x
	new_shape.map_depth = SIZE.y
	new_shape.map_data = heights
	#
	return new_shape

# pass in world x,y
func height_equation(x: float, y: float) -> float:
	var v := Vector2(x,y)
	var b1 := noise_equation(x, y)
	var v_course := v.rotated(PI/4)/6.0 + Vector2(20,20)
	var b2 := noise_equation(v_course.x, v_course.y)
	var v_fine := v.rotated(PI/3)*2.0  + Vector2(-20,20)
	var b3 := noise_equation(v_fine.x, v_fine.y)
	return b1 + 1.8*b2 + 0.15*b3#*max(0, sqrt(b1))

func noise_equation(x: float, y: float) -> float:
	var base := sin(x/5) + 0.05*sin(x/7+.4) + 0.05*sin(x/1.4+.8) + 0.4*sin(y/3) \
		+ 0.2*sin(x/4+y/2) + 0.2*sin(x/2-y/4) + 1.0*cos(x/20+y/25)
	return base


func build_mesh(map_data: PackedFloat32Array) -> void:
	#var vertices := height_map_to_vectors(map_data)
	#var normals := height_map_to_normals(map_data)
	#
	#
	var arrays := build_mesh_arrays(map_data)#[]
	#arrays.resize(Mesh.ARRAY_MAX)
	#arrays[Mesh.ARRAY_VERTEX] = vertices
	#arrays[Mesh.ARRAY_NORMAL] = normals
	# Create the Mesh.
	var arr_mesh := ArrayMesh.new()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh.surface_set_material(0, material)
	var meshIns := MeshInstance3D.new()
	meshIns.mesh = arr_mesh
	add_child(meshIns)
	#return arr_mesh


func build_mesh_arrays(heights: PackedFloat32Array) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var green1 := Color(0.03, 0.94, 0.03)
	var green2 := Color(0.0, 0.60, 0.0)
	var h_i := 0
	for z in range(SIZE.y-1):
		for x in range(SIZE.x-1): # I'm assuming x-major order
			var color := green1
			if (x%2 == z%2):
				color = green2
			#
			var vx := x-16
			var vz := z-16
			var h1 := get_height(x,z)
			var v1 := Vector3(vx, h1-MESH_OFFSET_Y, vz)
			var h2 := get_height(x+1,z)
			var v2 := Vector3(vx+1, h2-MESH_OFFSET_Y, vz)
			var h3 := get_height(x,z+1)
			var v3 := Vector3(vx, h3-MESH_OFFSET_Y, vz+1)
			var h4 := get_height(x+1,z+1)
			var v4 := Vector3(vx+1, h4-MESH_OFFSET_Y, vz+1)
			#
			h_i += 1
			#
			var n123 := (v1-v2).cross(v3-v1)
			var n432 := (v4-v3).cross(v2-v4)
			#
			vertices.push_back(v1)
			vertices.push_back(v2)
			vertices.push_back(v3)
			vertices.push_back(v4)
			vertices.push_back(v3)
			vertices.push_back(v2)
			#
			normals.push_back(n123)
			normals.push_back(n123)
			normals.push_back(n123)
			normals.push_back(n123)
			normals.push_back(n123)
			normals.push_back(n123)
			#normals.push_back(n432)
			#normals.push_back(n432)
			#normals.push_back(n432)
			#
			colors.push_back(color)
			colors.push_back(color)
			colors.push_back(color)
			colors.push_back(color)
			colors.push_back(color)
			colors.push_back(color)
			#
	#
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	#
	return arrays


func get_height(x: int, y: int) -> float:
	return $Shape.shape.map_data[y*SIZE.x + x]
	
