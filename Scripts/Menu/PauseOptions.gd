extends Node2D

var sel: int = 0
var selLimit: int = 4
var counter: float = 1

func _pseudo_ready():
	$AnimationPlayer.play('ToOptions')
	sel = 0
	counter = 0
	updateOptions()
	for i in get_children():
		if 'sel' in i.name:
			i.frame = 0
			i.modulate.a = 1

func _process(delta):
	if $AnimationPlayer.is_playing():
		get_node('../Pause').position = position - Vector2(640, 0)
		
	if !get_parent().options: return
	
	# Text blinking
	counter += 0.15 * Global.get_delta(delta)
	var sinalpha = sin(counter) * 0.3 + 0.7
	get_node('sel' + str(sel)).modulate.a = sinalpha
	# Text selection
	get_node('sel' + str(sel)).frame = 1
	# VSync Subtitle
	$VSyncNote.visible = sel == 3
	
	# CONTROLS
	
	if Input.is_action_just_pressed('ui_down'):
		get_node('sel' + str(sel)).frame = 0
		get_node('sel' + str(sel)).modulate.a = 1
		sel = 0 if sel + 1 > selLimit else sel + 1
		get_node('../choose').play()
	elif Input.is_action_just_pressed('ui_up'):
		get_node('sel' + str(sel)).frame = 0
		get_node('sel' + str(sel)).modulate.a = 1
		sel = selLimit if sel - 1 < 0 else sel - 1
		get_node('../choose').play()
	
	if Input.is_action_just_pressed('ui_accept') and counter > 0.15:
		if sel == 4:
			$AnimationPlayer.play('FromOptions')
			get_node('../enter').play()
			get_parent().options = false
	if Input.is_action_just_pressed('ui_right'):
		match sel:
			0:
				if Global.soundBar < 0.99:
					Global.soundBar += 0.1
					if is_nan(linear2db(Global.soundBar)): Global.soundBar = 1.0
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear2db(Global.soundBar))
					$tick.play()
					print('SoundVol: ', AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Sounds')))
			1:
				if Global.musicBar < 0.99:
					Global.musicBar += 0.1
					if is_nan(linear2db(Global.musicBar)): Global.musicBar = 1.0
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar) - 6)
					$tick.play()
					print('MusVol: ', AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')))
			2:
				if !Global.autopause:
					Global.autopause = true
					$change.play()
			3:
				if !OS.vsync_enabled:
					OS.vsync_enabled = true
					$change.play()
		updateOptions()
					
	elif Input.is_action_just_pressed('ui_left'):
		match sel:
			0:
				if Global.soundBar > 0.0001:
					Global.soundBar -= 0.1
					if is_nan(linear2db(Global.soundBar)): Global.soundBar = 0
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear2db(Global.soundBar))
					$tick.play()
					print('SoundVol: ', AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Sounds')))
			1:
				if Global.musicBar > 0.0001:
					Global.musicBar -= 0.1
					if is_nan(linear2db(Global.musicBar)): Global.musicBar = 0
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar) - 6)
					$tick.play()
					print('MusVol: ', AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')))
			2:
				if Global.autopause:
					Global.autopause = false
					$change.play()
			3:
				if OS.vsync_enabled:
					OS.vsync_enabled = false
					$change.play()
		updateOptions()
		
	if Input.is_action_just_pressed('ui_cancel') and counter > 1:
		$AnimationPlayer.play('FromOptions')
		saveOptions()
		get_node('../enter').play()
		get_parent().options = false


func updateOptions() -> void:
	$SoundBar.frame = round(Global.soundBar * 10.0)
	$MusicBar.frame = round(Global.musicBar * 10.0)
	$AutoPause.frame = Global.autopause
	$VSync.frame = OS.vsync_enabled
	
func saveOptions() -> void:
	Global.toSaveInfo = {
		'SoundVol': Global.soundBar,
		'MusicVol': Global.musicBar,
		'Efekty': Global.effects,
		'Scroll': Global.scroll,
		'Quality': Global.quality,
		'Scaling': Global.scaling,
		'Controls': Global.controls,
		'VSync': OS.vsync_enabled,
		'RPC': Global.rpc,
		'Autopause': Global.autopause,
		'Overlay': Global.overlay,
		'Autosave': Global.autosave
	}
	Global.saveInfo(JSON.print(Global.toSaveInfo))
