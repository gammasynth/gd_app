extends MainLoop
#class_name DatabaseTree
#
#
#var time_elapsed = 0
#
#func _initialize():
	#print("Initialized:")
	#print("  Starting time: %s" % str(time_elapsed))
#
#func _process(delta):
	#time_elapsed += delta
	## Return true to end the main loop.
	#if time_elapsed > 3.0: _finalize()
	#return time_elapsed > 3.0
#
#func _finalize():
	#print("Finalized:")
	#print("  End time: %s" % str(time_elapsed))
