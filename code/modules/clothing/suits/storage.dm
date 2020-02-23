/obj/item/clothing/suit/storage
	var/flags_armor_features
	var/brightness_on = 5 //Average attachable pocket light
	var/flashlight_cooldown = 0 //Cooldown for toggling the light
	var/obj/item/storage/has_attachment = null 

/obj/item/clothing/suit/storage/Initialize()
	. = ..()
//possibly logic here to hide the toggle draw method verb when the armor spawns without an attachment?


/obj/item/clothing/suit/storage/attack_hand(mob/living/user)
	if(has_attachment && src.loc == user)
		has_attachment.attack_hand(user)
		return

	//return nothing if the user clicks on it with an empty hand and while it's in their posession
	if(src.loc == user)
		return
	return ..()

/obj/item/clothing/suit/storage/MouseDrop(obj/over_object)
//	if(has_attachment.handle_mousedrop(usr, over_object))
		return ..(over_object)


/obj/item/clothing/suit/storage/attackby(obj/item/I, mob/user, params)
	if(has_attachment)
		return has_attachment.attackby(I, user, params)

	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user
	if(!src.attachmentsAllowed)
		to_chat(usr, "The [src] has no way to attach objects.")
		return FALSE
	if(!has_attachment && is_type_in_list(I, H.wear_suit.attachmentsAllowed) )
		user.drop_held_item()
		has_attachment = I
		has_attachment.on_suit_attached(src, user)
		H.update_inv_wear_suit()
	if(!is_type_in_list(I, src.attachmentsAllowed))
		to_chat(usr, "<span class='notice'>[I] may not be attached to [src].</span>")
		return FALSE
	return ..()

/obj/item/clothing/suit/storage/emp_act(severity)
	has_attachment.emp_act(severity)
	return ..()


/obj/item/clothing/suit/storage/proc/turn_off_light(mob/wearer)
	if(flags_armor_features & ARMOR_LAMP_ON)
		set_light(0)
		toggle_armor_light(wearer) //turn the light off
		return TRUE
	return FALSE


/obj/item/clothing/suit/storage/proc/toggle_armor_light(mob/user)
	flashlight_cooldown = world.time + 2 SECONDS
	if(flags_armor_features & ARMOR_LAMP_ON)
		set_light(0)
	else
		set_light(brightness_on)
	flags_armor_features ^= ARMOR_LAMP_ON
	playsound(src,'sound/items/flashlight.ogg', 15, 1)
	update_icon(user)
	update_action_button_icons()

/obj/item/clothing/suit/storage/proc/remove_storage(mob/user)
	if(!has_attachment)
		return
	has_attachment.on_suit_removed(src, user)
	if(user)
		user.put_in_hands(has_attachment)
	has_attachment = null
	update_clothing_icon()

/obj/item/clothing/suit/storage/verb/removeattachment()
	set name = "Remove Attachment"
	set category = "Object"
	set src in usr
	if(!isliving(usr))
		return
	if(usr.stat) return

	src.remove_storage(usr)


/obj/item/clothing/suit/storage/verb/toggle_draw_mode()
	if(has_attachment)
		has_attachment.toggle_draw_mode()
