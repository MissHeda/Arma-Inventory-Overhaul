#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Tells the player once when a unit's uniform, vest or backpack holds more than its grid has room for
 * (fnc_checkOverflow): in the arsenal's own message line while it is open, as ACE's text on the screen
 * once it is closed. Nothing is taken out - a whole loadout is the player's to sort.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Arsenal display, displayNull once it is closed <DISPLAY> (default: displayNull)
 *
 * Return Value:
 * Something did not fit <BOOL>
 *
 * Example:
 * [player, findDisplay 1127001] call einv_arsenal_fnc_reportOverflow;
 *
 * Public: No
 */

disableSerialization;

params [["_unit", objNull, [objNull]], ["_display", displayNull, [displayNull]]];

// In the editor the arsenal dresses a stand-in of the unit: left alone.
if (isNull _unit || {is3DEN}) exitWith {false};

private _names = [_unit] call FUNC(checkOverflow);

if (_names isEqualTo []) exitWith {false};

private _text = format [LLSTRING(Overflow), _names joinString ", "];

if (!isNull _display && {!isNil QACEFUNC(arsenal,message)}) exitWith {
    [_display, _text] call ACEFUNC(arsenal,message);
    true
};

if (isNil QACEFUNC(common,displayText)) then {
    hint _text;
} else {
    [_text, false, 5, 1] call ACEFUNC(common,displayText);
};

true
