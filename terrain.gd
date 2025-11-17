@tool

extends Node3D

const MACRO_WIDTH := 5

func _ready() -> void:
	if get_tree().current_scene == self or Engine.is_editor_hint():
		build_terrain()

func build_terrain() -> void:
	for y in range(-MACRO_WIDTH,MACRO_WIDTH):
		for x in range(-MACRO_WIDTH,MACRO_WIDTH):
			var q: SinBody = preload("res://sin_body.tscn").instantiate()
			q.position = Vector3(x*32, 0, y*32)
			add_child(q)
