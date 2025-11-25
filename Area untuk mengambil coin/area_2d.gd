extends Area2D

@export var item_name: String = "sword"
@onready var sfx = $AudioStreamPlayer2D

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		
		match item_name:
			"sword":
				if body.has_method("ambil_pedang"):
					body.ambil_pedang()

			"coin":
				if body.has_method("tambah_koin"):
					body.tambah_koin(1)

		# 🔊 Mainkan suara pickup jika ada
		if sfx.stream != null:
			sfx.play()
			# Hapus item setelah suara selesai
			await sfx.finished
			queue_free()
		else:
			queue_free()
