#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The picture of a category (ITEM_GROUPS): the watermark an empty compartment that accepts only that category shows
 * (fnc_drawCompartments). The textures are the slot pictures of the equipment column and of the strip at the side of a loot box.
 *
 * Arguments:
 * 0: The category - "weapon", "ammo", "grenade", "gear", "medical", "food", "tool" or "misc" <STRING>
 *
 * Return Value:
 * The texture, "" for a word that is no category <STRING>
 *
 * Example:
 * ["grenade"] call einv_gui_fnc_groupTexture;
 *
 * Public: No
 */

params [["_group", "", [""]]];

switch (_group) do {
    case "weapon": {UI_TEX(slot_rifle_ca)};
    case "ammo": {UI_TEX(slot_magazine_ca)};
    case "grenade": {UI_TEX(slot_grenade_ca)};
    case "gear": {UI_TEX(slot_vest_ca)};
    case "medical": {UI_TEX(slot_cat_medical_ca)};
    case "food": {UI_TEX(slot_cat_food_ca)};
    case "tool": {UI_TEX(slot_radio_ca)};
    case "misc": {UI_TEX(slot_cat_misc_ca)};
    default {""};
}
