extends Node

var GameName = "CloudEngine"
var soundBar: float = 0.0                      # Game options
var musicBar: float = 0.0
var effects: bool = true
var scroll: int = 0
var quality: int = 2
var scaling: int = ScalingType.FANCY
var controls: Dictionary
var autopause: bool = true

var toSaveInfo = {
  "SoundVol": soundBar,
  "MusicVol": musicBar,
  "Efekty": effects,
  "Scroll": scroll,
  "Quality": quality,
  "Scaling": scaling,
  "Controls": controls,
  "VSync": OS.vsync_enabled,
  "Autopause": autopause
}
var restartNeeded: bool = false
var saveFileExists: bool = false

enum ScalingType {
  FAST,
  FILTER,
  FANCY
}

var gravity: float = 20                      # Global gravity

var HUD: CanvasLayer                         # ref HUD
var Mario: Node2D                            # ref Mario

signal TimeTick                              # Called when time ticks
signal OnPlayerLoseLife                      # Called when the player dies
signal OnScoreChange                         # Called when score gets changed
signal OnLivesAdded                          # Called when a life gets added
signal OnCoinCollected                       # Called when coins get collected

var lives: int = 4                           # Player lives
var time: int = 999                          # Time left
var score: int = 0                           # Score
var coins: int = 0                           # Player coins
var deaths: int = 0                          # Player deaths (for precision madness-like levels)
var state: int = 0                           # Player powerup state

var projectiles_count: int = 0               # Number of player's projectiles on screen

var checkpoint_active: int = -1               # Self explanable
var checkpoint_position: Vector2

var debug: bool = true                       # Debug
var debug_fly: bool = false
var debug_inv: bool = false

var level_ended: bool = false
var currlevel: Node2D

var levelID: int = 0

var p_fps_switch: float = 0

var current_scene = null

# Create a new timer for delay
onready var timer: Timer = Timer.new()

static func get_delta(delta) -> float:       # Delta by 50 FPS
  return 50 / (1 / (delta if not delta == 0 else 0.0001))

static func get_vector_delta(delta) -> Vector2: # Vector2 with delta values
  return Vector2(get_delta(delta), get_delta(delta))

func _ready() -> void:
  var root = get_tree().get_root()
  current_scene = root.get_child(root.get_child_count() - 1)
  # Move the scene to viewport with shader if one launches it using the F6 key in Godot
  if current_scene.get_parent() == root:
    root.call_deferred('remove_child', current_scene)
    get_node('/root/GlobalViewport/Viewport').call_deferred('add_child', current_scene)
  # Adding a debug inspector
  if debug:
    add_child(preload('res://Objects/Core/Inspector.tscn').instance())
  timer.wait_time = 1.45
  add_child(timer)
  
  var loadedData = loadInfo()
  if !loadedData:
    return
  saveFileExists = true
  
  # Loading settings
  toSaveInfo = JSON.parse(loadedData).result
  
  if toSaveInfo.has('SoundVol'): soundBar = toSaveInfo.SoundVol
  if toSaveInfo.has('MusicVol'): musicBar = toSaveInfo.MusicVol
  if toSaveInfo.has('Efekty') and typeof(toSaveInfo.Efekty) == TYPE_BOOL: effects = toSaveInfo.Efekty
  if toSaveInfo.has('Scroll') and typeof(toSaveInfo.Scroll) == TYPE_REAL: scroll = toSaveInfo.Scroll
  if toSaveInfo.has('Quality') and typeof(toSaveInfo.Quality) == TYPE_REAL: quality = toSaveInfo.Quality
  if toSaveInfo.has('Scaling') and typeof(toSaveInfo.Scaling) == TYPE_REAL: scaling = toSaveInfo.Scaling
  if toSaveInfo.has('Controls') and typeof(toSaveInfo.Controls) == TYPE_DICTIONARY: controls = toSaveInfo.Controls
  if toSaveInfo.has('VSync') and typeof(toSaveInfo.VSync) == TYPE_BOOL: OS.vsync_enabled = toSaveInfo.VSync
  if toSaveInfo.has('Autopause') and typeof(toSaveInfo.Autopause) == TYPE_BOOL: autopause = toSaveInfo.Autopause
  
  # Loading controls
  for action in controls:
    if controls[action] and controls[action] is String:
      var scancode = OS.find_scancode_from_string(controls[action])
      var key = InputEventKey.new()
      key.scancode = scancode
      if key is InputEventKey:
        var oldKeys = InputMap.get_action_list(action)
        for toRemove in oldKeys:
          if toRemove is InputEventKey:
            InputMap.action_erase_event(action, toRemove)
        InputMap.action_add_event(action, key)
  
  GlobalViewport.set_deferred('filter_enabled', scaling == ScalingType.FILTER and ProjectSettings.get_setting("display/window/stretch/mode") == "disable" )
  VisualServer.set_default_clear_color(Color.black)
  
  # Loading music
  yield(get_tree(), 'idle_frame')
  if musicBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), round(musicBar / 5))
  if musicBar == -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), -1000)
  if soundBar > -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), round(soundBar / 5))
  if soundBar == -100:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), -1000)

func saveInfo(content):
  var file = File.new()
  
  file.open("user://" + GameName + ".cloudsav", File.WRITE)
  file.store_string(content)
  file.close()
  
  if scaling == ScalingType.FAST and ProjectSettings.get_setting("display/window/stretch/mode") != "viewport":
    ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
# warning-ignore:return_value_discarded
    ProjectSettings.save_custom("override.cfg")
    restartNeeded = true
    print('Need to restart')

  elif scaling == ScalingType.FILTER and ProjectSettings.get_setting("display/window/stretch/mode") != "disable":
    ProjectSettings.set_setting("display/window/stretch/mode", "disable")
# warning-ignore:return_value_discarded
    ProjectSettings.save_custom("override.cfg")
    restartNeeded = true
    print('Need to restart')
    
  elif scaling == ScalingType.FANCY and ProjectSettings.get_setting("display/window/stretch/mode") != "2d":
    ProjectSettings.set_setting("display/window/stretch/mode", "2d")
# warning-ignore:return_value_discarded
    ProjectSettings.save_custom("override.cfg")
    restartNeeded = true
    print('Need to restart')

func loadInfo():
  var file = File.new()
  if !file.file_exists("user://" + GameName + ".cloudsav"):
    return false
  file.open("user://" + GameName + ".cloudsav", File.READ)
  var content = file.get_as_text()
  file.close()
  return content

func _reset() -> void:   # Level Restart
  lives -= 1
  projectiles_count = 0
  if is_instance_valid(Mario):
    Mario.invulnerable = false
    Mario.dead = false
  goto_scene(current_scene.filename)

# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
  if timer.time_left <= 1 && time != -1: # Wait for delaying
    _delay()
    timer.start()
  if projectiles_count < 0:
    projectiles_count = 0
      
# Fullscreen toggle
func _input(ev):
  if ev.is_action_pressed('ui_fullscreen'):
    OS.window_fullscreen = !OS.window_fullscreen

  if !debug or !(ev is InputEventKey) or !ev.pressed:
    return
  if Input.is_action_pressed('debug_shift'):
  # Hotkey for restarting current level
    if ev.is_action_pressed('debug_f2'):
      lives += 1
      _reset()

    if ev.is_action_pressed('debug_straylist'):
      if Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) > 0:
        print('[CE OUTPUT]: --- STRAY NODES LIST ---')
        print_stray_nodes()
      else:
        print('[CE OUTPUT]: No stray nodes yet, we\'re fine!')

    if !is_instance_valid(Mario): return
  # Toggle fly mode
    if ev.scancode == 49:
      if Mario.dead_gameover: return
      Mario.get_node('Sprite').modulate.a = 0.5 * (1 + int(debug_fly))
      debug_fly = !debug_fly
      if debug_inv and debug_fly:
        debug_inv = false
      if Mario.dead:
        Mario.unkill()
      play_base_sound('DEBUG_Toggle')
      
  # Toggle invisible mode
    if ev.scancode == 50:
      debug_inv = !debug_inv
      if debug_inv and debug_fly:
        debug_fly = false
      play_base_sound('DEBUG_Toggle')
  
  # Toggle shoe
    if ev.scancode == 51:
      if Mario.shoe_node == null:
        var shoe = load('res://Objects/Bonuses/ShoeRed.tscn').instance()
        current_scene.add_child(shoe)
        shoe.global_position = Mario.global_position
      else:
        Mario.shoe_node.call_deferred('queue_free')
        Mario.unbind_shoe()
      play_base_sound('DEBUG_Toggle')
    
  # Toggle HUD visibility (without shift key)
  if ev.is_action_pressed('debug_hud'):
    if !is_instance_valid(HUD): return
    HUD.visible = !HUD.visible
      
# fix physics fps issues
func _process(delta: float):
  var temp = round((1 / delta) / 60) * 60
# warning-ignore:integer_division
  var temp2 = round(Engine.iterations_per_second / 60) * 60
  if temp > 0 and temp2 != temp:
    p_fps_switch += 1 * get_delta(delta)
  else:
    p_fps_switch = 0
  
  if p_fps_switch > 50:
    print('Updated engine iterations')
    Engine.iterations_per_second = temp
  
  # in case something goes wrong with volume
  if AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')) > 1:
    push_warning('Too high music volume!')
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), 0)

# warning-ignore:shadowed_variable
func add_score(score: int) -> void:
# warning-ignore:narrowing_conversion
  self.score += abs(score)
  HUD.get_node('Score').text = str(self.score)
  emit_signal('OnScoreChange')

# warning-ignore:shadowed_variable
func add_lives(lives: int, create_scoretext: bool) -> void:
  var scorePos = Mario.position + Vector2(0, -32).rotated(Mario.rotation)
  if create_scoretext:
    var ScoreT = ScoreText.new(1, scorePos)
    Mario.get_parent().add_child(ScoreT)
# warning-ignore:narrowing_conversion
  self.lives += abs(lives)
  HUD.get_node('LifeSound').play()
  HUD.get_node('Lives').text = str(self.lives)
  emit_signal('OnLivesAdded')

# warning-ignore:shadowed_variable
func add_coins(coins: int) -> void:
# warning-ignore:narrowing_conversion
  self.coins += abs(coins)
  if self.coins >= 100:
    add_lives(1, true)
    self.coins = 0
  HUD.get_node('Coins').text = str(self.coins)
  emit_signal('OnCoinCollected')

func play_base_sound(sound: String) -> void:
  if is_instance_valid(Mario):
    Mario.get_node('BaseSounds').get_node(sound).play()

func reset_all_values(reset_state: bool = true) -> void:
  lives = 4
  score = 0
  coins = 0
  deaths = 0
  projectiles_count = 0
  checkpoint_active = -1
  if reset_state: state = 0
  if is_instance_valid(Mario):
    Mario.invulnerable = false
  
func reset_audio_effects() -> void:
  AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index('Sounds'), 0, false)
  AudioServer.set_bus_volume_db(AudioServer.get_bus_index('CompositedSounds'), 0)

func _ppd() -> void: # Player Powerdown
  if Mario.shield_counter > 0 or debug_inv or debug_fly or Mario.invulnerable:
    return

  if state == 0 and !Mario.is_in_shoe:
    _pll()
  elif Mario.is_in_shoe:
    Mario.shoe_node.get_node('hit').play()
    Mario.shoe_node.hit()
    Mario.unbind_shoe()
    Mario.shield_counter = 150
  else:
    play_base_sound('MAIN_Pipe')
    if state > 1:
      state = 1
    else:
      state = 0
    Mario.appear_counter = 60
    Mario.shield_counter = 100

func _pll() -> void: # Player Death
  if Mario.dead or debug_inv or debug_fly or Mario.invulnerable:
    return
  Global.deaths += 1
  emit_signal('OnPlayerLoseLife')
  if Mario.is_in_shoe:
    Mario.shoe_node.queue_free()
    Mario.unbind_shoe()
  if not Mario.custom_die_stream:
    MusicPlayer.get_node('Main').volume_db = 0
    MusicPlayer.get_node('Main').stream = Mario.die_music
    MusicPlayer.get_node('Main').play()
    MusicPlayer.stop_on_pause()
    MusicPlayer.get_node('Star').stop()
  else:
    var dieMusPlayer = AudioStreamPlayer.new()
    dieMusPlayer.set_stream(Mario.custom_die_stream)
    add_child(dieMusPlayer)
    dieMusPlayer.play()
  
  Mario.dead = true

func _delay() -> void:
  if !is_instance_valid(Mario):
    return
  if !Mario.dead and Mario.controls_enabled:
    emit_signal('TimeTick')
    time -= 1
    if time == -1:
      _pll()

# Generic Functions

func enemy_bounce() -> void:
  if Input.is_action_pressed('mario_jump'):
    Mario.y_speed = -14
  else:
    Mario.y_speed = -9

func lerpa(a, b, t):
  return a - t * (b - a)
  
func is_mario_collide(_detector_name: String, obj) -> bool:
  var collisions = Mario.get_node_or_null(_detector_name).get_overlapping_bodies()
  return collisions && collisions.has(obj)
  
func is_mario_collide_area(_detector_name: String, obj) -> bool:
  var collisions = Mario.get_node_or_null(_detector_name).get_overlapping_areas()
  return collisions && collisions.has(obj)

func is_mario_collide_area_group(_detector_name: String, group: String) -> bool:
  var collisions = Mario.get_node_or_null(_detector_name).get_overlapping_areas()
  var has = false
  if !collisions:
    return false
  else: for c in collisions:
    if c.has_method('is_in_group') and c.is_in_group(group):
      has = true
  return has
 
func is_getting_closer(pix: float, pos: Vector2) -> bool:
  var camera = Mario.get_node_or_null('Camera')
  return (
    pos.x > camera.get_camera_screen_center().x - 320 + pix and
    pos.x < camera.get_camera_screen_center().x + 320 - pix and
    pos.y > camera.get_camera_screen_center().y - 240 + pix and
    pos.y < camera.get_camera_screen_center().y + 240 - pix
  )

func goto_scene(path: String):
  call_deferred('_deferred_goto_scene', path)

func _deferred_goto_scene(path: String):
  current_scene.free()
  var s = ResourceLoader.load(path)
  current_scene = s.instance()
  get_node('/root/GlobalViewport/Viewport').add_child(current_scene)
  #get_tree().set_current_scene(current_scene)
