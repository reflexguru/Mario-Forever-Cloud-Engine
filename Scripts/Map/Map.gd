extends Node2D

var internal_offset: float = 0

export var music: Resource
export var mario_speed: float = 1
export var mario_fast_speed: float = 15
export var stop_points: Array = []
export var level_scenes: Array = []
export var camera_left_limit: int = 0
export var camera_right_limit: int = 10000
export var camera_top_limit: int = 0
export var camera_bottom_limit: int = 480

var current_speed: float = mario_speed
var stopped: bool = false
var is_lerping: bool = false

var fading_out: bool = false
var circle_size: float = 0.623

var cam
onready var sprite = Global.Mario.get_node('Sprite')

func _ready() -> void:
  Global.Mario.invulnerable = true
  Global.Mario.movement_type = Global.Mario.Movement.NONE
  MusicPlayer.get_node('Main').stream = music
  MusicPlayer.get_node('Main').play()
  if Global.musicBar > 0.01:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear2db(Global.musicBar))
  MusicPlayer.play_on_pause()
  
  if Global.levelID > 0:
    $MarioPath/PathFollow2D.offset = stop_points[Global.levelID - 1]
  
  Global.call_deferred('reset_audio_effects')
  Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
  
  yield(get_tree(), 'idle_frame')
  cam = Global.current_camera
  if !cam: 
    push_warning('Camera not found')
    return
  
  cam.limit_left = camera_left_limit
  cam.limit_right = camera_right_limit
  cam.limit_top = camera_top_limit
  cam.limit_bottom = camera_bottom_limit
  cam.smoothing_enabled = true

func _input(ev):
  if !Global.debug or !(ev is InputEventKey) or !ev.pressed:
    return
  
  if Input.is_action_pressed('debug_shift'):
    if ev.scancode == 52 and !ev.echo:
      Global.levelID += 1
      Global.lives += 1
      Global._reset()

func _process(delta: float) -> void:
  sprite.animation = 'Walking' if Global.shoe_type == 0 else 'Stopped'
  if Global.shoe_type and !stopped and is_instance_valid(Global.Mario.shoe_node):
    Global.Mario.get_node('AnimationPlayer').play('Small' if Global.state == 0 else 'Big')
    Global.Mario.shoe_node.get_node('AnimatedSprite').offset.y = -12 if Global.state == 0 else 16
  sprite.speed_scale = 20 if !stopped else 5
  sprite.offset.y = 0 - sprite.frames.get_frame(sprite.animation, sprite.frame).get_size().y + 32 if Global.state > 0 else -12

  if $MarioPath/PathFollow2D.offset < stop_points[Global.levelID]:
    $MarioPath/PathFollow2D.offset += current_speed * Global.get_delta(delta)
    
    if Input.is_action_just_pressed('mario_jump'):
      if !is_lerping:
        is_lerping = true
  if is_lerping:
    current_speed = lerp(current_speed, mario_fast_speed, 0.1 * Global.get_delta(delta))

  if $MarioPath/PathFollow2D.offset > stop_points[Global.levelID]:
    $MarioPath/PathFollow2D.offset = stop_points[Global.levelID]
    stopped = true
    
  if stopped and not fading_out:
    var pj = $ParallaxBackground/ParallaxLayer/PressJump
    if pj.modulate.a < 1:
      pj.modulate.a += 0.1 * Global.get_delta(delta)
    else:
      pj.modulate.a = 1
    var music_overlay = get_node_or_null('ParallaxBackground/Control')
    if music_overlay and music_overlay.get_node('AnimationPlayer').current_animation_position < 4.0:
      music_overlay.get_node('AnimationPlayer').seek(4)

  if Input.is_action_just_pressed('mario_jump') and !fading_out and stopped:
    fading_out = true
    var fadeout = $fadeout.duplicate()
    get_node('/root').add_child(fadeout)
    fadeout.play()
    MusicPlayer.fade_out(MusicPlayer.get_node('Main'), 2.0)
  
  if fading_out:
    circle_size -= 0.012 * Global.get_delta(delta)
    $ParallaxBackground/ParallaxLayer/Transition.visible = true
    $ParallaxBackground/ParallaxLayer/Transition.material.set_shader_param('circle_size', circle_size)
  else:
    $ParallaxBackground/ParallaxLayer/Transition.visible = false
    
  if circle_size <= -0.1:
    Global.goto_scene(level_scenes[Global.levelID])
    Global.Mario.invulnerable = false


