extends Node2D

## Critical combat information, not decoration: one bounded draw node survives
## the shared projectile/VFX cap. Never owns damage, timers, RNG or targets.
const MAX_TRACES := 12
const MAX_CONTACTS := 12
const MAX_WINDUPS := 12
const CONTACT_LIFE := 0.46
const TRACE_HOLD := 0.30
const PROJECTILES := {
	"physical": preload("res://assets/production/sprites/projectiles/proj_bullet_physical.png"),
	"fire": preload("res://assets/production/sprites/projectiles/proj_bullet_fire.png"),
	"ice": preload("res://assets/production/sprites/projectiles/proj_bullet_ice.png"),
	"lightning": preload("res://assets/production/sprites/projectiles/proj_bullet_lightning.png"),
	"poison": preload("res://assets/production/sprites/projectiles/proj_acid_spit.png"),
}
var traces: Array[Dictionary] = []
var contacts: Array[Dictionary] = []
var windups: Array[Dictionary] = []
var reduced := false

func _ready() -> void:
	z_as_relative = false
	z_index = 76 # Above the shield boundary, actors and player impact clutter.

func show_attack(origin: Vector2, target: Vector2, element: String, color: Color, heavy: bool, travel := 0.0, style := "bolt", arrival_contact := false) -> void:
	var entry := {"origin": origin, "target": target, "element": element,
		"color": color, "heavy": heavy, "travel": travel, "style": style,
		"arrival_contact": arrival_contact, "game_age": 0.0, "age": 0.0}
	# Repeated attacks along one route refresh instead of accumulating nodes.
	for i in range(traces.size()):
		if traces[i].element == element and traces[i].origin.distance_to(origin) < 32.0 and traces[i].target.distance_to(target) < 32.0:
			traces[i] = entry
			queue_redraw()
			return
	if traces.size() >= MAX_TRACES:
		traces.pop_front()
	traces.append(entry)
	queue_redraw()

func show_windup(origin: Vector2, target: Vector2, color: Color, duration: float, heavy: bool) -> void:
	var entry := {"origin": origin, "target": target, "color": color,
		"duration": maxf(0.04, duration), "heavy": heavy, "age": 0.0}
	for i in range(windups.size()):
		if windups[i].origin.distance_to(origin) < 32.0:
			windups[i] = entry
			queue_redraw()
			return
	if windups.size() >= MAX_WINDUPS:
		windups.pop_front()
	windups.append(entry)
	queue_redraw()

func show_contact(target: Vector2, element: String, color: Color, heavy: bool, blocked: bool) -> void:
	var entry := {"target": target, "element": element, "color": color,
		"heavy": heavy, "blocked": blocked, "age": 0.0}
	for i in range(contacts.size()):
		if contacts[i].element == element and contacts[i].target.distance_to(target) < 48.0:
			contacts[i] = entry
			queue_redraw()
			return
	if contacts.size() >= MAX_CONTACTS:
		contacts.pop_front()
	contacts.append(entry)
	queue_redraw()

func _process(delta: float) -> void:
	var had_feedback := not traces.is_empty() or not contacts.is_empty() or not windups.is_empty()
	var real_delta := delta / maxf(float(Engine.time_scale), 0.001)
	for i in range(windups.size() - 1, -1, -1):
		windups[i].age += delta
		if float(windups[i].age) >= float(windups[i].duration):
			windups.remove_at(i)
	for i in range(traces.size() - 1, -1, -1):
		traces[i].game_age += delta
		# Flight follows combat time; the residual route remains readable at 5x.
		if float(traces[i].game_age) >= float(traces[i].travel):
			if bool(traces[i].arrival_contact):
				var trace: Dictionary = traces[i]
				show_contact(trace.target, trace.element, trace.color, trace.heavy, false)
				traces[i].arrival_contact = false
			traces[i].age += real_delta
		if float(traces[i].age) >= TRACE_HOLD:
			traces.remove_at(i)
	for i in range(contacts.size() - 1, -1, -1):
		contacts[i].age += real_delta
		if float(contacts[i].age) >= CONTACT_LIFE:
			contacts.remove_at(i)
	if had_feedback:
		queue_redraw()

func _draw() -> void:
	for windup in windups:
		_draw_windup(windup)
	for trace in traces:
		_draw_trace(trace)
	for contact in contacts:
		_draw_contact(contact)

func _draw_windup(entry: Dictionary) -> void:
	var progress := clampf(float(entry.age) / float(entry.duration), 0.0, 1.0)
	var extent := lerpf(56.0, 88.0 if entry.heavy else 68.0, progress)
	CombatVfxArt.paint(self, "charge", to_local(entry.origin), Vector2(extent, extent * 1.15), progress * 0.58, 0.48 if reduced else 0.7, 0.0, false, entry.color)
	if entry.heavy:
		# A compact gathering wisp on the real barricade, never a reticle/ring.
		CombatVfxArt.paint(self, "charge", to_local(entry.target), Vector2(90, 56), progress * 0.5, 0.25 + progress * 0.22, 0.0, false, entry.color)

func _draw_trace(entry: Dictionary) -> void:
	var origin: Vector2 = to_local(entry.origin)
	var target: Vector2 = to_local(entry.target)
	var fade := 1.0 - smoothstep(0.1, TRACE_HOLD, float(entry.age))
	var travel := float(entry.travel)
	var progress := clampf(float(entry.game_age) / travel, 0.0, 1.0) if travel > 0.0 else 1.0
	var control := origin.lerp(target, 0.5)
	if entry.element == "poison":
		control.x += 52.0
	var head := origin * pow(1.0 - progress, 2.0) + control * 2.0 * (1.0 - progress) * progress + target * progress * progress
	var direction := (target - origin).normalized()
	var phase := clampf(float(entry.age) / TRACE_HOLD, 0.0, 1.0)
	if entry.style == "strike":
		# Short material sweep only at impact. A claw/slam is not a laser beam.
		CombatVfxArt.paint(self, "void" if CombatVfxArt.material_kind(entry.color) == "void" else entry.element, target + Vector2(0, -14), Vector2(150, 95) if entry.heavy else Vector2(88, 68), phase, 0.68 * fade)
		return
	if entry.style == "beam":
		CombatVfxArt.paint(self, entry.element, origin.lerp(target, 0.5), Vector2(origin.distance_to(target) * 1.22, 126 if entry.heavy else 72), phase, 0.75 * fade, direction.angle() + PI, true)
		return
	# A viscous curved wake follows the projectile, no outlined vector path.
	var segments := 3 if reduced else 5
	for i in range(segments):
		var t := maxf(0.0, progress - float(i) * 0.035)
		var point := origin * pow(1.0 - t, 2.0) + control * 2.0 * (1.0 - t) * t + target * t * t
		var tangent := (control - origin) * (1.0 - t) + (target - control) * t
		CombatVfxArt.paint(self, entry.element, point, Vector2(80 if entry.heavy else 58, 40 if entry.heavy else 29), phase, fade * (0.58 - float(i) * 0.08), tangent.angle() + PI, true)
	var texture: Texture2D = PROJECTILES.get(entry.element, PROJECTILES.physical)
	var size := Vector2(60, 60) if entry.heavy else Vector2(42, 42)
	draw_set_transform(head, direction.angle())
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO)

func _draw_contact(entry: Dictionary) -> void:
	var t := clampf(float(entry.age) / CONTACT_LIFE, 0.0, 1.0)
	var kind: String = "shield" if entry.blocked else str(entry.element)
	if not entry.blocked and CombatVfxArt.material_kind(entry.color) == "void":
		kind = "void"
	var extent := 204.0 if entry.heavy else 132.0
	var scale_mult := lerpf(0.85, 1.07, t)
	# Crossfade genuinely different material phases; late dust/splatter fades.
	CombatVfxArt.paint(self, kind, to_local(entry.target) + Vector2(0, -14), Vector2(extent, extent * 0.85) * scale_mult, t, 1.0 - smoothstep(0.62, 1.0, t))
