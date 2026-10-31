#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Tells ACE that a class in the open uniform, vest or backpack changed through the panel - taken out, put
 * back out, or put in where ACE's own add was refused - the way ACE tells of its own changes
 * (ace_arsenal_fnc_fireItemsChangedEvent): other mods hear of it as of an add or removal in ACE's list,
 * and this addon follows up on it like on any other (fnc_onItemsChanged). An ACE without that event: the
 * follow-up is called directly.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: How many there were <NUMBER>
 * 2: How many there are now <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ACE_fieldDressing", 4, 3] call aio_arsenal_fnc_tellAce;
 *
 * Public: No
 */

disableSerialization;

params [["_class", "", [""]], ["_before", 0, [0]], ["_after", 0, [0]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display || {_before == _after}) exitWith {};

(call FUNC(selected)) params ["", "", "_panel"];

// No container's tab open - Enhanced First Aid Kits' kits tab over ACE's panels: ACE's list takes nothing to hear
// of (fnc_syncAce keeps ACE's record of the containers right then).
if (_panel < 0) exitWith {};

if (isNil QACEFUNC(arsenal,fireItemsChangedEvent)) exitWith {
    [_display] call FUNC(reconcile);
    [] call FUNC(settle);
};

[
    _display, _panel, createHashMapFromArray [[_class, _before]], createHashMapFromArray [[_class, _after]]
] call ACEFUNC(arsenal,fireItemsChangedEvent);
