-- luacheck config for the Agentcraft addon (WoW Lua 5.1).
-- Run: powershell -NoProfile -ExecutionPolicy Bypass -File dev/dev.ps1 lint
-- Maintain read_globals with: dev/dev.ps1 globals (lists every global the
-- addon reads); add new client APIs here when the addon starts using them.
std = "lua51"
max_line_length = false
codes = true

exclude_files = {
  "dev/tools/**",
}

ignore = {
  "212/self",  -- unused self in methods
  "212/_.*",   -- unused arguments named _ or _x
  "211/_.*",   -- unused locals named _ or _x
  "213/_.*",   -- unused loop variables named _ or _x
}

-- The only globals the addon may set. Anything else (W111) is a missing
-- 'local' and a taint risk.
globals = {
  "Agentcraft",
  "AgentcraftDB",
  "AgentcraftCharDB",
  "SLASH_AGENTCRAFT1",
  "SLASH_AGENTCRAFT2",
  -- Opening the window without /ac (UI/Window.lua): the addon compartment
  -- calls these by name (TOC); the Key Bindings UI reads the labels.
  "Agentcraft_OnAddonCompartmentClick", "Agentcraft_OnAddonCompartmentEnter", "Agentcraft_OnAddonCompartmentLeave",
  "BINDING_HEADER_AGENTCRAFT", "BINDING_NAME_AGENTCRAFT_TOGGLE", "BINDING_NAME_AGENTCRAFT_KEYBOARD",
  "BINDING_NAME_AGENTCRAFT_CONTROLLER", "BINDING_NAME_AGENTCRAFT_MACROS",
  SlashCmdList = { fields = { "AGENTCRAFT" } },
  StaticPopupDialogs = { fields = { "AGENTCRAFT_CONFIRM" } },  -- UI.Confirm's dialog
}

files["addon/Agentcraft/Modules/_Template.lua"] = {
  ignore = { "211", "212" },
}
files["dev/**/*.lua"] = {
  std = "lua51",
  globals = { "test", "eq", "ok", "fail", "note", "noErrors", "describeCalls" },
}

read_globals = {
  -- WoW Lua extensions
  "date", "wipe", "tinsert", "tremove", "strsplit", "strtrim", "strjoin", "format", "Mixin", "CreateFromMixins",
  "hooksecurefunc", "issecretvalue", "issecurevariable", "debugstack", "geterrorhandler",

  -- C_ namespaces and Enum
  "C_ActionBar", "C_AddOns", "C_AuctionHouse", "C_ClassTalents", "C_Container", "C_CurrencyInfo", "C_CVar",
  "C_EquipmentSet", "C_FriendList", "C_GamePad", "C_GamepadUI", "C_GuildInfo", "C_Item", "C_Map",
  "C_MountJournal", "C_PetInfo", "C_PetJournal", "C_QuestLog", "C_Reputation", "C_Secrets", "C_SkillInfo", "C_Spell",
  "C_SpellBook", "C_StableInfo", "C_TaxiMap", "C_Timer", "Screenshot", "C_TooltipInfo", "C_TradeSkillUI", "C_Traits",
  "C_UnitAuras", "C_XMLUtil", "Enum", "Constants",

  -- Frames and UI
  "CreateFrame", "UIParent", "GameTooltip", "GameTooltip_Hide", "ChatFontNormal", "LootFrame",
  "RaidWarningFrame", "RaidNotice_AddMessage", "UISpecialFrames", "EnumerateFrames", "PlaySound",
  "ChatTypeInfo", "SOUNDKIT", "RAID_CLASS_COLORS", "CLASS_ICON_TCOORDS", "LOCALIZED_CLASS_NAMES_MALE",
  "GamepadActionBarBindingUtil",
  "ShowUIPanel", "HideUIPanel", "StaticPopup_Show", "GameTooltip_SetTitle", "GameTooltip_AddNormalLine",
  "CreateAtlasMarkup", "C_Texture", "C_ClassColor", "C_InputInterfaceStyle", "GamepadMode",
  "SetOverrideBindingClick", "ClearOverrideBindings", "SmartNavigation_MarkFrameIgnored",
  "SmartNavigation_MarkFrameSubSection", "SmartNavigation_MarkFrameIgnoredContainerFrame",
  "SmartNavigation_AddJumpNavigationOverride", "SmartNavigation_ClearJumpNavigationOverrides", "SMART_NAV_INPUT_DIRECTION",
  "StaticPopup_Visible", "StaticPopup_Hide", "PanelTemplates_SetNumTabs", "PanelTemplates_SetTab",
  "PanelTemplates_ResizeTabsToFit", "PanelTemplates_TabResize", "MenuUtil", "ScrollUtil",
  "MinimalSliderWithSteppersMixin", "GetBindingText",
  -- v2 window (UI/Input.lua, UI/Fx.lua, UI/Controls.lua): every one guarded by an existence check
  "CreateColor", "GameTooltip_Hide", "GetCursorPosition", "GetFramerate", "IsShiftKeyDown", "IsControlKeyDown",
  "IsAltKeyDown", "GetBindingFromClick", "GetCurrentKeyBoardFocus", "RegisterGameMenuEscHandler", "GameMenuEscPriority",
  "InputIconTextureSetUtility", "InputDeviceIconSetManager", "SmartNavigation", "GlowEmitterFactory", "GlowEmitterMixin",
  "NineSliceUtil",
  "NORMAL_FONT_COLOR", "HIGHLIGHT_FONT_COLOR", "GRAY_FONT_COLOR", "DISABLED_FONT_COLOR", "GREEN_FONT_COLOR",
  "RED_FONT_COLOR", "ORANGE_FONT_COLOR", "LIGHTBLUE_FONT_COLOR",

  -- Constants
  "ATTACHMENTS_MAX_RECEIVE", "BOOKTYPE_PET", "BOOKTYPE_SPELL", "MAX_ACCOUNT_MACROS", "MAX_CHARACTER_MACROS",
  "NUM_BAG_SLOTS", "NUM_BANKBAGSLOTS", "NUM_PET_ACTION_SLOTS", "NOT_BOUND", "YES", "NO", "FILTER", "SEARCH",

  -- Action bars, cursor, bindings, macros
  "ClearCursor", "GetActionInfo", "GetActionText", "GetActionTexture", "GetCursorInfo", "HasAction",
  "PickupAction", "PickupItem", "PickupMacro", "PickupSpell", "PlaceAction",
  "GetBinding", "GetBindingAction", "GetBindingKey", "GetCurrentBindingSet", "GetNumBindings",
  "SaveBindings", "SetBinding", "SetBindingItem", "SetBindingMacro", "SetBindingSpell", "CHARACTER_BINDINGS",
  "CreateMacro", "DeleteMacro", "EditMacro", "GetMacroBody", "GetMacroIndexByName", "GetMacroInfo", "GetNumMacros",
  "InCombatLockdown", "GetTime",

  -- Spells and pet
  "GetFlyoutInfo", "GetFlyoutSlotInfo", "GetSpellBookItemInfo", "GetSpellBookItemName", "GetSpellInfo",
  "GetSpellTabInfo", "GetNumSpellTabs", "GetSpellTexture", "HasPetSpells", "IsPassiveSpell", "IsPlayerSpell",
  "IsSpellKnown", "GetPetActionInfo", "GetPetExperience", "GetPetFoodTypes", "GetPetHappiness",
  "GetPetLoyalty", "GetPetTrainingPoints", "GetStablePetInfo", "GetCompanionInfo", "GetNumCompanions",

  -- Talents (classic fallbacks; missing on the modern client, always guarded)
  "GetBonusBarOffset", "GetShapeshiftForm", "GetNumTalents", "GetNumTalentTabs", "GetTalentInfo", "GetTalentTabInfo", "GetUnspentTalentPoints",
  "UnitCharacterPoints",

  -- Items, bags, equipment
  "CursorHasItem", "EquipCursorItem", "EquipItemByName", "GetContainerItemID", "GetContainerItemInfo", "GetContainerNumSlots",
  "UnitIsDeadOrGhost", "ExpandQuestHeader", "CollapseQuestHeader", "ExpandSkillHeader", "CollapseSkillHeader",
  "ExpandFactionHeader", "CollapseFactionHeader",
  "GetInventoryItemCount", "GetInventoryItemDurability", "GetInventoryItemID", "GetInventoryItemLink",
  "GetInventoryItemQuality", "GetItemIcon", "GetItemInfo", "GetItemSpell", "GetWeaponEnchantInfo",

  -- Professions and crafting
  "GetCraftDisplaySkillLine", "GetCraftInfo", "GetCraftNumReagents", "GetCraftReagentInfo", "GetNumCrafts",
  "GetNumSkillLines", "GetNumTradeSkills", "GetProfessionInfo", "GetProfessions", "GetSkillLineInfo",
  "GetTradeSkillInfo", "GetTradeSkillLine", "GetTradeSkillNumReagents", "GetTradeSkillReagentInfo",

  -- Character and stats
  "GetBlockChance", "GetCritChance", "GetDodgeChance", "GetExpertise", "GetHitModifier", "GetManaRegen",
  "GetMaxPlayerLevel", "GetMeleeHaste", "GetMoney", "GetParryChance", "GetPVPLifetimeStats",
  "GetRangedCritChance", "GetRangedHaste", "GetSpellBonusDamage", "GetSpellBonusHealing", "GetSpellCritChance",
  "GetSpellHitModifier", "GetXPExhaustion", "IsMounted", "UnitArmor", "UnitAttackPower", "UnitAttackSpeed",
  "UnitBuff", "UnitChannelInfo", "UnitClass", "UnitCreatureFamily", "UnitDamage", "UnitDefense", "UnitExists",
  "UnitHealth", "UnitHealthMax", "UnitHealthPercent", "UnitHonor", "UnitLevel", "UnitName", "UnitPower", "UnitPowerMax", "UnitPowerPercent",
  "UnitPVPRank", "UnitRace", "UnitRangedAttackPower", "UnitRangedDamage", "UnitResistance", "UnitSpellHaste",
  "UnitStat", "UnitXP", "UnitXPMax",

  -- World, social, mail, auctions, quests
  "GetAddOnMetadata", "GetAuctionItemInfo", "GetBindLocation", "GetFactionInfo", "GetGuildInfo",
  "GetGuildRosterInfo", "GetInboxHeaderInfo", "GetInboxItem", "GetInboxNumItems", "GetNumAuctionItems",
  "GetNumFactions", "GetNumGroupMembers", "GetNumGuildMembers", "GetNumQuestLogEntries", "GetNumSavedInstances",
  "GetQuestLogTitle", "GetRealmName", "GetSavedInstanceInfo", "GetSubZoneText", "GetTaxiMapID", "GetZoneText",
  "IsInGuild", "IsInRaid", "NumTaxiNodes", "RequestRaidInfo", "RequestTimePlayed", "TaxiNodeGetType",
  "TaxiNodeName",
}
