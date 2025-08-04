## Static Object used for handling Alert System calls with single lines of code.
class_name AlertManager

static func do_alert(_alert_type:Alert.ALERT_TYPES, _alert_title:String, _alert_message:String, _custom_alert_screen_time:float, _custom_alert_fade_time:float, _server_alert:bool=false):
	var alert : Alert = Alert.new(_alert_type, _alert_title, _alert_message, _custom_alert_screen_time, _custom_alert_fade_time, _server_alert)
	
	var alert_signalname:String = "alert_called"
	match _alert_type:
		Alert.ALERT_TYPES.ALERT:
			alert_signalname = "alert_called"
		Alert.ALERT_TYPES.ERROR:
			alert_signalname = "error_called"
		Alert.ALERT_TYPES.WARNING:
			alert_signalname = "warning_called"
		Alert.ALERT_TYPES.TIP:
			alert_signalname = "tip_called"
	
	AlertSystem.instance.do_alert(alert_signalname, alert)



static func create_alert(_alert_title:String, _alert_message:String, _custom_alert_screen_time:float = -1.0, _custom_alert_fade_time:float = -1.0):
	do_alert(Alert.ALERT_TYPES.ALERT, _alert_title, _alert_message, _custom_alert_screen_time, _custom_alert_fade_time)

static func create_error(_alert_title:String, _alert_message:String, _custom_alert_screen_time:float = -1.0, _custom_alert_fade_time:float = -1.0):
	do_alert(Alert.ALERT_TYPES.ERROR, _alert_title, _alert_message, _custom_alert_screen_time, _custom_alert_fade_time)

static func create_warning(_alert_title:String, _alert_message:String, _custom_alert_screen_time:float = -1.0, _custom_alert_fade_time:float = -1.0):
	do_alert(Alert.ALERT_TYPES.WARNING, _alert_title, _alert_message, _custom_alert_screen_time, _custom_alert_fade_time)

static func create_tip(_alert_title:String, _alert_message:String, _custom_alert_screen_time:float = -1.0, _custom_alert_fade_time:float = -1.0):
	do_alert(Alert.ALERT_TYPES.TIP, _alert_title, _alert_message, _custom_alert_screen_time, _custom_alert_fade_time)


static func create_server_alert(_alert_title:String, _alert_message:String, _custom_alert_screen_time:float = -1.0, _custom_alert_fade_time:float = -1.0):
	do_alert(Alert.ALERT_TYPES.ALERT, _alert_title, _alert_message, _custom_alert_screen_time, _custom_alert_fade_time, true)



static func file_saving_error():
	create_error("SAVE FILE ACCESS ERROR!", "There was an error with saving to the filesystem, action cancelled.")

static func file_loading_error():
	create_error("LOAD FILE ACCESS ERROR!", "There was an error with loading from the filesystem, action cancelled.")

static func file_deletion_error():
	create_error("ERROR DELETING FILE!", "There was an error with deleting a file from the filesystem, action cancelled.")
