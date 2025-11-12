extends Area2D

# Coba ambil item di area ketika dipanggil dari player
func try_pickup_item():
	# Ambil semua area yang overlap dengan interaction area
	var areas = get_overlapping_areas()
	for a in areas:
		# Pastikan area itu item (kita tambahkan group "item" di item script)
		if a.is_in_group("item"):
			# jika item menyediakan method pick_up, panggil
			if a.has_method("pick_up"):
				a.pick_up()
			else:
				# fallback: hapus langsung
				a.queue_free()
