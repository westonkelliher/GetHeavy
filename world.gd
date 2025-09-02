class_name World
extends Node3D



#### Mouse Capture #####
#var mouse_captured := false
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Ui.mouse_captured = true
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Ui.mouse_captured = false
func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()


#### World Gen ####
func _ready() -> void:
	Calc.world_3d = get_world_3d()
	Calc.player = $Player
	$MyCamera.set_place($Player.get_cam_node())
	$MyCamera.set_springarm($Player.get_node("Q/SpringArm"))
	start_world()

func start_world() -> void:
	$HeightFloor.noise_init_heights()#5.0)
	await $HeightFloor.terrain_ready
	var p: Vector3 = $Player.position
	print(Calc.get_ground_y(p.x, p.z, [$Player.get_rid()]))
	$Player.position.y = Calc.get_ground_y(p.x, p.z, [$Player.get_rid()]) + 0.5
	print($Player.position)
	print($Player.global_position)
