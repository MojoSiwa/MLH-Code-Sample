extends Effect
class_name DamageEffect

# Side-agnostic damage: always hits ctx.opponent, so it works unchanged whether
# the player is shooting a cryptid or a cryptid is clawing the player. Replaces
# the old DamageCryptidEffect / DamagePlayerEffect pair.
#
# Authoring:
#   base_damage    - flat damage, applied regardless of weapon
#   weapon_scaling - multiplier on ctx.weapon.total_damage(); 0 ignores the
#                    weapon entirely (use for cryptid claws, or a pistol whip
#                    that shouldn't scale with ammo buffs)
#
# Because it reads total_damage(), weapon buffs are included automatically —
# a lit machete's fire bonus needs no special casing here.

@export var base_damage: int = 0
@export var weapon_scaling: float = 0.0


# Deals the computed damage to the opposing combatant, crediting ctx.actor as
# the source so kill attribution and source-filtered effects work.
func apply(ctx: EffectContext) -> bool:
	if ctx.opponent == null:
		return false
	ctx.opponent.take_damage(_compute_damage(ctx), ctx.actor)
	return true


# Fills the live damage number into the authored description, so the inspector
# shows what this card would actually hit for with the current weapon and buffs
# rather than the base value.
func format_description(ctx: EffectContext = null) -> String:
	return description.format({"damage": _compute_damage(ctx)})


# Flat damage plus the weapon's buffed damage times weapon_scaling. Tolerates a
# null ctx/weapon (inspector previews with no play in progress), in which case
# only base_damage counts.
func _compute_damage(ctx: EffectContext) -> int:
	var dmg: float = base_damage
	if ctx != null and ctx.weapon != null:
		dmg += ctx.weapon.total_damage() * weapon_scaling
	return int(dmg)
