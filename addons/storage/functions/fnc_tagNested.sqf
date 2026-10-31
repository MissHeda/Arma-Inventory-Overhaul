#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives every uniform, vest and backpack lying in a container an id of its own, on the container's
 * authority, as part of every normalise: [id, item class, container it lies in], kept where every
 * machine reads it (fnc_newUid). Siblings of one class with the same id - a copy came in from elsewhere
 * - get a fresh one.
 *
 * The id is part of the nested container's key (fnc_entryKey), and its places and tag travel with it in
 * payloads (fnc_snapshot): a moved backpack keeps its inside arrangement and its id.
 *
 * Where it is kept: on the nested object itself (aio_storage_tag, public) and, in multiplayer, in a copy
 * on the outermost container the nested ones lie under - a crate, vehicle, pile or a unit's uniform,
 * vest or backpack: aio_storage_nested = [[netId, id, item class, places], ...], sorted by netId,
 * covering every nested container under it, three levels deep. Whether variables on nested objects reach
 * other machines and those joining later is not known; the outermost container's always do. Readers take
 * the object's own tag first and the copy where it is missing (fnc_entryKey, fnc_readPlaces), and both
 * always hold the same - the copy is built here from the objects, so a tag fnc_restore set on a new
 * object, or places written on it, are taken over the moment its container is normalised. Copies of
 * objects that are gone drop out.
 *
 * Only the direct children of the container get ids here: their keys are the container's records, which
 * the same normalise writes next (fnc_normalize). Deeper ones get theirs when their own container is
 * normalised.
 *
 * On the way it leaves the marks every machine needs on the nested objects: their item class
 * (aio_storage_itemClass, fnc_getBlocks) and where they lie (aio_storage_parent, fnc_rootOf).
 *
 * The player's own: set here at once and broadcast with the places (GVAR(dirty), fnc_flushPlaces).
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Send every tag and the copy again, changed or not - for a viewer's stale copy (fnc_opNormalize)
 *    <BOOL> (default: false)
 *
 * Return Value:
 * Something was tagged or the copy was written <BOOL>
 *
 * Example:
 * [cursorObject] call aio_storage_fnc_tagNested;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_force", false, [false]]];

if (isNull _container) exitWith {false};

private _root = [_container] call FUNC(rootOf);

// Only the authority hands out ids; a phase running here was checked for that already.
private _authority = !isMultiplayer || {GVAR(executing)} || {GVAR(journalKey) isNotEqualTo ""} || {
    if (isNull _root) then {isServer} else {local _root}
};

if (!_authority) exitWith {false};

// The player's own, as fnc_writePlaces decides it: set here, broadcast within OWN_WRITE_DELAY.
private _own = false;

if (isMultiplayer && {hasInterface} && {!isNull player} && {_root isEqualTo player}) then {
    private _journalKey = GVAR(journalKey);
    private _bar = _journalKey find "|";

    _own = _bar < 0 || {(_journalKey select [0, _bar]) in GVAR(requests)};
};

private _public = isMultiplayer && {!_own};
private _top = [_container, objNull, "top"] call FUNC(rootOf);

// ---------------------------------------------------------------------------
// Everything nested under the outermost container, three levels deep, parents before children:
// [object, item class, parent].
// ---------------------------------------------------------------------------
private _tree = [];
private _level = [_top];

for "_depth" from 1 to 3 do {
    private _next = [];

    {
        private _parent = _x;

        {
            _x params ["_class", "_object"];

            _object setVariable [QGVAR(itemClass), _class];
            _object setVariable [QGVAR(parent), _parent];
            _tree pushBack [_object, _class, _parent];
            _next pushBack _object;
        } forEach (everyContainer _parent);
    } forEach _level;

    if (_next isEqualTo []) exitWith {};

    _level = _next;
};

private _old = [];

if (isMultiplayer) then {
    _old = _top getVariable [QGVAR(nested), []];

    if !(_old isEqualType []) then {_old = []};
};

private _taken = [];
private _copy = [];
private _changed = false;
private _dirty = [];

{
    _x params ["_object", "_class", "_parent"];

    private _netId = netId _object;
    private _tag = _object getVariable [QGVAR(tag), []];

    if !(_tag isEqualType []) then {_tag = []};

    private _uid = _tag param [0, ""];

    if !(_uid isEqualType "") then {_uid = ""};

    // The copy keeps the id where the object's own tag did not reach this machine - a new authority
    // after a change of locality.
    private _oldIndex = _old findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}};
    private _oldEntry = if (_oldIndex >= 0) then {_old select _oldIndex} else {[]};

    if (_uid isEqualTo "" && {_oldEntry isNotEqualTo []}) then {
        _uid = _oldEntry select 1;
    };

    // A direct child without an id, or with one another already has: a fresh one.
    if (_parent isEqualTo _container && {_uid isEqualTo "" || {_uid in _taken}}) then {
        _uid = call FUNC(newUid);
    };

    if (_uid isNotEqualTo "") then {
        _taken pushBack _uid;

        private _wanted = [_uid, _class, _parent];

        if (_force || {_tag isNotEqualTo _wanted}) then {
            _object setVariable [QGVAR(tag), _wanted, _public];
            _dirty pushBack _object;
            _changed = true;
        };
    };

    // The copy: its id, and its places as fnc_readPlaces counts them - the fresher of the object's own
    // and the old copy, as long as that carried the same id.
    if (isMultiplayer && {_netId isNotEqualTo ""} && {_netId isNotEqualTo "0:0"}) then {
        private _places = _object getVariable [QGVAR(places), [0, []]];

        if !(_places isEqualTypeArray [0, []]) then {_places = [0, []]};

        if (_oldEntry isNotEqualTo [] && {(_oldEntry select 1) in ["", _uid]}) then {
            private _oldPlaces = _oldEntry select 3;

            if (_oldPlaces isEqualTypeArray [0, []] && {(_oldPlaces select 0) > (_places select 0)}) then {
                _places = _oldPlaces;
            };
        };

        if (_uid isNotEqualTo "" || {(_places select 0) > 0}) then {
            _copy pushBack [_netId, _uid, _class, +_places];
        };
    };
} forEach _tree;

if (isMultiplayer) then {
    _copy sort true;

    if (_force || {_copy isNotEqualTo _old}) then {
        _top setVariable [QGVAR(nested), _copy, _public];
        _dirty pushBack _top;
        _changed = true;
    };
};

if (_own && {_dirty isNotEqualTo []}) then {
    // The first own write since the last broadcast arms the next one.
    if (GVAR(dirty) isEqualTo []) then {
        [{call FUNC(flushPlaces)}, [], OWN_WRITE_DELAY] call CBA_fnc_waitAndExecute;
    };

    {
        GVAR(dirty) pushBackUnique _x;
    } forEach _dirty;
};

_changed
