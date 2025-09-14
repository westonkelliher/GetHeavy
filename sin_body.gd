@tool
class_name SinBody
extends StaticBody3D

#const VERTICE_SPACING := 0.5
const AMPLITUDE := 3.0
const WIDTH := 32
const SIZE: Vector2i = Vector2i(WIDTH+1, WIDTH+1)
const STITCH_DIST: int = 10


func _ready() -> void:
	$Shape.shape = build_collision_shape(position.x, position.z)

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
	var v_fine := v.rotated(PI/3)*2.5  + Vector2(-20,20)
	var b3 := noise_equation(v_fine.x, v_fine.y)
	return b1 + 1.8*b2 + 0.3*b3*max(0, sqrt(b1))

func noise_equation(x: float, y: float) -> float:
	var base := sin(x/5) + 0.05*sin(x/7+.4) + 0.05*sin(x/1.4+.8) + 0.4*sin(y/3) \
		+ 0.2*sin(x/4+y/2) + 0.2*sin(x/2-y/4) + 1.0*cos(x/20+y/25)
	return base
