extends Area2D

@export_enum("Cooldown", "HitOnce", "DisableHitBox") var HurtBoxType = 0

@onready var colision = $CollisionShape2D
@onready var DisableTimer = $DisableTimer

signal hurt(dmg)


func _on_area_entered(area):
    if area.is_in_group("attack"):
        if not area.get("dmg") == null:
            match HurtBoxType:
                0: #Cooldown
                    colision.call_deferred("set", "disabled", true)
                    DisableTimer.start()
                1: #HitOnce
                    pass
                2: #DisableHitBox
                    if area.has_method("tempDisable"):
                        area.tempDisable()
            var dmg = area.dmg
            emit_signal("hurt", dmg)

func _on_disable_timer_timeout() -> void:
    colision.call_deferred("set", "disabled", false)	




