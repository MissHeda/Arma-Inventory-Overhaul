#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Sends what einv_storage_fnc_plan worked out for several tiles moved together - Take all, Put all in, a
 * group quick move, a group dragged over a container (fnc_takeAll, fnc_putAll, fnc_quickMoveGroup,
 * fnc_endDrag) - as moves (fnc_sendMoves): every tile to the cell planned for it, the ones that stay in
 * their own holder laid down at once (kind "placeMany"), so two of them never wait for each other's cells.
 *
 * The hint says how it went once everything planned did (fnc_afterAction): "Moved 4 of 6 - no room for
 * the rest" when the plan left some behind, and how many were not searched yet when the caller says so.
 * With nothing planned there is nothing to send and the hint says that there is nowhere to go.
 *
 * Arguments:
 * 0: What was planned, [[item, holder, root, cell], ...] - as einv_storage_fnc_plan answers, each item
 *    with "holder" and "root" of where it lies <ARRAY>
 * 1: How many tiles were meant to move, those left behind included <NUMBER>
 * 2: Not searched yet, and so left out <NUMBER> (default: 0)
 * 3: Options for fnc_sendMoves <HASHMAP> (default: empty)
 *
 * Return Value:
 * Something was sent <BOOL>
 *
 * Example:
 * [_assigned, count _items] call einv_gui_fnc_sendPlan;
 *
 * Public: No
 */

params [["_assigned", [], [[]]], ["_total", 0, [0]], ["_hidden", 0, [0]], ["_options", createHashMap, [createHashMap]]];

private _label = [];

if (count _assigned < _total) then {
    _label pushBack format [LLSTRING(Hint_MovedSome), count _assigned, _total];
};

if (_hidden > 0) then {
    _label pushBack format [LLSTRING(Hint_NotSearched), _hidden];
};

if (_assigned isEqualTo []) exitWith {
    // Nothing fits anywhere: one hint with the reason, and the number not searched with it.
    private _text = LLSTRING(Hint_NowhereToGo);

    if (_hidden > 0) then {
        _text = _text + ", " + format [LLSTRING(Hint_NotSearched), _hidden];
    };

    [_text] call FUNC(flashHint);

    false
};

// Those that stay in their holder go in one move per holder; every other tile is a move of its own.
private _moves = [];
private _laid = [];

{
    _x params ["_item", "_to", "_root", "_cell"];

    private _from = _item getOrDefault ["holder", objNull];
    private _fromRoot = _item getOrDefault ["root", objNull];

    if (_from isEqualTo _to && {_cell isNotEqualTo []}) then {
        private _at = _laid findIf {(_x select 0) isEqualTo _from};

        if (_at < 0) then {
            _at = _laid pushBack [_from, _fromRoot, []];
        };

        // An upright cell of the plan has the item's own size; op placeMany would take the size the tile
        // lies in now - turned, it would not be the cells the plan kept for it.
        if (count _cell < 5) then {
            ((([_item getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]])) params [["_sizeW", 1], ["_sizeH", 1]];

            _cell = [_cell select 0, _cell select 1, _cell param [2, 0], _sizeW, _sizeH, 0];
        };

        ((_laid select _at) select 2) pushBack [_item, _cell];
        continue;
    };

    _moves pushBack createHashMapFromArray [
        ["kind", "move"], ["from", _from], ["fromRoot", _fromRoot], ["entry", _item],
        ["to", _to], ["toRoot", _root], ["cell", _cell]
    ];
} forEach _assigned;

// The ones laid down within their holder go first: the cells the plan gave the others may be the ones
// they leave ("lifted", einv_storage_fnc_plan), and a put that found them still taken would land elsewhere.
_moves = (_laid apply {
    _x params ["_from", "_fromRoot", "_tiles"];

    createHashMapFromArray [
        ["kind", "placeMany"], ["from", _from], ["fromRoot", _fromRoot], ["tiles", _tiles]
    ]
}) + _moves;

if (_label isNotEqualTo [] && {(_options getOrDefault ["label", ""]) isEqualTo ""}) then {
    _options set ["label", _label joinString ", "];
};

[_moves, _options] call FUNC(sendMoves)
