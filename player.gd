class_name Player
extends CharacterBody3D


const HIGH_GRAV := 20.0
const LOW_GRAV := 5.0

const HIGH_FRIC := 0.005
const LOW_FRIC := 0.1

const RELEASE_BOOST_FLAT := 0.4
const RELEASE_BOOST_RATIO := 0.1
const RELEASE_LIFT := 1.0 # dotted with up vel

var is_heavy := false
var grounded := false
var GROUND_CAST_ADJUST := Vector3(0,-0.1,0) # maybe don't need

var target_scale := 1.0
var current_scale := 1.0

# if the leftover component of velocity is ever larger than the below number after 
# collision, then we should continue calculating collision again in the same frame until
# the remainder of velocity is less than this number
# TODO: when implementing this, make sure to go along the normal this amount so that we 
# don't infinite loop on an immediate collision
var DOUBLE_CALC_COLLISION_DISTANCE := 0.45

# TODO: decide on angle where we don't lose any speed when going through a bend

var saved_albedo := Vector3(0,0,0)

func _ready() -> void:
	var c: Color = $Mesh.mesh.material.albedo_color
	saved_albedo = Vector3(c.a, c.g, c.b)
	#print('player ready')

func get_cam_node() -> Node3D:
	return $Q/SpringArm/Cam

func _process(delta: float) -> void:
	var s := current_scale
	$Mesh.scale = Vector3(s, s, s)
	#var calc_c := saved_albedo - (1-s)*Vector3.ONE
	var calc_c := saved_albedo.move_toward(Vector3(0.1, 0.1, 0.1), sqrt(1-s))
	$Mesh.mesh.material.albedo_color = Color(calc_c.x, calc_c.y, calc_c.z)
	if grounded:
		$Debug/G.mesh.material.albedo_color = Color(0.7, 0.7, 0.2, 0.4)
	else:
		$Debug/G.mesh.material.albedo_color = Color(0.2, 0.2, 0.7, 0.7)



func _input(event: InputEvent) -> void:
	const rbf := RELEASE_BOOST_FLAT
	const rbr := RELEASE_BOOST_RATIO
	const rl := RELEASE_LIFT
	if Input.is_action_just_pressed("heavy"):
		is_heavy = true
		velocity *= (1.0 - rbr)
		velocity *= velocity.length() / (velocity.length() + rbf)
		target_scale = 0.75
		var s := target_scale
		$Shape.shape.radius = s/2
		$Cast.shape.radius = s/2
	if Input.is_action_just_released("heavy"):
		is_heavy = false
		velocity *= 1/(1-rbr)
		velocity *= (velocity.length() + rbf) / velocity.length()
		velocity += Vector3.UP * max(0, Vector3.UP.dot(velocity.normalized())) * rl
		target_scale = 1.0
		var s := target_scale
		$Shape.shape.radius = s/2
		$Cast.shape.radius = s/2


#### Physics ####
func _physics_process(delta: float) -> void:
	#if velocity.length() > 3:
		#velocity *= 0.95
	#set_scale_size(current_scale)
	phys_grav(delta)
	phys_sloping(delta) # lift a bit if we go convex
	#var vy := velocity.y
	phys_move_and_slide(delta)
	#velocity.y = vy
	phys_friction(delta)
	current_scale = move_toward(current_scale, target_scale, 2.0*delta)
	#print(current_scale)
	

# TODO: do the collision update when we change targ position or not until next frame?
func phys_move_and_slide(delta: float) -> void:
	$Cast.target_position = velocity*delta
	$Cast.force_shapecast_update() # the shapecast is not "enabled" so this is the only callsite

	# didnt hit anything
	if not $Cast.is_colliding():
		position += velocity*delta
		# check if we're grounded
		$SnapCast.target_position = Vector3.UP*0.1
		$SnapCast.target_position = -$SnapCast.position*1.1
		$SnapCast.force_shapecast_update()
		if not $SnapCast.is_colliding():
			grounded=false
		return
	var c_point: Vector3 = $Cast.get_collision_point(0)
	var c_fraction: float = $Cast.get_closest_collision_unsafe_fraction()
	$Cast.target_position = $Cast.target_position*c_fraction
	$Cast.force_shapecast_update()
	if $Cast.is_colliding():
		c_point = $Cast.get_collision_point(0)
	
	var c_normal: Vector3 = Calc.get_ground_normal(c_point.x, c_point.z)
	$Debug/Ray.target_position = c_normal
	# see if any of the purported collisions are non-gay
	#var n: int = $Cast.get_collision_count()
	#if n > 1:
		## godot can't seem to figure out how to not shit the bed in this case so I'll manually 
		## calculate the collision normal and fraction
		#$Q/MoCo.mesh.material.albedo_color = Color(1.0, 0.0, 0.0, 0.9)
		#$Q/MoCo/Timer.start(0.2)
	#for i in range(n):
		#var c_n: Vector3 = $Cast.get_collision_normal(0)
		#if velocity.dot(c_n) < 0:
			#if c_normal != Vector3.ZERO:
				#c_normal = Calc.get_ground_normal(position.x, position.y) # TODO: get normal at collision, not at here
				#break
			#c_normal = c_n
	#if c_normal == Vector3.ZERO:
		## ignoring gay collisions
		#position += velocity*delta
		#return
		##phys_snap_to_surface()
	var parallel := c_normal * velocity.dot(c_normal)
	var perpendicular := velocity - parallel # TODO: lose less vel?
	#
	var pre_c_v_component := velocity*c_fraction*delta
	var post_c_v_component := perpendicular*(1-c_fraction)*delta
	#
	position += pre_c_v_component
	var remaining_dist := post_c_v_component.length()
	var dccd := DOUBLE_CALC_COLLISION_DISTANCE
	while remaining_dist > dccd:
		#print("VELOCITY REMAINDER IS LARGE")
		# TODO: we could make this recursive
		# NOTE: that the difference rn is we don't recalculate collisions here, we just stick to the floor
		position += perpendicular*dccd
		remaining_dist -= dccd
		c_normal = Calc.get_ground_normal(position.x, position.z)
		phys_snap_to_surface(c_normal)
		parallel = c_normal * post_c_v_component.dot(c_normal)
		perpendicular = post_c_v_component - parallel # TODO: lose less vel?
		post_c_v_component = remaining_dist * perpendicular.normalized()
		# TODO: debug pausing
	position += post_c_v_component
		# prevent ourselves from phasing into the floor on concavities
	phys_snap_to_surface(c_normal)
	var vn := perpendicular.normalized()
	velocity = vn * vn.dot(velocity)
		# TODO: to dot or not to dot? for now sqrt()
	grounded=true

# TODO: calculate current_normal if last_normal isnt good enough
func phys_snap_to_surface(last_normal: Vector3) -> void:
	# TODO: in tight spots, we could back up the starting point until the point 
	#       where we don't start with a collision
	$SnapCast.position = last_normal * DOUBLE_CALC_COLLISION_DISTANCE*4.0
	$SnapCast.target_position = -$SnapCast.position
	$SnapCast.force_shapecast_update()
	if $SnapCast.is_colliding():
		var c_fraction: float = $SnapCast.get_closest_collision_safe_fraction()
		position = $SnapCast.global_position  + $SnapCast.target_position*c_fraction
	

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
	if not grounded:
		velocity += Vector3.DOWN*grav*delta
	else:
		var downhill := Calc.get_downward_vector(global_position.x, global_position.z)
		if downhill.length() == 0:
			return
		var dh_acc := downhill * downhill.dot(Vector3.DOWN) * grav
		velocity += dh_acc * delta

func phys_friction(delta: float) -> void:
	var fric := LOW_FRIC
	if is_heavy:
		fric = HIGH_FRIC
	var q := pow(1.0-fric, delta)
	velocity *= q


### Helper ###

#func set_scale_size(s: int) -> void:
	##$Shape.shape.radius = s/2
	##$Cast.shape.radius = s/2
	#$Mesh.scale = Vector3(s, s, s)

#### Debug ####
func set_debug_points(a: Array) -> void:
	for i in range(len(a)):
		$Debug/Marks.get_child(i).global_position = a[i]


func _on_moco_timeout() -> void:
	$Q/MoCo.mesh.material.albedo_color = Color(0.0, 1.0, 0.0, 0.1)
