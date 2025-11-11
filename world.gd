extends Node2D
# world.gd (Script yang terpasang pada Node 'World')

# Preload scene UI agar siap dimuat
const IN_GAME_UI_SCENE = preload("res://uidesign5/in_game_ui.tscn")

func _ready():
	# 1. Membuat instance dari scene UI
	var ui_instance = IN_GAME_UI_SCENE.instantiate()
	
	# 2. Menambahkan instance UI sebagai child dari Node World (self)
	add_child(ui_instance)
	
	# UI sekarang akan menjadi child dari Node World dan ditampilkan di atas game
