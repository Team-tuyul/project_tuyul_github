extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $Hitbox                         # CollisionShape2D untuk kena damage
@onready var serang_area = $"Area Serang"             # Area2D untuk mendeteksi player
<<<<<<< HEAD
@onready var serang_shape = $"Area Serang/CollisionShape2D"
=======
@onready var serang_shape = $"Area Serang"
>>>>>>> c78fbb43f66c759eb8b8cf321716e0f919dc0c41

@export var max_hp: int = 50
@export var damage: int = 10
@export var attack_cooldown: float = 1.2

var current_hp: int
var is_dead = false
var is_attacking = false
var is_taking_damage = false
var last_attack_time = 0.0

var arah = "bawah"
var target_player: Node = null


func _ready():
	current_hp = max_hp
	_play_idle()
	serang_area.body_entered.connect(_on_player_enter)
	serang_area.body_exited.connect(_on_player_exit)


func _physics_process(delta):
	if is_dead or is_taking_damage:
		return
		
	if target_player == null:
		# Tidak ada player → idle
		_play_idle()
		return

	# Ada player → coba serang
	_try_attack(target_player)


# ================== ANIMASI ==================

func _play_idle():
	if is_dead or is_attacking or is_taking_damage:
		return
	
	match arah:
		"atas":
			anim.play("idle_atas")
		"bawah":
			anim.play("idle_bawah")
		"kanan_kiri":
			anim.play("idle_kanan_kiri")


func _play_serang():
	is_attacking = true
	
	match arah:
		"atas":
			anim.play("serang_atas")
		"bawah":
			anim.play("serang_bawah")
		"kanan_kiri":
			anim.play("serang_kanan_kiri")
	
<<<<<<< HEAD
	anim.animation_finished.connect(_on_serang_selesai, CONNECT_ONE_SHOT)

=======
	# Cegah double connect
	if not anim.animation_finished.is_connected(_on_serang_selesai):
		anim.animation_finished.connect(_on_serang_selesai, CONNECT_ONE_SHOT)
>>>>>>> c78fbb43f66c759eb8b8cf321716e0f919dc0c41

func _play_damage():
	is_taking_damage = true
	
	match arah:
		"atas":
			anim.play("damage_atas")
		"bawah":
			anim.play("damage_bawah")
		"kanan_kiri":
			anim.play("damage_kanan_kiri")
	
	anim.animation_finished.connect(_on_damage_selesai, CONNECT_ONE_SHOT)


func _play_mati():
	is_dead = true
	hitbox.disabled = true
	serang_shape.disabled = true
	
	match arah:
		"atas":
			anim.play("mati_atas")
		"bawah":
			anim.play("mati_bawah")
		"kanan_kiri":
			anim.play("mati_kanan_kiri")


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


func _on_player_exit(body):
	if body == target_player:
		target_player = null
		is_attacking = false
		_play_idle()


func _try_attack(player):
	if is_dead or is_attacking or is_taking_damage:
		return

	# Cooldown
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time < attack_cooldown:
		return

	_set_arah(player.global_position - global_position)
	last_attack_time = now
	_play_serang()


func _on_serang_selesai():
	is_attacking = false
	_play_idle()


# ================== FACING DIRECTION ==================

func _set_arah(diff: Vector2):
	if abs(diff.x) > abs(diff.y):
		arah = "kanan_kiri"
		anim.flip_h = diff.x < 0   # kiri = flip
	else:
		arah = "bawah" if diff.y > 0 else "atas"
