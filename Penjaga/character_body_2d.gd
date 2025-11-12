extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var attack_timer = $AttackTimer
@onready var audio_walk = $AudioStreamPlayer2D# Suara jalan
@onready var audio_attack = $"AudioStreamPlayer2D2"# Suara serangan
@onready var audio_run = $"AudioStreamPlayer2D3"# Suara lari
@onready var audio_kenahit = $"AudioStreamPlayer2D4"# ⚡️ BARU: Asumsi node Audio Kena Hit
@onready var audio_mati = $"AudioStreamPlayer2D5"# ⚡️ BARU: Asumsi node Audio Mati

# === STAT ===
var max_health = 100# ⚡️ BARU: Health Maksimal
var health = 100# ⚡️ BARU: Health Saat Ini
var attack_min = 10
var attack_max = 20
var speed = 30
var chase_speed = 30
var attack_cooldown = 3.0

# === INTERNAL STATE ===
var player: Node2D = null
var is_chasing = false
var is_attacking = false
var is_hit = false # ⚡️ BARU: Status Kena Hit
var is_dead = false # ⚡️ BARU: Status Mati
var idle_timer = 0.0
var random_target = Vector2.ZERO
var rng = RandomNumberGenerator.new()

# === KONSTANTA PERILAKU ===
const RANDOM_WALK_RADIUS = 200
const IDLE_DURATION = 2.0
const STOP_DISTANCE = 10.0

func _ready():
	rng.randomize()

	area_deteksi.body_entered.connect(_on_player_detected)
	area_deteksi.body_exited.connect(_on_player_lost)
	area_serang.body_entered.connect(_on_attack_range)
	area_serang.body_exited.connect(_on_attack_out)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)

	_set_random_target()


func _physics_process(delta):
	# ⚡️ BLOKIR PERGERAKAN JIKA MATI ATAU KENDA HIT
	if is_dead or is_hit:
		_stop_all_movement_sounds()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# === Saat menyerang ===
	if is_attacking and player:
		_stop_all_movement_sounds()
		_play_attack_sound()
		velocity = Vector2.ZERO
		var dir = (player.global_position - global_position).normalized()
		anim.play(_get_anim("serang", dir))
		return

	# === Saat mengejar player ===
	if is_chasing and player:
		var dist = global_position.distance_to(player.global_position)
		if dist > STOP_DISTANCE:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * chase_speed
			_play_run_sound()
			anim.play(_get_anim("lari", dir))
		else:
			velocity = Vector2.ZERO
			_stop_all_movement_sounds()
			anim.play(_get_anim("idle", (player.global_position - global_position).normalized()))
	else:
		# === Gerak acak (patroli) ===
		if global_position.distance_to(random_target) < 10:
			idle_timer += delta
			velocity = Vector2.ZERO
			_stop_all_movement_sounds()
			anim.play(_get_anim("idle", Vector2.DOWN))
			if idle_timer >= IDLE_DURATION:
				_set_random_target()
				idle_timer = 0.0
		else:
			var dir = (random_target - global_position).normalized()
			velocity = dir * speed
			_play_walk_sound()
			anim.play(_get_anim("jalan", dir))

	move_and_slide()


# ----------------------------------------------------
# 💥 FUNGSI KENDA DAMAGE
# ----------------------------------------------------
func take_damage(amount: int):
	if health <= 0 or is_hit:
		return
		
	health -= amount
	is_hit = true
	is_attacking = false
	attack_timer.stop()
	velocity = Vector2.ZERO
	
	# Dapatkan arah sentakan (menjauhi player) untuk animasi
	var damage_direction = Vector2.ZERO
	if player:
		damage_direction = (global_position - player.global_position).normalized()
		
	var damage_anim_name = _get_anim("damage", damage_direction) # Asumsi ada animasi "damage"
	anim.play(damage_anim_name)
	
	# Atur flip H sesuai animasi damage kanan/kiri
	if damage_anim_name.ends_with("_kanan_kiri"):
		anim.flip_h = damage_direction.x > 0
	else:
		anim.flip_h = false
	
	# 🎧 Mainkan suara kena hit
	if audio_kenahit:
		audio_kenahit.play()
	
	if health <= 0:
		_die()
	else:
		# Hubungkan sinyal untuk reset state is_hit setelah animasi selesai
		if not anim.animation_finished.is_connected(_on_hit_anim_finished):
			anim.animation_finished.connect(_on_hit_anim_finished)

func _on_hit_anim_finished():
	# ⚡️ Dipanggil setelah animasi "damage" selesai
	if anim.animation_finished.is_connected(_on_hit_anim_finished):
		anim.animation_finished.disconnect(_on_hit_anim_finished)
		
	if anim.animation.begins_with("damage"):
		is_hit = false
		# Kembali ke animasi idle/jalan
		anim.play("idle_bawah")


# ----------------------------------------------------
# ☠️ FUNGSI MATI
# ----------------------------------------------------
func _die():
	is_dead = true
	is_hit = false
	is_attacking = false
	attack_timer.stop()
	velocity = Vector2.ZERO

	# Nonaktifkan area deteksi dan serang
	area_serang.set_deferred("monitoring", false)
	area_deteksi.set_deferred("monitoring", false)
	
	# Dapatkan arah animasi mati
	var die_direction = Vector2.ZERO
	if player:
		die_direction = (global_position - player.global_position).normalized()
		
	var die_anim_name = _get_anim("mati", die_direction) # Asumsi ada animasi "mati"
	anim.play(die_anim_name)
	
	# Atur flip H sesuai animasi mati kanan/kiri
	if die_anim_name.ends_with("_kanan_kiri"):
		anim.flip_h = die_direction.x > 0
	else:
		anim.flip_h = false
	
	# 🎧 Mainkan suara mati
	if audio_mati:
		audio_mati.play()
	
	# Biarkan animasi mati selesai
	await anim.animation_finished
	
	# Setelah mati, hapus dari scene
	queue_free()

# ----------------------------------------------------
# === RANDOM GERAK ===
# ----------------------------------------------------
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
		player = null
		_set_random_target()


# === SERANG ===
func _on_attack_range(body):
	# ⚡️ Cek is_hit sebelum menyerang
	if body.is_in_group("player") and not is_hit:
		is_attacking = true
		player = body
		_do_attack(body)
		attack_timer.start(attack_cooldown)

func _on_attack_out(body):
	if body.is_in_group("player"):
		is_attacking = false
		attack_timer.stop()
		_stop_attack_sound()

func _do_attack(target):
	if not target:
		return
	_play_attack_sound()
	var damage = rng.randi_range(attack_min, attack_max)
	if target.has_method("take_damage"):
		target.take_damage(damage)

func _on_attack_timer_timeout():
	if is_attacking and player and not is_hit: # ⚡️ Cek is_hit sebelum menyerang
		_do_attack(player)
		attack_timer.start(attack_cooldown)

func _on_anim_finished():
	if anim.animation.begins_with("serang"):
		is_attacking = false
		_stop_attack_sound()
		# Kembali ke chasing/idle
		anim.play("idle_bawah")


# === AUDIO SYSTEM ===
func _play_walk_sound():
	if not audio_walk.playing:
		audio_walk.pitch_scale = rng.randf_range(0.9, 1.1)
		audio_walk.play()
		audio_run.stop()

func _play_run_sound():
	if not audio_run.playing:
		audio_run.pitch_scale = rng.randf_range(1.1, 1.25)
		audio_run.play()
		audio_walk.stop()

func _stop_all_movement_sounds():
	if audio_walk.playing:
		audio_walk.stop()
	if audio_run.playing:
		audio_run.stop()

func _play_attack_sound():
	if not audio_attack.playing:
		var base_cooldown = 3.0
		var pitch_by_speed = clamp(base_cooldown / attack_cooldown, 0.7, 1.3)
		audio_attack.pitch_scale = rng.randf_range(pitch_by_speed - 0.05, pitch_by_speed + 0.05)
		audio_attack.play()

func _stop_attack_sound():
	if audio_attack.playing:
		audio_attack.stop()


# === ANIMASI ARAH ===
func _get_anim(base:String, dir:Vector2=Vector2.ZERO) -> String:
	if abs(dir.x) > abs(dir.y):
		# Di fungsi ini, flip hanya diatur untuk animasi non-damage/mati
		if not base.begins_with("damage") and not base.begins_with("mati"):
			anim.flip_h = dir.x < 0
		return base + "_kanan_kiri"
	elif dir.y < 0:
		anim.flip_h = false
		return base + "_atas"
	else:
		anim.flip_h = false
		return base + "_bawah"
