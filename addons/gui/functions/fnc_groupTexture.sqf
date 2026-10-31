#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The picture of a category (ITEM_GROUPS or one the setup defines): the strip at the side of a loot box, the watermark and the
 * badge of a compartment that accepts only that category (fnc_drawCompartments, fnc_drawBadge). The picture the setup gave the
 * category (picture=, aio_items_fnc_categoryInfo) - for a built-in one too -, else the slot pictures of the equipment column
 * for the eight built-in ones and a star for a category of the setup's own that has none.
 *
 * Arguments:
 * 0: The category's id - "weapon", "ammo", "grenade", "gear", "medical", "food", "tool", "misc" or one of the setup's own <STRING>
 * 1: Compiled rules to take the category's picture from - the wizard's draft; the rules in effect when left out <HASHMAP> (default: empty)
 *
 * Return Value:
 * The texture, "" for a word that is no category <STRING>
 *
 * Example:
 * ["grenade"] call aio_gui_fnc_groupTexture;
 *
 * Public: No
 */

params [["_group", "", [""]], ["_compiled", createHashMap, [createHashMap]]];

private _info = [_group, _compiled] call EFUNC(items,categoryInfo);
private _own = _info get "picture";

if (_own isNotEqualTo "") exitWith {_own};

switch (_group) do {
    case "weapon": {UI_TEX(slot_rifle_ca)};
    case "ammo": {UI_TEX(slot_magazine_ca)};
    case "grenade": {UI_TEX(slot_grenade_ca)};
    case "gear": {UI_TEX(slot_vest_ca)};
    case "medical": {UI_TEX(slot_cat_medical_ca)};
    case "food": {UI_TEX(slot_cat_food_ca)};
    case "tool": {UI_TEX(slot_radio_ca)};
    case "misc": {UI_TEX(slot_cat_misc_ca)};
    default {[UI_TEX(icon_star_ca), ""] select (_group isEqualTo "" || {!(_info get "known")})};
}
