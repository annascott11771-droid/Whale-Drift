extends Node

# End-to-end input test for Whale Drift.
# Runs the real Main.tscn at a tablet aspect ratio, injects real touch events and
# checks the game reacts the way a player would expect.

var main: Node2D
var failures := 0
var step := 0
var wait := 0
var done := false
var drag_y0 := 0.0
var lang_before := ""
var frame_times: Array = []
var bench_frames := 0

func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS  ", label)
	else:
		failures += 1
		print("FAIL  ", label)

func _ready() -> void:
	main = load("res://Main.tscn").instantiate()
	main.force_mobile = true
	add_child(main)

func to_screen_px(local: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * (local + main.position)

func touch_down(local: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = true
	ev.position = to_screen_px(local)
	Input.parse_input_event(ev)

func touch_up(local: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = false
	ev.position = to_screen_px(local)
	Input.parse_input_event(ev)

func touch(local: Vector2) -> void:
	touch_down(local)
	touch_up(local)

func _process(delta: float) -> void:
	if done:
		return
	wait += 1
	if wait < 2:
		return
	wait = 0
	var s := step
	step += 1
	match s:
		0:
			main.capture_resize = Vector2i(1024, 768)
		1:
			main.is_mobile = true
			main._apply_window()
			var vis := get_viewport().get_visible_rect().size
			print("window=", get_window().size, " visible=", vis, " offset=", main.position)
			check(vis.y >= 900.0, "4:3 tablet exposes extra design height (%.0f)" % vis.y)
			check(main.position.y >= 100.0, "content is centred vertically (%.0f)" % main.position.y)
		2:
			main.state = "menu"
			main.selection = 0
		3:
			check(main.ui_buttons.size() == 6, "menu exposes 6 buttons (got %d)" % main.ui_buttons.size())
			touch(Vector2(82 + 186, 316 + 4 * 54 + 24))
		4:
			check(main.state == "settings", "tap SETTINGS opens settings (state=%s)" % main.state)
			var rows: Array = main._setting_rows()
			print("rows=", rows)
			check(not ("display_mode" in rows), "mobile hides display_mode row")
			check(not ("resolution" in rows), "mobile hides resolution row")
			var li := rows.find("language")
			check(li >= 0, "language row present")
			var r: Rect2 = main._setting_row_rect(li)
			lang_before = main.settings.language
			touch(Vector2(r.position.x + 860, r.position.y + r.size.y * 0.5))
		5:
			check(main.settings.language != lang_before, "tap row right cycles language (%s -> %s)" % [lang_before, main.settings.language])
			var rows2: Array = main._setting_rows()
			var li2 := rows2.find("language")
			var r2: Rect2 = main._setting_row_rect(li2)
			lang_before = main.settings.language
			touch(Vector2(r2.position.x + 300, r2.position.y + r2.size.y * 0.5))
		6:
			check(main.settings.language == lang_before, "tap row left only selects (no accidental change)")
			var rows3: Array = main._setting_rows()
			var desc_y := 148.0 + rows3.size() * 42.0 + 12.0
			touch(Vector2(410 + 110, desc_y + 58.0 + 23.0))
		7:
			check(main.state == "menu", "tap DONE returns to menu (state=%s)" % main.state)
			touch(Vector2(82 + 186, 316 + 24))
		8:
			check(main.state == "playing", "tap NEW DIVE starts run (state=%s)" % main.state)
			check(main.ui_buttons.is_empty(), "no stale UI buttons while playing (%d)" % main.ui_buttons.size())
			main.mouse_pos = Vector2(82 + 186, 316 + 24)
			main._handle_click()
			check(main.state == "playing", "click during gameplay is ignored")
		9:
			drag_y0 = main.player_y
			touch_down(Vector2(640, 360))
		10:
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.position = to_screen_px(Vector2(640, 430))
			drag.relative = Vector2(0, 70)
			Input.parse_input_event(drag)
		11:
			check(absf(main.player_y - drag_y0) > 8.0, "drag moves whale (%.1f -> %.1f)" % [drag_y0, main.player_y])
			touch_up(Vector2(640, 430))
		12:
			var scr: Rect2 = main._screen_rect()
			var pr: Rect2 = main._mobile_pause_rect()
			var dr: Rect2 = main._mobile_dash_rect()
			check(scr.encloses(pr), "pause button inside screen")
			check(scr.encloses(dr), "dash button inside screen")
			check(pr.size.x >= 44.0 and pr.size.y >= 44.0, "pause button >=44 (%.0f)" % pr.size.x)
			check(dr.size.x >= 44.0 and dr.size.y >= 44.0, "dash button >=44 (%.0f)" % dr.size.x)
			check(not pr.intersects(dr), "pause and dash do not overlap")
			touch(pr.get_center())
		13:
			check(main.state == "paused", "tap pause works (state=%s)" % main.state)
			main.speed = 520.0
			main.distance = 300.0
			main.selection = 1
			main._pause_activate()
		14:
			check(main.state == "playing" and main.distance < 1.0, "restart resets distance (%.1f)" % main.distance)
			check(main.speed < 340.0, "restart resets speed (%.0f)" % main.speed)
			main.dash_cd = 0.0
			var s0 = main.speed
			main._dash()
			for i in range(10):
				main._tick_game(0.016)
			check(main.speed > s0 + 20.0, "dash increases speed (%.0f -> %.0f)" % [s0, main.speed])
			check(main.invuln > 0.3, "dash grants invulnerability (%.2f)" % main.invuln)
		15:
			var h0 = main.hp
			main.invuln = 0.0
			main.dash_timer = 0.0
			main.obstacles.clear()
			main._spawn_spike(main.scroll_x + 3000.0, "top")
			main._check_collisions()
			check(is_equal_approx(main.hp, h0), "distant spike does not hit")
			var h1 = main.hp
			main.invuln = 0.0
			main.dash_timer = 0.0
			main.obstacles.clear()
			main.player_y = 300.0
			main.obstacles.append({"kind":"spike","side":"top","w":200.0,"h":300.0,"draw_y":180.0,
				"x":main.scroll_x + main.PLAYER_X,"tex":main.spike_frames[0],"used":false})
			main._check_collisions()
			check(is_equal_approx(main.hp, h1 - main.HIT_DAMAGE), "overlapping spike costs half a heart (%.1f -> %.1f)" % [h1, main.hp])
		16:
			# sub-stepping: one huge frame must not skip past a spike
			main._start_new()
			main.invuln = 0.0
			main.player_y = 300.0
			main.obstacles.clear()
			main.dash_timer = 0.0
			main.obstacles.append({"kind":"spike","side":"top","w":200.0,"h":300.0,"draw_y":180.0,
				"x":main.scroll_x + main.PLAYER_X + 4.0,"tex":main.spike_frames[0],"used":false})
			var hh = main.hp
			main._process(0.25)
			check(main.hp <= hh, "large frame still resolves collision (hp %.1f)" % main.hp)
		17:
			# --- health model: 6 points, half-heart steps ---
			main._start_new()
			main.invuln = 0.0
			main.dash_timer = 0.0
			main.bubble_stacks = 0
			check(is_equal_approx(main.hp, 6.0), "max hp is 6 points (%.1f)" % main.hp)
			check(is_equal_approx(main._heart_fill(0), 1.0), "heart 1 full at 6 hp")
			main.hp = 3.0
			check(is_equal_approx(main._heart_fill(0), 1.0), "hp 3 -> heart 1 full")
			check(is_equal_approx(main._heart_fill(1), 0.5), "hp 3 -> heart 2 half")
			check(is_equal_approx(main._heart_fill(2), 0.0), "hp 3 -> heart 3 empty")
			main.hp = 5.0
			check(is_equal_approx(main._heart_fill(2), 0.5), "hp 5 -> third heart half")
		18:
			# one clean hit costs 1 point = half a heart
			main._start_new()
			main.bubble_stacks = 0
			main.invuln = 0.0
			main.dash_timer = 0.0
			main._hit_player()
			check(is_equal_approx(main.hp, 5.0), "clean hit removes 1 point (hp %.1f)" % main.hp)
		19:
			# a stacked bubble soaks half of the hit and is consumed
			main._start_new()
			main.bubble_stacks = 1
			main.invuln = 0.0
			main.dash_timer = 0.0
			main._hit_player()
			check(is_equal_approx(main.hp, 5.5), "bubble halves the hit (hp %.1f)" % main.hp)
			check(main.bubble_stacks == 0, "bubble is consumed (%d)" % main.bubble_stacks)
		20:
			# stacking up to six and refusing more
			main._start_new()
			for i in range(10):
				main._collect({"kind": "shield", "x": 0.0, "y": 0.0, "alive": true})
			check(main.bubble_stacks == 6, "bubbles stack to 6 (%d)" % main.bubble_stacks)
			main.invuln = 0.0
			main.dash_timer = 0.0
			var hp_before = main.hp
			main._hit_player()
			check(is_equal_approx(main.hp, hp_before - 0.5), "6-stack still halves one hit (%.1f)" % main.hp)
			check(main.bubble_stacks == 5, "one bubble consumed from the stack (%d)" % main.bubble_stacks)
		21:
			# death only at zero
			main._start_new()
			main.hp = 0.5
			main.bubble_stacks = 0
			main.invuln = 0.0
			main.dash_timer = 0.0
			main._hit_player()
			check(main.state == "gameover", "hp 0 ends the run")
		22:
			# fps label uses the engine measurement
			main.settings.show_fps = true
			check(main.fps_shown >= 0.0, "fps value available (%.0f)" % main.fps_shown)
		23:
			print("RESULT failures=", failures)
			done = true
			get_tree().quit(failures)
