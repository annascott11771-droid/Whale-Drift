extends Node

# =============================================================================
# GlobalData.gd —— 全局单例（Autoload 名称：GlobalData）
#
# 负责三件事：
#   1. 数据层：玩家总珍珠、三个天赋等级，以及存读档（user://save_data.cfg）
#   2. 逻辑层：根据天赋等级计算游戏内属性（护盾时长 / 冲刺距离 / 吸附半径）
#   3. 经济层：单局珍珠结算公式，带通胀上限，防止数值崩坏
#
# 设计约定：
#   · 天赋等级从 1 级起步，最高 5 级
#   · 价格表长度 = 4，对应 1→2、2→3、3→4、4→5
#   · 所有数值都是公开常量，方便后续调平衡
# =============================================================================

signal pearls_changed(total: int)          # 珍珠变化（UI 刷新用）
signal level_changed(kind: String, level: int)
signal save_failed(path: String)

# ---------------------------------------------------------------- 存档
const SAVE_PATH := "user://save_data.cfg"
const SAVE_SECTION := "progress"

# ---------------------------------------------------------------- 经济平衡常量
# 距离折算：每 100 米算 1 颗珍珠
const DISTANCE_PER_PEARL := 100.0
# 单局收益硬上限：无论跑多远、刷多少分，一局最多 50 颗
const PEARL_RUN_CAP := 50
# 局内收集珍珠的计入上限：超过部分只加分数、不再增加货币产出
# （这是把“3~5 局升一次基础天赋”落到实处的关键旋钮）
const COLLECTED_CAP := 12
# 积分加成：10 万分起步，每多 5 万分 +1 颗，最多 +10 颗
const SCORE_BONUS_THRESHOLD := 100000
const SCORE_BONUS_STEP := 50000
const SCORE_BONUS_MAX := 10

# ---------------------------------------------------------------- 天赋定义
# prices：升级到下一级需要的珍珠（指数级递增）
const MAX_LEVEL := 5

const SKILL_ORDER := ["shield", "dash", "magnet"]

const SKILLS := {
	"shield": {
		"name_key": "skill_shield",
		"desc_key": "skill_shield_desc",
		"prices": [50, 120, 250, 500],
		"base": 3.0,
		"per_level": 0.5,
	},
	"dash": {
		"name_key": "skill_dash",
		"desc_key": "skill_dash_desc",
		"prices": [60, 140, 280, 560],
		"base": 100.0,
		"per_level": 20.0,
	},
	"magnet": {
		"name_key": "skill_magnet",
		"desc_key": "skill_magnet_desc",
		"prices": [80, 180, 360, 720],
		"base": 0.0,
		"per_level": 50.0,
	},
}

# ---------------------------------------------------------------- 运行时数据
var total_pearls := 0
var shield_level := 1
var dash_level := 1
var magnet_level := 1

# ---------------------------------------------------------------- 生命周期
func _ready() -> void:
	load_progress()

# ---------------------------------------------------------------- 等级读写
func get_level(kind: String) -> int:
	match kind:
		"shield": return shield_level
		"dash": return dash_level
		"magnet": return magnet_level
	return 1

func _set_level(kind: String, value: int) -> void:
	var v := clampi(value, 1, MAX_LEVEL)
	match kind:
		"shield": shield_level = v
		"dash": dash_level = v
		"magnet": magnet_level = v
	level_changed.emit(kind, v)

# ---------------------------------------------------------------- 属性计算（逻辑层）
# 护盾时长：基础 3 秒，每级 +0.5 秒，5 级 = 5.0 秒
func get_shield_duration() -> float:
	return 3.0 + 0.5 * float(shield_level - 1)

# 冲刺距离：基础 100，每级 +20，5 级 = 180
func get_dash_distance() -> float:
	return 100.0 + 20.0 * float(dash_level - 1)

# 吸附半径：基础 0，每级 +50，5 级 = 200
func get_magnet_radius() -> float:
	return 50.0 * float(magnet_level - 1)

# ---------------------------------------------------------------- 经济结算
# calculate_pearls —— 单局珍珠产出
#   distance         本局深度（米）
#   collected_pearls 本局吃到的珍珠数
#   score            本局得分
#
# 公式：
#   距离部分 = floor(distance / 100)
#   收集部分 = min(collected_pearls, 12)
#   积分部分 = 分数 >= 10 万时按每 5 万分 +1，最多 +10
#   合计     = min(50, 距离 + 收集 + 积分)
#
# 举例：1200 米 / 吃 20 颗 / 3 万分
#   → 12 + 12 + 0 = 24 颗，第一级天赋 50 颗约 2~3 局，符合节奏
func calculate_pearls(distance: float, collected_pearls: int, score: int) -> int:
	var distance_part := int(floor(maxf(distance, 0.0) / DISTANCE_PER_PEARL))
	var collected_part := mini(maxi(collected_pearls, 0), COLLECTED_CAP)
	var score_part := 0
	if score >= SCORE_BONUS_THRESHOLD:
		score_part = 1 + int((score - SCORE_BONUS_THRESHOLD) / SCORE_BONUS_STEP)
		score_part = mini(score_part, SCORE_BONUS_MAX)
	return mini(distance_part + collected_part + score_part, PEARL_RUN_CAP)

# 把一局的珍珠加进总账（返回实际获得的珍珠）
func add_run_pearls(distance: float, collected_pearls: int, score: int) -> int:
	var earned := calculate_pearls(distance, collected_pearls, score)
	add_pearls(earned)
	return earned

func add_pearls(amount: int) -> void:
	if amount == 0:
		return
	total_pearls = maxi(0, total_pearls + amount)
	pearls_changed.emit(total_pearls)

# ---------------------------------------------------------------- 商店价格（消耗层）
func price_for(kind: String) -> int:
	var info: Dictionary = SKILLS.get(kind, {})
	if info.is_empty():
		return -1
	var level := get_level(kind)
	if level >= MAX_LEVEL:
		return -1        # 已满级
	var prices: Array = info["prices"]
	var idx := level - 1
	if idx < 0 or idx >= prices.size():
		return -1
	return int(prices[idx])

func is_max(kind: String) -> bool:
	return get_level(kind) >= MAX_LEVEL

# 尝试升级，返回：
#   "ok"   成功
#   "poor" 珍珠不足
#   "max"  已满级
func try_upgrade(kind: String) -> String:
	if is_max(kind):
		return "max"
	var price := price_for(kind)
	if price < 0:
		return "max"
	if total_pearls < price:
		return "poor"
	total_pearls -= price
	_set_level(kind, get_level(kind) + 1)
	pearls_changed.emit(total_pearls)
	save_progress()
	return "ok"

# ---------------------------------------------------------------- 存档（FileAccess / ConfigFile）
func save_progress() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, "total_pearls", total_pearls)
	cfg.set_value(SAVE_SECTION, "shield_level", shield_level)
	cfg.set_value(SAVE_SECTION, "dash_level", dash_level)
	cfg.set_value(SAVE_SECTION, "magnet_level", magnet_level)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("GlobalData: 保存失败 %s (err=%d)" % [SAVE_PATH, err])
		save_failed.emit(SAVE_PATH)
		return false
	return true

func load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return          # 首次运行没有存档，使用默认值
	total_pearls = maxi(0, int(cfg.get_value(SAVE_SECTION, "total_pearls", 0)))
	shield_level = clampi(int(cfg.get_value(SAVE_SECTION, "shield_level", 1)), 1, MAX_LEVEL)
	dash_level = clampi(int(cfg.get_value(SAVE_SECTION, "dash_level", 1)), 1, MAX_LEVEL)
	magnet_level = clampi(int(cfg.get_value(SAVE_SECTION, "magnet_level", 1)), 1, MAX_LEVEL)
	pearls_changed.emit(total_pearls)

# 调试 / 测试用：清空进度
func reset_progress() -> void:
	total_pearls = 0
	shield_level = 1
	dash_level = 1
	magnet_level = 1
	save_progress()
	pearls_changed.emit(total_pearls)
