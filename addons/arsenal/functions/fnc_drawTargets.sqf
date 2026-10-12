#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws the ring round the slot the soldier clicked to browse for (the target of double clicks and Alt+click)
 * and round the caption of the container he clicked free cells of (the target of quick adds). Part of every
 * build, and drawn again when a click changes a target. The rings are kept in the column ("rings") so the
 * next draw can take them away; a rebuild takes them away as well.
 *
 * A target that is gone - a container swapped out, a slot that is not shown - is let go.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_drawTargets;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

{
    ctrlDelete _x;
} forEach (_column getOrDefault ["rings", []]);

_column set ["rings", []];

if (isNull _display) exitWith {};

private _theme = EGVAR(gui,theme);
private _accent = _theme getOrDefault ["accent", [0.961, 0.647, 0.141, 1]];
private _unit = GVAR(center);
private _rings = [];

// ----- The slot -----
private _slotId = GVAR(targetSlot);

if (_slotId isNotEqualTo "") then {
    private _slots = uiNamespace getVariable [QEGVAR(gui,slots), []];
    private _index = _slots findIf {(_x param [5, ""]) isEqualTo _slotId && {(_x param [6, objNull]) isEqualTo _unit}};

    if (_index < 0) then {
        GVAR(targetSlot) = "";
    } else {
        private _record = _slots select _index;
        private _rect = _record select 0;
        private _anchor = _record param [3, createHashMap];
        private _parent = controlNull;
        private _inside = +_rect;

        // A slot in a scrolling column is ringed in that column, so the ring scrolls with it.
        if (_anchor isEqualType createHashMap && {"rel" in _anchor} && {!isNull (_anchor getOrDefault ["parent", controlNull])}) then {
            _parent = _anchor get "parent";
            _inside = (_anchor get "rel") + [_rect select 2, _rect select 3];
        };

        private _radius = (_theme getOrDefault ["radius", 0]) min ((_inside select 3) / 4);

        _rings append ([_display, _parent, _inside, _accent, _radius] call EFUNC(gui,uiRing));
    };
};

// ----- The container: round its caption -----
private _container = GVAR(targetContainer);

if (!isNull _container) then {
    private _info = (uiNamespace getVariable [QEGVAR(gui,sectionInfo), []]) select {(_x getOrDefault ["holder", objNull]) isEqualTo _container};
    private _tab = (_info param [0, createHashMap]) getOrDefault ["tab", []];
    _tab = _tab select {!isNull _x};

    if (_tab isEqualTo []) then {
        GVAR(targetContainer) = objNull;
    } else {
        // The caption is several pieces; the ring goes round all of them.
        private _left = 1e9;
        private _top = 1e9;
        private _right = -1e9;
        private _bottom = -1e9;

        {
            (ctrlPosition _x) params ["_x0", "_y0", "_w0", "_h0"];

            _left = _left min _x0;
            _top = _top min _y0;
            _right = _right max (_x0 + _w0);
            _bottom = _bottom max (_y0 + _h0);
        } forEach _tab;

        private _radius = (_theme getOrDefault ["radius", 0]) min ((_bottom - _top) / 4);

        _rings append ([_display, ctrlParentControlsGroup (_tab select 0), [_left, _top, _right - _left, _bottom - _top], _accent, _radius] call EFUNC(gui,uiRing));
    };
};

_column set ["rings", _rings];
