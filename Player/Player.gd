extends KinematicBody2D

# World constatns
var TILE_SIZE = 16

# Movement constatns
var SPEED = 90

# Movement
var direction = Vector2.ZERO
var last_direction = direction
var velocity = Vector2.ZERO

# Items
var held_items = []
var on_item = null
var on_wall = null

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
onready var Berry = preload("res://Items/Berries.tscn")

# Load nodes
onready var text_label = $Control/Label


func set_text():
	text_label.text = str(len(held_items), "/3")

func _physics_process(delta):
	highlight()
	
	match state:
		ACTIVE:
			interact()
			take_player_input()
			update_player_movement(delta)
		STOPPED:
			harvesting(delta)


func _unhandled_input(event):
	
	# Check for interactable objects/items 
	if event.is_action_pressed("ui_interact"):
		
		var player_grid_pos = Main.Grass.world_to_map(global_position)
		var items = Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x]
		
		# Wall interaction has priority
		if !wall_interact(player_grid_pos) and can_place():
			for item in held_items:
				Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x].append(item)
				item.global_position = player_grid_pos * TILE_SIZE
				item.visible = true
				item.picked_up = false
				held_items[0].picked_up = false
			held_items = []
			set_text()
				
		elif can_take():
			if Input.is_action_just_pressed("ui_take_one_item"):
				held_items.append(items[0])
				Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x].erase(held_items[0])
				held_items[0].picked_up = true
				held_items[0].visible = true
			else:
				held_items = [] + items
				for i in held_items:
					i.visible = false
					i.picked_up = true
				held_items[0].visible = true
				Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x].clear()
			set_text()
		elif can_harvest():
			harvesting = Main.world_layers["resource_makers"][player_grid_pos.y][player_grid_pos.x][0]
			time_to_harvest = harvesting.time_to_harvest
			state = STOPPED

func harvesting(delta):
	if Input.is_action_pressed("ui_interact"):
		harvest_timer += delta
	else:
		harvest_timer = 0
		time_to_harvest = 0
		state = ACTIVE
		harvesting = null
		
	if harvest_timer > time_to_harvest:
		var berry = harvesting.resource.instance()
		Main.add_child(berry)
		held_items.append(berry)
		harvest_timer = 0
		
		# Only for visual queue
		interact()
		set_text()
		berry.picked_up = true
		
		if len(held_items) >= 3:
			harvest_timer = 0
			time_to_harvest = 0
			state = ACTIVE
			harvesting = null
		

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
		held_items[0].global_position = Vector2(global_position.x, global_position.y - 8)
		
func wall_interact(player_grid_pos):
	# Check for walls in direction of last movement
	# Change player position to center (leg hitbox doesn't work)
	player_grid_pos = Main.Grass.world_to_map(global_position+Vector2(0,-TILE_SIZE/2))
	var wall_pos = Vector2(player_grid_pos.x+round(last_direction.x), player_grid_pos.y+round(last_direction.y))
	var wall = Main.world_layers["flesh_wall"][wall_pos.y][wall_pos.x]
	if wall and (last_direction.x == 0 or last_direction.y == 0) and held_items and held_items[0].item_name == "berry":
		if len(held_items) >= wall["food_to_next_lvl"] - wall["current_food"]:
			for i in range(wall["food_to_next_lvl"] - wall["current_food"]):
				held_items[0].queue_free()
				held_items.remove(0)
			if held_items:
				held_items[0].visible = true
			Main.build_wall(wall_pos, player_grid_pos)
		else:
			Main.world_layers["flesh_wall"][wall_pos.y][wall_pos.x]["current_food"] += len(held_items)
			for i in range(len(held_items)):
				held_items[0].queue_free()
				held_items.remove(0)
			Main.update_wall_progress(wall_pos)
		set_text()
		return true
	return false

func update_player_movement(delta):
	velocity = direction * SPEED
	velocity = move_and_slide(velocity)

# Highlight 
func highlight():
	var player_grid_pos = Main.Grass.world_to_map(global_position)
	var items = Main.world_layers["resources"][player_grid_pos.y][player_grid_pos.x]
	items += Main.world_layers["resource_makers"][player_grid_pos.y][player_grid_pos.x]
	# Set highlight if player is on interactable item 
	if len(items) > 0:
		# Check if item is interactable
		if items[0].get("interactable"):
			
			# Remove highlight from old item and add to new
			if on_item != items[0] and on_item != null:
				on_item.material.set_shader_param("width", 0.0)
			on_item = items[0]
			items[0].material.set_shader_param("width", 1.0)

	elif on_item != null:
		# Turn of highlight if the player isn't on a item
		on_item.material.set_shader_param("width", 0.0)
		on_item = null
	else:
		player_grid_pos = Main.Grass.world_to_map(global_position+Vector2(0,-TILE_SIZE/2))
		var wall_pos = Vector2(player_grid_pos.x+round(last_direction.x), player_grid_pos.y+round(last_direction.y))
		var wall = Main.world_layers["flesh_wall"][wall_pos.y][wall_pos.x]
		if wall and (last_direction.x == 0 or last_direction.y == 0):
			on_wall = true
		else:
			on_wall = false
		if on_wall:
			Main.WallProgressBar.set_position(Main.Grass.map_to_world(wall_pos)) 
			Main.WallProgressBar.visible = true
			Main.update_wall_progress(wall_pos)
		else:
			Main.WallProgressBar.visible = false

func can_place():
	var grid_pos = Main.Grass.world_to_map(global_position)
	var tile_items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
	# Player has to be holding an item to place something
	if !held_items:
		return false
	
	# Check items occupying the tile
	if len(tile_items) > 0:
		
		# Check the items on ground match the held items
		if tile_items[0].item_name != held_items[0].item_name:
			return false 
		if len(tile_items) + len(held_items) > 3:
			return false
	
	# Check no resource makers are occupying the tile
	if Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x]:
		return false
	if Main.world_layers["flesh_wall"][grid_pos.y][grid_pos.x]:
		return false
	
	return true

func can_take():
	var grid_pos = Main.Grass.world_to_map(global_position)
	var tile_items = Main.world_layers["resources"][grid_pos.y][grid_pos.x]
	if len(tile_items) <= 0 or held_items:
		return false
	return true

func can_harvest():
	var grid_pos = Main.Grass.world_to_map(global_position)
	var resource_maker = Main.world_layers["resource_makers"][grid_pos.y][grid_pos.x]
	if len(resource_maker) <= 0:
		return false
	if held_items and resource_maker[0].resource_name != held_items[0].item_name:
		return false
	return true
