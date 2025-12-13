extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var setting_panel: Panel = $SettingPanel



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _ready() -> void:
	main_buttons.visible = true
	setting_panel.visible = false


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	main_buttons.visible = false
	setting_panel.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	_ready()
