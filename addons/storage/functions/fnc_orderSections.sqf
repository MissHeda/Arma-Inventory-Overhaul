#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the loot column's sections in their final order. A section with a "parent" - a uniform, vest or
 * backpack opened from inside a container, a kit - lies right below its parent's section, after the
 * parent's earlier children and what hangs under them; the ones whose parent is not in the column (opened
 * from the player's own storage) come after what was looted and before the nearby boxes, as they stood
 * before there were any.
 *
 * Sections without a parent keep the order they came in: what the window was opened on, the engine's
 * second container, then the nearby boxes (their "nearby" is true).
 *
 * Arguments:
 * 0: Sections, as fnc_getLootSections builds them <ARRAY of HASHMAPs>
 *
 * Return Value:
 * The same sections, in order <ARRAY of HASHMAPs>
 *
 * Example:
 * [_sections] call aio_storage_fnc_orderSections;
 *
 * Public: No
 */

params [["_sections", [], [[]]]];

// A parent is a container object, or a kit's key; null and "" mean none.
private _fnc_parentOf = {
    params ["_section"];

    _section getOrDefault ["parent", objNull]
};

private _fnc_hasParent = {
    params ["_section"];

    private _parent = _section getOrDefault ["parent", objNull];

    if (_parent isEqualType "") exitWith {_parent isNotEqualTo ""};

    _parent isEqualType objNull && {!isNull _parent}
};

// What a section stands for as somebody's parent: its container, or its key.
private _fnc_selfOf = {
    params ["_section"];

    private _container = _section getOrDefault ["container", objNull];

    if (isNull _container) then {_section getOrDefault ["key", ""]} else {_container}
};

private _top = _sections select {!([_x] call _fnc_hasParent)};
private _kids = _sections select {[_x] call _fnc_hasParent};

if (_kids isEqualTo []) exitWith {_sections};

private _selves = _top apply {[_x] call _fnc_selfOf};

// Children whose parent is no section here: after what was looted, before the nearby boxes.
private _orphans = [];
private _placed = [];

{
    private _parent = [_x] call _fnc_parentOf;
    private _known = _selves findIf {_x isEqualTo _parent} >= 0;

    if (!_known) then {
        private _kidSelves = _kids apply {[_x] call _fnc_selfOf};

        _known = _kidSelves findIf {_x isEqualTo _parent} >= 0;
    };

    if (_known) then {
        _placed pushBack _x;
    } else {
        _orphans pushBack _x;
    };
} forEach _kids;

_kids = _placed;

private _looted = _top select {!(_x getOrDefault ["nearby", false])};
private _nearby = _top select {_x getOrDefault ["nearby", false]};
private _ordered = _looted + _orphans + _nearby;

// The rest, as many rounds as there are levels of nesting (the engine nests three at most): each child goes
// below its parent once that one is placed, after the children placed there before it.
for "_round" from 1 to 4 do {
    if (_kids isEqualTo []) exitWith {};

    private _left = [];

    {
        private _child = _x;
        private _parent = [_child] call _fnc_parentOf;
        private _at = _ordered findIf {([_x] call _fnc_selfOf) isEqualTo _parent};

        if (_at < 0) then {
            _left pushBack _child;
            continue;
        };

        // Past the parent, its earlier children and what hangs under those.
        private _place = _at + 1;
        private _family = [_parent];

        while {_place < count _ordered} do {
            private _next = _ordered select _place;
            private _nextParent = [_next] call _fnc_parentOf;

            if (!([_next] call _fnc_hasParent) || {_family findIf {_x isEqualTo _nextParent} < 0}) exitWith {};

            _family pushBack ([_next] call _fnc_selfOf);
            _place = _place + 1;
        };

        _ordered = (_ordered select [0, _place]) + [_child] + (_ordered select [_place]);
    } forEach _kids;

    _kids = _left;
};

// A child whose parent never turned up (a cycle, a section left out): at the end rather than lost.
_ordered append _kids;

_ordered
