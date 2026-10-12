#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Eats or drinks, with ACE's field rations: its own function does it - the progress bar, the animation
 * and sound, what it quenches or satisfies, what is left (a bottle becomes half a bottle). The slot
 * follows that chain (fnc_useOf): the first of its items that is carried is the one used, so the key
 * keeps working until the bottle is empty.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Class <STRING>
 * 2: Slot index - not used <NUMBER>
 *
 * Return Value:
 * [done, text] - for done "" (ACE's bar names it), else why not <ARRAY>
 *
 * Example:
 * [player, "ACE_WaterBottle", 3] call einv_hotbar_fnc_useConsumable;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

if (isNil "ace_field_rations_fnc_consumeItem" || {!(missionNamespace getVariable ["acex_field_rations_enabled", false])}) exitWith {
    [false, LLSTRING(Reason_RationsOff)]
};

if (!([_unit, ["isNotInside", "isNotSitting"]] call FUNC(canAct))) exitWith {[false, LLSTRING(Reason_NotNow)]};

([_class] call FUNC(useOf)) params ["", "_chain"];

// The first of the chain that is carried: a full bottle before the half one it leaves.
private _items = items _unit;
private _magazines = magazines _unit;
private _item = "";

{
    private _candidate = _x;
    private _inMagazines = isClass (configFile >> "CfgMagazines" >> _candidate);
    private _carried = [_items, _magazines] select _inMagazines;

    if ((_carried findIf {_x == _candidate}) >= 0) exitWith {
        _item = _candidate;
    };
} forEach _chain;

if (_item isEqualTo "") exitWith {[false, LLSTRING(Reason_NoneLeft)]};

[objNull, _unit, [_item, _item call CBA_fnc_getItemConfig, isClass (configFile >> "CfgMagazines" >> _item)]] call ace_field_rations_fnc_consumeItem;

[true, ""]
