#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The tile of a weapon lying in a container that the attachments view shows (#56, Attachments in the tile's menu): found again
 * in the window's grids by its container and its cell, as it is now - its parts change its key, never its cell (op "fit" puts it
 * back onto it, fnc_doFit).
 *
 * Arguments:
 * 0: The weapon - "container" and "cell" [col, row, compartment] <HASHMAP>
 *
 * Return Value:
 * The tile, an empty HashMap when it is gone <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["container", backpackContainer player], ["cell", [0, 2, 0]]]] call aio_gui_fnc_weaponTile;
 *
 * Public: No
 */

params [["_target", createHashMap, [createHashMap]]];

private _container = _target getOrDefault ["container", objNull];

(_target getOrDefault ["cell", []]) params [["_col", -1], ["_row", -1], ["_block", 0]];

if (isNull _container || {_col < 0}) exitWith {createHashMap};

private _found = createHashMap;

{
    if ((_x getOrDefault ["container", objNull]) isNotEqualTo _container || {(_x getOrDefault ["kit", ""]) isNotEqualTo ""}) then {continue};

    private _index = (_x getOrDefault ["tiles", []]) findIf {
        (_x getOrDefault ["col", -1]) == _col && {(_x getOrDefault ["row", -1]) == _row} && {(_x getOrDefault ["block", 0]) == _block}
        && {(_x getOrDefault ["attachments", []]) isNotEqualTo []}
    };

    if (_index >= 0) exitWith {
        _found = (_x get "tiles") select _index;
    };
} forEach (uiNamespace getVariable [QGVAR(grids), []]);

_found
