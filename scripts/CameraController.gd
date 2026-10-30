extends Node

var world_camera: Camera3D = null
var camera2: Camera3D = null
var camera2_copy: Camera3D = null
var zoom_level: float = 1.0

func setup(cam1: Camera3D, cam2: Camera3D) -> void:
	world_camera = cam1
	self.camera2 = cam2

func set_active_camera(cam_num: int) -> void:
	if world_camera:
		world_camera.current = (cam_num == 1)
	if self.camera2:
		self.camera2.current = (cam_num == 2)

func rotate_camera(cam: Camera3D, angle: float, duration: float = 0.8) -> void:
	if cam == null:
		return
	var target_rotation: float = cam.rotation.y + deg_to_rad(angle)
	var tween := cam.create_tween()
	tween.tween_property(cam, "rotation:y", target_rotation, duration).set_ease(Tween.EASE_IN_OUT)

func zoom_camera(cam: Camera3D, zoom_change: float, duration: float = 0.6) -> void:
	if cam == null:
		return
	zoom_level = clampf(zoom_level + zoom_change, 0.5, 2.0)
	var target_fov: float = clampf(70.0 / zoom_level, 35.0, 90.0)
	var tween := cam.create_tween()
	tween.tween_property(cam, "fov", target_fov, duration).set_ease(Tween.EASE_IN_OUT)

func get_zoom_level() -> float:
	return zoom_level

func reset_zoom() -> void:
	zoom_level = 1.0
