@tool
extends TweenPanel

enum completion_context { 
	int_range, 
	float_range,
}

@export var config_path = "res://control_tools/console/console.cfg"
@export var line_edit: LineEdit = null
@export var console_text: RichTextLabel = null
@export var target_label: Label = null

var target_object: Object = self 
var command_string_array: PackedStringArray
var commands = {}
var cfg: ConfigFile

@export_group("settings")
@export_subgroup("optional")
@export var viewport: Viewport = null 

func _ready():
	
	if viewport == null: 
		viewport = get_viewport()
	
	target_object = get_tree().root
	
	line_edit.text_submitted.connect(_text_submitted)
	line_edit.text_changed.connect(_text_changed)
	
	panel_shown.connect(_panel_shown)
	
	target_label.text = "target object: " + str(target_object)
	
	config()
	
	add_default_commands()
	
	super()
	

func add_default_commands(): 
	
	add_command("help", "shows all commands", func() : 
		add_line("\n")
		add_line("[b]Commands:[/b]")
		for cmd in commands: 
			add_line("[indent]" + str(cmd) + ": " + commands.get(cmd)["description"] + "[/indent]")
	)
	
	add_command("call", "call method on target object", func() : 
		var args = parse_args("call")
		
		if args.size() > 0 and target_object.has_method(args[0]): 
			var new_args = args.duplicate()
			new_args.remove_at(0)
			target_object.callv(args[0], new_args)
	)
	
	add_command("clear", "clears all console text", func() : 
		console_text.text = ""
	)
	
	add_command("root", "sets target object to the scene root", func() : 
		set_target_object(get_tree().root)
	)
	
	add_command("echo", "prints given variable of target object to the console", func() : 
		if !target_object is Node: return 
		var args = parse_args("echo")
		
		if args.size() > 0 and target_object.get(args[0]): 
			add_line(str(target_object.get(args[0])))
	)
	
	add_command("ls", "list target object's children", func() : 
		if !target_object is Node: 
			return  
	
		for child in target_object.get_children(true): 
			add_line("----\\" + "[color=White]" + str(child) + "[/color]")
	)
	
	add_command("cd", "traverse the scene tree", func() : 
		if !target_object is Node: return 
		var args = parse_args("cd")
		
		if args.size() > 0 and target_object.has_node(args[0]): 
			var node: Node = self 
			
			if target_object is Node: 
				node = target_object
				
			set_target_object(node.get_node(args[0]))
	)
	
	add_command("ts", "sets the timescale", func() : 
		var args = parse_args("ts")
		if args.size() > 0: 
			Engine.time_scale = float(args[0])
	)
	
	add_command("del", "deletes node from the given path", func(): 
		if !target_object is Node: return 
		var args = parse_args("del")
		
		if args.size() > 0 and target_object.has_node(args[0]): 
			var obj = target_object.get_node(args[0])
			
			if obj == target_object: 
				set_target_object(obj.get_parent())
				
			obj.queue_free()
	)
	
	add_command("rl", "reloads current scene", func(): 
		get_tree().reload_current_scene()
	)
	
	add_command("setv", "sets variable on current object", func() : 
		var args = parse_args("setv")
		
		if args.size() > 1 and target_object.get(args[0]): 
			if target_object.get(args[0]) is float: 
				target_object.set(args[0], float(args[1]))
			if target_object.get(args[0]) is int: 
				target_object.set(args[0], int(args[1]))
			if target_object.get(args[0]) is bool: 
				target_object.set(args[0], bool(args[1]))
	)
	
	add_command("quit", "quit the game", func() : 
		get_tree().quit()
	) 
	
	add_command("lyt", "set console layout", func() : 
		var args = parse_args("lyt")
		
		if args.size() > 0 and int(args[0]) <= 15 : 
			anchors_preset = int(args[0])
			hidden_pos.x = position.x
			visible_pos = position
			
			set_config_value("layout", int(args[0]))
			
	,[], completion_context.int_range)
	
	add_command("alpha", "sets transparency", func() : 
		var args = parse_args("alpha")
		
		if args.size() > 0 and float(args[0]) <= 1 and float(args[0]) >= 0.1: 
			modulate.a = float(args[0])
			show_alpha = float(args[0])
			set_config_value("alpha", float(args[0]))
			
	,[], completion_context.int_range)
	
	add_command("camgo", "sets camera position to target node position", func() : 
		
		var cam3D = get_viewport().get_camera_3d()
		var cam2D = get_viewport().get_camera_2d()
		
		if cam3D != null and target_object is Node3D: 
			cam3D.global_position = target_object.global_position
		if cam2D != null and target_object is Node2D: 
			cam2D.global_position = target_object.global_position
	)
	
	add_command("ownergo", "sets camera owner position to target node position", func() : 
		
		var cam3D = viewport.get_camera_3d()
		var cam2D = viewport.get_camera_2d()
		
		if cam3D != null and target_object is Node3D: 
			cam3D.owner.global_position = target_object.global_position
		if cam2D != null and target_object is Node2D: 
			cam2D.owner.global_position = target_object.global_position
	)
	
	
	add_command("pause", "pause game", func() : 
		get_tree().paused = !get_tree().paused
	)
	
	
func set_target_object(obj: Object): 
	target_object = obj
	target_label.text = "target object: " + str(target_object)

func valid_command(command) -> bool: 
	if command_string_array.size() > 0 and command_string_array[0] == command.to_lower():
		return true 
	return false

func parse_args(cmd) -> Array[String]: 
	var args: Array[String] = []
	var index = 0 
	
	for i in command_string_array.size(): 
		if cmd == command_string_array[i]: 
			index = i
			
	for x in command_string_array.size(): 
		if x > index:
			if !command_string_array[x].begins_with("-"): 
				args.append(command_string_array[x]) 
	return args

func add_line(txt): 
	console_text.text += "\n" + txt

func add_command(cmd, description, callable: Callable, args=[], ctx=null): 
	commands[cmd] = {
		"description": description, 
		"action": callable.bindv(args), 
		"ctx": ctx
	}

func config(): 
	anchors_preset = get_config_value("layout", 0)
	modulate.a = float(get_config_value("alpha", 0.1))
	show_alpha = float(get_config_value("alpha", 0.1))
	hidden_pos.x = position.x
	visible_pos = position
	
func get_cfg() -> ConfigFile: 
	var file = ConfigFile.new()
	var err = file.load(config_path)
	
	if err: 
		print(err)
		
	return file

func set_config_value(name, value): 
	var file = get_cfg()
	file.set_value("", name, value)
	file.save(config_path)

func get_config_value(name, default):
	var file = get_cfg()
	
	return get_cfg().get_value("", name, default) 

func _panel_shown(panel): 
	line_edit.grab_focus.call_deferred()

func _text_changed(text): 
	if text == "`": 
		line_edit.clear()
	
	command_string_array = text.strip_edges().split(" ")
	
	for s in command_string_array: 
		if s == "": 
			var index = command_string_array.find(s)
			command_string_array.remove_at(index)

func _text_submitted(text: String): 
	add_line( text)
	
	command_string_array = text.strip_edges().split(" ")
	
	for cmd in commands: 
		if valid_command(cmd): 
			var args = parse_args("cmd")
			commands.get(cmd)["action"].call()
	
	if target_object == null: 
		target_object = get_tree().root
	
	line_edit.clear()
	console_text.get_v_scroll_bar().set_deferred("value", console_text.get_v_scroll_bar().max_value)  

func _try_completion(ctx=null): 
	var split = line_edit.text.split(" ")
	
	match split.size(): 
		0: 
			var index = 0 
			if commands.keys().has(line_edit.text): 
				index = commands.keys().find(line_edit.text)
				index += 1
			
			if index >= commands.keys().size(): 
				index = 0
				
			line_edit.text = str(commands.keys()[index])
			
		1: 
			var prefix = split[0]
			
			commands.keys().sort()
			
			for key in commands.keys(): 
				if key.to_lower().begins_with(prefix.to_lower()) and !line_edit.text.contains(key): 
					line_edit.text = key
					line_edit.caret_column = line_edit.text.length()
					return 
			
			var index = 0 
			if commands.keys().has(line_edit.text): 
				index = commands.keys().find(line_edit.text)
				index += 1
			
			if index >= commands.keys().size(): 
				index = 0
				
			line_edit.text = str(commands.keys()[index])
			
		2: 
			var index = 0 
			
			if !target_object is Node: return 
			
			if commands.has(split[0]) and commands.get(split[0]).ctx != null:
				match commands.get(split[0]).ctx: 
					completion_context.int_range: 
						var inpt = split[1]
						var i = 0
						
						if inpt == "": 
							line_edit.text += str(i)
						elif int(inpt) >= 0:
							i = int(inpt) + 1
							split[1] = str(i)
							line_edit.text = " ".join(split)
						line_edit.caret_column = line_edit.text.length()
				return 
			
			if split[1] == "": 
				line_edit.text += "./" + str(target_object.get_child(index).name)
			else: 
				for child in target_object.get_children(): 
					if child.name.to_lower().begins_with(split[1].to_lower()) and child.name != split[1]: 
						index = child.get_index()
					elif split[1].trim_prefix("./") == child.name: 
						
						index = child.get_index() + 1
				
				if index >= target_object.get_children().size(): 
					index = 0 
					
				split[1] = str(target_object.get_child(index).name)
				
				line_edit.text = " ./".join(split)
			
	line_edit.caret_column = line_edit.text.length()

func _input(event):
	super(event)
	
	
	if is_hidden: 
		return 
		
	if event.is_action_pressed("ui_focus_next"): 
		_try_completion()


