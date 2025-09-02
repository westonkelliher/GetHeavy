class_name Player
extends CharacterBody3D


const HIGH_GRAV := 10.0
const LOW_GRAV := 3.0

const HIGH_FRIC := 0.005
const LOW_FRIC := 0.1

const RELEASE_BOOST := 0.4

var is_heavy := false

func _ready() -> void:
	print('ready')

func get_cam_node() -> Node3D:
	return $Q/SpringArm/Cam

func _process(delta: float) -> void:
	# set debug ray pointing down gradient
	#print(global_position)
	#$Debug/Ray.global_position = Vector3($M.global_position.x, .3, $M.global_position.z)
	pass



func _input(event: InputEvent) -> void:
	const rb = RELEASE_BOOST
	if Input.is_action_just_pressed("heavy"):
		is_heavy = true
		velocity *= velocity.length() / (velocity.length() + rb)
	if Input.is_action_just_released("heavy"):
		is_heavy = false
		velocity *= (velocity.length() + rb) / velocity.length()


#### Physics ####
func _physics_process(delta: float) -> void:
	#velocity = Vector3.FORWARD
	# TODO: handle momentum change when hitting the floor
	phys_snap_help(delta)
	phys_grav(delta)
	move_and_slide()
	#if is_on_floor():
		#apply_floor_snap()
	phys_friction(delta)

func phys_snap_help(delta: float) -> void:
	if is_heavy:
		self.floor_snap_length = 0.4
	elif velocity.normalized().dot(Vector3.DOWN) > 0.3:
		self.floor_snap_length = 0.02
	else:
		self.floor_snap_length = 0.0

func phys_grav(delta: float) -> void:
	var grav := LOW_GRAV
	if is_heavy:
		grav = HIGH_GRAV
	if not is_on_floor():
		print('airborn')
		velocity += Vector3.DOWN*grav*delta
	else:
		var downhill := Calc.get_downward_vector(global_position.x, global_position.z)
		if downhill.length() == 0:
			return
		var dh_acc := downhill * downhill.dot(Vector3.DOWN) * grav
		$Debug/Ray.target_position = dh_acc * 0.5/sqrt(dh_acc.length())
		velocity += dh_acc * delta

func phys_friction(delta: float) -> void:
	var fric := LOW_FRIC
	if is_heavy:
		fric = HIGH_FRIC
	var q := pow(1.0-fric, delta)
	velocity *= q



#### Debug ####
func set_debug_points(a: Array) -> void:
	for i in range(len(a)):
		$Debug/Marks.get_child(i).global_position = a[i]
		#print($Debug/Marks/Q1.position)
		#print($Debug/Marks/Q1.global_position)
