var/global/list/atom/all_thinkers = list()

/subsystem/thinking/
	name = "Think Subsystem"
	desc = "Any and all objects that think when it is active are handled here."
	priority = SS_ORDER_PRELOAD
	tick_rate = DECISECONDS_TO_TICKS(1)

/subsystem/thinking/on_life()

	for(var/atom/A in all_thinkers)
		if(!A.think())
			all_thinkers -= A

	return TRUE