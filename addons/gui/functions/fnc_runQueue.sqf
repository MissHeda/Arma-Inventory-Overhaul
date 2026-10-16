#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The first action of the hands' queue has run its time (fnc_animateQueue): it leaves the queue and is sent
 * as a move of the window always is (fnc_sendMoves, with the option "now" so it is not queued again) - the
 * transaction, the authority, the answer and its hint are exactly those of a move that was never queued. When
 * nothing is sent (the move is refused here: the item is gone, nowhere to put it, a lock set meanwhile, and the
 * hint says why) its tile is free again, and the next entry starts either way. The tiles and circles are drawn
 * anew (fnc_drawPending): the one that went is a move in flight now, the next one has the ring that fills.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * [_display] call einv_gui_fnc_runQueue;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

if (GVAR(handQueue) isEqualTo []) exitWith {false};

private _head = GVAR(handQueue) deleteAt 0;
private _tiles = [_head] call FUNC(queueTiles);

GVAR(handStarted) = -1;

{
    _x params ["", "_tile"];
    _tile deleteAt "queued";
} forEach _tiles;

// Gone with the circle: the ring has run its course.
{ctrlDelete _x} forEach (_head getOrDefault ["fx", []]);

private _sent = [[_head get "move"], _head get "options"] call FUNC(sendMoves);

// Refused (say, the item was taken by somebody else meanwhile): the tile is not on its way.
if (!_sent) then {
    {
        _x params ["", "_tile"];

        _tile set ["pending", false];

        {
            _x ctrlSetFade 0;
            _x ctrlCommit 0;
        } forEach (_tile getOrDefault ["controls", []]);
    } forEach _tiles;
};

call FUNC(drawPending);

_sent
