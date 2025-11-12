extends MarginContainer 

# --- Properti Audio ---
@export var audio_bus_name: String = "Music" 
var music_bus_index: int = -1
var sfx_bus_index: int = -1 

# --- Properti Kecerahan (Brightness) ---
var canvas_modulate: CanvasModulate 

# --- Properti SFX ---
var menu_sfx_player: AudioStreamPlayer2D = null # HARUS AudioStreamPlayer2D

func _ready() -> void:
	# 1. Dapatkan Indeks Bus Audio
	music_bus_index = AudioServer.get_bus_index(audio_bus_name)
	sfx_bus_index = AudioServer.get_bus_index("SFX") 
	
	# 2. Dapatkan CanvasModulate
	canvas_modulate = get_tree().get_root().find_child("CanvasModulate", true, false)
	
	# --- Inisialisasi SFX Player ---
	menu_sfx_player = $MenuSFX # Mengakses AudioStreamPlayer2D yang ada sebagai child
	
	if is_instance_valid(menu_sfx_player) and sfx_bus_index != -1:
		menu_sfx_player.bus = "SFX" # Atur Bus SFX

	# ----------------------------------------------------------------------
	# --- INISIALISASI TOMBOL TOGGLE ---
	# ----------------------------------------------------------------------
	
	var popup_menu = get_parent() # Parent dari settingMenu (asumsi: popupMenu)
	
	if is_instance_valid(popup_menu):
		
		# A. Tombol Pembuka Menu Pengaturan ("Bar Putih yang Memanjang")
		# Jalur: popupMenu/baseMenuOpenButtonContainer/toggleMenuButton
		var open_setting_button = popup_menu.get_node("baseMenuOpenButtonContainer/toggleMenuButton")
		
		# B. Tombol Penutup Menu Pengaturan (Di dalam Menu Setting)
		# Jalur: popupMenu/menu/baseMenuScreen/VBoxContainer/toggleMenuButton
		var close_setting_button = popup_menu.get_node("menu/baseMenuScreen/VBoxContainer/toggleMenuButton")
		
		# Hubungkan Tombol Pembuka (Bar Putih)
		if is_instance_valid(open_setting_button) and open_setting_button is Button:
			open_setting_button.pressed.connect(_on_menu_toggled) 
			# SFX AKAN BERMAIN DI SINI
		else:
			print("PERINGATAN: Tombol Pembuka Setting Menu tidak ditemukan/salah tipe.")
			
		# Hubungkan Tombol Penutup
		if is_instance_valid(close_setting_button) and close_setting_button is Button:
			close_setting_button.pressed.connect(_on_menu_toggled) 
			# SFX AKAN BERMAIN DI SINI
		else:
			print("PERINGATAN: Tombol Penutup Setting Menu tidak ditemukan/salah tipe.")
	
	# --- Inisialisasi Slider Volume dan Kecerahan ---
	var volume_slider = $NinePatchRect/VBoxContainer/VBoxContainer/volumeBar/VBoxContainer/HSlider
	var brightness_slider = $NinePatchRect/VBoxContainer/brightnessBar/VBoxContainer/HScrollBar
	
	# Hubungkan Volume
	if music_bus_index != -1 and is_instance_valid(volume_slider):
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
		volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	
	# Hubungkan Kecerahan
	if is_instance_valid(canvas_modulate) and is_instance_valid(brightness_slider):
		brightness_slider.value = canvas_modulate.color.r 
		brightness_slider.value_changed.connect(_on_brightness_slider_value_changed)
		brightness_slider.max_value = 1.0
		brightness_slider.min_value = 0.0

# ----------------------------------------------------------------------
# --- FUNGSI PENGELOLA TOGGLE MENU DAN SFX ---
# ----------------------------------------------------------------------

func _on_menu_toggled() -> void:
	# Mengubah visibility
	self.visible = !self.visible 
	
	# Memainkan SFX ketika tombol BUKA atau TUTUP ditekan
	if is_instance_valid(menu_sfx_player):
		menu_sfx_player.play() 

# ----------------------------------------------------------------------
# --- FUNGSI PENGONTROL VOLUME (dipanggil oleh HSlider) ---
# ----------------------------------------------------------------------
func _on_volume_slider_value_changed(value: float) -> void:
	if music_bus_index != -1:
		var db_value: float
		if value <= 0.001: 
			db_value = -80.0 
		else:
			db_value = linear_to_db(value)
		
		AudioServer.set_bus_volume_db(music_bus_index, db_value)
		
		# PANGGIL SFX saat slider digeser
		if is_instance_valid(menu_sfx_player):
			menu_sfx_player.play()

# ----------------------------------------------------------------------
# --- FUNGSI PENGONTROL KECERAHAN (dipanggil oleh HScrollBar) ---
# ----------------------------------------------------------------------
func _on_brightness_slider_value_changed(value: float) -> void:
	if is_instance_valid(canvas_modulate):
		canvas_modulate.color = Color(value, value, value)
		
		# PANGGIL SFX saat slider digeser
		if is_instance_valid(menu_sfx_player):
			menu_sfx_player.play()
