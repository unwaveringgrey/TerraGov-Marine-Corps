//used for spreading armor values to other armor pieces.
//Specifically so that marine armor can share it's armor values with equipped helmets, boots, and gloves
//A bit of nonsense code to troll CABAL
/datum/component/armor_sharer
	var/mob/living/carbon/human/wearing_mob
	var/obj/item/clothing/head/helmet/marine/helmet
	var/obj/item/clothing/gloves/marine/gloves
	var/obj/item/clothing/shoes/marine/boots

/datum/component/armor_sharer/Destroy(force, silent)
	resetHelmetArmor()
	resetGloveArmor()
	resetBootArmor()
	wearing_mob = null
	return ..()

/datum/component/armor_sharer/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED_TO_SLOT, .proc/equipped_to_slot)
	RegisterSignal(parent, HELMET_EQUIPPED, .proc/helmet_equipped)
	RegisterSignal(parent, GLOVES_EQUIPPED, .proc/gloves_equipped)
	RegisterSignal(parent, BOOTS_EQUIPPED, .proc/boots_equipped)
	RegisterSignal(parent, list(COMSIG_ITEM_EQUIPPED_NOT_IN_SLOT, COMSIG_ITEM_DROPPED), .proc/removed_from_slot)

/datum/component/armor_sharer/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_ITEM_EQUIPPED_TO_SLOT, HELMET_EQUIPPED, GLOVES_EQUIPPED, 
		BOOTS_EQUIPPED, COMSIG_ITEM_EQUIPPED_NOT_IN_SLOT, COMSIG_ITEM_DROPPED))

/datum/component/armor_sharer/proc/equipped_to_slot(datum/source, mob/user)
	wearing_mob = user
	updateHelmetArmor()
	updateGloveArmor()
	updateBootArmor()

/datum/component/armor_sharer/proc/removed_from_slot(datum/source, mob/user)
	resetHelmetArmor()
	resetGloveArmor()
	resetBootArmor()
	wearing_mob = null

/datum/component/armor_sharer/proc/helmet_equipped(datum/source, mob/user)
	updateHelmetArmor()

/datum/component/armor_sharer/proc/gloves_equipped(datum/source, mob/user)
	updateGloveArmor()

/datum/component/armor_sharer/proc/boots_equipped(datum/source, mob/user)
	updateBootArmor()

/datum/component/armor_sharer/proc/updateHelmetArmor()
	if(wearing_mob.head)
		helmet = wearing_mob.head
		if(istype(helmet))
			helmet.armor = wearing_mob.wear_suit.armor
		else
			helmet = null

/datum/component/armor_sharer/proc/updateGloveArmor()
	if(wearing_mob.gloves)
		gloves = wearing_mob.gloves
		if(istype(gloves))
			gloves.armor = wearing_mob.wear_suit.armor
		else
			gloves = null

/datum/component/armor_sharer/proc/updateBootArmor()
	if(wearing_mob.shoes)	
		boots = wearing_mob.shoes
		if(istype(boots))
			boots.armor = wearing_mob.wear_suit.armor
		else
			boots = null

/datum/component/armor_sharer/proc/resetHelmetArmor()
	if(!helmet && wearing_mob && wearing_mob.head)
		helmet = wearing_mob.head
	if(helmet && istype(helmet))
		helmet.armor = helmet.armor_original
	helmet = null

/datum/component/armor_sharer/proc/resetGloveArmor()
	if(!gloves && wearing_mob && wearing_mob.gloves)
		gloves = wearing_mob.gloves
	if(gloves && istype(gloves))
		gloves.armor = gloves.armor_original
	gloves = null

/datum/component/armor_sharer/proc/resetBootArmor()
	if(!boots && wearing_mob && wearing_mob.shoes)
		boots = wearing_mob.shoes
	if(boots && istype(boots))
		boots.armor = boots.armor_original
	boots = null

