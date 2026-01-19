extends Node

# ArtRegistry - maps art_id to texture paths using png_filenames.md

# Art mapping based on png_filenames.md
const ART_MAPPING = {
	# Card art
	"art_sap_shot": "res://Art/art_sap_shot.png",
	"art_seed_shield": "res://Art/art_seed_shield.png",
	"art_blossom_strike": "res://Art/art_blossom_strike.png",
	"art_thorn_lash": "res://Art/art_thorn_lash.png",
	"art_vine_whip": "res://Art/art_vine_whip.png",
	"art_sprout_heal": "res://Art/art_sprout_heal.png",
	"art_growth_aura": "res://Art/art_growth_aura.png",
	"art_seed_surge": "res://Art/art_seed_surge.png",
	"art_arc_bolt": "res://Art/art_arc_bolt.png",
	"art_avalanche": "res://Art/art_avalanche.png",
	"art_blight_barrier": "res://Art/art_blight_barrier.png",
	"art_blight_jab": "res://Art/art_blight_jab.png",
	"art_blight_shield": "res://Art/art_blight_shield.png",
	"art_blighted_bolt": "res://Art/art_blighted_bolt.png",
	"art_blighted_path": "res://Art/art_blighted_path.png",
	"art_blooming_edge": "res://Art/art_blooming_edge.png",
	"art_blooming_ward": "res://Art/art_blooming_ward.png",
	"art_bone_graft": "res://Art/art_bone_graft.png",
	"art_bud_barrier": "res://Art/art_bud_barrier.png",
	"art_bud_burst": "res://Art/art_bud_burst.png",
	"art_burning_ritual": "res://Art/art_burning_ritual.png",
	"art_carcass_trap": "res://Art/art_carcass_trap.png",
	"art_carrion_cage": "res://Art/art_carrion_cage.png",
	"art_carrion_whip": "res://Art/art_carrion_whip.png",
	"art_chain_lightning": "res://Art/art_chain_lightning.png",
	"art_contagion_strike": "res://Art/art_contagion_strike.png",
	"art_corrosive_edge": "res://Art/art_corrosive_edge.png",
	"art_corruption_ritual": "res://Art/art_corruption_ritual.png",
	"art_death_sentries": "res://Art/art_death_sentries.png",
	"art_deaths_embrace": "res://Art/art_deaths_embrace.png",
	"art_deaths_kiss": "res://Art/art_deaths_kiss.png",
	"art_decay_bubble": "res://Art/art_decay_bubble.png",
	"art_decay_communion": "res://Art/art_decay_communion.png",
	"art_decay_glyph": "res://Art/art_decay_glyph.png",
	"art_decay_surge": "res://Art/art_decay_surge.png",
	"art_electro_glyph": "res://Art/art_electro_glyph.png",
	"art_electro_surge": "res://Art/art_electro_surge.png",
	"art_elemental_ritual": "res://Art/art_elemental_ritual.png",
	"art_elemental_ward": "res://Art/art_elemental_ward.png",
	"art_ember_bond": "res://Art/art_ember_bond.png",
	"art_ember_shot": "res://Art/art_ember_shot.png",
	"art_eternal_blossom": "res://Art/art_eternal_blossom.png",
	"art_eternal_decay": "res://Art/art_eternal_decay.png",
	"art_eternal_elemental": "res://Art/art_eternal_elemental.png",
	"art_fertile_soil": "res://Art/art_fertile_soil.png",
	"art_festering_aura": "res://Art/art_festering_aura.png",
	"art_festering_roots": "res://Art/art_festering_roots.png",
	"art_flame_guard": "res://Art/art_flame_guard.png",
	"art_flame_lash": "res://Art/art_flame_lash.png",
	"art_frost_armor": "res://Art/art_frost_armor.png",
	"art_frost_bite": "res://Art/art_frost_bite.png",
	"art_frost_step": "res://Art/art_frost_step.png",
	"art_frost_wall": "res://Art/art_frost_wall.png",
	"art_frozen_path": "res://Art/art_frozen_path.png",
	"art_fungal_fortress": "res://Art/art_fungal_fortress.png",
	"art_fungus_flail": "res://Art/art_fungus_flail.png",
	"art_gale_slash": "res://Art/art_gale_slash.png",
	"art_garden_bloom": "res://Art/art_garden_bloom.png",
	"art_gilded_bud": "res://Art/art_gilded_bud.png",
	"art_glacial_edge": "res://Art/art_glacial_edge.png",
	"art_glacial_surge": "res://Art/art_glacial_surge.png",
	"art_growth_glyph": "res://Art/art_growth_glyph.png",
	"art_growth_ritual": "res://Art/art_growth_ritual.png",
	"art_gust_barrier": "res://Art/art_gust_barrier.png",
	"art_ice_shard": "res://Art/art_ice_shard.png",
	"art_ichor_of_life": "res://Art/art_ichor_of_life.png",
	"art_icy_embrace": "res://Art/art_icy_embrace.png",
	"art_infectious_veil": "res://Art/art_infectious_veil.png",
	"art_lava_burst": "res://Art/art_lava_burst.png",
	"art_lava_flow": "res://Art/art_lava_flow.png",
	"art_magma_mantle": "res://Art/art_magma_mantle.png",
	"art_malignant_flow": "res://Art/art_malignant_flow.png",
	"art_molten_ward": "res://Art/art_molten_ward.png",
	"art_mossy_guard": "res://Art/art_mossy_guard.png",
	"art_natures_boon": "res://Art/art_natures_boon.png",
	"art_necrotic_infusion": "res://Art/art_necrotic_infusion.png",
	"art_noxious_rip": "res://Art/art_noxious_rip.png",
	"art_overgrowth": "res://Art/art_overgrowth.png",
	"art_pestilence_storm": "res://Art/art_pestilence_storm.png",
	"art_pestilent_bond": "res://Art/art_pestilent_bond.png",
	"art_pestilent_strike": "res://Art/art_pestilent_strike.png",
	"art_petal_parade": "res://Art/art_petal_parade.png",
	"art_petal_pierce": "res://Art/art_petal_pierce.png",
	"art_petal_spray": "res://Art/art_petal_spray.png",
	"art_petal_step": "res://Art/art_petal_step.png",
	"art_petal_veil": "res://Art/art_petal_veil.png",
	"art_plague_burst": "res://Art/art_plague_burst.png",
	"art_poisonous_aura": "res://Art/art_poisonous_aura.png",
	"art_putrid_cleave": "res://Art/art_putrid_cleave.png",
	"art_putrid_renew": "res://Art/art_putrid_renew.png",
	"art_putrid_ward": "res://Art/art_putrid_ward.png",
	"art_rancid_step": "res://Art/art_rancid_step.png",
	"art_root_smash": "res://Art/art_root_smash.png",
	"art_rooted_resolve": "res://Art/art_rooted_resolve.png",
	"art_rooting_pulse": "res://Art/art_rooting_pulse.png",
	"art_rotten_shield": "res://Art/art_rotten_shield.png",
	"art_rotting_ritual": "res://Art/art_rotting_ritual.png",
	"art_rotting_slash": "res://Art/art_rotting_slash.png",
	"art_rune_of_defense": "res://Art/art_rune_of_defense.png",
	"art_rune_of_elements": "res://Art/art_rune_of_elements.png",
	"art_rune_of_fury": "res://Art/art_rune_of_fury.png",
	"art_sanguine_shield": "res://Art/art_sanguine_shield.png",
	"art_sappy_lunge": "res://Art/art_sappy_lunge.png",
	"art_scorching_aura": "res://Art/art_scorching_aura.png",
	"art_sear_decay": "res://Art/art_sear_decay.png",
	"art_seed_of_renewal": "res://Art/art_seed_of_renewal.png",
	"art_seeded_slash": "res://Art/art_seeded_slash.png",
	"art_seedlings": "res://Art/art_seedlings.png",
	"art_shockwave": "res://Art/art_shockwave.png",
	"art_spark_jab": "res://Art/art_spark_jab.png",
	"art_sprouting_might": "res://Art/art_sprouting_might.png",
	"art_sprout_sentry": "res://Art/art_sprout_sentry.png",
	"art_static_shield": "res://Art/art_static_shield.png",
	"art_storm_fang": "res://Art/art_storm_fang.png",
	"art_storm_ritual": "res://Art/art_storm_ritual.png",
	"art_storm_sentinel": "res://Art/art_storm_sentinel.png",
	"art_storms_embrace": "res://Art/art_storms_embrace.png",
	"art_thorn_barrage": "res://Art/art_thorn_barrage.png",
	"art_thorn_wall": "res://Art/art_thorn_wall.png",
	"art_thorned_blade": "res://Art/art_thorned_blade.png",
	"art_thorned_roots": "res://Art/art_thorned_roots.png",
	"art_thunder_clap": "res://Art/art_thunder_clap.png",
	"art_thunder_ward": "res://Art/art_thunder_ward.png",
	"art_toxic_infusion": "res://Art/art_toxic_infusion.png",
	"art_toxic_transfusion": "res://Art/art_toxic_transfusion.png",
	"art_verdant_bond": "res://Art/art_verdant_bond.png",
	"art_verdant_warding": "res://Art/art_verdant_warding.png",
	"art_vine_cleaver": "res://Art/art_vine_cleaver.png",
	"art_vine_trap": "res://Art/art_vine_trap.png",
	"art_virulent_fangs": "res://Art/art_virulent_fangs.png",
	"art_volt_barrage": "res://Art/art_volt_barrage.png",
	"art_wind_cleave": "res://Art/art_wind_cleave.png",
	"art_zephyr_shield": "res://Art/art_zephyr_shield.png",
	"art_zephyr_veil": "res://Art/art_zephyr_veil.png",
	
	# Backgrounds
	"forest_combat": "res://Art/forest_combat.png",
	"growth_combat": "res://Art/forest_combat.png",  # Alias for forest_combat
	
	# UI elements
	"card_back": "res://Art/card_back.png",
	"button_end_turn": "res://Art/button_end_turn.9.png",
	"button_buy": "res://Art/button_buy.9.png",
	"button_skip": "res://Art/button_skip.9.png",
	"cost_orb": "res://Art/cost_orb.png",
	"frame_common": "res://Art/frame_common.png",
	"frame_uncommon": "res://Art/frame_uncommon.png",
	"frame_rare": "res://Art/frame_rare.png",
	"icon_block": "res://Art/icon_block.png",
	"icon_damage": "res://Art/icon_damage.png",
	"gold": "res://Art/gold.png",
	"modal": "res://Art/modal.9.png",
	"panel_dark": "res://Art/panel_dark.9.png",
	"tooltip": "res://Art/tooltip.9.png",
	
	# Targeting
	"target_ring": "res://Art/target_ring.png",
	"target_ring_enemy": "res://Art/target_ring_enemy.png",
	"target_ring_boss": "res://Art/target_ring_boss.png",
	"target_ring_friendly": "res://Art/target_ring_friendly.png",
	"target_ring_hover": "res://Art/target_ring_hover.png",
	"target_ring_pressed": "res://Art/target_ring_pressed.png",
	
	# Enemies
	"bone_husk": "res://Art/bone_husk.png",
	"chrono_gaurdian": "res://Art/chrono_gaurdian.png",
	"decay_caller": "res://Art/decay_caller.png",
	"ember_weaver": "res://Art/ember_weaver.png",
	"flame_wisp": "res://Art/flame_wisp.png",
	"frostbreaker": "res://Art/frostbreaker.png",
	"glyphbound_scribe": "res://Art/glyphbound_scribe.png",
	"iron_sentinel": "res://Art/iron_sentinel.png",
	"mindforger": "res://Art/mindforger.png",
	"mold_spitter": "res://Art/mold_spitter.png",
	"rot_crawler": "res://Art/rot_crawler.png",
	"rune_binder": "res://Art/rune_binder.png",
	"sap_warden": "res://Art/sap_warden.png",
	"sludge_fiend": "res://Art/sludge_fiend.png",
	"soul_reaper": "res://Art/soul_reaper.png",
	"spore_puffer": "res://Art/spore_puffer.png",
	"sproutling": "res://Art/sproutling.png",
	"stone_golem": "res://Art/stone_golem.png",
	"stone_warden": "res://Art/stone_warden.png",
	"storm_caller": "res://Art/storm_caller.png",
	"storm_imp": "res://Art/storm_imp.png",
	"venom_prince": "res://Art/venom_prince.png",
	"vine_shooter": "res://Art/vine_shooter.png",
	"water_sprite": "res://Art/water_sprite.png",
	
	# Sigils
	"aegis_of_the_ancients": "res://Art/aegis_of_the_ancients.png",
	"ancient_spark": "res://Art/ancient_spark.png",
	"avatars_core": "res://Art/avatars_core.png",
	"battleforged_crest": "res://Art/battleforged_crest.png",
	"catalyst_of_wrath": "res://Art/catalyst_of_wrath.png",
	"chronomancers_pendant": "res://Art/chronomancers_pendant.png",
	"echo_of_fortune": "res://Art/echo_of_fortune.png",
	"ember_shard": "res://Art/ember_shard.png",
	"focused_lens": "res://Art/focused_lens.png",
	"greeds_edge": "res://Art/greeds_edge.png",
	"ironbound_sigil": "res://Art/ironbound_sigil.png",
	"mana_tap": "res://Art/mana_tap.png",
	"quickstep_emblem": "res://Art/quickstep_emblem.png",
	"resonant_heart": "res://Art/resonant_heart.png",
	"reverberating_echo": "res://Art/reverberating_echo.png",
	"shard_of_insight": "res://Art/shard_of_insight.png",
	"sigil_of_renewal": "res://Art/sigil_of_renewal.png",
	"soul_nexus": "res://Art/soul_nexus.png",
	"vital_coil": "res://Art/vital_coil.png",
	"worldbreaker_glyph": "res://Art/worldbreaker_glyph.png"
}

func _ready() -> void:
	pass

func get_texture(art_id: String) -> Texture2D:
	# Get texture for the given art_id, fallback to card_back if not found
	if art_id == "" or not ART_MAPPING.has(art_id):
		# Fallback to card_back
		if ART_MAPPING.has("card_back"):
			var fallback_path = ART_MAPPING["card_back"]
			if ResourceLoader.exists(fallback_path):
				return load(fallback_path)
		return null
	
	var path = ART_MAPPING[art_id]
	if ResourceLoader.exists(path):
		return load(path)
	
	# Fallback to card_back if the mapped path doesn't exist
	if ART_MAPPING.has("card_back"):
		var fallback_path = ART_MAPPING["card_back"]
		if ResourceLoader.exists(fallback_path):
			return load(fallback_path)
	
	return null

func get_art_path(art_id: String) -> String:
	# Get the resource path for the given art_id
	if ART_MAPPING.has(art_id):
		return ART_MAPPING[art_id]
	return ART_MAPPING.get("card_back", "")

func has_art(art_id: String) -> bool:
	# Check if art_id exists in the mapping
	return ART_MAPPING.has(art_id)
