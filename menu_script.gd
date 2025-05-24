extends Node2D
@export var game_scene: PackedScene


func _on_button_pressed() -> void:
	var game = game_scene.instantiate()
	add_sibling(game)
	queue_free()
