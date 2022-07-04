extends TextureProgress

onready var tween = $Tween

var current_time = 0
var cycle_time = 30

func _ready():
	update_bar()

func update_bar(amount=0):
	current_time += amount
	var new_value = 100*(float(current_time)/float(cycle_time))
	tween.interpolate_property(self, "value", value, new_value, 0.3, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
