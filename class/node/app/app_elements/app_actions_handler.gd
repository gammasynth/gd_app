#|*******************************************************************
# app_actions_handler.gd
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

class_name AppActionsHandler

var action_count: int :
	get: return action_history.size()

var action_history: Dictionary[int, AppAction] = {}

var undone_action_history: Dictionary[int, AppAction] = {}
var undone_action_count: int :
	get: return undone_action_history.size()

func clear_all_history() -> void:
	action_history.clear()
	undone_action_history.clear()

func record_action(action:AppAction):
	undone_action_count = 0
	undone_action_history.clear()
	#add(action, action_count + 1)
	action_history[action_count] = action

func make_action_undone(action:AppAction):
	action.make_undone()
	undone_action_history[undone_action_count] = action
	action_history.erase(action_history.find_key(action))

func make_action_redone(action:AppAction):
	action.make_redone()
	action_history[action_count] = action
	undone_action_history.erase(undone_action_history.find_key(action))

func can_undo(by_amount:int=1)-> bool:
	for a in by_amount:
		var action_int:int = action_count - (a + 1)
		if not action_history.keys().has(action_int): return false
	return true
func undo(by_amount:int=1):
	for a in by_amount:
		var action_int:int = action_count - (a + 1)
		if not action_history.keys().has(action_int): 
			warn("unavailable action to undo!")
			continue
		var action:AppAction = action_history[action_int]
		if not action:
			warn("undo action is null in history!")
			continue
		make_action_undone(action)

func can_redo(by_amount:int=1)-> bool:
	for a in by_amount:
		var action_int:int = undone_action_count - (a + 1)
		if not undone_action_history.keys().has(action_int): return false
	return true
func redo(by_amount:int=1):
	for a in by_amount:
		var action_int:int = undone_action_count - (a + 1)
		if not undone_action_history.keys().has(action_int): 
			warn("unavailable action to redo!")
			continue
		var action:AppAction = undone_action_history[action_int]
		if not action:
			warn("redo action is null in history!")
			continue
		make_action_redone(action)
