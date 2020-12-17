/datum/xeno_mutator/powder
	name = "STRAIN: Queen - More Power"
	description = "You are now a very... very strong and slower, you don't can more screech Queen. Don't go mutation on ovi, and u no can more grow ovipositor"
	flavor_description = "You are the Stronger now."
	cost = MUTATOR_COST_EXPENSIVE
	individual_only = TRUE
	caste_whitelist = list("Queen")
	mutator_actions_to_remove = list("Screech (250)", "Grow Ovipositor (500)")
	mutator_actions_to_add = list()
	behavior_delegate_type = /datum/behavior_delegate/powder_queen
	keystone = TRUE

/datum/xeno_mutator/powder/apply_mutator(datum/mutator_set/individual_mutators/MS)
	. = ..()
	if (. == 0)
		return

	var/mob/living/carbon/Xenomorph/Queen/Q = MS.xeno
	Q.speed_modifier += XENO_SPEED_SLOWMOD_TIER_12
	Q.health_modifier += XENO_HEALTH_MOD_OVERLARGE
	Q.damage_modifier += XENO_DAMAGE_MOD_OVERLARGE
	Q.explosivearmor_modifier -= XENO_EXPOSIVEARMOR_MOD_LARGE
	Q.claw_type = CLAW_TYPE_VERY_SHARP

	mutator_update_actions(Q)
	MS.recalculate_actions(description, flavor_description)

	Q.recalculate_everything()

	apply_behavior_holder(Q)
	Q.mutation_type = QUEEN_POWDER

/datum/behavior_delegate/powder_queen
	name = "Queen Power Behavior Delegate"