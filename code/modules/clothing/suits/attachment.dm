/obj/item/clothing/suit/attachment
	var/flags_armor_features
	var/brightness_on = 5 //Average attachable pocket light
	var/flashlight_cooldown = 0 //Cooldown for toggling the light
	var/obj/item/storage/has_attachment = null

/obj/item/clothing/suit/attachment/Initialize()
	. = ..()

//the logic here is half stolen from obj/item/storage/internal
/obj/item/clothing/suit/attachment/attack_hand(mob/living/user)
	if(can_interact(user))
		if(has_attachment)
			if(istype(has_attachment, /obj/item/storage/internal/attachment))
				has_attachment.interact()
			else if(istype(has_attachment, /obj/item/storage/internal))
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					if(H.l_store == src && !H.get_active_held_item())	//Prevents opening if it's in a pocket.
						H.put_in_hands(src)
						H.l_store = null
						return 0
					if(H.r_store == src && !H.get_active_held_item())
						H.put_in_hands(src)
						H.r_store = null
						return 0

				if(loc == user)
					has_attachment.open(user)
					return 0

				for(var/mob/M in range(1, loc))
					if(M.s_active == has_attachment)
						has_attachment.close(M)
				return ..()
			else if(istype(has_attachment, /obj/item/storage) && loc == user)
				has_attachment.attack_hand(user)
				return
		//return nothing if the user clicks on it with an empty hand and while it's in their posession
		else if(!has_attachment && src.loc == user)
			to_chat(usr, "The [src] currently has nothing attached to it.")
			return
		return ..()

//the logic here is half stolen from obj/item/storage/internal
/obj/item/clothing/suit/attachment/MouseDrop(obj/over_object)
	if(can_interact(usr))
		if(has_attachment && over_object == usr && Adjacent(usr)) //This must come before the screen objects only block
			has_attachment.open(usr)
			return 0

		if(flags_item & NODROP)
			return

		if(!istype(over_object, /obj/screen))
			return ..(over_object)

		//Makes sure master_item is equipped before putting it in hand, so that we can't drag it into our hand from miles away.
		//There's got to be a better way of doing this...
		if(loc != usr || (loc && loc.loc == usr))
			return 0

		if(!usr.incapacitated())
			switch(over_object.name)
				if("r_hand")
					if(time_to_unequip)
						spawn(0)
							if(!do_after(usr, time_to_unequip, TRUE, src, BUSY_ICON_FRIENDLY))
								to_chat(usr, "You stop taking off \the [src]")
							else
								usr.dropItemToGround(src)
								usr.put_in_r_hand(src)
							return 0
					else
						usr.dropItemToGround(src)
						usr.put_in_r_hand(src)
				if("l_hand")
					if(time_to_unequip)
						spawn(0)
							if(!do_after(usr, time_to_unequip, TRUE, src, BUSY_ICON_FRIENDLY))
								to_chat(usr, "You stop taking off \the [src]")
							else
								usr.dropItemToGround(src)
								usr.put_in_l_hand(src)
							return 0
					else
						usr.dropItemToGround(src)
						usr.put_in_l_hand(src)
			return 0
	return 0

/obj/item/clothing/suit/attachment/attackby(obj/item/storage/I, mob/user, params)
	if(has_attachment)
		return has_attachment.attackby(I, user, params)

	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user
	if(!src.attachmentsAllowed)
		to_chat(usr, "The [src] has no way to attach objects.")
		return FALSE
	if(!has_attachment && is_type_in_list(I, src.attachmentsAllowed))
		if(istype(I, /obj/item/storage))
			user.drop_held_item()
			has_attachment = I
			has_attachment.on_suit_attached(src, user)
			if(loc == user)
				H.update_inv_wear_suit()
		else //if the attachment isn't obj/item/storage or a child of that then spawn a container for it.
			has_attachment = new /obj/item/storage/internal/attachment(src)
			user.drop_held_item()
			has_attachment.loc = src
			has_attachment.handle_item_insertion(I)
	if(!has_attachment && !is_type_in_list(I, src.attachmentsAllowed))
		to_chat(usr, "<span class='notice'>[I] may not be attached to [src].</span>")
		return FALSE
	return ..()

/obj/item/clothing/suit/attachment/emp_act(severity)
	has_attachment.emp_act(severity)
	return ..()


/obj/item/clothing/suit/attachment/proc/turn_off_light(mob/wearer)
	if(flags_armor_features & ARMOR_LAMP_ON)
		set_light(0)
		toggle_armor_light(wearer) //turn the light off
		return TRUE
	return FALSE


/obj/item/clothing/suit/attachment/proc/toggle_armor_light(mob/user)
	flashlight_cooldown = world.time + 2 SECONDS
	if(flags_armor_features & ARMOR_LAMP_ON)
		set_light(0)
	else
		set_light(brightness_on)
	flags_armor_features ^= ARMOR_LAMP_ON
	playsound(src,'sound/items/flashlight.ogg', 15, 1)
	update_icon(user)
	update_action_button_icons()

/obj/item/clothing/suit/attachment/proc/remove_attachment(mob/user)
	if(!has_attachment)
		return
	if(user)
		if(istype(has_attachment, /obj/item/storage/internal/attachment))
			has_attachment.attack_hand(user)
		else
			user.put_in_hands(has_attachment)
	has_attachment.on_suit_removed(src, user)
	has_attachment = null
	update_clothing_icon()

/obj/item/clothing/suit/attachment/verb/removeattachment()
	set name = "Remove Attachment"
	set category = "Object"
	set src in usr
	if(!isliving(usr))
		return
	if(usr.stat)
		return
	if(!can_interact(usr))
		return
	src.remove_attachment(usr)

/obj/item/clothing/suit/attachment/proc/toggle_draw_mode()
	set name = "Toggle Draw Mode"
	if(has_attachment)
		has_attachment.toggle_draw_mode()

/obj/item/storage/internal/attachment/attack_hand()
	attachedItem.interact(usr)

/obj/item/storage/internal/attachment/handle_item_insertion(I)
	. = ..()
	if(.)
		attachedItem = I

//attachment internal storage, for attaching attachments which aren't obj/item/storage
/obj/item/storage/internal/attachment
	storage_slots = 1	
	max_w_class = 6		
	max_storage_space = 6
	var/obj/item/attachedItem = null

///obj/item/storage/internal/attachment/open()
//	to_chat(usr, "<span class='notice'>Passing through internal/attachment open proc</span>")
//	attachedItem.open()


/obj/item/clothing/suit/attachment/can_interact(mob/user)
	if(ishuman(user) || ismonkey(user))
		if(user.lying || istype(user.loc, /obj/vehicle/multitile/root/cm_armored))
			return 0
		return 1
	return 0
