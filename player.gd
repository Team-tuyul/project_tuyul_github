extends CharacterBody2D

@export var move_speed: float = 120.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5

var can_attack: bool = true
var hp: int = 100

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_attack: Area2D = $Hitbox_Serang   # Pastikan nama node sama


func _physics_process(delta: float) -> void:
	player_movement(delta)

	# Saat serang (tekan J atau Space → bebas nanti diganti)
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()


func player_movement(delta: float) -> void:
	var dir = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1

	dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()

	# Animasi
	if dir == Vector2.ZERO:
		anim.play("idle_bawah")
	else:
		if abs(dir.x) > abs(dir.y):
			anim.play("jalan_kanan_kiri")
			anim.flip_h = dir.x < 0
		else:
			if dir.y < 0:
				anim.play("jalan_atas")
			else:
				anim.play("jalan_bawah")


func attack():
	can_attack = false
	anim.play("serang_bawah") # nanti akan saya buat auto arah seperti boss

	hitbox_attack.set_deferred("monitoring", true)

	# Damage ke musuh yang kena hit
	for body in hitbox_attack.get_overlapping_bodies():
		if body.has_method("take_damage_from_player"):
			body.take_damage_from_player(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	hitbox_attack.set_deferred("monitoring", false)
	can_attack = true


# ----------------- DAMAGE SYSTEM ---------------- #

func take_damage(amount: int):
	hp -= amount
	print("Player HP:", hp)

	anim.play("damage_bawah") # nanti bisa auto arah juga

	if hp <= 0:
		player_die()


func player_die():
	print("Player Mati!")
	anim.play("mati_bawah")
	set_physics_process(false)
