extends Node

var camera = Global.Mario.get_node('Camera')
var throw_script
var throw_delay
var lakitu_addon
var result
var time
var lakitu = load('res://Objects/Enemies/Lakito.tscn').instance()

func _ready() -> void:
  time = get_tree().create_timer(7.0, false)
  time.connect('timeout', self, 'newlakitu')

func newlakitu():
  lakitu.vars['throw_script'] = throw_script
  lakitu.vars['throw_delay'] = throw_delay
  lakitu.vars['lakitu_addon'] = lakitu_addon
  if result: lakitu.vars['result'] = result
  lakitu.position = Vector2(camera.global_position.x + 520, camera.limit_top + 72 + rand_range(-16, 16))
  get_parent().add_child(lakitu)
