extends Control

# =============================================================================
# ShopUI.gd —— 天赋商店面板（消耗层）
#
# 三个升级按钮：护盾时长 / 冲刺距离 / 珍珠磁铁
#   · 珍珠足够且未满级：扣珍珠、等级 +1、刷新 UI、写存档
#   · 珍珠不足：按钮红闪，并轻轻抖动提示
#   · 已满级：按钮变灰显示 MAX
#
# 交互同时支持鼠标与触摸（本工程全局关闭了“触摸转鼠标”，所以两种事件都收）
# =============================================================================

signal closed                       # 关闭面板
signal purchased(kind: String, level: int)
signal denied(kind: String)         # 珍珠不足

const ROW_ORDER := ["shield", "dash", "magnet"]
const PANEL := Rect2(150, 56, 980, 608)
const ROW_X := 190.0
const ROW_W := 900.0
const ROW_Y0 := 176.0
const ROW_H := 104.0
const ROW_GAP := 120.0
const BTN_W := 186.0
const BTN_H := 42.0
const CLOSE_RECT := Rect2(540, 566, 200, 50)

var font_regular: Font
var font_bold: Font
var _t: Callable = Callable()
var _flash := {}          # kind -> 剩余红闪时间
var _pulse := 0.0
var _btn_cache := {}

# ---------------------------------------------------------------- 初始化
func setup(regular: Font, bold: Font, translator: Callable) -> void:
	font_regular = regular
	font_bold = bold
	_t = translator
	for kind in ROW_ORDER:
		_flash[kind] = 0.0
	queue_redraw()

func open() -> void:
	visible = true
	for kind in ROW_ORDER:
		_flash[kind] = 0.0
	queue_redraw()

func close() -> void:
	visible = false
	closed.emit()

func _process(delta: float) -> void:
	if not visible:
		return
	_pulse += delta
	for kind in ROW_ORDER:
		_flash[kind] = maxf(0.0, float(_flash[kind]) - delta)
	queue_redraw()

# ---------------------------------------------------------------- 布局
func row_rect(index: int) -> Rect2:
	return Rect2(ROW_X, ROW_Y0 + float(index) * ROW_GAP, ROW_W, ROW_H)

func button_rect(index: int) -> Rect2:
	var r := row_rect(index)
	return Rect2(r.end.x - BTN_W - 24.0, r.position.y + 46.0, BTN_W, BTN_H)

# ---------------------------------------------------------------- 交互
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var pressed := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		pos = event.position
	if not pressed:
		return
	var local: Vector2 = get_global_transform().affine_inverse() * pos
	_handle_tap(local)

func _handle_tap(local: Vector2) -> void:
	for i in range(ROW_ORDER.size()):
		if button_rect(i).has_point(local):
			_try_buy(i)
			return
	if CLOSE_RECT.has_point(local):
		close()

func _try_buy(index: int) -> void:
	var kind: String = ROW_ORDER[index]
	var result := GlobalData.try_upgrade(kind)
	if result == "ok":
		purchased.emit(kind, GlobalData.get_level(kind))
	elif result == "poor":
		_flash[kind] = 0.45
		denied.emit(kind)
	# "max" 时按钮本来就是灰的，不做任何事

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	if not visible:
		return
	# 半透明遮罩
	draw_rect(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color(0.0, 0.04, 0.08, 0.62))
	_round(PANEL, Color8(3, 22, 36, 238), 28, Color8(87, 165, 157, 90), 1)
	_text(_tr("shop_title"), 1280.0 / 2.0, 100.0, 34, Color8(233, 248, 240), true, "center")
	_text(_tr("shop_sub"), 1280.0 / 2.0, 130.0, 13, Color8(143, 185, 183), false, "center")
	# 持有珍珠
	var chip := Rect2(PANEL.end.x - 250.0, 74.0, 210.0, 42.0)
	_round(chip, Color8(3, 20, 33, 210), 18, Color8(96, 205, 188, 60), 1)
	_text(_tr("shop_total"), chip.position.x + 18.0, chip.position.y + 13.0, 11, Color8(143, 185, 183), false)
	_text("%d" % GlobalData.total_pearls, chip.end.x - 18.0, chip.position.y + 11.0, 22, Color8(255, 210, 122), true, "right")

	for i in range(ROW_ORDER.size()):
		_draw_row(i)

	# 关闭按钮
	var by := 1.0 + 0.02 * sin(_pulse * 3.0)
	_round(CLOSE_RECT, Color8(28, 100, 102, 240), 14, Color8(126, 247, 218, 120), 1)
	_text(_tr("shop_back"), CLOSE_RECT.get_center().x, CLOSE_RECT.position.y + 14.0, 22,
		Color8(233, 248, 240), true, "center")

func _draw_row(index: int) -> void:
	var kind: String = ROW_ORDER[index]
	var info: Dictionary = GlobalData.SKILLS[kind]
	var r := row_rect(index)
	var level := GlobalData.get_level(kind)
	var maxed := GlobalData.is_max(kind)
	var flash := float(_flash[kind])
	var shake := sin(flash * 90.0) * 6.0 * flash
	var rr := Rect2(r.position + Vector2(shake, 0), r.size)

	var bg := Color8(9, 34, 48, 225)
	if flash > 0.0:
		bg = Color8(90, 24, 34, 235).lerp(Color8(9, 34, 48, 225), 1.0 - flash / 0.45)
	_round(rr, bg, 16, Color8(126, 247, 218, 90) if not maxed else Color8(120, 140, 145, 70), 1)

	# 名称
	_text(_tr(info["name_key"]), rr.position.x + 22.0, rr.position.y + 18.0, 22, Color8(233, 248, 240), true)
	# 等级
	var lv_text := "%s  %d / %d" % [_tr("shop_level"), level, GlobalData.MAX_LEVEL]
	_text(lv_text, rr.position.x + 22.0, rr.position.y + 48.0, 13, Color8(124, 247, 218), true)
	# 当前效果
	_text(_effect_text(kind, level), rr.position.x + 22.0, rr.position.y + 70.0, 13, Color8(143, 185, 183), false)

	# 价格
	var price := GlobalData.price_for(kind)
	if not maxed and price >= 0:
		var afford := GlobalData.total_pearls >= price
		_text("%d" % price, rr.end.x - 24.0, rr.position.y + 14.0, 20,
			Color8(255, 210, 122) if afford else Color8(255, 140, 150), true, "right")
		_text(_tr("shop_pearl_unit"), rr.end.x - 24.0, rr.position.y + 36.0, 11,
			Color8(143, 185, 183), false, "right")

	# 按钮
	var br := button_rect(index)
	if maxed:
		_round(br, Color8(40, 58, 66, 235), 12, Color8(120, 140, 145, 90), 1)
		_text(_tr("shop_max"), br.get_center().x, br.position.y + 9.0, 20, Color8(150, 168, 172), true, "center")
	elif flash > 0.0:
		_round(br, Color8(180, 45, 55, 240), 12, Color8(255, 120, 130, 200), 1)
		_text(_tr("shop_poor"), br.get_center().x, br.position.y + 9.0, 18, Color8(255, 220, 224), true, "center")
	else:
		var afford2 := GlobalData.total_pearls >= GlobalData.price_for(kind)
		_round(br, Color8(38, 135, 132, 245) if afford2 else Color8(26, 78, 84, 220), 12,
			Color8(126, 247, 218, 120), 1)
		_text(_tr("shop_upgrade"), br.get_center().x, br.position.y + 9.0, 20,
			Color8(233, 248, 240) if afford2 else Color8(150, 175, 178), true, "center")

func _effect_text(kind: String, level: int) -> String:
	var info: Dictionary = GlobalData.SKILLS[kind]
	var value: float = float(info["base"]) + float(info["per_level"]) * float(level - 1)
	match kind:
		"shield":
			return _tr("skill_shield_desc") % value
		"dash":
			return _tr("skill_dash_desc") % int(round(value))
		_:
			return _tr("skill_magnet_desc") % int(round(value))

# ---------------------------------------------------------------- 绘制工具
func _tr(key: String) -> String:
	if _t.is_valid():
		return str(_t.call(key))
	return key

func _round(r: Rect2, col: Color, radius: int, border: Color = Color(0, 0, 0, 0), width: int = 0) -> void:
	var key := "%d_%d_%d_%d" % [radius, col.to_rgba32(), border.to_rgba32(), width]
	var sb: StyleBoxFlat = _btn_cache.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = col
		sb.corner_radius_top_left = radius
		sb.corner_radius_top_right = radius
		sb.corner_radius_bottom_left = radius
		sb.corner_radius_bottom_right = radius
		if width > 0:
			sb.set_border_width_all(width)
			sb.border_color = border
		_btn_cache[key] = sb
	draw_style_box(sb, r)

func _text(value: String, x: float, y: float, size: int, col: Color, bold := false, align := "left") -> void:
	var f: Font = font_bold if bold else font_regular
	if f == null:
		f = ThemeDB.fallback_font
	var w := f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var px := x
	if align == "center":
		px = x - w / 2.0
	elif align == "right":
		px = x - w
	var py := y + f.get_ascent(size) * 0.6
	draw_string_outline(f, Vector2(px, py), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0.03, 0.06, 0.7))
	draw_string(f, Vector2(px, py), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
