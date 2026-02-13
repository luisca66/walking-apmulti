extends Node

func _ready():
	print("TextureGenerator initialized")

# --- TEXTURA DE PIEDRA (muro medieval) ---
func generate_stone_wall(size: int = 512) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGB8)

	var rows = 10
	var cols = 8
	var brick_h = size / rows
	var brick_w = size / cols

	# Fondo gris oscuro (mortero)
	img.fill(Color(0.18, 0.18, 0.18))

	for row in range(rows):
		var offset = 0 if row % 2 == 0 else brick_w / 2
		for col in range(-1, cols + 1):
			# Color aleatorio por piedra
			var shade = (100.0 + randf() * 80.0) / 255.0
			var stone_color = Color(shade * 0.95, shade, shade * 0.9)

			var bx = int(col * brick_w + offset + 2)
			var by = int(row * brick_h + 2)
			var bw = int(brick_w - 4)
			var bh = int(brick_h - 4)

			# Dibujar rectángulo de piedra
			for py in range(max(0, by), min(size, by + bh)):
				for px in range(max(0, bx), min(size, bx + bw)):
					# Agregar ruido sutil por pixel
					var noise_val = (randf() - 0.5) * 0.06
					var c = Color(
						clampf(stone_color.r + noise_val, 0.0, 1.0),
						clampf(stone_color.g + noise_val, 0.0, 1.0),
						clampf(stone_color.b + noise_val, 0.0, 1.0)
					)
					img.set_pixel(px, py, c)

			# Borde más oscuro en los bordes de cada piedra (efecto 3D sutil)
			var border = 3
			for py in range(max(0, by), min(size, by + border)):
				for px in range(max(0, bx), min(size, bx + bw)):
					var c = img.get_pixel(px, py).darkened(0.15)
					img.set_pixel(px, py, c)
			for py in range(max(0, by + bh - border), min(size, by + bh)):
				for px in range(max(0, bx), min(size, bx + bw)):
					var c = img.get_pixel(px, py).darkened(0.1)
					img.set_pixel(px, py, c)

	var tex = ImageTexture.create_from_image(img)
	return tex

# --- TEXTURA DE PUERTA DE MADERA ---
func generate_wood_door(width: int = 512, height: int = 1024) -> ImageTexture:
	var img = Image.create(width, height, false, Image.FORMAT_RGB8)

	var planks = 6
	var plank_w = width / planks
	var wood_colors = [
		Color(0.427, 0.298, 0.255),  # marrón medio
		Color(0.365, 0.251, 0.216),  # marrón oscuro
		Color(0.475, 0.333, 0.282),  # marrón claro
		Color(0.306, 0.204, 0.176),  # marrón muy oscuro
		Color(0.553, 0.431, 0.388),  # marrón pastel
		Color(0.243, 0.149, 0.137)   # marrón profundo
	]

	# Pintar tablones
	for i in range(planks):
		var base_color = wood_colors[randi() % wood_colors.size()]
		var x_start = i * plank_w

		for py in range(height):
			for px in range(x_start, min(width, x_start + plank_w)):
				# Vetas verticales de madera
				var veta = sin(float(px) * 0.3 + float(py) * 0.02 + randf() * 0.5) * 0.04
				var noise_val = (randf() - 0.5) * 0.03
				var c = Color(
					clampf(base_color.r + veta + noise_val, 0.0, 1.0),
					clampf(base_color.g + veta * 0.8 + noise_val, 0.0, 1.0),
					clampf(base_color.b + veta * 0.6 + noise_val, 0.0, 1.0)
				)
				img.set_pixel(px, py, c)

		# Línea divisoria entre tablones
		if i > 0:
			for py in range(height):
				var line_x = x_start
				if line_x < width:
					img.set_pixel(line_x, py, Color(0.15, 0.09, 0.06))
					if line_x + 1 < width:
						img.set_pixel(line_x + 1, py, Color(0.15, 0.09, 0.06))

	# Bandas horizontales de hierro
	var band_height = 30
	var band_positions = [int(height * 0.15), int(height * 0.75)]
	for band_y in band_positions:
		for py in range(band_y, min(height, band_y + band_height)):
			for px in range(width):
				var iron_noise = (randf() - 0.5) * 0.05
				img.set_pixel(px, py, Color(0.1 + iron_noise, 0.1 + iron_noise, 0.1 + iron_noise))

		# Remaches/clavos en las bandas
		var stud_spacing = 80
		for sx in range(40, width, stud_spacing):
			var sy = band_y + band_height / 2
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if dx * dx + dy * dy <= 16:  # círculo radio 4
						var px2 = sx + dx
						var py2 = sy + dy
						if px2 >= 0 and px2 < width and py2 >= 0 and py2 < height:
							var dist = sqrt(float(dx * dx + dy * dy)) / 4.0
							var bright = 0.3 - dist * 0.15
							img.set_pixel(px2, py2, Color(bright, bright, bright))

	# Marco exterior
	var frame_w = 4
	var frame_color = Color(0.12, 0.07, 0.04)
	for py in range(height):
		for fx in range(frame_w):
			img.set_pixel(fx, py, frame_color)
			img.set_pixel(width - 1 - fx, py, frame_color)
	for px in range(width):
		for fy in range(frame_w):
			img.set_pixel(px, fy, frame_color)
			img.set_pixel(px, height - 1 - fy, frame_color)

	var tex = ImageTexture.create_from_image(img)
	return tex

# --- TEXTURA DE PASTO ---
func generate_grass(size: int = 512) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGB8)

	for py in range(size):
		for px in range(size):
			var base_g = 0.35 + randf() * 0.15
			var base_r = base_g * 0.5 + randf() * 0.05
			var base_b = base_g * 0.3 + randf() * 0.03
			img.set_pixel(px, py, Color(base_r, base_g, base_b))

	var tex = ImageTexture.create_from_image(img)
	return tex
