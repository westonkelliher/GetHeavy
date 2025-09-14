@tool

extends Node3D

func _ready() -> void:
	print('start')
	if get_tree().current_scene == self or Engine.is_editor_hint():
		print('hey')
		build_terrain()

func build_terrain() -> void:
	for y in range(-5,5):
		for x in range(-5,5):
			var q: SinBody = preload("res://sin_body.tscn").instantiate()
			q.position = Vector3(x*32, 0, y*32)
			add_child(q)
