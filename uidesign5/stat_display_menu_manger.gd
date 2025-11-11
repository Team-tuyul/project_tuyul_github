extends VBoxContainer

@onready var coin_display = $coinDisplay
@onready var score_display = $scoreDisplay

var coins: String = str(84)
var score: String = str(1928)

func _process(delta):
	#coins = str(global.coins)
	#score = str(global.current_score
	update_text()

func update_text():
	coin_display.text = ("COINS: " + coins)
	score_display.text = ("SCORE: " + score)
