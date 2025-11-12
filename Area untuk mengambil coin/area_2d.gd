extends Area2D

@export var item_name: String = "sword"

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Pastikan yang menyentuh punya group 'player'
	if body.is_in_group("player"):
		match item_name:
			"sword":
				# ⚡️ Panggil fungsi di Player yang akan memicu pergantian Scene
				if body.has_method("ambil_pedang"):
					body.ambil_pedang()
				
			"coin":
				if body.has_method("tambah_koin"):
					body.tambah_koin(1)
		
		queue_free() # Hilangkan item dari dunia setelah diambil
