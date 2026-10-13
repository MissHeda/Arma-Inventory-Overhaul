#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A key pressed on ACE Arsenal's display, beside ACE's own handler, which runs as always: Escape closes,
 * the arrows add and take out, typing goes into ACE's search fields. The engine gets only two keys: R
 * while it drags something (a quarter turn), and Delete while the mouse is over the panel (the tile there
 * is taken out - the engine's Delete ends in the "ground" hook, fnc_remove). Nothing while a field of
 * ACE's has the cursor.
 *
 * Whether Ctrl is held is noted with every key, pressed or let go (also by the display's KeyUp handler,
 * fnc_onOpened), and with every mouse button (fnc_onMouse): the wheel's event does not say it, and Ctrl
 * with the wheel over a tile adds or takes out one (fnc_onWheel), by the latest note. A Ctrl let go while
 * the display had no focus is so corrected by the next key or click.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Key (DIK code) <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 * 5: Pressed (true) or let go (false) <BOOL> (default: true)
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [_display, 211, false, false, false] call einv_arsenal_fnc_onKey;
 *
 * Public: No
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]], ["_key", 0, [0]], ["_shift", false, [false]], ["_ctrl", false, [false]],
    ["_alt", false, [false]], ["_down", true, [true]]
];

private _isCtrl = _key in [DIK_LCONTROL, DIK_RCONTROL];

GVAR(ctrlHeld) = [_ctrl && {!_isCtrl}, _ctrl || {_isCtrl}] select _down;

if (!_down) exitWith {false};

if (!GVAR(attached) || {(uiNamespace getVariable [QEGVAR(gui,display), displayNull]) isNotEqualTo _display}) exitWith {false};

private _focused = focusedCtrl _display;

if (!isNull _focused && {ctrlType _focused == 2}) exitWith {false};

private _dragging = EGVAR(gui,dragging);

if (
    (_key == DIK_R && {_dragging})
    || {_key == DIK_DELETE && {!_dragging} && {[getMousePosition] call FUNC(isOver)}}
) exitWith {
    _this call EFUNC(gui,onKeyDown)
};

false
