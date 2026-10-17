#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes an action out of the hands' queue (fnc_queueMoves): a click on its tile or slot, or "Cancel" in the
 * menu. Nothing had been sent or changed - the move only waited - so there is nothing to undo: the tile
 * is free again and the others are numbered again (their circles stay, only the numbers are written anew,
 * once in the next frame however many were taken out - fnc_animateQueue). If it was the one the hands were
 * busy with, the next one starts from nothing.
 *
 * Arguments:
 * 0: The queue entry's id, 0 for every entry <NUMBER> (default: 0)
 *
 * Return Value:
 * How many were taken out <NUMBER>
 *
 * Example:
 * [3] call einv_gui_fnc_cancelQueued;
 *
 * Public: No
 */

disableSerialization;

params [["_id", 0, [0]]];

private _gone = GVAR(handQueue) select {_id == 0 || {(_x get "id") == _id}};

if (_gone isEqualTo []) exitWith {0};

private _headId = (GVAR(handQueue) select 0) get "id";

if (_gone findIf {(_x get "id") == _headId} >= 0) then {
    GVAR(handStarted) = -1;
};

GVAR(handQueue) = GVAR(handQueue) select {_id != 0 && {(_x get "id") != _id}};

{
    {ctrlDelete _x} forEach (_x getOrDefault ["fx", []]);

    // The tiles fnc_drawQueue marked for it (found anew only when it has not been drawn yet).
    private _tiles = _x getOrDefault ["tiles", []];

    if (_tiles isEqualTo []) then {
        _tiles = [_x] call FUNC(queueTiles);
    };

    {
        _x params ["", "_tile"];

        _tile set ["pending", false];
        _tile deleteAt "queued";

        {
            _x ctrlSetFade 0;
            _x ctrlCommit 0;
        } forEach (_tile getOrDefault ["controls", []]);
    } forEach _tiles;
} forEach _gone;

// The others are numbered again, in the next frame.
GVAR(queueDirty) = true;

count _gone
