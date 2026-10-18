#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the draft makes of a container class, for the Containers step: its info and the compartments it
 * gets, as the inventory lays them out (einv_storage_fnc_blocksFor) - a grid by load or by a pattern
 * (pockets, rig) becomes the compartments it gives this class, so the editor can show and change those
 * cells. The cell editor draws them; "Same as another class" copies them from the class picked.
 * Compartments without a row take no place in the inventory and are left out.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * [info, compartments] - info as einv_items_fnc_getInfo gives it, compartments [[cols, rows, holes, pos],
 * ...] each a copy of its own, pos [] where it flows <ARRAY>
 *
 * Example:
 * ([_class] call einv_setup_fnc_classBlocks) params ["_info", "_blocks"];
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _info = [_class, GVAR(draftRules), GVAR(draftCache)] call EFUNC(items,getInfo);
private _kind = _info getOrDefault ["kind", ""];
private _blocks = [];

if (!isNil QEFUNC(storage,blocksFor)) then {
    _blocks = [
        _info getOrDefault ["class", _class], [_kind, "crate"] select (_kind in ["crate", "vehicle"]), _info getOrDefault ["maxLoad", 0],
        _info getOrDefault ["grid", ["auto"]], (GVAR(draftRules) getOrDefault ["cell", 5]) max 1
    ] call EFUNC(storage,blocksFor);
};

_blocks = (_blocks select {(_x select 1) > 0}) apply {[_x select 0, _x select 1, +(_x param [2, []]), +(_x param [3, []]), +(_x param [4, []]), _x param [5, false]]};

[_info, _blocks]
