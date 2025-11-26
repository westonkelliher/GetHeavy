@tool

extends Node3D

const MACRO_WIDTH := 2
const SINBODY_SIZE := 32

# hashmap to store sin_bodys / chunks
var sinbodies: Dictionary = {}

func _ready() -> void:
	if get_tree().current_scene == self or Engine.is_editor_hint():
		build_initial_terrain()

func build_initial_terrain() -> void:
	for y in range(-MACRO_WIDTH+1,MACRO_WIDTH):
		for x in range(-MACRO_WIDTH+1,MACRO_WIDTH):
			var q: SinBody = preload("res://terrain/sin_body.tscn").instantiate()
			q.position = Vector3(x*SINBODY_SIZE, 0, y*SINBODY_SIZE)
			# q.visible = false
			add_child(q)
			sinbodies[Vector2i(x, y)] = q


func generate_chunks_around_index(idx_x: int, idx_z: int) -> void:
	for z in range(idx_z - 1, idx_z + 2):
		for x in range(idx_x - 1, idx_x + 2):
			var key := Vector2i(x, z)
			if sinbodies.has(key):
				continue
			var chunk: SinBody = preload("res://terrain/sin_body.tscn").instantiate()
			chunk.position = Vector3(x * SINBODY_SIZE, 0, z * SINBODY_SIZE)
			# chunk.visible = false
			add_child(chunk)
			sinbodies[key] = chunk
