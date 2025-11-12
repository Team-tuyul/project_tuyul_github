extends Node2D

@onready var bgm = $AudioStreamPlayer2D
# Ganti path ini dengan lokasi file scene UI CanvasLayer Anda.
const UI_SCENE = preload("res://uidesign5/canvas_layer.tscn")

# ⚡️ PATH KE SCENE KARAKTER BARU
const KARAKTER_PEDANG_SCENE = preload("res://Pemain/player_sword.tscn") # PASTIKAN PATH INI BENAR!

var ui_instance = null
var current_player = null

func _ready():
	# 1. Muat dan Tambahkan UI
	ui_instance = UI_SCENE.instantiate()
	add_child(ui_instance)
	print("Antarmuka Pengguna In-Game (CanvasLayer) telah berhasil dimuat dan ditampilkan.")
	
	# 2. ⚡️ MENCARI PLAYER UNARMED (Node Player Lama)
	# Pastikan nama Node Player Unarmed di World Scene adalah 'player_unarmed_fariz'
	current_player = $player_unarmed_fariz
	
	# 3. HUBUNGKAN SINYAL PERGANTIAN KARAKTER DARI PLAYER LAMA
	if current_player and is_instance_valid(current_player) and current_player.has_signal("request_scene_change"):
		current_player.request_scene_change.connect(_ganti_karakter)
		print("DEBUG: Sinyal Player Unarmed berhasil terhubung.")
	else:
		# Jika nama Node salah atau Node belum ada saat _ready(), error ini muncul.
		print("ERROR: Player lama tidak ditemukan atau tidak memiliki sinyal 'request_scene_change'.")
	
	# 4. Mulai BGM
	bgm.play()
	bgm.stream.loop = true

# =========================================================================
# FUNGSI PENGGANTIAN KARAKTER
# =========================================================================
func _ganti_karakter(posisi_lama: Vector2):
	
	# 1. Player lama sudah dihapus oleh dirinya sendiri (queue_free())
	current_player = null
		
	# 2. Buat Instance Karakter Baru (Player Sword)
	var karakter_baru = KARAKTER_PEDANG_SCENE.instantiate()
	
	if karakter_baru == null:
		print("FATAL ERROR: Instancing player_sword.tscn gagal. Cek path/file.")
		return
		
	# 3. ⚡️ SOLUSI ALTERNATIF: Gunakan set_global_position() eksplisit
	karakter_baru.set_global_position(posisi_lama)
	
	# 4. Tambahkan ke Scene
	add_child(karakter_baru)
	
	# 5. Update referensi Player yang aktif
	current_player = karakter_baru
	
	# 6. Hubungkan Sinyal dari Player Baru (jika Player baru juga bisa memicu pergantian)
	if current_player.has_signal("request_scene_change"):
		current_player.request_scene_change.connect(_ganti_karakter)
	
	# 7. ⚡️ AKTIFKAN KAMERA DI KARAKTER BARU & DEBUG VISUAL
	if current_player.has_node("Camera2D"):
		current_player.get_node("Camera2D").make_current()
	else:
		print("DEBUG: Peringatan! Karakter baru tidak memiliki Node Camera2D.")
		
	# ⚡️ DEBUG TAMBAHAN: Cek offset AnimatedSprite2D
	if current_player.has_node("AnimatedSprite2D"):
		var sprite_pos = current_player.get_node("AnimatedSprite2D").position
		print("DEBUG: Posisi AnimatedSprite2D relatif: ", sprite_pos)
		if sprite_pos.length() > 50: # Angka 50 bisa disesuaikan
			print("PERINGATAN! Sprite memiliki offset besar. Kemungkinan ini penyebab tidak terlihat!")

	print("Karakter berhasil diganti ke versi Pedang di posisi: ", posisi_lama)


# =========================================================================
# FUNGSI PENGONTROL PAUSE GAME (Tidak Berubah)
# =========================================================================
func set_game_paused(is_paused: bool):
	get_tree().paused = is_paused
	
	if ui_instance:
		if is_paused:
			ui_instance.call_deferred("show_pause_menu")
		else:
			ui_instance.call_deferred("hide_pause_menu")
	
	print("Game status diubah: Paused = ", is_paused)
	
func _on_ui_pause_requested():
	set_game_paused(true)

func _on_ui_resume_requested():
	set_game_paused(false)
