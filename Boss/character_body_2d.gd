extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var attack_timer = $AttackTimer

# 🔊 Audio
@onready var step_sound = $AudioStreamPlayer2D      # jalan
@onready var attack_sound = $AudioStreamPlayer2D2   # serang
@onready var run_sound = $AudioStreamPlayer2D3      # lari
@onready var damage_sound = $AudioStreamPlayer2D4   # damage
@onready var death_sound = $AudioStreamPlayer2D5    # mati

# === STAT ===
var max_health = 1000
var health = 1000
var attack_min = 10
var attack_max = 20
var speed = 30
var chase_speed = 30
var attack_cooldown = 8.0

# === INTERNAL STATE ===
var player: Node2D = null
var is_chasing = false
var is_attacking = false
var idle_timer = 0.0
var random_target = Vector2.ZERO
var rng = RandomNumberGenerator.new()

# === KONSTANTA PERILAKU ===
const RANDOM_WALK_RADIUS = 250
const IDLE_DURATION = 2.5
const STOP_DISTANCE = 5.0


func _ready():
	rng.randomize()
	
	area_deteksi.body_entered.connect(_on_player_detected)
	area_deteksi.body_exited.connect(_on_player_lost)
	area_serang.body_entered.connect(_on_attack_range)
	area_serang.body_exited.connect(_on_attack_out)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	_set_random_target()


func _physics_process(delta):
	if is_attacking and player:
		velocity = Vector2.ZERO
		var dir = (player.global_position - global_position).normalized()
		anim.play(_get_anim("serang", dir))
		_stop_all_sounds_except("attack")
		_play_attack_sound()
		return

	if is_chasing and player:
		var dist = global_position.distance_to(player.global_position)
		var dir = (player.global_position - global_position).normalized()

		if dist > STOP_DISTANCE:
			velocity = dir * chase_speed
			anim.play(_get_anim("lari", dir))
			_stop_all_sounds_except("run")
			_play_run_sound()
		else:
			velocity = Vector2.ZERO
			anim.play(_get_anim("idle", dir))
			_stop_all_sounds()
	else:
		if global_position.distance_to(random_target) < 10:
			idle_timer += delta
			velocity = Vector2.ZERO
			anim.play(_get_anim("idle"))
			_stop_all_sounds()
			if idle_timer >= IDLE_DURATION:
				_set_random_target()
				idle_timer = 0.0
		else:
			var dir = (random_target - global_position).normalized()
			velocity = dir * speed
			anim.play(_get_anim("jalan", dir))
			_stop_all_sounds_except("step")
			_play_step_sound()

	move_and_slide()

	if velocity.length() < 0.1:
		_stop_all_sounds()


# === AUDIO UTAMA ===
func _stop_all_sounds():
	_stop_step_sound()
	_stop_run_sound()
	_stop_attack_sound()
	_stop_damage_sound()
	_stop_death_sound()

func _stop_all_sounds_except(type: String):
	match type:
		"step":
			_stop_run_sound()
			_stop_attack_sound()
			_stop_damage_sound()
			_stop_death_sound()
		"run":
			_stop_step_sound()
			_stop_attack_sound()
			_stop_damage_sound()
			_stop_death_sound()
		"attack":
			_stop_step_sound()
			_stop_run_sound()
			_stop_damage_sound()
			_stop_death_sound()
		"damage":
			_stop_step_sound()
			_stop_run_sound()
			_stop_attack_sound()
			_stop_death_sound()
		"death":
			_stop_step_sound()
			_stop_run_sound()
			_stop_attack_sound()
			_stop_damage_sound()


# === AUDIO: JALAN ===
func _play_step_sound():
	step_sound.pitch_scale = 1.0
	if not step_sound.playing:
		step_sound.seek(0.0)
		step_sound.play()

func _stop_step_sound():
	if step_sound.playing:
		step_sound.stop()
		step_sound.seek(0.0)


# === AUDIO: LARI ===
func _play_run_sound():
	run_sound.pitch_scale = 1.0
	if not run_sound.playing:
		run_sound.seek(0.0)
		run_sound.play()

func _stop_run_sound():
	if run_sound.playing:
		run_sound.stop()
		run_sound.seek(0.0)


# === AUDIO: SERANG ===
func _play_attack_sound():
	attack_sound.pitch_scale = 0.6
	if not attack_sound.playing:
		attack_sound.seek(0.0)
		attack_sound.play()

func _stop_attack_sound():
	if attack_sound.playing:
		attack_sound.stop()
		attack_sound.seek(0.0)


# === AUDIO: DAMAGE ===
func _play_damage_sound():
	damage_sound.pitch_scale = 0.75
	if not damage_sound.playing:
		damage_sound.seek(0.0)
		damage_sound.play()

func _stop_damage_sound():
	if damage_sound.playing:
		damage_sound.stop()
		damage_sound.seek(0.0)


# === AUDIO: MATI ===
func _play_death_sound():
	death_sound.pitch_scale = 0.9  # agak lambat biar kesan berat dan realistis
	if not death_sound.playing:
		death_sound.seek(0.0)
		death_sound.play()

func _stop_death_sound():
	if death_sound.playing:
		death_sound.stop()
		death_sound.seek(0.0)


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
		_stop_all_sounds()
		_set_random_target()


# === SERANG ===
func _on_attack_range(body):
	if body.is_in_group("player"):
		is_attacking = true
		player = body
		_stop_all_sounds_except("attack")
		_play_attack_sound()
		_do_attack(body)
		attack_timer.start(attack_cooldown)


func _on_attack_out(body):
	if body.is_in_group("player"):
		is_attacking = false
		attack_timer.stop()
		_stop_attack_sound()


func _do_attack(target):
	if not target: return
	var damage = rng.randi_range(attack_min, attack_max)
	if target.has_method("take_damage"):
		target.take_damage(damage)


func _on_attack_timer_timeout():
	if is_attacking and player:
		_do_attack(player)
		attack_timer.start(attack_cooldown)


# === ANIMASI ===
func _get_anim(base:String, dir:Vector2=Vector2.ZERO) -> String:
	if dir == Vector2.ZERO:
		anim.flip_h = false
		return base + "_bawah"

	if abs(dir.x) > abs(dir.y):
		anim.flip_h = dir.x < 0
		return base + "_kanan_kiri"
	elif dir.y < 0:
		anim.flip_h = false
		return base + "_atas"
	else:
		anim.flip_h = false
		return base + "_bawah"


# === DAMAGE / MATI ===
func take_damage(amount:int):
	health -= amount
	anim.play(_get_anim("damage"))
	_stop_all_sounds_except("damage")
	_play_damage_sound()
	await anim.animation_finished
	_stop_damage_sound()

	if health <= 0:
		_die()


func _die():
	is_chasing = false
	is_attacking = false
	velocity = Vector2.ZERO
	anim.play(_get_anim("mati"))
	_stop_all_sounds_except("death")
	_play_death_sound()
	await anim.animation_finished
	_stop_death_sound()
	queue_free()
