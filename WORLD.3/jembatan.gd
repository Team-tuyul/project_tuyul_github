extends Area2D

func _on_body_entered(body):
	if body.name == "CharacterBody2D":
		# Matikan deteksi collision terhadap air (layer 2)
		body.set_collision_mask_value(2, false)

func _on_body_exited(body):
	if body.name == "CharacterBody2D":
		# Nyalakan lagi collision terhadap air setelah keluar dari jembatan
		body.set_collision_mask_value(2, true)
