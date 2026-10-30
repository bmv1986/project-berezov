extends Node

var devices_scanned: bool = false
var gate_opened: bool = false

func scan_devices() -> void:
	devices_scanned = true

func is_device_available(device_name: String) -> bool:
	match device_name:
		"gate":
			return devices_scanned
		"robot":
			return devices_scanned and gate_opened
		"camera2":
			return gate_opened
		_:
			return false

func set_gate_opened(opened: bool) -> void:
	gate_opened = opened
