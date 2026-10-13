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
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Key (DIK code) <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
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

params [["_display", displayNull, [displayNull]], ["_key", 0, [0]], ["_shift", false, [false]], ["_ctrl", false, [false]], ["_alt", false, [false]]];

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
