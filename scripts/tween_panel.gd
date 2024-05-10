@tool
extends Control

@export var start_visible = false 

@export var hidden_pos: Vector2 
@export var hidden_rot: float 

@export var visible_pos: Vector2 
@export var visible_rot: float 

@export_group("hide settings")
@export var hide_time = 0.5
@export var hide_speed_scale = 1.0
@export var hide_ease_type: Tween.EaseType
@export var hide_transition_type: Tween.TransitionType
@export var hide_pause_mode: Tween.TweenPauseMode

@export_group("show settings")
@export var show_time = 0.5
@export var show_speed_scale = 1.0
@export var show_ease_type: Tween.EaseType
@export var show_transition_type: Tween.TransitionType
@export var show_pause_mode: Tween.TweenPauseMode
@export var show_alpha = 1.0

@export_category("tool")
@export_group("setters")
@export_subgroup("hidden setters")
@export var set_hidden_pos: bool : 
	set(is_set): 
		if is_set: 
			set_hidden_pos = false
			hidden_pos = global_position
			
@export var set_hidden_rot: bool : 
	set(is_set): 
		if is_set: 
			set_hidden_rot = false
			hidden_rot = rotation

@export_subgroup("visbile setters")
@export var set_visible_pos: bool : 
	set(is_set): 
		if is_set: 
			set_visible_pos = false
			visible_pos = global_position
			
@export var set_visible_rot: bool : 
	set(is_set): 
		if is_set: 
			set_visible_rot = false
			visible_rot = rotation

@export_group("testing")
@export var test_show: bool : 
	set(is_set): 
		if is_set: 
			_test_show()

@export var test_hide: bool : 
	set(is_set): 
		if is_set: 
			_test_hide()

var is_hidden: bool = false 
var show_tween: Tween = null
var hide_tween: Tween = null

signal panel_hidden; 
signal panel_shown(panel); 

func _ready(): 
	if !start_visible: 
		visible = false
		hide_panel()
	else: 
		visible = true 
		show_panel()

func hide_panel(): 
	if show_tween != null and show_tween.is_running(): 
		show_tween.kill()
	
	var color = modulate
	color.a = 0.0
	
	hide_tween = get_tree().create_tween()
	hide_tween.set_parallel(true)
	hide_tween.set_pause_mode(hide_pause_mode)
	
	hide_tween.set_ease(hide_ease_type)
	hide_tween.set_trans(hide_transition_type)
	hide_tween.set_speed_scale(hide_speed_scale)
	hide_tween.tween_property(self, "position", hidden_pos, hide_time)
	hide_tween.tween_property(self, "rotation", deg_to_rad(hidden_rot), hide_time)
	hide_tween.tween_property(self, "modulate", color, hide_time)
	
	await  hide_tween.finished
	
	hide()
	is_hidden = true 
	
	emit_signal("panel_hidden")
	
func show_panel(): 
	if hide_tween != null and hide_tween.is_running(): 
		hide_tween.kill()
	
	var color = modulate
	color.a = show_alpha
	
	show_tween = get_tree().create_tween()
	show_tween.set_parallel(true)
	show_tween.set_pause_mode(show_pause_mode)
	
	
	show()
	
	show_tween.set_ease(show_ease_type)
	show_tween.set_trans(show_transition_type)
	show_tween.set_speed_scale(show_speed_scale)
	show_tween.tween_property(self, "position", visible_pos, show_time)
	show_tween.tween_property(self, "rotation", deg_to_rad(visible_rot), hide_time)
	show_tween.tween_property(self, "modulate", color, show_time)
		
	is_hidden = false 
	
	emit_signal("panel_shown", self)

func _test_hide(): 
	hide_panel()
	
func _test_show(): 
	show_panel()
	
func _input(event):
	
	if event is InputEventKey:
		if !event.keycode == KEY_QUOTELEFT: 
			return 
			
		if event.is_pressed() and is_hidden: 
			show_panel()
			return 

		if event.is_pressed() && !is_hidden: 
			hide_panel()
			return 

