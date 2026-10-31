#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * An item dragged out of ACE's list - or the list of Enhanced First Aid Kits' kits tab - over a kit's tile in the
 * panel (the "dragCheck" hook, fnc_dragCheck): it goes into that kit, wherever the kit lies - a container or the
 * staging space. The cell under
 * the mouse decides, as in the inventory: the footprint's corner plus where the item was taken by
 * (aio_gui_press), or the cell the engine names. The kit answers (aio_compat_efak_fnc_canPackNew): whether it may be
 * filled in the arsenal (the kit type's Arsenal setting, a kit that follows the default contents), that mod's rules
 * for it, and its room in the measure it is counted in
 * (aio_compat_efak_fnc_roomMode) - that mod's capacity, or the free cells of a grid a rule or its config
 * gives the kit, never the capacity then. Green when some of them fit - the hint says how many -, red
 * with the reason when none does. The same over a cell of the kit's grid in the kits tab (fnc_layout): the
 * engine's grid target stands, with the kit's verdict.
 *
 * Arguments:
 * 0: The engine's target, a grid's ["grid", index, col, row, ...] <ARRAY>
 * 1: What is dragged <HASHMAP>
 *
 * Return Value:
 * ["kitTile", grid index, tile index, 0, fits, why] - [] when it is over no kit's tile <ARRAY>
 *
 * Example:
 * [_target, _entry] call aio_arsenal_fnc_listToKit;
 *
 * Public: No
 */

params [["_target", [], [[]]], ["_entry", createHashMap, [createHashMap]]];

if (isNil QEFUNC(compat_efak,canPackNew) || {(_target param [0, ""]) isNotEqualTo "grid"}) exitWith {[]};

private _targetIndex = _target param [1, -1];
private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_targetIndex, createHashMap];

if (count _grid == 0 || {(_grid getOrDefault ["source", ""]) isNotEqualTo ""}) exitWith {[]};

// The kit's own grid in the kits tab (fnc_layout): the item is let go on a cell of it, the kit's first free
// spot taking it when that cell is not free.
private _gridKit = _grid getOrDefault ["kit", ""];
private _tileIndex = -1;
private _kit = _gridKit;

if (_gridKit isEqualTo "") then {
    // The cell under the mouse: the engine's target names it as its 11th element (the item is held by its middle and
    // the footprint's corner follows from that), else the footprint's corner and where in the item it is held.
    (EGVAR(gui,press) param [3, [0, 0]]) params [["_grabCol", 0, [0]], ["_grabRow", 0, [0]]];

    private _under = _target param [10, []];
    private _col = [(_target param [2, 0]) + _grabCol, _under param [0, 0]] select (_under isNotEqualTo []);
    private _row = [(_target param [3, 0]) + _grabRow, _under param [1, 0]] select (_under isNotEqualTo []);
    private _tiles = _grid getOrDefault ["tiles", []];

    _tileIndex = _tiles findIf {
        private _tileCol = _x getOrDefault ["col", -1];
        private _tileRow = _x getOrDefault ["row", -1];

        !(_x getOrDefault ["hidden", false])
        && {_col >= _tileCol} && {_col < _tileCol + (_x getOrDefault ["w", 1])}
        && {_row >= _tileRow} && {_row < _tileRow + (_x getOrDefault ["h", 1])}
    };

    _kit = ["", (_tiles param [_tileIndex, createHashMap]) getOrDefault ["class", ""]] select (_tileIndex >= 0);
};

if (_kit isEqualTo "" || {!([_kit] call EFUNC(compat_efak,isKit))}) exitWith {[]};

// As many as the wheel left, all of the stack when it left nothing.
private _stack = (_entry getOrDefault ["count", 1]) max 1;
private _amount = [_stack, EGVAR(gui,dragCount)] select (EGVAR(gui,dragCount) >= 1 && {EGVAR(gui,dragCount) < _stack});

([_kit, _entry getOrDefault ["class", ""], _amount] call EFUNC(compat_efak,canPackNew)) params ["_n", "_why"];

private _fits = _n > 0;

// Said once as the drag gets onto this kit, and again when the count changes.
private _zone = format ["kit|%1|%2|%3", _targetIndex, _tileIndex, _amount];

if (GVAR(dragZone) isNotEqualTo _zone) then {
    GVAR(dragZone) = _zone;

    if (_fits) then {
        [[
            format [LLSTRING(Hint_IntoKit), [_kit] call EFUNC(gui,itemName)],
            format [LELSTRING(compat_efak,SomeFit), _n, _amount]
        ] select (_n < _amount), ["text2", "accent"] select (_n < _amount)] call EFUNC(gui,showHint);
    } else {
        [[_why, "Failed"] select (_why isEqualTo "")] call EFUNC(gui,flashHint);
    };
};

private _reason = ["", [_why, "Failed"] select (_why isEqualTo "")] select !_fits;

// The engine's target stands for a grid, only its verdict is the kit's.
if (_gridKit isNotEqualTo "") exitWith {
    private _answer = +_target;

    _answer set [4, _fits];
    _answer set [5, _reason];
    _answer
};

["kitTile", _targetIndex, _tileIndex, 0, _fits, _reason]
