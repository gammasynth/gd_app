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
