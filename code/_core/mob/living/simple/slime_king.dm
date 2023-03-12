/mob/living/simple/slime_king //Not a subtype of slime because it behaves way differently
	name = "slime king"
	boss_icon_state = "slime_king"
	desc = "Oh no. They're here too."

	icon = 'icons/mob/living/simple/slime_king_new.dmi'
	icon_state = "living"

	ai = /ai/boss/slime_king

	damage_type = /damagetype/npc/slime

	can_attack_while_moving = TRUE

	color = "#2222FF"
	alpha = 200

	pixel_x = -32
	pixel_y = -12

	health_base = 5000
	stamina_base = 5000
	mana_base = 100

	value = 500

	object_size = 2

	boss = TRUE
	force_spawn = TRUE

	armor = /armor/slime

	status_immune = list(
		STUN = TRUE,
		SLEEP = TRUE,
		PARALYZE = TRUE,
		STAMCRIT = TRUE,
		STAGGER = TRUE,
		CONFUSED = TRUE,
		DISARM = TRUE,
		FIRE = TRUE,
		GRAB = TRUE,
		PAINCRIT = TRUE
	)

	fatigue_mul = 0

	butcher_contents = list(
		/obj/item/soapstone/orange
	)

	size = SIZE_BOSS

	damage_type = /damagetype/npc/slime

	enable_medical_hud = FALSE
	enable_security_hud = FALSE

	iff_tag = "Slime"
	loyalty_tag = "Slime"

	stun_angle = 0

	blood_type = null

	soul_size = SOUL_SIZE_RARE

	respawn_time = SECONDS_TO_DECISECONDS(300)

	movement_delay = DECISECONDS_TO_TICKS(6)

	level = 30

	var/elite = FALSE

/mob/living/simple/slime_king/update_icon()
	. = ..()
	icon = initial(icon)
	icon_state = initial(icon_state)
	if(dead)
		icon_state = "dead"

/mob/living/simple/slime_king/Finalize()
	. = ..()
	color = rgb(
		h=max(0,health.health_current/health.health_max)*220,
		s=69,
		v=100
	)
	update_sprite()

/mob/living/simple/slime_king/update_overlays()
	. = ..()
	var/image/I = new/image(icon,"[icon_state]_crown")
	I.appearance_flags = src.appearance_flags | RESET_COLOR | KEEP_APART
	add_overlay(I)

/mob/living/simple/slime_king/on_damage_received(var/atom/atom_damaged,var/atom/attacker,var/atom/weapon,var/damagetype/DT,var/list/damage_table,var/damage_amount,var/critical_hit_multiplier,var/stealthy=FALSE)

	. = ..()

	if(health.health_current <= health.health_max*0.5)
		elite = TRUE

	if(elite)
		var/health_mod = clamp((health.health_current/health.health_max)*200,0,100)
		color = rgb(
			h=0,
			s=health_mod,
			v=health_mod
		)
	else
		color = rgb(
			h=max(0, (health.health_current/health.health_max)*1.5 - 0.5)*220,
			s=69,
			v=100
		)

	if(!dead && prob(damage_amount) && attacker)
		var/turf/T = get_step(src,get_dir(src,attacker))
		if(T)
			var/mob/living/simple/slime/S = new(T)
			S.color = src.color
			S.alpha = src.alpha
			INITIALIZE(S)
			FINALIZE(S)
			var/xvel = rand(-1,1)
			var/yvel = rand(-1,1)
			if(xvel == 0 && yvel == 0)
				xvel = pick(-1,1)
				yvel = pick(-1,1)
			S.throw_self(src,attacker,16,16,xvel*10,yvel*10)
			if(S.ai)
				S.ai.aggression = 3
				S.ai.set_active(TRUE)
				S.ai.set_objective(attacker)

/mob/living/simple/slime_king/post_death()
	. = ..()
	update_sprite()
	animate(src,alpha=0,time=SECONDS_TO_DECISECONDS(10))
	CALLBACK("\ref[src]_delete_in",SECONDS_TO_DECISECONDS(11),src,.proc/delete_self)

/mob/living/simple/slime_king/proc/delete_self()
	qdel(src)

/mob/living/simple/slime_king/proc/shoot_slime_ball(var/atom/target)

	if(has_status_effect(PARALYZE))
		return FALSE

	shoot_projectile(
		src,
		target,
		null,
		null,
		/obj/projectile/slime_ball,
		/damagetype/ranged/slime_ball/,
		16,
		16,
		0,
		(TILE_SIZE-1)*0.125,
		1,
		src.color,
		0,
		1,
		src.iff_tag,
		src.loyalty_tag,
		1,
		get_base_spread(),
		0
	)

	return TRUE

/mob/living/simple/slime_king/Bump(atom/Obstacle)

	. = ..()

	if(Obstacle.health && src.dash_amount > 0)
		var/damagetype/DT = all_damage_types[/damagetype/npc/bubblegum]
		var/list/params = list()
		params[PARAM_ICON_X] = rand(0,32)
		params[PARAM_ICON_Y] = rand(0,32)
		var/atom/object_to_damage = Obstacle.get_object_to_damage(src,src,params,/damagetype/npc/bubblegum,TRUE,TRUE)
		visible_message(span("danger","\The [src.name] rams into \the [Obstacle.name]!"))
		DT.process_damage(src,Obstacle,src,object_to_damage,src,1)

/mob/living/simple/slime_king/proc/slime_wave(var/target_direction=dir)

	if(has_status_effect(PARALYZE))
		return FALSE

	add_status_effect(PARALYZE,duration=VIEW_RANGE*2,magnitude=-1,stealthy=TRUE)

	for(var/i=-1,i<=1,i+=1)
		var/angle_mod = i*90
		var/final_diraction = angle_mod ? turn(target_direction,angle_mod) : target_direction
		var/turf/T = get_step(src,final_diraction)
		if(!T)
			break
		for(var/j=1,j<=VIEW_RANGE,j++)
			var/turf/old_turf = T
			var/should_break = FALSE
			T = get_step(T,target_direction)
			if(!T || j == VIEW_RANGE)
				should_break = TRUE
			else if(T.has_dense_atom)
				if(T.density && !T.Enter(src,old_turf))
					should_break = TRUE
				else
					for(var/k in T.contents)
						var/atom/movable/M = k
						if(M.density && !is_living(M) && !M.Cross(src))
							should_break = TRUE
							break

			CALLBACK("\ref[src]_slime_wave_[i]_[j]",j,src,.proc/create_slime_tile,old_turf,should_break)
			if(should_break)
				if(i==0 && elite)
					remove_status_effect(PARALYZE)
					src.dash_target = old_turf
					src.dash_amount = get_dist(src,old_turf)
					play_sound('sound/effects/dodge.ogg',get_turf(src))
				break
			else if(elite && !(j % 3))
				throw_bomb(old_turf,20)



/mob/living/simple/slime_king/proc/create_slime_tile(var/turf/T,var/create_bomb_slime=FALSE)
	var/obj/structure/interactive/slime_wall/SW = locate() in T.contents
	if(SW) return FALSE
	var/obj/structure/interactive/slime_tile/S = locate() in T.contents
	if(S) return FALSE
	S = new(T)
	S.color = src.color
	S.alpha = src.alpha
	INITIALIZE(S)
	GENERATE(S)
	FINALIZE(S)
	if(create_bomb_slime)
		var/mob/living/simple/slime/L = new(T)
		L.has_bomb = TRUE
		L.color = S.color
		INITIALIZE(L)
		GENERATE(L)
		FINALIZE(L)
		if(L.ai)
			L.ai.aggression = 3
			L.ai.set_active(TRUE)
			L.ai.find_new_objectives(AI_TICK,TRUE)
		L.pixel_z = -10
		L.alpha = 0
		animate(
			L,
			alpha=src.alpha,
			pixel_z=0,
			time=10
		)
	return TRUE

/mob/living/simple/slime_king/proc/create_slime_wall(var/turf/T)
	var/obj/structure/interactive/slime_tile/ST = locate() in T.contents
	if(ST)
		qdel(ST)
	var/obj/structure/interactive/slime_wall/S = locate() in T.contents
	if(S) return FALSE
	S = new(T)
	S.color = src.color
	S.alpha = src.alpha
	INITIALIZE(S)
	GENERATE(S)
	FINALIZE(S)
	return TRUE

/mob/living/simple/slime_king/proc/throw_bombs()

	if(has_status_effect(PARALYZE))
		return FALSE

	add_status_effect(PARALYZE,duration=12,magnitude=-1,stealthy=TRUE)

	var/list/valid_turfs = list()
	var/list/valid_target_turfs = list()

	for(var/turf/T in oview(VIEW_RANGE,src))
		if(T.density)
			continue
		valid_turfs += T

	if(elite)
		for(var/mob/living/L in oview(VIEW_RANGE,src))
			if(L.dead)
				continue
			if(L.loyalty_tag == L.loyalty_tag)
				continue
			var/turf/T = get_turf(L)
			if(L)
				valid_target_turfs += T

	for(var/i=1,i<=10,i++)
		var/turf/T
		if(elite && length(valid_target_turfs))
			T = pick(valid_target_turfs)
			valid_target_turfs -= T
		else
			if(!length(valid_turfs))
				break
			T = pick(valid_turfs)
			valid_turfs -= T
		var/desired_time = elite ? 1 + i : 3 + i*3
		CALLBACK("\ref[src]_throw_bomb_[i]",desired_time,src,.proc/throw_bomb,T)

/mob/living/simple/slime_king/proc/throw_bomb(var/turf/T,var/throw_time=40)
	var/obj/item/slime_bomb/B = new(T)
	B.owner = src
	B.loyalty_tag = src.loyalty_tag
	B.anchored = 2 //For now.
	B.mouse_opacity = 0
	var/offset_x = src.x - T.x
	var/offset_y = src.y - T.y
	B.pixel_x = offset_x * TILE_SIZE
	B.pixel_y = offset_y * TILE_SIZE
	B.pixel_z = 0
	animate(B,pixel_x = B.pixel_x*0.5,pixel_y=B.pixel_y*0.5,pixel_z=TILE_SIZE*3,time=throw_time*0.5)
	animate(pixel_x=0,pixel_y=0,pixel_z=0,time=throw_time*0.5)
	CALLBACK("\ref[B]_arm",throw_time*0.75,src,.proc/arm_bomb,B)

/mob/living/simple/slime_king/proc/arm_bomb(var/obj/item/slime_bomb/B)
	B.anchored = FALSE
	B.mouse_opacity = initial(B.mouse_opacity)
	B.light()
	return TRUE

/mob/living/simple/slime_king/proc/build_a_house(var/size=4)

	if(has_status_effect(PARALYZE))
		return FALSE

	var/turf/T = get_turf(src)

	if(!T)
		return FALSE

	add_status_effect(PARALYZE,duration=size*2*3*2,magnitude=-1,stealthy=TRUE)

	for(var/tx=-size,tx<=size,tx++) for(var/ty=-size,ty<=size,ty++)
		var/turf/TA = locate(T.x + tx,T.y + ty,T.z)
		if(!TA) continue
		var/delay = (abs(tx) + abs(ty))*3
		if(abs(tx) == size || abs(ty) == size)
			CALLBACK("\ref[src]_build_wall_[tx]_[ty]",delay,src,.proc/create_slime_wall,TA)
		else
			CALLBACK("\ref[src]_build_wall_[tx]_[ty]",delay,src,.proc/create_slime_tile,TA)