#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The box of the open window was taken out of ACE's arsenal system (ace_arsenal_boxRemoved): the window
 * closes, saying that the box is gone. A full arsenal ignores the box, and a vanilla box is none of ACE's
 * concern.
 *
 * Arguments:
 * 0: The box <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_box] call einv_arsenal_fnc_onBoxRemoved;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]]];

if (isNull _box || {_box isNotEqualTo GVAR(box)} || {GVAR(full)} || {GVAR(source) isNotEqualTo "ace"}) exitWith {};

[LLSTRING(Hint_BoxGone), false, 4, 2] call ACEFUNC(common,displayText);
[2] call FUNC(close);
