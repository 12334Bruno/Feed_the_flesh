extends AnimatedSprite

# Obejct info
var interactable = false
var item_name = "berry_bush"

onready var timer = $Timer
onready var Berry = preload("res://Items/Berries.tscn")
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()
onready var Main = get_parent()

var resource_generated = false
var berry = null

func _ready():
	timer.start()

func _on_Timer_timeout():
	var grid_pos = Grass.world_to_map(global_position)
	
	timer.stop()
	berry = Berry.instance()
	berry.connect("picked_up", self, "make_berry")
	berry.global_position = global_position
	get_parent().add_child(berry)
	Main.world_layers["resources"][grid_pos.y][grid_pos.x].append(berry)

func make_berry():
	berry.disconnect("picked_up", self, "make_berry")
	timer.start()
	
