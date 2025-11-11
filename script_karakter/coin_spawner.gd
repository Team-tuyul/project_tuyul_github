extends Node2D

@export var coin_scene: PackedScene
@export var spawn_area := Rect2(Vector2(-200, -100), Vector2(400, 200)) # area acak
@export var spawn_interval := 2.0 # tiap berapa detik spawn
@export var max_coins := 5 # jumlah maksimal coin di dunia

var active_coins := []

func _ready():
	spawn_timer()

func spawn_timer():
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_spawn_coin)
	add_child(timer)
	timer.start()

func _spawn_coin():
	# bersihkan daftar coin yg sudah hilang
	active_coins = active_coins.filter(func(c): return is_instance_valid(c))

	if active_coins.size() >= max_coins:
		return

	var coin = coin_scene.instantiate()
	var random_pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	coin.position = random_pos
	add_child(coin)
	active_coins.append(coin)
