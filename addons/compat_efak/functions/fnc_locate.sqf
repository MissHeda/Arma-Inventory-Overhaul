#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a kit lies: [container, kit it is packed in] - and the container at the top of that, which a
 * kit packed in kits lies in after all. Two ways to look:
 *
 *   Without a root - the window's side: where the kit windows were last drawn found it
 *   (GVAR(holders)), else among the contents of an open kit. A kit's tile in a container the window
 *   shows comes with its holder from the caller instead (fnc_drop).
 *   With a root - the side that runs a kit op (einv_storage_fnc_execute): the real cargo under that
 *   root, nothing the window remembers - the uniform, vest and backpack of a unit (or the object
 *   itself: a crate, a vehicle, a pile), the uniforms, vests and backpacks lying in them three deep as
 *   the storage walks them (einv_storage_fnc_verifyChain), and the kits packed in kits there, as deep
 *   as kits go (KIT_MAX_DEPTH).
 *
 * Arguments:
 * 0: Kit class, any case <STRING>
 * 1: Where it lies, [container, kit] - [] to look it up; not used with a root <ARRAY> (default: [])
 * 2: Root to look under, objNull for the window's side <OBJECT> (default: objNull)
 *
 * Return Value:
 * [where it lies [container, kit], the container at the top - objNull when it is found nowhere] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_locate;
 * ["efak_ifak_7", [], _crate] call einv_compat_efak_fnc_locate;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_holder", [], [[]]], ["_root", objNull, [objNull]]];

private _key = toLowerANSI _kit;

if (_key isEqualTo "") exitWith {[[objNull, ""], objNull]};

// ----- Under a root: the real cargo -----
if (!isNull _root) exitWith {
    private _containers = if (_root isKindOf "CAManBase") then {
        [uniformContainer _root, vestContainer _root, backpackContainer _root] select {!isNull _x}
    } else {
        [_root]
    };

    // The uniforms, vests and backpacks lying in them, as deep as the storage follows them.
    private _level = +_containers;

    for "_depth" from 1 to 3 do {
        private _next = [];

        {
            _next append (((everyContainer _x) apply {_x select 1}) select {!isNull _x});
        } forEach _level;

        if (_next isEqualTo []) exitWith {};

        _containers append _next;
        _level = _next;
    };

    private _found = [];

    // Kits lying in those containers, each with the container it lies in: [kit class, container].
    private _frontier = [];

    {
        private _container = _x;
        private _classes = (getItemCargo _container) param [0, []];

        if ((_classes findIf {toLowerANSI _x isEqualTo _key}) >= 0) exitWith {
            _found = [[_container, ""], _container];
        };

        {
            if ([_x] call FUNC(isKit)) then {
                _frontier pushBack [_x, _container];
            };
        } forEach _classes;
    } forEach _containers;

    // Packed in one of those kits, or in a kit packed in one - a pass per level.
    private _unready = missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap];

    for "_depth" from 1 to KIT_MAX_DEPTH do {
        if (_found isNotEqualTo [] || {_frontier isEqualTo []}) exitWith {};

        private _next = [];

        {
            _x params ["_outer", "_top"];

            // A kit nobody has carried yet holds nothing of its own.
            if (toLowerANSI _outer in _unready) then {continue};

            private _contents = [_outer] call EFAKFUNC(core,getContents);

            if ((_contents findIf {toLowerANSI (_x select 0) isEqualTo _key}) >= 0) exitWith {
                _found = [[objNull, _outer], _top];
            };

            {
                if ([_x select 0] call FUNC(isKit)) then {
                    _next pushBack [_x select 0, _top];
                };
            } forEach _contents;
        } forEach _frontier;

        _frontier = _next;
    };

    [_found, [[objNull, ""], objNull]] select (_found isEqualTo [])
};

// ----- The window's side -----
// Where the kit windows were last drawn found a kit, else the open kit it is packed in.
private _fnc_holder = {
    params ["_class"];

    private _known = GVAR(holders) getOrDefault [toLowerANSI _class, []];

    if (_known isNotEqualTo []) exitWith {_known};

    private _index = GVAR(opened) findIf {
        (([_x] call EFAKFUNC(core,getContents)) findIf {(_x select 0) == _class}) >= 0
    };

    if (_index < 0) exitWith {[objNull, ""]};

    [objNull, GVAR(opened) select _index]
};

if (_holder isEqualTo []) then {
    _holder = [_kit] call _fnc_holder;
};

_holder params [["_where", objNull, [objNull]], ["_parent", "", [""]]];

// Packed in a kit: up to the container the outermost one lies in, as deep as kits go.
for "_i" from 1 to KIT_MAX_DEPTH do {
    if (!isNull _where || {_parent isEqualTo ""}) exitWith {};

    ([_parent] call _fnc_holder) params [["_container", objNull, [objNull]], ["_outer", "", [""]]];

    _where = _container;
    _parent = _outer;
};

[_holder, _where]
