#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes the mark of the hands' queue off a tile (fnc_drawQueue put it on): it is free to be lifted again, no longer faded,
 * and its surface has its own colour back. For a move that was cancelled or refused; one that is sent keeps its fade as
 * any move on its way does (fnc_runQueue calls it with "keepFade").
 *
 * Arguments:
 * 0: The tile <HASHMAP>
 * 1: Keep the tile pending and faded - it is on its way now <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_tile] call einv_gui_fnc_unmarkQueued;
 *
 * Public: No
 */

params [["_tile", createHashMap, [createHashMap]], ["_keepFade", false, [false]]];

_tile deleteAt "queued";

private _color = _tile getOrDefault ["color", []];

if (_color isNotEqualTo []) then {
    [_tile getOrDefault ["backgrounds", []], _color] call FUNC(paintSurface);
};

if (_keepFade) exitWith {};

_tile set ["pending", false];

{
    _x ctrlSetFade 0;
    _x ctrlCommit 0;
} forEach (_tile getOrDefault ["controls", []]);
