#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The lock on every op of a transaction (einv_storage_guards), checked on the machine that runs the op -
 * the root's authority -, whoever sent it and whatever the requester's window showed: a lock set a moment
 * ago, a script, a client without this window. Refuses an op that reaches into a container the
 * requester may not open (fnc_canReach: a lock of ours, a lock the mission set, another mod's lock such
 * as ACE's vehicle lock).
 *
 * What an op reaches into: the holders it names, and the phase's root - the crate or vehicle also for a
 * backpack opened inside it, and for a kit of Enhanced First Aid Kits (a holder that is no object, left
 * to its root). A unit's own slots (takeOff, putOn) and the ground at the feet (putGround) are never
 * locked, and neither is any container whose root is a unit: gear and bodies cannot be locked, and a
 * backpack lying in a locked crate has the crate for its root. Each holder is asked with its own root:
 * two crates of one move share an authority, not a root.
 *
 * Settlement phases (the system putting things back) do not ask guards, and nobody asking - a script that
 * names no requester - has nothing to check. Every input is global: the lock record, the unit's group
 * and side, the admin login (the server only: another client's login is unknown to a client authority),
 * Zeus, ACE's vehicle lock and keys.
 *
 * Arguments:
 * 0: Op <STRING>
 * 1: Its args <ARRAY>
 * 2: Requester <OBJECT>
 * 3: Root <OBJECT>
 *
 * Return Value:
 * "" when allowed, "Locked" when not <STRING>
 *
 * Example:
 * ["take", [_crate, _entryArray, 1], player, _crate] call einv_locks_fnc_guard;
 *
 * Public: No
 */

params [
    ["_op", "", [""]],
    ["_args", [], [[]]],
    ["_requester", objNull, [objNull]],
    ["_root", objNull, [objNull]]
];

if (isNull _requester) exitWith {""};

private _holders = [];

switch (_op) do {
    case "move": {
        _holders = [_args param [0, objNull], _args param [1, objNull]];
    };
    // einv_magazines: every container of the repack.
    case "repack": {
        _holders = ((_args param [0, []]) select {_x isEqualType []}) apply {_x param [0, objNull]};
    };
    case "place";
    case "placeMany";
    case "sort";
    case "normalize";
    case "take";
    case "put": {
        _holders = [_args param [0, objNull]];
    };
};

_holders pushBack _root;

private _reason = "";

{
    private _holder = _x;

    if (_holder isEqualType objNull && {!isNull _holder} && {!(_holder isKindOf "CAManBase")}) then {
        private _top = [_holder] call EFUNC(storage,rootOf);

        // Nobody can say where it lies: it counts as its own root.
        if (isNull _top) then {
            _top = _holder;
        };

        // Gear and bodies: never locked, and nothing lying in them is.
        if !(_top isKindOf "CAManBase") then {
            private _chain = objNull;

            if (_top isNotEqualTo _holder) then {
                _chain = _top;
            };

            if !(([_requester, _holder, _chain] call FUNC(canReach)) select 0) then {
                _reason = "Locked";
            };
        };
    };

    if (_reason isNotEqualTo "") exitWith {};
} forEach _holders;

_reason
