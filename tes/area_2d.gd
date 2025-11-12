extends Area2D

func _ready():
	add_to_group("item")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player mengambil item:", name)
		queue_free()  # hapus item setelah diambil
