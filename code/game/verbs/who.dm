/client/verb/who()
	set name = "Who"
	set category = "OOC"

	var/list/counted_humanoids = list(
							"Observers" = 0,
							"Admin observers" = 0,
							"Humans" = 0,
							"Infected humans" = 0,
							FACTION_MARINE = 0,
							"USCM Marines" = 0,
							"Lobby" = 0,

							FACTION_YAUTJA = 0,
							"Infected preds" = 0,

							FACTION_PMC = 0,
							FACTION_CLF = 0,
							FACTION_UPP = 0,
							FACTION_FREELANCER = 0,
							FACTION_SURVIVOR = 0,
							FACTION_DEATHSQUAD = 0,
							FACTION_COLONIST = 0,
							FACTION_MERCENARY = 0,
							FACTION_DUTCH = 0,
							FACTION_HEFA = 0,
							FACTION_GLADIATOR = 0,
							FACTION_PIRATE = 0,
							FACTION_PIZZA = 0,
							FACTION_SOUTO = 0,

							FACTION_NEUTRAL = 0,

							FACTION_ZOMBIE = 0
							)

	var/list/counted_xenos = list(0,0,0,0,0,0)

	var/body = "<b>Current Players:</b><br>"
	var/list/Lines = list()
	if(admin_holder && ((R_ADMIN & admin_holder.rights) || (R_MOD & admin_holder.rights)))
		for(var/client/C in GLOB.clients)
			var/entry = "[C.key]"
			if(C.mob)	//Juuuust in case
				if(istype(C.mob, /mob/new_player))
					entry += " - In Lobby"
					counted_humanoids["Lobby"]++
				else
					entry += " - Playing as [C.mob.real_name]"

				if(isobserver(C.mob))
					counted_humanoids["Observers"]++
					if(C.admin_holder)
						counted_humanoids["Admin observers"]++
						counted_humanoids["Observers"]--
					var/mob/dead/observer/O = C.mob
					if(O.started_as_observer)
						entry += " - <font color='#777'>Observing</font>"
					else
						entry += " - <font color='#000'><b>DEAD</b></font>"
				else
					switch(C.mob.stat)
						if(UNCONSCIOUS)
							entry += " - <font color='#404040'><b>Unconscious</b></font>"
						if(DEAD)
							entry += " - <font color='#000'><b>DEAD</b></font>"

					if(C.mob && C.mob.stat != DEAD)
						if(ishuman(C.mob))
							if(C.mob.faction == FACTION_ZOMBIE)
								counted_humanoids[FACTION_ZOMBIE]++
								continue
							if(C.mob.faction == FACTION_YAUTJA)
								counted_humanoids[FACTION_YAUTJA]++
								if(C.mob.status_flags & XENO_HOST)
									counted_humanoids["Infected preds"]++
								continue
							counted_humanoids["Humans"]++
							if(C.mob.status_flags & XENO_HOST)
								counted_humanoids["Infected humans"]++
							if(C.mob.faction == FACTION_MARINE)
								counted_humanoids[FACTION_MARINE]++
								if(C.mob.job in (ROLES_MARINES))
									counted_humanoids["USCM Marines"]++
							else
								counted_humanoids[C.mob.faction]++
						if(isXeno(C.mob))
							var/mob/living/carbon/Xenomorph/X = C.mob
							if(X.hivenumber > 0 && X.hivenumber <= 5)	//hard check to prevent admin version of who runtiming from non-standard hivenumbers created by bugs/admins
								counted_xenos[X.hivenumber]++
							if(X.faction == FACTION_PREDALIEN)
								counted_xenos[6]++
							entry += " - <b><font color='red'>Xenomorph</font></b>"

				entry += " (<A HREF='?_src_=admin_holder;ahelp=adminplayeropts;extra=\ref[C.mob]'>?</A>)"
				Lines += entry

		for(var/line in sortList(Lines))
			body += "[line]<br>"
		body += "<b>Total Players: [length(Lines)]</b>"
		body += "<br><b style='color:#777'>In Lobby: [counted_humanoids["Lobby"]]</b>"
		body += "<br><b style='color:#777'>Observers: [counted_humanoids["Observers"]] players and [counted_humanoids["Admin observers"]] staff members</b>"
		body += "<br><b style='color:#2C7EFF'>Humans: [counted_humanoids["Humans"]]</b> <b style='color:#F00'>(Infected: [counted_humanoids["Infected humans"]])</b>"
		if(counted_humanoids[FACTION_MARINE])
			body += "<br><b style='color:#2C7EFF'>USCM personnel: [counted_humanoids[FACTION_MARINE]]</b> <b style='color:#688944'>(Squad Marines: [counted_humanoids["USCM Marines"]])</b>"
		if(counted_humanoids[FACTION_YAUTJA])
			body += "<br><b style='color:#7ABA19'>Predators: [counted_humanoids[FACTION_YAUTJA]]</b> [counted_humanoids["Infected preds"] ? "<b style='color:#F00'>(Infected: [counted_humanoids["Infected preds"]])</b>" : ""]"

		var/show_fact = TRUE
		for(var/i in 10 to LAZYLEN(counted_humanoids) - 2)
			if(counted_humanoids[counted_humanoids[i]])
				if(show_fact)
					body += "<br><br>Other factions:"
					show_fact = FALSE
				body += "<br><b style='color:#2C7EFF'>[counted_humanoids[i]]: [counted_humanoids[counted_humanoids[i]]]</b>"
		if(counted_humanoids[FACTION_NEUTRAL])
			body += "<br><b style='color:#777'>[FACTION_NEUTRAL] humans: [counted_humanoids[FACTION_NEUTRAL]]</b>"

		show_fact = TRUE
		var/datum/hive_status/hive
		for(var/i = 1;i < LAZYLEN(counted_xenos); i++)
			if(counted_xenos[i])
				if(show_fact)
					body += "<br><br>Xenomorphs:"
					show_fact = FALSE
				hive = hive_datum[i]
				if(hive)
					body += "<br><b style='color:[hive.color ? hive.color : "#8200FF"]'>[hive.name]: [counted_xenos[i]]</b> <b style='color:#4D0096'>(Queen: [hive.living_xeno_queen ? "Alive" : "Dead"])</b>"
				else
					body += "<br><b style='color:#F00'>Error: no hive datum detected for [counted_xenos[i]]s Hive.</b>"
				hive = null
		if(counted_xenos[6])
			body += "<br><b style='color:#7ABA19'>Predaliens: [counted_xenos[6]]</b>"

	else
		for(var/client/C in GLOB.clients)
			if(C.admin_holder && C.admin_holder.fakekey)
				continue

			Lines += C.key
		for(var/line in sortList(Lines))
			body += "[line]<br>"
		body += "<b>Total Players: [length(Lines)]</b><br>"

	var/datum/browser/browser = new(usr, "who", "<div align='center'>Who</div>", 1200, 1500)
	browser.set_content(body)
	browser.open()



/client/verb/staffwho()
	set name = "Staffwho"
	set category = "OOC"

	var/body = ""
	var/modbody = ""
	var/mentbody = ""
	var/num_mods_online = 0
	var/num_admins_online = 0
	var/num_mentors_online = 0

	if(admin_holder && !AHOLD_IS_ONLY_MENTOR(admin_holder))
		for(var/client/C in GLOB.admins)
			if(AHOLD_IS_ADMIN(C.admin_holder))	//Used to determine who shows up in admin rows
				body += "[C] is a [C.admin_holder.rank]"

				if(C.admin_holder.fakekey)
					body += " <i>(HIDDEN)</i>"

				if(isobserver(C.mob))
					body += " - Observing"
				else if(istype(C.mob,/mob/new_player))
					body += " - Lobby"
				else
					body += " - Playing"

				if(C.is_afk())
					body += " (AFK)"
				body += "<br>"

				num_admins_online++
			else if(AHOLD_IS_MOD(C.admin_holder))				//Who shows up in mod/mentor rows.
				modbody += "[C] is a [C.admin_holder.rank]"

				if(C.admin_holder.fakekey)
					modbody += " <i>(HIDDEN)</i>"

				if(isobserver(C.mob))
					modbody += " - Observing"
				else if(istype(C.mob,/mob/new_player))
					modbody += " - Lobby"
				else
					modbody += " - Playing"

				if(C.is_afk())
					modbody += " (AFK)"
				modbody += "<br>"
				num_mods_online++

			else if(AHOLD_IS_MENTOR(C.admin_holder))
				mentbody += "\t[C] is a [C.admin_holder.rank]"

				if(C.is_afk())
					mentbody += " (AFK)"
				mentbody += "<br>"

				num_mentors_online++

	else
		for(var/client/C in GLOB.admins)
			if(AHOLD_IS_ADMIN(C.admin_holder))
				if(C.admin_holder.fakekey)
					continue

				body += "[C] is a [C.admin_holder.rank]<br>"
				num_admins_online++
			else if (AHOLD_IS_MOD(C.admin_holder))
				if(C.admin_holder.fakekey)
					continue

				modbody += "[C] is a [C.admin_holder.rank]<br>"
				num_mods_online++
			else if (AHOLD_IS_MENTOR(C.admin_holder))
				mentbody += "[C] is a [C.admin_holder.rank]<br>"
				num_mentors_online++

	body = "<b>Current Admins ([num_admins_online]):</b><br>" + body

	if(CONFIG_GET(flag/show_mods))
		body += "<b> Current Moderators ([num_mods_online]):</b><br>" + modbody

	if(CONFIG_GET(flag/show_mentors))
		body += "<b> Current Mentors ([num_mentors_online]):</b><br>" + mentbody

	var/datum/browser/browser = new(usr, "Staffwho", "<div align='center'>Staffwho</div>", 1200, 1500)
	browser.set_content(body)
	browser.open()