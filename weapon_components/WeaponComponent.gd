class_name WeaponComponent
extends Node

# Base class for weapon capability components.
# Components live as child nodes of a Weapon scene and own state/behavior
# for a specific capability (buffs, runtime tags, traps, etc.).
#
# Weapons access components via Weapon.get_component(type) which iterates
# children and matches by class.


# Override to true whenever this component's current state means the
# weapon's on_turn_start_card should NOT spawn this turn (e.g. an armed
# trap). Weapon.can_spawn_turn_start_card() asks every component this
# question generically, so a new blocking component never requires
# touching Weapon or CombatManager.
func blocks_turn_start_card() -> bool:
	return false
