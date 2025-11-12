extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var audio_jalan = $Audio_Jalan_Goblin  # node AudioStreamPlayer2D untuk sound langkah

@export var speed: float = 20.0
@export var walk_distance: float = 40.0
@export var idle_duration: float = 5.0
@export var start_delay: float = 5.0  # delay sebelum mulai jalan pertama

var start_position: Vector2
var target_position: Vector2
var is_idling = true
var idle_timer = 2.0
var first_idle_done = false
var patrol_direction = 1 # 1 = kanan, -1 = kiri
var delay_timer = 0.5

func _ready():
	start_position = global_position
	target_position = start_position
	_play_idle("bawah")  # idle bawah pertama
	_stop_sound()  # pastikan tidak bunyi di awal

func _physics_process(delta):
	if is_idling:
		velocity = Vector2.ZERO
		_stop_sound()  # berhenti suara kalau idle

		# Delay sebelum mulai jalan pertama
		if not first_idle_done:
			delay_timer += delta
			if delay_timer >= start_delay:
				delay_timer = 0
				is_idling = false
				first_idle_done = true
				patrol_direction = 1
				target_position = start_position + Vector2(walk_distance, 0)
			return

		# Idle normal
		idle_timer += delta
		if idle_timer >= idle_duration:
			idle_timer = 0.0
			is_idling = false
			# Balik arah untuk patrol berikutnya
			patrol_direction *= -1
			target_position = global_position + Vector2(walk_distance * patrol_direction, 0)
		else:
			return

	# --- Bagian gerak ---
	var dir = (target_position - global_position)
	if dir.length() > 1: # jangan gerak kalau sudah dekat
		dir = dir.normalized()
		velocity = dir * speed
		_play_jalan(dir)
		_play_sound()  # nyalakan suara jalan saat bergerak
	else:
		velocity = Vector2.ZERO
		_stop_sound()  # berhenti suara kalau diam

	move_and_slide()

	# Jika sampai target → idle kanan-kiri
	if global_position.distance_to(target_position) < 5 and not is_idling:
		is_idling = true
		idle_timer = 0.0
		_play_idle("kanan_kiri")

# --- Animasi jalan kanan-kiri ---
func _play_jalan(dir: Vector2):
	anim.flip_h = dir.x < 0
	if anim.animation != "jalan_kanan_kiri":
		anim.play("jalan_kanan_kiri")

# --- Animasi idle ---
func _play_idle(arah: String):
	match arah:
		"bawah":
			anim.play("idle_bawah")
		"atas":
			anim.play("idle_atas")
		"kanan_kiri":
			anim.play("idle_kanan_kiri")

# --- Sound kontrol ---
func _play_sound():
	if not audio_jalan.playing:
		audio_jalan.play()

func _stop_sound():
	if audio_jalan.playing:
		audio_jalan.stop()
