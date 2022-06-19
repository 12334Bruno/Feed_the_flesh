extends AnimatedSprite

# Obejct info
var item_name = "berry_bush"

onready var Berry = preload("res://Items/Berries.tscn")
onready var Grass = preload("res://World/Environment/Grass.tscn").instance()
onready var Main = get_parent()
	
