/datum/job/command/tank_crew
	title = JOB_CREWMAN
	total_positions = 2
	spawn_positions = 2
	allow_additional = 1
	scaled = 0
	flags_startup_parameters = ROLE_ADD_TO_DEFAULT|ROLE_ADD_TO_MODE|ROLE_WHITELISTED
	flags_whitelist = WHITELIST_CREWMAN
	gear_preset = "USCM Vehicle Crewman (CRMN) (Cryo)"

/datum/job/command/tank_crew/New()
	. = ..()
	gear_preset_whitelist = list(
		"[JOB_CREWMAN][WHITELIST_NORMAL]" = "USCM Vehicle Crewman (CRMN)",
		"[JOB_CREWMAN][WHITELIST_COUNCIL]" = "USCM Vehicle Capitan (CRMN+)",
		"[JOB_CREWMAN][WHITELIST_LEADER]" = "USCM Vehicle Commander (CRMN++)"
	)

/datum/job/command/tank_crew/get_whitelist_status(var/list/roles_whitelist, var/client/player)
	. = ..()
	if(!.)
		return

	if(roles_whitelist[player.ckey] & WHITELIST_CREWMAN_LEADER)
		return get_desired_status(player.prefs.vc_status, WHITELIST_LEADER)
	else if(roles_whitelist[player.ckey] & WHITELIST_CREWMAN_COUNCIL)
		return get_desired_status(player.prefs.vc_status, WHITELIST_COUNCIL)
	else if(roles_whitelist[player.ckey] & WHITELIST_CREWMAN)
		return get_desired_status(player.prefs.vc_status, WHITELIST_NORMAL)

/datum/job/command/tank_crew/generate_entry_message(mob/living/carbon/human/H)
	entry_message_body = "Your job is to operate and maintain the ship's armored vehicles. You are in charge of representing the armored presence amongst the marines during the operation, as well as maintaining and repairing your own tank."
	return ..()

AddTimelock(/datum/job/command/tank_crew, list(
	JOB_SQUAD_ROLES = 10 HOURS,
	JOB_ENGINEER_ROLES = 5 HOURS
))

/obj/effect/landmark/start/tank_crew
	name = JOB_CREWMAN
	job = /datum/job/command/tank_crew
