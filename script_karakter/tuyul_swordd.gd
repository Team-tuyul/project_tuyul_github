extends CharacterBody2D

const SPEED_JALAN = 100
const SPEED_LARI = 200

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var walk_sound = $FootSteep_player
@onready var run_sound = $RunSteep_player
@onready var attack_sound = $AttackSound_player  

var arah = "bawah"
var is_attacking = false 
var has_sword = false
var step_timer = 0.0

func _ready():
	camera.make_current() 

func _physics_process(_delta):
	player_movement() 
	
	if is_attacking:
		update_attack_animation()
	else:
		atur_animasi()
	
	atur_suara_langkah()
	move_and_slide()

# ------------------------------
# 🦶 SUARA LANGKAH
# ------------------------------
func atur_suara_langkah():
	if velocity == Vector2.ZERO:
		# Kalau diam → hentikan semua suara
		if walk_sound.playing:
			walk_sound.stop()
		if run_sound.playing:
			run_sound.stop()
	else:
		# Kalau bergerak → pilih suara jalan atau lari
		if velocity.length() > SPEED_JALAN + 10:
			# Lari
			if not run_sound.playing:
				run_sound.play()
			if walk_sound.playing:
				walk_sound.stop()
		else:
			# Jalan
			if not walk_sound.playing:
				walk_sound.play()
			if run_sound.playing:
				run_sound.stop()

# ------------------------------
# 🎮 GERAKAN & ANIMASI
# ------------------------------
func player_movement():
	if Input.is_action_just_pressed("attack") and not is_attacking:
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

# ------------------------------
# ⚔️ SISTEM SERANGAN
# ------------------------------
func start_attack():
	# Putuskan sinyal lama sebelum memulai (kebersihan kode)
	if sprite.animation_finished.is_connected(_on_attack_finished):
		sprite.animation_finished.disconnect(_on_attack_finished)

	# 🔊 Putar suara serangan di awal serangan
	if not attack_sound.playing:
		attack_sound.pitch_scale = randf_range(0.95, 1.05) # variasi alami
		attack_sound.play()

	# Set Status dan panggil update pertama
	is_attacking = true
	update_attack_animation()

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
		if sprite.animation_finished.is_connected(_on_attack_finished):
			sprite.animation_finished.disconnect(_on_attack_finished)
		atur_animasi() 

# ------------------------------
# 🎨 ANIMASI NORMAL
# ------------------------------
func atur_animasi():
	if is_attacking:
		return 
		
	if velocity == Vector2.ZERO:
		match arah:
			"atas":
				sprite.play("idle_atas")
			"bawah":
				sprite.play("idle_bawah")
			"kiri", "kanan":
				sprite.play("idle_sword")
			_:
				sprite.play("idle_sword")
	else:
		if velocity.length() > SPEED_JALAN + 10: 
			match arah:
				"atas":
					sprite.play("lari_atas")
				"bawah":
					sprite.play("lari_bawah")
				"kiri", "kanan": 
					sprite.play("lari")
				_:
					sprite.play("lari")
		else:
			match arah:
				"atas":
					sprite.play("jalan_atas")
				"bawah":
					sprite.play("jalan_bawah")
				"kiri", "kanan":
					sprite.play("jalan")
				_:
					sprite.play("jalan")
