extends Area2D

var nearby_item: Node = null  # item yang bisa diambil

func _ready():
	monitoring = true
	monitorable = true

func _on_area_entered(area):
	if area.is_in_group("item"):
		nearby_item = area

func _on_area_exited(area):
	if nearby_item == area:
		nearby_item = null

func try_interact():
	if nearby_item:
		if nearby_item.has_method("on_picked"):
			nearby_item.on_picked()
			nearby_item = null
