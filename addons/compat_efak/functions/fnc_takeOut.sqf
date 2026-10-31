#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ctrl+click or a double click on a tile of an open kit (aio_gui_fnc_quickMove): into the player's own
 * gear - the kit's "take into" choice first, then uniform, vest, backpack (fnc_ownTargets) - the first
 * with a free spot on its grid. The layout finds it a cell.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Tile <HASHMAP>
 *
 * Return Value:
 * Moved <BOOL>
 *
 * Example:
 * ["efak_IFAK_7", _tile] call aio_compat_efak_fnc_takeOut;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_tile", createHashMap, [createHashMap]]];

private _targets = [_kit] call FUNC(ownTargets);
private _index = _targets findIf {[_x, _tile] call EFUNC(storage,hasRoom)};

if (_index < 0) exitWith {
    ["NowhereToGo"] call EFUNC(gui,flashHint);
    false
};

[[objNull, _kit], [_targets select _index, ""], _tile, -1, [], []] call FUNC(drop)
