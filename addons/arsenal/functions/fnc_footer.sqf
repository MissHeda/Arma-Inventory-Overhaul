#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The panel's hint line (the "footer" hook), in place of the inventory's footer, which would lie over ACE's
 * menu bar: the panel's last band (fnc_layout), on the panel's own background like the rest of it, under a
 * line in the colour of ACE's frame, with the engine's hint in it in the size of ACE's message line - what
 * the mouse is on, what a drag would do, why something did not go (einv_gui_fnc_updateHover,
 * einv_gui_fnc_flashHint). With no panel drawn there is no hint either.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call einv_arsenal_fnc_footer;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_theme", createHashMap, [createHashMap]]];

uiNamespace setVariable [QEGVAR(gui,hint), controlNull];

if (GVAR(hintRect) isEqualTo []) exitWith {};

GVAR(hintRect) params ["_left", "_top", "_width", "_height"];

// Where the column ends: a line as thin and dark as the frame round the panel, so the hint line reads as
// part of the block rather than a bar of its own.
private _lineColor = _theme getOrDefault ["panelBorder", []];

if (_lineColor isNotEqualTo []) then {
    private _line = [_display, "EINV_PanelRect", controlNull, [_left, _top, _width, pixelH]] call EFUNC(gui,uiCreate);
    _line ctrlSetBackgroundColor _lineColor;
};

// The text, centred, its lines as high as ACE's sort bar (fnc_layout gives the band one or two of them).
private _padX = SQUARE(UNIT * 0.4);
private _padY = SNAP_H(HINT_PAD * ACE_GRID_H);

uiNamespace setVariable [QEGVAR(gui,hint), [
    _display, "EINV_ArsenalHint", controlNull,
    [_left + _padX, _top + _padY, _width - _padX * 2, _height - _padY * 2]
] call EFUNC(gui,uiCreate)];
