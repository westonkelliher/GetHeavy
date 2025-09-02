extends Node


var player: Node3D = null

# TODO: will prob need to exclude anything nearby in the 
# can aggregate with an area3d

var world_3d: World3D = null # set by world.gd

func get_ground_y(world_x: float, world_z: float, exclude := [player], max_height := 1_000.0) -> float:
	var space := world_3d.direct_space_state
	# Build the parameter object in one line.
	var params := PhysicsRayQueryParameters3D.create(
		Vector3(world_x, -1000,  world_z),    # from
		Vector3(world_x,  1000,  world_z),   # to
	)
	params.collide_with_bodies = true   # default, but explicit reads clearer
	params.collide_with_areas  = false  # skip Area3D triggers; set true if needed
	params.exclude = exclude
	var hit := space.intersect_ray(params)   # single‑arg call in 4.x  :contentReference[oaicite:0]{index=0}
	return hit.position.y if hit else 0.0    # put the player a small margin above

# normalized vector tangent to ground surface in the most downward direction
func get_downward_vector(world_x: float, world_z: float) -> Vector3:
	var q1: Vector3 = _get_downward_vector(world_x, world_z, 0.15, 0)
	var q2: Vector3 = _get_downward_vector(world_x, world_z, 0.4, PI*2/6)
	return ((q1+q2)/2.0).normalized()

# normalized vector tangent to ground surface in the most downward direction
func _get_downward_vector(world_x: float, world_z: float, non_limit_dist: float, start_theta: float) -> Vector3:
	# TODO: choose the first point in the xz direction of velocity
	var py: float = get_ground_y(world_x, world_z)
	var p: Vector3 = Vector3(world_x, py, world_z)
	print(p)
	# a
	var thetq: Vector3 = Vector3.FORWARD * non_limit_dist
	var a: Vector3 = p + thetq
	a.y = get_ground_y(a.x, a.z)
	# b
	thetq = thetq.rotated(Vector3.UP, PI*2/3)
	var b: Vector3 = p + thetq
	b.y = get_ground_y(b.x, b.z)
	# c
	thetq = thetq.rotated(Vector3.UP, PI*2/3)
	var c: Vector3 = p + thetq
	c.y = get_ground_y(c.x, c.z)
	# downward normal of the plane
	var tang_norm: Vector3 = (b-a).cross(c-a).normalized()
	if tang_norm.y > 0:
		tang_norm = -tang_norm
	# projection of DOWN onto the plane
	var dot := tang_norm.dot(Vector3.DOWN)
	if dot > 0.999:
		return Vector3.ZERO
	var down_proj: Vector3 = Vector3.DOWN - dot * tang_norm
	# debug
	player.set_debug_points([a, b, c, p])
	#
	print('--- ' + str(down_proj.normalized()) + ' ---')
	return down_proj.normalized()
	
