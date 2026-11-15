extends Node

# Simple frame-time benchmark for the gameplay scene.

var main: Node2D
var frames: Array = []
var warm := 0
var done := false

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = load("res://Main.tscn").instantiate()
	add_child(main)

func _process(delta: float) -> void:
	if done:
		return
	warm += 1
	if warm == 3:
		main._start_new()
		main.settings.show_fps = true
		main.settings.fps_limit = 0
		main.is_mobile = false
		main._apply_window()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	if warm < 90:
		return
	frames.append(delta)
	if frames.size() >= 300:
		done = true
		var total := 0.0
		for d in frames:
			total += d
		var avg := total / float(frames.size())
		var sorted := frames.duplicate()
		sorted.sort()
		var p95: float = sorted[int(sorted.size() * 0.95)]
		var worst: float = sorted[sorted.size() - 1]
		print("BENCH frames=%d avg_ms=%.2f p95_ms=%.2f worst_ms=%.2f avg_fps=%.1f obstacles=%d" % [
			frames.size(), avg * 1000.0, p95 * 1000.0, worst * 1000.0, 1.0 / avg, main.obstacles.size()])
		get_tree().quit(0)
