extends Node2D

# World size
var world_width = 44
var world_height = 22
var world_tiles = []
var wall_tiles = []

# Ids
var resource_ids = {
	"berry": preload("res://Items/Berries.tscn"),
	"stone": preload("res://Items/Stone.tscn")
}
var resource_maker_ids = {
	"berry_bush": preload("res://Items/ItemGenerators/BerryBush.tscn")
}

# World Layers
var world_layers = {
	"resources": [],
	"resource_makers": [],
}

# Grass will need to be added manualy eventually
onready var Walls = preload("res://World/Walls.tscn").instance()
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()

func _ready():
	# Setup 
	get_node("YSort").add_child(Walls)
	add_child(Grass)
	# Save world tiles and wall tiles into array 
	for _i in range(world_height):
		var row = []
		for _j in range(world_width):
			row.append([]) 
			spawn_instance("grass", Vector2(_j,_i), 0)
		for layer in world_layers.keys():
			world_layers[layer].append(row.duplicate(true))
		
		row.append(false)
		wall_tiles.append(row.duplicate(true))
		
			
	var zero_pos = Vector2(8,3)
	for i in range(7):
		var start = 0
		var end = 0
		if i <= 3:
			start = 3 - i
			end = 4 + i
		else:
			start = i - 3
			end = 12 - i
		for j in range(start, end):
			spawn_instance("grass", Vector2(zero_pos.x+j, zero_pos.y+i), 1)
	# Spawn objects
	spawn_instance("berry", Vector2(9,5))
	spawn_instance("berry", Vector2(10,4))
	spawn_instance("stone", Vector2(2,4))
	spawn_instance("berry_bush", Vector2(2,2))
	# Spawn walls
	zero_pos = Vector2(7,2)
	for i in range(9):
		var placement = []
		if i <= 4:
			placement = [4-i,4-i-1,4+i,4+i+1]
		else:
			placement = [i-5,i-4,13-i,12-i]
		for j in placement:
			var tile_pos = Vector2(zero_pos.x+j, zero_pos.y+i)
			if Walls.get_cellv(tile_pos) != 0 and j >= 0 and j <= 8:
				# Spawn and add to wall_tiles
				spawn_instance("wall", tile_pos, 0)
				
	
	
func spawn_instance(instance_id, pos, tilemap_id = false):
	if instance_id in resource_ids.keys():
		var spawned_instance = resource_ids[instance_id].instance()
		spawned_instance.set_position(Grass.map_to_world(pos))
		spawned_instance.z_index = -1
		world_layers["resources"][pos.y][pos.x].append(spawned_instance) 
		add_child(spawned_instance)
	elif instance_id in resource_maker_ids.keys():
		var spawned_instance = resource_maker_ids[instance_id].instance()
		spawned_instance.set_position(Grass.map_to_world(pos))
		spawned_instance.z_index = -1
		world_layers["resource_makers"][pos.y][pos.x].append(spawned_instance) 
		add_child(spawned_instance)
	elif instance_id == "wall":
		Walls.set_cellv(pos, tilemap_id)
		var wall_attributes = {
			"level" : 0,
			"current_food" : 0,
			"food_to_next_lvl" : 1
		}
		if tilemap_id != -1:
			wall_tiles[pos.y][pos.x] = true
		else:
			wall_tiles[pos.y][pos.x] = false
	elif instance_id == "grass":
		Grass.set_cellv(pos, tilemap_id)
