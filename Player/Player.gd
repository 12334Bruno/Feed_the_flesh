extends KinematicBody2D

# Movement constatns
var SPEED = 90

# Movement
var direction = Vector2.ZERO
var last_direction = direction
var velocity = Vector2.ZERO

# Items
var held_item = null

# World constatns
var TILE_SIZE = 16

func _physics_process(delta):
	take_player_input()
	interact()
	update_player_movement(delta)


func _unhandled_input(event):
	
	# Check for interactable objects 
	if event.is_action_pressed("ui_interact"):
		
		# Detect any interactable objects with a raycast
		var space_state = get_world_2d().direct_space_state
		var ray = Vector2(100, 0).rotated(last_direction.angle()) + global_position
		var result = space_state.intersect_ray(global_position, ray, [self, held_item])
		
		if held_item:
			var snapped_position = Vector2()
			snapped_position.x = stepify(global_position.x - TILE_SIZE, TILE_SIZE) + TILE_SIZE
			snapped_position.y = stepify(global_position.y - TILE_SIZE, TILE_SIZE) + TILE_SIZE
			
			held_item.global_position = snapped_position
			
			held_item = null
		
		# Check for collision and for type of item
		if result.get("collider") != null:
			if result.get("collider").type == "pickupable_item":
				held_item = result.get("collider")
			
			

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

func interact():
	
	if held_item:
		held_item.global_position = global_position + (last_direction * 13)
	
	
