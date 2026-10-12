#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The button came up after a frame was dragged out from an empty cell: the tiles it touched are the
 * selection (added to the one there was when Ctrl was held at the press - on the same side), on the side
 * of the column it was dragged in, and the first of them in reading order is the anchor for Shift+click.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_endBand;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

{ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(bandFrame), []]);
uiNamespace setVariable [QGVAR(bandFrame), []];

private _tiles = GVAR(bandTiles);
private _side = [GVAR(bandPress) param [4, ""], ""] select (GVAR(bandPress) isEqualTo []);
private _ctrl = GVAR(bandPress) param [3, false];

GVAR(band) = false;
GVAR(bandPress) = [];
GVAR(bandTiles) = [];

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _refs = [];
private _order = [];

{
    _x params ["_gridIndex", "_tileIndex"];

    private _grid = _grids param [_gridIndex, createHashMap];
    private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];

    if (count _tile == 0) then {continue};

    private _key = _tile getOrDefault ["key", ""];

    if (_key isEqualTo "") then {
        _key = [_tile] call EFUNC(storage,entryKey);
    };

    private _block = _grid getOrDefault ["block", 0];
    private _holder = _grid getOrDefault ["holder", objNull];
    private _ref = [_holder, _key, _block, _tile getOrDefault ["col", 0], _tile getOrDefault ["row", 0]];

    if (_refs findIf {_x isEqualTo _ref} >= 0) then {continue};

    _order pushBack [_block, _tile getOrDefault ["row", 0], _tile getOrDefault ["col", 0], _refs pushBack _ref];
} forEach _tiles;

// Added to what was selected, on the same side only.
private _selection = [[], GVAR(selection)] select (_ctrl && {GVAR(selectionSide) isEqualTo _side});

_order sort true;

{
    private _ref = _refs select (_x select 3);

    if (_selection findIf {_x isEqualTo _ref} < 0) then {
        _selection pushBack _ref;
    };
} forEach _order;

GVAR(selection) = _selection;
GVAR(selectionSide) = [_side, ""] select (_selection isEqualTo []);
GVAR(selectionAnchor) = [_selection param [0, []], []] select (_selection isEqualTo []);

[] call FUNC(drawSelection);
