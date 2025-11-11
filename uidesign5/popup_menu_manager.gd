extends MarginContainer

@export var menu_screen: VBoxContainer
@export var open_menu_screen: VBoxContainer
@export var help_menu_screen: MarginContainer
@export var setting_menu_screen: MarginContainer
@export var pause_menu_screen: MarginContainer

@export var open_menu_button: Button
@export var close_menu_button: Button
@export var open_help_button: Button
@export var close_help_button: Button
@export var open_settings_button: Button
@export var close_settings_button: Button
@export var open_pause_button: Button
@export var close_pause_button: Button
@export var open_quit_button: Button

var in_menu_buttons: Array
var close_menu_buttons: Array
var toggle_popupmenu_buttons: Array

func _ready():
	in_menu_buttons = [open_help_button, open_settings_button, open_pause_button, open_quit_button]
	toggle_popupmenu_buttons = [open_menu_button, close_menu_button]
	close_menu_buttons = [close_settings_button, close_help_button, close_pause_button]

func _process(delta):
	update_button_scale()

func update_button_scale():
	for button in in_menu_buttons:
		button_hov(button, 1.3, 0.2)
	for button in toggle_popupmenu_buttons:
		button_hov(button, 1.8, 0.3)
	for button in close_menu_buttons:
		button_hov(button, 1.5, 0.2)

func button_hov(button: Button, tween_amt, duration):
	button.pivot_offset = button.size / 2
	if button.is_hovered():
		tween(button, "scale", Vector2.ONE * tween_amt, duration)
	else:
		tween(button, "scale", Vector2.ONE, duration)

func tween(button, property, amount, duration):
	var tween = create_tween()
	tween.tween_property(button, property, amount, duration)

func toggle_visibility(object):
	var anim = $AnimationPlayer
	var animation_type: String
	if object.visible:
		animation_type = "close_"
	else:
		animation_type = "open_"
	anim.play(animation_type + str(object.name))

func _on_toggle_menu_button_pressed():
	toggle_visibility(menu_screen)

func _on_toggle_help_menu_button_pressed():
	toggle_visibility(help_menu_screen)

func _on_toggle_setting_menu_button_pressed():
	toggle_visibility(setting_menu_screen)

func _on_pause_button_pressed():
	toggle_visibility(pause_menu_screen)

func _on_quit_button_pressed():
	get_tree().quit()
