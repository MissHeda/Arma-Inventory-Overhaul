#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "strict": brings a unit's hidden holder and its uniform, vest and backpack in line with the settings
 * "Use items from ..." on Strict (fnc_hiddenLists). The holder keeps, per container, what the setting keeps
 * out of the cargo: items of the limited kinds (USE_ITEM_KINDS) that are not whitelisted for it
 * (fnc_useState "blocked"). The window shows them as the container's own tiles all the same
 * (fnc_getContents merges them, marked "strict"), so nothing visibly moves here. Per container, in order:
 *
 *   1. Out of the holder - what no longer belongs there. The holder's list of a kind whose container is not
 *      Strict any more, or while the holder is not in force (fnc_hiddenActive: the unit died, became an AI,
 *      an arsenal is open here), goes back into that container, raw (fnc_addPayload) and verified; on a
 *      Strict container only what is whitelisted meanwhile goes back. A list taken out of a container that is
 *      not the one worn now (swapped, dropped or replaced by another mod, a script, a loadout) follows that
 *      container when it is still an object anywhere - into the dropped backpack, as its contents went -,
 *      and is gone with it when it was deleted, as its contents were (the RPT says so). With no container of
 *      the kind left, another of the unit's takes it, else a pile at its feet.
 *   2. Into the holder - what lies in a Strict container's cargo and may not: every such tile is taken out
 *      (fnc_removeEntry, verified) and put in again (fnc_addPayload), which routes it into the holder
 *      (fnc_hiddenRoute, fnc_hiddenPut). What the holder will not take goes back into the cargo.
 *
 * The holder is written on the unit after every step, so a script error cannot put anything back twice,
 * and public once at the end (fnc_hiddenWrite). The places need no change: a hidden tile has the key its
 * cargo twin would have, so its record stays. The unit's containers are laid out and written once at the end
 * of the phase, and their views dropped (fnc_execute). The person guard lets it through for any requester,
 * like "migrate".
 *
 * Asked for by fnc_requestMigrate when fnc_hiddenDue says there is something to do: the player's own unit
 * runs it at once, any other through the hub on its owner. Nothing in Eden.
 *
 * Extra: [tiles taken into the holder, entries given back, entries gone with a deleted container].
 *
 * Arguments:
 * 0: Args, [unit] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status - "" done (also with nothing to do), else why not ("Moved" the unit is gone, "Skipped" in Eden,
 *     "Bounced" something is produced)
 *   produced - the payloads it handed on, each consumed by a later op or settled
 *     (aio_storage_fnc_settle)
 *   extra - what else it tells, [] for nothing
 *
 * Example:
 * [[player], _context] call aio_storage_fnc_opStrict;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {["Moved", [], []]};
if (is3DEN) exitWith {["Skipped", [], []]};

private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _active = (missionNamespace getVariable [QGVAR(strictActive), false]) && {[_unit] call FUNC(hiddenActive)};

([_unit] call FUNC(hiddenLists)) params ["_lists", "_containers"];

private _hidden = 0;
private _returned = 0;
private _discarded = 0;
private _produced = [];
private _pile = objNull;

// On the unit at once after every step - a script error must not give anything back twice or hide it twice.
private _fnc_save = {
    _unit setVariable [QGVAR(hidden), [_lists, _containers]];
};

{
    private _index = _forEachIndex;
    private _kind = _x;
    private _container = _own select _index;
    private _list = _lists select _index;
    private _strict = _active && {!isNull _container} && {([_kind] call FUNC(useMode)) isEqualTo USE_STRICT};

    // -----------------------------------------------------------------------
    // 1. Out of the holder.
    // -----------------------------------------------------------------------
    if (_list isNotEqualTo []) then {
        private _recorded = _containers select _index;
        private _target = _container;
        private _back = [];

        if (_recorded isNotEqualTo _container) then {
            // Taken out of a container that is not the one worn now: they follow it where it still is, and
            // are gone with it where it was deleted.
            _back = +_list;
            _target = _recorded;
        } else {
            _back = if (_strict) then {
                _list select {([_x select 0, _kind] call FUNC(useState)) isNotEqualTo "blocked"}
            } else {
                +_list
            };

            // No container of its kind: another of the unit's, else a pile at its feet.
            if (isNull _target) then {
                _target = (_own select {!isNull _x}) param [0, objNull];
            };

            if (isNull _target) then {
                if (isNull _pile) then {
                    _pile = [_unit, objNull, true] call FUNC(getGroundHolder);
                };

                _target = _pile;
            };
        };

        {
            private _entry = _x;
            private _at = _list find _entry;

            if (_at < 0) then {continue};

            _list deleteAt _at;

            if (isNull _target) then {
                _discarded = _discarded + 1;
            } else {
                _entry params ["_class", "_count", "_ammo"];

                private _rest = [_target, [_class, _count, _ammo] call FUNC(hiddenPayload), true] call FUNC(addPayload);

                if (_rest isNotEqualTo []) then {
                    private _n = if ((_rest select 0) isEqualTo "magazine") then {count (_rest select 2)} else {_rest param [2, 0]};

                    if (_n > 0) then {
                        [_list, _class, _n, _ammo] call FUNC(hiddenAdd);
                    };
                };

                _returned = _returned + 1;
            };

            call _fnc_save;
        } forEach _back;

        if (_list isEqualTo []) then {
            _containers set [_index, objNull];
            call _fnc_save;
        };
    };

    // -----------------------------------------------------------------------
    // 2. Into the holder.
    // -----------------------------------------------------------------------
    if (_strict) then {
        private _entries = ([_container] call FUNC(getContents)) select {
            !(_x getOrDefault ["strict", false]) && {([_x get "class", _kind] call FUNC(useState)) isEqualTo "blocked"}
        };

        {
            private _payload = [_container, _x] call FUNC(removeEntry);

            if (_payload isEqualTo []) then {continue};

            private _rest = [_container, _payload] call FUNC(addPayload);

            if (_rest isEqualTo []) then {
                ["in", _payload] call FUNC(journalNote);
                _hidden = _hidden + 1;
            } else {
                // The holder would not take it (its state changed under us): back into the cargo as it was.
                // What even that does not take is produced and settles.
                private _again = [_container, _rest, true] call FUNC(addPayload);

                if (_again isEqualTo []) then {
                    ["in", _payload] call FUNC(journalNote);
                } else {
                    _produced pushBack _again;
                };
            };
        } forEach _entries;

        // fnc_hiddenPut wrote the holder: read again for the kinds after this one.
        private _fresh = [_unit] call FUNC(hiddenLists);

        _lists = _fresh select 0;
        _containers = _fresh select 1;
    };
} forEach USE_KINDS;

[_unit, [_lists, _containers]] call FUNC(hiddenWrite);

if (!isNull _pile) then {
    [_pile] call FUNC(pruneScriptedPile);
};

if (_discarded > 0) then {
    INFO_2("%1 hidden entries of %2 were taken out of a container that was deleted since - gone with it, as its cargo was.",_discarded,_unit);
};

if (_produced isNotEqualTo []) exitWith {["Bounced", _produced, [_hidden, _returned, _discarded]]};

["", [], [_hidden, _returned, _discarded]]
