extends CharacterBody2D

const SPEED_JALAN = 100
const SPEED_LARI = 200

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

var arah = "bawah"  # arah terakhir pemain

func _ready():
	# Mengaktifkan kamera.
	camera.make_current() 

func _physics_process(_delta):
	player_movement()
	atur_animasi()

func player_movement():
	velocity = Vector2.ZERO
	# --- Logika Invert Sprite Ditambahkan di sini ---
	var input_detected = true
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = 1
		arah = "kanan"
		sprite.flip_h = false # ⬅️ Tidak dibalik saat ke kanan
		input_detected = true
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -1
		arah = "kiri"
		sprite.flip_h = true # ⬅️ Dibalik (invert) saat ke kiri
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
		
		# Jika tombol 'run' ditekan → Lari
		if Input.is_action_pressed("run"):
			velocity *= SPEED_LARI
		else:
			velocity *= SPEED_JALAN

	move_and_slide()

func atur_animasi():
	if velocity == Vector2.ZERO:
		# Diam (Idle)
		match arah:
			"atas":
				sprite.play("idle_atas")
			"bawah":
				sprite.play("idle_bawah")
			# 💡 Ketika idle, sprite akan menggunakan flip_h terakhir dari gerakan
			_:
				sprite.play("idle_sword")
	else:
		# Bergerak
		if velocity.length() > SPEED_JALAN + 10: 
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
