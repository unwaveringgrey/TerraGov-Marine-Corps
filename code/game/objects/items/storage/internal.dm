//A storage item intended to be used by other items to provide storage functionality.
//Types that use this should consider overriding emp_act() and hear_talk(), unless they shield their contents somehow.
/obj/item/storage/internal
	var/obj/item/master_item

/obj/item/storage/internal/Initialize()
	. = ..()
	master_item = loc
	name = master_item.name
	forceMove(master_item)
	verbs -= /obj/item/verb/verb_pickup	//make sure this is never picked up.

/obj/item/storage/internal/attack_hand(mob/living/user)
	return TRUE

/obj/item/storage/internal/mob_can_equip()
	return 0	//make sure this is never picked up

//Helper procs to cleanly implement internal storages - storage items that provide inventory slots for other items.
//These procs are completely optional, it is up to the master item to decide when it's storage get's opened by calling open()
//However they are helpful for allowing the master item to pretend it is a storage item itself.
//If you are using these you will probably want to override attackby() as well.
//See /obj/item/clothing/suit/storage for an example.

//Items that use internal storage have the option of calling this to emulate default storage MouseDrop behaviour.
//Returns 1 if the master item's parent's MouseDrop() should be called, 0 otherwise. It's strange, but no other way of
//Doing it without the ability to call another proc's parent, really.
/obj/item/storage/internal/proc/handle_mousedrop(mob/user as mob, obj/over_object as obj)
	if(ishuman(user) || ismonkey(user)) //so monkeys can take off their backpacks -- Urist

		if(user.lying) //Can't use your inventory when lying
			return

		if(istype(user.loc, /obj/vehicle/multitile/root/cm_armored)) //Stops inventory actions in a mech/tank
			return 0

		if(over_object == user && Adjacent(user)) //This must come before the screen objects only block
			open(user)
			return 0

		if(master_item.flags_item & NODROP) return

		if(!istype(over_object, /obj/screen))
			return 1

		//Makes sure master_item is equipped before putting it in hand, so that we can't drag it into our hand from miles away.
		//There's got to be a better way of doing this...
		if(master_item.loc != user || (master_item.loc && master_item.loc.loc == user))
			return 0

		if(!user.incapacitated())
			switch(over_object.name)
				if("r_hand")
					if(master_item.time_to_unequip)
						spawn(0)
							if(!do_after(user, master_item.time_to_unequip, TRUE, master_item, BUSY_ICON_FRIENDLY))
								to_chat(user, "You stop taking off \the [master_item]")
							else
								user.dropItemToGround(master_item)
								user.put_in_r_hand(master_item)
							return 0
					else
						user.dropItemToGround(master_item)
						user.put_in_r_hand(master_item)
				if("l_hand")
					if(master_item.time_to_unequip)
						spawn(0)
							if(!do_after(user, master_item.time_to_unequip, TRUE, master_item, BUSY_ICON_FRIENDLY))
								to_chat(user, "You stop taking off \the [master_item]")
							else
								user.dropItemToGround(master_item)
								user.put_in_l_hand(master_item)
							return 0
					else
						user.dropItemToGround(master_item)
						user.put_in_l_hand(master_item)
			return 0
	return 0

//Items that use internal storage have the option of calling this to emulate default storage attack_hand behaviour.
//Returns 1 if the master item's parent's attack_hand() should be called, 0 otherwise.
//It's strange, but no other way of doing it without the ability to call another proc's parent, really.
/obj/item/storage/internal/proc/handle_attack_hand(mob/user as mob)

	if(user.lying)
		return 0

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.l_store == master_item && !H.get_active_held_item())	//Prevents opening if it's in a pocket.
			H.put_in_hands(master_item)
			H.l_store = null
			return 0
		if(H.r_store == master_item && !H.get_active_held_item())
			H.put_in_hands(master_item)
			H.r_store = null
			return 0

	if(master_item.loc == user)
		src.open(user)
		return 0

	for(var/mob/M in range(1, master_item.loc))
		if(M.s_active == src)
			src.close(M)
	return 1

/obj/item/storage/internal/Adjacent(atom/neighbor)
	return master_item.Adjacent(neighbor)


/obj/item/storage/internal/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	. = ..()
	master_item.on_pocket_insertion()


/obj/item/storage/internal/remove_from_storage(obj/item/W as obj, atom/new_location)
	. = ..()
	master_item.on_pocket_removal()


//things to do when an item is inserted in the obj's internal pocket
/obj/item/proc/on_pocket_insertion()
	return

//things to do when an item is removed in the obj's internal pocket
/obj/item/proc/on_pocket_removal()
	return

//A type of internal storage that can store a single other item. It allows it to be accessed as if it wasn't stored.
//This is mainly meant to allow for attaching items to items
/obj/item/storage/internal/attachment
	storage_slots = 1
	max_w_class = 6
	max_storage_space = 6
	var/image/attachment_icon = null
	var/obj/item/attachedItem = null
	var/list/attachmentsAllowed = list(
		/obj/item/storage/pouch,
		/obj/item/storage/large_holster/machete,
		/obj/item/storage/large_holster/katana,
		/obj/item/storage/large_holster/m39,
		/obj/item/motiondetector)
	bypass_w_limit = list(
		/obj/item/storage/pouch,
		/obj/item/storage/large_holster/machete,
		/obj/item/storage/large_holster/katana,
		/obj/item/storage/large_holster/m39,
		/obj/item/motiondetector)

/obj/item/storage/internal/attachment/handle_attack_hand(mob/living/user)
	if(!attachedItem && master_item.loc == user)
		to_chat(usr, "\the [master_item] has nothing attached to it.")
	. = ..()
	//if(.)
	updateAttachmentIcon()

/obj/item/storage/internal/attachment/open(mob/living/user)
	if(istype(attachedItem, /obj/item/storage))
		//we can't just call attack_hand here because the storage attack_hand proc checks that loc == user
		var/obj/item/storage/O = attachedItem
		if(O.draw_mode && ishuman(user) && O.contents.len)
			var/obj/item/I = O.contents[O.contents.len]
			I.attack_hand(user)
		else
			O.open(user)
	else if(istype(attachedItem, /obj/item/motiondetector))
		var/obj/item/motiondetector/MD = attachedItem
		MD.interact(user)
	return 1

/obj/item/storage/internal/attachment/attackby(obj/item/I, mob/living/user)
	if(attachedItem)
		attachedItem.attackby(I, user)
		updateAttachmentIcon()
	else
		if(!is_type_in_list(I, src.attachmentsAllowed))
			to_chat(user, "\the [master_item] cannot attach \the [I].")
			return 0
		. = ..()
		if(.)
			attachedItem = I
			updateAttachmentIcon()
			var/obj/item/storage/O = I
			if(istype(O))
				master_item.verbs += /obj/item/clothing/suit/storage/marine/verb/toggle_draw_mode

/obj/item/storage/internal/attachment/toggle_draw_mode()
	var/obj/item/storage/O = attachedItem
	if(istype(O))
		O.toggle_draw_mode()

/obj/item/storage/internal/attachment/proc/removeAttachment(mob/living/user)
	master_item.verbs -= /obj/item/clothing/suit/storage/marine/verb/toggle_draw_mode

/obj/item/storage/internal/attachment/proc/remove_storage(mob/user)
	if(!attachedItem)
		return
	if(user)
		user.put_in_hands(attachedItem)
	var/obj/item/storage/O = attachedItem
	if(istype(O))
		master_item.verbs -= /obj/item/clothing/suit/storage/marine/verb/toggle_draw_mode
	attachedItem = null
	updateAttachmentIcon()

/obj/item/storage/internal/attachment/proc/updateAttachmentIcon()
	if(attachment_icon != null && (!attachedItem || attachment_icon.icon_state != attachedItem.icon_state))
		master_item.overlays -= attachment_icon
		var/obj/item/clothing/suit/storage/marine/MI = master_item
		MI.armor_overlays["attachment"] = null
		attachment_icon = null
	if(attachedItem && attachment_icon == null)
		attachment_icon = image("icon" = 'icons/obj/clothing/suit_attachments.dmi', "icon_state" = attachedItem.icon_state)
		var/obj/item/clothing/suit/storage/marine/MI = master_item
		master_item.overlays += attachment_icon
		MI.armor_overlays["attachment"] = attachment_icon

	master_item.update_icon(usr)
	master_item.update_action_button_icons()

/obj/item/storage/internal/attachment/can_be_inserted(src, warning)
	to_chat(usr, "can_be_inserted outer")
	if(attachedItem && istype(attachedItem, /obj/item/storage))
		var/obj/item/storage/S = attachedItem
		to_chat(usr, "can_be_inserted inner")
		return S.can_be_inserted(src, warning)
	. = ..()

/obj/item/storage/internal/attachment/handle_item_insertion(obj/item/W as obj, prevent_warning = 0, mob/user)
	if(attachedItem && istype(attachedItem, /obj/item/storage))
		var/obj/item/storage/S = attachedItem
		S.handle_item_insertion(W, prevent_warning, user)
		updateAttachmentIcon()
	else if(!attachedItem)
		..()
		attachedItem = W
		var/obj/item/storage/O = W
		if(istype(O))
			master_item.verbs += /obj/item/clothing/suit/storage/marine/verb/toggle_draw_mode
	updateAttachmentIcon()
	master_item.on_pocket_insertion()

/obj/item/storage/internal/attachment/remove_from_storage(obj/item/I, atom/new_location)
	. = ..()
	updateAttachmentIcon()

/obj/item/storage/internal/attachment/handle_mousedrop(mob/user as mob, obj/over_object as obj)
	. = ..()
	updateAttachmentIcon()