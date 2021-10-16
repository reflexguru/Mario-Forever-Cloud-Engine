extends Brain

func _setup(b)-> void:
  ._setup(b)
  owner.get_node(owner.vars['hitbox']).connect('area_entered',self,"_on_hitbox_enter")

func _ai_process(delta: float) -> void:
  ._ai_process(delta)
  if owner.velocity.y < 0:
    owner.velocity.y = 0
  if !owner.alive:
    owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
    owner.vars["speed"] -= owner.vars["speed"] * 0.01 * Global.get_delta(delta)
  owner.velocity.x = owner.vars["speed"] * owner.dir
  
  owner.animated_sprite.flip_h = owner.dir < 0

func _on_hitbox_enter(a) -> void:
  if !owner.alive:
    return
  if a.name == 'InsideDetector':
    Global._ppd()
  elif a.name == 'BottomDetector':
    if Input.is_action_pressed('mario_jump'):
      Global.Mario.velocity.y = -(owner.vars['bounce'] + 5) * 50
    else:
      Global.Mario.velocity.y = -owner.vars['bounce'] * 50
    owner.kill(AliveObject.DEATH_TYPE.FALL)
