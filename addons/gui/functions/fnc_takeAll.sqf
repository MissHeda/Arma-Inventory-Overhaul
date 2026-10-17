#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Take all" on a section of the loot column: everything searched in it moves into the unit's uniform, vest
 * and backpack, in that order (einv_storage_fnc_plan, then fnc_sendPlan). Worked out from what the
 * container holds, not from what is drawn, so it also works on a section folded away to its caption. What
 * is not searched yet stays ("3 not searched yet"), so does a tile a move is under way for, and what finds
 * no room ("Moved 7 of 10 - no room for the rest"). A living person's gear only as the settings for it say
 * (fnc_checkTouch). With a category chosen at the box or a word in the search field, only the tiles that show (that match) are taken.
 *
 * Arguments:
 * 0: The section's container <OBJECT>
 *
 * Return Value:
 * Something was sent <BOOL>
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_takeAll;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull]]];

if (isNull _holder || {!(call FUNC(isInventoryMode))}) exitWith {false};

private _section = (GVAR(context) getOrDefault ["lootSections", []]) param [
    (GVAR(context) getOrDefault ["lootSections", []]) findIf {(_x getOrDefault ["container", objNull]) isEqualTo _holder}, createHashMap
];

if (count _section == 0) exitWith {false};

private _why = [_holder, "items"] call FUNC(checkTouch);

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(flashHint);
    false
};

// What lies there, in the order it lies; what is not searched yet is marked (and not queued).
private _placed = ([_holder, [_holder] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";

[_holder, _placed, false] call FUNC(markHidden);

// Tiles a move of this window takes from, and those waiting for the hands, are not planned a second time.
private _pending = [];

{
    _pending append (_y param [0, []]);
} forEach GVAR(inFlight);

private _items = [];
private _hidden = 0;
private _root = _section getOrDefault ["root", objNull];

// Only what the player sees: with a category chosen at the box or a word in the search field, the tiles that do not match are hidden
// (fnc_applyFilter) and stay where they lie.
private _boxGroup = [_holder] call FUNC(boxGroup);
private _searching = GVAR(filter) isNotEqualTo "" || {_boxGroup isNotEqualTo ""};

{
    if (_x getOrDefault ["hidden", false]) then {
        _hidden = _hidden + 1;
        continue;
    };

    private _entry = _x;

    if (_searching && {!([_entry getOrDefault ["class", ""]] call FUNC(matchesFilter)) || {!([_entry getOrDefault ["class", ""], _boxGroup] call FUNC(matchesGroup))}}) then {continue};

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

    // Another living player's kit stays where it is, as for a single tile (einv_compat_efak).
    if (!isNil QEFUNC(compat_efak,checkTile) && {([_entry getOrDefault ["class", ""], _holder] call EFUNC(compat_efak,checkTile)) isNotEqualTo ""}) then {continue};

    _entry set ["holder", _holder];
    _entry set ["root", _root];
    _items pushBack _entry;
} forEach _placed;

if (_items isEqualTo []) exitWith {
    if (_hidden > 0) then {
        [format [LLSTRING(Hint_NotSearched), _hidden]] call FUNC(flashHint);
    };

    false
};

private _unit = GVAR(unit);
private _targets = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] select {!isNull _x} apply {[_x, _unit]};

([_items, _targets] call EFUNC(storage,plan)) params ["_assigned"];

[_assigned, count _items, _hidden] call FUNC(sendPlan)
