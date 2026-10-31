#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shift+click on a stack: half of it (rounded down, at least one) is split off onto the nearest free
 * cell of the container it lies in, where it stays as a stack of its own - it joins no other stack of its
 * class. Shift+drag lifts half of a stack as ever (fnc_startDrag) and the wheel changes how many, so a
 * chosen count can be put down anywhere.
 *
 * Only where the storage keeps separate stacks (einv_storage_stackSplits, op "split"), and only
 * for a stack of two or more on a grid of a container, searched and not on its way, in the inventory.
 * The cell is left to the storage (op "split" with no cell: the nearest free one), which says "NoRoom"
 * when the container has none. Checked first as any move is (fnc_applyMove, fnc_checkTouch).
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [0, 3] call einv_gui_fnc_splitStack;
 *
 * Public: No
 */

params ["_gridIndex", "_tileIndex"];

if !(missionNamespace getVariable [QEGVAR(storage,stackSplits), false]) exitWith {false};

private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _container = _grid getOrDefault ["container", objNull];

if (
    count _tile == 0 || {isNull _container} || {_grid getOrDefault ["virtual", true]} || {(_grid getOrDefault ["source", ""]) isNotEqualTo ""}
    || {(_grid getOrDefault ["kit", ""]) isNotEqualTo ""} || {_tile getOrDefault ["hidden", false]} || {_tile getOrDefault ["pending", false]}
    || {!(call FUNC(isInventoryMode))}
) exitWith {false};

private _count = _tile getOrDefault ["count", 1];

if (_count < 2) exitWith {false};

private _split = [_container, _container, _tile, (floor (_count / 2)) max 1, [], createHashMapFromArray [["separate", true]]] call FUNC(applyMove);

if (_split isEqualTo true) then {
    [] call FUNC(drawPending);
};

_split isEqualTo true
