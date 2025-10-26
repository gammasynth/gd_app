#|*******************************************************************
# alert.gd
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
