extends Node2D
@export var card_scene: PackedScene

var hand = []
var full_deck = []
var deck
var screen_size
var area_size
var side_switched
var points
var maxx_p #when true, cards are drawn when points are reduced 
var peekable #number of turns cards can be peeked at for
var points_history = [] #tracks the peak of points since the start of the previous turn

func _ready():
	maxx_p = false
	peekable = 0 
	points_history = []
	points = 10
	deck = full_deck
	side_switched = false
	screen_size = get_viewport_rect().size
	$Area/Shape.shape.size = Vector2(screen_size.x, screen_size.y / 2 + screen_size.y / 36)
	area_size = $Area/Shape.shape.size
	$Area.position.x = screen_size.x / 2
	$Area.position.y = screen_size.y - $Area/Shape.shape.size.y * 0.5
	$Area/Points.set_position($Area/Shape.position - ($Area/Shape.shape.size / 2))
	$Area/Points.set_size(Vector2(area_size.x / 8, area_size.y / 12))
	$Area/end_turn_button.set_position($Area/Shape.position - ($Area/Shape.shape.size / 2))
	$Area/end_turn_button.position.x += 25
	$Area/end_turn_button.set_size(Vector2(area_size.x / 10, area_size.y / 12))
	refresh_points()
	points_history.append(points)
	
func add_to_deck(card):
	full_deck.append(card)
	card.hide()
	add_child(card)

func draw_card():
	if(deck.size() > 0):
		hand.append(deck.pop_at(0))
		hand.get(0).position = screen_size / Vector2(2, 2)
	show_hand()
		
func show_hand():
	var start = area_size.x / 5
	var increment = area_size.x * 4 / 5 / (hand.size() + 1)
	var increments = 1
	for card in hand:
		if(!side_switched):
			card.position.x = start + increment * increments + card.get_size().x / 2
			card.position.y = area_size.y * 5 / 3
		else:
			card.position.x = screen_size.x - (start + increment * increments + card.get_size().x / 2)
			card.position.y = screen_size.y - area_size.y * 5 / 3
		card.rotation = $Area.rotation
		card.z_index = increments * 7
		increments += 1
		if side_switched: card.switch_side("back")
		else: card.switch_side("front")
		card.show()

func refresh_points():
	$Area/Points.clear()
	$Area/Points.append_text(str(points))
		
func play_card(card: Object) -> Object:
	card._on_panel_container_mouse_exited()
	remove_child(card)
	hand.remove_at(hand.find(card))
	refresh_points()
	return card
	
func get_hand_y() -> float:
	return area_size.y * 5 / 3

func get_card_points(card: Object) -> int:
	var points = card.get_points()
	return points
	
func get_size() -> Vector2:
	return $Area/Shape.shape.size
	
func get_end_turn_button() -> Object:
	return $Area/end_turn_button

func change_card_points(card: Object, num: int, type: String) -> void:
	if card.get_card_name() == "Onyx Blade": return
	match type:
		"multiply": card.set_points(card.get_points() * num)
		"divide": card.set_points(card.get_points() / num)
		"add": card.set_points(card.get_points() + num)
		"subtract": card.set_points(card.get_points() - num)
	card.load_text(false)
		
func get_area_position() -> Vector2:
	return $Area.position

func multiply_points(num: int):
	change_points(num, "multiply")

func divide_points(num: int):
	change_points(num, "divide")
	
func add_points(num: int):
	change_points(num, "add")
	
func subtract_points(num: int):
	change_points(num, "subtract")
	
func change_points(num: int, type: String):
	var initial_points = points
	match type:
		"multiply": points = points * num
		"divide": points = points / num
		"add": points = points + num
		"subtract": points = points - num
	refresh_points()
	if maxx_p: maxx_p_activate(initial_points, points)
	points_history.append(points)
	
func clear_points_history():
	points_history.clear()
	
func switch_side():
	side_switched = true
	$Area.rotate(3.14)
	$Area.position = Vector2($Area.position.x, ($Area/Shape.shape.size.y * 0.5))
	
#card effect functions
func block_peeking(turns: int) -> void:
	peekable = turns
		
func maxx_p_activate(before: int, after: int):
	maxx_p = true
	if before < after: draw_card()
	
func restore_points_to_peak():
	if !points_history.is_empty(): points = points_history.max()

func reveal_card(card: Object):
	card.switch_side("front")
	
func reveal_hand():
	for card in hand: reveal_card(card)
