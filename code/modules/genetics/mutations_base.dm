GLOBAL_LIST_INIT(dna_machinery_styles, list(
	"cyan",
	"yellow",
	"purple"))


GLOBAL_LIST_INIT(mutation_limit_by_tier, list(
	"0" = 5, // Nero
	"1" = 4, // Vespasian
	"2" = 3, // Tacitus
	"3" = 2, // Hadrian
	"4" = 1)) // Aurelien


var/global/default_dna_machinery_style


/hook/startup/proc/pick_dna_machinery_style()
	default_dna_machinery_style = pick(GLOB.dna_machinery_styles)


proc/can_get_mutation(mob/user, tier)
	if(user.mutation_count_by_tier["[tier]"] < GLOB.mutation_limit_by_tier["[tier]"])
		return TRUE


proc/get_dormant_mutation(mob/user, mutation_type)
	for(var/datum/mutation/M in user.dormant_mutations)
		if(ispath(M.type, mutation_type))
			return M


proc/get_active_mutation(mob/user, mutation_type)
	for(var/datum/mutation/M in user.active_mutations)
		if(ispath(M.type, mutation_type))
			return M


/datum/computer_file/binary/animalgene
	filetype = "ADNA"
	size = 5
	var/gene_type
	var/gene_value


/datum/mutation
	var/name = "Unknown"
	var/desc = "Unknown"
	var/hex = "FFFFFF"
	var/tier_num = 0 // 0, 1, 2, 3, 4
	var/tier_string = "Nero" // "Nero", "Vespasian", "Tacitus", "Hadrian", "Aurelien"
	var/NSA_load = 1 // How much NSA holder get if mutation is active
	var/is_active = FALSE
	var/domino_r = 1
	var/domino_l = 1
	var/buff_type
	var/buff_power


/datum/mutation/New()
	hex = num2hex(rand(21845, 65535))
	domino_r = pick(1, 2, 3, 4, 5, 6, 7, 8)
	domino_l = pick(1, 2, 3, 4, 5, 6, 7, 8)


/datum/mutation/proc/imprint(mob/living/carbon/user)
	if(!istype(user))
		return FALSE

	if(!can_get_mutation(user, tier_num))
		return FALSE // Maximum mutations of that tier

	if(get_active_mutation(user, type))
		return FALSE // Already have that mutation

	var/datum/mutation/duplicate = get_dormant_mutation(user, type)

	if(duplicate)
		user.dormant_mutations -= duplicate

	user.active_mutations |= src
	user.metabolism_effects.adjust_nsa(NSA_load, "Mutation_[hex]_[name]")
	user.mutation_count_by_tier["[tier_num]"]++
	user.mutation_index += tier_num

	return TRUE


/datum/mutation/proc/cleanse(mob/living/carbon/user)
	if(!istype(user))
		return FALSE

	if(!get_dormant_mutation(user, type))
		user.dormant_mutations |= src

	user.active_mutations -= src
	user.metabolism_effects.remove_nsa("Mutation_[hex]_[name]")
	user.mutation_count_by_tier["[tier_num]"]--
	user.mutation_index -= tier_num

	return TRUE


/datum/mutation/proc/clone()
	var/datum/mutation/M = new type
	M.name = name
	M.desc = desc
	M.hex = hex
	M.tier_num = tier_num
	M.tier_string = tier_string
	M.NSA_load = NSA_load
	M.is_active = is_active
	M.domino_r = domino_r
	M.domino_l = domino_l
	M.buff_type = buff_type
	M.buff_power = buff_power
	return M