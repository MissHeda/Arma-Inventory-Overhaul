#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens ACE Arsenal for a vanilla Virtual Arsenal's box, with the same items (fnc_biItems). Everything:
 * ACE's full arsenal. Else ACE's own function classifies the class names (ace_arsenal_fnc_addVirtualItems -
 * it takes base weapons, config-cases the names and drops what the game does not know) onto a helper of
 * this machine's only, and ACE opens with that helper as its box; the box itself is never touched. The
 * helper goes when ACE's window closes (fnc_onClosed), or when the next one is made.
 *
 * Arguments:
 * 0: The vanilla box, or the unit itself for a full arsenal <OBJECT>
 * 1: Unit to dress <OBJECT>
 * 2: Everything <BOOL>
 * 3: Class names (fnc_biItems) <ARRAY>
 *
 * Return Value:
 * Opening <BOOL>
 *
 * Example:
 * [_box, player, false, _classes] call aio_arsenal_fnc_openBI;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]], ["_center", objNull, [objNull]], ["_full", false, [false]], ["_classes", [], [[]]]];

if (isNull _center || {!GVAR(ready)}) exitWith {false};

if (_full) exitWith {
    [[_box, _center] select (isNull _box), _center, true] call ACEFUNC(arsenal,openBox);
    true
};

if (!isNull GVAR(biHelper)) then {
    deleteVehicle GVAR(biHelper);
};

private _helper = "Land_HelipadEmpty_F" createVehicleLocal [0, 0, 0];
[_helper, _classes, false] call ACEFUNC(arsenal,addVirtualItems);

if (isNil {_helper getVariable QACEGVAR(arsenal,virtualItems)}) exitWith {
    deleteVehicle _helper;
    [localize "STR_ace_arsenal_noVirtualItems", false, 5, 1] call ACEFUNC(common,displayText);
    false
};

GVAR(biHelper) = _helper;

[_helper, _center] call ACEFUNC(arsenal,openBox);

true
