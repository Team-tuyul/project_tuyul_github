extends Node2D

# Ganti path ini dengan lokasi file scene UI CanvasLayer Anda.
# Contoh: "res://UI/main_hud.tscn"
const UI_SCENE = preload("res://uidesign5/canvas_layer.tscn")

# Fungsi ini dipanggil secara otomatis saat node dan semua child-nya siap.
func _ready():
	# 1. Buat instance (salinan) dari scene UI yang sudah dimuat.
	var ui_instance = UI_SCENE.instantiate()
	
	# 2. Tambahkan instance UI sebagai child dari node ini (misalnya, "World").
	# Karena UI_SCENE adalah CanvasLayer, ia akan otomatis di-render
	# di atas konten game 2D/3D Anda.
	add_child(ui_instance)
	
	# Opsional: Pesan debug untuk konfirmasi
	print("Antarmuka Pengguna In-Game (CanvasLayer) telah berhasil dimuat dan ditampilkan.")

# Tambahkan fungsi lain di sini (misalnya, fungsi untuk pause game, update skor, dll.)
