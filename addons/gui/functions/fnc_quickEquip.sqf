#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Alt+click on a tile: puts the item on the player - into the slot it belongs to, an attachment or
 * magazine onto the first weapon that takes it (aio_storage_fnc_slotFor). What was in the slot goes
 * where the new item came from - out of an open kit, into the kit where it may go (fnc_doEquip). A tile
 * not searched yet, or one a move is under way for, stays.
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [0, 3] call aio_gui_fnc_quickEquip;
 *
 * Public: No
 */

disableSerialization;

params ["_gridIndex", "_tileIndex"];

private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _from = _grid getOrDefault ["container", objNull];
private _kit = _grid getOrDefault ["kit", ""];

if (
    count _tile == 0 || {isNull _from && {_kit isEqualTo ""}} || {_grid getOrDefault ["virtual", true]}
    || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]}
) exitWith {false};

private _slot = [GVAR(unit), _tile get "class"] call EFUNC(storage,slotFor);

if (_slot isEqualTo "") exitWith {
    ["NoFit"] call FUNC(flashHint);
    false
};

[_slot, _from, _tile, _kit] call FUNC(doEquip)
