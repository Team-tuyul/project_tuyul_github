extends CharacterBody2D

const SPEED_JALAN = 100
const SPEED_LARI = 200
const SPEED_STEALTH = 50

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

var arah = "bawah"  # arah terakhir pemain
var is_stealth = false #status mode stealth
var is_dead = false
var is_hit = false

func _ready():
	camera.make_current()
	add_to_group("player") # biar item bisa kenali ini sebagai player

func _physics_process(_delta):
	if is_dead or is_hit:
		return
		
	cek_input_stealth()
	player_movement()
	atur_animasi()
	atur_visual()

func cek_input_stealth():
	is_stealth = Input.is_action_pressed("stealth_mode")

func player_movement():
	velocity = Vector2.ZERO
	var input_detected = true
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = 1
		arah = "kanan"
		sprite.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -1
		arah = "kiri"
		sprite.flip_h = true
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -1
		arah = "atas"
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 1
		arah = "bawah"
	
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized()
		if is_stealth:
			velocity *= SPEED_STEALTH
		elif Input.is_action_pressed("run"):
			velocity *= SPEED_LARI
		else:
			velocity *= SPEED_JALAN

	move_and_slide()

func atur_animasi():
	if velocity == Vector2.ZERO:
		match arah:
			"atas": sprite.play("idle_atas")
			"bawah": sprite.play("idle_bawah")
			_: sprite.play("idle")
	else:
		if is_stealth:
			match arah:
				"atas": sprite.play("stealth_atas")
				"bawah": sprite.play("stealth_bawah")
				_: sprite.play("stealth")
		elif velocity.length() > SPEED_JALAN + 10:
			match arah:
				"atas": sprite.play("lari_atas")
				"bawah": sprite.play("lari_bawah")
				_: sprite.play("lari")
		else:
			match arah:
				"atas": sprite.play("jalan_atas")
				"bawah": sprite.play("jalan_bawah")
				_: sprite.play("jalan")

func atur_visual():
	if is_stealth:
		sprite.modulate = Color(1, 1, 1, 0.7)
	else:
		sprite.modulate = Color(1,1,1,1)

func on_detected_by_penjaga(direction: String) -> void:
	if is_dead:
		return
	is_hit = true
	
	match direction:
		"atas": sprite.play("kena_hit_atas")
		"bawah": sprite.play("kena_hit_bawah")
		"kanan":
			sprite.flip_h = false
			sprite.play("kena_hit")
		"kiri":
			sprite.flip_h = true
			sprite.play("kena_hit")

	await sprite.animation_finished
	is_hit = false
	_die(direction)

func _die(direction: String) -> void:
	is_dead = true
	match direction:
		"atas": sprite.play("mati_atas")
		"bawah": sprite.play("mati_bawah")
		"kanan":
			sprite.flip_h = false
			sprite.play("mati")
		"kiri":
			sprite.flip_h = true
			sprite.play("mati")


func _on_player_interaction_item_area_entered(area: Area2D) -> void:
	pass # Replace with function body.


func _on_player_interaction_item_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
