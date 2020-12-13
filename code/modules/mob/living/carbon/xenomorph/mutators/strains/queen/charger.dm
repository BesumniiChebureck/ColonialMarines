/datum/xeno_mutator/charger
	name = "STRAIN: Queen - More Crashing"
	description = "You are now a crasher Queen."
	flavor_description = "Time to crash everyone."
	cost = MUTATOR_COST_EXPENSIVE
	individual_only = TRUE
	caste_whitelist = list("Queen")
	mutator_actions_to_remove = list("")
	mutator_actions_to_add = list()
	behavior_delegate_type = /datum/behavior_delegate/queen_charger
	keystone = TRUE

/datum/xeno_mutator/charger/apply_mutator(datum/mutator_set/individual_mutators/MS)
	. = ..()
	if (. == 0)
		return

	var/mob/living/carbon/Xenomorph/Queen/Q = MS.xeno
	Q.speed_modifier += XENO_SPEED_FASTMOD_TIER_5
	Q.armor_modifier += XENO_ARMOR_MOD_VERYLARGE

	mutator_update_actions(Q)
	MS.recalculate_actions(description, flavor_description)

	Q.recalculate_everything()

	apply_behavior_holder(Q)
	Q.mutation_type = QUEEN_CHARGER

/datum/behavior_delegate/queen_charger
	name = "Queen Charge Behavior Delegate"