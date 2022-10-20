extends Brain

var speed_modifier: float = 0
var speed: float = 162.5
var temp: bool = false
var old_rotation: float = 0
var inv_counter: float = 0

func _setup(b)-> void:
	._setup(b)
# warning-ignore:return_value_discarded
	owner.get_node(owner.vars['hitbox']).connect('area_entered',self,"_on_hitbox_enter")
	owner.animated_sprite.flip_v = owner.rotation > 0.5

func _ai_process(delta: float) -> void:
	._ai_process(delta)
	if owner.velocity.y < 0:
		owner.velocity.y = 0
	
	if !Global.is_getting_closer(-300, owner.position):
		owner.queue_free()
	
	owner.velocity.x = (speed - speed_modifier) * owner.dir
	if inv_counter < 7:
		inv_counter += 1 * Global.get_delta(delta)
	if !owner.alive:
		owner.gravity_scale = 0.8
		owner.velocity.y += Global.gravity * owner.gravity_scale * Global.get_delta(delta)
		if !temp:
			speed = owner.velocity.rotated(old_rotation).x * owner.dir
			#owner.animated_sprite.flip_v = false
			temp = true
		#owner.animated_sprite.flip_h = owner.velocity.rotated(old_rotation).x * -owner.dir < 0
		if speed_modifier < speed:
			speed_modifier += speed * 0.002
		return
	old_rotation = owner.rotation
	owner.animated_sprite.flip_h = owner.dir < 0

func _on_hitbox_enter(a) -> void:
	if !owner.alive:
		return
	if a.name == 'BottomDetector' and !owner.invincible:
		inv_counter = 0
		Global.Mario.enemy_stomp()
		owner.call_deferred('kill', AliveObject.DEATH_TYPE.FALL)
		return
	elif a.name == 'InsideDetector' and inv_counter > 5:
		Global._ppd()
