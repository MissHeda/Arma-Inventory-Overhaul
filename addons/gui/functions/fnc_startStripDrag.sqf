#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lifts the binding of a hotbar slot (einv_hotbar): a press on a filled slot of the strip that moved
 * (fnc_onFrame, fnc_onMouseButton - the slot's number is the tenth element of GVAR(press)). Not an item and
 * nothing moves in the gear: the item's picture follows the mouse as a ghost the size of the slot, and
 * what the drop does is told in the hint (fnc_updateStripDrag). Let go on another slot of the strip it moves
 * there (the two swap, einv_hotbar_fnc_moveSlot); let go anywhere outside the strip it is removed
 * (einv_hotbar_fnc_unbind); let go on the strip between its slots it stays (fnc_endStripDrag).
 *
 * The press stays in GVAR(press) while the binding is held, so that nothing is built meanwhile
 * (fnc_onFrame). The name at the mouse is gone while it is held (fnc_updateHover).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_startStripDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

private _index = GVAR(press) param [9, -1];
private _slots = uiNamespace getVariable [QGVAR(slots), []];
private _at = _slots findIf {(_x param [7, -1]) == _index};

if (_index < 0 || {_at < 0} || {((_slots select _at) param [1, ""]) isEqualTo ""}) exitWith {
    GVAR(press) = [];
};

private _record = _slots select _at;
private _class = _record select 1;

// The strip's box: what its slots cover together, with a little margin - letting go between two slots
// leaves the binding where it is.
private _box = [];

{
    if ((_x param [7, -1]) >= 0) then {
        private _rect = [_x] call FUNC(slotRect);

        if (_rect isNotEqualTo []) then {
            _rect params ["_left", "_top", "_width", "_height"];

            if (_box isEqualTo []) then {
                _box = [_left, _top, _left + _width, _top + _height];
            } else {
                _box = [
                    (_box select 0) min _left, (_box select 1) min _top,
                    (_box select 2) max (_left + _width), (_box select 3) max (_top + _height)
                ];
            };
        };
    };
} forEach _slots;

private _margin = UNIT * 0.3;

if (_box isNotEqualTo []) then {
    _box = [(_box select 0) - _margin, (_box select 1) - _margin, (_box select 2) + _margin, (_box select 3) + _margin];
};

// The name at the mouse goes while the binding is held.
(uiNamespace getVariable [QGVAR(tooltip), controlNull]) ctrlShow false;

ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
uiNamespace setVariable [QGVAR(compare), controlNull];
uiNamespace setVariable [QGVAR(tipShown), controlNull];

private _size = ((_record select 0) select [2, 2]) apply {_x max (UNIT * 1.5)};
private _info = [_class] call EFUNC(items,getInfo);
private _rect = [0, 0, _size select 0, _size select 1];

private _ghost = [
    _display, controlNull, _rect, _info getOrDefault ["picture", ""], _info getOrDefault ["icon", ICON_PLAIN], [1, 1, 1, 0.85], _rect
] call FUNC(uiItemPicture);

(ctrlPosition _ghost) params ["_ghostX", "_ghostY"];

GVAR(stripDrag) = [_index, _ghost, _box, [_ghostX, _ghostY], _size];
GVAR(dragHintShown) = [];

[_display, getMousePosition] call FUNC(updateStripDrag);
