extends Node2D

var card_name: String
var effect: String
var front: bool = false
var _color: Color
var font_color: Color
var font: Variant
var font_size: int
var text_time: float = 0.1
var loaded: bool
var points: int
var text_scale = 0.1
var mouse_entered = false

func _ready():
	$NameLabel.set_scale(Vector2(text_scale, text_scale))
	$EffectLabel.set_scale(Vector2(text_scale, text_scale))
	$PointsLabel.set_scale(Vector2(text_scale, text_scale))
	loaded = true
	switch_side("front")

func switch_side(side: String):
	front = !front
	
func set_color(font_color_entered: Color):
	font_color = font_color_entered
	re_push()

func set_font_size(size_entered: int):
	font_size = size_entered
	re_push()
	
func set_points(points_entered: int):
	points = points_entered
	re_push()
	
func set_font(font_entered: String):
	font = font_entered
	re_push()
	
func set_card_name(name_entered: String):
	card_name = name_entered
	re_push()
	
func set_effect(effect_entered: String):
	effect = effect_entered
	re_push()

func re_push():
	$NameLabel.clear()
	if(font_color != null): $NameLabel.push_color(font_color)
	if(font_size != null): $NameLabel.push_font_size(font_size)
	if(font != null): $NameLabel.push_font(font)
	
	$EffectLabel.clear()
	if(font_color != null): $EffectLabel.push_color(font_color)
	if(font_size != null): $EffectLabel.push_font_size(font_size)
	if(font != null): $EffectLabel.push_font(font)
	
	$PointsLabel.clear()
	if(font_color != null): $PointsLabel.push_color(font_color)
	if(font_size != null): $PointsLabel.push_font_size(font_size * 2)
	if(font != null): $PointsLabel.push_font(font)
	
func hovered_over() -> bool:
	return mouse_entered
	

func get_size() -> Vector2:
	return $PanelContainer.size * $PanelContainer.scale
	
func get_card_name() -> String:
	return card_name

func get_effect() -> String:
	return effect

func get_font_color() -> Color:
	return font_color
	
func get__color() -> Color:
	return _color
	
func get_font() -> String:
	return font
	
func get_font_size() -> int:
	return font_size
	
func get_points() -> int:
	return points

func load_text(gradually: bool):
	$NameLabel.clear()
	$EffectLabel.clear()
	$PointsLabel.clear()
	re_push()
	var effect_with_int = effect #effect but [points value] is replaced with the actual number
	while effect_with_int.find("[points value]") != -1:
		effect_with_int = effect_with_int.substr(0, effect_with_int.find("[points value]")) + str(points) + effect_with_int.substr(effect_with_int.find("[points value]") + "[points value]".length())
	if gradually:
		loaded = false
		for char in card_name:
			if loaded: break
			$NameLabel.append_text(char)
			await get_tree().create_timer(text_time / card_name.length()).timeout
		for char in effect_with_int:
			if loaded: break
			$EffectLabel.append_text(char)
			await get_tree().create_timer(text_time / effect.length()).timeout
	else:
		$NameLabel.append_text(card_name)
		$EffectLabel.append_text(effect_with_int)
	$PointsLabel.append_text(str(points))
	loaded = true

func extend_margin(length: int, expansion: int, text_position: int, duration: int) -> void:
	var tween = get_tree().create_tween()
	tween.set_speed_scale(7)
	var stylebox := $PanelContainer.get_theme_stylebox("panel") as StyleBoxFlat
	if stylebox == null:
		push_error("No StyleBoxFlat found for 'panel'")
		return

	if not $PanelContainer.has_theme_stylebox_override("panel"):
		stylebox = stylebox.duplicate()
		$PanelContainer.add_theme_stylebox_override("panel", stylebox)
		
	tween.tween_property(stylebox, "expand_margin_left", length, duration)
	tween.set_parallel()
	tween.tween_property(stylebox, "expand_margin_right", expansion, duration)
	tween.tween_property(stylebox, "expand_margin_bottom", expansion, duration)
	tween.tween_property(stylebox, "expand_margin_top", expansion, duration)
	tween.tween_property($NameLabel, "position:x", text_position, duration)
	tween.tween_property($PointsLabel, "position:x", text_position, duration)
	tween.tween_property($EffectLabel, "position:x", text_position, duration)

@onready var z_default: int = z_index
@onready var unextended_length: int = $PanelContainer.size.x
@onready var first_position: Vector2 = $PanelContainer.position
@onready var text_first_position: Vector2 = $NameLabel.position
func _on_panel_container_mouse_entered():
	mouse_entered = true
	extend_margin(unextended_length * 1.5, 50, text_first_position.x - unextended_length * 1.5 * $PanelContainer.scale.x, 1)
	load_text(true)
	
func _on_panel_container_mouse_exited():
	mouse_entered = false
	loaded = true
	await re_push()
	extend_margin(10, 10, text_first_position.x, 1)
	await get_tree().create_timer(200).timeout
	z_index = z_default
	
	
