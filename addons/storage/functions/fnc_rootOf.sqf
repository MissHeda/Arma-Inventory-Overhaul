#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The object whose locality decides who may change a holder: the unit for a unit's uniform, vest or
 * backpack and anything lying in them, the object itself for a crate, vehicle, ground pile or body, the
 * root of what a nested container lies in - by its tag's parent (fnc_tagNested), else by the container
 * it is known to lie in - and for a holder of another type ("kit:...") that type's own answer
 * (GVAR(holderTypes) "root").
 *
 * Where a nested container lies is known from the marks every read of its parent leaves on it
 * (fnc_getContents, fnc_verifyChain: aio_storage_parent, on this machine only), from its tag, or from
 * the caller - each checked against the real cargo (everyContainer) before it counts: the engine makes
 * a new object on every move, but a backpack worn again may still carry a mark of where it lay.
 *
 * Any machine may ask; the machine that executes never trusts it (fnc_verifyChain).
 *
 * Arguments:
 * 0: Holder <OBJECT or STRING>
 * 1: Container it lies in, when known - the window's own record of where it opened it; for a holder of
 *    another type handed on to that type as its hint (a container it lies in, or a root it lay under)
 *    <OBJECT> (default: objNull)
 * 2: What to return <STRING> (default: "root")
 *    "root"   - the root
 *    "top"    - the outermost container it lies in (a crate, vehicle, pile or a unit's uniform, vest or
 *               backpack), the holder itself when it lies in none - where copies of nested tags and
 *               places are kept (aio_storage_nested, fnc_tagNested); objNull for a holder that is no
 *               object
 *    "parent" - the container it lies in, objNull when none
 *
 * Return Value:
 * Root (or what was asked for), objNull when none is known <OBJECT>
 *
 * Example:
 * [backpackContainer player] call aio_storage_fnc_rootOf;
 *
 * Public: Yes
 */

params [["_holder", objNull, [objNull, ""]], ["_parent", objNull, [objNull]], ["_want", "root", [""]]];

// A holder that is no object: its type knows (aio_compat_efak for kits), with the caller's hint - a
// machine without a window knows a kit's root only from that.
if (_holder isEqualType "") exitWith {
    if (_want isNotEqualTo "root") exitWith {objNull};

    private _type = GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap];
    private _code = _type get "root";

    if (isNil "_code") exitWith {objNull};

    private _root = [_holder, _parent] call _code;

    if (isNil "_root" || {!(_root isEqualType objNull)}) exitWith {objNull};

    _root
};

if (isNull _holder) exitWith {objNull};

// ---------------------------------------------------------------------------
// A unit's own uniform, vest or backpack: the unit. fnc_getOwner reads a mark the window leaves; the
// player's own containers are known without it - the Arsenal and Eden write them before any window
// opened.
// ---------------------------------------------------------------------------
private _owner = ([_holder] call FUNC(getOwner)) select 0;

if (isNull _owner) then {
    {
        if (!isNull _x && {_holder in [uniformContainer _x, vestContainer _x, backpackContainer _x]}) exitWith {
            _owner = _x;
            _holder setVariable [QGVAR(owner), _x];
        };
    } forEach [player, missionNamespace getVariable ["ACE_player", objNull]];
};

if (!isNull _owner) exitWith {
    switch (_want) do {
        case "top": {_holder};
        case "parent": {objNull};
        default {_owner};
    }
};

// ---------------------------------------------------------------------------
// Lying in a container: what that lies in decides. Only a parent whose cargo really lists the holder
// counts - a mark or tag can be older than the last move.
// ---------------------------------------------------------------------------
private _tag = _holder getVariable [QGVAR(tag), []];

if !(_tag isEqualType []) then {_tag = []};

private _tagParent = _tag param [2, objNull];

if !(_tagParent isEqualType objNull) then {_tagParent = objNull};

private _in = objNull;

{
    private _candidate = _x;

    if (
        _candidate isEqualType objNull && {!isNull _candidate} && {_candidate isNotEqualTo _holder}
        && {((everyContainer _candidate) findIf {(_x select 1) isEqualTo _holder}) >= 0}
    ) exitWith {
        _in = _candidate;
    };
} forEach [_holder getVariable [QGVAR(parent), objNull], _tagParent, _parent];

// Neither a unit's nor lying in anything known: a root of its own - a crate, vehicle, pile or body - or a
// unit's container nobody here can tell the unit of, whose own locality is the best answer left.
if (isNull _in) exitWith {
    if (_want isEqualTo "parent") then {objNull} else {_holder}
};

if (_want isEqualTo "parent") exitWith {_in};

// Real cargo has no loops, and the engine nests three levels at most.
[_in, objNull, _want] call FUNC(rootOf)
