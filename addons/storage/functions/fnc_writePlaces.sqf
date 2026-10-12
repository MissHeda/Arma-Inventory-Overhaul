#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes where things lie in a holder - on its authority only, always the whole list, once per change:
 * revision = the higher of the one read and the last one written here, plus one. Not written when the
 * records did not change, unless forced (a viewer's stale copy, fnc_opNormalize).
 *
 * The player's own containers (root = the player) - from the player's own moves or outside any phase -
 * are set here at once and broadcast within OWN_WRITE_DELAY seconds (GVAR(dirty), fnc_flushPlaces); any
 * other write is public at once and takes the holder out of GVAR(dirty) - unless a nested tag or a copy
 * of nested places on it still waits there. Kits are written as a public mission variable. The Arsenal
 * and Eden write the same way, outside any phase.
 *
 * In multiplayer the authority keeps its latest write and looks again after HEAL_DELAYS whether an older
 * write of a previous authority overtook it - then it writes its own again (the heal). Only the latest
 * write is ever re-asserted.
 *
 * A uniform, vest or backpack lying in a container keeps its places on its own object, and in
 * multiplayer also in the copy on the outermost container it lies under (einv_storage_nested,
 * fnc_tagNested): whether variables on nested objects reach every machine is not known, the outermost
 * container's always do. A forced write sends that copy again as well.
 *
 * Which phase asked: a phase running here whose transaction this machine requested
 * (GVAR(journalKey) "id|phase|attempt", the id in GVAR(requests)) or no phase at all is the player's
 * own; a phase the hub sent for somebody else is not.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 * 1: Records [[key, col, row, w, h, block], ...] - put in canonical order here <ARRAY>
 * 2: Write even when nothing changed <BOOL> (default: false)
 *
 * Return Value:
 * The holder's revision now, -1 when nothing was written because this machine is not its authority (an
 *    RPT error names it) <NUMBER>
 *
 * Example:
 * [backpackContainer player, _records] call einv_storage_fnc_writePlaces;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_records", [], [[]]], ["_force", false, [false]]];

private _isKey = _holder isEqualType "";

if ((_isKey && {_holder isEqualTo ""}) || {!_isKey && {isNull _holder}}) exitWith {-1};

private _root = [_holder] call FUNC(rootOf);

// Only the authority writes: where the root is local, the server for none. A phase running here - its
// ops, or the writes at its end (GVAR(journalKey) is set until it is done) - was checked for that before
// its first op (fnc_execute); single player and Eden are one machine.
private _authority = !isMultiplayer || {GVAR(executing)} || {GVAR(journalKey) isNotEqualTo ""} || {
    if (isNull _root) then {isServer} else {local _root}
};

if (!_authority) exitWith {
    private _name = if (_isKey) then {_holder} else {typeOf _holder};
    private _machine = call FUNC(machineId);

    ERROR_2("Places of %1 written on machine %2, which is not its authority - not written.",_name,_machine);
    -1
};

// ---------------------------------------------------------------------------
// Canonical: by key, and within a key in the order given - the n-th record of a key is the n-th entry's
// (fnc_getLayout). So "changed" is one comparison, and two machines with the same data hold the same
// array.
// ---------------------------------------------------------------------------
private _groups = createHashMap;
private _keys = [];

{
    if (_x isEqualType [] && {(_x select [0, 6]) isEqualTypeArray ["", 0, 0, 0, 0, 0]}) then {
        private _key = _x select 0;
        private _group = _groups get _key;

        if (isNil "_group") then {
            _group = [];
            _groups set [_key, _group];
            _keys pushBack _key;
        };

        _group pushBack (_x select [0, 6]);
    };
} forEach _records;

_keys sort true;

private _canonical = [];

{
    _canonical append (_groups get _x);
} forEach _keys;

([_holder, true] call FUNC(readPlaces)) params ["_storedRevision", "_storedRecords"];

if (!_force && {_canonical isEqualTo _storedRecords}) exitWith {_storedRevision};

private _written = if (_isKey) then {
    GVAR(writtenKits) getOrDefault [_holder, []]
} else {
    _holder getVariable [QGVAR(written), []]
};

if !(_written isEqualType []) then {_written = []};

private _lastRevision = (_written param [1, []]) param [0, 0];

if !(_lastRevision isEqualType 0) then {_lastRevision = 0};

private _revision = (_storedRevision max _lastRevision) + 1;
private _value = [_revision, _canonical];

// ---------------------------------------------------------------------------
// The player's own: set here at once, broadcast within OWN_WRITE_DELAY (fnc_flushPlaces). Anything else
// public at once. Kits are always public - they change seldom.
// ---------------------------------------------------------------------------
private _ownRoot = !isNull player && {_root isEqualTo player};
private _own = false;

if (isMultiplayer && {hasInterface} && {!_isKey} && {_ownRoot}) then {
    private _journalKey = GVAR(journalKey);
    private _bar = _journalKey find "|";

    _own = _bar < 0 || {(_journalKey select [0, _bar]) in GVAR(requests)};
};

private _public = isMultiplayer && {!_own};
private _dirty = [];

if (_isKey) then {
    missionNamespace setVariable [format ["%1_%2", QGVAR(places), (_holder splitString ":") joinString "_"], _value, _public];
} else {
    _holder setVariable [QGVAR(places), _value, _public];
    _dirty pushBack _holder;

    // Lying in a container: the copy on the outermost one, which every machine reads.
    if (isMultiplayer) then {
        private _top = [_holder, objNull, "top"] call FUNC(rootOf);
        private _netId = netId _holder;

        if (_top isNotEqualTo _holder && {_netId isNotEqualTo ""} && {_netId isNotEqualTo "0:0"}) then {
            private _nested = _top getVariable [QGVAR(nested), []];

            if !(_nested isEqualType []) then {_nested = []};

            // A copy: the stored one is not changed in place.
            _nested = (+_nested) select {_x isEqualTypeArray ["", "", "", []]};

            private _index = _nested findIf {(_x select 0) isEqualTo _netId};
            private _tag = _holder getVariable [QGVAR(tag), []];

            if !(_tag isEqualType []) then {_tag = []};

            private _uid = _tag param [0, ""];
            private _itemClass = _tag param [1, ""];

            if !(_uid isEqualType "") then {_uid = ""};

            if !(_itemClass isEqualType "" && {_itemClass isNotEqualTo ""}) then {
                _itemClass = _holder getVariable [QGVAR(itemClass), ""];
            };

            if (_index >= 0) then {
                private _entry = _nested select _index;

                _entry set [3, +_value];

                // Tagged since the copy was made: the copy takes the id, so it keeps counting
                // (fnc_readPlaces).
                if ((_entry select 1) isEqualTo "" && {_uid isNotEqualTo ""}) then {
                    _entry set [1, _uid];
                };
            } else {
                _nested pushBack [_netId, _uid, _itemClass, +_value];
                _nested sort true;
            };

            _top setVariable [QGVAR(nested), _nested, _public];
            _dirty pushBack _top;
        };

        // Forced for a viewer's stale copy: the copies of nested tags and places kept on it go again too.
        if (_force && {_top isEqualTo _holder}) then {
            private _copy = _holder getVariable QGVAR(nested);

            if (!isNil "_copy") then {
                _holder setVariable [QGVAR(nested), _copy, _public];
            };
        };
    };
};

if (_own) then {
    // The first own write since the last broadcast arms the next one.
    if (GVAR(dirty) isEqualTo []) then {
        [{call FUNC(flushPlaces)}, [], OWN_WRITE_DELAY] call CBA_fnc_waitAndExecute;
    };

    {
        GVAR(dirty) pushBackUnique _x;
    } forEach _dirty;
} else {
    // Public now with the whole list. One that also carries a copy of nested places, or a nested tag,
    // stays: those may still be waiting for their broadcast.
    if (!_isKey && {isNil {_holder getVariable QGVAR(nested)}} && {isNil {_holder getVariable QGVAR(tag)}}) then {
        private _index = GVAR(dirty) find _holder;

        if (_index >= 0) then {GVAR(dirty) deleteAt _index};
    };
};

// What a running phase reads from here on is what was written.
if (GVAR(executing)) then {
    private _index = GVAR(buffer) findIf {(_x select 0) isEqualTo _holder};

    if (_index >= 0) then {
        (GVAR(buffer) select _index) set [1, +_canonical];
    };
};

// ---------------------------------------------------------------------------
// The heal: in multiplayer the latest write is kept here and checked again a little later. A write of a
// previous authority that arrives after this one would otherwise stand. Not for the player's own unit,
// whose owner never changes; never in Eden (not multiplayer).
// ---------------------------------------------------------------------------
if (isMultiplayer && {!_ownRoot}) then {
    private _latest = [_revision, +_value];

    if (_isKey) then {
        GVAR(writtenKits) set [_holder, _latest];
    } else {
        _holder setVariable [QGVAR(written), _latest];
    };

    private _fnc_heal = {
        params ["_holder", "_stamp"];

        private _isKey = _holder isEqualType "";

        if (!_isKey && {isNull _holder}) exitWith {};

        private _latest = if (_isKey) then {
            GVAR(writtenKits) getOrDefault [_holder, []]
        } else {
            _holder getVariable [QGVAR(written), []]
        };

        // A newer write armed checks of its own; a dropped holder has none.
        if !(_latest isEqualType [] && {(_latest param [0, -1]) isEqualTo _stamp}) exitWith {};

        private _root = [_holder] call FUNC(rootOf);

        if !(if (isNull _root) then {isServer} else {local _root}) exitWith {};

        private _value = _latest select 1;
        private _stale = ([_holder, true] call FUNC(readPlaces)) isNotEqualTo _value;

        // Lying in a container: its copy on the outermost one as well.
        if (!_stale && {!_isKey}) then {
            private _top = [_holder, objNull, "top"] call FUNC(rootOf);
            private _netId = netId _holder;

            if (_top isNotEqualTo _holder && {_netId isNotEqualTo ""} && {_netId isNotEqualTo "0:0"}) then {
                private _nested = _top getVariable [QGVAR(nested), []];
                private _index = if (_nested isEqualType []) then {
                    _nested findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}}
                } else {-1};

                _stale = _index < 0 || {((_nested select _index) select 3) isNotEqualTo _value};
            };
        };

        if (_stale) then {
            private _name = if (_isKey) then {_holder} else {typeOf _holder};

            WARNING_1("Places of %1 were overtaken by an older write - written again.",_name);
            [_holder, _value select 1, true] call FUNC(writePlaces);
        };
    };

    {
        [_fnc_heal, [_holder, _revision], _x] call CBA_fnc_waitAndExecute;
    } forEach HEAL_DELAYS;
};

_revision
