extends Node2D

# Whale Drift — Godot 4.7 port of the original 2D infinite runner.
# All geometry uses the original 1280x720 design coordinates.
# The Java save backend is intentionally left untouched; this client keeps a
# local JSON mirror so it remains playable offline.

const W := 1280.0
const H := 720.0
const StringsEN = preload("res://scripts/Strings_en.gd")
const PLAYER_X := 330.0
const PLAY_TOP := 126.0
const PLAY_BOTTOM := 596.0
const PLAYER_MIN_Y := PLAY_TOP + 28.0
const PLAYER_MAX_Y := PLAY_BOTTOM - 28.0
const PX_PER_METER := 20.0
const BIOME_LENGTH := 550.0
const SPAWN_AHEAD := 1640.0
const BASE_SPEED := 300.0
const MAX_SPEED := 520.0
const SPEED_GAIN := 0.060
const PLAYER_ACCEL := 2350.0
const PLAYER_MAX_VY := 470.0
const PLAYER_DRAG := 7.5
const DASH_DURATION := 0.55
const DASH_COOLDOWN := 5.0
const HIT_INVULN := 1.7

# 鲸鱼身体主体基准尺寸（纹理实测，不含尾巴/鳍尖端）
# 实际碰撞箱 = 身体主体 × WHALE_SCALE(视觉缩小) × 当前难度 hit_scale
const WHALE_BODY_RX := 95.0
const WHALE_BODY_RY := 67.0
const WHALE_BODY_OX := 55.0
const WHALE_BODY_OY := 12.0
const WHALE_SCALE := 0.9
const PEARL_HIT_R := 24.0

const UI_TEXT := Color8(233, 248, 240)
const UI_MUTED := Color8(143, 185, 183)
const UI_DIM := Color8(91, 132, 136)
const UI_DARK := Color8(4, 22, 35)
const UI_ACCENT := Color8(124, 247, 218)
const UI_GOLD := Color8(255, 210, 122)
const UI_RED := Color8(255, 112, 128)
const UI_AMBER := Color8(255, 190, 100)
const UI_GREEN := Color8(112, 241, 172)

const BIOMES := [
	{"name": "Sunlit Reef", "en": "SUNLIT REEF", "tint": Color8(255, 244, 224), "accent": Color8(137, 255, 224), "mote": Color8(134, 255, 226), "sub": "Warm currents thread through the coral canyons."},
	{"name": "Twilight Canyon", "en": "TWILIGHT CANYON", "tint": Color8(218, 228, 255), "accent": Color8(126, 213, 255), "mote": Color8(158, 220, 255), "sub": "The light is leaving these waters."},
	{"name": "Abyssal Blue", "en": "ABYSSAL BLUE", "tint": Color8(177, 198, 244), "accent": Color8(115, 158, 255), "mote": Color8(128, 174, 255), "sub": "The deeper it gets, the quieter — and the more dangerous."},
	{"name": "Luminous Trench", "en": "LUMINOUS TRENCH", "tint": Color8(215, 182, 255), "accent": Color8(231, 146, 255), "mote": Color8(238, 157, 255), "sub": "Glowing creatures breathe between the rock walls."},
	{"name": "Aurora Current", "en": "AURORA CURRENT", "tint": Color8(183, 255, 240), "accent": Color8(119, 255, 203), "mote": Color8(139, 255, 211), "sub": "The current rolls like an aurora."},
	{"name": "Sunken Ruins", "en": "SUNKEN RUINS", "tint": Color8(255, 220, 188), "accent": Color8(255, 192, 121), "mote": Color8(255, 204, 137), "sub": "Who left a city at the bottom of the sea?"},
]

const DIFFICULTIES := [
	{"id":"drift","name":"Driftling","tag":"CASUAL","en":"DRIFT","desc":"Almost no pressure. Slow currents and sparse obstacles — for sightseeing, music, and learning the controls.","speed_mult":0.80,"ramp_mult":0.50,"max_speed_mult":0.92,"gap_min":1.85,"gap_max":2.60,"gate_gap":330,"unlock":18.0,"invuln_mult":1.45,"score_mult":0.80,"dash_cd_mult":0.85,"hit_scale":0.60,"weights":{"gate":16,"spike_top":9,"spike_bottom":9,"rock":24,"jelly":22,"urchin":20,"jelly_pair":0,"twin_rock":0,"urchin_swing":0}},
	{"id":"tide","name":"Tidewalker","tag":"EASY","en":"TIDE","desc":"Still forgiving, but the current and creatures begin to find their rhythm.","speed_mult":0.90,"ramp_mult":0.70,"max_speed_mult":0.98,"gap_min":1.55,"gap_max":2.20,"gate_gap":315,"unlock":15.0,"invuln_mult":1.30,"score_mult":0.90,"dash_cd_mult":0.92,"hit_scale":0.74,"weights":{"gate":20,"spike_top":12,"spike_bottom":12,"rock":20,"jelly":18,"urchin":18,"jelly_pair":0,"twin_rock":0,"urchin_swing":2}},
	{"id":"blue","name":"Blue Wanderer","tag":"NORMAL","en":"BLUE","desc":"The design baseline. Denser, faster currents, but every gap leaves room to breathe.","speed_mult":1.00,"ramp_mult":1.00,"max_speed_mult":1.04,"gap_min":1.22,"gap_max":1.78,"gate_gap":290,"unlock":11.0,"invuln_mult":1.00,"score_mult":1.00,"dash_cd_mult":1.00,"hit_scale":0.88,"weights":{"gate":24,"spike_top":14,"spike_bottom":14,"rock":15,"jelly":13,"urchin":10,"jelly_pair":7,"twin_rock":4,"urchin_swing":6}},
	{"id":"current","name":"Current Hunter","tag":"HARD","en":"CURRENT","desc":"Cross-currents close in: combos are more common and reaction windows shrink.","speed_mult":1.08,"ramp_mult":1.18,"max_speed_mult":1.12,"gap_min":1.02,"gap_max":1.50,"gate_gap":270,"unlock":9.0,"invuln_mult":0.85,"score_mult":1.15,"dash_cd_mult":1.05,"hit_scale":0.92,"weights":{"gate":22,"spike_top":13,"spike_bottom":13,"rock":11,"jelly":10,"urchin":8,"jelly_pair":9,"twin_rock":8,"urchin_swing":6}},
	{"id":"abyss","name":"Abyss Echo","tag":"NIGHTMARE","en":"ABYSS","desc":"The abyss stops whispering. Endless combos, tight gaps, fast currents — for seasoned divers.","speed_mult":1.16,"ramp_mult":1.35,"max_speed_mult":1.20,"gap_min":0.88,"gap_max":1.30,"gate_gap":252,"unlock":7.0,"invuln_mult":0.72,"score_mult":1.30,"dash_cd_mult":1.12,"hit_scale":0.95,"weights":{"gate":20,"spike_top":12,"spike_bottom":12,"rock":9,"jelly":9,"urchin":7,"jelly_pair":12,"twin_rock":10,"urchin_swing":9}},
	{"id":"extinction","name":"Trench Extinction","tag":"EXTREME","en":"EXTINCTION","desc":"For those who truly want to be swallowed by the trench. Razor-thin gaps, dense patterns, reactions measured in frames.","speed_mult":1.24,"ramp_mult":1.50,"max_speed_mult":1.28,"gap_min":0.72,"gap_max":1.08,"gate_gap":235,"unlock":5.5,"invuln_mult":0.62,"score_mult":1.50,"dash_cd_mult":1.25,"hit_scale":0.99,"weights":{"gate":18,"spike_top":10,"spike_bottom":10,"rock":8,"jelly":8,"urchin":6,"jelly_pair":14,"twin_rock":14,"urchin_swing":12}},
]

const RESOLUTIONS := [Vector2i(960,540), Vector2i(1280,720), Vector2i(1366,768), Vector2i(1600,900), Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(3840,2160)]
const FPS_OPTIONS := [30,60,90,120,144,165,240,0]
const SENS_VALUES := [0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6]
const VOL_VALUES := [0,10,20,30,40,50,60,70,80,90,100]
const DISPLAY_MODES := ["windowed","borderless","fullscreen"]
const SETTING_ROWS := ["difficulty","display_mode","resolution","fps_limit","sensitivity","volume","screen_shake","show_fps","language"]

var textures := {}
var whale_frames: Array[Texture2D] = []
var jelly_frames: Array[Texture2D] = []
var rock_frames: Array[Texture2D] = []
var spike_frames: Array[Texture2D] = []
var fish_frames: Array[Texture2D] = []
var coral_frames: Array[Texture2D] = []
var font_regular: Font
var font_bold: Font
var sfx := {}
var music: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

var settings := {
	"difficulty":"blue", "display_mode":"windowed", "resolution":Vector2i(1280,720),
	"fps_limit":60, "sensitivity":1.0, "volume":80, "screen_shake":true, "show_fps":false, "language":"en",
}
var save_data := {"bestDistance":0.0, "bestScore":0, "runs":0, "totalPearls":0, "checkpoint":null}
var state := "menu"
var selection := 0
var settings_selection := 0
var time := 0.0
var toast := ""
var toast_sub := ""
var toast_timer := 0.0
var toast_color := UI_ACCENT
var biome_banner := 0.0
var biome_name := ""
var biome_sub := ""
var run_seconds := 0.0
var distance := 0.0
var score := 0
var pearls := 0
var scroll_x := 0.0
var speed := BASE_SPEED
var biome_index := 0
var hearts := 3
var player_y := 361.0
var player_vy := 0.0
var invuln := 0.0
var dash_timer := 0.0
var dash_cd := 0.0
var dash_held := false
var pad_dash_held := false
var pad_nav_dir := Vector2i.ZERO
var pad_nav_timer := 0.0
var shield := false
var boost_timer := 0.0
var shake := 0.0
var flash := 0.0
var boost_flash := 0.0
var obstacles: Array = []
var pickups: Array = []
var particles: Array = []
var texts: Array = []
var decor: Array = []
var next_spawn := 0.0
var next_pickup := 0.0
var next_decor := 0.0
var rng := RandomNumberGenerator.new()
var ui_buttons: Array = []
var mouse_pos := Vector2.ZERO
var capture_path := ""
var capture_frames := -1
var capture_scene := ""
var capture_resize := Vector2i.ZERO
var capture_done := false
var fps_value := 0.0
var frame_count := 0
var checkpoint_saved := 0.0
var game_time := 0.0
var tutorial_timer := 0.0

func T(key: String) -> String:
	var table: Dictionary = StringsEN.TEXT if settings.get("language", "en") == "en" else WhaleStrings.TEXT
	return str(table.get(key, key))

func _biome_name(i: int) -> String:
	return T("b%d_name" % (i % BIOMES.size()))

func _biome_sub(i: int) -> String:
	return T("b%d_sub" % (i % BIOMES.size()))

func _diff_name() -> String:
	return T("d_%s_name" % _difficulty().id)

func _diff_tag() -> String:
	return T("d_%s_tag" % _difficulty().id)

func _diff_desc() -> String:
	return T("d_%s_desc" % _difficulty().id)

# ---------------------------------------------------------------------------
# setup / assets
# ---------------------------------------------------------------------------
func _ready() -> void:
	rng.randomize()
	_load_assets()
	_load_settings()
	_load_save()
	_apply_audio()
	_apply_window()
	_parse_capture_args()
	if capture_resize != Vector2i.ZERO:
		settings.resolution = capture_resize
		_apply_window()
	if capture_scene == "settings":
		state = "settings"
	elif capture_scene == "play":
		_start_new()
	elif capture_scene == "pause":
		_start_new()
		state = "paused"
	elif capture_scene == "gameover":
		_start_new()
		hearts = 0
		state = "gameover"
	elif capture_scene == "help":
		state = "help"
	elif capture_scene == "hazards":
		_start_new()
		state = "playing"
		_spawn_gate(PLAYER_X + 300.0)
	queue_redraw()

func _make_glow(px: int, col: Color) -> ImageTexture:
	# 生成径向渐变光晕纹理（中心亮、边缘透明）
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := float(px) * 0.5
	for y in range(px):
		for x in range(px):
			var d := Vector2(float(x) - c + 0.5, float(y) - c + 0.5).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * a))
	return ImageTexture.create_from_image(img)


func _load_assets() -> void:
	var base := "res://assets/"
	for n in ["ocean_bg","layer_far","layer_mid","canyon_top","canyon_bottom","vignette","glow_warm","glow_pearl","bubble_small","pearl","power_shield","power_boost","urchin","icon_heart","icon_dash","icon_save"]:
		var p: String = base + n + ".png"
		if not ResourceLoader.exists(p):
			p = base + n + ".webp"
		if ResourceLoader.exists(p):
			textures[n] = load(p)
	for i in range(6):
		var p := base + "whale_%d.png" % i
		if ResourceLoader.exists(p):
			whale_frames.append(load(p))
	for i in range(4):
		var p := base + "jelly_%d.png" % i
		if ResourceLoader.exists(p):
			jelly_frames.append(load(p))
	for i in range(3):
		rock_frames.append(load(base + "rock_%d.png" % i))
		var ctex: Texture2D = load(base + "coral_%d.png" % i)
		var cimg: Image = ctex.get_image()
		cimg.flip_y()
		textures["coral_top_%d" % i] = ImageTexture.create_from_image(cimg)
		spike_frames.append(load(base + "spike_%d.png" % i))
		fish_frames.append(load(base + "fish_%d.png" % i))
		coral_frames.append(load(base + "coral_%d.png" % i))
	var grad := Image.create(128, 1, false, Image.FORMAT_RGBA8)
	for x in range(128):
		var a := int(155.0 * (1.0 - float(x) / 127.0))
		grad.set_pixel(x, 0, Color8(1, 10, 18, a))
	textures["menu_shade"] = ImageTexture.create_from_image(grad)
	# glow_warm / glow_pearl 没有对应资源文件，这里用代码生成径向渐变光晕，
	# 避免 draw_texture_rect 收到 null 纹理（rp_texture is null）。
	if not textures.has("glow_warm"):
		textures["glow_warm"] = _make_glow(96, Color(1.0, 0.6, 0.45))
	if not textures.has("glow_pearl"):
		textures["glow_pearl"] = _make_glow(96, Color(1.0, 0.7, 0.9))
	# 打包字体：Web 平台不支持 SystemFont（浏览器无系统字体 API），
	# 必须使用项目内置字体，否则中文会变成方框并报 rp_texture 为空。
	var f_reg_path := "res://assets/fonts/NotoSansSC-Regular.otf"
	var f_bold_path := "res://assets/fonts/NotoSansSC-Bold.otf"
	if ResourceLoader.exists(f_reg_path):
		font_regular = load(f_reg_path)
	if ResourceLoader.exists(f_bold_path):
		font_bold = load(f_bold_path)
	if font_regular == null:
		# 兜底：仅桌面端可用系统字体
		var sys_regular := SystemFont.new()
		sys_regular.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans SC", "SimHei"])
		sys_regular.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		sys_regular.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		font_regular = sys_regular
	if font_bold == null:
		font_bold = font_regular
	for n in ["sfx_collect","sfx_dash","sfx_gameover","sfx_hit","sfx_power","sfx_save","sfx_ui"]:
		var p := "res://assets/%s.wav" % n
		if ResourceLoader.exists(p):
			sfx[n] = load(p)
	music = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/ambient.ogg"):
		music.stream = load("res://assets/ambient.ogg")
		if music.stream is AudioStreamOggVorbis:
			music.stream.loop = true
		add_child(music)
		music.play()
	for i in range(5):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func _load_settings() -> void:
	var f := FileAccess.open("user://whale_settings.json", FileAccess.READ)
	if f:
		var raw = JSON.parse_string(f.get_as_text())
		if raw is Dictionary:
			for k in settings.keys():
				if raw.has(k):
					settings[k] = raw[k]
			var res = settings.get("resolution", [1280,720])
			if res is Array and res.size() >= 2:
				settings["resolution"] = Vector2i(int(res[0]), int(res[1]))
	if Engine.has_method("set_max_fps"):
		Engine.max_fps = int(settings.fps_limit)

func _save_settings() -> void:
	var out := settings.duplicate()
	out["resolution"] = [settings.resolution.x, settings.resolution.y]
	var f := FileAccess.open("user://whale_settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(out, "  "))
	Engine.max_fps = int(settings.fps_limit)
	_apply_audio()
	_apply_window()

func _load_save() -> void:
	var f := FileAccess.open("user://whale_save.json", FileAccess.READ)
	if f:
		var raw = JSON.parse_string(f.get_as_text())
		if raw is Dictionary:
			save_data = raw
			return
	# one-time migration from the Python version, if present
	var appdata := OS.get_environment("LOCALAPPDATA")
	if appdata != "":
		var p := appdata + "\\WhaleDrift\\save_data\\save.json"
		if FileAccess.file_exists(p):
			var f2 := FileAccess.open(p, FileAccess.READ)
			if f2:
				var raw2 = JSON.parse_string(f2.get_as_text())
				if raw2 is Dictionary:
					save_data = raw2
					_save_save()

func _save_save() -> void:
	var f := FileAccess.open("user://whale_save.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_data, "  "))

func _apply_audio() -> void:
	var v := clampf(float(settings.volume) / 100.0, 0.0, 1.0)
	if music:
		music.volume_db = -60.0 if v <= 0.001 else linear_to_db(v * 0.55)
	for p in sfx_players:
		p.volume_db = -60.0 if v <= 0.001 else linear_to_db(v)

func _play_sfx(name: String, volume := 0.8) -> void:
	if not sfx.has(name):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx[name]
			p.volume_db = linear_to_db(clampf(float(settings.volume)/100.0,0.001,1.0) * volume)
			p.play()
			return

# ---------------------------------------------------------------------------
# window / input
# ---------------------------------------------------------------------------
func _apply_window() -> void:
	if DisplayServer.get_name() != "headless":
		var fps := int(settings.fps_limit)
		var vs := DisplayServer.VSYNC_DISABLED if (fps <= 0 or fps >= 120) else DisplayServer.VSYNC_ENABLED
		DisplayServer.window_set_vsync_mode(vs)
	if settings.display_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif settings.display_mode == "borderless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(settings.resolution))
		get_window().size = Vector2i(settings.resolution)
		# Re-assert content scaling after a live resolution change so fonts and
		# HUD geometry are recalculated instead of staying at the old scale.
		var win := get_window()
		win.content_scale_size = Vector2i(1280, 720)
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_pos = get_viewport().get_mouse_position()
		_handle_click()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: int = int(event.keycode)
		if key == 0:
			key = event.physical_keycode
		_handle_key(key)
	elif event is InputEventJoypadButton and event.pressed:
		_handle_pad_button(event.button_index)

func _pad_nav_vector() -> Vector2i:
	var vx := 0
	var vy := 0
	var x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(x) > 0.40:
		vx = 1 if x > 0.0 else -1
	if absf(y) > 0.40:
		vy = 1 if y > 0.0 else -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT): vx = -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT): vx = 1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP): vy = -1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN): vy = 1
	return Vector2i(vx, vy)

func _pad_nav_step(dir: Vector2i) -> void:
	if state == "settings":
		if dir.x != 0:
			_handle_key(KEY_RIGHT if dir.x > 0 else KEY_LEFT)
		elif dir.y != 0:
			_handle_key(KEY_DOWN if dir.y > 0 else KEY_UP)
	elif state in ["menu", "paused", "gameover"]:
		if dir.y != 0:
			_handle_key(KEY_DOWN if dir.y > 0 else KEY_UP)
	elif state == "playing":
		pass

func _update_pad_nav(delta: float) -> void:
	if not (state in ["menu", "settings", "help", "paused", "gameover"]):
		pad_nav_dir = Vector2i.ZERO
		pad_nav_timer = 0.0
		return
	var dir := _pad_nav_vector()
	if dir == Vector2i.ZERO:
		pad_nav_dir = Vector2i.ZERO
		pad_nav_timer = 0.0
		return
	if dir != pad_nav_dir:
		pad_nav_dir = dir
		pad_nav_timer = 0.34
		_pad_nav_step(dir)
	else:
		pad_nav_timer -= delta
		if pad_nav_timer <= 0.0:
			pad_nav_timer = 0.12
			_pad_nav_step(dir)

func _pad_dash_pressed() -> bool:
	return Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_joy_button_pressed(0, JOY_BUTTON_X) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.6

func _handle_pad_button(button: int) -> void:
	if button == JOY_BUTTON_START:
		if state == "playing" or state == "paused":
			_handle_key(KEY_ESCAPE)
		elif state == "menu":
			_handle_key(KEY_ENTER)
		return
	if button == JOY_BUTTON_B:
		if state in ["settings", "help", "paused", "gameover"]:
			_handle_key(KEY_ESCAPE)
		return
	if button in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER]:
		if state == "playing":
			_dash()
		else:
			_handle_key(KEY_ENTER)

func _handle_key(key: int) -> void:
	if key == KEY_L:
		settings.language = "zh" if str(settings.get("language", "en")) == "en" else "en"
		if state == "playing" or state == "dying":
			biome_name = _biome_name(biome_index)
			biome_sub = _biome_sub(biome_index)
		toast = ""
		toast_sub = ""
		_save_settings()
		queue_redraw()
		return
	if key == KEY_F11:
		settings.display_mode = "windowed" if settings.display_mode == "fullscreen" else "fullscreen"
		_apply_window()
		return
	if key == KEY_M:
		settings.volume = 0 if int(settings.volume) > 0 else 80
		_apply_audio()
		return
	if state == "settings":
		if key in [KEY_ESCAPE, KEY_BACKSPACE]:
			state = "menu"; selection = 1
		elif key in [KEY_UP, KEY_W]:
			settings_selection = (settings_selection - 1 + SETTING_ROWS.size()) % SETTING_ROWS.size()
			_play_sfx("sfx_ui",0.5)
		elif key in [KEY_DOWN, KEY_S]:
			settings_selection = (settings_selection + 1) % SETTING_ROWS.size()
			_play_sfx("sfx_ui",0.5)
		elif key in [KEY_LEFT, KEY_A]:
			_cycle_setting(settings_selection, -1)
		elif key in [KEY_RIGHT, KEY_D, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_cycle_setting(settings_selection, 1)
		elif key == KEY_R:
			_reset_settings()
		return
	if state == "menu":
		if key in [KEY_UP, KEY_W]:
			selection = (selection - 1 + 5) % 5
			_play_sfx("sfx_ui",0.4)
		elif key in [KEY_DOWN, KEY_S]:
			selection = (selection + 1) % 5
			_play_sfx("sfx_ui",0.4)
		elif key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_menu_activate(selection)
		elif key == KEY_ESCAPE:
			get_tree().quit()
	elif state == "help":
		if key in [KEY_ESCAPE, KEY_BACKSPACE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			state = "menu"; selection = 2
	elif state == "playing":
		if key in [KEY_ESCAPE, KEY_P]:
			state = "paused"; selection = 0; _play_sfx("sfx_ui",0.5)
		elif key in [KEY_SPACE, KEY_SHIFT]:
			_dash()
	elif state == "paused":
		if key in [KEY_ESCAPE, KEY_P]:
			state = "playing"
		elif key in [KEY_UP, KEY_W]:
			selection = (selection - 1 + 3) % 3
			_play_sfx("sfx_ui",0.4)
		elif key in [KEY_DOWN, KEY_S]:
			selection = (selection + 1) % 3
			_play_sfx("sfx_ui",0.4)
		elif key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_pause_activate()
	elif state == "gameover":
		if key in [KEY_UP, KEY_W]:
			selection = (selection - 1 + 2) % 2
			_play_sfx("sfx_ui",0.4)
		elif key in [KEY_DOWN, KEY_S]:
			selection = (selection + 1) % 2
			_play_sfx("sfx_ui",0.4)
		elif key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_gameover_activate()
		elif key == KEY_ESCAPE:
			state = "menu"; selection = 0
	queue_redraw()

func _handle_click() -> void:
	for b in ui_buttons:
		if b.rect.has_point(mouse_pos):
			var id = b.id
			if state == "menu":
				_menu_activate(id)
			elif state == "paused":
				selection = id; _pause_activate()
			elif state == "gameover":
				selection = id; _gameover_activate()
			elif state == "settings":
				if id is int:
					if id == -1:
						state = "menu"; selection = 1
					elif id == -2:
						_reset_settings()
					elif id >= 100:
						_cycle_setting(id - 100, -1)
					else:
						_cycle_setting(id, 1)
			elif state == "help":
				state = "menu"; selection = 2
			return
	if state == "settings":
		# clicking the rows selects them
		for i in range(SETTING_ROWS.size()):
			var r := Rect2(174, 148 + i * 42, 932, 38)
			if r.has_point(mouse_pos):
				settings_selection = i
				return
	if state == "help":
		state = "menu"; selection = 2

func _menu_activate(id: int) -> void:
	_play_sfx("sfx_ui")
	match id:
		0: _start_new()
		1: _continue_run()
		2: state = "help"; selection = 0
		3: state = "settings"; settings_selection = 0
		4: get_tree().quit()

func _pause_activate() -> void:
	if selection == 0:
		state = "playing"
	elif selection == 1:
		_start_new()
	else:
		state = "menu"; selection = 0

func _gameover_activate() -> void:
	if selection == 0:
		_start_new()
	else:
		state = "menu"; selection = 0

# ---------------------------------------------------------------------------
# settings
# ---------------------------------------------------------------------------
func _difficulty() -> Dictionary:
	for d in DIFFICULTIES:
		if d.id == settings.difficulty:
			return d
	return DIFFICULTIES[2]

func _value_text(key: String) -> String:
	match key:
		"difficulty":
			return "%s · %s" % [_diff_name(), _diff_tag()]
		"display_mode":
			return {"windowed":T("set_windowed"),"borderless":T("set_borderless"),"fullscreen":T("set_fullscreen")}.get(settings.display_mode,T("set_windowed"))
		"resolution": return "%d × %d" % [settings.resolution.x, settings.resolution.y]
		"fps_limit": return T("set_unlimited") if int(settings.fps_limit) <= 0 else "%d FPS" % int(settings.fps_limit)
		"sensitivity": return "%d%%" % int(round(float(settings.sensitivity) * 100.0))
		"volume": return "%d%%" % int(settings.volume)
		"screen_shake": return T("set_on") if settings.screen_shake else T("set_off")
		"show_fps": return T("set_show") if settings.show_fps else T("set_hide")
		"language": return T("set_zh") if str(settings.get("language","en")) == "zh" else T("set_en")
	return ""

func _desc(key: String) -> String:
	match key:
		"difficulty":
			return T("set_d_difficulty") % [_diff_desc(), _difficulty().score_mult, _difficulty().dash_cd_mult]
		"display_mode":
			return T("set_d_display")
		"resolution":
			return T("set_d_res")
		"fps_limit":
			return T("set_d_fps")
		"sensitivity":
			return T("set_d_sens")
		"volume":
			return T("set_d_vol")
		"screen_shake":
			return T("set_d_shake")
		"show_fps":
			return T("set_d_showfps")
		"language":
			return T("set_d_language")
	return ""

func _cycle_setting(index: int, delta: int) -> void:
	var key: String = SETTING_ROWS[index]
	var step := 1 if delta >= 0 else -1
	match key:
		"difficulty":
			var ids := []
			for d in DIFFICULTIES: ids.append(d.id)
			var i := ids.find(settings.difficulty)
			settings.difficulty = ids[(i + step + ids.size()) % ids.size()]
		"display_mode":
			var i := DISPLAY_MODES.find(settings.display_mode)
			settings.display_mode = DISPLAY_MODES[(i + step + 3) % 3]
		"resolution":
			var i := RESOLUTIONS.find(settings.resolution)
			settings.resolution = RESOLUTIONS[(i + step + RESOLUTIONS.size()) % RESOLUTIONS.size()]
		"fps_limit":
			var i := FPS_OPTIONS.find(int(settings.fps_limit))
			settings.fps_limit = FPS_OPTIONS[(i + step + FPS_OPTIONS.size()) % FPS_OPTIONS.size()]
		"sensitivity":
			var i := SENS_VALUES.find(float(settings.sensitivity))
			settings.sensitivity = SENS_VALUES[(i + step + SENS_VALUES.size()) % SENS_VALUES.size()]
		"volume":
			var i := VOL_VALUES.find(int(settings.volume))
			settings.volume = VOL_VALUES[(i + step + VOL_VALUES.size()) % VOL_VALUES.size()]
		"screen_shake": settings.screen_shake = not settings.screen_shake
		"show_fps": settings.show_fps = not settings.show_fps
		"language":
			settings.language = "zh" if str(settings.get("language","en")) == "en" else "en"
	_save_settings()
	_play_sfx("sfx_ui",0.5)
	queue_redraw()

func _reset_settings() -> void:
	settings = {"difficulty":"blue","display_mode":"windowed","resolution":Vector2i(1280,720),"fps_limit":60,"sensitivity":1.0,"volume":80,"screen_shake":true,"show_fps":false,"language":"en"}
	_save_settings(); queue_redraw()

# ---------------------------------------------------------------------------
# run lifecycle
# ---------------------------------------------------------------------------
func _start_new() -> void:
	state = "playing"
	scroll_x = 0.0
	distance = 0.0
	score = 0
	pearls = 0
	hearts = 3
	player_y = (PLAY_TOP + PLAY_BOTTOM) / 2.0
	player_vy = 0.0
	invuln = 1.2
	dash_timer = 0.0
	dash_cd = 0.0
	dash_held = false
	pad_dash_held = false
	pad_nav_dir = Vector2i.ZERO
	pad_nav_timer = 0.0
	shield = false
	boost_timer = 0.0
	shake = 0.0
	flash = 0.0
	boost_flash = 0.0
	obstacles.clear(); pickups.clear(); particles.clear(); texts.clear(); decor.clear()
	biome_index = 0
	run_seconds = 0.0
	next_spawn = SPAWN_AHEAD + 580.0
	next_pickup = SPAWN_AHEAD + 240.0
	next_decor = 260.0
	checkpoint_saved = 0.0
	toast = ""; toast_sub = ""; toast_timer = 0.0
	biome_name = _biome_name(0); biome_sub = _biome_sub(0); biome_banner = 2.8
	_seed_decor()
	_play_sfx("sfx_ui",0.5)

func _continue_run() -> void:
	var cp = save_data.get("checkpoint")
	if not (cp is Dictionary):
		return
	_start_new()
	state = "playing"
	distance = maxf(0.0, float(cp.get("distance",0)))
	scroll_x = distance * PX_PER_METER
	pearls = maxi(0, int(cp.get("pearls",0)))
	hearts = maxi(1, int(cp.get("hearts",3)))
	var yn := clampf(float(cp.get("yNorm",0.5)),0.0,1.0)
	player_y = lerpf(PLAY_TOP + 60, PLAY_BOTTOM - 60, yn)
	next_spawn = scroll_x + SPAWN_AHEAD + 580
	next_pickup = scroll_x + SPAWN_AHEAD + 240
	invuln = 1.4
	biome_index = int(distance / BIOME_LENGTH) % BIOMES.size()
	biome_name = _biome_name(biome_index); biome_sub = _biome_sub(biome_index); biome_banner = 0.0
	toast = T("hud_continue"); toast_sub = T("hud_continue_sub") % [distance, _diff_name()]
	toast_timer = 3.2; toast_color = UI_ACCENT

func _save_checkpoint(reason: String) -> void:
	if state != "playing" or hearts <= 0:
		return
	save_data["checkpoint"] = {
		"distance": distance, "yNorm": clampf((player_y - PLAY_TOP) / (PLAY_BOTTOM - PLAY_TOP),0,1),
		"score": score, "pearls": pearls, "hearts": hearts, "biome": biome_index,
		"difficulty": settings.difficulty,
	}
	_save_save()
	toast = T("hud_checkpoint"); toast_sub = T("hud_checkpoint_sub") % distance
	toast_timer = 2.0; toast_color = UI_GREEN
	_play_sfx("sfx_save",0.6)

func _die() -> void:
	if state != "playing" and state != "dying": return
	state = "gameover"; selection = 0
	save_data["runs"] = int(save_data.get("runs",0)) + 1
	save_data["totalPearls"] = int(save_data.get("totalPearls",0)) + pearls
	var best := float(save_data.get("bestDistance",0))
	if distance > best:
		save_data["bestDistance"] = distance
		save_data["bestScore"] = maxi(int(save_data.get("bestScore",0)), score)
		save_data["checkpoint"] = null
	_save_save()
	_play_sfx("sfx_gameover",0.9)
	flash = 0.7
	queue_redraw()

# ---------------------------------------------------------------------------
# gameplay update
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	time += delta
	game_time += delta
	frame_count += 1
	if fps_value <= 0: fps_value = 1.0/maxf(delta,0.0001)
	else: fps_value = fps_value * 0.92 + (1.0/maxf(delta,0.0001)) * 0.08
	if state == "playing" or state == "dying":
		_tick_game(delta)
	elif state == "menu" or state == "help" or state == "settings":
		pass
	_update_pad_nav(delta)
	if toast_timer > 0: toast_timer = maxf(0.0, toast_timer - delta)
	if biome_banner > 0: biome_banner = maxf(0.0, biome_banner - delta)
	if capture_frames >= 0 and frame_count >= capture_frames and not capture_done:
		capture_done = true
		_capture_and_quit()
	queue_redraw()

func _tick_game(delta: float) -> void:
	run_seconds += delta
	var diff := _difficulty()
	var target_speed := minf(BASE_SPEED * float(diff.speed_mult) + distance * SPEED_GAIN * float(diff.ramp_mult), MAX_SPEED * float(diff.max_speed_mult))
	if state == "dying":
		target_speed *= 0.5
	if dash_timer > 0:
		target_speed *= 1.75
		speed = maxf(speed, target_speed)
	var accel := PLAYER_ACCEL * float(settings.sensitivity)
	var maxvy := PLAYER_MAX_VY * float(settings.sensitivity)
	var dash_key := Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SPACE)
	if state == "playing" and dash_key and not dash_held and dash_cd <= 0:
		_dash()
	dash_held = dash_key
	var pad_dash := _pad_dash_pressed()
	if state == "playing" and pad_dash and not pad_dash_held and dash_cd <= 0:
		_dash()
	pad_dash_held = pad_dash
	var pad_up := Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) < -0.35
	var pad_down := Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) > 0.35
	var up := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or pad_up
	var down := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or pad_down
	if up and not down:
		player_vy = maxf(-maxvy, player_vy - accel*delta)
	elif down and not up:
		player_vy = minf(maxvy, player_vy + accel*delta)
	else:
		player_vy = move_toward(player_vy, 0.0, PLAYER_DRAG * maxvy * delta)
	player_y = clampf(player_y + player_vy*delta, PLAYER_MIN_Y, PLAYER_MAX_Y)
	speed = lerpf(speed, target_speed, clampf(delta*1.5,0,1))
	scroll_x += speed * delta
	distance = scroll_x / PX_PER_METER
	score = int((distance + pearls * 80.0) * float(diff.score_mult))
	if invuln > 0: invuln = maxf(0.0, invuln-delta)
	if boost_timer > 0: boost_timer = maxf(0.0, boost_timer-delta)
	if dash_timer > 0: dash_timer = maxf(0.0, dash_timer-delta)
	if dash_timer > 0.0:
		invuln = maxf(invuln, dash_timer + 0.2)
	if dash_cd > 0: dash_cd = maxf(0.0, dash_cd-delta)
	if flash > 0: flash = maxf(0.0, flash-delta)
	if boost_flash > 0: boost_flash = maxf(0.0, boost_flash-delta)
	if shake > 0: shake = maxf(0.0, shake-delta*2.6)
	var ni := int(distance / BIOME_LENGTH) % BIOMES.size()
	if ni != biome_index:
		biome_index = ni
		biome_name = _biome_name(biome_index)
		biome_sub = _biome_sub(biome_index)
		biome_banner = 2.8
		_play_sfx("sfx_power",0.5)
	_spawn_ahead()
	_update_objects(delta)
	_check_collisions()
	if run_seconds - checkpoint_saved >= 5.0 and hearts > 0:
		checkpoint_saved = run_seconds
		_save_checkpoint("tick")

func _spawn_ahead() -> void:
	while next_spawn < scroll_x + SPAWN_AHEAD:
		_spawn_pattern(next_spawn)
		var diff := _difficulty()
		var gap := randf_range(float(diff.gap_min), float(diff.gap_max))
		next_spawn += gap * speed
	while next_pickup < scroll_x + SPAWN_AHEAD + 600:
		_spawn_pearl_line(next_pickup)
		next_pickup += randf_range(280, 520)
	while next_decor < scroll_x + SPAWN_AHEAD + 600:
		_spawn_decor(next_decor)
		next_decor += randf_range(260, 520)

func _spawn_pattern(x: float) -> void:
	var diff := _difficulty()
	var vertical := run_seconds >= float(diff.unlock)
	if not vertical:
		var kinds := ["rock","jelly","urchin"]
		var kind: String = kinds[rng.randi_range(0,2)]
		_spawn_simple(kind, x)
		return
	var weights: Dictionary = diff.weights
	var total := 0.0
	for k in weights: total += float(weights[k])
	var pick := rng.randf() * total
	var kind := "rock"
	for k in weights:
		pick -= float(weights[k])
		if pick <= 0:
			kind = k
			break
	match kind:
		"gate": _spawn_gate(x)
		"spike_top": _spawn_spike(x, "top")
		"spike_bottom": _spawn_spike(x, "bottom")
		"jelly_pair":
			_spawn_jelly(x, 260.0, 1.0)
			_spawn_jelly(x + 190.0, 260.0, 1.4)
		"twin_rock":
			_spawn_rock(x, PLAY_TOP + 70.0)
			_spawn_rock(x, PLAY_BOTTOM - 70.0)
		"urchin_swing": _spawn_urchin(x, true)
		_:
			_spawn_simple(kind, x)

func _spawn_simple(kind: String, x: float) -> void:
	if kind == "rock":
		_spawn_rock(x, randf_range(PLAY_TOP+80, PLAY_BOTTOM-80))
	elif kind == "jelly":
		_spawn_jelly(x, randf_range(PLAY_TOP+90, PLAY_BOTTOM-90), randf_range(0.8,1.8))
	else:
		_spawn_urchin(x, false)

func _spawn_spike(x: float, side: String) -> void:
	var length := rng.randf_range(220,330)
	var width := rng.randf_range(188,220)
	var idx := rng.randi_range(0,2)
	var tex: Texture2D = spike_frames[idx]
	var draw_y := PLAY_TOP - 58.0 if side == "top" else PLAY_BOTTOM + 58.0 - length
	obstacles.append({"kind":"spike","x":x,"side":side,"w":width,"h":length,"draw_y":draw_y,"tex":tex,"used":false})

func _spawn_gate(x: float) -> void:
	var diff := _difficulty()
	var gap := rng.randf_range(float(diff.gate_gap), float(diff.gate_gap)+45.0)
	var top := rng.randf_range(PLAY_TOP+58, PLAY_BOTTOM-58-gap)
	var bottom := top + gap
	var width := rng.randf_range(185,216)
	var top_len := top - (PLAY_TOP-58)
	var bot_len := (PLAY_BOTTOM+58) - bottom
	var top_idx := rng.randi_range(0,2)
	var bot_idx := rng.randi_range(0,2)
	obstacles.append({"kind":"gate","x":x,"w":width,"gap_top":top,"gap_bottom":bottom,
		"top_len":maxf(110,top_len),"bot_len":maxf(110,bot_len),
		"top_tex":spike_frames[top_idx], "bot_tex":spike_frames[bot_idx],
		"top_y":PLAY_TOP-58.0, "bot_y":PLAY_BOTTOM+58.0-bot_len, "used":false})
	for i in range(5):
		pickups.append({"kind":"pearl","x":x-72+i*36,"base_y":top+gap/2+sin(i*1.2)*14,"phase":i*0.4,"alive":true})

func _spawn_rock(x: float, y: float) -> void:
	obstacles.append({"kind":"rock","x":x,"y":y,"w":204.0,"h":168.0,"tex":rock_frames[rng.randi_range(0,2)],"used":false})

func _spawn_jelly(x: float, y: float, speed: float) -> void:
	obstacles.append({"kind":"jelly","x":x,"y":y,"base_y":y,"w":132.0,"h":171.0,
		"amp":rng.randf_range(8,28),"speed":speed,"phase":rng.randf_range(0,TAU),"used":false})

func _spawn_urchin(x: float, swing: bool) -> void:
	obstacles.append({"kind":"urchin","x":x,"y":rng.randf_range(PLAY_TOP+90,PLAY_BOTTOM-90),
		"w":104.0,"h":104.0,"base_y":0.0,"amp":55.0 if swing else 0.0,"speed":1.4,
		"tex":textures.get("urchin"),"phase":rng.randf_range(0,TAU),"rot":0.0,"used":false})
	if swing:
		obstacles[-1]["base_y"] = obstacles[-1].y

func _spawn_pearl_line(x: float) -> void:
	var y := randf_range(PLAY_TOP+90, PLAY_BOTTOM-90)
	var n := rng.randi_range(3, 6)
	# At most one power-up per line; its position and type are random.
	var power_i := -1
	var power_kind := "pearl"
	if rng.randf() < 0.16:
		power_i = rng.randi_range(0, n - 1)
		power_kind = "shield" if rng.randf() < 0.5 else "boost"
	for i in range(n):
		var kind: String = power_kind if i == power_i else "pearl"
		pickups.append({"kind":kind,"x":x+i*38,"base_y":y+sin(i*0.9)*12,"phase":i*0.35,"alive":true})

func _spawn_decor(x: float) -> void:
	var side := "bottom" if rng.randf() < 0.5 else "top"
	var y := PLAY_BOTTOM - 4.0 if side == "bottom" else PLAY_TOP + 4.0
	var ci := rng.randi_range(0,2)
	var tex: Texture2D = textures.get("coral_top_%d" % ci, coral_frames[ci]) if side == "top" else coral_frames[ci]
	decor.append({"x":x,"y":y,"tex":tex,"side":side,"phase":rng.randf_range(0,TAU)})

func _seed_decor() -> void:
	for i in range(6): _spawn_decor(160 + i*380)

func _update_objects(delta: float) -> void:
	for o in obstacles:
		if o.kind == "jelly":
			o.y = o.base_y + sin(game_time*o.speed + o.phase)*o.amp
		elif o.kind == "urchin":
			if o.amp > 0:
				o.y = o.base_y + sin(game_time*o.speed + o.phase)*o.amp
			o.rot += delta*120.0
	for p in pickups: p["y"] = p.base_y + sin(game_time*2.2 + p.phase)*7.0
	for d in decor: d["sway"] = sin(game_time*0.8 + d.phase)*2.0
	obstacles = obstacles.filter(func(o): return o.x - scroll_x > -420)
	pickups = pickups.filter(func(p): return p.alive and p.x - scroll_x > -160)
	decor = decor.filter(func(d): return d.x - scroll_x > -220)
	for i in range(particles.size()-1, -1, -1):
		var p = particles[i]
		p.life -= delta
		p.x += (p.vx - speed*0.18)*delta
		p.y += p.vy*delta
		if p.kind == "spark": p.vy += 110*delta
		p.size += p.get("grow",0.0)*delta
		if p.life <= 0: particles.remove_at(i)
	for i in range(texts.size()-1,-1,-1):
		texts[i].life -= delta
		texts[i].y -= 38*delta
		if texts[i].life <= 0: texts.remove_at(i)

# ---------------------------------------------------------------------------
# collisions
# ---------------------------------------------------------------------------
func _check_collisions() -> void:
	if state != "playing":
		return
	# 障碍物碰撞：无敌/冲刺期间不判定受伤
	if invuln <= 0 and dash_timer <= 0:
		for o in obstacles:
			if o.used: continue
			if absf(o.x - scroll_x - PLAYER_X) > 260: continue
			if _hit_obstacle(o):
				o.used = true
				_hit_player()
				break
	# 拾取：任何时刻都可捡（无敌/冲刺期间也能捡珍珠与道具）
	for p in pickups:
		if not p.alive: continue
		var dx: float = (p.x - scroll_x) - _player_hit_cx()
		var dy: float = p.y - _player_hit_cy()
		var prx := _player_hit_rx() + PEARL_HIT_R
		var pry := _player_hit_ry() + PEARL_HIT_R
		if (dx*dx)/(prx*prx) + (dy*dy)/(pry*pry) < 1.0:
			_collect(p)

func _hit_scale() -> float:
	return float(_difficulty().get("hit_scale", 0.88))

func _player_hit_rx() -> float:
	return WHALE_BODY_RX * WHALE_SCALE * _hit_scale()

func _player_hit_ry() -> float:
	return WHALE_BODY_RY * WHALE_SCALE * _hit_scale()

func _player_hit_cx() -> float:
	return PLAYER_X + WHALE_BODY_OX * WHALE_SCALE * _hit_scale()

func _player_hit_cy() -> float:
	return player_y + WHALE_BODY_OY * WHALE_SCALE * _hit_scale()

func _hit_obstacle(o: Dictionary) -> bool:
	var sx: float = o.x - scroll_x
	var cx := _player_hit_cx()
	var cy := _player_hit_cy()
	var hrx := _player_hit_rx()
	var hry := _player_hit_ry()
	if o.kind == "urchin":
		var dx: float = sx - cx
		var dy: float = o.y - cy
		var rx := 31.0 + hrx
		var ry := 31.0 + hry
		return (dx*dx)/(rx*rx) + (dy*dy)/(ry*ry) < 1.0
	if o.kind == "rock":
		var nx: float = (sx - cx) / (72.0 + hrx)
		var ny: float = (o.y - cy) / (48.0 + hry)
		return nx*nx + ny*ny < 1.0
	if o.kind == "jelly":
		var nx: float = (sx - cx) / (48.0 + hrx)
		var ny: float = (o.y - 28.0 - cy) / (45.0 + hry)
		return nx*nx + ny*ny < 1.0
	if o.kind == "spike":
		var poly := _spike_polygon(o, sx)
		return _ellipse_hits_poly(Vector2(cx, cy), hrx, hry, poly)
	if o.kind == "gate":
		var top := _gate_top_poly(o, sx)
		var bot := _gate_bottom_poly(o, sx)
		return _ellipse_hits_poly(Vector2(cx,cy), hrx, hry, top) or _ellipse_hits_poly(Vector2(cx,cy), hrx, hry, bot)
	return false

func _spike_polygon(o: Dictionary, sx: float) -> PackedVector2Array:
	var top: bool = o.side == "top"
	var y0: float = o.draw_y
	var y1: float = o.draw_y + o.h
	var base_y := y0 if top else y1
	var tip_y := y1 if top else y0
	var base_half: float = o.w * 0.34
	var tip_half: float = o.w * 0.075
	return PackedVector2Array([
		Vector2(sx-base_half, base_y), Vector2(sx+base_half, base_y),
		Vector2(sx+tip_half, tip_y), Vector2(sx-tip_half, tip_y)
	])

func _gate_top_poly(o: Dictionary, sx: float) -> PackedVector2Array:
	var y0: float = o.top_y
	var y1: float = o.top_y + o.top_len
	var bh: float = o.w * 0.34
	var th: float = o.w * 0.075
	return PackedVector2Array([Vector2(sx-bh,y0),Vector2(sx+bh,y0),Vector2(sx+th,y1),Vector2(sx-th,y1)])

func _gate_bottom_poly(o: Dictionary, sx: float) -> PackedVector2Array:
	var y0: float = o.bot_y + o.bot_len
	var y1: float = o.bot_y
	var bh: float = o.w * 0.34
	var th: float = o.w * 0.075
	return PackedVector2Array([Vector2(sx-bh,y0),Vector2(sx+bh,y0),Vector2(sx+th,y1),Vector2(sx-th,y1)])

func _ellipse_hits_poly(center: Vector2, rx: float, ry: float, poly: PackedVector2Array) -> bool:
	# 在鲸鱼碰撞椭圆边缘采样，检测是否与障碍物多边形相交
	for i in range(16):
		var a := TAU * float(i) / 16.0
		var p := center + Vector2(cos(a)*rx, sin(a)*ry)
		if Geometry2D.is_point_in_polygon(p, poly):
			return true
	return Geometry2D.is_point_in_polygon(center, poly)

func _hit_player() -> void:
	if invuln > 0 or dash_timer > 0: return
	if shield:
		shield = false
		invuln = 1.0
		flash = 0.35
		_play_sfx("sfx_hit",0.8)
		return
	hearts -= 1
	invuln = 1.7 * float(_difficulty().invuln_mult)
	flash = 0.8
	shake = 1.0
	_play_sfx("sfx_hit",0.9)
	if hearts <= 0:
		_die()

func _collect(p: Dictionary) -> void:
	p.alive = false
	if p.kind == "pearl":
		pearls += 1
		_play_sfx("sfx_collect",0.45)
		texts.append({"text":T("hud_pearl_pop"),"x":p.x-scroll_x,"y":p.y-20,"life":1.0,"max_life":1.0,"color":UI_GOLD,"size":20})
	elif p.kind == "shield":
		shield = true
		_play_sfx("sfx_power",0.8)
		toast = T("hud_shield_toast"); toast_sub = T("hud_shield_sub"); toast_timer = 2.0; toast_color = UI_ACCENT
	elif p.kind == "boost":
		boost_timer = 5.0
		boost_flash = 1.0
		_play_sfx("sfx_power",0.8)
		toast = T("hud_boost_toast"); toast_sub = T("hud_boost_sub"); toast_timer = 2.0; toast_color = UI_GOLD

func _dash() -> void:
	if state != "playing" or dash_cd > 0: return
	dash_timer = DASH_DURATION
	dash_cd = DASH_COOLDOWN * float(_difficulty().dash_cd_mult)
	invuln = maxf(invuln, DASH_DURATION + 0.2)
	_play_sfx("sfx_dash",0.8)

# ---------------------------------------------------------------------------
# draw
# ---------------------------------------------------------------------------
func _draw() -> void:
	if state == "menu" or state == "help" or state == "settings":
		_draw_menu_background()
		if state == "menu": _draw_menu()
		elif state == "settings": _draw_settings()
		else: _draw_help()
		return
	_draw_world()
	_draw_ui()
	if state == "paused": _draw_pause()
	elif state == "gameover": _draw_gameover()

func _draw_world() -> void:
	var shake_off := Vector2.ZERO
	if settings.screen_shake and shake > 0:
		shake_off = Vector2(sin(game_time*91.0)*7.0*shake, cos(game_time*77.0)*7.0*shake*0.7)
	draw_set_transform(shake_off)
	var b: Dictionary = BIOMES[biome_index]
	var tint: Color = b.tint
	if textures.has("ocean_bg"):
		draw_texture_rect(textures.ocean_bg, Rect2(0,0,W,H), false, Color(tint.r, tint.g, tint.b, 1.0))
	# far ridge
	var far: Texture2D = textures.get("layer_far")
	if far:
		var fs := far.get_size()
		var fx := fmod(-scroll_x*0.085, fs.x)
		draw_texture_rect(far, Rect2(fx, 80, fs.x, H-80), false, Color(tint.r,tint.g,tint.b,0.55))
		draw_texture_rect(far, Rect2(fx+fs.x, 80, fs.x, H-80), false, Color(tint.r,tint.g,tint.b,0.55))
	var mid: Texture2D = textures.get("layer_mid")
	if mid:
		var ms := mid.get_size()
		var mx := fmod(-scroll_x*0.24, ms.x)
		draw_texture_rect(mid, Rect2(mx, 130, ms.x, H-130), false, Color(tint.r,tint.g,tint.b,0.7))
		draw_texture_rect(mid, Rect2(mx+ms.x, 130, ms.x, H-130), false, Color(tint.r,tint.g,tint.b,0.7))
	# canyon walls
	if textures.has("canyon_top") and textures.has("canyon_bottom"):
		var top_tex: Texture2D = textures.canyon_top
		var bot_tex: Texture2D = textures.canyon_bottom
		var tw := top_tex.get_size().x
		var off := fmod(scroll_x, tw)
		for i in range(2):
			var x := -off + i*tw
			draw_texture_rect(top_tex, Rect2(x,0,tw,top_tex.get_size().y), false, Color(tint.r,tint.g,tint.b,0.8))
			draw_texture_rect(bot_tex, Rect2(x,H-bot_tex.get_size().y,tw,bot_tex.get_size().y), false, Color(tint.r,tint.g,tint.b,0.8))
	# decor
	for d in decor:
		var sx: float = d.x - scroll_x
		if sx < -180 or sx > W+180: continue
		var col := Color(1,1,1,0.42)
		if d.side == "top":
			draw_texture_rect(d.tex, Rect2(sx,d.y+d.get("sway",0),d.tex.get_size().x,d.tex.get_size().y), false, col)
		else:
			draw_texture_rect(d.tex, Rect2(sx,d.y+d.get("sway",0),d.tex.get_size().x,d.tex.get_size().y), false, col)
	# pickups
	for p in pickups:
		if not p.alive: continue
		var sx: float = p.x - scroll_x
		if sx < -100 or sx > W+100: continue
		var tex: Texture2D = textures.pearl
		if p.kind == "shield": tex = textures.power_shield
		elif p.kind == "boost": tex = textures.power_boost
		var sz := 48.0 if p.kind == "pearl" else (94.0 if p.kind == "boost" else 118.0)
		var pulse := 1.0 + 0.06*sin(game_time*4+p.phase)
		if p.kind == "pearl": sz *= pulse
		draw_circle(Vector2(sx,p.y), sz*0.55, Color(0.55,0.75,0.9,0.10))
		draw_texture_rect(tex, Rect2(sx-sz/2,p.y-sz/2,sz,sz), false)
	# obstacles
	for o in obstacles:
		var sx: float = o.x - scroll_x
		if sx < -300 or sx > W+300: continue
		_draw_obstacle(o,sx)
	# player
	_draw_player(shake_off)
	# particles
	for p in particles:
		var a: float = clampf(p.life/maxf(0.001,p.max_life),0,1)
		if p.kind == "bubble":
			var sz: float = maxf(3,p.size)
			draw_texture_rect(textures.bubble_small, Rect2(p.x,p.y,sz,sz), false, Color(1,1,1,a*0.6))
		elif p.kind == "spark":
			draw_circle(Vector2(p.x,p.y), maxf(1,p.size)*2, Color(0.7,1,0.95,a*0.4))
		else:
			draw_circle(Vector2(p.x,p.y), maxf(1,p.size), Color(p.color.r,p.color.g,p.color.b,a*0.5))
	if textures.has("vignette"):
		draw_texture_rect(textures.vignette, Rect2(0,0,W,H), false)
	if boost_flash > 0: draw_rect(Rect2(0,0,W,H), Color(1,0.85,0.55,0.18*boost_flash))
	if flash > 0: draw_rect(Rect2(0,0,W,H), Color(1,0.3,0.35,0.28*flash))
	draw_set_transform(Vector2.ZERO)

func _draw_obstacle(o: Dictionary, sx: float) -> void:
	var glow: Texture2D = textures.glow_warm
	if o.kind == "rock":
		draw_texture_rect(glow, Rect2(sx-125,o.y-100,250,200), false, Color(1,0.6,0.45,0.18))
		draw_texture_rect(o.tex, Rect2(sx-o.w/2,o.y-o.h/2,o.w,o.h), false)
	elif o.kind == "jelly":
		var frame: Texture2D = jelly_frames[int(game_time*6+o.phase)%4]
		draw_texture_rect(textures.glow_pearl, Rect2(sx-90,o.y-110,180,220), false, Color(1,0.7,0.9,0.22))
		draw_texture_rect(frame, Rect2(sx-66,o.y-85,132,171), false, Color(1,1,1,0.92))
	elif o.kind == "urchin":
		draw_texture_rect(textures.glow_warm, Rect2(sx-75,o.y-75,150,150), false, Color(1,0.6,0.45,0.25))
		draw_set_transform(Vector2(sx,o.y), deg_to_rad(o.rot), Vector2.ONE)
		draw_texture_rect(o.tex, Rect2(-52,-52,104,104), false)
		draw_set_transform(Vector2.ZERO)
	elif o.kind == "spike":
		if o.side == "bottom":
			draw_set_transform(Vector2(sx, o.draw_y + o.h), 0, Vector2(1, -1))
			draw_texture_rect(o.tex, Rect2(-o.w/2, 0, o.w, o.h), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(o.tex, Rect2(sx-o.w/2,o.draw_y,o.w,o.h), false)
		var tipy: float = o.draw_y + o.h if o.side == "top" else o.draw_y
		draw_texture_rect(textures.glow_warm, Rect2(sx-60,tipy-60,120,120), false, Color(1,0.6,0.45,0.3))
	elif o.kind == "gate":
		draw_texture_rect(o.top_tex, Rect2(sx-o.w/2, o.top_y, o.w, o.top_len), false)
		draw_set_transform(Vector2(sx, o.bot_y + o.bot_len), 0, Vector2(1, -1))
		draw_texture_rect(o.bot_tex, Rect2(-o.w/2, 0, o.w, o.bot_len), false)
		draw_set_transform(Vector2.ZERO)
		for yy in [o.gap_top,o.gap_bottom]:
			draw_texture_rect(textures.glow_warm, Rect2(sx-60,yy-60,120,120), false, Color(1,0.6,0.45,0.28))

func _draw_player(off: Vector2) -> void:
	var fi := int(game_time*9)%whale_frames.size()
	var ang := clampf(-player_vy*0.030,-12,12) + sin(game_time*1.7)*1.2
	var center := Vector2(PLAYER_X, player_y + sin(game_time*2.1)*3.0) + off
	draw_circle(center, 80.0 * WHALE_SCALE, Color(0.55,0.9,0.85,0.06))
	if shield:
		var r := 98 + int(6*sin(game_time*4))
		draw_texture_rect(textures.power_shield, Rect2(center-Vector2(r,r),Vector2(r*2,r*2)), false, Color(1,1,1,0.65))
	# 无敌时鲸鱼本体隔帧闪烁（保留光环与护盾）
	if invuln > 0 and dash_timer <= 0.0 and int(invuln*18) % 2 == 0:
		return
	draw_set_transform(center, deg_to_rad(ang), Vector2(WHALE_SCALE, WHALE_SCALE))
	var tex: Texture2D = whale_frames[fi]
	var ts := tex.get_size()
	draw_texture_rect(tex, Rect2(-ts.x/2,-ts.y/2,ts.x,ts.y), false, Color(1,1,1,1) if dash_timer<=0 else Color(1.25,1.15,1.05,1))
	draw_set_transform(Vector2.ZERO)

func _draw_ui() -> void:
	# HUD chips
	_draw_chip(Rect2(24,20,330,78), 232)
	_text(T("hud_depth"), 44, 37, 12, Color8(118,180,175), true)
	_text("%.0f m" % distance, 42, 56, 35, UI_TEXT, true)
	var best := maxf(float(save_data.get("bestDistance",0)), distance)
	_text(T("hud_best") % best, 336, 74, 12, UI_MUTED, false, "right")
	_text(T("hud_difficulty") % _diff_name(), 24, 105, 12, BIOMES[biome_index].accent, true)
	if settings.show_fps:
		_text("%.0f FPS" % fps_value, 354, 108, 11, UI_MUTED, false, "right")
	_draw_chip(Rect2(444,20,386,78), 232)
	_text(T("hud_biome"), 464, 32, 12, Color8(118,180,175), true)
	_text(_biome_name(biome_index), 464, 48, 21, BIOMES[biome_index].accent, true)
	_text(BIOMES[biome_index].en, 812, 38, 11, Color8(110,156,157), false, "right")
	var bar := Rect2(464,80,346,5)
	draw_rect(bar, Color8(10,35,49))
	var prog := fmod(distance, BIOME_LENGTH)/BIOME_LENGTH
	draw_rect(Rect2(bar.position, Vector2(bar.size.x*prog,bar.size.y)), BIOMES[biome_index].accent)
	_text(T("hud_next"), 812, 88, 10, Color8(95,140,143), false, "right")
	_draw_chip(Rect2(862,20,394,78), 232)
	_text(T("hud_score"), 882, 36, 12, Color8(118,180,175), true)
	_text("%d" % score, 880, 58, 30, UI_GOLD, true)
	_text(T("hud_pearl"), 1105, 37, 12, Color8(118,180,175), true)
	draw_texture_rect(textures.pearl, Rect2(1100,56,25,25), false)
	_text("%d" % pearls, 1132, 76, 23, Color8(255,231,246), true)
	_text(T("hud_life"), 1110, 128, 11, Color8(126,170,168), false, "right")
	for i in range(3):
		var col := Color(1,1,1,1) if i < hearts else Color(1,1,1,0.2)
		draw_texture_rect(textures.icon_heart, Rect2(1158+i*38,108,28,26), false, col)
	var sy := 148
	if shield:
		draw_texture_rect(textures.power_shield, Rect2(1158,sy,38,38), false)
		_text(T("hud_shield"), 1200, sy+19, 12, UI_ACCENT, true)
		sy += 42
	if boost_timer > 0:
		draw_texture_rect(textures.power_boost, Rect2(1158,sy,36,36), false)
		_text(T("hud_boost") % boost_timer, 1200, sy+18, 12, UI_GOLD, true)
	# dash
	_draw_chip(Rect2(24,652,258,42), 200)
	draw_texture_rect(textures.icon_dash, Rect2(38,660,24,24), false)
	var ready := dash_cd <= 0
	draw_rect(Rect2(76,672,120,7), Color8(9,33,44))
	var p := 1.0 if ready else 1.0-dash_cd/(DASH_COOLDOWN*float(_difficulty().dash_cd_mult))
	draw_rect(Rect2(76,672,120*clampf(p,0,1),7), UI_ACCENT if ready else Color8(63,115,116))
	_text(T("hud_dash_ready") if ready else T("hud_dash_cool"), 76, 666, 12, UI_ACCENT if ready else Color8(123,160,160), true)
	_text("SHIFT / A", 268, 674, 10, Color8(94,137,140), false, "right")
	# compact save status, bottom-right
	var sr := Rect2(W-202, H-58, 178, 30)
	_draw_chip(sr, 210)
	draw_texture_rect(textures.icon_save, Rect2(sr.position.x+12, sr.position.y+7, 15, 15), false, Color(1,1,1,0.85))
	draw_circle(Vector2(sr.position.x+37, sr.position.y+15), 3.5, UI_GREEN)
	_text(T("hud_save_short"), sr.position.x+48, sr.position.y+7, 12, UI_GREEN, true)
	if run_seconds < 9.5:
		var a := int(210*clampf(minf(run_seconds/1.0,(9.5-run_seconds)/1.4),0,1))
		_draw_rounded(Rect2(W/2-280,604,560,40), Color8(3,20,33,int(150*a/255)), 20)
		_text(T("hud_hint"), W/2, 626, 15, Color8(211,242,232,a), true, "center")
	if toast_timer > 0 and state in ["playing", "dying"]:
		var a := int(255*clampf(minf((4.0-toast_timer)/0.25,toast_timer/0.55),0,1))
		_draw_rounded(Rect2(W/2-210,108,420,44), Color8(3,20,33,int(200*a/255)), 20)
		_text(toast, W/2, 132, 21, Color(toast_color.r,toast_color.g,toast_color.b,a), true, "center")
	if biome_banner > 0 and state in ["playing", "dying"]:
		var a2 := int(255*minf(clampf((2.8-biome_banner)/0.4,0,1),clampf(biome_banner/0.7,0,1)))
		_text(biome_name, W/2, 186, 30, Color(BIOMES[biome_index].accent.r,BIOMES[biome_index].accent.g,BIOMES[biome_index].accent.b,a2), true, "center")
		_text(biome_sub, W/2, 232, 13, Color(173,207,198,a2*0.8), false, "center")
	for t in texts:
		var a3 := int(255*clampf(t.life/t.max_life,0,1))
		_text(t.text, t.x, t.y, t.size, Color(t.color.r,t.color.g,t.color.b,a3), false, "center")

func _draw_menu_background() -> void:
	var tint := Color(0.55,0.9,0.9,1)
	if textures.has("ocean_bg"):
		draw_texture_rect(textures.ocean_bg, Rect2(0,0,W,H), false, Color(0.75,0.9,0.95,1))
	if textures.has("layer_far"):
		var fs: Vector2 = textures.layer_far.get_size()
		var fx := fmod(-time*12.0, fs.x)
		draw_texture_rect(textures.layer_far, Rect2(fx,80,fs.x,H-80), false, Color(0.8,1,1,0.4))
		draw_texture_rect(textures.layer_far, Rect2(fx+fs.x,80,fs.x,H-80), false, Color(0.8,1,1,0.4))
	if textures.has("vignette"):
		draw_texture_rect(textures.vignette, Rect2(0,0,W,H), false)
	# whale
	var whale: Texture2D = whale_frames[0] if whale_frames.size() > 0 else null
	if whale != null:
		var bob := sin(time*1.25)*9
		draw_texture_rect(whale, Rect2(770,260+bob,334,195), false, Color(1,1,1,0.95))
	# soft left shade (single gradient texture, no banding)
	if textures.has("menu_shade"):
		draw_texture_rect(textures.menu_shade, Rect2(0, 0, 760, H), false)

func _draw_menu() -> void:
	_text(T("menu_kicker"), 78, 103, 14, UI_ACCENT, true)
	draw_line(Vector2(78,116),Vector2(342,116),Color8(84,154,151),1)
	_text(T("menu_title"), 72, 130, 76, UI_TEXT, true)
	_text(T("menu_subtitle"), 84, 250, 24, Color8(143,205,195))
	_text(T("menu_tagline"), 84, 284, 16, UI_MUTED)
	ui_buttons.clear()
	var rows := [
		[T("menu_new"), "%s · %s" % [_diff_name(),_diff_tag()], true],
		[T("menu_continue"), _continue_label(), save_data.get("checkpoint") is Dictionary],
		[T("menu_help"), "", true], [T("menu_settings"), "", true], [T("menu_quit"), "", true],
	]
	for i in range(5):
		var r := Rect2(82,324+i*66,372,58)
		_draw_button(r, rows[i][0], rows[i][1], selection == i, rows[i][2], i==0)
		ui_buttons.append({"id":i,"rect":r})
	_text(T("menu_best_depth"), 84, 656, 12, Color8(92,144,145))
	_text("%.0f m" % float(save_data.get("bestDistance",0)), 84, 680, 25, UI_TEXT, true)
	_text(T("menu_best_score"), 252, 656, 12, Color8(92,144,145))
	_text("%d" % int(save_data.get("bestScore",0)), 252, 680, 25, UI_TEXT, true)
	_text(T("menu_runs"), 426, 656, 12, Color8(92,144,145))
	_text("%d" % int(save_data.get("runs",0)), 426, 680, 25, UI_TEXT, true)
	_text(T("menu_hint"), W-34, 690, 13, Color8(134,177,176), false, "right")
	_text(T("menu_version"), W-34, 704, 12, Color8(82,123,128), false, "right")
	_draw_save_badge()

func _continue_label() -> String:
	var cp = save_data.get("checkpoint")
	if cp is Dictionary:
		return "%.0f m" % float(cp.get("distance",0))
	return T("menu_no_cp")

func _draw_button(r: Rect2, label: String, sub: String, selected: bool, enabled: bool, primary: bool) -> void:
	if str(settings.get("language", "en")) == "en" and sub in ["DONE", "RESET", "RESUME", "RESTART", "MENU", "DIVE AGAIN", "MAIN MENU"]:
		sub = ""
	var bg := Color8(28,100,102,240) if not primary else Color8(38,135,132,245)
	if not enabled: bg = Color8(20,55,62,170)
	if selected: bg = Color8(38,140,135,250)
	_draw_rounded(r, bg, 14, Color8(126,247,218,150) if selected else Color(0,0,0,0), 1)
	if selected:
		draw_rect(Rect2(r.position+Vector2(1,17),Vector2(4,r.size.y-34)), UI_ACCENT)
	_text(label, r.position.x+30, r.position.y+r.size.y/2-10, 23 if r.size.y<70 else 25,
		UI_TEXT if enabled else Color8(95,119,123), true)
	if sub != "":
		_text(sub, r.end.x-42, r.position.y+r.size.y/2-3, 14, UI_MUTED if enabled else Color8(70,93,99), false, "right")

func _draw_settings() -> void:
	var panel := Rect2(140,44,1000,632)
	_draw_rounded(panel, Color8(3,22,36,225), 28)
	draw_rect(panel, Color8(87,165,157,80), false, 1.0)
	_text(T("set_kicker"), W/2, 68, 12, UI_ACCENT, true, "center")
	_text(T("set_title"), W/2, 88, 34, UI_TEXT, true, "center")
	ui_buttons.clear()
	for i in range(SETTING_ROWS.size()):
		var key: String = SETTING_ROWS[i]
		var r := Rect2(174,148+i*42,932,38)
		if i==settings_selection:
			_draw_rounded(r, Color8(18,66,78,175), 10, Color8(126,247,218,155), 1)
		var cy := r.position.y + r.size.y * 0.5
		_text(_setting_label(key), 194, cy, 18, UI_TEXT, true, "left", true)
		_text(_value_text(key), 760, cy, 18, BIOMES[0].accent, true, "right", true)
		_text("<", 795, cy, 18, Color8(107,180,173), false, "center", true)
		_text(">", 840, cy, 18, Color8(107,180,173), false, "center", true)
		ui_buttons.append({"id":100+i,"rect":Rect2(785,r.position.y+8,28,28)})
		ui_buttons.append({"id":i,"rect":Rect2(828,r.position.y+8,28,28)})
	var desc := _desc(SETTING_ROWS[settings_selection])
	_draw_rounded(Rect2(174,548,932,50), Color8(3,20,33,150), 10)
	_text(desc, 194, 572, 13, UI_MUTED)
	_draw_action(Rect2(410,604,220,46), T("set_done"), "DONE", false)
	_draw_action(Rect2(660,604,220,46), T("set_reset"), "RESET", false)
	_text(T("set_hint"), W/2, 684, 12, UI_MUTED, false, "center")

func _setting_label(key: String) -> String:
	return {"difficulty":T("set_difficulty"),"display_mode":T("set_display"),"resolution":T("set_resolution"),"fps_limit":T("set_fps"),"sensitivity":T("set_sensitivity"),"volume":T("set_volume"),"screen_shake":T("set_shake"),"show_fps":T("set_showfps"),"language":T("set_language")}.get(key,key)

func _draw_action(r: Rect2, label: String, sub: String, selected: bool) -> void:
	_draw_button(r, label, sub, selected, true, false)
	ui_buttons.append({"id":-1 if label==T("set_done") else -2,"rect":r})

func _draw_help() -> void:
	_draw_rounded(Rect2(170,70,940,580), Color8(3,22,36,225), 28)
	_text(T("help_title"), W/2, 120, 38, UI_TEXT, true, "center")
	var lines := [
		T("help_l1"),
		T("help_l2"),
		T("help_l3"),
		T("help_l4"),
		T("help_l5"),
		T("help_l6"),
		T("help_l7"),
	]
	for i in range(lines.size()):
		_text(lines[i], 250, 210+i*54, 20, UI_TEXT if i<3 else UI_MUTED)
	_text(T("help_back"), W/2, 610, 14, UI_ACCENT, false, "center")
	ui_buttons.clear()

func _draw_pause() -> void:
	draw_rect(Rect2(0,0,W,H), Color8(1,10,18,176))
	var panel := Rect2(340,104,600,512)
	_draw_rounded(panel, Color8(3,22,36,235), 24)
	draw_rect(panel, Color8(87,165,157,70), false, 1.0)
	_text(T("pause_kicker"), W/2, 146, 12, UI_ACCENT, true, "center")
	_text(T("pause_title"), W/2, 184, 36, UI_TEXT, true, "center")
	_text("%.0f m" % distance, 470, 270, 25, UI_TEXT, true, "center")
	_text("%d" % pearls, 640, 270, 25, UI_TEXT, true, "center")
	_text("%d" % score, 810, 270, 25, UI_TEXT, true, "center")
	_text(T("pause_depth"), 470, 242, 12, UI_MUTED, false, "center")
	_text(T("pause_pearl"), 640, 242, 12, UI_MUTED, false, "center")
	_text(T("pause_score"), 810, 242, 12, UI_MUTED, false, "center")
	_text(T("pause_difficulty") % [_diff_name(),_diff_tag()], W/2, 306, 13, BIOMES[biome_index].accent, false, "center")
	ui_buttons.clear()
	var labels := [[T("pause_resume"),"RESUME"],[T("pause_restart"),"RESTART"],[T("pause_menu"),"MENU"]]
	for i in range(3):
		var r := Rect2(430,332+i*68,420,56)
		_draw_button(r, labels[i][0], labels[i][1], selection==i, true, i==0)
		ui_buttons.append({"id":i,"rect":r})
	_text(T("pause_hint"), W/2, 580, 13, Color8(113,158,159), false, "center")

func _draw_gameover() -> void:
	draw_rect(Rect2(0,0,W,H), Color8(1,10,18,150))
	var panel := Rect2(340,88,600,548)
	_draw_rounded(panel, Color8(3,22,36,235), 24)
	draw_rect(panel, Color8(87,165,157,70), false, 1.0)
	_text(T("over_kicker"), W/2, 126, 12, UI_ACCENT, true, "center")
	_text(T("over_title"), W/2, 172, 38, Color8(255,196,198), true, "center")
	_text(T("over_record"), W/2, 246, 13, UI_GOLD, true, "center") if distance > 0.0 and distance >= float(save_data.get("bestDistance",0)) else null
	_text(T("over_depth"), 460, 284, 12, UI_MUTED, false, "center")
	_text("%.0f m" % distance, 460, 316, 27, UI_TEXT, true, "center")
	_text(T("over_pearl"), 640, 284, 12, UI_MUTED, false, "center")
	_text("%d" % pearls, 640, 316, 27, UI_TEXT, true, "center")
	_text(T("over_score"), 820, 284, 12, UI_MUTED, false, "center")
	_text("%d" % score, 820, 316, 27, UI_TEXT, true, "center")
	_text(T("over_best") % [float(save_data.get("bestDistance",0)), int(save_data.get("bestScore",0))], W/2, 366, 14, UI_MUTED, false, "center")
	_text(T("over_difficulty") % [_diff_name(),_difficulty().score_mult], W/2, 396, 13, BIOMES[biome_index].accent, false, "center")
	ui_buttons.clear()
	var labels := [[T("over_again"),"DIVE AGAIN"],[T("over_menu"),"MAIN MENU"]]
	for i in range(2):
		var r := Rect2(430,424+i*68,420,56)
		_draw_button(r, labels[i][0], labels[i][1], selection==i, true, i==0)
		ui_buttons.append({"id":i,"rect":r})
	_text(T("over_hint"), W/2, 590, 13, Color8(113,158,159), false, "center")

# ---------------------------------------------------------------------------
# drawing helpers
# ---------------------------------------------------------------------------
func _draw_chip(r: Rect2, alpha: int) -> void:
	_draw_rounded(r, Color8(3,20,33,int(alpha*0.9)), 18)
	draw_rect(r, Color8(96,205,188,55), false, 1.0)

func _draw_rounded(r: Rect2, col: Color, radius: float, border_color: Color = Color(0,0,0,0), border_width: int = 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = int(radius)
	sb.corner_radius_top_right = int(radius)
	sb.corner_radius_bottom_left = int(radius)
	sb.corner_radius_bottom_right = int(radius)
	if border_width > 0:
		sb.set_border_width_all(border_width)
		sb.border_color = border_color
	draw_style_box(sb, r)

func _draw_save_badge() -> void:
	var r := Rect2(W-268, 24, 240, 40)
	_draw_chip(r, 220)
	draw_texture_rect(textures.icon_save, Rect2(r.position.x+16, r.position.y+12, 16, 16), false, Color(1,1,1,0.9))
	draw_circle(Vector2(r.position.x+44, r.position.y+20), 4, UI_GREEN if save_data.get("checkpoint") is Dictionary or int(save_data.get("bestDistance",0))>0 else UI_MUTED)
	_text(T("hud_save_short"), r.position.x+56, r.position.y+11, 13, UI_TEXT, true)

func _text(value: String, x: float, y: float, size: int, col: Color, bold := false, align := "left", center_y := false) -> void:
	var f: Font = font_bold if bold else font_regular
	if f == null: return
	var w := f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var px := x
	var al := HORIZONTAL_ALIGNMENT_LEFT
	if align == "center": px = x - w/2
	elif align == "right": px = x - w
	# 默认 y 是"顶部-ish"坐标；center_y=true 时把 y 当作文字垂直中心
	var py: float
	if center_y:
		py = y + (f.get_ascent(size) - f.get_descent(size)) * 0.5
	else:
		py = y + f.get_ascent(size) * 0.82
	draw_string_outline(f, Vector2(px,py), value, al, -1, size, 3, Color(0,0.03,0.06,0.7))
	draw_string(f, Vector2(px,py), value, al, -1, size, col)

# ---------------------------------------------------------------------------
# particles / capture
# ---------------------------------------------------------------------------
func _emit_bubble(x: float, y: float, size: float, life: float) -> void:
	particles.append({"kind":"bubble","x":x,"y":y,"vx":randf_range(-20,10),"vy":randf_range(-40,-10),"size":size,"life":life,"max_life":life,"grow":0.0})

func _capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if capture_path != "":
		img.save_png(capture_path)
	get_tree().quit()

func _parse_capture_args() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--capture="):
			capture_path = a.substr(10)
			if capture_frames < 0: capture_frames = 8
		elif a.begins_with("--frames="):
			capture_frames = int(a.substr(9))
		elif a.begins_with("--scene="):
			capture_scene = a.substr(8)
		elif a.begins_with("--resize="):
			var rs := a.substr(9).split("x")
			if rs.size() == 2:
				capture_resize = Vector2i(int(rs[0]), int(rs[1]))
