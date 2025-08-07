class_name UserProfileManager

const DEFAULT_ENCRYPTION_PASSKEY: String = "USER_PROFILE_KEY"
static var encryption_passkey: String = DEFAULT_ENCRYPTION_PASSKEY

static func create_new_profile(username:String) -> UserProfileData:
	var profile_folder_name = username.validate_filename()
	var profile_file_path = str("user://user/profiles/" + profile_folder_name + "/")
	var new_profile = UserProfileData.new(username, profile_file_path)
	
	save_profile_to_disk(new_profile)
	return new_profile




static func load_all_profiles() -> Array[UserProfileData]:
	
	DirAccess.make_dir_absolute("user://user/profiles/")
	
	var all_profiles : Array[UserProfileData] = []
	
	var dir = DirAccess.open("user://user/")
	if not dir:
		printerr("Load user profile error: no user folder for profiles, or no read access!")
		return []
	
	if not dir.dir_exists("profiles"):
		printerr("Load user profile error: no user/profiles folder for profiles!")
		return []
	
	dir = DirAccess.open("user://user/profiles/")
	if not dir:
		printerr("Load user profile error: no user/profiles folder for profiles, or no read access!")
		return []
	
	var existing_profile_folders = dir.get_directories()
	
	for existing_profile_string in existing_profile_folders:
		
		var file_name = str(existing_profile_string + ".user")
		var file_path = str("user://user/profiles/" + existing_profile_string + "/" + file_name)
		
		var loaded_profile:UserProfileData = await load_profile_from_path(file_path)
		if loaded_profile != null:
			all_profiles.append(loaded_profile)
	
	return all_profiles



static func load_profile_from_path(file_path:String) -> UserProfileData:
	
	DirAccess.make_dir_absolute("user://user/profiles/")
	
	var passkey = encryption_passkey
	
	var profile_dict = await File.load_dict_file(file_path, encryption_passkey)
	var user_profile = await File.deserialize_object(profile_dict)
	
	return user_profile



static func save_profile_to_disk(profile:UserProfileData):
	
	var username = profile.username.validate_filename()
	
	var file_name = str(username + ".user")
	var file_path = str("user://user/profiles/" + username + "/" + file_name)
	
	DirAccess.make_dir_absolute("user://user/")
	DirAccess.make_dir_absolute("user://user/profiles/")
	
	var dir = DirAccess.open("user://user/profiles/")
	if not dir:
		printerr("Save user profile error: no user/profiles folder for profiles, or no read access!")
		return []
	
	
	var existing_profile_folders = dir.get_directories()
	if not existing_profile_folders.has(username):
		dir.make_dir(username)
	
	var file_dict = File.serialize_object(profile)
	
	var passkey = "factory td profile key"
	var err = File.save_dict_file(file_dict, file_path, passkey)
	
	if err == OK:
		print("Saved Player Profile.")
	else:
		profile_saving_error()



static func delete_local_profile(local_profile:UserProfileData):
	var username = local_profile.username.validate_filename()
	
	var file_name =  str(username + ".user")
	var file_path = str("user://user/profiles/" + username + "/" + file_name)
	
	var dir = DirAccess.open("user://user/profiles/")
	
	var existing_profile_folders = dir.get_directories()
	if existing_profile_folders.has(username):
		
		var file_to_remove = str(file_path + file_name)
		OS.move_to_trash(ProjectSettings.globalize_path(file_path))
		
		#dir = DirAccess.open(file_path)
		#if dir:
			#dir.list_dir_begin()
			#var other_file_name = dir.get_next()
			#while other_file_name != "":
				#if dir.current_is_dir():
					#print("Found directory in profile directory: " + other_file_name + ", may prevent deletion!")
				#else:
					#var other_file_to_remove = str(file_path + other_file_name)
					#OS.move_to_trash(ProjectSettings.globalize_path(other_file_to_remove))
					#print("Deleted file: " + file_name)
				#file_name = dir.get_next()
		AlertSystem.create_warning("Profile deleted!", str("The profile named " + local_profile.username + " was deleted from the filesystem."))

		
	else:
		profile_deletion_error()



static func profile_saving_error():
	AlertSystem.file_saving_error()

static func profile_loading_error():
	AlertSystem.file_loading_error()

static func profile_deletion_error():
	AlertSystem.file_deletion_error()
