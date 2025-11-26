class_name World
extends Node3D

const SINBODY_SIZE := 32.0

var current_chunk_idx: Vector2i = Vector2i(0, 0)
var current_chunk: SinBody = null


func _process(_delta: float) -> void:
	var p: Vector3 = $Player.position
	$Z1.position = Vector3(roundf(p.x / SINBODY_SIZE) * SINBODY_SIZE, 0, roundf(p.z / SINBODY_SIZE) * SINBODY_SIZE)
	_update_visible_sinbody(p)


#var mouse_captured := false
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Ui.mouse_captured = true
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Ui.mouse_captured = false
func _unhandled_input(_event: InputEvent) -> void:
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
	#$HeightFloor.noise_init_heights()#5.0)
	#await $HeightFloor.terrain_ready
	$Terrain.build_initial_terrain()
	var p: Vector3 = $Player.position
	#print(Calc.get_ground_y(p.x, p.z, [$Player.get_rid()]))
	$Player.position.y = Calc.get_ground_y(p.x, p.z, [$Player.get_rid()]) + 2.0
	#print($Player.position)
	#print($Player.global_position)
	_update_visible_sinbody($Player.position)


func _update_visible_sinbody(player_pos: Vector3) -> void:
	var idx := Vector2i(roundi(player_pos.x / SINBODY_SIZE), roundi(player_pos.z / SINBODY_SIZE))
	if idx == current_chunk_idx and current_chunk:
		return
	# if current_chunk:
	# 	current_chunk.visible = false
	var terrain := $Terrain
	terrain.generate_chunks_around_index(idx.x, idx.y)
	if terrain.sinbodies.has(idx):
		current_chunk = terrain.sinbodies[idx]
		current_chunk.visible = true
		current_chunk_idx = idx
