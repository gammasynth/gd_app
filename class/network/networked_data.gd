extends RefInstance
class_name NetworkedData

var dataset_name:String = "unknown_data"
var dataset_identifier:int = -1
var received_packets: Dictionary[int, PackedByteArray]

func _init(_dataset_name:String="unknown_data", _dataset_identifier:int=-1, _received_packets:Dictionary[int, PackedByteArray]={}) -> void:
	dataset_name = _dataset_name
	dataset_identifier = _dataset_identifier
	received_packets = _received_packets
