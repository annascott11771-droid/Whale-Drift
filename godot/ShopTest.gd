extends Node

# 经济系统 / 天赋商店 / 结算公式自检

var main: Node2D
var failures := 0
var step := 0
var wait := 0
var done := false

func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS  ", label)
	else:
		failures += 1
		print("FAIL  ", label)

func _ready() -> void:
	GlobalData.reset_progress()
	main = load("res://Main.tscn").instantiate()
	main.force_mobile = false
	add_child(main)

func _process(_d: float) -> void:
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
			check(GlobalData.total_pearls == 0, "fresh pearls = 0")
			check(GlobalData.shield_level == 1 and GlobalData.dash_level == 1 and GlobalData.magnet_level == 1,
				"all talents start at level 1")
		1:
			# ---- 经济公式 ----
			check(GlobalData.calculate_pearls(0.0, 0, 0) == 0, "0 m / 0 pearls = 0")
			check(GlobalData.calculate_pearls(1200.0, 20, 30000) == 24, "1200m + 20 pearls = 24")
			check(GlobalData.calculate_pearls(250.0, 3, 0) == 5, "250m + 3 pearls = 5")
			check(GlobalData.calculate_pearls(9000.0, 100, 200000) == 50, "huge run capped at 50")
			check(GlobalData.calculate_pearls(0.0, 0, 100000) == 1, "score 100k gives +1")
			check(GlobalData.calculate_pearls(0.0, 0, 99999) == 0, "score below 100k gives 0")
			check(GlobalData.calculate_pearls(0.0, 0, 1000000) == 10, "score bonus capped at 10")
		2:
			# ---- 价格阶梯 ----
			check(GlobalData.price_for("shield") == 50, "shield 1->2 costs 50")
			check(GlobalData.price_for("dash") == 60, "dash 1->2 costs 60")
			check(GlobalData.price_for("magnet") == 80, "magnet 1->2 costs 80")
		3:
			# ---- 属性计算 ----
			check(is_equal_approx(GlobalData.get_shield_duration(), 3.0), "shield base 3.0s")
			check(is_equal_approx(GlobalData.get_dash_distance(), 100.0), "dash base 100")
			check(is_equal_approx(GlobalData.get_magnet_radius(), 0.0), "magnet base 0")
		4:
			# ---- 珍珠不足 ----
			GlobalData.total_pearls = 49
			var r1 := GlobalData.try_upgrade("shield")
			check(r1 == "poor", "49 pearls cannot buy (got %s)" % r1)
			check(GlobalData.shield_level == 1, "level unchanged on failure")
		5:
			# ---- 购买成功 ----
			GlobalData.total_pearls = 50
			var r2 := GlobalData.try_upgrade("shield")
			check(r2 == "ok", "50 pearls buys shield lv2 (got %s)" % r2)
			check(GlobalData.shield_level == 2, "shield level 2")
			check(GlobalData.total_pearls == 0, "pearls deducted (%.0f)" % GlobalData.total_pearls)
			check(is_equal_approx(GlobalData.get_shield_duration(), 3.5), "lv2 shield = 3.5s")
			check(GlobalData.price_for("shield") == 120, "next shield price 120")
		6:
			# ---- 满级 ----
			GlobalData.total_pearls = 100000
			for i in range(10):
				GlobalData.try_upgrade("shield")
			check(GlobalData.shield_level == 5, "shield maxes at 5 (got %d)" % GlobalData.shield_level)
			check(is_equal_approx(GlobalData.get_shield_duration(), 5.0), "lv5 shield = 5.0s")
			check(GlobalData.try_upgrade("shield") == "max", "maxed returns max")
			check(GlobalData.price_for("shield") == -1, "maxed price = -1")
		7:
			# ---- 另外两个天赋满级 ----
			for i in range(10):
				GlobalData.try_upgrade("dash")
				GlobalData.try_upgrade("magnet")
			check(is_equal_approx(GlobalData.get_dash_distance(), 180.0), "lv5 dash = 180")
			check(is_equal_approx(GlobalData.get_magnet_radius(), 200.0), "lv5 magnet = 200")
		8:
			# ---- 存档往返 ----
			GlobalData.total_pearls = 777
			GlobalData.save_progress()
			check(FileAccess.file_exists("user://save_data.cfg"), "save file written")
			GlobalData.total_pearls = 0
			GlobalData.shield_level = 1
			GlobalData.load_progress()
			check(GlobalData.total_pearls == 777, "pearls restored (%.0f)" % GlobalData.total_pearls)
			check(GlobalData.shield_level == 5, "talent level restored (%d)" % GlobalData.shield_level)
		9:
			# ---- 商店 UI ----
			main.state = "menu"
			main._open_shop()
			check(main.state == "shop", "shop opens (state=%s)" % main.state)
			check(main.shop != null and main.shop.visible, "shop node visible")
		10:
			# 用真实触摸点击第一行按钮（磁铁先重置为 1 级，价格 80）
			GlobalData.reset_progress()
			GlobalData.total_pearls = 100
			GlobalData.save_progress()
			var br: Rect2 = main.shop.button_rect(0)
			var ev := InputEventScreenTouch.new()
			ev.index = 0
			ev.pressed = true
			ev.position = main.shop.get_global_transform() * br.get_center()
			Input.parse_input_event(ev)
		11:
			check(GlobalData.shield_level == 2, "tap upgrade buys level 2 (got %d)" % GlobalData.shield_level)
			check(GlobalData.total_pearls == 50, "50 pearls left (%.0f)" % GlobalData.total_pearls)
		12:
			# 珍珠不足：再买一次（120）应该失败并红闪
			var br2: Rect2 = main.shop.button_rect(0)
			var ev2 := InputEventScreenTouch.new()
			ev2.index = 0
			ev2.pressed = true
			ev2.position = main.shop.get_global_transform() * br2.get_center()
			Input.parse_input_event(ev2)
		13:
			check(GlobalData.shield_level == 2, "insufficient pearls does not upgrade")
			check(float(main.shop._flash["shield"]) > 0.0, "row flashes red on failure")
		14:
			# 满级按钮状态
			GlobalData.total_pearls = 99999
			for i in range(6):
				GlobalData.try_upgrade("shield")
			check(main.shop.is_max_public("shield") if main.shop.has_method("is_max_public") else GlobalData.is_max("shield"),
				"shop reports max state")
			main.shop.close()
		15:
			check(main.state == "menu", "closing shop returns to menu (state=%s)" % main.state)
			# 游戏内天赋生效
			main._start_new()
			GlobalData.dash_level = 5
			main.dash_cd = 0.0
			main._dash()
			var expect := 0.55 * GlobalData.get_dash_distance() / 100.0
			check(absf(main.dash_timer - expect) < 0.02 and expect > 0.9, "lv5 dash lasts %.2fs (base 0.55)" % main.dash_timer)
		16:
			# 磁铁：把珍珠放到半径内，推进一帧后应该被拉近
			main._start_new()
			GlobalData.magnet_level = 5
			main.pickups.clear()
			main.pickups.append({"kind":"pearl","x":main.scroll_x + main.PLAYER_X + 120.0,
				"base_y":main.player_y, "y":main.player_y, "phase":0.0, "alive":true})
			var before: float = main.pickups[0].x
			main._apply_magnet(0.2)
			check(main.pickups[0].x < before, "magnet pulls pearls closer")
		17:
			# 血量显示用四段贴图，保证和 hp 同步
			check(main.heart_masks.size() == 3, "quarter heart textures built (%d)" % main.heart_masks.size())
			main.hp = 5.5
			check(absf(main._heart_fill(2) - 0.75) < 0.001, "hp 5.5 -> third heart 75%%")
		18:
			# 结算：一局跑完会加珍珠
			GlobalData.reset_progress()
			main._start_new()
			main.distance = 1500.0
			main.pearls = 10
			main.score = 50000
			var expect2 := GlobalData.calculate_pearls(1500.0, 10, 50000)
			main._die()
			check(main.run_payout == expect2, "run payout matches formula (%d vs %d)" % [main.run_payout, expect2])
			check(GlobalData.total_pearls == expect2, "payout added to wallet (%.0f)" % GlobalData.total_pearls)
		19:
			print("RESULT failures=", failures)
			GlobalData.reset_progress()
			done = true
			get_tree().quit(failures)
