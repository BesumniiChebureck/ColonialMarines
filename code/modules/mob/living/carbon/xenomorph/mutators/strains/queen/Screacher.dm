/datum/xeno_mutator/screecher
	name = "STRAIN: Queen - Screech go better"
	description = "You now have very strong screech. Don't go mutation on ovi, and u no can more grow ovipositor"
	flavor_description = "You are the Stronger now."
	cost = MUTATOR_COST_EXPENSIVE
	individual_only = TRUE
	caste_whitelist = list("Queen")
	mutator_actions_to_remove = list("Screech (250)", "Grow Ovipositor (500)")
	mutator_actions_to_add = list(/datum/action/xeno_action/activable/screeche)
	behavior_delegate_type = /datum/behavior_delegate/screecher_queen
	keystone = TRUE

/datum/xeno_mutator/screecher/apply_mutator(datum/mutator_set/individual_mutators/MS)
	. = ..()
	if (. == 0)
		return

	var/mob/living/carbon/Xenomorph/Queen/Q = MS.xeno
	Q.speed_modifier += XENO_SPEED_SLOWMOD_TIER_11
	Q.damage_modifier += XENO_DAMAGE_MOD_LARGE
	Q.health_modifier -= XENO_HEALTH_MOD_LARGE
	Q.explosivearmor_modifier -= XENO_EXPOSIVEARMOR_MOD_LARGE
	Q.phero_modifier += XENO_PHERO_MOD_VERYLARGE
	Q.plasmapool_modifier += XENO_PLASMAPOOL_MOD_OVERLARGE

	mutator_update_actions(Q)
	MS.recalculate_actions(description, flavor_description)

	Q.recalculate_everything()

	apply_behavior_holder(Q)
	Q.mutation_type = QUEEN_SCREECHER

/datum/behavior_delegate/screecher_queen
	name = "Queen Screacher Behavior Delegate"