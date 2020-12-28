
//Areas for the Zero Point and Zero Point SMALL GAY... No, Gey//oh soooooo.. cute

/area/zero
	name = "Zero Point"
	icon = 'icons/turf/area_zero.dmi'
	//ambience = list('figuresomethingout.ogg')
	icon_state = "zero"
	can_build_special = TRUE //T-Comms structure
	temperature = 305
	lighting_use_dynamic = 1
	ambience_exterior = AMBIENCE_ZERO

/area/shuttle/drop1/zero
	name = "Zero - Dropship Alamo Landing Zone"
	icon_state = "shuttle"
	icon = 'icons/turf/area_zero.dmi'
	lighting_use_dynamic = 1

/area/shuttle/drop2/zero
	name = "Zero - Dropship Normandy Landing Zone"
	icon_state = "shuttle2"
	icon = 'icons/turf/area_zero.dmi'
	lighting_use_dynamic = 1

/area/zero/interior/oob/dev_room
	name = "Zero - Credits Room"
	is_resin_allowed = FALSE
	flags_atom = AREA_NOTUNNEL
	icon_state = "zero"

/area/zero/interior/caves
	name = "Caves"
	ceiling = CEILING_DEEP_UNDERGROUND
	icon_state = "colony_caves_3"
	ambience_exterior = AMBIENCE_CAVE
	soundscape_playlist = SCAPE_PL_CAVE
	soundscape_interval = 25
	sound_environment = 6
/area/zero/interior/caves/northern_caves
	name = "Northern Caves"
	icon_state = "colony_caves_0"
/area/zero/interior/caves/south_caves
	name = "Southern Caves"
	icon_state = "colony_caves_1"

/area/zero/interior/caves/central_caves
	name = "Central Caves"
	icon_state = "colony_caves_2"

/area/zero/interior
	name = "Kutjevo - Interior"
	ceiling = CEILING_UNDERGROUND
	icon_state = "zero"
	requires_power = 1

/area/zero/interior/exp
	name = "Kutjevo Complex"
	ceiling = CEILING_METAL
	icon_state = "complex"

/area/zero/interior/exp/landing1
	name = "LZ1"
	icon_state = "shuttle"

/area/zero/interior/exp/landing2
	name = "LZ2"
	icon_state = "shuttle2"

/area/zero/interior/exp/brig
	name = "Brig"
	icon_state = "power"

/area/zero/interior/exp/tcomms
	name = "Tcomms"
	icon_state = "tcomms"

/area/zero/interior/exp/research_lab
	name = "Lab"
	icon_state = "lab"

/area/zero/interior/exp/generators
	name = "Generators"
	icon_state = "power"

/area/zero/interior/exp/dorms0
	name = "Dorms"
	icon_state = "dorms_0"

/area/zero/interior/exp/dorms1
	name = "Dorms"
	icon_state = "dorms_1"

/area/zero/interior/exp/biodome
	name = "Biodome"
	icon_state = "biodome"
	temperature = 380
	always_unpowered = 1
	ceiling = CEILING_GLASS

/area/zero/interior/exp/med
	name = "Kutjevo Complex - Medical Foyer"
	icon_state = "med"