extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var serang_area = $"Area Serang"
@onready var serang_shape = $"Area Serang/Area Serang 2"

@onready var sound_idle = $"Suara Idle"
@onready var sound_attack = $"Suara Serang"
@onready var sound_hit = $"Suara Kena Hit"
@onready var sound_die = $"Suara Mati"

@export var max_hp: int = 50
@export var damage: int = 10
@export var attack_cooldown: float = 1.2
@export var attack_hit_delay: float = 0.3 # delay pukulan ke player biar sinkron

var current_hp: int
var is_dead = false
var is_attacking = false
var is_taking_damage = false
var last_attack_time = 0.0
var arah = "bawah"
var target_player: Node = null

func _ready():
	current_hp = max_hp
	_play_sound_idle()
	_play_idle()
	serang_area.body_entered.connect(_on_player_enter)
	serang_area.body_exited.connect(_on_player_exit)

func _physics_process(delta):
	if is_dead or is_taking_damage:
		return

	if target_player == null:
		_play_idle()
		return

	_try_attack(target_player)

# ================== ANIMASI ==================
func _play_idle():
	if is_dead or is_taking_damage:
		return
	match arah:
		"atas": anim.play("idle_atas")
		"bawah": anim.play("idle_bawah")
		"kanan_kiri": anim.play("idle_kanan_kiri")

func _play_serang():
	is_attacking = true
	_play_sound_attack()

	match arah:
		"atas": anim.play("serang_atas")
		"bawah": anim.play("serang_bawah")
		"kanan_kiri": anim.play("serang_kanan_kiri")

	# Ini adalah bagian yang diambil dari commit bc00e216abc280394daab7fde5c7d0752e4ec40d
	await get_tree().create_timer(attack_hit_delay).timeout
	_do_attack_hit()

	if not anim.animation_finished.is_connected(_on_serang_selesai):
		anim.animation_finished.connect(_on_serang_selesai, CONNECT_ONE_SHOT)

func _play_damage():
	is_taking_damage = true
	match arah:
		"atas": anim.play("damage_atas")
		"bawah": anim.play("damage_bawah")
		"kanan_kiri": anim.play("damage_kanan_kiri")
	anim.animation_finished.connect(_on_damage_selesai, CONNECT_ONE_SHOT)

func _play_mati():
	is_dead = true
	hitbox.disabled = true
	serang_shape.disabled = true

	if sound_die:
		sound_die.play()

	# stop semua suara kecuali mati
	if sound_idle and sound_idle.playing:
		sound_idle.stop()
	if sound_attack and sound_attack.playing:
		sound_attack.stop()

	match arah:
		"atas": anim.play("mati_atas")
		"bawah": anim.play("mati_bawah")
		"kanan_kiri": anim.play("mati_kanan_kiri")

	# ketika animasi mati selesai, hapus node musuh
	anim.animation_finished.connect(_on_mati_selesai, CONNECT_ONE_SHOT)
		
func _on_mati_selesai():
	if is_dead:
		queue_free()

# ================== DAMAGE SYSTEM ==================
func take_damage(amount: int, player_pos: Vector2):
	if is_dead:
		return

	current_hp -= amount
	_set_arah(player_pos - global_position)
	_play_damage()

	if current_hp <= 0:
		_play_mati()

func _on_damage_selesai():
	is_taking_damage = false
	_play_idle()

# ================== SERANG SYSTEM ==================
func _on_player_enter(body):
	if body.is_in_group("player"):
		target_player = body
		_play_sound_idle()  # pastikan idle selalu nyala

func _on_player_exit(body):
	if body == target_player:
		target_player = null
		is_attacking = false
		_play_sound_idle()  # nyalain lagi kalau hilang
		_play_idle()

func _try_attack(player):
	if is_dead or is_taking_damage:
		return

	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time < attack_cooldown:
		return

	_set_arah(player.global_position - global_position)
	last_attack_time = now
	_play_serang()

func _do_attack_hit():
	if not target_player:
		return
	if target_player.has_method("take_damage"):
		target_player.take_damage(damage)
	if sound_hit:
		sound_hit.play()

func _on_serang_selesai():
	is_attacking = false
	_play_idle()
	# serang terus kalau player masih di area
	if target_player and not is_dead and not is_taking_damage:
		_try_attack(target_player)

# ================== ARAH ==================
func _set_arah(diff: Vector2):
	if abs(diff.x) > abs(diff.y):
		arah = "kanan_kiri"
		anim.flip_h = diff.x < 0
	else:
		arah = "bawah" if diff.y > 0 else "atas"

# ================== SUARA ==================
func _play_sound_idle():
	if sound_idle and not sound_idle.playing:
		sound_idle.play()

func _play_sound_attack():
	if sound_attack and not sound_attack.playing:
		sound_attack.play()