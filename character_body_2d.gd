extends CharacterBody2D

const SPEED_JALAN = 50
const SPEED_LARI = 120
const SPEED_STEALTH = 50
const MAX_HEALTH = 100 # ⚡️ BARU: Health Maksimal

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var interaction = $player_interaction_item

# 🎧 NODE AUDIO BARU
@onready var sfx_jalan_unarmed = $sfx_jalan_unarmed
@onready var sfx_lari_unarmed = $sfx_lari_unarmed
@onready var sfx_sakit_unarmed = $sfx_sakit_unarmed
@onready var sfx_mati_unarmed = $sfx_mati_unarmed

# ⚡️ SINYAL BARU: Dipancarkan saat Player mengambil item yang memicu pergantian Scene
signal request_scene_change(posisi_lama)

var arah = "bawah" # arah terakhir pemain
var is_stealth = false #status mode stealth
var is_dead = false
var is_hit = false
var health = MAX_HEALTH # ⚡️ BARU: Health saat ini


func _physics_process(_delta):
	# 💡 Blokir pergerakan JIKA mati atau kena hit
	if is_dead or is_hit:
		# Hentikan suara langkah
		atur_suara_langkah(false)
		velocity = Vector2.ZERO # Pastikan berhenti
		move_and_slide()
		return
		
	cek_input_stealth()
	player_movement()
	atur_animasi()
	atur_visual()
	atur_suara_langkah(velocity != Vector2.ZERO) # Panggil fungsi suara langkah

# ----------------------------------------------------
# 💥 FUNGSI TAKE DAMAGE BARU
# ----------------------------------------------------
func take_damage(amount: int):
	if is_dead or is_hit:
		return

	health -= amount
	is_hit = true
	velocity = Vector2.ZERO # Hentikan gerakan saat terkena damage (Flinch)

	# 🎧 Mainkan suara sakit
	sfx_sakit_unarmed.play()

	# Pilih animasi kena hit sesuai arah terakhir
	match arah:
		"atas":
			sprite.play("kena_hit_atas")
		"bawah":
			sprite.play("kena_hit_bawah")
		"kanan":
			sprite.flip_h = false
			sprite.play("kena_hit")
		"kiri":
			sprite.flip_h = true
			sprite.play("kena_hit")
			
	# Jika darah habis, mati
	if health <= 0:
		_die(arah) # Panggil _die dengan arah saat ini
	else:
		# ⚡️ PASTIKAN KONEKSI HANYA DIBUAT SEKALI UNTUK MENGHINDARI BUG MULTI-CONNECT
		if sprite.animation_finished.is_connected(_on_hit_finished):
			sprite.animation_finished.disconnect(_on_hit_finished)
		sprite.animation_finished.connect(_on_hit_finished)

# ----------------------------------------------------
# 🔁 FUNGSI SAAT ANIMASI HIT SELESAI
# ----------------------------------------------------
func _on_hit_finished():
	# ⚠️ PUTUSKAN KONEKSI SINYAL DULU
	if sprite.animation_finished.is_connected(_on_hit_finished):
		sprite.animation_finished.disconnect(_on_hit_finished)
		
	# ⚡️ HANYA RESET JIKA ANIMASI YANG BARU SELESAI ADALAH ANIMASI HIT
	if sprite.animation.begins_with("kena_hit"):
		is_hit = false
		print("Kena Hit Selesai, is_hit = false. Player bisa bergerak.")
		atur_animasi() # Kembali ke animasi idle/jalan

# ----------------------------------------------------
# 🎧 FUNGSI PENGONTROL SUARA LANGKAH
# ----------------------------------------------------
func atur_suara_langkah(is_moving: bool):
	# ⚡️ Diperbarui: Tambahkan is_dead dan is_hit untuk menghentikan suara
	if not is_moving or is_stealth or is_dead or is_hit:
		# Hentikan semua suara jika diam, mode stealth, mati, atau kena hit
		if sfx_jalan_unarmed.playing: sfx_jalan_unarmed.stop()
		if sfx_lari_unarmed.playing: sfx_lari_unarmed.stop()
		return
# ... (sisa fungsi ini tidak diubah)
	if velocity.length() > SPEED_JALAN + 10:
		# Mode Lari
		if not sfx_lari_unarmed.playing:
			sfx_lari_unarmed.play()
		if sfx_jalan_unarmed.playing: sfx_jalan_unarmed.stop()
	else:
		# Mode Jalan
		if not sfx_jalan_unarmed.playing:
			sfx_jalan_unarmed.play()
		if sfx_lari_unarmed.playing: sfx_lari_unarmed.stop()

func cek_input_stealth():
	is_stealth = Input.is_action_pressed("stealth_mode")

func player_movement():
	if is_hit or is_dead: # ⚡️ Cegah gerakan saat kena hit atau mati
		return
		
	velocity = Vector2.ZERO
# ... (sisa fungsi ini tidak diubah)
	# --- Logika Invert Sprite Ditambahkan di sini ---
	var input_detected = true
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = 1
		arah = "kanan"
		sprite.flip_h = false # ⬅ Tidak dibalik saat ke kanan
		input_detected = true
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -1
		arah = "kiri"
		sprite.flip_h = true # ⬅ Dibalik (invert) saat ke kiri
		input_detected = true
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -1
		arah = "atas"
		# Tidak membalik saat bergerak vertikal
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 1
		arah = "bawah"
		# Tidak membalik saat bergerak vertikal
	
	# Jika ada input arah horizontal, pastikan flip_h tidak direset
	if velocity.x == 0 and velocity.y != 0 and (arah == "kiri" or arah == "kanan"):
		# Jika berhenti bergerak secara horizontal, sprite tetap menghadap arah terakhir
		pass
	# --- Akhir Logika Invert Sprite ---

	if velocity != Vector2.ZERO:
		velocity = velocity.normalized()
		
		#Tentukan kecepetan berdasar mode
		if is_stealth:
			velocity *= SPEED_STEALTH
		# Jika tombol 'run' ditekan → Lari
		if Input.is_action_pressed("run"):
			velocity *= SPEED_LARI
		else:
			velocity *= SPEED_JALAN

	move_and_slide()

func atur_animasi():
	if is_hit or is_dead: # ⚡️ Animasi ditangani oleh take_damage atau _die
		return
# ... (sisa fungsi ini tidak diubah)
	if velocity == Vector2.ZERO:
		# Diam (Idle)
		match arah:
			"atas":
				sprite.play("idle_atas")
			"bawah":
				sprite.play("idle_bawah")
			# 💡 Ketika idle, sprite akan menggunakan flip_h terakhir dari gerakan
			_:
				sprite.play("idle")
	else:
		# Bergerak
		if is_stealth:
			match arah:
				"atas":
					sprite.play("stealth_atas")
				"bawah":
					sprite.play("stealth_bawah")
				_:
					sprite.play("stealth")
		
		elif velocity.length() > SPEED_JALAN + 10:
			# Lari
			match arah:
				"atas":
					sprite.play("lari_atas")
				"bawah":
					sprite.play("lari_bawah")
				# 💡 Gunakan animasi lari default untuk kiri/kanan, flip_h akan menangani arahnya
				_:
					sprite.play("lari")
		else:
			# Jalan
			match arah:
				"atas":
					sprite.play("jalan_atas")
				"bawah":
					sprite.play("jalan_bawah")
				# 💡 Gunakan animasi jalan default untuk kiri/kanan, flip_h akan menangani arahnya
				_:
					sprite.play("jalan")

#EFEK VISUAL STEALTH
func atur_visual():
	if is_stealth:
		sprite.modulate = Color(1, 1, 1, 0.7) # sedikit transparan
	else:
		sprite.modulate = Color(1,1,1,1)

# ----------------------------------------------------
# ⚠️ FUNGSI ON_DETECTED_BY_PENJAGA DIUBAH
# ----------------------------------------------------
func on_detected_by_penjaga(damage_amount: int) -> void:
	if is_dead or is_hit:
		return
		
	take_damage(damage_amount)
	
# ----------------------------------------------------
# ☠️ FUNGSI MATI (COCOK DENGAN LOGIKA TAKE_DAMAGE)
# ----------------------------------------------------
func _die(direction: String) -> void:
	is_dead = true
	
	# Hentikan semua suara pergerakan
	if sfx_jalan_unarmed.playing: sfx_jalan_unarmed.stop()
	if sfx_lari_unarmed.playing: sfx_lari_unarmed.stop()
	
	# 🎧 Mainkan suara mati
	sfx_mati_unarmed.play()
	
	match direction:
		"atas":
			sprite.play("mati_atas")
		"bawah":
			sprite.play("mati_bawah")
		"kanan":
			sprite.flip_h = false
			sprite.play("mati")
		"kiri":
			sprite.flip_h = true
			sprite.play("mati")

# ⚡️ FUNGSI BARU UNTUK MERESPON PENGAMBILAN ITEM PEDANG
func ambil_pedang() -> void:
	print("Player lama berada di posisi: ", global_position) # <<< Tambahkan ini
	request_scene_change.emit(global_position)
	queue_free()
