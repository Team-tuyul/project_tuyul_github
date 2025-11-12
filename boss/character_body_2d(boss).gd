extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var attack_timer = $AttackTimer

# === AUDIO ===
@onready var audio_step = $AudioStep
@onready var audio_attack = $AudioAttack
@onready var audio_lari = $AudioLari
@onready var audio_kenahit = $AudioKenaHit
@onready var audio_mati = $AudioMati

# === STAT ===
var max_health = 1000
var health = 1000
var attack_min = 10
var attack_max = 20
var speed = 60
var chase_speed = 60
var attack_cooldown = 1.0

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

# === SUARA ===
var langkah_sounds = [
	preload("res://Theme Song/step boss.mp3")
]
var serang_sounds = [
	preload("res://Theme Song/sword slice boss.mp3")
]
var lari_sounds = [
	preload("res://Theme Song/lari boss.mp3")
]
var hit_sounds = [
	preload("res://Theme Song/suara kena hit boss.mp3")
]
var mati_sounds = [
	preload("res://Theme Song/growl boss.mp3")
]

# === TIMER UNTUK SUARA ===
var last_step_time := 0.0
var step_interval := 0.35
var last_attack_time := 0.0
var attack_interval := 0.5
var last_lari_time := 0.0
var lari_interval := 0.28


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
	last_step_time += delta
	last_attack_time += delta
	last_lari_time += delta

	if is_attacking and player:
		_stop_step_sound_if_playing()
		_stop_lari_sound_if_playing()

		velocity = Vector2.ZERO
		var dir = (player.global_position - global_position).normalized()
		anim.play(_get_anim("serang", dir))
		_update_attack_sound()
		return

	if is_chasing and player:
		var dist = global_position.distance_to(player.global_position)

		if dist > STOP_DISTANCE:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * chase_speed
			anim.play(_get_anim("lari", dir))
			if not is_attacking:
				_update_lari_sound()
			_stop_step_sound_if_playing()
		else:
			velocity = Vector2.ZERO
			anim.play(_get_anim("idle"))
			_stop_lari_sound_if_playing()
	else:
		if global_position.distance_to(random_target) < 10:
			idle_timer += delta
			velocity = Vector2.ZERO
			anim.play(_get_anim("idle"))
			_stop_step_sound_if_playing()
			_stop_lari_sound_if_playing()
			if idle_timer >= IDLE_DURATION:
				_set_random_target()
				idle_timer = 0.0
		else:
			var dir = (random_target - global_position).normalized()
			velocity = dir * speed
			anim.play(_get_anim("jalan", dir))
			if not is_attacking:
				_update_step_sound()
			_stop_lari_sound_if_playing()

	move_and_slide()


func _set_random_target():
	var rand_offset = Vector2(
		rng.randf_range(-RANDOM_WALK_RADIUS, RANDOM_WALK_RADIUS),
		rng.randf_range(-RANDOM_WALK_RADIUS, RANDOM_WALK_RADIUS)
	)
	random_target = global_position + rand_offset


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
		_stop_attack_sound_if_playing()


func _do_attack(target):
	if not target: return
	_update_attack_sound(true)
	var damage = rng.randi_range(attack_min, attack_max)
	if target.has_method("take_damage"):
		target.take_damage(damage)


func _on_attack_timer_timeout():
	if is_attacking and player:
		_do_attack(player)
		attack_timer.start(attack_cooldown)


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


func take_damage(amount:int):
	health -= amount
	anim.play(_get_anim("damage"))
	_play_hit_sound()
	if health <= 0:
		_die()


func _die():
	is_chasing = false
	is_attacking = false
	velocity = Vector2.ZERO
	anim.play(_get_anim("mati"))
	_play_die_sound()
	await anim.animation_finished
	queue_free()


# === AUDIO HELPERS ===
func _update_step_sound():
	if is_attacking or (anim and anim.animation.begins_with("serang")):
		_stop_step_sound_if_playing()
		return

	if anim and anim.animation.begins_with("jalan") and last_step_time >= step_interval and not audio_step.playing:
		audio_step.stream = langkah_sounds[rng.randi_range(0, langkah_sounds.size() - 1)]
		audio_step.pitch_scale = rng.randf_range(0.9, 1.1)
		audio_step.play()
		last_step_time = 0.0

func _stop_step_sound_if_playing():
	if audio_step.playing:
		audio_step.stop()

func _update_lari_sound():
	if is_attacking or (anim and anim.animation.begins_with("serang")):
		_stop_lari_sound_if_playing()
		return

	if anim and anim.animation.begins_with("lari") and last_lari_time >= lari_interval and not audio_lari.playing:
		audio_lari.stream = lari_sounds[rng.randi_range(0, lari_sounds.size() - 1)]
		audio_lari.pitch_scale = rng.randf_range(0.95, 1.05)
		audio_lari.play()
		last_lari_time = 0.0

func _stop_lari_sound_if_playing():
	if audio_lari.playing:
		audio_lari.stop()

func _update_attack_sound(force: bool=false):
	if not anim: return
	if not is_attacking or not anim.animation.begins_with("serang"):
		_stop_attack_sound_if_playing()
		return
	if (force or last_attack_time >= attack_interval) and not audio_attack.playing:
		audio_attack.stream = serang_sounds[rng.randi_range(0, serang_sounds.size() - 1)]
		audio_attack.pitch_scale = rng.randf_range(0.9, 1.2)
		audio_attack.play()
		last_attack_time = 0.0

func _stop_attack_sound_if_playing():
	if audio_attack.playing:
		audio_attack.stop()


# === SUARA TAMBAHAN ===
func _play_hit_sound():
	if audio_kenahit and not audio_kenahit.playing:
		audio_kenahit.stream = hit_sounds[rng.randi_range(0, hit_sounds.size() - 1)]
		audio_kenahit.pitch_scale = rng.randf_range(0.9, 1.1)
		audio_kenahit.play()

func _play_die_sound():
	if audio_mati and not audio_mati.playing:
		audio_mati.stream = mati_sounds[rng.randi_range(0, mati_sounds.size() - 1)]
		audio_mati.pitch_scale = rng.randf_range(0.9, 1.1)
		audio_mati.play()


func _on_anim_finished():
	if not anim: return
	if anim.animation.begins_with("serang"):
		is_attacking = false
		_stop_attack_sound_if_playing()
