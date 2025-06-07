extends Database

## AppAction class, override _make_undone and _make_redone in an extended class.
class_name AppAction

func _allow_undo() -> bool: return true

func make_undone() -> Variant:
	if not _allow_undo(): return
	return _make_undone()

func _make_undone() -> Variant:
	return null


func _allow_redo() -> bool: return true

func make_redone() -> Variant:
	if not _allow_redo(): return
	return _make_redone()

func _make_redone() -> Variant:
	return null
