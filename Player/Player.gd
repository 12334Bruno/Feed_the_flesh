extends KinematicBody2D

# World constatns
var TILE_SIZE = 16

# Movement 
var SPEED = 90
var direction = Vector2.ZERO
var velocity = Vector2.ZERO
var last_direction = direction
var grid_pos = Vector2.ZERO
var last_grid_pos = Vector2.ZERO

# Items
var HOLDING_CAPACITY = 3
var held_items = []
var on_item = null
var front_pos = null
var on_wall = null
var stacking_items = true

# Harvesting
var harvest_timer = 0
var time_to_harvest = 2
var harvesting = null

# States
enum {
	ACTIVE,
	STOPPED
}
var state = ACTIVE

# Load scenes
onready var Main = get_parent().get_parent()
onready var Y_Sort = Main.get_node("YSort")
onready var PB = preload("res://ProgressBarIcon/ProgressBarIcon.tscn")
onready var FB = Main.get_node("CanvasLayer/FeedMeter") #preload("res://UI/FeedMeter.tscn").instance() # Feed Bar
onready var TB = Main.get_node("CanvasLayer/CycleTimer") #preload("res://UI/CycleTimer.tscn").instance() # Time Bar (to next feasting)
var progress_bar = null

# Load nodes
onready var text_label = $Control/Label

# Load animations
onready var animationTree = $AnimationTree
onready var animationPlayer = $AnimationPlayer
onready var animationState = animationTree.get('parameters/playback')

	
func set_text():
	text_label.text = str(len(held_items), "/", HOLDING_CAPACITY)

func _physics_process(delta):
	highlight()
	
	match state:
		ACTIVE:
			update_player_position(delta)
			automatic_interact()
			take_player_input()
		STOPPED:
			harvesting(delta)


func _unhandled_input(event):
	# Check for interactable objects/items 
	if event.is_action_pressed("ui_interact"):
		# interactable variable is command string 
		var interactable = can_interact()
		if interactable:
			# Turn this string into array so the information is easily usable
			interactable = interactable.split("_")
			# Interaction position of interactable object -> index 0 in interactable
			var inter_pos = grid_pos
			if interactable[0] == "front":
				inter_pos = front_pos
			# What is interactable (type of interaction) -> index 1
			if interactable[1] == "wall":
				wall_interact(inter_pos)
			elif interactable[1] == "altar":
				altar_interact()
			elif interactable[1] == "place":
				# How much is interactable (shift/no shift) -> index 2
				var one = false
				if interactable[2] == "one":
					one = true
				place_interact(inter_pos, one)
			elif interactable[1] == "take":
				var one = false
				if interactable[2] == "one":
					one = true
				take_interact(inter_pos, one)
			elif interactable[1] == "switch":
				switch_interact(inter_pos)
			elif interactable[1] == "harvest":
				harvest_interact(inter_pos)

# Harvest any material
func harvesting(delta):
	var stop = false
	# Keep harvesting while the interact button is pressed, else stop
	if Input.is_action_pressed("ui_interact"):
		harvest_timer += delta
	else:
		stop = true
	
	# After a certain time harvest the material and add it to held_items
	if harvest_timer >= time_to_harvest:
		var resource = harvesting.resource.instance()
		Y_Sort.add_child(resource)
		held_items.append(resource)
		harvest_timer = 0
		
		
		if harvesting:
				
			if harvesting.uses == 1:
				stop = true
				on_item = null
			harvesting.uses -= 1
		
		# Only for visual queue
		automatic_interact()
		set_text()
		
		resource.picked_up = true
		
		# Stop harvesting if HOLDING_CAPACITY is full
		if len(held_items) >= HOLDING_CAPACITY or not harvesting.can_harvest:
			stop = true
	
	if stop:
		harvest_timer = 0
		time_to_harvest = 0
		state = ACTIVE
		harvesting = null
		progress_bar.queue_free()

func take_player_input():
	# Take player direction input
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = Vector2(x_input, y_input).normalized()
	
	# Set last_direction when moving 
	if x_input != 0 or y_input != 0:
		last_direction = direction
		animationTree.set('parameters/Idle/blend_position', direction)
		animationTree.set('parameters/Run/blend_position', direction)
		animationState.travel("Run")
	else:
		animationState.travel("Idle")

func automatic_interact():
	if held_items:
		held_items[0].global_position = Vector2(global_position.x, global_position.y) + (last_direction * 8)
		
		if stacking_items:
			var tile_items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
			# Take items you run over if you're holding the same type of item
			if (len(tile_items) > 0 and held_items[0].item_name == tile_items[0].item_name
				and len(held_items) < HOLDING_CAPACITY):
				take_interact(grid_pos, false)


func update_player_position(delta):
	velocity = direction * SPEED
	velocity = move_and_slide(velocity)
	var new_grid_pos = Main.Grass.world_to_map(global_position)
	if new_grid_pos != grid_pos:
		last_grid_pos = grid_pos
		grid_pos = new_grid_pos
		stacking_items = true
		
func can_interact():
	# Wall interaction 
	if held_items and held_items[0].item_name == "berry":
		if last_direction.x == 0 or last_direction.y == 0:
			if Main.world_layers["flesh_wall"][grid_pos.y][grid_pos.x]:
				return "grid_wall_interactable"
			if Main.world_layers["flesh_wall"][front_pos.y][front_pos.x]:
				return "front_wall_interactable"
		if front_pos == Main.center_pos and FB.current != FB.threshold:
			return "front_altar_interactable"
	# Harvest interaction
	if len(held_items) < HOLDING_CAPACITY:
		var tile_resource_maker = Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x]
		var front_resource_maker = Main.world_layers["resource_makers"][front_pos.y][front_pos.x]
		if tile_resource_maker and tile_resource_maker[0].can_harvest:
			if (!held_items or held_items[0].item_name == tile_resource_maker[0].resource_name):
				return "grid_harvest_interactable"
		elif front_resource_maker and front_resource_maker[0].can_harvest:
			if (!held_items or held_items[0].item_name == front_resource_maker[0].resource_name):
				return "front_harvest_interactable"
	# Place/Take iteraction
	var tile_items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
	# Player position doesn't have interactable resources
	if !tile_items:
		tile_items = Main.world_layers["resources"][front_pos.y][front_pos.x]
		# Position before player doesn't have interactable resources
		if !tile_items:
			# Player holds items
			if held_items:
				if Input.is_action_just_pressed("ui_interact_one"):
					return "grid_place_one_interactable"
				return "grid_place_all_interactable"
		# Position before player has interactable resources
		else:
			# Player holds items
			if held_items:
				if held_items[0].item_name == tile_items[0].item_name:
					if Input.is_action_just_pressed("ui_interact_one") and (1 + len(tile_items) <= 3):
						return "front_place_one_interactable"
					if len(held_items) + len(tile_items) <= 3:
						return "front_place_some_interactable"
				else:
					return "front_switch_interactable"
			# Player doesn't hold items
			else:
				if Input.is_action_just_pressed("ui_interact_one"):
					return "front_take_one_interactable"
				return "front_take_all_interactable"
	# Player position has interactable resources
	else:
		# Player holds items
		if held_items:
			if held_items[0].item_name == tile_items[0].item_name:
				if Input.is_action_just_pressed("ui_interact_one") and (1 + len(tile_items) <= 3):
					return "grid_place_one_interactable"
				if len(held_items) + len(tile_items) <= 3:
					return "grid_place_some_interactable"
			else:
				return "grid_switch_interactable"
		# Player doesn't hold items
		else:
			if Input.is_action_just_pressed("ui_interact_one"):
				return "grid_take_one_interactable"
			return "grid_take_all_interactable"
	return false


# Highlight 
func highlight():
	var items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
	items += Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x]
	
	front_pos = Main.Grass.world_to_map(global_position + (last_direction * TILE_SIZE / 2))
	if items == []:
		
		items = Main.world_layers["resources"][front_pos.y][front_pos.x]
		items += Main.world_layers["resource_makers"][front_pos.y][front_pos.x]
	
	# Set highlight if player is on interactable item 
	if len(items) > 0:
		# Check if item is interactable
		if items[0].get("interactable"):
			# Remove highlight from old item and add to new
			if on_item != items[0] and on_item != null:
				on_item.get_node("Visual").material.set_shader_param("width", 0.0)
			on_item = items[0]
			items[0].get_node("Visual").material.set_shader_param("width", 1.0)
		elif items[0].get("interactable") == false:
			items[0].get_node("Visual").material.set_shader_param("width", 0.0)
	elif on_item != null:
		# Turn of highlight if the player isn't on a item
		on_item.get_node("Visual").material.set_shader_param("width", 0.0)
		on_item = null
	else:
		var wall = Main.world_layers["flesh_wall"][grid_pos.y][grid_pos.x]
		var pos = grid_pos
		
		if not wall:
			wall = Main.world_layers["flesh_wall"][front_pos.y][front_pos.x]
			pos = front_pos
			
		if wall and (last_direction.x == 0 or last_direction.y == 0):
			on_wall = true
		else:
			on_wall = false
		if on_wall:
			Main.ProgressBarIcon.z_index = 10
			Main.ProgressBarIcon.set_position(Main.Grass.map_to_world(pos)) 
			Main.ProgressBarIcon.visible = true
			Main.update_wall_progress(pos)
		else:
			Main.ProgressBarIcon.visible = false

# Fuction takes an array of items
func take_interact(item_pos, one):
	var items = []+Main.world_layers["resources"][item_pos.y][item_pos.x]

	if one == true:
		stacking_items = false
		items = [items[0]]
		
	for item in items:
		var new_item_pos = Main.Grass.world_to_map(item.global_position)
		if len(held_items) < HOLDING_CAPACITY: 
			Main.world_layers["resources"][new_item_pos.y][new_item_pos.x].erase(item)
			held_items.append(item)
	
	for i in held_items:
		i.visible = false
		i.picked_up = true
	held_items[0].visible = true
	set_text()

# Function takes an array of items
func place_interact(item_pos, one):
	var items = [] + held_items
	if one == true:
		stacking_items = false
		# Visuals
		if len(held_items) > 1:
			held_items[1].visible = true
		items = [items[0]]
	
	for item in items:
		Main.world_layers["resources"][item_pos.y][item_pos.x].append(item)
		item.global_position = item_pos * TILE_SIZE + item.self_offset
		item.visible = true
		item.picked_up = false
		held_items[0].picked_up = false
		held_items.erase(item)
	set_text()
		

func switch_interact(item_pos):
	var items = Main.world_layers["resources"][item_pos.y][item_pos.x]
	var new_held_items = [] + held_items
	held_items = []
	stacking_items = false
	take_interact(items, false)
	place_interact(new_held_items, false)
	for item in held_items:
		item.text_label.visible = false

func harvest_interact(item_pos):
	harvesting = Main.world_layers["resource_makers"][item_pos.y][item_pos.x][0]
	time_to_harvest = harvesting.time_to_harvest
	progress_bar = PB.instance()
	Y_Sort.add_child(progress_bar)
	progress_bar.animation = "no_color"
	progress_bar.global_position = global_position - Vector2(8, 20) # Offset for visuals
	progress_bar.speed_scale /= time_to_harvest
	progress_bar.playing = true
	progress_bar.z_index = 10
	state = STOPPED


func wall_interact(wall_pos):
	var wall = Main.world_layers["flesh_wall"][wall_pos.y][wall_pos.x]
	if len(held_items) >= wall["food_to_next_lvl"] - wall["current_food"]:
		for i in range(wall["food_to_next_lvl"] - wall["current_food"]):
			held_items[0].queue_free()
			held_items.remove(0)
		if held_items:
			held_items[0].visible = true
		Main.build_wall(wall_pos, grid_pos)
	else:
		Main.world_layers["flesh_wall"][wall_pos.y][wall_pos.x]["current_food"] += len(held_items)
		for i in range(len(held_items)):
			held_items[0].queue_free()
			held_items.remove(0)
		Main.update_wall_progress(wall_pos)
	set_text()

func altar_interact():
	for i in range(len(held_items)):
		if FB.current < FB.threshold:
			held_items[0].queue_free()
			held_items.remove(0)
			FB.update_bar(1)
	set_text()
