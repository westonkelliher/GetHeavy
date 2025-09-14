class_name Player
extends CharacterBody3D


const HIGH_GRAV := 20.0
const LOW_GRAV := 3.0

const HIGH_FRIC := 0.005
const LOW_FRIC := 0.1

const RELEASE_BOOST_FLAT := 0.4
const RELEASE_BOOST_RATIO := 0.2
const RELEASE_LIFT := 1.0 # dotted with up vel

var is_heavy := false
var grounded := false

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
	const rbf := RELEASE_BOOST_FLAT
	const rbr := RELEASE_BOOST_RATIO
	const rl := RELEASE_LIFT
	if Input.is_action_just_pressed("heavy"):
		is_heavy = true
		velocity *= (1.0 - rbr)
		velocity *= velocity.length() / (velocity.length() + rbf)
	if Input.is_action_just_released("heavy"):
		is_heavy = false
		velocity *= 1/(1-rbr)
		velocity *= (velocity.length() + rbf) / velocity.length()
		velocity += Vector3.UP * max(0, Vector3.UP.dot(velocity.normalized())) * rl


#### Physics ####
func _physics_process(delta: float) -> void:
	#velocity = Vector3.FORWARD
	# TODO: handle momentum change when hitting the floor
	phys_snap_help(delta)
	#self.floor_snap_length = 0.1
	phys_grav(delta)
	phys_sloping(delta) # lift a bit if we go convex
	var vy := velocity.y
	move_and_slide()
	velocity.y = vy
	#if is_on_floor():
		#apply_floor_snap()
	phys_friction(delta)


#func phys_move_and_slide(delta: float) -> void:
	#$Cast.target_position = velocity
	#if $Cast.is_colliding():
		

func phys_snap_help(delta: float) -> void:
	if is_heavy:
		self.floor_snap_length = 0.4
	elif velocity.normalized().dot(Vector3.DOWN) > 0.3:
		self.floor_snap_length = 0.05
	else:
		self.floor_snap_length = 0.0

func phys_sloping(delta: float) -> void:
	var v := velocity
	v = 0.1*v/sqrt(v.length())
	var p := position
	var slope1 := Calc.get_ground_slope_in_dir_at(v.x, v.z, p.x, p.z)
	var slope2 := Calc.get_ground_slope_in_dir_at(v.x, v.z, p.x+v.x, p.z+v.z)
	$Debug/Ray2.target_position = v*5.0
	var m: StandardMaterial3D = $Debug/Ray2/C.mesh.material
	if slope1 < slope2:
		m.albedo_color = Color(1.0, 0.0, 0.0)
	else:
		m.albedo_color = Color(0.5, 0.5, 0.5)
		

func phys_grav(delta: float) -> void:
	var grav := LOW_GRAV
	if is_heavy:
		grav = HIGH_GRAV
	if not is_on_floor():
		velocity += Vector3.DOWN*grav*delta
	else:
		var downhill := Calc.get_downward_vector(global_position.x, global_position.z)
		if downhill.length() == 0:
			return
		var dh_acc := downhill * downhill.dot(Vector3.DOWN) * grav
		$Debug/Ray.target_position = dh_acc * 0.5/sqrt(dh_acc.length())
		print('---')
		print(velocity.y)
		velocity += dh_acc * delta
		print(velocity.y)

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
