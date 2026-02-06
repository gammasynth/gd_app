#|*******************************************************************
# user_profile_data.gd
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
extends Database
class_name UserProfileData

var username:String = "user"
var profile_file_path = ""
var use_generic_serializer:bool=true

var user_icon: ImageTexture = null:
	get = _get_user_icon, set = _set_user_icon

func _get_user_icon() -> ImageTexture: return user_icon

func _set_user_icon(icon:ImageTexture) -> void: user_icon = icon

## Call this function to serialize the live instance of UserProfileData to Dictionary.
func get_as_dict() -> Dictionary:
	var profile_dict = {}
	#profile_dict["USERNAME"] = username# LEGACY CODE
	#profile_dict["FILEPATH"] = profile_file_path# LEGACY CODE
	profile_dict.set("username", username)
	profile_dict.set("profile_file_path", profile_file_path)
	profile_dict.set("use_generic_serializer", use_generic_serializer)
	
	profile_dict = _get_as_dict(profile_dict)
	
	return profile_dict

## Override this function and add entries to profile_dict in an extended class.
func _get_as_dict(profile_dict:Dictionary) -> Dictionary:
	return profile_dict


## Call this function to initialize variables of UserProfileData from a Dictionary.
func init_from_dict(profile_dict:Dictionary) -> Error:
	if profile_dict.has("USERNAME"): username = profile_dict.get("USERNAME")# LEGACY CODE
	else: username = profile_dict.get("username")
	
	if profile_dict.has("FILEPATH"): profile_file_path = profile_dict.get("FILEPATH")# LEGACY CODE
	else: profile_file_path = profile_dict.get("profile_file_path")
	
	if profile_dict.has("use_generic_serializer"): use_generic_serializer = profile_dict.get("use_generic_serializer")
	
	_do_init(str(get_script().get_global_name() + username))
	
	profile_dict = _init_from_dict(profile_dict)
	
	return OK

## Override this function and set variables from profile_dict entries in an extended class.
func _init_from_dict(profile_dict:Dictionary) -> Dictionary:
	return profile_dict


## Assign a username and profile_file_path when creating a new instance of UserProfileData.
func _init(_username:String="username", _profile_file_path:String="") -> void:
	username = _username
	profile_file_path = _profile_file_path
	
	super(str(get_script().get_global_name() + username))
