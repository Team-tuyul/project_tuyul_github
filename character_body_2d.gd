extends CharacterBody2D

# --- Konstanta Kecepatan ---
const SPEED_JALAN = 100
const SPEED_LARI = 200
const SPEED_STEALTH = 50

# --- Node yang digunakan ---
@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var sfx_jalan = $sfx_jalan_unarmed
@onready var sfx_lari = $sfx_lari_unarmed
@onready var sfx_hurt = $sfx_sakit_unarmed
@onready var sfx_death = $sfx_mati_unarmed

# --- Variabel Status ---
var arah = "bawah"
var is_stealth = false
var is_dead = false
var is_hit = false

func _ready():
	camera.make_current()
	add_to_group("player") # agar item bisa kenali player

func _physics_process(_delta):
	if is_dead or is_hit:
		return
		
	cek_input_stealth()
	player_movement()
	atur_animasi()
	atur_visual()

# ==============================
# --- INPUT & GERAK PLAYER ---
# ==============================
func cek_input_stealth():
	is_stealth = Input.is_action_pressed("stealth_mode")

func player_movement():
	velocity = Vector2.ZERO
	var current_speed = SPEED_JALAN

	# --- Input Gerakan ---
	if Input.is_action_pressed("ui_right"):
		velocity.x = 1
		arah = "kanan"
		sprite.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -1
		arah = "kiri"
		sprite.flip_h = true
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -1
		arah = "atas"
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 1
		arah = "bawah"

	# --- Tentukan kecepatan sesuai mode ---
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized()
		if is_stealth:
			current_speed = SPEED_STEALTH
		elif Input.is_action_pressed("run"):
			current_speed = SPEED_LARI
		else:
			current_speed = SPEED_JALAN

		velocity *= current_speed

	move_and_slide()

	# --- Suara langkah disesuaikan ---
	_play_footstep_sound(velocity, current_speed)

# ==============================
# --- SUARA LANGKAH ---
# ==============================
func _play_footstep_sound(input_vector: Vector2, speed: float):
	if input_vector == Vector2.ZERO:
		if sfx_jalan.playing:
			sfx_jalan.stop()
		if sfx_lari.playing:
			sfx_lari.stop()
		return
	
	if is_stealth:
		if sfx_jalan.playing:
			sfx_jalan.stop()
		if sfx_lari.playing:
			sfx_lari.stop()
		return

	# --- Jalan pelan ---
	if speed <= SPEED_JALAN and not sfx_jalan.playing:
		sfx_lari.stop()
		sfx_jalan.play()

	# --- Lari cepat ---
	elif speed > SPEED_JALAN and not sfx_lari.playing:
		sfx_jalan.stop()
		sfx_lari.play()

# ==============================
# --- SFX KENA HIT ---
# ==============================
func take_hit():
	if not is_dead:
		if sfx_hurt:
			sfx_hurt.play()
		sprite.modulate = Color(1, 0.5, 0.5) # nyala merah
		await get_tree().create_timer(0.3).timeout
		sprite.modulate = Color(1, 1, 1)

# ==============================
# --- FUNGSI MATI ---
# ==============================
func die():
	if not is_dead:
		is_dead = true

		# Stop suara langkah dulu
		if sfx_jalan.playing:
			sfx_jalan.stop()
		if sfx_lari.playing:
			sfx_lari.stop()

		# Mainkan animasi dan suara mati
		sprite.play("death")
		if sfx_death:
			sfx_death.play()

		# Tunggu sampai suara mati selesai
		if sfx_death:
			await sfx_death.finished

		queue_free() # bisa diganti respawn nanti

# ==============================
# --- ANIMASI ---
# ==============================
func atur_animasi():
	if velocity == Vector2.ZERO:
		match arah:
			"atas": sprite.play("idle_atas")
			"bawah": sprite.play("idle_bawah")
			_: sprite.play("idle")
	else:
		if is_stealth:
			match arah:
				"atas": sprite.play("stealth_atas")
				"bawah": sprite.play("stealth_bawah")
				_: sprite.play("stealth")
		elif velocity.length() > SPEED_JALAN + 10:
			match arah:
				"atas": sprite.play("lari_atas")
				"bawah": sprite.play("lari_bawah")
				_: sprite.play("lari")
		else:
			match arah:
				"atas": sprite.play("jalan_atas")
				"bawah": sprite.play("jalan_bawah")
				_: sprite.play("jalan")

# ==============================
# --- VISUAL (Stealth efek) ---
# ==============================
func atur_visual():
	if is_stealth:
		sprite.modulate = Color(1, 1, 1, 0.7)
	else:
		sprite.modulate = Color(1, 1, 1, 1)

# ==============================
# --- KETIKA TERDETEKSI PENJAGA ---
# ==============================
func on_detected_by_penjaga(direction: String) -> void:
	if is_dead:
		return
	is_hit = true
	
	match direction:
		"atas": sprite.play("kena_hit_atas")
		"bawah": sprite.play("kena_hit_bawah")
		"kanan":
			sprite.flip_h = false
			sprite.play("kena_hit")
		"kiri":
			sprite.flip_h = true
			sprite.play("kena_hit")

	await sprite.animation_finished
	is_hit = false
	_die(direction)

# ==============================
# --- MATI (versi arah) ---
# ==============================
func _die(direction: String) -> void:
	is_dead = true
	match direction:
		"atas": sprite.play("mati_atas")
		"bawah": sprite.play("mati_bawah")
		"kanan":
			sprite.flip_h = false
			sprite.play("mati")
		"kiri":
			sprite.flip_h = true
			sprite.play("mati")
 
