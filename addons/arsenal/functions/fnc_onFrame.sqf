#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Every frame of the panel (the "frame" hook), also while something is dragged. While the engine holds
 * something lifted in the panel, ACE's camera must not take the same mouse button for a pan or a turn
 * over the middle: ACE notes every press on its display, also those on the panel, and moves its camera
 * while the button is down. So its note is emptied every frame meanwhile.
 *
 * A button let go where no event of the display reached the engine (over one of ACE's own controls) ends
 * the drag where it stands all the same, and a press that never became a drag is forgotten - it would
 * otherwise start one later with the button up.
 *
 * A build ACE's events asked for while something was held (fnc_settle) comes once it is let go.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Mouse [x, y] <ARRAY>
 * 2: Now (diag_tickTime) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition, diag_tickTime] call einv_arsenal_fnc_onFrame;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

private _holding = EGVAR(gui,dragging) || {EGVAR(gui,press) isNotEqualTo []};

if (_holding) then {
    if (!isNil QACEGVAR(arsenal,mouseButtonState)) then {
        ACEGVAR(arsenal,mouseButtonState) = [[], []];
    };

    if (inputMouse 0 == 0) then {
        if (EGVAR(gui,dragging)) then {
            [_display] call EFUNC(gui,endDrag);
        } else {
            EGVAR(gui,press) = [];
        };
    };
};

if (_holding || {!GVAR(dirty)}) exitWith {};

GVAR(dirty) = false;

[_display] call EFUNC(gui,build);
