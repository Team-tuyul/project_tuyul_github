extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var attack_timer = $AttackTimer

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
	if is_attacking and player:
		velocity = Vector2.ZERO
		var dir = (player.global_position - global_position).normalized()
		anim.play(_get_anim("serang", dir))
		return

	if is_chasing and player:
		var dist = global_position.distance_to(player.global_position)
		if dist > STOP_DISTANCE:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * chase_speed

			var is_running = true
			if is_attacking:
				if is_running:
					anim.play(_get_anim("seranglari", dir))
				else:
					anim.play(_get_anim("serangjalan", dir))
			else:
				if is_running:
					anim.play(_get_anim("lari", dir))
				else:
					anim.play(_get_anim("jalan", dir))
		else:
			velocity = Vector2.ZERO
			anim.play(_get_anim("idle", (player.global_position - global_position).normalized()))
	else:
		# === RANDOM GERAK ===
		if global_position.distance_to(random_target) < 10:
			idle_timer += delta
			velocity = Vector2.ZERO
			anim.play(_get_anim("idle", Vector2.DOWN))
			if idle_timer >= IDLE_DURATION:
				_set_random_target()
				idle_timer = 0.0
		else:
			var dir = (random_target - global_position).normalized()
			velocity = dir * speed
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

func _do_attack(target):
	if not target:
		return
	var damage = rng.randi_range(attack_min, attack_max)
	if target.has_method("take_damage"):
		target.take_damage(damage)

func _on_attack_timer_timeout():
	if is_attacking and player:
		_do_attack(player)
		attack_timer.start(attack_cooldown)


# === ANIMASI ARAH ===
func _get_anim(base:String, dir:Vector2=Vector2.ZERO) -> String:
	# Arah kanan / kiri
	if abs(dir.x) > abs(dir.y):
		anim.flip_h = dir.x < 0
		return base + "_kanan_kiri"

	# Arah atas
	elif dir.y < 0:
		anim.flip_h = false
		return base + "_atas"

	# Arah bawah
	else:
		anim.flip_h = false
		return base + "_bawah"
