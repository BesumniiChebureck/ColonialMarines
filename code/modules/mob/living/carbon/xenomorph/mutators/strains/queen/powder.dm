/datum/xeno_mutator/powder
	name = "STRAIN: Queen - More Power"
	description = "You are now a over powered Queen."
	flavor_description = "You are the Power."
	cost = MUTATOR_COST_EXPENSIVE
	individual_only = TRUE
	caste_whitelist = list("Queen")
	mutator_actions_to_remove = list("")
	mutator_actions_to_add = list()
	behavior_delegate_type = /datum/behavior_delegate/queen_powder
	keystone = TRUE

/datum/xeno_mutator/powder/apply_mutator(datum/mutator_set/individual_mutators/MS)
	. = ..()
	if (. == 0)
		return

	var/mob/living/carbon/Xenomorph/Queen/Q = MS.xeno
	Q.speed_modifier += XENO_SPEED_SLOWMOD_TIER_11
	Q.health_modifier += XENO_HEALTH_MOD_OVERLARGE
	Q.armor_modifier += XENO_ARMOR_MOD_OVERLARGE
	Q.damage_modifier += XENO_DAMAGE_MOD_OVERLARGE
	Q.claw_type = CLAW_TYPE_VERY_SHARP

	mutator_update_actions(Q)
	MS.recalculate_actions(description, flavor_description)

	Q.recalculate_everything()

	apply_behavior_holder(Q)
	Q.mutation_type = QUEEN_POWDER

/datum/behavior_delegate/queen_powder
	name = "Queen Power Behavior Delegate"