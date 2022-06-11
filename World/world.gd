extends Node2D

# World size
var world_width = 44
var world_height = 22
var world_tiles = []

var scene_ids = {
	"ground" : preload("res://World/Environment/Grass.tscn"),
	"berry" : preload("res://Items/Berries.tscn")
}

onready var Main = get_node("/root/main")
onready var Grass = get_node("/root/main/Grass")

func _ready():
	# Save world tiles into array 
	for _i in range(world_height):
		var row = []
		for _j in range(world_width):
			row.append([]) 
		world_tiles.append(row)
		
	# Spawn berries (TEST!)
	_spawn_instance("berry", Vector2(2,3))
	_spawn_instance("berry", Vector2(2,4))
	
func _spawn_instance(instance_id, position):
	var spawned_instance = scene_ids[instance_id].instance()
	spawned_instance.set_position(Grass.map_to_world(position))
	spawned_instance.z_index = -1
	world_tiles[position.y][position.x].append(spawned_instance) 
	if instance_id == "berry":
		Main.add_child(spawned_instance)
