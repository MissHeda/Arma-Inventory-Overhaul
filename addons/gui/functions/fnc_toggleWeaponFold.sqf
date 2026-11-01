#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Folds a weapon card of the equipment column to its header line, or opens it again (fnc_drawEquipmentCards) - a
 * click on the header's chevron or caption. The column's sections fold the same way, under "equipment", "gear" and
 * "hotbar". Folded, the header names the weapon and still takes a weapon dragged
 * onto it, but the card and its attachments are gone, so the column does not keep the room of a weapon that is not
 * used. The choice is each player's own, kept in the profile (GVAR(weaponFolds)); until the first click every card
 * is open but the second primary's, which is folded while nothing is on the back.
 *
 * Arguments:
 * 0: The card's slot, "primary", "primary2", "handgun" or "launcher" - or the section, "equipment", "gear" or "hotbar" <STRING>
 * 1: Folded now, as the card is drawn <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["launcher", false] call aio_gui_fnc_toggleWeaponFold;
 *
 * Public: No
 */

params [["_slot", "", [""]], ["_folded", false, [false]]];

if (_slot isEqualTo "") exitWith {};

GVAR(weaponFolds) set [_slot, !_folded];
profileNamespace setVariable [QGVAR(weaponFolds), (keys GVAR(weaponFolds)) apply {[_x, GVAR(weaponFolds) get _x]}];
saveProfileNamespace;

[] call FUNC(buildSoon);
