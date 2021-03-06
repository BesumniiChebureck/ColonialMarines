//Straight up copied from old Bay
//Abby

//Xeno Overlays Indexes//////////
#define X_WOUND3_LAYER			11
#define X_WOUND2_LAYER			10
#define X_WOUND1_LAYER			9
#define X_HEAD_LAYER			8
#define X_SUIT_LAYER			7
#define X_L_HAND_LAYER			6
#define X_R_HAND_LAYER			5
#define X_RESOURCE_LAYER		4
#define X_TARGETED_LAYER		3
#define X_LEGCUFF_LAYER			2
#define X_FIRE_LAYER			1
#define X_TOTAL_LAYERS			11
/////////////////////////////////


/mob/living/carbon/Xenomorph/apply_overlay(cache_index)
	var/image/I = overlays_standing[cache_index]
	if(I)
		overlays += I

/mob/living/carbon/Xenomorph/remove_overlay(cache_index)
	if(overlays_standing[cache_index])
		overlays -= overlays_standing[cache_index]
		overlays_standing[cache_index] = null

/mob/living/carbon/Xenomorph/update_icons()
	if(!caste)
		return
	if(stat == DEAD)
		icon_state = "[mutation_type] [caste.caste_name] Dead"
	else if(lying)
		if((resting || sleeping) && (!knocked_down && !knocked_out && health > 0))
			icon_state = "[mutation_type] [caste.caste_name] Sleeping"
		else
			icon_state = "[mutation_type] [caste.caste_name] Knocked Down"
	else
		icon_state = "[mutation_type] [caste.caste_name] Running"

	update_fire() //the fire overlay depends on the xeno's stance, so we must update it.
	update_wounds() //the damage overlay

/mob/living/carbon/Xenomorph/regenerate_icons()
	..()
	update_inv_r_hand()
	update_inv_l_hand()
	update_inv_resource()
	update_icons()


/mob/living/carbon/Xenomorph/update_inv_pockets()
	var/datum/custom_hud/alien/ui_datum = custom_huds_list["alien"]
	if(l_store)
		if(client && hud_used && hud_used.hud_shown)
			l_store.screen_loc = ui_datum.ui_storage1
			client.screen += l_store
	if(r_store)
		if(client && hud_used && hud_used.hud_shown)
			r_store.screen_loc = ui_datum.ui_storage2
			client.screen += r_store

/mob/living/carbon/Xenomorph/update_inv_r_hand()
	remove_overlay(X_R_HAND_LAYER)
	if(r_hand)
		if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
			var/datum/custom_hud/alien/ui_datum = custom_huds_list["alien"]
			r_hand.screen_loc = ui_datum.ui_rhand
			client.screen += r_hand
		var/t_state = r_hand.item_state
		if(!t_state)
			t_state = r_hand.icon_state
		overlays_standing[X_R_HAND_LAYER] = r_hand.get_mob_overlay(src, WEAR_R_HAND)
		apply_overlay(X_R_HAND_LAYER)

/mob/living/carbon/Xenomorph/update_inv_l_hand()
	remove_overlay(X_L_HAND_LAYER)
	if(l_hand)
		if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
			var/datum/custom_hud/alien/ui_datum = custom_huds_list["alien"]
			l_hand.screen_loc = ui_datum.ui_lhand
			client.screen += l_hand
		var/t_state = l_hand.item_state
		if(!t_state)
			t_state = l_hand.icon_state
		overlays_standing[X_L_HAND_LAYER] = l_hand.get_mob_overlay(src, WEAR_L_HAND)
		apply_overlay(X_L_HAND_LAYER)

/mob/living/carbon/Xenomorph/proc/update_inv_resource()
	remove_overlay(X_RESOURCE_LAYER)
	if(crystal_stored)
		overlays_standing[X_RESOURCE_LAYER] = image("icon" = icon, "icon_state" = "[caste_name]_resources", "layer" =-X_RESOURCE_LAYER)
		apply_overlay(X_RESOURCE_LAYER)

//Call when target overlay should be added/removed
/mob/living/carbon/Xenomorph/update_targeted()
	remove_overlay(X_TARGETED_LAYER)
	if(targeted_by && target_locked)
		overlays_standing[X_TARGETED_LAYER]	= image("icon" = target_locked, "layer" =-X_TARGETED_LAYER)
	else if(!targeted_by && target_locked)
		QDEL_NULL(target_locked)
	if(!targeted_by || src.stat == DEAD)
		overlays_standing[X_TARGETED_LAYER]	= null
	apply_overlay(X_TARGETED_LAYER)

/mob/living/carbon/Xenomorph/update_inv_legcuffed()
	remove_overlay(X_LEGCUFF_LAYER)
	if(legcuffed)
		overlays_standing[X_LEGCUFF_LAYER]	= image("icon" = get_icon_from_source(CONFIG_GET(string/alien_effects)), "icon_state" = "legcuff", "layer" =-X_LEGCUFF_LAYER)
		apply_overlay(X_LEGCUFF_LAYER)

/mob/living/carbon/Xenomorph/proc/create_shriekwave(var/color = null)
	var/image/screech_image

	var/offset_x = 0
	var/offset_y = 0
	if(mob_size <= MOB_SIZE_XENO)
		offset_x = -7
		offset_y = -10

	if (color)
		screech_image = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" = "shriek_waves_greyscale") // For Praetorian screech
		screech_image.color = color
		screech_image.pixel_x = offset_x
		screech_image.pixel_y = offset_y
	else
		screech_image = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" = "shriek_waves") //Ehh, suit layer's not being used.
		screech_image.pixel_x = offset_x
		screech_image.pixel_y = offset_y

	remove_suit_layer()

	overlays_standing[X_SUIT_LAYER] = screech_image
	apply_overlay(X_SUIT_LAYER)
	addtimer(CALLBACK(src, .proc/remove_overlay, X_SUIT_LAYER), 30)

/mob/living/carbon/Xenomorph/proc/create_stomp()
	remove_suit_layer()

	overlays_standing[X_SUIT_LAYER] = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" = "stomp") //Ehh, suit layer's not being used.
	apply_overlay(X_SUIT_LAYER)
	addtimer(CALLBACK(src, .proc/remove_overlay, X_SUIT_LAYER), 12)

/mob/living/carbon/Xenomorph/proc/create_empower()
	remove_suit_layer()

	overlays_standing[X_SUIT_LAYER] = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" = "empower")
	apply_overlay(X_SUIT_LAYER)
	addtimer(CALLBACK(src, .proc/remove_overlay, X_SUIT_LAYER), 20)

/mob/living/carbon/Xenomorph/proc/create_shield(var/duration = 10)
	remove_suit_layer()

	overlays_standing[X_SUIT_LAYER] = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" = "shield2")
	apply_overlay(X_SUIT_LAYER)
	addtimer(CALLBACK(src, .proc/remove_overlay, X_SUIT_LAYER), duration)

/mob/living/carbon/Xenomorph/proc/remove_suit_layer()
	remove_overlay(X_SUIT_LAYER)

/mob/living/carbon/Xenomorph/update_fire()
	remove_overlay(X_FIRE_LAYER)
	if(on_fire)
		var/image/I
		if(mob_size >= MOB_SIZE_BIG)
			if((!initial(pixel_y) || lying) && !resting && !sleeping)
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state"="alien_fire", "layer"=-X_FIRE_LAYER)
				I.color = fire_reagent.burncolor
			else
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state"="alien_fire_lying", "layer"=-X_FIRE_LAYER)
				I.color = fire_reagent.burncolor
		else
			I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_effects)), "icon_state"="alien_fire", "layer"=-X_FIRE_LAYER)
			I.color = fire_reagent.burncolor

		overlays_standing[X_FIRE_LAYER] = I
		apply_overlay(X_FIRE_LAYER)

/mob/living/carbon/Xenomorph/proc/create_crusher_shield()
	remove_overlay(X_HEAD_LAYER)

	var/image/shield = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" = "empower")
	shield.color = rgb(87, 73, 144)
	overlays_standing[X_HEAD_LAYER] = shield
	apply_overlay(X_HEAD_LAYER)
	addtimer(CALLBACK(src, .proc/remove_overlay, X_HEAD_LAYER), 20)

/mob/living/carbon/Xenomorph/proc/update_wounds()
	remove_overlay(X_WOUND1_LAYER)
	if(health < maxHealth * 0.75) //Injuries appear at less than 25% health
		var/image/I
		if(mob_size >= MOB_SIZE_BIG)
			if((!initial(pixel_y) || lying) && !resting && !sleeping)
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" =  "wound1", "layer"=-X_WOUND1_LAYER)
			else
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state" =  "wound1_lying", "layer"=-X_WOUND1_LAYER)
		else
			I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_effects)), "icon_state" =  "wound1", "layer"=-X_WOUND1_LAYER)

		overlays_standing[X_WOUND1_LAYER] = I
		apply_overlay(X_WOUND1_LAYER)
	remove_overlay(X_WOUND2_LAYER)
	if(health < (maxHealth * 0.5)) //Injuries appear at less than 50% health
		var/image/I
		if(mob_size >= MOB_SIZE_BIG)
			if((!initial(pixel_y) || lying) && !resting && !sleeping)
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state"="wound2", "layer"=-X_WOUND2_LAYER)
			else
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state"="wound2_lying", "layer"=-X_WOUND2_LAYER)
		else
			I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_effects)), "icon_state"="wound2", "layer"=-X_WOUND2_LAYER)

		overlays_standing[X_WOUND2_LAYER] = I
		apply_overlay(X_WOUND2_LAYER)
	remove_overlay(X_WOUND3_LAYER)
	if(health < (maxHealth * 0.25)) //Injuries appear at less than 75% health
		var/image/I
		if(mob_size >= MOB_SIZE_BIG)
			if((!initial(pixel_y) || lying) && !resting && !sleeping)
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state"="wound3", "layer"=-X_WOUND3_LAYER)
			else
				I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_overlay_64x64)), "icon_state"="wound3_lying", "layer"=-X_WOUND3_LAYER)
		else
			I = image("icon"=get_icon_from_source(CONFIG_GET(string/alien_effects)), "icon_state"="wound3", "layer"=-X_WOUND3_LAYER)

		overlays_standing[X_WOUND3_LAYER] = I
		apply_overlay(X_WOUND3_LAYER)

//Xeno Overlays Indexes//////////
#undef X_WOUND3_LAYER
#undef X_WOUND2_LAYER
#undef X_WOUND1_LAYER
#undef X_HEAD_LAYER
#undef X_SUIT_LAYER
#undef X_L_HAND_LAYER
#undef X_R_HAND_LAYER
#undef X_LEGCUFF_LAYER
#undef X_FIRE_LAYER
