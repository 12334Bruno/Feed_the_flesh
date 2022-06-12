extends Node2D

# World size
var world_width = 44
var world_height = 22
var world_tiles = []

var scene_ids = {
	"berry" : preload("res://Items/Berries.tscn"),
	"stone" : preload("res://Items/Stone.tscn")
}

# Grass will need to be added manualy eventually
onready var Walls = preload("res://World/Walls.tscn").instance()
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()

func _ready():
	# Setup Wall tiles
	get_node("YSort").add_child(Walls)
	# Save world tiles into array 
	for _i in range(world_height):
		var row = []
		for _j in range(world_width):
			row.append([]) 
		world_tiles.append(row)
		
	# Spawn berries 
	spawn_instance("berry", Vector2(9,5))
	spawn_instance("berry", Vector2(10,4))
	spawn_instance("stone", Vector2(2,4))
	# Spawn walls
	var zero_pos = Vector2(7,2)
	for i in range(9):
		var placement = []
		if i <= 4:
			placement = [4-i,4-i-1,4+i,4+i+1]
		else:
			placement = [i-5,i-4,13-i,12-i]
		for j in placement:
			var tile_pos = Vector2(zero_pos.x+j, zero_pos.y+i)
			if Walls.get_cellv(tile_pos) != 0 and j >= 0 and j <= 8:
				spawn_instance("wall", tile_pos, 0)
	spawn_instance("wall", Vector2(7,6), -1)
	
	
func spawn_instance(instance_id, position, tilemap_id = false):
	if instance_id == "berry" or instance_id == "stone":
		var spawned_instance = scene_ids[instance_id].instance()
		spawned_instance.set_position(Grass.map_to_world(position))
		spawned_instance.z_index = -1
		world_tiles[position.y][position.x].append(spawned_instance) 
		add_child(spawned_instance)
	elif instance_id == "wall":
		Walls.set_cellv(position, tilemap_id)
