class_name Combatant
extends RefCounted

# Shared damage/heal pipeline for both combatants.
#
# Player (an autoload Node) and BaseCryptid (a Node2D with a data resource)
# can't share a base class — GDScript is single-inheritance and their bases
# differ. So the pipeline lives here as static helpers both hosts delegate to,
# keeping hp / signals / statuses on each host while the interceptor logic
# exists in exactly one place.
#
# Each host passes itself plus its own max_hp; the helper runs the GameBus
# interception and returns the resulting hp. The host stays responsible for
# storing that hp, emitting hp_changed/died, and holding its StatusList.


# Runs the damage interception pipeline and returns the hp the host should now
# have. Emits GameBus.damage_incoming with `host` as event.target, so listeners
# (traps, shields, future resistances) can filter by side and mutate or absorb
# the event before it lands. Returns current_hp unchanged when the damage is
# non-positive, fully absorbed, or reduced to zero — the host uses that to
# decide whether anything actually happened.
static func apply_damage(host: Object, current_hp: int, max_hp: int, amount: int, source: Object = null) -> int:
	if amount <= 0:
		return current_hp
	var event := DamageEvent.new()
	event.amount = amount
	event.source = source
	event.target = host
	GameBus.damage_incoming.emit(event)
	if event.absorbed:
		return current_hp
	var final_amount: int = max(0, event.amount)
	if final_amount == 0:
		return current_hp
	return max(0, current_hp - final_amount)


# Mirror of apply_damage for healing. Emits GameBus.heal_incoming so a future
# heal-block or heal-reduction effect has somewhere to hook in, then clamps the
# result to max_hp. Returns current_hp unchanged when the heal is non-positive,
# blocked, or reduced to zero.
static func apply_heal(host: Object, current_hp: int, max_hp: int, amount: int, source: Object = null) -> int:
	if amount <= 0:
		return current_hp
	var event := HealEvent.new()
	event.amount = amount
	event.source = source
	event.target = host
	GameBus.heal_incoming.emit(event)
	if event.blocked:
		return current_hp
	var final_amount: int = max(0, event.amount)
	if final_amount == 0:
		return current_hp
	return min(max_hp, current_hp + final_amount)
