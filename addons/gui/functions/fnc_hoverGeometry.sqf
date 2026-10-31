#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where every grid, slot and info area of the window lies on the screen, for the hover to look through
 * (fnc_updateHover). Walking the groups a grid lies in costs a few commands per level for each grid and each
 * slot, and the hover asked it of all of them whenever the mouse moved - with a dozen grids and thirty slots
 * the most of what a hovering frame cost. The answer is kept in uiNamespace hoverGeom and handed out again
 * while nothing it depends on changed: the lists of grids, slots and info areas are the same ones with as
 * many entries, no window or the inspect card moved, none of the groups they lie in scrolled or changed its
 * height (a stamp of each group's scroll and content height, read per call), and no scroll is waiting to be
 * put back (fnc_onFrame). It is worked out again at the latest after CHECK_INTERVAL, whatever happened in
 * place meanwhile, and whenever asked to (the force flag).
 *
 * Each grid is [grid, window key, box its column shows or [], left, top of its cells, [left, top, right,
 * bottom] of the cells that show], each slot and each info area [left, top, right, bottom] where it shows
 * ([0, 0, 0, 0] for one scrolled out of sight).
 *
 * Arguments:
 * 0: Work it out again <BOOL> (default: false)
 *
 * Return Value:
 * [grids <ARRAY>, slots <ARRAY>, info areas <ARRAY>, counts <ARRAY>, valid until <NUMBER>, groups <ARRAY>, stamp <ARRAY>, grid boxes <ARRAY>, slot boxes <ARRAY>, info boxes <ARRAY>]
 * - the first three are the lists it was made for, the fourth their lengths, the sixth and seventh the groups
 * and what they read when it was made; the last three are what the hover wants
 *
 * Example:
 * (call einv_gui_fnc_hoverGeometry) select 8;
 *
 * Public: No
 */

disableSerialization;

params [["_force", false, [false]]];

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _slots = uiNamespace getVariable [QGVAR(slots), []];
private _areas = uiNamespace getVariable [QGVAR(infoAreas), []];
private _now = diag_tickTime;

// A scroll waiting to be put back (fnc_onFrame) moves every place: nothing is kept while it waits.
private _pending = (uiNamespace getVariable [QGVAR(scrollRestore), []]) isNotEqualTo [];
private _entry = uiNamespace getVariable [QGVAR(hoverGeom), []];

if (!_force && {!_pending} && {_entry isNotEqualTo []}) then {
    _entry params ["_gridsMade", "_slotsMade", "_areasMade", "_counts", "_until", "_groups", "_stamp"];

    if !(
        _now < _until && {_gridsMade isEqualRef _grids} && {_slotsMade isEqualRef _slots} && {_areasMade isEqualRef _areas}
        && {_counts isEqualTo [count _grids, count _slots, count _areas]} && {
            _stamp isEqualTo [
                (uiNamespace getVariable [QGVAR(windows), []]) apply {_x getOrDefault ["rect", []]},
                uiNamespace getVariable [QGVAR(inspectRect), []],
                _groups apply {[((ctrlScrollValues _x) select 0) max 0, _x getVariable [QGVAR(contentH), -1]]}
            ]
        }
    ) then {
        _entry = [];
    };
} else {
    _entry = [];
};

if (_entry isNotEqualTo []) exitWith {_entry};

// ----- Worked out anew -----
private _groups = [];

// Every group a place lies in, up to the display: what the stamp reads.
private _fnc_chain = {
    params ["_group"];

    while {!isNull _group} do {
        _groups pushBackUnique _group;
        _group = ctrlParentControlsGroup _group;
    };
};

// A slot's or an info area's box, where it shows (fnc_slotRect), as [left, top, right, bottom].
private _fnc_box = {
    params ["_place"];

    private _anchor = _place param [3, createHashMap];

    if (_anchor isEqualType createHashMap) then {
        private _parent = _anchor getOrDefault ["parent", controlNull];

        if (!isNull _parent) then {
            [_parent] call _fnc_chain;
        };
    };

    ([_place] call FUNC(slotRect)) params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];

    [_left, _top, _left + _width, _top + _height]
};

private _gridBoxes = _grids apply {
    private _parent = _x getOrDefault ["parent", controlNull];
    private _visible = [];

    if (!isNull _parent) then {
        [_parent] call _fnc_chain;

        (ctrlPosition _parent) params ["_groupX", "_groupY", "_groupW", "_groupH"];
        ([createHashMapFromArray [["rel", [_groupX, _groupY]], ["parent", ctrlParentControlsGroup _parent]]] call FUNC(gridOrigin)) params ["_groupLeft", "_groupTop"];

        _visible = [_groupLeft, _groupTop, _groupW, _groupH];
    };

    ([_x] call FUNC(gridOrigin)) params ["_originX", "_originY"];

    // Its cells reach to where its last column and row start and a pitch on (fnc_createGrid "colX", "rowY").
    private _colX = _x getOrDefault ["colX", []];
    private _rowY = _x getOrDefault ["rowY", []];
    private _lastX = if (_colX isEqualTo []) then {((_x get "cols") - 1) * (_x get "cellW")} else {_colX select (count _colX - 1)};
    private _lastRow = (_x getOrDefault ["rowTo", _x get "rows"]) - 1;
    private _lastY = if (_rowY isEqualTo []) then {_lastRow * (_x get "cellH")} else {_rowY select _lastRow};
    private _left = _originX;
    private _top = _originY;
    private _right = _originX + _lastX + (_x get "cellW");
    private _bottom = _originY + _lastY + (_x get "cellH");

    if (_visible isNotEqualTo []) then {
        _visible params ["_visibleX", "_visibleY", "_visibleW", "_visibleH"];

        _left = _left max _visibleX;
        _top = _top max _visibleY;
        _right = _right min (_visibleX + _visibleW);
        _bottom = _bottom min (_visibleY + _visibleH);
    };

    [_x, _x getOrDefault ["window", ""], _visible, _originX, _originY, [_left, _top, _right, _bottom]]
};

private _slotBoxes = _slots apply {[_x] call _fnc_box};
private _areaBoxes = _areas apply {[_x] call _fnc_box};

_entry = [
    _grids, _slots, _areas, [count _grids, count _slots, count _areas], _now + CHECK_INTERVAL, _groups,
    [
        (uiNamespace getVariable [QGVAR(windows), []]) apply {_x getOrDefault ["rect", []]},
        uiNamespace getVariable [QGVAR(inspectRect), []],
        _groups apply {[((ctrlScrollValues _x) select 0) max 0, _x getVariable [QGVAR(contentH), -1]]}
    ],
    _gridBoxes, _slotBoxes, _areaBoxes
];

uiNamespace setVariable [QGVAR(hoverGeom), [_entry, []] select _pending];

_entry
