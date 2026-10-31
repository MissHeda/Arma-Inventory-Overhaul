#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts a picture's clip group back to the top after the wheel turned over it (fnc_uiItemPicture). The group
 * holds a picture larger than itself, so the engine scrolls it by the wheel - and does so after the handler
 * of the event has run, so a reset in the handler alone leaves it scrolled by one step each turn. The group
 * is put back at once and noted: fnc_onFrame puts it back again for the next few frames (the same frame's
 * draw, before the display is drawn, and any smooth scrolling), and once more a frame later where no window
 * runs a frame (the setup wizard's preview).
 *
 * Arguments:
 * 0: The clip group <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_group] call aio_gui_fnc_unscroll;
 *
 * Public: No
 */

disableSerialization;

params [["_group", controlNull, [controlNull]]];

if (isNull _group) exitWith {};

_group ctrlSetScrollValues [0, 0];

// Where no window runs a frame, what is noted is only cleared away here.
private _noted = (uiNamespace getVariable [QGVAR(unscroll), []]) select {!isNull (_x select 0) && {diag_frameNo <= (_x select 1)}};

_noted pushBack [_group, diag_frameNo + UNSCROLL_FRAMES];
uiNamespace setVariable [QGVAR(unscroll), _noted];

[{
    params ["_group"];

    if (!isNull _group) then {
        _group ctrlSetScrollValues [0, 0];
    };
}, [_group]] call FUNC(later);
