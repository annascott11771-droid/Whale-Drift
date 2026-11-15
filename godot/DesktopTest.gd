extends Node

# Desktop regression test: window modes, resolution, mouse clicks, fps cap.

var main: Node2D
var _vol_before = null
var _sens_before := 1.0
var failures := 0
var step := 0
var wait := 0

func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS  ", label)
	else:
		failures += 1
		print("FAIL  ", label)

func _ready() -> void:
	main = load("res://Main.tscn").instantiate()
	add_child(main)

func _process(delta: float) -> void:
	wait += 1
	if wait < 2:
		return
	wait = 0
	var s := step
	step += 1
	match s:
		0:
			main.is_mobile = false
			main.settings.display_mode = "windowed"
			main.settings.resolution = Vector2i(1280, 720)
			main._apply_window()
		1:
			var rows: Array = main._setting_rows()
			check(rows.size() == 9, "desktop shows 9 rows (got %d)" % rows.size())
			check("display_mode" in rows and "resolution" in rows, "desktop keeps display/resolution rows")
			check(get_viewport().get_visible_rect().size == Vector2(1280, 720), "desktop keeps 1280x720 canvas")
		2:
			main.settings.resolution = Vector2i(1600, 900)
			main._apply_window()
		3:
			var w := DisplayServer.window_get_size()
			check(w.x >= 1500, "resolution change resizes window (%s)" % str(w))
			main.settings.resolution = Vector2i(1280, 720)
			main._apply_window()
		4:
			main.settings.fps_limit = 144
			main._save_settings()
			check(Engine.max_fps == 144, "fps cap applied (%d)" % Engine.max_fps)
			main.settings.fps_limit = 60
			main._save_settings()
			check(Engine.max_fps == 60, "fps cap lowered (%d)" % Engine.max_fps)
		5:
			check(main.font_regular != null, "font loaded")
			var cjk := "鲸".unicode_at(0)
			var cjk2 := "深".unicode_at(0)
			check(main.font_regular.has_char(cjk), "regular font has CJK glyph")
			check(main.font_regular.has_char(cjk2), "regular font has second CJK glyph")
			check(main.font_regular.get_string_size("鲸跃深潮", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x > 100.0,
				"chinese title has width")
			main.state = "menu"
			main.selection = 0
		6:
			# mouse path: move then click the SETTINGS row
			var ev := InputEventMouseMotion.new()
			ev.position = Vector2(268, 556)
			Input.parse_input_event(ev)
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = true
			mb.position = Vector2(268, 556)
			Input.parse_input_event(mb)
		7:
			check(main.state == "settings", "mouse click opens settings (state=%s)" % main.state)
		8:
			# tapping the right half of a row cycles that row's value
			var r: Rect2 = main._setting_row_rect(0)
			_vol_before = main.settings.difficulty
			main.mouse_pos = Vector2(r.position.x + 800, r.position.y + 19)
			main._handle_click()
		9:
			check(main.settings.difficulty != _vol_before, "row tap cycles difficulty")
			var r2: Rect2 = main._setting_row_rect(4)
			_vol_before = main.settings.sensitivity
			main.mouse_pos = Vector2(796, r2.position.y + 19)
			main._handle_click()
		10:
			check(main.settings.sensitivity != _vol_before, "left arrow cycles sensitivity")
			var r3: Rect2 = main._setting_row_rect(4)
			_sens_before = main.settings.sensitivity
			main.mouse_pos = Vector2(846, r3.position.y + 19)
			main._handle_click()
		11:
			check(main.settings.sensitivity != _sens_before, "right arrow cycles sensitivity")
			main.state = "menu"
		12:
			check(main.ui_buttons.size() == 6, "menu buttons rebuilt after leaving settings")
			print("RESULT failures=", failures)
			get_tree().quit(failures)
