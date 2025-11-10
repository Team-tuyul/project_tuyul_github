extends CharacterBody2D

@export var move_speed: float = 70.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0

var player: Node2D = null
var is_player_detected: bool = false
var can_attack: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var agro_area: Area2D = $"Deteksi Player"
@onready var attack_area: Area2D = $"Serang"

func _ready():
	agro_area.body_entered.connect(_on_player_entered)
	agro_area.body_exited.connect(_on_player_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)

	anim.play("idle_bawah") # default facing down


func _physics_process(delta: float) -> void:
	if is_player_detected and player:
		move_towards_player(delta)
	else:
		idle_animation()


func move_towards_player(delta: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	if can_attack:
		play_movement_animation(direction)


func idle_animation():
	velocity = Vector2.ZERO

	var current = anim.animation
	if current.begins_with("jalan"):
		var arah = current.trim_prefix("jalan_")
		anim.play("idle_" + arah)


func play_movement_animation(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		anim.play("jalan_kanan_kiri")
		anim.flip_h = direction.x < 0
	else:
		if direction.y < 0:
			anim.play("jalan_atas")
		else:
			anim.play("jalan_bawah")


# ---------------- SIGNAL HANDLER DETEKSI PLAYER ---------------- #

func _on_player_entered(body):
	if body.name == "Player":
		player = body
		is_player_detected = true


func _on_player_exited(body):
	if body == player:
		is_player_detected = false
		player = null


# ---------------- ATTACK SYSTEM ---------------- #

func _on_attack_area_entered(body):
	if body == player and can_attack:
		attack_player()

func attack_player():
	can_attack = false

	var dir = (player.global_position - global_position).normalized()

	# Tentukan anim serang berdasarkan arah player
	if abs(dir.x) > abs(dir.y):
		anim.play("serang_kanan_kiri")
		anim.flip_h = dir.x < 0
	else:
		if dir.y < 0:
			anim.play("serang_atas")
		else:
			anim.play("serang_bawah")

	# Beri damage ke player (player harus punya fungsi take_damage)
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
