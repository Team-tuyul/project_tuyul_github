extends HScrollBar # KOREKSI: Ini adalah HScrollBar yang Anda gunakan

@export var audio_bus_name: String = "Music" 
var music_bus_index: int = -1

func _ready() -> void:
	music_bus_index = AudioServer.get_bus_index(audio_bus_name)
	
	if music_bus_index != -1:
		# Pastikan HScrollBar memiliki pengaturan Range yang benar di Inspector:
		# Min Value: 0.0, Max Value: 1.0, Page: 0.0 (penting agar tampil penuh)
		
		# Inisialisasi: Menggunakan 'self.value'
		self.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
		
		# Koneksi sinyal value_changed (ini yang akan dipanggil saat nilai berubah)
		self.value_changed.connect(_on_volume_slider_value_changed)
	else:
		print("ERROR: Audio Bus '", audio_bus_name, "' tidak ditemukan!")


# Fungsi yang dipanggil setiap kali nilai HScrollBar berubah
func _on_volume_slider_value_changed(value: float) -> void:
	if music_bus_index != -1:
		var db_value: float
		
		# LOGIKA BISU MUTLAK: Jika nilai sangat dekat dengan 0, paksakan ke -80 dB
		if value <= 0.01: 
			db_value = -80.0 # Bisu Mutlak
		else:
			# Jika tidak, gunakan konversi normal
			db_value = linear_to_db(value)
			
		AudioServer.set_bus_volume_db(music_bus_index, db_value)
