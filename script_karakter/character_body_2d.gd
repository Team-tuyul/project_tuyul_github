extends CharacterBody2D

const SPEED_JALAN = 100
const SPEED_LARI = 200

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

var arah = "bawah"
var is_attacking = false 
var has_sword = false

func _ready():
	camera.make_current() 

func _physics_process(_delta):
	player_movement() 
	
	if is_attacking:
		# 💡 Panggil fungsi baru untuk memperbarui animasi serangan jika arah berubah
		update_attack_animation()
	else:
		atur_animasi()
	
	move_and_slide()

func player_movement():
	# Cek input serangan (diprioritaskan)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()
	
	velocity = Vector2.ZERO
	
	# 1. Hitung Arah dan Atur arah/flip_h
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

	# 2. Tentukan Kecepatan (Jalan atau Lari)
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized()
		
		if Input.is_action_pressed("run"):
			velocity *= SPEED_LARI
		else:
			velocity *= SPEED_JALAN

# ⚔️ FUNGSI UNTUK MEMULAI SERANGAN (Hanya set status, panggil update)
func start_attack():
	# Putuskan sinyal lama sebelum memulai (kebersihan kode)
	if sprite.animation_finished.is_connected(_on_attack_finished):
		sprite.animation_finished.disconnect(_on_attack_finished)
	
	# Set Status dan panggil update pertama
	is_attacking = true
	update_attack_animation()

# 🔁 FUNGSI BARU: Memperbarui animasi serangan (dipanggil di setiap frame saat menyerang)
func update_attack_animation():
	var new_animation_name = ""

	# Tentukan nama animasi yang SEHARUSNYA diputar
	if Input.is_action_pressed("run"):
		# LARI + SERANG
		match arah:
			"atas": new_animation_name = "run_attack_atas"
			"bawah": new_animation_name = "run_attack_bawah"
			_: new_animation_name = "run_attack"
	else:
		# IDLE/JALAN + SERANG
		match arah:
			"atas": new_animation_name = "sword_animation_up"
			"bawah": new_animation_name = "sword_attack_down"
			_: new_animation_name = "sword_attack_samping"
			
	# 🛑 PENTING: Putar animasi HANYA JIKA NAMA ANIMASI BERBEDA
	if sprite.get_animation() != new_animation_name:
		# Putuskan koneksi sinyal LAMA sebelum memutar animasi baru
		if sprite.animation_finished.is_connected(_on_attack_finished):
			sprite.animation_finished.disconnect(_on_attack_finished)
			
		# Putar animasi baru dari frame 0
		sprite.play(new_animation_name)
		
		# Sambungkan sinyal animation_finished baru
		sprite.animation_finished.connect(_on_attack_finished)
		
# 🗡️ FUNGSI DIPANGGIL HANYA SETELAH ANIMASI SERANGAN SELESAI
func _on_attack_finished():
	if is_attacking: 
		is_attacking = false
		
		if sprite.animation_finished.is_connected(_on_attack_finished):
			sprite.animation_finished.disconnect(_on_attack_finished)
			
		atur_animasi() 

## 🎨 Fungsi atur_animasi() untuk Gerakan Normal
func atur_animasi():
	if is_attacking:
		return 
		
	if velocity == Vector2.ZERO:
		# --- Diam (Idle) ---
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
		# --- Bergerak ---
		if velocity.length() > SPEED_JALAN + 10: 
			# Lari
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
			# Jalan
			match arah:
				"atas":
					sprite.play("jalan_atas")
				"bawah":
					sprite.play("jalan_bawah")
				"kiri", "kanan":
					sprite.play("jalan")
				_:
					sprite.play("jalan")
