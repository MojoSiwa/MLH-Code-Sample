extends WeaponComponent
class_name BuffableComponent

# Owns the temporary modifiers on its parent Weapon.
#
# Every weapon has one. Buffs are per-instance state living here on the node,
# never on the shared WeaponData — two copies of the same weapon must be able to
# hold different buffs.
#
# Buffs tick on the PLAYER's end phase specifically (not the cryptid's), so a
# "3 turn" buff means three of the player's turns.

var active_buffs: Array[WeaponBuff] = []


# Subscribes to the turn bus. Every buffable weapon listens independently, which
# is why the filter below has to be exact.
func _ready() -> void:
	GameBus.turn_phase.connect(_on_turn_phase)


# Ticks buffs down at the end of the player's turn only. Filtering on
# (PLAYER, END) is what makes buff durations count player turns rather than
# every phase of both sides.
func _on_turn_phase(side: GameBus.Side, phase: GameBus.Phase) -> void:
	if side == GameBus.Side.PLAYER and phase == GameBus.Phase.END:
		tick_buffs()


# Adds a buff. Duplicate prevention lives in BuffWeaponEffect.can_apply, not
# here — this just stores what it's given.
func add_buff(buff: WeaponBuff) -> void:
	active_buffs.append(buff)


# Counts every buff down one turn and drops the expired ones, revoking any
# runtime tag a buff was responsible for granting (the lit machete losing
# FLAMMABLE when its fire burns out).
#
# Iterates in reverse so removing an expired buff can't shift an index we
# haven't visited yet.
func tick_buffs() -> void:
	for i in range(active_buffs.size() - 1, -1, -1):
		active_buffs[i].remaining_turns -= 1
		if active_buffs[i].remaining_turns <= 0:
			var buff: WeaponBuff = active_buffs[i]
			if buff.removes_tag_on_expire:
				_remove_tag_on_parent(buff.expire_tag)
			active_buffs.remove_at(i)


# Sum of every active buff's damage bonus. Weapon.total_damage() adds this to
# the authored base damage, which is how buffs reach every damage calculation
# without any effect knowing buffs exist.
func total_damage_bonus() -> int:
	var total: int = 0
	for buff in active_buffs:
		total += buff.damage_bonus
	return total


# Asks the sibling TaggableComponent to drop a tag an expiring buff granted.
# Goes through the parent weapon rather than assuming a sibling exists, so a
# weapon without a TaggableComponent simply no-ops instead of crashing.
func _remove_tag_on_parent(tag: Tags.Tag) -> void:
	var weapon: Weapon = get_parent() as Weapon
	if weapon == null:
		return
	var taggable: TaggableComponent = weapon.get_component(TaggableComponent)
	if taggable == null:
		return
	taggable.remove_runtime_tag(tag)
