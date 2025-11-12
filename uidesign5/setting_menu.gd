extends MarginContainer # Sesuai dengan Inherits yang Anda pilih

# --- Properti Audio ---
@export var audio_bus_name: String = "Music" 
var music_bus_index: int = -1

# --- Properti Kecerahan (Brightness) ---
# Biasanya dikontrol melalui CanvasModulate, bukan Bus Audio.
# Kita akan asumsikan Anda memiliki node CanvasModulate di root CanvasLayer.
var canvas_modulate: CanvasModulate 

func _ready() -> void:
	# 1. Dapatkan Indeks Bus Audio
	music_bus_index = AudioServer.get_bus_index(audio_bus_name)
	
	# 2. Dapatkan CanvasModulate
	# Asumsi: CanvasModulate ada di root scene Anda atau di CanvasLayer (World/CanvasLayer/CanvasModulate)
	# Anda harus mengganti jalur ini agar sesuai dengan lokasi node CanvasModulate Anda
	canvas_modulate = get_tree().get_root().find_child("CanvasModulate", true, false)
	
	# --- Inisialisasi dan Koneksi Volume (HSlider) ---
	var volume_slider = $NinePatchRect/VBoxContainer/VBoxContainer/volumeBar/VBoxContainer/HSlider
	
	if music_bus_index != -1 and is_instance_valid(volume_slider):
		# Inisialisasi: Konversi dB ke linear
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
		volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	
	# --- Inisialisasi dan Koneksi Kecerahan (HScrollBar) ---
	# Jalur: settingMenu/NinePatchRect/VBoxContainer/brightnessBar/VBoxContainer/HScrollBar
	var brightness_slider = $NinePatchRect/VBoxContainer/brightnessBar/VBoxContainer/HScrollBar
	
	if is_instance_valid(canvas_modulate) and is_instance_valid(brightness_slider):
		# Inisialisasi: Konversi nilai warna ke nilai slider (0.0 hingga 1.0)
		brightness_slider.value = canvas_modulate.color.r 
		brightness_slider.value_changed.connect(_on_brightness_slider_value_changed)
		
		# Atur nilai maksimum HScrollBar agar sesuai dengan skala 0.0 - 1.0
		brightness_slider.max_value = 1.0
		brightness_slider.min_value = 0.0
	else:
		print("PERINGATAN: CanvasModulate atau Brightness Slider tidak ditemukan.")


# FUNGSI PENGONTROL VOLUME (dipanggil oleh HSlider)
func _on_volume_slider_value_changed(value: float) -> void:
	if music_bus_index != -1:
		var db_value: float
		
		if value <= 0.001: # Jika nilai slider sangat dekat dengan 0 (atau tepat 0)
			db_value = -80.0 # Atur ke nilai Bisu Mutlak (-80 dB)
		else:
			# Konversi nilai slider linear (0.0 - 1.0) menjadi desibel (dB)
			db_value = linear_to_db(value)
		
		AudioServer.set_bus_volume_db(music_bus_index, db_value)

# ----------------------------------------------------------------------
# --- FUNGSI PENGONTROL KECERAHAN (dipanggil oleh HScrollBar) ---
# ----------------------------------------------------------------------
func _on_brightness_slider_value_changed(value: float) -> void:
	if is_instance_valid(canvas_modulate):
		# Nilai slider (0.0 hingga 1.0) digunakan untuk mengatur warna CanvasModulate.
		# Catatan: nilai 1.0 adalah kecerahan normal. Nilai < 1.0 membuat gelap.
		canvas_modulate.color = Color(value, value, value)
		
		# Jika Anda ingin kontrol 'gamma' (lebih cerah dari 1.0), 
		# Anda perlu menyesuaikan Max Value HScrollBar, misalnya 1.5,
		# dan menggunakan fungsi power(): canvas_modulate.color = Color(pow(value, 2.0), ...)
