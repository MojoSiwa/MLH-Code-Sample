extends WeaponComponent
class_name TrapComponent

# Owns the armed state of a trap weapon (currently just the bear trap).
#
# The whole point of this class: TrapEffect is a shared resource, so it can't
# remember that it's armed. This component — a node, one per weapon instance —
# holds which effect is armed, which signal triggers it, and the context
# captured at arm time. Two armed traps can therefore never collide.
#
# Only the component subscribes to the trigger; it calls the effect's spring
# logic directly. That means exactly one connection, whose receiver is this
# node, so Godot auto-disconnects it if the weapon is freed.
#
# The trigger is the side-agnostic GameBus.damage_incoming. The component filters
# by ctx.opponent, so a player's trap fires on cryptid hits and a cryptid's trap
# would fire on player hits — no per-side signal, no per-side effect class.

enum STATES {IDLE, ARMED, SPRUNG}

var state = STATES.IDLE
var effect: TrapEffect = null
var trigger: Signal
var ctx: EffectContext = null


# Listens for its weapon being unequipped. Without this, arming a bear trap and
# then stowing it in the backpack would leave it absorbing hits from inside the
# bag.
func _ready() -> void:
	GameBus.weapon_unequipped.connect(_on_weapon_unequipped)


# Disarms when the unequipped weapon is this component's own parent. Every trap
# component hears every unequip, so the identity check is what keeps one trap
# from disarming another.
func _on_weapon_unequipped(weapon) -> void:
	if weapon == get_parent():
		disarm()


# Arms the trap: stores what to fire, what fires it, and the context to fire it
# with, then subscribes. Only legal from IDLE or SPRUNG — an already-armed trap
# ignores re-arming rather than silently replacing its own state.
func arm(new_effect: TrapEffect, new_trigger: Signal, new_ctx: EffectContext) -> void:
	if state == STATES.IDLE or state == STATES.SPRUNG:
		state = STATES.ARMED
		effect = new_effect
		trigger = new_trigger
		ctx = new_ctx
		trigger.connect(spring)


# Trigger handler. Ignores anything not aimed at the side this trap punishes —
# that filter is what keeps a player's own bleed from setting off their own
# bear trap.
#
# Local copies of effect/ctx are taken before clearing state so the trap is
# fully disarmed BEFORE the effect runs. Otherwise spring() dealing damage could
# re-enter this handler while it's still armed.
func spring(event) -> void:
	if state != STATES.ARMED:
		return
	if ctx != null and event.target != ctx.opponent:
		return
	state = STATES.SPRUNG
	var sprung_effect: TrapEffect = effect
	var sprung_ctx: EffectContext = ctx
	trigger.disconnect(spring)
	effect = null
	ctx = null
	sprung_effect.spring(event, sprung_ctx)


# Cancels an armed trap without firing it, returning it to IDLE so it can be
# armed again later. Called when the weapon leaves the player's hands.
func disarm() -> void:
	if state == STATES.ARMED:
		state = STATES.IDLE
		trigger.disconnect(spring)
		effect = null
		ctx = null


# Stops the weapon's turn-start card (the "Arm Bear Trap" card) from spawning
# while the trap is already armed — a second copy would do nothing but clutter
# the hand. Overrides the WeaponComponent hook, which Weapon asks generically.
func blocks_turn_start_card() -> bool:
	return state == STATES.ARMED
