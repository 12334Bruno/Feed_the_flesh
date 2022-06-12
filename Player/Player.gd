extends KinematicBody2D

# Movement constatns
var SPEED = 90

# Movement
var direction = Vector2.ZERO
var last_direction = direction
var velocity = Vector2.ZERO

# Items
var held_item = null
var on_item = null

# World constatns
var TILE_SIZE = 16

# Load scenes
onready var Main = get_parent().get_parent()
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()

func _ready():
	set_position(Vector2(192,144))

func _physics_process(delta):
	highlight()
	take_player_input()
	update_player_movement(delta)


func _unhandled_input(event):
	
	# Check for interactable objects 
	if event.is_action_pressed("ui_interact"):
		
		# Snap released item to grid
		if held_item:
			var snapped_position = Vector2()
			snapped_position.x = stepify(global_position.x - TILE_SIZE/2, TILE_SIZE) + TILE_SIZE/2
			snapped_position.y = stepify(global_position.y - TILE_SIZE/2, TILE_SIZE) + TILE_SIZE/2
			
			held_item.global_position = snapped_position
			
			held_item = null
			
		var player_position = global_position + Vector2(Globals.GRID_SIZE / 2, Globals.GRID_SIZE / 2)
		var player_grid_pos = Grass.world_to_map(player_position)
#		print(Main.world_tiles[player_grid_pos.x][player_grid_pos.y])
			

func take_player_input():
	# Take player direction input
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction = Vector2(x_input, y_input).normalized()
	
	# Set last_direction when moving 
	if x_input != 0 or y_input != 0:
		last_direction = direction
	
func update_player_movement(delta):
	velocity = direction * SPEED
	velocity = move_and_slide(velocity)

# Highlight 
func highlight():
	var player_grid_pos = Grass.world_to_map(global_position)
	var items = Main.world_tiles[player_grid_pos.y][player_grid_pos.x]
	
	if len(items) > 0:
		if items[0].interactable:
			if on_item != items[0] and on_item != null:
				on_item.get_node("Sprite").material.set_shader_param("width", 0.0)
			on_item = items[0]
			items[0].get_node("Sprite").material.set_shader_param("width", 1.0)
	elif on_item != null:
		on_item.get_node("Sprite").material.set_shader_param("width", 0.0)

