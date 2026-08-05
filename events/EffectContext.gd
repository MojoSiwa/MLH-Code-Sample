extends RefCounted
class_name EffectContext

# Per-play bundle handed to every Effect. Built fresh by whoever is acting
# (CardManager.build_player_context for the player, BaseCryptid.build_context
# for the cryptid) and thrown away after.
#
# This is what makes effects side-agnostic. An effect reads ctx.opponent instead
# of reaching for a global, so one DamageEffect resource serves the player
# shooting a cryptid AND the cryptid clawing the player — who gets hit depends
# entirely on who built the context.
#
# It's also what keeps play state OFF the shared effect resources. Effects are
# .tres files shared by reference; anything per-play written onto one would leak
# between plays. It lives here instead, in an object that dies with the play.
#
# actor / opponent are untyped on purpose: Player is an autoload Node and
# BaseCryptid is a Node2D, and GDScript is single-inheritance, so they can't
# share a base class. They share the damage/heal pipeline instead (see
# Combatant), and both expose take_damage() / heal() / statuses — which is all
# an effect needs.

var actor = null            # who is playing the card (Player autoload or a BaseCryptid)
var opponent = null         # the other combatant
var weapon: Weapon = null   # the acting Weapon; null for empty hand / cryptid plays
var target: BaseCard = null # pre-resolved target, set by the pipeline when requires_targeting()
