extends CharacterBody2D

const SPEED_JALAN = 50
const SPEED_LARI = 120
const MAX_HEALTH = 120

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var walk_sound = $FootSteep_player
@onready var run_sound = $RunSteep_player
@onready var attack_sound = $AttackSound_player
@onready var hit_sound = $HitSound_player
@onready var death_sound = $DeathSound_player
@onready var attack_hitbox = $AttackHitbox # 💥 Pastikan ada node Area2D bernama AttackHitbox!

var arah = "bawah"
var is_attacking = false
var has_sword = true # ⚡️ PERBAIKAN: Karakter ini sudah bersenjata
var step_timer = 0.0
var health = MAX_HEALTH
var is_dead = false
var is_hit = false
var rng = RandomNumberGenerator.new() # Diperlukan untuk damage acak

func _ready():
	# ⚡️ PERBAIKAN: make_current() DIHAPUS.
	# Kamera diaktifkan oleh World Script setelah player di-instantiate pada posisi yang benar.
	# if camera:
	# 	camera.make_current() 
	rng.randomize()
	
	# Hubungkan sinyal AttackHitbox saat body lain masuk
	if attack_hitbox:
		# Asumsi: Musuh (Boss) adalah CharacterBody2D, jadi gunakan body_entered
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
		attack_hitbox.monitoring = false # Nonaktifkan deteksi awal

func _physics_process(_delta):
	if is_dead:
		return

	# 💥 Untuk uji coba kena damage (hapus nanti setelah tes)
	if Input.is_action_just_pressed("ui_accept"):
		take_damage(30)

	player_movement()

	if is_attacking:
		update_attack_animation()
	elif is_hit:
		return
	else:
		atur_animasi()

	atur_suara_langkah()
	move_and_slide()

# ----------------------------------------------------
# 💥 FUNGSI KENA DAMAGE
# ----------------------------------------------------
func take_damage(amount):
	if is_dead or is_hit:
		return

	health -= amount
	is_hit = true

	# mainkan suara kena hit
	hit_sound.play()

	# pilih animasi kena hit sesuai arah
	match arah:
		"atas":
			sprite.play("kena_hit_atas")
		"bawah":
			sprite.play("kena_hit_bawah")
		_:
			sprite.play("kena_hit")

	# jika darah habis, mati
	if health <= 0:
		die()
	else:
		# setelah animasi hit selesai, lanjut lagi
		if not sprite.animation_finished.is_connected(_on_hit_finished):
			sprite.animation_finished.connect(_on_hit_finished)

# ----------------------------------------------------
# ☠️ FUNGSI MATI
# ----------------------------------------------------
func die():
	is_dead = true
	is_hit = false
	velocity = Vector2.ZERO

	death_sound.play()

	# mainkan animasi mati sesuai arah
	match arah:
		"atas":
			sprite.play("mati_atas")
		"bawah":
			sprite.play("mati_bawah")
		_:
			sprite.play("mati")

# ----------------------------------------------------
# 🔁 FUNGSI SAAT ANIMASI HIT SELESAI
# ----------------------------------------------------
func _on_hit_finished():
	if sprite.animation_finished.is_connected(_on_hit_finished):
		sprite.animation_finished.disconnect(_on_hit_finished)
	is_hit = false

# ----------------------------------------------------
# 🦶 SUARA LANGKAH
# ----------------------------------------------------
func atur_suara_langkah():
	if velocity == Vector2.ZERO or is_attacking or is_hit or is_dead:
		if walk_sound.playing:
			walk_sound.stop()
		if run_sound.playing:
			run_sound.stop()
	else:
		if velocity.length() > SPEED_JALAN + 10:
			if not run_sound.playing:
				run_sound.play()
			if walk_sound.playing:
				walk_sound.stop()
		else:
			if not walk_sound.playing:
				walk_sound.play()
			if run_sound.playing:
				run_sound.stop()

# ----------------------------------------------------
# 🎮 GERAKAN
# ----------------------------------------------------
func player_movement():
	if is_attacking or is_hit or is_dead:
		return

	if Input.is_action_just_pressed("attack"):
		start_attack()

	velocity = Vector2.ZERO

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

	if velocity != Vector2.ZERO:
		velocity = velocity.normalized()
		if Input.is_action_pressed("run"):
			velocity *= SPEED_LARI
		else:
			velocity *= SPEED_JALAN

# ----------------------------------------------------
# ⚔️ SERANGAN
# ----------------------------------------------------
func start_attack():
	if sprite.animation_finished.is_connected(_on_attack_finished):
		sprite.animation_finished.disconnect(_on_attack_finished)
		
	is_attacking = true
	
	# ⚡ AKTIFKAN HITBOX saat serangan dimulai
	if attack_hitbox:
		attack_hitbox.monitoring = true
		
	update_attack_animation()
	attack_sound.play()

func update_attack_animation():
	var new_animation_name = ""
	if Input.is_action_pressed("run"):
		match arah:
			"atas": new_animation_name = "run_attack_atas"
			"bawah": new_animation_name = "run_attack_bawah"
			_: new_animation_name = "run_attack"
	else:
		match arah:
			"atas": new_animation_name = "sword_animation_up"
			"bawah": new_animation_name = "sword_attack_down"
			_: new_animation_name = "sword_attack_samping"
			
	if sprite.get_animation() != new_animation_name:
		if sprite.animation_finished.is_connected(_on_attack_finished):
			sprite.animation_finished.disconnect(_on_attack_finished)
		sprite.play(new_animation_name)
		sprite.animation_finished.connect(_on_attack_finished)

func _on_attack_finished():
	if is_attacking:
		is_attacking = false
		
		# ⚡ Ubah: Pastikan monitoring dimatikan HANYA JIKA masih aktif.
		if attack_hitbox and attack_hitbox.monitoring:
			attack_hitbox.monitoring = false
			
		if sprite.animation_finished.is_connected(_on_attack_finished):
			sprite.animation_finished.disconnect(_on_attack_finished)
		atur_animasi()
		
# ----------------------------------------------------
# 💥 MEBERIKAN DAMAGE KE MUSUH (Fungsi Baru)
# ----------------------------------------------------
func deal_damage_to_boss(target_body):
	# Pastikan target memiliki fungsi take_damage
	if target_body is CharacterBody2D and target_body.has_method("take_damage"):
		# 1. Hitung damage acak antara 8 sampai 27
		var damage = rng.randi_range(8, 27)
		
		# 2. Panggil fungsi take_damage pada objek target (Boss)
		target_body.take_damage(damage)
		
		print("Player menyerang musuh! Damage: ", damage)
		
		# Opsional: Menonaktifkan hitbox setelah damage diberikan
		if attack_hitbox:
			attack_hitbox.monitoring = false
			
# Di skrip Player:
func _on_attack_hitbox_body_entered(body):
	# Cek 1: Apakah tabrakan terdeteksi sama sekali?
	print("Tabrakan terdeteksi: ", body.name, " Group: ", body.is_in_group("enemy"))

	if body.is_in_group("enemy") and is_attacking:
		# Cek 2: Apakah damage diberikan?
		deal_damage_to_boss(body)
		print("Damage diberikan ke Boss!")
		
		if attack_hitbox:
			attack_hitbox.monitoring = false
	else:
		# Cek 3: Kenapa gagal?
		if not is_attacking:
			print("Gagal: Player tidak sedang menyerang.")
		elif not body.is_in_group("enemy"):
			print("Gagal: Body yang ditabrak bukan di Group 'enemy'.")

# ----------------------------------------------------
# 🎨 ANIMASI NORMAL
# ----------------------------------------------------
func atur_animasi():
	if is_attacking or is_hit or is_dead:
		return
		
	if velocity == Vector2.ZERO:
		match arah:
			"atas": sprite.play("idle_atas")
			"bawah": sprite.play("idle_bawah")
			"kiri", "kanan": sprite.play("idle_sword")
			_: sprite.play("idle_sword")
	else:
		if velocity.length() > SPEED_JALAN + 10:
			match arah:
				"atas": sprite.play("lari_atas")
				"bawah": sprite.play("lari_bawah")
				"kiri", "kanan": sprite.play("lari")
				_: sprite.play("lari")
		else:
			match arah:
				"atas": sprite.play("jalan_atas")
				"bawah": sprite.play("jalan_bawah")
				"kiri", "kanan": sprite.play("jalan")
				_: sprite.play("jalan")
