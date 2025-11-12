extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var audio_jalan = $Audio_Jalan  # sound effect langkah

@export var speed: float = 15.0
@export var walk_distance: float = 30.0
@export var idle_duration: float = 5.0
@export var start_delay: float = 3.0  # delay sebelum mulai jalan pertama

var start_position: Vector2
var target_position: Vector2
var is_idling = true
var idle_timer = 0.0
var first_idle_done = false
var patrol_direction = 1  # 1 = kanan, -1 = kiri
var delay_timer = 0.0
var moving = false

func _ready():
	start_position = global_position
	target_position = start_position
	_play_idle_bawah()

func _physics_process(delta):
	if is_idling:
		velocity = Vector2.ZERO
		_stop_sound()  # pastikan suara berhenti pas idle
		idle_timer += delta

		# idle awal
		if not first_idle_done:
			if idle_timer >= start_delay:
				first_idle_done = true
				is_idling = false
				moving = true
				idle_timer = 0.0
				patrol_direction = 1
				start_position = global_position
				target_position = start_position + Vector2(walk_distance * patrol_direction, 0)
			else:
				return
		# idle setelah mondar-mandir
		elif idle_timer >= idle_duration:
			is_idling = false
			moving = true
			idle_timer = 0.0
			patrol_direction = 1
			start_position = global_position
			target_position = start_position + Vector2(walk_distance * patrol_direction, 0)
		else:
			return

	elif moving:
		var dir = target_position - global_position
		if dir.length() > 1:
			dir = dir.normalized()
			velocity = dir * speed
			_play_jalan(dir)
			_play_sound()  # nyalakan suara langkah
		else:
			velocity = Vector2.ZERO
			_stop_sound()  # berhenti jalan = hentikan suara

			# balik arah kalau baru ke kanan
			if patrol_direction == 1:
				patrol_direction = -1
				start_position = global_position
				target_position = start_position + Vector2(walk_distance * patrol_direction, 0)
			else:
				# selesai bolak-balik → idle bawah 5 detik
				moving = false
				is_idling = true
				idle_timer = 0.0
				_play_idle_bawah()
		move_and_slide()

# --- Animasi jalan kanan-kiri ---
func _play_jalan(dir: Vector2):
	anim.flip_h = dir.x < 0
	if anim.animation != "jalan_kanan_kiri":
		anim.play("jalan_kanan_kiri")

# --- Animasi idle bawah ---
func _play_idle_bawah():
	if anim.animation != "idle_bawah":
		anim.play("idle_bawah")

# --- Sound kontrol ---
func _play_sound():
	if not audio_jalan.playing:
		audio_jalan.play()

func _stop_sound():
	if audio_jalan.playing:
		audio_jalan.stop()
