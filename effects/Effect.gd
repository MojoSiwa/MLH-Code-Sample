extends Resource
class_name Effect

# Base class for everything a card DOES. One Effect answers all four questions
# the game asks about a card: what happens, whether it's legal right now, what
# text to show, and how to pick a target.
#
# Effects are STATELESS shared resources — Godot hands the same .tres instance
# to every card referencing it, so writing per-play state onto `self` would let
# two plays corrupt each other. Everything situational arrives through the
# EffectContext built fresh by the play pipeline (CardManager for the player,
# BaseCryptid for the cryptid):
#   ctx.actor    - who is playing the card
#   ctx.opponent - the other combatant
#   ctx.weapon   - the acting Weapon, or null (empty hand / cryptid plays)
#   ctx.target   - the pre-resolved target, when requires_targeting() is true
#
# Because effects read the context instead of reaching for globals, the same
# effect works from either side of the table.

@export_multiline var description: String = ""


# Performs the effect. Returns true on success, false if the context was
# invalid or nothing happened — the pipeline uses that to decide whether to
# charge the action cost.
func apply(_ctx: EffectContext) -> bool:
	return true


# Whether this effect is legal in this context right now. Called both before a
# play attempt and by the inspector to grey out buttons, so the player sees the
# same rule the engine enforces.
func can_apply(_ctx: EffectContext) -> bool:
	return true


# Player-facing text for the inspector. ctx may be null (inspecting a cryptid's
# card, where there's no play in progress), so implementations must tolerate it.
# Subclasses format live numbers into `description` here.
func format_description(_ctx: EffectContext = null) -> String:
	return description


# Why can_apply() said no. Shown by the inspector under a disabled button.
func unavailable_reason(_ctx: EffectContext) -> String:
	return ""


# Whether this effect needs the player to click something. If true, CardManager
# resolves the target BEFORE calling apply() and puts it in ctx.target — effects
# never talk to the input system themselves, which is what keeps them usable by
# the AI and testable without a mouse.
func requires_targeting() -> bool:
	return false


# Whether a clicked card is a legal target for this effect. Called by the
# targeting loop on each click; only used when requires_targeting() is true.
func is_valid_target(_card, _ctx: EffectContext) -> bool:
	return false
