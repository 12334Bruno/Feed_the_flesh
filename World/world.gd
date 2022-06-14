extends Node2D

# World size
var world_width = 44
var world_height = 22
var world_tiles = []
var wall_tiles = []
var walls_to_dump = []
var dump_timer = Timer.new()

var scene_ids = {
	"berry" : preload("res://Items/Berries.tscn"),
	"stone" : preload("res://Items/Stone.tscn")
}

# Grass will need to be added manualy eventually
onready var Walls = preload("res://World/Walls.tscn").instance()
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()

func _ready():
	# Setup 
	get_node("YSort").add_child(Walls)
	add_child(Grass)
	# Create timer for dumping inside walls
	dump_timer.connect("timeout", self, "wall_dump")
	dump_timer.set_wait_time(2)
	dump_timer.set_one_shot(false)
	add_child(dump_timer)
	dump_timer.start()
	# Save world tiles and wall tiles into array 
	for _i in range(world_height):
		var row = []
		for _j in range(world_width):
			row.append([]) 
		world_tiles.append(row)
	for _i in range(world_height):
		var row = []
		for _j in range(world_width):
			row.append(false) 
		wall_tiles.append(row)
	# Spawn normal and corrupt grass 
	for i in range(world_height):
		for j in range(world_width):
			spawn_instance("grass", Vector2(j,i), 0)
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
				spawn_instance("grass", tile_pos, 1)
				
func wall_dump():
	# Sometimes wall doesn't get dumped every cycle, need to fix
	if len(walls_to_dump) > 0:
		var wall_pos = walls_to_dump[0]
		for i in range(3):
			for j in range(3):
				var tile_pos = Vector2(wall_pos.x-1+j,wall_pos.y-1+i)
				if (!(wall_tiles[tile_pos.y][tile_pos.x]) and
				Grass.get_cellv(tile_pos) != 1):
					spawn_instance("wall", tile_pos, 0)
					spawn_instance("grass", tile_pos, 1)
					wall_tiles[wall_pos.y][wall_pos.x] = true
		spawn_instance("wall", wall_pos, -1)
		wall_tiles[wall_pos.y][wall_pos.x] = false
		walls_to_dump.remove(0)
	
func spawn_instance(instance_id, pos, tilemap_id = false):
	if instance_id == "berry" or instance_id == "stone":
		var spawned_instance = scene_ids[instance_id].instance()
		spawned_instance.set_position(Grass.map_to_world(pos))
		spawned_instance.z_index = -1
		world_tiles[pos.y][pos.x].append(spawned_instance) 
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
