#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * For missions: moves what a tile stands for, as a transaction (fnc_request) - within one holder to
 * another cell (op "place"), within one root into another container ("move"), else out of the one and
 * into the other ("take", then "put", each at its own root's authority). Kits (einv_compat_efak) move
 * with their own ops (einv_storage_holderTypes). The window no longer calls this.
 *
 * A backpack into a backpack (fnc_backpackIntoBackpack) and, with no cell given, a free spot
 * (fnc_hasSpace) are asked here first; the machine that runs it asks again and decides.
 *
 * Arguments:
 * 0: Holder it lies in - a container, or a kit's key <OBJECT or STRING>
 * 1: Holder it goes to <OBJECT or STRING>
 * 2: Entry, as fnc_getLayout placed it - or as fnc_getContents gave it: then any tile of its kind <HASHMAP>
 * 3: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 * 4: Cell [col, row, block] - with [.., w, h] when it lies turned there - in the target, [] for the first
 *    free spot <ARRAY> (default: [])
 * 5: Requester - whose reach counts; on a dedicated server a unit local there <OBJECT> (default: objNull -
 *    the player, fnc_request)
 *
 * Return Value:
 * "" when it was moved here and then, "Requested" when it went to the server and is moved shortly, else
 * why not ("NoBackpack", "NoRoom", "Gone", "Taken", "IntoItself", "OutOfReach", "Moved", "NotReady",
 * "Bounced" - it went back where it was -, "Failed") <STRING>
 *
 * Example:
 * [uniformContainer player, backpackContainer player, _entry] call einv_storage_fnc_moveEntry;
 *
 * Public: Yes
 */

params [
    ["_from", objNull, [objNull, ""]],
    ["_to", objNull, [objNull, ""]],
    ["_entry", createHashMap, [createHashMap]],
    ["_count", -1, [0]],
    ["_cell", [], [[]]],
    ["_requester", objNull, [objNull, false]]
];

// Before 0.2.0 the sixth argument said whether to keep the layouts in step - they always are now.
if !(_requester isEqualType objNull) then {
    _requester = objNull;
};

private _fnc_gone = {
    params ["_holder"];

    if (_holder isEqualType "") then {_holder isEqualTo ""} else {isNull _holder}
};

if ([_from] call _fnc_gone || {[_to] call _fnc_gone} || {count _entry == 0}) exitWith {"Failed"};

// The op of a holder's type: storage's own for a container, the type's for a kit.
private _fnc_op = {
    params ["_holder", "_op"];

    if (_holder isEqualType "") then {
        (GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap]) getOrDefault [_op, ""]
    } else {
        _op
    }
};

private _fromRoot = [_from] call FUNC(rootOf);
private _toRoot = [_to] call FUNC(rootOf);

if (isNull _fromRoot || {isNull _toRoot}) exitWith {"Failed"};

if (_from isEqualTo _to && {_cell isEqualTo []}) exitWith {""};

// A backpack never goes into a backpack.
if (_to isEqualType objNull && {_from isNotEqualTo _to} && {[_to, _entry] call FUNC(backpackIntoBackpack)}) exitWith {"NoBackpack"};

// Nothing may land beside the grid: with no cell given it needs a free spot.
if (
    _to isEqualType objNull && {_from isNotEqualTo _to}
    && {_cell isEqualTo []} && {!([_to, _entry] call FUNC(hasSpace))}
) exitWith {"NoRoom"};

private _entryArray = [_entry] call FUNC(entryToArray);
private _take = [_from, "take"] call _fnc_op;
private _put = [_to, "put"] call _fnc_op;
private _putArgs = [[_to, ["#ref", 0, 0, 0], _cell, false], [_to, ["#ref", 0, 0, 0], _cell]] select (_to isEqualType "");
private _phases = [];

switch (true) do {
    case (_from isEqualTo _to): {
        if (_cell isNotEqualTo []) then {
            private _place = [_from, "place"] call _fnc_op;

            if (_place isNotEqualTo "") then {
                _phases = [[_fromRoot, [[_place, [_from, _entryArray, _cell]]]]];
            };
        };
    };
    case (_fromRoot isNotEqualTo _toRoot): {
        // Two roots: each phase is checked against its own - chain, reach, guards, locality. The put's
        // payload is the one the take produced.
        if (_take isNotEqualTo "" && {_put isNotEqualTo ""}) then {
            _phases = [[_fromRoot, [[_take, [_from, _entryArray, _count]]]], [_toRoot, [[_put, _putArgs]]]];
        };
    };
    case (_from isEqualType objNull && {_to isEqualType objNull}): {
        _phases = [[_fromRoot, [["move", [_from, _to, _entryArray, _count, _cell]]]]];
    };
    case (_from isEqualType "" && {_to isEqualType ""}): {
        private _move = [_from, "move"] call _fnc_op;

        if (_move isNotEqualTo "") then {
            _phases = [[_fromRoot, [[_move, [_from, _to, _entryArray, _count, _cell]]]]];
        };
    };
    default {
        // A kit and a container under one root: out and in within one phase.
        if (_take isNotEqualTo "" && {_put isNotEqualTo ""}) then {
            _phases = [[_fromRoot, [[_take, [_from, _entryArray, _count]], [_put, _putArgs]]]];
        };
    };
};

if (_phases isEqualTo []) exitWith {"Failed"};

// Answered here and now when every phase ran here; else the server's hub answers later.
private _answers = [];
private _id = [_phases, {(_this select 3) pushBack (_this select 1)}, _answers, false, _requester] call FUNC(request);

if (_id isEqualTo "") exitWith {"Failed"};
if (_answers isEqualTo []) exitWith {"Requested"};

private _status = "";

{
    {
        if ((_x param [0, ""]) isNotEqualTo "") exitWith {
            _status = _x select 0;
        };
    } forEach _x;

    if (_status isNotEqualTo "") exitWith {};
} forEach (((_answers select 0) param [0, []]));

_status
