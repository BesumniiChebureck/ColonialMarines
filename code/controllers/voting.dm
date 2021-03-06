var/datum/controller/vote/vote = new()

datum/controller/vote
	var/initiator = null
	var/started_time = null
	var/time_remaining = 0
	var/mode = null
	var/question = null
	var/list/choices = list()
	var/list/voted = list()
	var/list/voting = list()
	var/list/current_votes = list()
	var/list/additional_text = list()
	var/auto_muted = 0

	New()
		if(vote != src)
			if(istype(vote))
				qdel(vote)
			vote = src

	process()	//called by master_controller
		if(mode)
			// No more change mode votes after the game has started.
			// 3 is GAME_STATE_PLAYING, but that #define is undefined for some reason
			if(mode == "gamemode" && SSticker.current_state >= GAME_STATE_SETTING_UP)
				to_world("<b>Voting aborted due to game start.</b>")
				src.reset()
				return

			// Calculate how much time is remaining by comparing current time, to time of vote start,
			// plus vote duration
			time_remaining = round((started_time + CONFIG_GET(number/vote_period) - world.time)/10)

			if(time_remaining < 0)
				result()
				for(var/client/C in voting)
					if(C)
						close_browser(C,"vote")
				reset()
			else
				for(var/client/C in voting)
					if(C)
						show_browser(C, vote.interface(C), "Vote", "vote", "can_close=0")

				voting.Cut()

	proc/autogamemode()
		initiate_vote("gamemode","the server")
		log_debug("The server has called a gamemode vote")

	proc/reset()
		initiator = null
		time_remaining = 0
		mode = null
		question = null
		choices.Cut()
		voted.Cut()
		voting.Cut()
		current_votes.Cut()
		additional_text.Cut()

	/*	if(auto_muted && !ooc_allowed)
			auto_muted = 0
			ooc_allowed = !( ooc_allowed )
			to_world("<b>The OOC channel has been automatically enabled due to vote end.</b>")
			log_admin("OOC was toggled automatically due to vote end.")
			message_admins("OOC has been toggled on automatically.")
	*/

	proc/get_result()
		//get the highest number of votes
		var/greatest_votes = 0
		var/total_votes = 0
		for(var/option in choices)
			var/votes = choices[option]
			total_votes += votes
			if(votes > greatest_votes)
				greatest_votes = votes
		//default-vote for everyone who didn't vote
		if(!CONFIG_GET(flag/vote_no_default) && choices.len)
			var/non_voters = (GLOB.clients.len - total_votes)
			if(non_voters > 0)
				if(mode == "restart")
					choices["Continue Playing"] += non_voters
					if(choices["Continue Playing"] >= greatest_votes)
						greatest_votes = choices["Continue Playing"]
				else if(mode == "gamemode")
					if(choices[master_mode])
						choices[master_mode] += non_voters
						if(choices[master_mode] >= greatest_votes)
							greatest_votes = choices[master_mode]


		//get all options with that many votes and return them in a list
		. = list()
		if(greatest_votes)
			for(var/option in choices)
				if(choices[option] == greatest_votes)
					. += option
		return .

	proc/announce_result()
		var/list/winners = get_result()
		var/text
		if(winners.len > 0)
			if(winners.len > 1)
				if(mode != "gamemode") // Here we are making sure we don't announce potential game modes
					text = "<b>Vote Tied Between:</b>\n"
					for(var/option in winners)
						text += "\t[option]\n"
			. = pick(winners)

			if((mode == "gamemode" && . == "extended")) // Announce Extended gamemode, but not other gamemodes
				text += "<b>Vote Result: [.]</b>"
			else
				if(mode != "gamemode")
					text += "<b>Vote Result: [.]</b>"
				else
					text += "<b>The vote has ended.</b>" // What will be shown if it is a gamemode vote that isn't extended

		else
			text += "<b>Vote Result: Inconclusive - No Votes!</b>"
		log_vote(text)
		to_world("<font color='purple'>[text]</font>")
		return .

	proc/result()
		. = announce_result()
		var/restart = 0
		if(.)
			switch(mode)
				if("restart")
					if(. == "Restart Round")
						restart = 1
				if("gamemode")
					if(master_mode != .)
						world.save_mode(.)
						if(SSticker && SSticker.mode)
							restart = 1
						else
							master_mode = .

		if(mode == "gamemode") //fire this even if the vote fails.
			if(!going)
				going = 1
				to_world("<font color='red'><b>The round will start soon.</b></font>")

		if(restart)
			to_world("World restarting due to vote...")
			sleep(50)
			log_game("Rebooting due to restart vote")
			world.Reboot()

		return .

	proc/submit_vote(var/ckey, var/vote)
		if(mode)
			if(CONFIG_GET(flag/vote_no_dead) && usr.stat == DEAD && (!usr.client.admin_holder || !(usr.client.admin_holder.rights & R_MOD)))
				return 0
			if(current_votes[ckey])
				choices[choices[current_votes[ckey]]]--
			if(vote && 1<=vote && vote<=choices.len)
				voted += usr.ckey
				choices[choices[vote]]++	//check this
				current_votes[ckey] = vote
				return vote
		return 0

	proc/initiate_vote(var/vote_type, var/initiator_key)
		if(!mode)
			if(started_time != null && !check_rights(R_ADMIN))
				var/next_allowed_time = (started_time + CONFIG_GET(number/vote_delay))
				if(next_allowed_time > world.time)
					return 0

			reset()
			switch(vote_type)
				if("restart")
					choices.Add("Restart Round","Continue Playing")
				if("gamemode")
					if(SSticker.current_state == GAME_STATE_SETTING_UP)
						return 0
					choices.Add(config.votable_modes)
					var/list/L = typesof(/datum/game_mode) - /datum/game_mode
					for (var/F in choices)
						for (var/T in L)
							var/datum/game_mode/M = new T()
							if (M.config_tag == F)
								additional_text.Add("<td align = 'center'>[M.required_players]</td>")
								break
				if("custom")
					question = stripped_input(usr,"What is the vote for?")
					if(!question)	return 0
					for(var/i=1,i<=10,i++)
						var/option = capitalize(stripped_input(usr,"Please enter an option or hit cancel to finish"))
						if(!option || mode || !usr.client)	break
						choices.Add(option)
				else			return 0
			mode = vote_type
			initiator = initiator_key
			started_time = world.time
			var/text = "[capitalize(mode)] vote started by [initiator]."
			if(mode == "custom")
				text += "\n[question]"

			log_vote(text)
			to_world("<font color='purple'><b>[text]</b>\nType vote to place your votes.\nYou have [CONFIG_GET(number/vote_period)/10] seconds to vote.</font>")
			switch(vote_type)
				if("gamemode")
					world << sound('sound/ambience/alarm4.ogg', repeat = 0, wait = 0, volume = 50, channel = 1)
				if("custom")
					world << sound('sound/ambience/alarm4.ogg', repeat = 0, wait = 0, volume = 50, channel = 1)
			if(mode == "gamemode" && going)
				going = 0
				to_world("<font color='red'><b>Round start has been delayed.</b></font>")



			time_remaining = round(CONFIG_GET(number/vote_period)/10)
			return 1
		return 0

	proc/interface(var/client/C)
		if(!C)	return
		var/admin = 0
		var/trialmin = 0
		if(C.admin_holder)
			if(C.admin_holder.rights & R_ADMIN)
				admin = 1
				trialmin = 1 // don't know why we use both of these it's really weird, but I'm 2 lasy to refactor this all to use just admin.
		voting |= C

		. = "<html><head><title>Voting Panel</title></head><body>"
		if(mode)
			if(question)	. += "<h2>Vote: '[question]'</h2>"
			else			. += "<h2>Vote: [capitalize(mode)]</h2>"
			. += "Time Left: [time_remaining] s<hr>"
			. += "<table width = '100%'><tr><td align = 'center'><b>Choices</b></td><td align = 'center'><b>Votes</b></td>"
			if(capitalize(mode) == "Gamemode") .+= "<td align = 'center'><b>Minimum Players</b></td></b></tr>"

			for(var/i = 1, i <= choices.len, i++)
				var/votes = choices[choices[i]]
				if(!votes)	votes = 0
				. += "<tr>"
				if(current_votes[C.ckey] == i)
					. += "<td><b><a href='?src=\ref[src];vote=[i]'>[choices[i]]</a></b></td><td align = 'center'>[votes]</td>"
				else
					. += "<td><a href='?src=\ref[src];vote=[i]'>[choices[i]]</a></b></td><td align = 'center'>[votes]</td>"

				if (additional_text.len >= i)
					. += additional_text[i]
				. += "</tr>"

			. += "</table><hr>"
			if(admin)
				. += "(<a href='?src=\ref[src];vote=cancel'>Cancel Vote</a>) "
		else
			. += "<h2>Start a vote:</h2><hr><ul><li>"
			//restart
			if(trialmin)
				. += "<a href='?src=\ref[src];vote=restart'>Restart</a>"
			else
				. += "<font color='grey'>Restart (Disallowed)</font>"
			. += "</li><li>"
			if(trialmin)
				. += "\t(<a href='?src=\ref[src];vote=toggle_restart'>[CONFIG_GET(flag/allow_vote_restart)?"Allowed":"Disallowed"]</a>)"
			. += "</li><li>"
			//gamemode
			if(trialmin || CONFIG_GET(flag/allow_vote_mode))
				. += "<a href='?src=\ref[src];vote=gamemode'>GameMode</a>"
			else
				. += "<font color='grey'>GameMode (Disallowed)</font>"
			if(trialmin)
				. += "\t(<a href='?src=\ref[src];vote=toggle_gamemode'>[CONFIG_GET(flag/allow_vote_mode)?"Allowed":"Disallowed"]</a>)"

			. += "</li>"
			//custom
			if(trialmin)
				. += "<li><a href='?src=\ref[src];vote=custom'>Custom</a></li>"
			. += "</ul><hr>"
		. += "<a href='?src=\ref[src];vote=close' style='position:absolute;right:50px'>Close</a></body></html>"
		return .


	Topic(href,href_list[],hsrc)
		if(!usr || !usr.client)	return	//not necessary but meh...just in-case somebody does something stupid
		switch(href_list["vote"])
			if("close")
				voting -= usr.client
				close_browser(usr, "vote")
				return
			if("cancel")
				if(usr.client.admin_holder && (usr.client.admin_holder.rights & R_MOD))
					reset()
			if("toggle_restart")
				if(usr.client.admin_holder && (usr.client.admin_holder.rights & R_MOD))
					CONFIG_SET(flag/allow_vote_restart, !CONFIG_GET(flag/allow_vote_restart))
			if("toggle_gamemode")
				if(usr.client.admin_holder && (usr.client.admin_holder.rights & R_MOD))
					CONFIG_SET(flag/allow_vote_mode, !CONFIG_GET(flag/allow_vote_mode))
			if("restart")
				if(CONFIG_GET(flag/allow_vote_restart) || (usr.client.admin_holder && (usr.client.admin_holder.rights & R_MOD)))
					initiate_vote("restart",usr.key)
			if("gamemode")
				if(CONFIG_GET(flag/allow_vote_mode) || (usr.client.admin_holder && (usr.client.admin_holder.rights & R_MOD)))
					initiate_vote("gamemode",usr.key)
			if("custom")
				if(usr.client.admin_holder && (usr.client.admin_holder.rights & R_MOD))
					initiate_vote("custom",usr.key)
			else
				submit_vote(usr.ckey, round(text2num(href_list["vote"])))
		usr.vote()

/mob/verb/vote()
	set category = "OOC"
	set name = "Vote"

	if(vote)
		show_browser(src, vote.interface(client), "Vote", "vote", "can_close=0")



var/MapDaemon_UID = -1 //-1 by default so we know when to set it
var/force_mapdaemon_vote = 0

//Basically, this completely ignores the voting datum etc in favor of editing a simple a simple list, player_votes
//Upon request by MapDaemon, world/Topic() will it into JSON and send it away, so we do 0 handling in DM
/client/verb/mapVote()
	set category = "OOC"
	set name = "Map Vote"

	if(!SSticker.mode || !SSticker.mode.round_finished)
		to_chat(src, SPAN_NOTICE("Please wait until the round ends."))
		return

	var/list/L = list()
	L += "Don't care"

	// For future modularity and maybe more subtle solutions here?
	switch(GLOB.clients.len)
		if (0 to PLAYERCOUNT_LOWPOP_MAP_LIMIT)
			L += LOWPOP_NEXT_MAP_CANDIDATES.Copy()
		else
			L += NEXT_MAP_CANDIDATES.Copy()
	L -= map_tag
	var/selection = input("Vote for the next map to play on", "Vote:", "Don't care") as null|anything in L

	if(!selection || !src) return

	if(selection == "Don't care")
		to_chat(src, SPAN_NOTICE("You have not voted."))
		return

	to_chat(src, SPAN_NOTICE("You have voted for [selection]."))

	player_votes[src.ckey] = selection

/client/proc/forceMDMapVote()
	set name = "M: Force Map Vote"
	set category = "Server"

	force_mapdaemon_vote = !force_mapdaemon_vote
	to_chat(src, SPAN_NOTICE("The server will [force_mapdaemon_vote ? "now" : "no longer"] tell Mapdaemon to start a vote the next time possible."))

	message_staff("[src] is attempting to force a MapDaemon vote.")

//Uses an invalid ckey to rig the votes
//Special case for }}} handled in World/Topic()
//Set up so admins can fight over what the map will be, hurray
/client/proc/forceNextMap()
	set name = "M: Force Map"
	set category = "Server"

	if(alert("Are you sure you want to force the next map?",, "Yes", "No") == "No") return

	var/selection = input("Vote for the next map to play on", "Vote:", "LV-624") as null|anything in DEFAULT_NEXT_MAP_CANDIDATES

	if(!selection || !src) return

	to_chat(src, SPAN_NOTICE("You have forced the next map to be [selection]"))

	message_staff("[src] just forced the next map to be [selection].")

	player_votes["}}}"] = selection //}}} is an invalid ckey so we won't be in risk of someone using this cheekily


var/enable_map_vote = 1
/client/proc/cancelMapVote()
	set name = "M: Toggle Map Vote"
	set category = "Server"

	if(alert("Are you sure you want to turn the map vote [!enable_map_vote ? "on" : "off"]?",, "Yes", "No") == "No") return

	enable_map_vote = !enable_map_vote

	to_world(SPAN_NOTICE("[src] has toggled the map vote [enable_map_vote ? "on" : "off"]"))
	to_chat(src, SPAN_NOTICE("You have toggled the map vote [enable_map_vote ? "on" : "off"]"))

	message_staff("[src] just toggled the map vote [enable_map_vote ? "on" : "off"].")

/client/proc/showVotableMaps()
	set name = "M: List Maps"
	set category = "Server"

	to_chat(src, "Possible maps irrespective of pop:")
	for(var/i in NEXT_MAP_CANDIDATES)
		to_chat(src, SPAN_NOTICE(i))

/client/proc/editVotableMaps()
	set name = "M: Edit Maps"
	set category = "Server"

	if(alert("Are you sure you want to edit the map voting candidates?",, "Yes", "No") == "No") return

	switch(alert("Do you want to add or remove a map?",, "Add", "Remove", "Cancel"))
		if("Cancel")
			return
		if("Add")
			var/selection = ""
			switch(alert("Do you want to add one of the default map possibilities?",, "Yes", "No"))
				if("Yes")
					selection = input("Pick a default map.") as null|anything in DEFAULT_NEXT_MAP_CANDIDATES
				if("No")
					if(alert("Warning! This is a very dangerous option. If there is a typo in the map name and your choice wins, MapDaemon will crash. Please make sure you enter the exact name of the map. Are you sure you want to continue?", "WARNING", "Yes", "No") == "No") return
					selection = input("Enter a map at your own risk.")

			if(!selection || !src) return
			if(NEXT_MAP_CANDIDATES.Find(selection))
				alert("That option was already available.")
				return
			NEXT_MAP_CANDIDATES.Add(selection)
			message_staff("[src] just added [selection] to the map pool.")
		if("Remove")
			var/selection = input("Pick a map to remove from the pool") as null|anything in NEXT_MAP_CANDIDATES
			if(!selection || !src) return
			NEXT_MAP_CANDIDATES.Remove(selection)
			message_staff("[src] just removed [selection] from the map pool.")

var/kill_map_daemon = 0
/client/proc/killMapDaemon()
	set name = "M: Kill MapDaemon"
	set category = "Server"

	if(alert("Are you sure you want to kill MapDaemon?",, "Yes", "No") == "No") return

	kill_map_daemon = 1

	alert("MapDaemon will be killed on next round-end check.")
	message_staff("[src] just killed MapDaemon. It may be restarted with \"Map Vote - Revive MapDaemon\".")

/client/proc/reviveMapDaemon()
	set name = "M: Revive MapDaemon"
	set category = "Server"

	kill_map_daemon = 0

	message_staff("[src] is attempting to restart MapDaemon.")

	run_mapdaemon_batch()

/proc/run_mapdaemon_batch()

	set waitfor = 0

	if(world.system_type != MS_WINDOWS) return 0 //Don't know if it'll work for non-Windows, so let's just abort

	shell("run_mapdaemon.bat")
