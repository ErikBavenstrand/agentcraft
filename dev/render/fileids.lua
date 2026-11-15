-- Texture file IDs the renderer can draw, mapped to their Interface path.
-- The fixture and mock hand out file IDs (spell and item icons), which have
-- no path of their own. dev.ps1 render -Fetch adds the ones a render reports
-- missing (named through the wago.tools file search, which reads the
-- github.com/wowdev/wow-listfile community listfile); entries can also be added by hand.
return {
  [134400] = "Interface\\Icons\\INV_Misc_QuestionMark",  -- mock default item/action icon
  [136243] = "Interface\\Icons\\Trade_Engineering",      -- mock default spell icon
  [132118] = "interface\\icons\\ability_druid_cower",
  [132150] = "interface\\icons\\ability_eyeoftheowl",
  [132153] = "interface\\icons\\ability_golemstormbolt",
  [132157] = "interface\\icons\\ability_hunter_aimedshot",
  [132159] = "interface\\icons\\ability_hunter_aspectofthemonkey",
  [132161] = "interface\\icons\\ability_hunter_beastcall",
  [132162] = "interface\\icons\\ability_hunter_beastcall02",
  [132163] = "interface\\icons\\ability_hunter_beastsoothe",
  [132164] = "interface\\icons\\ability_hunter_beasttaming",
  [132165] = "interface\\icons\\ability_hunter_beasttraining",
  [132172] = "interface\\icons\\ability_hunter_eagleeye",
  [132179] = "interface\\icons\\ability_hunter_mendpet",
  [132204] = "interface\\icons\\ability_hunter_quickshot",
  [132208] = "interface\\icons\\ability_hunter_runningshot",
  [132212] = "interface\\icons\\ability_hunter_snipershot",
  [132215] = "interface\\icons\\ability_hunter_swiftstrike",
  [132218] = "interface\\icons\\ability_impalingbolt",
  [132222] = "interface\\icons\\ability_marksmanship",
  [132223] = "interface\\icons\\ability_meleedamage",
  [132242] = "interface\\icons\\ability_mount_jungletiger",
  [132267] = "interface\\icons\\ability_mount_whitetiger",
  [132270] = "interface\\icons\\ability_physical_taunt",
  [132278] = "interface\\icons\\ability_racial_cannibalize",
  [132293] = "interface\\icons\\ability_rogue_feigndeath",
  [132294] = "interface\\icons\\ability_rogue_feint",
  [132309] = "interface\\icons\\ability_rogue_trip",
  [132328] = "interface\\icons\\ability_tracking",
  [132329] = "interface\\icons\\ability_trueshot",
  [132330] = "interface\\icons\\ability_upgrademoonglaive",
  [132336] = "interface\\icons\\ability_warrior_challange",
  [133971] = "interface\\icons\\inv_misc_food_15",
  [135130] = "interface\\icons\\inv_spear_07",
  [135726] = "interface\\icons\\racial_orc_berserkerstrength",
  [135805] = "interface\\icons\\spell_fire_fire",
  [135815] = "interface\\icons\\spell_fire_flare",
  [135826] = "interface\\icons\\spell_fire_selfdestruct",
  [135834] = "interface\\icons\\spell_frost_chainsofice",
  [135840] = "interface\\icons\\spell_frost_freezingbreath",
  [135860] = "interface\\icons\\spell_frost_stun",
  [135942] = "interface\\icons\\spell_holy_prayerofhealing",
  [136020] = "interface\\icons\\spell_nature_drowsy",
  [136076] = "interface\\icons\\spell_nature_ravenform",
  [136095] = "interface\\icons\\spell_nature_spiritwolf",
  [136192] = "interface\\icons\\spell_shadow_sealofkings",
  [136245] = "interface\\icons\\trade_fishing",  -- added by render -Fetch
  [135813] = "interface\\icons\\spell_fire_flameshock",  -- added by render -Fetch
  [132400] = "interface\\icons\\inv_axe_09",
  [133682] = "interface\\icons\\inv_misc_bandage_12",
  [134414] = "interface\\icons\\inv_misc_rune_01",
  [134834] = "interface\\icons\\inv_potion_54",  -- added by render -Fetch
}
