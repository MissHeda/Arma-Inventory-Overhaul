#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A mouse button pressed or let go anywhere on ACE Arsenal's display (the "mouseDown" and "mouseUp" hooks).
 * Outside the panel it is ACE's alone: the engine is told it is taken, and does nothing with it - no menu,
 * no press. Over the panel it is the engine's: ACE's note of the press, which would pan or turn its camera
 * as the mouse moves on over the middle, is emptied now and once more a frame later, whichever of the
 * two handlers ran first.
 *
 * Let go, a drag or press that began on the panel is the engine's to end wherever the mouse is - outside
 * the panel that takes the item out (fnc_dragCheck, fnc_onDrop).
 *
 * A press on ACE's list is noted by the list's own handler (fnc_onListPress); let go anywhere, the note
 * goes.
 *
 * Whether Ctrl is held is noted with every button, pressed or let go, as with every key (fnc_onKey): a
 * Ctrl let go while the display had no key focus is then corrected by the next click.
 *
 * Arguments:
 * 0: Pressed (true) or let go (false) <BOOL>
 * 1: Button, 0 left, 1 right <NUMBER>
 * 2: Mouse [x, y] <ARRAY>
 * 3: Shift (not used) <BOOL>
 * 4: Ctrl <BOOL> (default: as last noted)
 *
 * Return Value:
 * Taken - the engine leaves it alone <BOOL>
 *
 * Example:
 * [true, 0, getMousePosition] call aio_arsenal_fnc_onMouse;
 *
 * Public: No
 */

params [
    ["_down", true, [true]], ["_button", 0, [0]], ["_mouse", getMousePosition, [[]]], "", ["_ctrl", GVAR(ctrlHeld), [true]]
];

GVAR(ctrlHeld) = _ctrl;

private _over = [_mouse] call FUNC(isOver);

if (!_down) exitWith {
    GVAR(listPress) = [];

    if (EGVAR(gui,dragging) || {EGVAR(gui,press) isNotEqualTo []}) exitWith {false};

    !_over
};

if (!_over) exitWith {true};

if (!isNil QACEGVAR(arsenal,mouseButtonState)) then {
    ACEGVAR(arsenal,mouseButtonState) = [[], []];

    [{
        if (!isNil QACEGVAR(arsenal,mouseButtonState)) then {
            ACEGVAR(arsenal,mouseButtonState) = [[], []];
        };
    }] call EFUNC(gui,later);
};

false
