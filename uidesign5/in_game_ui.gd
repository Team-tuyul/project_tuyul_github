extends Control

# Pastikan nama node HSlider ini benar sesuai struktur scene Anda.
# Contoh: $popupMenu/menu/baseMenuScreen/VBoxContainer/volumeBar/VBoxContainer/HSlider
# Ganti path di bawah ini sesuai dengan lokasi HSlider Anda.
@onready var volume_slider = $popupMenu/settingMenu/VBoxContainer/VBoxContainer/volumeBar/HSlider

# Pastikan nama Bus ini SAMA PERSIS dengan yang Anda buat (misalnya "Music")
const MUSIC_BUS_NAME = "Music" 
var music_bus_index: int = -1

func _ready():
	# 1. Dapatkan indeks Bus. Kita lakukan ini hanya sekali di awal.
	music_bus_index = AudioServer.get_bus_index(Music)
	
	if music_bus_index == -1:
		# Peringatan jika Bus tidak ditemukan
		print("Error: Audio Bus '%s' tidak ditemukan! Cek pengaturan Audio." % MUSIC_BUS_NAME)
		return
		
	# 2. Inisialisasi: Atur nilai awal Slider sesuai volume Bus saat ini
	var current_db = AudioServer.get_bus_volume_db(music_bus_index)
	volume_slider.value = db_to_linear(current_db)
	
	# 3. Hubungkan sinyal (Jika Anda tidak menghubungkannya melalui editor Godot)
	# Jika Anda sudah menghubungkannya di editor, baris ini opsional.
	volume_slider.value_changed.connect(_on_slider_value_changed)


# Ini adalah fungsi yang dipanggil ketika nilai HSlider berubah
# Nama fungsi ini harus SAMA PERSIS dengan yang Anda masukkan saat menghubungkan sinyal.
func _on_slider_value_changed(new_value: float):
	if music_bus_index == -1:
		return
		
	# 1. Konversi nilai linear Slider (0.0 - 1.0) ke Desibel (dB)
	var db_value = linear_to_db(new_value)
	
	# 2. Tangani nilai nol (0.0) agar menjadi sangat hening (-80 dB)
	if new_value <= 0.0001:
		db_value = -80.0
	
	# 3. Terapkan nilai dB ke Audio Bus yang sudah ditentukan
	AudioServer.set_bus_volume_db(music_bus_index, db_value)
