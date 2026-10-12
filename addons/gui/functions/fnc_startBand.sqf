#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mouse moved past DRAG_THRESHOLD with the button held since a press on an empty cell
 * (GVAR(bandPress), fnc_onMouseButton): a frame is dragged out. Its fill and frame are made on the display
 * itself, last, so they lie over the columns without growing a column's scroll range; fnc_updateBand moves
 * them with the mouse.
 *
 * Without Ctrl held at the press the selection is cleared first - the frame starts a new one -, and so is
 * a selection on the other side than the column the press was in: one side at a time.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_startBand;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

if (GVAR(bandPress) isEqualTo []) exitWith {};

GVAR(bandPress) params ["", "", "", "_ctrl", "_side"];

if (!_ctrl || {GVAR(selectionSide) isNotEqualTo _side}) then {
    call FUNC(clearSelection);
};

private _accent = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _fill = +_accent;
_fill set [3, BAND_FILL_ALPHA];

private _filled = [_display, "EINV_PanelRect", controlNull, [0, 0, 0, 0]] call FUNC(uiCreate);
_filled ctrlSetBackgroundColor _fill;
_filled ctrlShow false;

private _frame = [_display, controlNull, [0, 0, 0, 0], _accent] call FUNC(uiFrame);
_frame ctrlShow false;

uiNamespace setVariable [QGVAR(bandFrame), [_filled, _frame]];

GVAR(band) = true;
GVAR(bandTiles) = [];
