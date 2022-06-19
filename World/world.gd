extends Node2D

# World size
var world_width = 44
var world_height = 22

var world_tiles = [] # Do we ever use this?
var walls_to_dump = []

var dump_timer = Timer.new()
var wall_levels = [1,2,3,4,5] 

var circ = 9 # Circumference of corrupt area
var center_pos = Vector2(world_width/2, world_height/2) # Center of corrupt area

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
	"flesh_wall": [],
}

# Grass will need to be added manualy eventually
onready var Walls = preload("res://World/Walls.tscn").instance()
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()
onready var WallProgressBar = preload("res://WallProgressBar/WallProgressBar.tscn").instance()

func _ready():
	# Setup 
	get_node("YSort").add_child(Walls)
	add_child(Grass)
	add_child(WallProgressBar)
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
			# Spawn normal grass
			spawn_instance("grass", Vector2(_j,_i), 0)
		for layer in world_layers.keys():
			if layer == "flesh_wall":
				row.append(false)
			world_layers[layer].append(row.duplicate(true))
			
	# Spawn corrupt grass
	var zero_pos = center_pos - Vector2(circ/2,circ/2)
	
	for i in range(circ):
		var start = 0
		var end = 0
		if i <= circ / 2:
			start = circ / 2 - i
			end = ceil(float(circ)/2) + i
		else:
			start = i - circ / 2
			end = ceil(float(circ)/2) + circ + 1 - i
		for j in range(start, end):
			spawn_instance("grass", Vector2(zero_pos.x+j, zero_pos.y+i), 1)
	# Spawn objects
	spawn_instance("berry", Vector2(20,10))
	spawn_instance("berry", Vector2(21,11))
	spawn_instance("stone", Vector2(22,9))
	spawn_instance("berry_bush", center_pos)
	# Spawn walls
	zero_pos -= Vector2(1,1)
	circ += 2
	for i in range(circ):
		var placement = []
		if i <= circ / 2:
			placement = [circ / 2 - i,circ / 2 - i - 1, 
						 circ / 2 + i,circ / 2 + i + 1]
		else:
			placement = [i - ceil(float(circ)/2), i - circ/2,
						 circ + circ / 2 - i, circ + circ / 2 - 1 - i]
		for j in placement:
			var tile_pos = Vector2(zero_pos.x+j, zero_pos.y+i)
			if Walls.get_cellv(tile_pos) != 0 and j >= 0 and j <= circ - 1:
				# Spawn and add to wall_tiles
				spawn_instance("wall", tile_pos, 1)
				Walls.update_bitmask_region(Vector2(tile_pos.x-1,tile_pos.y-1),Vector2(tile_pos.x+1,tile_pos.y+1))
				spawn_instance("grass", tile_pos, 1)
				
func wall_dump():
	# Sometimes wall doesn't get dumped every cycle, need to fix
	var wall_dumped = false
	while len(walls_to_dump) > 0 and !wall_dumped:
		var wall_pos = walls_to_dump[0]
		walls_to_dump.remove(0)
		if Walls.get_cellv(wall_pos) == 1:
			spawn_instance("wall", wall_pos, -1)
			Walls.update_bitmask_region(Vector2(wall_pos.x-1,wall_pos.y-1),Vector2(wall_pos.x+1,wall_pos.y+1))
			world_layers["flesh_wall"][wall_pos.y][wall_pos.x] = false
			wall_dumped = true
		
func build_wall(wall_pos, player_grid_pos):
	var new_walls_pos = []
	# Create new walls
	for i in range(3):
		for j in range(3):
			var tile_pos = Vector2(wall_pos.x-1+j,wall_pos.y-1+i)
			if (!(world_layers["flesh_wall"][tile_pos.y][tile_pos.x]) and 
			player_grid_pos != tile_pos and 
			Grass.get_cellv(tile_pos) != 1):
				new_walls_pos.append(tile_pos)
				spawn_instance("wall", tile_pos, 1, wall_level(tile_pos))
				Walls.update_bitmask_region(Vector2(tile_pos.x-1,tile_pos.y-1),
											Vector2(tile_pos.x+1,tile_pos.y+1))
				spawn_instance("grass", tile_pos, 1)
				world_layers["flesh_wall"][wall_pos.y][wall_pos.x] = true
	# Replace old wall
	spawn_instance("wall", wall_pos, -1)
	Walls.update_bitmask_region(Vector2(wall_pos.x-1,wall_pos.y-1),Vector2(wall_pos.x+1,wall_pos.y+1))
	world_layers["flesh_wall"][wall_pos.y][wall_pos.x] = false
	find_dump_walls(new_walls_pos)
	
func update_wall_progress(wall_pos):
	var wall = world_layers["flesh_wall"][wall_pos.y][wall_pos.x]
	WallProgressBar.get_node("TextureProgress").value = (float(wall["current_food"])/
														 float(wall["food_to_next_lvl"]))*100
	
func wall_level(wall_pos):
	var distance = sqrt(pow(center_pos.x - wall_pos.x, 2) + pow(center_pos.y - wall_pos.y, 2))
	if distance <= 5:
		return 0
	elif distance <= 8:
		return 1
	elif distance <= 11:
		return 2
	elif distance <= 14:
		return 3
	else:
		return 4
	
func find_dump_walls(new_walls_pos):
	var walls_to_check = []
	for wall_pos in new_walls_pos:
		for i in range(3):
			for j in range(3):
				var tile_pos = Vector2(wall_pos.x-1+j,wall_pos.y-1+i)
				if world_layers["flesh_wall"][tile_pos.y][tile_pos.x]:
					walls_to_check.append(tile_pos)
	var new_walls_to_dump = []
	for wall_pos in walls_to_check:
		var corrupt_surroundings = 0
		for i in range(3):
			for j in range(3):
				var tile_pos = Vector2(wall_pos.x-1+j,wall_pos.y-1+i)
				if tile_pos != wall_pos and Grass.get_cellv(tile_pos) == 1:
					corrupt_surroundings += 1
		if corrupt_surroundings == 8 and !walls_to_dump.has(wall_pos):
			new_walls_to_dump.append(wall_pos)
	for wall in new_walls_to_dump:
		walls_to_dump.append(wall)
	
func spawn_instance(instance_id, pos, tilemap_id = false, wall_level = 0):
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
			"level" : wall_level,
			"current_food" : 0,
			"food_to_next_lvl" : wall_levels[wall_level]
		}
		if tilemap_id != -1:
			world_layers["flesh_wall"][pos.y][pos.x] = wall_attributes
		else:
			world_layers["flesh_wall"][pos.y][pos.x] = false
	elif instance_id == "grass":
		Grass.set_cellv(pos, tilemap_id)
