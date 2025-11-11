extends Area2D

@export var lifetime := 5.0  # coin hilang setelah 5 detik

func _ready():
	# timer agar coin hilang otomatis
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Coin diambil!")
		queue_free()
