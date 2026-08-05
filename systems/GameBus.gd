extends Node

# Centralized event bus for cross-system signals.
# Autoload registered as `GameBus` in project.godot.
#
# Mechanics that react to game events subscribe here instead of being
# hard-wired into CombatManager / Player / BaseCryptid. New mechanics
# become "one new file that connects to a signal" rather than "five files
# touched."


# Which side of the table an event concerns.
enum Side { PLAYER, CRYPTID }

# The five beats of every turn, emitted in order by CombatManager:
#   DRAW -> STANDBY -> PLAY -> ONGOING -> END
#   STANDBY = entity status effects (DoTs) tick
#   ONGOING = board cards resolve (hexes fire, durations tick down)
#   END     = weapon buffs tick
enum Phase { DRAW, STANDBY, PLAY, ONGOING, END }


# --- Turn phase signal ---
# One signal for every beat; listeners filter on (side, phase).
# CombatManager.emit_phase(side, phase) is the single emit path.
signal turn_phase(side: Side, phase: Phase)


# --- Card lifecycle ---
# Fired by CardManager when a card resolves or a weapon equip state changes.
# Useful for reactive cards ("when a weapon is equipped, draw 1") and HUD.
signal card_played(card, context)
signal weapon_equipped(weapon)
signal weapon_unequipped(weapon)


# --- Interceptable damage ---
# Fired by Combatant.apply_damage BEFORE the HP change is applied. Listeners
# receive the DamageEvent and may:
#   - reduce/increase event.amount
#   - set event.absorbed = true to fully prevent the damage
# event.target identifies which combatant is being hit, so a single listener
# can serve either side.
#
# If absorbed is true after all listeners run, no HP change occurs.
# Otherwise, max(0, event.amount) damage is applied to the target.
signal damage_incoming(event: DamageEvent)


# --- Interceptable healing ---
# Mirrors damage_incoming. Fired by Combatant.apply_heal BEFORE HP is restored.
# Listeners may reduce/increase event.amount or set event.blocked = true.
signal heal_incoming(event: HealEvent)
