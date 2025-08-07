extends Database
class_name UserProfileData

var username:String = "user"
var profile_file_path = ""

var user_icon: ImageTexture = null:
	get = get_user_icon, set = set_user_icon


func get_user_icon() -> ImageTexture: return _get_user_icon()

func _get_user_icon() -> ImageTexture: return user_icon

func set_user_icon(icon:ImageTexture) -> void: _set_user_icon(icon)

func _set_user_icon(icon:ImageTexture) -> void: user_icon = icon

### Call this function to serialize the live instance of UserProfileData to Dictionary.
#func get_as_dict() -> Dictionary:
	#var profile_dict = {}
	#profile_dict["USERNAME"] = username
	#profile_dict["FILEPATH"] = profile_file_path
	#
	#profile_dict = _get_as_dict(profile_dict)
	#
	#return profile_dict
#
### Override this function and add entries to profile_dict in an extended class.
#func _get_as_dict(profile_dict:Dictionary) -> Dictionary:
	#return profile_dict
#
#
### Call this function to initialize variables of UserProfileData from a Dictionary.
#func init_from_dict(profile_dict:Dictionary) -> Error:
	#username = profile_dict["USERNAME"]
	#profile_file_path = profile_dict["FILEPATH"]
	#
	#profile_dict = _init_from_dict(profile_dict)
	#
	#return OK
#
### Override this function and set variables from profile_dict entries in an extended class.
#func _init_from_dict(profile_dict:Dictionary) -> Dictionary:
	#return profile_dict


## Assign a username and profile_file_path when creating a new instance of UserProfileData.
func _init(_username:String="username", _profile_file_path:String="") -> void:
	if origin_instance == null: origin_instance = self; is_origin_instance = true
	
	username = _username
	profile_file_path = _profile_file_path
	
	super(username)
