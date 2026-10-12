#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts an item class on a slot of the hotbar. Nothing moves - the item stays where it lies; the slot
 * only remembers its class, so any item of that class is used and a new one picked up later works
 * as well. The class leaves any other slot it was on. Saved in the profile at once.
 *
 * Refused when the item does nothing from the bar, is not carried, or fits no weapon (fnc_canBindFrom):
 * the reason shows in the window's hint, else as a message on the screen.
 *
 * Arguments:
 * 0: Slot index, 0 to 6 <NUMBER>
 * 1: Class <STRING>
 * 2: Where it lies, as fnc_canBindFrom takes it; [] for no check of that <ARRAY> (default: [])
 * 3: Already checked - the window's drag asked fnc_canBindFrom itself while it ran <BOOL> (default: false)
 *
 * Return Value:
 * Put on the slot <BOOL>
 *
 * Example:
 * [1, "ACE_elasticBandage"] call einv_hotbar_fnc_bind;
 *
 * Public: Yes
 */

params [["_index", -1, [0]], ["_class", "", [""]], ["_from", [], [[]]], ["_checked", false, [false]]];

if (_index < 0 || {_index >= SLOT_COUNT} || {_class isEqualTo ""} || {!(call FUNC(isActive))}) exitWith {false};

private _window = !isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull]);

// The drag has asked already (checked); everything else is asked here.
private _allowed = _checked;

if (!_allowed) then {
    ([_class, _from] call FUNC(canBindFrom)) params ["_ok", "_why"];

    _allowed = _ok;

    if (!_ok) then {
        if (_window) then {
            [_why] call EFUNC(gui,flashHint);
        } else {
            [_why] call ace_common_fnc_displayTextStructured;
        };
    };
};

if (!_allowed) exitWith {false};

// Written the way the config names it, so comparing and pictures work whatever case it came in.
private _config = _class call CBA_fnc_getItemConfig;
private _cased = [_class, configName _config] select (isClass _config);

{
    if (_x == _cased) then {
        GVAR(slots) set [_forEachIndex, ""];
    };
} forEach GVAR(slots);

GVAR(slots) set [_index, _cased];

call FUNC(saveSlots);

GVAR(nextCount) = 0;
call FUNC(hudPing);

// The window shows it at once, and says so with its sound.
if (_window) then {
    ["", objNull] call EFUNC(gui,afterAction);
};

true
