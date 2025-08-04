extends DatabaseNode
class_name AlertSystem

static var instance: AlertSystem

signal alert_called
signal error_called
signal warning_called
signal tip_called

signal systemrule_changed

func _init() -> void:
	if instance:
		printerr("Only use one instance of AlertSystem! Deleting additional instance...")
		queue_free()
	instance = self
	db.persona = ""

func do_alert(alert_signalname:String, alert:Alert) -> void:
	emit_signal(alert_signalname, alert)
	chatf(str(alert.alert_title + " | " + alert.alert_message))
