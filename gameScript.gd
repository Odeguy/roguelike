extends Node2D
@export var text_scene: PackedScene
@export var main_scene: PackedScene
@export var battle_scene: PackedScene

var save_state = 1
var start_menu
var text_box
func _ready():
	start_menu = main_scene.instantiate()
	start_menu.get_node("start_button").pressed.connect(_on_start_button_pressed)
	start_menu.get_node("settings_button").pressed.connect(_on_settings_button_pressed)
	start_menu.get_node("exit_button").pressed.connect(_on_exit_button_pressed)
	start_menu.get_node("free_battle_button").pressed.connect(_on_free_battle_button_pressed)
	add_child(start_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var choice
func _on_start_button_pressed():
	game_states(save_state)
	
func conversate(file):
	start_menu.hide()
	text_box = text_scene.instantiate()
	add_child(text_box)
	var script = JSON.parse_string(FileAccess.get_file_as_string(file))
	text_box.toggle_text_box()
	if(text_box.on_screen):
		for part in script["parts"]:
			await text_box.load_text(part)
			if(part.size() > 2): choice = await text_box.ask(part["choice"])
	text_box.toggle_text_box()
	text_box.queue_free()
	
func _on_settings_button_pressed():
	pass
	
func _on_free_battle_button_pressed():
	pass
	
func _on_exit_button_pressed():
	get_tree().quit()
	
func game_states(state):
	match(state):
		1: 
			await conversate("res://Conversations/conv1.json")
			if(choice == "Okay, cool."): save_state += 1
		2: 
			await conversate("res://Conversations/conv2.json")
			save_state -= 1
	_ready()
