extends Camera3D

const MOUSE_SENSITIVITY := 0.0055

var place: Node3D = null
var springarm: SpringArm3D = null

func set_place(p: Node3D) -> void:
	place = p
func set_springarm(sa: SpringArm3D) -> void:
	springarm = sa

func _process(delta: float) -> void:
	#if !place:
		#return
	global_position = place.global_position
	global_rotation = place.global_rotation

##### camera movement ####
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Ui.mouse_captured:
		springarm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		springarm.rotation_degrees.x = clamp(springarm.rotation_degrees.x, -120.0, 70.0)
		springarm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
