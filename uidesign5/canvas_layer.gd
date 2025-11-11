# File: in_game_ui.gd
extends CanvasLayer

# 1. Definisikan sinyal yang akan dikirim
signal pause_requested
signal resume_requested

# ...

# --- Fungsi yang terhubung ke Tombol Pause HUD ---
func _on_pause_button_pressed():
	# 2. Kirim sinyal (berteriak)
	pause_requested.emit()
	
# --- Fungsi yang terhubung ke Tombol Resume ---
func _on_resume_button_pressed():
	# 2. Kirim sinyal (berteriak)
	resume_requested.emit()
