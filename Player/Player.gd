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
var on_item_pos = null
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
onready var FB = preload("res://Player/FeedMeter.tscn").instance() # Feed Bar
onready var TB = preload("res://Player/CycleTimer.tscn").instance() # Time Bar (to next feasting)
var progress_bar = null

# Load nodes
onready var text_label = $Control/Label

func _ready():
	add_child(FB)
	add_child(TB)

func set_text():
	text_label.text = str(len(held_items), "/", HOLDING_CAPACITY)

func _physics_process(delta):
	highlight()
	
	match state:
		ACTIVE:
			update_player_position(delta)
			interact()
			take_player_input()
		STOPPED:
			harvesting(delta)


func _unhandled_input(event):
	
	# Check for interactable objects/items 
	if event.is_action_pressed("ui_interact"):
		
		var took_front_item = null
		var items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
		if items == []:
			took_front_item = front_pos
			items = Main.world_layers["resources"][front_pos.y][front_pos.x]
      
		# Wall interaction has priority
		if !wall_interact() and can_place(items):
    
		# Wall interaction has priority
		if wall_interact():
			pass
		elif altar_interact():
			pass
		elif can_place():
			
			if Input.is_action_just_pressed("ui_interact_one"):
				stacking_items = false
				# Visuals
				if len(held_items) > 1:
					held_items[1].visible = true
				
				place_items([held_items[0]])
			else:
				place_items(held_items)
			
		elif can_take(items):
			if Input.is_action_just_pressed("ui_interact_one"):
				stacking_items = false
				take_items([items[0]])
			else:
				take_items(items)
		elif can_switch(items):
			var new_held_items = [] + held_items
			held_items = []
			stacking_items = false
			
			take_items(items)
			place_items(new_held_items, took_front_item)
			
			for item in held_items:
				item.text_label.visible = false
			
		
		elif can_harvest(resource_maker):
			harvesting = resource_maker[0]
			time_to_harvest = harvesting.time_to_harvest
			progress_bar = PB.instance()
			Y_Sort.add_child(progress_bar)
			progress_bar.animation = "no_color"
			progress_bar.global_position = global_position - Vector2(8, 20) # Offset for visuals
			progress_bar.speed_scale /= time_to_harvest
			progress_bar.playing = true
			progress_bar.z_index = 10
			state = STOPPED

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
				on_item_pos = null
			harvesting.uses -= 1
		
		# Only for visual queue
		interact()
		set_text()
		
		resource.picked_up = true
		
		# Stop harvesting if HOLDING_CAPACITY is full
		if len(held_items) >= HOLDING_CAPACITY:
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

func interact():
	if held_items:
		held_items[0].global_position = Vector2(global_position.x, global_position.y) + (last_direction * 8)
		
		if stacking_items:
			var tile_items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
			# Take items you run over if you're holding the same type of item
			if (len(tile_items) > 0 and held_items[0].item_name == tile_items[0].item_name
				and len(held_items) < HOLDING_CAPACITY):
				take_items(tile_items)
			
func wall_interact():
	# Check for walls in direction of last movement
	# Change player position to center (leg hitbox doesn't work)
	
	var wall = Main.world_layers["flesh_wall"][front_pos.y][front_pos.x]
  
	if wall and (last_direction.x == 0 or last_direction.y == 0) and (held_items 
		and held_items[0].item_name == "berry"):
		if len(held_items) >= wall["food_to_next_lvl"] - wall["current_food"]:
			for i in range(wall["food_to_next_lvl"] - wall["current_food"]):
				held_items[0].queue_free()
				held_items.remove(0)
			if held_items:
				held_items[0].visible = true
			Main.build_wall(front_pos, grid_pos)
		else:
			Main.world_layers["flesh_wall"][front_pos.y][front_pos.x]["current_food"] += len(held_items)
			for i in range(len(held_items)):
				held_items[0].queue_free()
				held_items.remove(0)
			Main.update_wall_progress(front_pos)
		set_text()
		return true
	return false
	
func altar_interact():
	if front_pos == Main.center_pos:
		if held_items and held_items[0].item_name == "berry" and FB.current != FB.threshold:
			for i in range(len(held_items)):
				if FB.current < FB.threshold:
					held_items[0].queue_free()
					held_items.remove(0)
					FB.update_bar(1)
			set_text()
			return true
	return false


func update_player_position(delta):
	velocity = direction * SPEED
	velocity = move_and_slide(velocity)
	var new_grid_pos = Main.Grass.world_to_map(global_position)
	if new_grid_pos != grid_pos:
		last_grid_pos = grid_pos
		grid_pos = new_grid_pos
		stacking_items = true
		

# Highlight 
func highlight():
	var items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
	items += Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x]
	
	front_pos = Main.Grass.world_to_map(global_position + last_direction * TILE_SIZE / 2)
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
			on_item_pos = Main.Grass.world_to_map(on_item.position)
			items[0].get_node("Visual").material.set_shader_param("width", 1.0)

	elif on_item != null:
		# Turn of highlight if the player isn't on a item
		on_item.get_node("Visual").material.set_shader_param("width", 0.0)
		on_item = null
		on_item_pos = null
	else:
		var wall = Main.world_layers["flesh_wall"][front_pos.y][front_pos.x]
		if wall and (last_direction.x == 0 or last_direction.y == 0):
			on_wall = true
		else:
			on_wall = false
		if on_wall:
			Main.ProgressBarIcon.set_position(Main.Grass.map_to_world(front_pos)) 
			Main.ProgressBarIcon.visible = true
			Main.update_wall_progress(front_pos)
		else:
			Main.ProgressBarIcon.visible = false

# Fuction takes an array of items
func take_items(items2):
	var items = [] + items2
	
	for item in items:
		var item_pos = Main.Grass.world_to_map(item.global_position)
		
		if len(held_items) < HOLDING_CAPACITY: 
			Main.world_layers["resources"][item_pos.y][item_pos.x].erase(item)
			held_items.append(item)
	
	for i in held_items:
		i.visible = false
		i.picked_up = true
	held_items[0].visible = true
	set_text()

# Function takes an array of items
func place_items(items2, item_pos = null):
	print(item_pos)
	var items = [] + items2

	if not item_pos:
		item_pos = grid_pos
	
	for item in items:
		Main.world_layers["resources"][item_pos.y][item_pos.x].append(item)
		item.global_position = item_pos * TILE_SIZE + item.self_offset
		item.visible = true
		item.picked_up = false
		held_items[0].picked_up = false
		held_items.erase(item)
	set_text()
		

# Checks if items can be placed on current tile
func can_place(tile_items):
	# Player has to be holding an item to place something
	if !held_items:
		return false
	
	# Check items occupying the tile
	if len(tile_items) > 0:
		
		# Check the items on ground match the held items
		if tile_items[0].item_name != held_items[0].item_name:
			return false 
		if len(tile_items) + len(held_items) > HOLDING_CAPACITY:
			return false
	
	# Check no resource makers are occupying the tile
	if Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x]:
		return false
	if Main.world_layers["flesh_wall"][grid_pos.y][grid_pos.x]:
		return false
	
	return true
	
# Checks if items can be taken from current tile
func can_take(tile_items):
	if len(tile_items) == 0 or held_items:
		return false
	if len(held_items) >= HOLDING_CAPACITY:
		return false
	return true

func can_switch(tile_items):
	if not held_items or not tile_items:
		return false
	return true

# Checks if player can harvest anything on current tile
func can_harvest(resource_maker):
	if len(held_items) >= HOLDING_CAPACITY:
		return false
	if len(resource_maker) <= 0:
		return false
	if held_items and resource_maker[0].resource_name != held_items[0].item_name:
		return false
	return true
