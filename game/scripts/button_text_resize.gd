extends Button

func _ready():
	update_font_size()

func update_font_size():
	var font = get_theme_font("font")
	if font:
		var new_size = int(size.y * 0.6)
		add_theme_font_size_override("font_size", new_size)
