extends AppAction

## Use this Script's code as a template when implementing an app's actions.
## To implement the action in your app's systems, call App.record_action(your_app_action_instance)
class_name ExampleAppAction

## test is just an example parameter for an action, you can assign params in the func _init
var test:Object = null

func _init(_test:Object=null) -> void:
	test = _test

func _allow_undo() -> bool: return true

func _make_undone() -> Variant:
	test.undo()
	return null


func _allow_redo() -> bool: return true

func _make_redone() -> Variant:
	test.redo()
	return null
