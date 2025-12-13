extends CanvasLayer

@onready var setting_panel: Panel = $SettingPanel

func _ready() -> void:
	visible = false
	setting_panel.visible = false

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
		visible = false
	else:
		get_tree().paused = true
		visible = true

func _on_resume_btn_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_back_btn_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_setting_btn_pressed() -> void:
	setting_panel.visible = true

func _on_settingback_btn_pressed() -> void:
	setting_panel.visible = false
