extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var attack_timer = $AttackTimer
@onready var audio_walk = $AudioStreamPlayer2D           # Suara jalan
@onready var audio_attack = $"AudioStreamPlayer2D2"       # Suara serangan
@onready var audio_run = $"AudioStreamPlayer2D3"          # Suara lari

# === STAT ===
var attack_min = 10
var attack_max = 20
var speed = 30
var chase_speed = 30
var attack_cooldown = 3.0

# === INTERNAL STATE ===
var player: Node2D = null
var is_chasing = false
var is_attacking = false
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

	_set_random_target()


func _physics_process(delta):
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


# === RANDOM GERAK ===
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
	if body.is_in_group("player"):
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
	if is_attacking and player:
		_do_attack(player)
		attack_timer.start(attack_cooldown)


# === AUDIO SYSTEM ===
func _play_walk_sound():
	if not audio_walk.playing:
		audio_walk.pitch_scale = rng.randf_range(0.9, 1.1)
		audio_walk.play()
		audio_run.stop()

func _play_run_sound():
	if not audio_run.playing:
		audio_run.pitch_scale = rng.randf_range(1.1, 1.25)  # Lebih cepat dari jalan
		audio_run.play()
		audio_walk.stop()

func _stop_all_movement_sounds():
	if audio_walk.playing:
		audio_walk.stop()
	if audio_run.playing:
		audio_run.stop()

func _play_attack_sound():
	if not audio_attack.playing:
		# Sesuaikan tempo dengan kecepatan serangan
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
		anim.flip_h = dir.x < 0
		return base + "_kanan_kiri"
	elif dir.y < 0:
		anim.flip_h = false
		return base + "_atas"
	else:
		anim.flip_h = false
		return base + "_bawah"
