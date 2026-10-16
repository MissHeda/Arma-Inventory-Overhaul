#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mouse wheel while a stack is dragged, as in Enhanced First Aid Kits: up one more, down one less
 * of the stack goes - at least one, at most all of it. The middle button takes all of it again
 * (fnc_updateDrag). The columns do not scroll meanwhile (fnc_updateDrag holds them); a single item
 * leaves the wheel to them. A window that attached (fnc_attach) is offered the wheel first when nothing is
 * dragged (the "wheel" hook). A new count moves the weight card's preview (fnc_previewWeight).
 *
 * Reported by the display and by every scrolling column, both for the same turn of the wheel: one
 * per frame counts. A picture's clip group over a tile reports it too, and passes it on to the column
 * (fnc_passWheel).
 *
 * Arguments:
 * 0: The event's own arguments [control or display, scroll] <ARRAY>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [_this] call einv_gui_fnc_onMouseZ;
 *
 * Public: No
 */

params ["_args"];
_args params [["_source", displayNull], ["_scroll", 0]];

// A picture's clip group (fnc_uiItemPicture) lies over its tile and keeps the wheel from the column the tile
// is in: it hands the turn on - unless the wheel is counting a stack just now.
if (_source isEqualType controlNull && {_scroll != 0} && {_source getVariable [QGVAR(clip), false]}) then {
    private _entry = uiNamespace getVariable [QGVAR(dragEntry), createHashMap];
    private _counting = GVAR(dragging) && {GVAR(dragGroup) isEqualTo []} && {(_entry getOrDefault ["count", 1]) > 1};

    if (!_counting) then {
        [_source, _scroll] call FUNC(passWheel);
    };
};

// Not dragging: a window that attached may use the wheel itself (the Arsenal panel adds or takes out one with
// Ctrl over a tile) - once per turn, though the display and the column both report it. The hook
// is told the turn and where the mouse is; a hook that scrolls a column itself sets its value every
// frame, as fnc_updateDrag holds the columns: answering true does not stop the column's own step.
if (!GVAR(dragging) && {_scroll != 0} && {"wheel" in GVAR(hooks)}) exitWith {
    if (GVAR(lastWheel) isEqualTo diag_frameNo) exitWith {false};

    GVAR(lastWheel) = diag_frameNo;

    (["wheel", [_scroll, getMousePosition], false] call FUNC(hook)) isEqualTo true
};

// Several tiles dragged together go whole: the wheel keeps scrolling the column under them.
if (!GVAR(dragging) || {_scroll == 0} || {GVAR(dragGroup) isNotEqualTo []}) exitWith {false};

private _stack = (uiNamespace getVariable [QGVAR(dragEntry), createHashMap]) getOrDefault ["count", 1];

if (_stack <= 1) exitWith {false};

if (GVAR(lastWheel) isEqualTo diag_frameNo) exitWith {true};

GVAR(lastWheel) = diag_frameNo;
GVAR(dragCount) = ((GVAR(dragCount) + ([-1, 1] select (_scroll > 0))) max 1) min _stack;

// The weight card's preview follows the count (fnc_previewWeight): only moved - what lift made is all there is.
[uiNamespace getVariable [QGVAR(display), displayNull], uiNamespace getVariable [QGVAR(dragEntry), createHashMap], GVAR(dragCount), false] call FUNC(previewWeight);

true
