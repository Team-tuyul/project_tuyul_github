extends Node2D

# Ganti path ini dengan lokasi file scene UI CanvasLayer Anda.
# Contoh: "res://UI/main_hud.tscn"
const UI_SCENE = preload("res://uidesign5/canvas_layer.tscn")

var ui_instance = null # Variabel untuk menyimpan referensi instance UI

# Fungsi ini dipanggil secara otomatis saat node dan semua child-nya siap.
func _ready():
	# 1. Buat instance (salinan) dari scene UI yang sudah dimuat.
	ui_instance = UI_SCENE.instantiate()
	
	# 2. Tambahkan instance UI sebagai child dari node ini (misalnya, "World").
	add_child(ui_instance)
	
	# Opsional: Pesan debug untuk konfirmasi
	print("Antarmuka Pengguna In-Game (CanvasLayer) telah berhasil dimuat dan ditampilkan.")
	
	# Opsional: Hubungkan input tombol tertentu (misalnya tombol 'ESC') ke fungsi pause
	# if Input.is_action_just_pressed("ui_cancel"):
	# 	set_game_paused(not get_tree().paused)


# =========================================================================
# FUNGSI PENGONTROL PAUSE GAME
# Fungsi ini dipanggil dari skrip UI (misalnya, saat tombol 'Pause' atau 'Resume' diklik)
# =========================================================================
func set_game_paused(is_paused: bool):
	# 1. Mengatur status pause untuk seluruh Godot engine
	get_tree().paused = is_paused
	
	# 2. Mengontrol tampilan menu pause di UI
	if ui_instance:
		# Asumsikan Anda memiliki fungsi show_pause_menu() dan hide_pause_menu()
		# di skrip yang melekat pada CanvasLayer (in_game_ui.gd)
		if is_paused:
			# Tampilkan menu pause
			ui_instance.call_deferred("show_pause_menu") 
		else:
			# Sembunyikan menu pause
			ui_instance.call_deferred("hide_pause_menu")
	
	print("Game status diubah: Paused = ", is_paused)
