extends MarginContainer

# 1. Menu Utama: Container yang berisi opsi (RESUME, SETTINGS, dll.)
# Digunakan untuk menyembunyikan/menampilkan semua opsi menu.
@export var menu_utama: Control # Node Basemenuscreen

# 2. Tombol Pembuka: Node yang diklik untuk membuka menu
# Menggunakan Control untuk fleksibilitas (cocok untuk VBoxContainer atau Button)
@export var tombol_pembuka: Control # Node basemenuopenbutton

@export var pause_game: bool = true

func _ready():
	# Pastikan status awal: Menu Utama tersembunyi, Tombol Pembuka terlihat
	if is_instance_valid(menu_utama):
		menu_utama.visible = false
		
	if is_instance_valid(tombol_pembuka):
		tombol_pembuka.visible = true

# --- Fungsi Aksi: Membuka Menu ---
# Dihubungkan ke sinyal 'pressed' dari tombol_pembuka
func open_menu_action():
	if !is_instance_valid(menu_utama) || !is_instance_valid(tombol_pembuka):
		return

	# Aksi 1: Tampilkan menu utama dan sembunyikan tombol pembuka
	menu_utama.visible = true
	tombol_pembuka.visible = false
	
	# Aksi 2: Pause game
	if pause_game:
		get_tree().paused = true

# --- Fungsi Aksi: Menutup Menu ---
# Dihubungkan ke sinyal 'pressed' dari tombol RESUME
func close_menu_action():
	if !is_instance_valid(menu_utama) || !is_instance_valid(tombol_pembuka):
		return

	# Aksi 1: Sembunyikan menu utama dan tampilkan tombol pembuka
	menu_utama.visible = false
	tombol_pembuka.visible = true
	
	# Aksi 2: Lanjutkan game
	if pause_game:
		get_tree().paused = false
