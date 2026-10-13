#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A tile of the panel let go (the "drop" hook). Within the panel the engine moves it as in the inventory -
 * to a free spot, turned or not, onto another of its kind - a move of place within the container, or a
 * move between the container and the staging space (fnc_staging), both the storage's own. For the latter
 * the count of that class in the container is noted, and the frame hook tells ACE once the move landed
 * (fnc_onFrame): the soldier gained or lost it. Let go outside the panel, where fnc_dragCheck pointed it at
 * ACE's list, it is taken out of the container or the staging space: as much of the stack as was dragged
 * (fnc_remove).
 *
 * An item dragged out of ACE's list (fnc_listDrag) is always this hook's to end: on a grid of the panel it
 * is put in, on the cell it was let go on and turned as it was, as many as the wheel left (fnc_addTo);
 * anywhere else it was nothing.
 *
 * Arguments:
 * 0: Kind of target <STRING>
 * 1: Index of the grid it comes from <NUMBER>
 * 2: Index of its tile <NUMBER>
 * 3: The slot it comes from, [] for a tile <ARRAY>
 * 4: What is dragged <HASHMAP>
 * 5: How many of a stack, -1 for all <NUMBER>
 * 6: Index of the target - a grid's, a zone's <NUMBER>
 * 7: Column of the cell <NUMBER>
 * 8: Row of the cell <NUMBER>
 * 9: Width it lies in there <NUMBER>
 * 10: Height it lies in there <NUMBER>
 *
 * Return Value:
 * Handled - the engine does nothing more <BOOL>
 *
 * Example:
 * ["zone", 0, 3, [], _entry, -1] call einv_arsenal_fnc_onDrop;
 *
 * Public: No
 */

params [
    ["_kind", "", [""]], ["_sourceIndex", -1, [0]], ["_tileIndex", -1, [0]], ["_slotSource", [], [[]]],
    ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]], ["_targetIndex", -1, [0]], ["_col", 0, [0]],
    ["_row", 0, [0]], ["_w", 1, [0]], ["_h", 1, [0]], "", "", ["_rot", 0, [0]]
];

GVAR(dragZone) = "";

private _grids = uiNamespace getVariable [QEGVAR(gui,grids), []];
private _from = if (_slotSource isEqualTo []) then {_grids param [_sourceIndex, createHashMap]} else {createHashMap};

// Out of ACE's list: into the grid it was let go on.
if ((_from getOrDefault ["source", ""]) isEqualTo "aceList") exitWith {
    if (_kind isEqualTo "grid") then {
        private _target = _grids param [_targetIndex, createHashMap];
        private _amount = [_count, _entry getOrDefault ["count", 1]] select (_count < 1);

        [
            _target getOrDefault ["container", objNull], _entry getOrDefault ["class", ""], _amount,
            [_col, _row, _target getOrDefault ["block", 0], _w, _h, _rot]
        ] call FUNC(addTo);
    };

    true
};

// Between the soldier's container and the staging space: ACE is told once it landed.
if (_kind isEqualTo "grid" && {!isNull GVAR(staging)}) exitWith {
    private _to = (_grids param [_targetIndex, createHashMap]) getOrDefault ["container", objNull];
    private _source = _from getOrDefault ["container", objNull];

    (call FUNC(selected)) params ["", "_open"];

    if (_source isNotEqualTo _to && {GVAR(staging) in [_source, _to]} && {_open in [_source, _to]}) then {
        private _class = _entry getOrDefault ["class", ""];

        GVAR(watch) = [_open, _class, [_open, _class] call EFUNC(storage,countClass), diag_tickTime + WATCH_TIME];
    };

    false
};

if !(_kind in ["zone", "ground"]) exitWith {false};

// Only the panel's own tiles are dragged here; a slot has nothing to take out.
if (_slotSource isEqualTo []) then {
    [[_sourceIndex, _tileIndex], _count] call FUNC(remove);
};

true
