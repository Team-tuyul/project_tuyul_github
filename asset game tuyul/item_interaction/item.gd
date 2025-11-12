extends Area2D

@export var item_name: String = "Gold"
@export var amount: int = 1

func _ready():
	add_to_group("item")  # penting supaya player_interaction gampang deteksi

func pick_up():
	# efek saat diambil: suara / efek / tambah inventory (nanti)
	print("Picked up:", item_name, "x", amount)
	queue_free()  # hapus item dari scene
