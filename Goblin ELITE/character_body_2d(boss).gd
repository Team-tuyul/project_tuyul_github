extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var area_deteksi = $DeteksiPlayer
@onready var area_serang = $Serang
@onready var attack_timer = $AttackTimer # Cooldown Serangan
@onready var hit_timer = $HitTimer # Timer Jaminan Reset is_hit
@onready var despawn_timer = $DespawnTimer # Timer untuk menghapus Boss setelah mati

# === AUDIO ===
@onready var audio_step = $AudioStep
@onready var audio_attack = $AudioAttack
@onready var audio_lari = $AudioLari
@onready var audio_kenahit = $AudioKenaHit
@onready var audio_mati = $AudioMati

# === STAT ===
var max_health = 100
var health = 100
var attack_min = 10
var attack_max = 20
var speed = 35
var chase_speed = 50 # Dibuat lebih cepat dari speed agar lebih terasa mengejar
var attack_cooldown = 8.0

# === INTERNAL STATE ===
var player: Node2D = null
var is_chasing = false
var is_attacking = false
var is_hit = false
var is_cooldown = false # State cooldown
var idle_timer = 0.0
var random_target = Vector2.ZERO
var rng = RandomNumberGenerator.new()

# === KONSTANTA PERILAKU ===
const RANDOM_WALK_RADIUS = 250
const IDLE_DURATION = 2.5
const STOP_DISTANCE = 5.0 # Jarak berhenti saat mengejar

# === SUARA ===
var langkah_sounds = [
	preload("res://asset game tuyul/Theme Song/step boss.mp3")
]
var serang_sounds = [
	preload("res://asset game tuyul/Theme Song/sword slice boss.mp3")
]
var lari_sounds = [
	preload("res://asset game tuyul/Theme Song/lari boss.mp3")
]
var hit_sounds = [
	preload("res://asset game tuyul/Theme Song/suara kena hit boss.mp3")
]
var mati_sounds = [
	preload("res://asset game tuyul/Theme Song/growl boss.mp3")
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
	
	# Hubungkan semua Timer
	if not hit_timer.timeout.is_connected(_on_hit_timer_timeout):
		hit_timer.timeout.connect(_on_hit_timer_timeout)
	
	if not despawn_timer.timeout.is_connected(_on_despawn_timer_timeout):
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
# ⚡️ HUBUNGKAN SINYAL DESPAWN TIMER
	if not despawn_timer.timeout.is_connected(_on_despawn_timer_timeout):
		despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		
	_set_random_target()


func _physics_process(delta):
	last_step_time += delta
	last_attack_time += delta
	last_lari_time += delta

	# BLOKIR PERGERAKAN JIKA MATI, KENDA HIT, ATAU COOLDOWN AKTIF
	if health <= 0 or is_hit:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# LOGIKA COOLDOWN (Boss idle terarah)
	if is_cooldown:
		velocity = Vector2.ZERO
		_stop_step_sound_if_playing()
		_stop_lari_sound_if_playing()
		
		# Boss idle menghadap Player selama cooldown
		if player:
			var dir = (player.global_position - global_position).normalized()
			# Panggil _set_flip_direction sebelum play animasi
			_set_flip_direction(dir)
			anim.play(_get_anim("idle", dir))
		else:
			anim.play(_get_anim("idle", Vector2.ZERO))
			
		move_and_slide()
		return

	# LOGIKA SERANG (Hanya terjadi selama animasi serang dimainkan)
	if is_attacking and player:
		_stop_step_sound_if_playing()
		_stop_lari_sound_if_playing()

		velocity = Vector2.ZERO
		var dir = (player.global_position - global_position).normalized()
		# Panggil _set_flip_direction sebelum play animasi serang
		_set_flip_direction(dir)
		anim.play(_get_anim("serang", dir))
		_update_attack_sound()
		return

	# LOGIKA CHASE/KEJAR
	if is_chasing and player:
		var dist = global_position.distance_to(player.global_position)

		if dist > STOP_DISTANCE:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * chase_speed
			# Panggil _set_flip_direction untuk animasi lari
			_set_flip_direction(dir) 
			anim.play(_get_anim("lari", dir))
			if not is_attacking:
				_update_lari_sound()
			_stop_step_sound_if_playing()
		else:
			# Berhenti di depan Player (Jarak < STOP_DISTANCE)
			velocity = Vector2.ZERO
			var dir = (player.global_position - global_position).normalized()
			_set_flip_direction(dir)
			anim.play(_get_anim("idle", dir))
			_stop_lari_sound_if_playing()
	
	# LOGIKA IDLE/RANDOM WALK (Jika tidak chasing)
	else:
		if global_position.distance_to(random_target) < 10:
			# Boss mencapai target, masuk ke IDLE
			idle_timer += delta
			velocity = Vector2.ZERO
			# Pastikan Boss tidak flip saat idle diam
			anim.flip_h = false
			anim.play(_get_anim("idle", Vector2.ZERO))
			_stop_step_sound_if_playing()
			_stop_lari_sound_if_playing()
			if idle_timer >= IDLE_DURATION:
				_set_random_target() # Tentukan target baru setelah durasi idle
				idle_timer = 0.0
		else:
			# Boss sedang Random Walk
			var dir = (random_target - global_position).normalized()
			velocity = dir * speed
			# Panggil _set_flip_direction untuk animasi jalan
			_set_flip_direction(dir)
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
		is_cooldown = false
		player = null
		_set_random_target()
		attack_timer.stop()


func _on_attack_range(body):
	if body.is_in_group("player") and not is_hit and not is_cooldown and not is_attacking:
		is_attacking = true
		player = body
		_do_attack(body)


func _on_attack_out(body):
	if body.is_in_group("player"):
		is_attacking = false
		_stop_attack_sound_if_playing()


func _do_attack(target):
	if not target: return
	_update_attack_sound(true)
	var damage = rng.randi_range(attack_min, attack_max)
	if target.has_method("take_damage"):
		target.take_damage(damage)


func _on_attack_timer_timeout():
	is_cooldown = false
	


# ----------------------------------------------------
# 🎨 FUNGSI BANTU MENDAPATKAN NAMA ANIMASI
# ----------------------------------------------------
# FUNGSI INI HANYA MENGEMBALIKAN NAMA ANIMASI, TIDAK MENGATUR FLIP
func _get_anim(base:String, dir:Vector2=Vector2.ZERO) -> String:
	if dir == Vector2.ZERO:
		return base + "_bawah"

	if abs(dir.x) > abs(dir.y):
		return base + "_kanan_kiri"
	elif dir.y < 0:
		return base + "_atas"
	else:
		return base + "_bawah"

# 🔄 FUNGSI BARU UNTUK MENGATUR FLIP BERDASARKAN ARAH (HANYA KANAN/KIRI)
func _set_flip_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		# Jika bergerak ke kiri (dir.x < 0), Boss harus menghadap kiri (flip_h=true)
		# Jika bergerak ke kanan (dir.x > 0), Boss harus menghadap kanan (flip_h=false)
		anim.flip_h = dir.x < 0
	else:
		# Reset flip untuk animasi atas/bawah
		anim.flip_h = false


# ----------------------------------------------------
# 💥 FUNGSI KENDA DAMGE (MEMPERBAIKI FLIP/INVERT)
# ----------------------------------------------------
func take_damage(amount:int):
	if health <= 0 or is_hit:
		return
		
	health -= amount
	
	is_hit = true
	is_attacking = false
	is_cooldown = false
	attack_timer.stop()
	velocity = Vector2.ZERO
	
	var damage_direction = Vector2.ZERO
	if player:
		# damage_direction adalah arah sentakan Boss (menjauhi player)
		damage_direction = (global_position - player.global_position).normalized()
	
	var damage_anim_name = _get_anim("damage", damage_direction)
	anim.play(damage_anim_name)
	
	# ⚡️ PERBAIKAN FLIP: Flip terjadi HANYA jika animasi kanan/kiri
	if damage_anim_name.ends_with("_kanan_kiri"):
		# Saat terkena hit, Boss tersentak ke arah damage_direction.
		# Jika tersentak ke KANAN (damage_direction.x > 0), Boss harus menghadap KIRI (flip_h=true)
		anim.flip_h = damage_direction.x > 0
	else:
		anim.flip_h = false # Animasi atas/bawah tidak di-flip
	
	_play_hit_sound()
	
	if anim.animation_finished.is_connected(_on_damage_anim_finished):
		anim.animation_finished.disconnect(_on_damage_anim_finished)
	anim.animation_finished.connect(_on_damage_anim_finished)
	
	hit_timer.start()
	
	if health <= 0:
		_die()

# ----------------------------------------------------
# 🔁 HANDLER SETELAN ANIMASI DAMAGE SELESAI
# ----------------------------------------------------
func _on_damage_anim_finished():
	if anim.animation_finished.is_connected(_on_damage_anim_finished):
		anim.animation_finished.disconnect(_on_damage_anim_finished)
		
	hit_timer.stop()
		
	if anim.animation.begins_with("damage"):
		is_hit = false
		# Kembali ke state normal (akan diproses di _physics_process)
		anim.play("idle_bawah") # Animasi default


# ----------------------------------------------------
# 🔁 HANDLER JAMINAN RESET IS_HIT
# ----------------------------------------------------
func _on_hit_timer_timeout():
	if anim.animation_finished.is_connected(_on_damage_anim_finished):
		anim.animation_finished.disconnect(_on_damage_anim_finished)
		
	if is_hit:
		is_hit = false
		anim.play("idle_bawah") # Animasi default

# ----------------------------------------------------
# ☠️ FUNGSI MATI (FINAL)
# ----------------------------------------------------
func _die():
	# 1. NONAKTIFKAN SEMUA STATE
	is_chasing = false
	is_attacking = false
	is_hit = false
	is_cooldown = false
	attack_timer.stop()
	hit_timer.stop() 
	velocity = Vector2.ZERO
	
	# 2. NONAKTIFKAN INTERAKSI AREA (Agar mayat tidak bisa menyerang atau dideteksi)
	if area_serang:
		area_serang.set_deferred("monitoring", false) # Menonaktifkan area serang
	if area_deteksi:
		area_deteksi.set_deferred("monitoring", false) # Menonaktifkan area deteksi
	
	# Putuskan koneksi animasi damage jika ada
	if anim.animation_finished.is_connected(_on_damage_anim_finished):
		anim.animation_finished.disconnect(_on_damage_anim_finished)
	
	# 3. LOGIKA ANIMASI KEMATIAN
	var die_direction = Vector2.ZERO
	if player:
		die_direction = (global_position - player.global_position).normalized()
		
	var die_anim_name = _get_anim("mati", die_direction)
	anim.play(die_anim_name)
	
	if die_anim_name.ends_with("_kanan_kiri"):
		anim.flip_h = die_direction.x > 0
	else:
		anim.flip_h = false
	
	_play_die_sound()
	
	# 4. MEMASTIKAN BERHENTI DI FRAME 7
	await anim.animation_finished
	
	# Setelah animasi selesai, kita Paksakan berhenti dan memastikan tidak ada loop.
	anim.frame = 7
	anim.stop()
	
	# 5. MULAI DESPAWN TIMER
	despawn_timer.start()

# ----------------------------------------------------
# 💀 HANDLER DESPAWN TIMER (Tidak Berubah)
# ----------------------------------------------------
func _on_despawn_timer_timeout():
	queue_free()


# === AUDIO HELPERS (Tidak Berubah) ===
func _update_step_sound():
	if is_attacking or is_hit or is_cooldown or (anim and anim.animation.begins_with("serang")):
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
	if is_attacking or is_hit or is_cooldown or (anim and anim.animation.begins_with("serang")):
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


# === SUARA TAMBAHAN (Tidak Berubah) ===
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
		
		is_cooldown = true
		attack_timer.start(attack_cooldown)
