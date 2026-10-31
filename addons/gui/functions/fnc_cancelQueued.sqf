#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes an action out of the hands' queue (fnc_queueMoves): a click on its tile or slot, "Cancel" in the
 * menu, or the stop button in the caption line of its box (which cancels all of the box's). Nothing had been sent
 * or changed - the move only waited - so there is nothing to undo: the tile is free again and its colour is back. If it
 * was the one the hands were busy with, the next one starts from nothing. The box's count (fnc_boxStep) goes down by
 * as many as left.
 *
 * Arguments:
 * 0: The queue entry's id, 0 for every entry <NUMBER> (default: 0)
 * 1: Only the entries of this box - with the id 0 - objNull for every box <OBJECT> (default: objNull)
 *
 * Return Value:
 * How many were taken out <NUMBER>
 *
 * Example:
 * [3] call aio_gui_fnc_cancelQueued;
 * [0, _crate] call aio_gui_fnc_cancelQueued;
 *
 * Public: No
 */

disableSerialization;

params [["_id", 0, [0]], ["_box", objNull, [objNull]]];

private _all = _id == 0 && {isNull _box};

private _gone = GVAR(handQueue) select {
    if (_id != 0) then {(_x get "id") == _id} else {isNull _box || {(_x getOrDefault ["box", objNull]) isEqualTo _box}}
};

if (_gone isEqualTo []) exitWith {0};

private _headId = (GVAR(handQueue) select 0) get "id";

if (_gone findIf {(_x get "id") == _headId} >= 0) then {
    GVAR(handStarted) = -1;
};

private _goneIds = _gone apply {_x get "id"};

GVAR(handQueue) = GVAR(handQueue) select {!((_x get "id") in _goneIds)};

if (_all) then {
    GVAR(handWaiting) = createHashMap;
    GVAR(handBoxes) = [];
} else {
    [_gone, false] call FUNC(queueIndex);

    {
        [_x, false] call FUNC(boxStep);
    } forEach _gone;
};

// What the cancelled moves had room reserved for is free again (fnc_roomFor).
GVAR(roomCache) = [];

{
    {ctrlDelete _x} forEach (_x getOrDefault ["fx", []]);

    // The tiles fnc_drawQueue marked for it (found anew only when it has not been drawn yet).
    private _tiles = _x getOrDefault ["tiles", []];

    if (_tiles isEqualTo []) then {
        _tiles = [_x] call FUNC(queueTiles);
    };

    {
        _x params ["", "_tile"];

        [_tile] call FUNC(unmarkQueued);
    } forEach _tiles;
} forEach _gone;

// The others are marked again where they need it, in the next frame.
GVAR(queueFrom) = 0;
GVAR(queueDirty) = true;

count _gone
