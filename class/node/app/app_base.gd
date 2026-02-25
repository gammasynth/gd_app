#|*******************************************************************
# app_base.gd
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
extends DatabaseNode

## AppBase is a Foundational class with the skeleton of properties App class may use.
class_name AppBase

static var instance: AppBase

signal app_starting

signal pre_load
signal ui_mercy

## An App can be in one of multiple APP_STATES at once.
enum APP_STATES {
	INIT, 
	DEVICE_START_SESSION,
	PARSE_BOOT_ARGS, 
	BOOT, 
	REGISTRY_BOOT, 
	LOADING, 
	APP_START_SESSION,
	RUNNING, 
	QUERY, 
	CLOSING
	}

## The current state from APP_STATES that an App is in, at a time.
static var state : APP_STATES = APP_STATES.INIT

## Reccomended to keep debug_all turned off, unless bugfixing or implementing features.
#static var debug_all:bool = false

## WARNING! Some games may print an absurd amount of statements when this is turned on!
#static var deep_debug_all:bool = false

## Title of software, pulls from project settings. Set title in project settings first.
static var title: String = ProjectSettings.get_setting("application/config/name")


## If the program is a game, and not general software.
@export var is_game : bool = false

## Reccomended to turn on for games, or apps with very nice names.
@export var show_title_instead_of_product_type:bool = false

## product_type is mostly used for print statements.
var product_type:String = "app":
	get:
		if is_game: product_type = "game"
		else: product_type = "app"
		if show_title_instead_of_product_type: product_type = title
		return product_type

## whether to log deep information about app startup.
@export var show_boot_info: bool = false


@export var focusless_input : bool = false# TODO
var is_input_allowed: bool = true:
	get:
		if focusless_input: return true
		if get_window().has_focus():
			is_input_allowed = true
		else:
			is_input_allowed = false
		return is_input_allowed

#static var version: String = "0.0.1"
var first_run: bool = true

## Collect data from end-user.
@export var device_tracking: bool = true
## Force close app & prevent app operation if unable to track device and collect data from it, requires internet connection to operate app.
@export var mandatory_device_tracking: bool = false
@export var internet_connection_test_URL:String = "https://google.com"

@export var clear_all_user_files_on_version_update: bool = true

static var is_loader_instance:bool=false
static var load_tracker: LoadTracker


@export var ui_scene_path: String = ""#res://src/scene/ui/main_ui.tscn
static var ui:Control = null# This needs to be an AppUI node, if using GUI for this App.
var ui_subduing:bool = false

#@export var uses_action_history: bool = false
static var session_seed : int = 0
static var game_seed : int = 0
static var unique_id_count : int = 0

var started: bool = false

var related_window_pids:Array[int] = []
