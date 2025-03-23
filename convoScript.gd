extends Control

var screen_size = get_viewport_rect().size
var velocity
var loading_text = false
var skip = false
func _ready():
	$Panel.show()
	$Sprite2D.show()
	velocity = Vector2(0, 0)
	on_screen = false
	$TextBox.hide()
	screen_size = get_viewport_rect().size
	$TextBox.position =  Vector2(25, screen_size.y + 20)
	$Sprite2D.position = Vector2(-200, screen_size.y / 1.5)
	
	
var on_screen
func toggle_text_box():
	if on_screen == false:
		$TextBox.show()
		velocity.y = -7
	else:
		velocity.y = 7
	on_screen = !on_screen
	
@export var text_speed := 0.07
func load_line(line, color, font, size):
	# add up the text only 
	while velocity.y != 0:
		await get_tree().process_frame
	$TextBox.push_color(color)
	$TextBox.push_font(font, size)
	for i in range(len(line)):
		$TextBox.append_text(line[i])  # Show progressively more text
		if(!skip): await get_tree().create_timer(text_speed).timeout  # Wait before next letter
	$TextBox.pop()
	$TextBox.pop()
	$TextBox.append_text("\n")
	
#should take json input
func load_text(script):
	$Sprite2D.texture = load("res://Sprites/" + script["character"] + ".png")
	#standardizes size
	$Sprite2D.scale = Vector2(158, 341) * Vector2(2, 2) / $Sprite2D.texture.get_size()
	if(loading_text): return
	await velocity.y == 0
	loading_text = true
	$TextBox.clear()
	var font = preload("res://Fonts/Amnesty-SansStamp.ttf")
	if(script["character"].contains('(')): await load_line(script["character"].substr(0, script["character"].find('(')) + ": ", Color(0.8, 1, 0.8), font, 30)
	else: await load_line(script["character"] + ": ", Color(0.8, 1, 0.8), font, 30)
	for line in script["lines"]:
		await load_line(line, Color(0.6, 0.2, 0.8), font, 20)
	loading_text = false
	if(!skip): await get_tree().create_timer(text_speed * 10).timeout
	else:
		skip = false
		#input isn't happening
		while(!skip):
			await get_tree().process_frame
	skip = false

var choice
func ask(options):
	var button_position = Vector2($Panel.position.x + ($Panel.size.x * 0.7), $Panel.position.y - 50)
	var button_size = Vector2($Panel.position.x * 0.3, 40)
	choice = null
	var buttons = []
	for option in options:
		var button = Button.new()
		button.text = option
		button.position = button_position
		button_position.y -= 50
		button.size = button_size
		button.pressed.connect(_on_button_pressed.bind(button))
		buttons.append(button)
		add_child(button)
	while(choice == null):
		await get_tree().process_frame
	for button in buttons:
		button.queue_free()
	return choice

func _on_button_pressed(button):
	choice = button.text

func _process(delta):
	#moving box
	$Panel.size = $TextBox.size + Vector2(20, 20)  # Adjust padding
	$Panel.position = $TextBox.position + Vector2(-10, -10)
	if(velocity.y != 0):
		$TextBox.position.y += velocity.y
		$Sprite2D.position.x -= velocity.y 
		if($TextBox.position.y >= screen_size.y + 20 or $TextBox.position.y <= screen_size.y / 2):
			velocity.y = 0

func _input(event):
	if(loading_text and event is InputEventMouseButton and event.pressed and $Panel.get_global_rect().has_point(get_global_mouse_position())):
		skip = true
	
