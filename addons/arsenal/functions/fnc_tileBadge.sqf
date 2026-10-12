#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mark in the top left corner of an item that this arsenal does not offer (the "tileBadge" hook).
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * A texture, "" for no mark <STRING>
 *
 * Example:
 * ["arifle_MX_F"] call einv_arsenal_fnc_tileBadge;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "" || {!([_class] call FUNC(isUnique))}) exitWith {""};

ICON(icon_unique_ca,icon_auto_ca)
