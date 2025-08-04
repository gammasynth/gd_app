extends RefCounted
class_name Alert

enum ALERT_TYPES {ALERT, WARNING, ERROR, TIP}

var alert_type : ALERT_TYPES = ALERT_TYPES.ALERT
var alert_title : String = "Alert"
var alert_message : String = "This is an Alert."

#region Alert UI Parameters

var custom_alert_screen_time : float = -1.0
var custom_alert_fade_time : float = -1.0
#endregion

var server_alert: bool = false

func _init(_alert_type:ALERT_TYPES, _alert_title:String, _alert_message:String, _custom_alert_screen_time:float = -1.0, _custom_alert_fade_time:float = -1.0, _server_alert=false):
	alert_type = _alert_type
	alert_title = _alert_title
	alert_message = _alert_message
	
	custom_alert_screen_time = _custom_alert_screen_time
	custom_alert_fade_time = _custom_alert_fade_time
	
	server_alert = _server_alert
