extends PanelContainer

@export var weapon : Weapon:
	set(value):
		weapon = value
		$AnimatedSprite2D.sprite_frames = value.sprite_frames
		$AnimatedSprite2D.play("default")
		$Cooldown.wait_time = value.cooldown


func update_icon():
	if weapon == null:
		$TextureRect.texture = null
		return
	
	if weapon.sprite_frames:
		var frames = weapon.sprite_frames
		if frames.has_animation("default") and frames.get_frame_count("default") > 0:
			$TextureRect.texture = frames.get_frame_texture("default", 0)

func _on_cooldown_timeout():
	if weapon:
		$Cooldown.wait_time = weapon.cooldown
		weapon.activate(owner, owner.nearest_enemy, get_tree())
