extends CharacterBody2D

# === NODE BARU: Pastikan ada Timer di scene bernama 'AttackTimer' ===
@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var hitbox = $Hitbox
@onready var attack_timer = $AttackTimer # ⚠️ Asumsi node Timer sudah ada di Scene

# === STAT ===
var max_health = 2000
var health = 2000
var attack_min = 10
var attack_max = 20
var speed = 60
var chase_speed = 70
var attack_cooldown = 8.0 # Waktu jeda antar serangan

# === INTERNAL STATE ===
var player = null
var is_chasing = false
var is_attacking = false
var idle_timer = 0.0
var random_target = Vector2.ZERO
var last_player_pos = Vector2.ZERO
var rng = RandomNumberGenerator.new()

# === KONSTANTA PERILAKU ===
const RANDOM_WALK_RADIUS = 250
const IDLE_DURATION = 3.0

func _ready():
	rng.randomize()
	area_deteksi.body_entered.connect(_on_player_detected)
	area_deteksi.body_exited.connect(_on_player_lost)
	area_serang.body_entered.connect(_on_attack_range)
	area_serang.body_exited.connect(_on_attack_out)
	
	# Hubungkan timer untuk serangan
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	_set_random_target()


func _physics_process(delta):
	# ⚠️ Hanya atur animasi Serang/Idle di sini jika tidak ada gerakan
	if is_attacking and player: # Pastikan player masih ada
		velocity = Vector2.ZERO
		# 🔥 MODIFIKASI: Hitung arah saat menyerang
		var attack_dir = (player.global_position - global_position).normalized()
		anim.play(_get_anim("serang", attack_dir)) # Kirim arah ke fungsi
		move_and_slide()
		return
	elif is_attacking and not player:
		# Jika is_attacking TRUE tapi Player tiba-tiba hilang (null)
		is_attacking = false
		attack_timer.stop()

	if is_chasing and player:
		# Lari mengejar
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * chase_speed
		anim.play(_get_anim("lari", dir))
	else:
		# Gerakan Acak (Random Walk)
		if global_position.distance_to(random_target) < 10:
			# Berhenti/Idle
			idle_timer += delta
			anim.play(_get_anim("idle"))
			velocity = Vector2.ZERO # Pastikan berhenti saat idle
			
			if idle_timer >= IDLE_DURATION:
				_set_random_target()
				idle_timer = 0
		else:
			# Jalan menuju target acak
			var dir = (random_target - global_position).normalized()
			velocity = dir * speed
			anim.play(_get_anim("jalan", dir))

	move_and_slide()


# === FUNGSI UNTUK RANDOM GERAK ===
func _set_random_target():
	var rand_offset = Vector2(
		rng.randf_range(-RANDOM_WALK_RADIUS, RANDOM_WALK_RADIUS),
		rng.randf_range(-RANDOM_WALK_RADIUS, RANDOM_WALK_RADIUS)
	)
	random_target = global_position + rand_offset


# === DETEKSI PLAYER ===
func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		is_chasing = true
		is_attacking = false

func _on_player_lost(body):
	if body.is_in_group("player"):
		is_chasing = false
		is_attacking = false
		player = null # Set player ke null
		last_player_pos = body.global_position
		random_target = last_player_pos # Boss akan menuju posisi terakhir player
		idle_timer = 0.0


# === SERANG ===
func _on_attack_range(body):
	if body.is_in_group("player"):
		is_attacking = true
		player = body # Pastikan player node diset di sini juga
		_do_attack(body)
		attack_timer.start(attack_cooldown) # Mulai timer serangan berulang

func _on_attack_out(body):
	if body.is_in_group("player"):
		is_attacking = false
		attack_timer.stop() # Hentikan timer serangan

func _do_attack(target):
	if not target: return
	var damage = rng.randi_range(attack_min, attack_max)
	if target.has_method("take_damage"):
		target.take_damage(damage)

func _on_attack_timer_timeout():
	# Serang lagi jika masih berada dalam mode menyerang dan player masih terdeteksi
	if is_attacking and player:
		_do_attack(player)
		attack_timer.start(attack_cooldown) # Atur timer lagi

# === ANIMASI DIRECTION (FIXED) ===
func _get_anim(base:String, dir:Vector2=Vector2.ZERO) -> String:
	# ... (kode untuk "damage" dan "mati" tetap sama)

	# Jika tidak bergerak (Idle)
	if dir == Vector2.ZERO:
		# Asumsikan idle/serang bawah sebagai default saat diam
		anim.flip_h = false 
		return base + "_bawah"

	# Logika Arah
	if abs(dir.x) > abs(dir.y):
		# Horizontal (serang_kanan_kiri)
		anim.flip_h = dir.x < 0 # Dibalik jika bergerak ke kiri
		return base + "_kanan_kiri"
	elif dir.y < 0:
		# Atas (serang_atas)
		anim.flip_h = false 
		return base + "_atas"
	else:
		# Bawah (serang_bawah)
		anim.flip_h = false 
		return base + "_bawah"


# === TERIMA DAMAGE ===
func take_damage(amount:int):
	health -= amount
	anim.play(_get_anim("damage"))
	# Tambahkan timer atau cek untuk memastikan animasi damage selesai 
	# sebelum kembali ke animasi lain, jika diperlukan.
	if health <= 0:
		_die()

func _die():
	is_chasing = false
	is_attacking = false
	velocity = Vector2.ZERO
	anim.play(_get_anim("mati"))
	
	# Hapus setelah animasi mati selesai
	await anim.animation_finished
	queue_free()
