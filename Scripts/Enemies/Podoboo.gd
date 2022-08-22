extends Area2D


export var jump_strength: float = -10
export var timer: float = 250
export var time_offset: float = 0
export var apply_rotated_motion: bool = false
var remove_in_lava: bool = false # For volcano podoboo launchers

var counter: float = 0
var active: bool = false
var velocity := Vector2.ZERO
onready var firstpos = position

var inv_counter: float = 10
var camera: Camera2D = null

func _ready():
  z_index = 0
  counter = timer - time_offset

func _physics_process(delta):
  $CollisionShape2D.disabled = !active
  
  counter += 1 * Global.get_delta(delta)
  if active:
    position += velocity.rotated(rotation) * Global.get_delta(delta) # start y = -12.8
    
    if apply_rotated_motion:
      velocity += Vector2(0, 0.2).rotated(-rotation) * Global.get_delta(delta)
    else:
      velocity += Vector2(0, 0.2) * Global.get_delta(delta)
    
    # Hiding in lava
    if (velocity.y > 2 and !apply_rotated_motion) or (velocity.rotated(rotation).y > 2 and apply_rotated_motion):
      for i in get_overlapping_areas():
        if i.is_in_group('Lava'):
          lava_hide()
      camera = Global.current_camera
      if camera and position.y > camera.get_camera_screen_center().y + 260:
        lava_hide(true)

  elif counter > timer and !remove_in_lava: # Launching
    active = true
    velocity.x = 0
    velocity.y = jump_strength
    counter = 0
  

func _process(delta):
  # Animation
  if active:
    if apply_rotated_motion:
      $AnimatedSprite.flip_v = velocity.rotated(rotation).y > 0.2
      if velocity.rotated(rotation).y > 0.2:
        $AnimatedSprite.rotation = rotation * -2 if velocity.x > 0 else rotation * -2
      else:
        $AnimatedSprite.rotation = 0
    else:
      $AnimatedSprite.flip_v = velocity.y > 0.2
  
  visible = active
  if inv_counter < 10:
    inv_counter += 1 * Global.get_delta(delta)

  if Global.Mario.is_in_shoe and Global.Mario.shoe_type == 1:
    if Global.is_mario_collide_area('BottomDetector', self) and Global.Mario.velocity.y > 0:
      velocity += Vector2(0, 5).rotated(-rotation)
      inv_counter = 0
      Global.Mario.shoe_node.stomp()
      return
    elif Global.is_mario_collide_area('InsideDetector', self) and velocity.y > -8 and inv_counter > 8:
      Global._ppd()
  elif Global.is_mario_collide_area('InsideDetector', self):
    Global._ppd()

func lava_hide(hide_splash = false) -> void:
  if !hide_splash:
    var splash = preload('res://Scripts/Effects/LavaEffect.gd').new(position - Vector2(0, 24).rotated(rotation), -rotation if apply_rotated_motion else rotation)
    get_parent().add_child(splash)
  if remove_in_lava:
    queue_free()
    return
  active = false
  position = firstpos
  
