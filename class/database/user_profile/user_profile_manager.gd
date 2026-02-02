#|*******************************************************************
# user_profile_manager.gd
#*******************************************************************
# This file is part of gd_app.
# 
# gd_app is an open-source software library.
# gd_app is licensed under the MIT license.
# https://github.com/gammasynth/gd_app
#*******************************************************************
# Copyright (c) 2025 AD - present; 1447 AH - present, Gammasynth.  
# 
# Gammasynth
# 
# Gammasynth (Gammasynth Software), Texas, U.S.A.
# https://gammasynth.com
# https://github.com/gammasynth
# 
# This software is licensed under the MIT license.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
#|*******************************************************************
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
	
	var profile_dict = await File.load_dict_file(file_path, encryption_passkey)
	#var user_profile = await File.deserialize_object(profile_dict)
	var user_profile = UserProfileData.new()
	user_profile.init_from_dict(profile_dict)
	
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
	
	#var file_dict = File.serialize_object(profile)
	var file_dict: Dictionary = profile.get_as_dict()
	
	var err = File.save_dict_file(file_dict, file_path, encryption_passkey)
	
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
		
		#var file_to_remove = str(file_path + file_name)
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
