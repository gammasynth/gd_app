#|*******************************************************************
# chat_system.gd
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
