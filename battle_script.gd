extends Node2D
@export var table_scene: PackedScene
@export var card_scene: PackedScene

var cards: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://cards.json"))
var player: Object
var opponent: Object
var turn: bool = true #player's turn
var gameover: bool
var chosen_card: Object
var chosen_opponent_card: Object
var chosen_other_card: Object
var other_hand: Array = []
var points_goal: int
var text_break: float = 0.07
var turn_count: int 
var screen_size: Vector2 = get_viewport_rect().size
var probability: int = 1  #multiplier of chance occurences
var altered_probability_turns: int = 0
var last_effect: String
var card_queue: Array = []
var deploy: bool

#initializes a new game
func _ready():
	screen_size = get_viewport_rect().size
	card_queue = []
	turn_count = 0
	points_goal = 500
	gameover = false
	probability = 1
	load_goal()
	player = table_scene.instantiate()
	opponent = table_scene.instantiate()
	add_child(player)
	add_child(opponent)
	for i in range(14):
		player.add_to_deck(create_random_card())
		opponent.add_to_deck(create_random_card())
	opponent.switch_side()
	for i in range(7):
		player.draw_card()
		opponent.draw_card()
	player.show_hand()
	opponent.show_hand()
	play()
	
func load_goal():
	var goal_text = "Goal: " + str(points_goal)
	for char in goal_text:
		$Goal.append_text(char)
		await get_tree().create_timer(text_break).timeout

func create_card(num: int) -> Object:
	var new_card = card_scene.instantiate()
	new_card.set_card_name(cards["cards"][num]["name"])
	new_card.set_effect(cards["cards"][num]["effect"])
	new_card.set_points(cards["cards"][num]["points"])
	new_card.set_color(Color(0, 0, 0))
	new_card.set_font_size(125)
	return new_card

func create_random_card() -> Object:
	var new_card = card_scene.instantiate()
	var num = randi() % cards["cards"].size()
	new_card.set_card_name(cards["cards"][num]["name"])
	new_card.set_effect(cards["cards"][num]["effect"])
	new_card.set_points(cards["cards"][num]["points"])
	new_card.set_color(Color(0, 0, 0))
	new_card.set_font_size(125)
	return new_card

func play():
	new_turn()
	turn_count += 1
	for i in range(4): #3 plays, 0 - 2
		if turn:
			if turn_count > 2: player.draw_card()
			if await make_play_or_deploy(): break
			var points = player.get_card_points(chosen_card)
			var card = player.play_card(chosen_card)
			show_card_queue()
			player.show_hand()
			await add_to_card_queue(card, points, player, opponent)
		else:
			if turn_count > 2:
				await get_tree().create_timer(0.5).timeout
				opponent.draw_card()
			if chance_occurence(0.08):
				print(card_queue.size())
				deploy_queue()
				break
			await get_tree().create_timer(0.5).timeout
			var random_card = random_opponent_card()
			var points = opponent.get_card_points(random_card)
			var card = await opponent.play_card(random_card)
			show_card_queue()
			opponent.show_hand()
			await add_to_card_queue(card, points, opponent, player)
			await get_tree().create_timer(0.5).timeout
			if i == 2: await deploy_queue() #final iteration
	if player.points == points_goal or opponent.points == points_goal:
		gameover = true
	if player.hand.size() == 0 and player.deck.size() == 0 or opponent.hand.size() == 0 and opponent.hand.size() == 0:
		gameover = true
	turn = !turn
	if !gameover:
		play()
		
func random_opponent_card() -> Object:
	var rand_card = opponent.hand.get(randi() % opponent.hand.size())
	return rand_card
		
func make_play_or_deploy() -> bool: #returns true if deploying
	show_card_queue()
	chosen_card = null
	deploy = false
	var prompt
	player.get_end_turn_button().pressed.connect(_on_deploy_pressed.bind())
	if card_queue.size() == 3:
		prompt = text_prompt("Deploy")
		while !deploy:
			await get_tree().process_frame
	else:
		prompt = text_prompt("Play a card or Deploy")
		while chosen_card == null and !deploy:
			await get_tree().process_frame
	prompt.queue_free()
	if deploy:
		await deploy_queue()
		return true
	return false
	
	
func deploy_queue() -> void:
	if card_queue.is_empty(): return
	var start = card_queue.size() - 1
	for i in range(start, -1, -1):
		await get_tree().create_timer(0.5).timeout
		var card = card_queue[i]
		card_queue.remove_at(i)
		card[0].hide()
		show_card_queue()
		await card_effect(card[0], card[1], card[2], card[3])
		card[0].queue_free()
		
func _on_deploy_pressed():
	deploy = true

func add_to_card_queue(card, points, sender, reciever):
	card_queue.append([card, points, sender, reciever])
	show_card_queue()
		
func show_card_queue():
	var start = screen_size.x * 3 / 10
	var increment = screen_size.x * 4 / 10 / (card_queue.size() + 1)
	var increments = 1
	for c in card_queue:
		var card = c[0]
		var pos_x = start + increment * increments + card.get_size().x / 2
		var pos_y = screen_size.y * 1 / 2
		var tween = get_tree().create_tween()
		tween.set_speed_scale(7)
		tween.tween_property(card, "position:x", pos_x, 1)
		tween.tween_property(card, "position:y", pos_y, 1)
		card.z_index = increments * 7
		increments += 1
		card.switch_side("front")
		add_child(card)
		card.show()

func card_effect(card, points, sender, reciever):
	match card.get_card_name():
		"Hollow Mask":
			sender.block_peeking(points)
		"Pyrrhic Victory":
			sender.multiply_points(0)
			reciever.divide_points(points)
		"Monument to Pain":
			sender.maxx_p_activate(0, 0)
		"Onyx Blade":
			pass #passive in table_script change_card_points()
		"Restoring Flame":
			sender.restore_points_to_peak()
		"Reckless Gamble":
			var selection
			if turn: selection = await choose_card()
			else: selection = random_opponent_card()
			if chance_occurence(0.4): sender.change_card_points(selection, 2, "multiply")
			else: 
				sender.play_card(selection)
		"Divination":
			if turn: opponent.reveal_hand() #Right now this does nothing for the opponent
		"Vision Sharing":
			if turn: #Right now this does nothing for the opponent
				await choose_opponent_card()
				highlight_card(chosen_opponent_card)
		"Induction":
			print("Later")
		"Deduction":
			if turn: highlight_card(opponent.deck.get(0)) #Right now this does nothing for the opponent
		"Cause and Effect":
			print("Later")
		"Free Will":
			print("Later")
		"Calamity":
			set_probability(0.5, 5)
		"Luck Streak":
			set_probability(2, 5)
		"Motivational Poster":
			var selection
			if turn: selection = await choose_card()
			else: selection = random_opponent_card()
			sender.change_card_points(selection, points, "add") #this method makes sure card is refreshed
		"Rousing Speech":
			print("Later")
		"Sharp Outfit":
			if turn:
				await choose_card_from_deck(sender, points)
			else:
				sender.hand.append(sender.deck.pop_at(randi() % 3))
		"Cognitive Dissonance":
			if last_effect != null:
				card.set_card_name(last_effect)
				print(card.get_card_name())
				card_effect(card, points, sender, reciever)
		"Outrage":
			sender.add_points(points)
			reciever.subtract_points(points)
		"Heart Attack":
			reciever.subtract_points(points)
		"Barrage":
			sender.add_points(randi() % points)
		"High Potential":
			if points > 0: reciever.divide_points(points)
				
	if card.get_card_name() != "Cognitive Dissonance": last_effect = card.get_card_name()
	sender.refresh_points()
	reciever.refresh_points()
	
func text_prompt(prompt: String) -> Object: #returns the label so that it can be deleted
	var sign = RichTextLabel.new()
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.push_font_size(25)
	sign.append_text(prompt)
	sign.set_position(Vector2(screen_size.x / 5, screen_size.y * 4.2 / 6))
	sign.set_size(player.get_size())
	add_child(sign)
	return sign

func choose_card() -> Object:
	var prompt = text_prompt("Choose One Of Your Cards")
	chosen_card = null
	while chosen_card == null:
		await get_tree().process_frame
	prompt.queue_free()
	return chosen_card
	
func choose_opponent_card() -> Object:
	var prompt = text_prompt("Choose An Opponent Card")
	chosen_opponent_card = null
	while chosen_opponent_card == null:
		await get_tree().process_frame
	prompt.queue_free()
	return chosen_opponent_card

func chance_occurence(chance: float) -> bool:
	return randi() % 10 < chance * 10 * use_probability()
	
func duplicate_card(card: Object) -> Object:
	var new_card = card_scene.instantiate()
	new_card.card_name = card.card_name
	new_card.effect = card.effect
	new_card.points = card.points
	new_card.color = card.color
	new_card.font = card.font
	new_card.font_size = card.font_size
	return new_card
	
var highlight
var highlight_button
func highlight_card(card: Object) -> void:
	if card == null: return
	remove_child(highlight)
	remove_child(highlight_button)
	highlight = duplicate_card(card)
	highlight.switch_side("front")
	highlight.position = Vector2(highlight.get_size().x, player.get_hand_y())
	highlight_button = Button.new()
	highlight_button.text = "OK"
	highlight_button.position = Vector2(highlight.position.x - 15, highlight.position.y - highlight.get_size().y / 1.5)
	highlight_button.pressed.connect(_on_button_pressed.bind(highlight_button))
	add_child(highlight)
	add_child(highlight_button)
	highlight.show()
	highlight_button.show()
	while(highlight_button.text == "OK" and highlight != null):
		await get_tree().process_frame
	highlight.queue_free()
	highlight_button.queue_free()
	highlight = null
	highlight_button = null

func _on_button_pressed(button):
	if button.text == "OK": button.text = "COOL"
	
func set_probability(num: float, turns: int) -> void:
	probability = num
	altered_probability_turns = turns
	
func use_probability() -> float: #all chances should be multiplied by this  ex. randi() % 10 < 6 * use_probability()
	altered_probability_turns -= 1
	var prob = probability
	if altered_probability_turns == 0: probability = 1
	return prob
	
func choose_card_from_deck(playing: Object, cards: int) -> Object:
	if playing.deck.is_empty():
		return
		
	for card in playing.hand:
		card.hide()
	var start = playing.area_size.x / 5
	var increment = playing.area_size.x * 4 / 5 / (cards + 1)
	var increments = 1
	for i in range(0, cards):
		var card = playing.deck.get(i)
		if card == null: break
		card.position.x = (start + increment * increments + card.get_size().x / 2)
		card.position.y = playing.area_size.y * 5 / 3
		card.z_index = increments
		increments += 1
		other_hand.append(card)
		add_child(card)
		card.switch_side("front")
		card.show()
	var prompt = text_prompt("Choose A Card From The Deck")
	chosen_other_card = null
	while chosen_other_card == null:
		await get_tree().process_frame
	for card in other_hand:
		card.hide()
		remove_child(card)
	other_hand.clear()
	playing.hand.append(playing.deck.pop_at(playing.deck.find(chosen_other_card)))
	playing.show_hand()
	prompt.queue_free()
	return chosen_other_card
	

func new_turn() -> void: #everything that should happen at the beginning of a turn
	player.maxx_p = false
	opponent.maxx_p = false
	if player.peekable > 0: player.peekable -= 1
	if opponent.peekable > 0: opponent.peekable -= 1
	player.clear_points_history()
	opponent.clear_points_history()
		
func _input(event: InputEvent) -> void:
	for card in player.hand:
		if(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and card.loaded and card.hovered_over()):
			chosen_card = card
	for card in opponent.hand:
		if(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and card.loaded and card.hovered_over()):
			chosen_opponent_card = card
	for card in other_hand:
		if(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and card.loaded and card.hovered_over()):
			chosen_other_card = card
