extends DatabaseNode
class_name ChatSystem

## message_posted is a local signal emitted when receiving & printing a chat message, whether from self or server or a peer.
signal message_posted(username:String, message:String)

static var instance: ChatSystem
static var message_count: int = 0
#static var messages: Dictionary[String, String]# username : message


func _initialized() -> void:
	if instance:
		printerr("Only use one instance of ChatSystem! Deleting additional instance...")
		queue_free()
	instance = self
	db.persona = ""

func _ready_up() -> Error:
	if App.ui: App.ui.chat_system_ui.initialize_chat_system()
	return OK

const MAX_USERNAME_LENGTH: int = 16
const MAX_MESSAGE_LENGTH: int = 256

static func send_message(message:String, username:String="", to_pid:int=-1) -> void: instance.post_message(message, username, to_pid)

func post_message(message:String, username:String="", to_pid:int=-1) -> void:
	if username.is_empty() and App.user_profile: username =  App.user_profile.username
	
	if username.length() > MAX_USERNAME_LENGTH: username = username.substr(0, MAX_USERNAME_LENGTH)
	if message.length() > MAX_MESSAGE_LENGTH: message = message.substr(0, MAX_MESSAGE_LENGTH)
	
	var pid:int = App.pid
	if to_pid == -1:
		propagate_message.rpc(pid, message, username)
	else:
		propagate_message.rpc_id(to_pid, pid, message, username)




@rpc("any_peer", "call_local", "reliable")
func propagate_message(from_pid:int=1, message:String="", username:String=""):
	# can use from_pid to check local information on the sender such as user_icon
	# TODO (get user_icon etc)
	message_count += 1
	message_posted.emit(username, message)
	if username == "^&": chatf(message)
	else: chatf(str(username + " | " + message))
