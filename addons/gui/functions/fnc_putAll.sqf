#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Put all in" on one of the unit's own sections - its uniform, vest or backpack, or a container opened from
 * one of them: everything in it moves into the first container of the loot column that takes things, the
 * next one when that is full (fnc_putAllTarget, einv_storage_fnc_plan, fnc_sendPlan). Never onto the
 * ground. A tile a move is under way for is not planned a second time; what finds no room stays ("Moved 7
 * of 10 - no room for the rest").
 *
 * Arguments:
 * 0: The section's container <OBJECT>
 *
 * Return Value:
 * Something was sent <BOOL>
 *
 * Example:
 * [backpackContainer player] call einv_gui_fnc_putAll;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]]];

if (isNull _holder || {!(call FUNC(isInventoryMode))}) exitWith {false};

private _targets = call FUNC(putAllTarget);

if (_targets isEqualTo []) exitWith {
    ["NowhereToGo"] call FUNC(flashHint);
    false
};

private _placed = ([_holder, [_holder] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";

// Tiles a move of this window takes from, and those waiting for the hands, are not planned a second time.
private _pending = [];

{
    _pending append (_y param [0, []]);
} forEach GVAR(inFlight);

private _items = [];
private _unit = GVAR(unit);

{
    private _entry = _x;

    if (_pending findIf {
        _x params [["_pendingHolder", objNull], ["_pendingKey", ""], ["_pendingBlock", 0], ["_pendingCol", -1], ["_pendingRow", -1]];

        _pendingHolder isEqualTo _holder && {_pendingKey isEqualTo (_entry getOrDefault ["key", ""])}
        && {_pendingBlock == (_entry getOrDefault ["block", 0])} && {_pendingCol == (_entry getOrDefault ["col", -1])}
        && {_pendingRow == (_entry getOrDefault ["row", -1])}
    } >= 0) then {continue};

    // And those waiting for the hands (fnc_queueMoves), found in the queue's index, not by a pass over the queue.
    if ([[
        _holder, _entry getOrDefault ["key", ""], _entry getOrDefault ["block", 0], _entry getOrDefault ["col", -1], _entry getOrDefault ["row", -1]
    ]] call FUNC(queueWaits)) then {continue};

    _entry set ["holder", _holder];
    _entry set ["root", _unit];
    _items pushBack _entry;
} forEach _placed;

if (_items isEqualTo []) exitWith {false};

([_items, _targets] call EFUNC(storage,plan)) params ["_assigned"];

[_assigned, count _items] call FUNC(sendPlan)
