extends AppAction
class_name GenericAppAction

var undo_func:Callable
var redo_func:Callable

func _init(_undo_func:Callable, _redo_func:Callable) -> void:
	undo_func = _undo_func
	redo_func = _redo_func

func _allow_undo() -> bool: return true

func _make_undone() -> Variant:
	return undo_func.call()


func _allow_redo() -> bool: return true

func _make_redone() -> Variant:
	return redo_func.call()
