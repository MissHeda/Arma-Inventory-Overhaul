#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a holder really lies under a root, walked through the real cargo (everyContainer, three levels
 * at most; a holder of another type through its "verify", GVAR(holderTypes)) - run by the machine that
 * executes a phase, before anything is touched: a holder no longer where the requester thought gives
 * "Moved".
 *
 * On the way it sets the local marks every machine that lays out a holder needs: the owner mark on a
 * unit's container (fnc_getOwner), so the server lays out a body's pockets as the clients do, and the
 * item class on every nested container it passes (fnc_getBlocks) - with where it lies (aio_storage_parent,
 * fnc_rootOf), so the places written next find the outermost container to keep their copy on.
 *
 * Where the root is local - the authority, about to run ops - the whole cargo under it is walked, and
 * every nested container whose tag or places on its own object are missing or older here than the copy
 * on its outermost container (aio_storage_nested, fnc_tagNested) takes the copy's, on this machine
 * only: a machine that just became the authority may never have received them on the objects, and the
 * ops read them from there (fnc_snapshot carries them along). The copy counts only with the same id as
 * the object's own tag, or with none here.
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 * 1: Root <OBJECT>
 *
 * Return Value:
 * It lies there <BOOL>
 *
 * Example:
 * [backpackContainer _unit, _unit] call aio_storage_fnc_verifyChain;
 *
 * Public: No
 */

params [["_holder", objNull, [objNull, ""]], ["_root", objNull, [objNull]]];

// A holder that is no object: its type knows (aio_compat_efak for kits).
if (_holder isEqualType "") exitWith {
    private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];
    private _code = _type get "verify";

    if (isNil "_code") exitWith {false};

    private _lies = [_holder, _root] call _code;

    !isNil "_lies" && {_lies isEqualTo true}
};

if (isNull _holder || {isNull _root}) exitWith {false};

// Where to start: a unit's own three containers, anything else is a container itself. Each is the
// outermost container of what lies in it.
private _starts = [_root];

if (_root isKindOf "CAManBase") then {
    _starts = [uniformContainer _root, vestContainer _root, backpackContainer _root] select {!isNull _x};

    {
        _x setVariable [QGVAR(owner), _root];
    } forEach _starts;
};

// A crate, vehicle, pile or body that is its own root, or one of a unit's three.
private _found = _holder isEqualTo _root || {_holder in _starts};

// The authority walks everything under an outermost container with copies to bring the objects up to
// them - once a frame each: within a frame only this machine's own writes change them, and those keep
// objects and copies alike. Anyone else walks only until it found the holder.
private _adoptTops = [];

if (isMultiplayer && {local _root}) then {
    {
        if ((_x getVariable [QGVAR(adoptedAt), -1]) != diag_frameNo) then {
            private _copies = _x getVariable [QGVAR(nested), []];

            if (_copies isEqualType [] && {_copies isNotEqualTo []}) then {
                _adoptTops pushBack _x;
            };

            _x setVariable [QGVAR(adoptedAt), diag_frameNo];
        };
    } forEach _starts;
};

private _adopt = _adoptTops isNotEqualTo [];

if (_found && {!_adopt}) exitWith {true};

private _level = _starts apply {[_x, _x]};      // [container, its outermost container]

for "_depth" from 1 to 3 do {
    private _next = [];

    {
        _x params ["_parent", "_top"];

        private _copies = [];

        if (_top in _adoptTops) then {
            _copies = _top getVariable [QGVAR(nested), []];
        };

        {
            _x params ["_class", "_object"];

            _object setVariable [QGVAR(itemClass), _class];
            _object setVariable [QGVAR(parent), _parent];
            _next pushBack [_object, _top];

            if (_copies isNotEqualTo []) then {
                private _netId = netId _object;
                private _index = _copies findIf {_x isEqualTypeArray ["", "", "", []] && {(_x select 0) isEqualTo _netId}};

                if (_index >= 0) then {
                    (_copies select _index) params ["", "_uid", "", "_places"];

                    private _tag = _object getVariable [QGVAR(tag), []];
                    private _ownUid = if (_tag isEqualType []) then {_tag param [0, ""]} else {""};

                    if !(_ownUid isEqualType "") then {_ownUid = ""};

                    if (_ownUid isEqualTo "" && {_uid isNotEqualTo ""}) then {
                        _object setVariable [QGVAR(tag), [_uid, _class, _parent]];
                        _ownUid = _uid;
                    };

                    if (_ownUid isEqualTo _uid && {_places isEqualTypeArray [0, []]}) then {
                        private _own = _object getVariable [QGVAR(places), [0, []]];

                        if (!(_own isEqualTypeArray [0, []]) || {(_places select 0) > (_own select 0)}) then {
                            _object setVariable [QGVAR(places), +_places];
                        };
                    };
                };
            };
        } forEach (everyContainer _parent);
    } forEach _level;

    if (!_found && {(_next findIf {(_x select 0) isEqualTo _holder}) >= 0}) then {
        _found = true;
    };

    if (_next isEqualTo [] || {_found && {!_adopt}}) exitWith {};

    _level = _next;
};

_found
