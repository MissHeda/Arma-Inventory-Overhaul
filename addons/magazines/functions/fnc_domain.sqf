#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whose gear a grid's magazines are, for deciding whether two of them can be repacked together: the root
 * of the grid's container (einv_storage_fnc_rootOf) - the player for the player's own uniform, vest and
 * backpack and what lies in them, else the crate, vehicle, pile or body that holds them. Two magazines
 * are repacked together only under the same root: one transaction changes one root, at its authority.
 *
 * A living person's gear (not the player's own) changes on their machine, and a grid with no container
 * (a kit's) is no business of this addon: no root.
 *
 * Arguments:
 * 0: Grid, see einv_gui_fnc_createGrid <HASHMAP>
 *
 * Return Value:
 * The root, objNull for gear that never takes part <OBJECT>
 *
 * Example:
 * [_grid] call einv_magazines_fnc_domain;
 *
 * Public: No
 */

params [["_grid", createHashMap, [createHashMap]]];

private _container = _grid getOrDefault ["container", objNull];

if (isNull _container) exitWith {objNull};

private _root = _grid getOrDefault ["root", objNull];

if (isNull _root) then {
    _root = [_container] call EFUNC(storage,rootOf);
};

if (isNull _root) exitWith {objNull};

// Alive and somebody else: their gear is theirs (the person search). A body is a crate.
if (_root isKindOf "CAManBase" && {alive _root} && {_root isNotEqualTo EGVAR(gui,unit)}) exitWith {objNull};

_root
