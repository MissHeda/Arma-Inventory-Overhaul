#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player's loadout changed: while the inventory window is open (not ACE Arsenal's panel) and the primary slot went empty, the weapon
 * WebKnight's Two Primary Weapons carries on his back comes into his hands, as that mod's own "Put" handler does
 * for the engine's inventory. Only while the window is open - that mod's key does not run then (CBA keybinds wait
 * for the dialog), so an empty slot is never one of its own switches half done.
 *
 * Arguments:
 * 0: Player's unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call einv_compat_wbk_twoprimary_fnc_onLoadout;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit} || {!local _unit} || {!isNull objectParent _unit}) exitWith {};
if (isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull]) || {!(call EFUNC(gui,isInventoryMode))}) exitWith {};
if (primaryWeapon _unit isNotEqualTo "") exitWith {};

private _second = _unit getVariable "WBK_SecondWeapon";

if (isNil "_second" || {!(_second isEqualType [])}) exitWith {};

_second params [["_box", objNull, [objNull]], ["_weapon", [], [[]]]];

if (_weapon isEqualTo [] || {!((_weapon select 0) isEqualType "")}) exitWith {};

// As that mod does: the box goes, the variable with it, and the weapon is in the hands with its attachments and the
// magazines in it - loaded straight into the weapon, so a full vest loses no round.
_unit setVariable ["WBK_SecondWeapon", nil, true];

if (!isNull _box) then {
    deleteVehicle _box;
};

[_unit, _weapon select 0] call CBA_fnc_addWeaponWithoutItems;

private _class = primaryWeapon _unit;

if (_class isEqualTo "") exitWith {
    WARNING_1("Could not bring %1 from the back into the hands.",_weapon select 0);
};

{
    switch (true) do {
        case (_x isEqualType "" && {_x isNotEqualTo ""}): {
            _unit addPrimaryWeaponItem _x;
        };
        case (_x isEqualType [] && {_x isNotEqualTo []} && {(_x select 0) isEqualType ""}): {
            _unit addWeaponItem [_class, [_x select 0, _x param [1, 1]], true];
        };
    };
} forEach (_weapon select [1]);

INFO_1("Brought %1 from the back into the hands (WebKnight's Two Primary Weapons).",_class);
