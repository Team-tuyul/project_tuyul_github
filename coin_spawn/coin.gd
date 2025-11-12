extends Area2D

@export var lifetime := 5.0 # Variabel ini masih ada, tapi tidak digunakan lagi

func _ready():
	# Kode timer yang menyebabkan coin hilang otomatis telah dihapus atau dinonaktifkan.
	# HAPUS: await get_tree().create_timer(lifetime).timeout
	# HAPUS: queue_free()
	pass # Fungsi _ready() sekarang tidak melakukan apa-apa.

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Coin diambil!")
		# Koin hanya akan hilang setelah diambil oleh player
		queue_free()
