#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ctrl+click on a card: adds one, or the amount of the setting with Shift, into the container chosen as the
 * target, else where its kind belongs - magazines and grenades to the vest first, explosives to the
 * backpack, small things to the uniform, anything bigger to the backpack. Every container needs room by
 * weight and a free spot on the grid, for every item of a count: a count spreads over containers, and the
 * window is looked at once at the end.
 *
 * What fits is worked out first (the pile that still has room, the cells that are free, the weight), so
 * nothing is added that would only land in the red row at the foot of a container.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: How many <NUMBER>
 * 2: Container to put it in, objNull to choose <OBJECT> (default: objNull)
 * 3: As many as fit, whatever the count says - no "only some fit" hint <BOOL> (default: false)
 *
 * Return Value:
 * How many were added <NUMBER>
 *
 * Example:
 * ["ACE_fieldDressing", 5] call einv_arsenal_fnc_quickAdd;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_count", 1, [0]], ["_container", objNull, [objNull]], ["_fill", false, [false]]];

private _unit = GVAR(center);

if (_class isEqualTo "" || {isNull _unit} || {_count < 1}) exitWith {0};

private _info = [_class] call EFUNC(items,getInfo);
private _kind = _info getOrDefault ["kind", ""];
private _name = [_class] call EFUNC(gui,itemName);
private _stack = (_info getOrDefault ["stack", 1]) max 1;
private _capacity = _info getOrDefault ["capacity", 0];

// ----- Where, in this order -----
private _uniform = uniformContainer _unit;
private _vest = vestContainer _unit;
private _backpack = backpackContainer _unit;
private _order = [];

if (!isNull _container) then {
    _order = [_container];
} else {
    private _put = uiNamespace getVariable [QACEGVAR(arsenal,putCache), []];
    private _cells = (_info getOrDefault ["cells", 1]);

    _order = switch (true) do {
        case (_kind in ["magazine", "grenade"] && {!(_class in _put)}): {[_vest, _uniform, _backpack]};
        case (_class in _put): {[_backpack, _vest, _uniform]};
        case (_cells <= 2): {[_uniform, _vest, _backpack]};
        default {[_backpack, _vest, _uniform]};
    };

    _order = _order select {!isNull _x};

    // The container the player clicked free cells of comes first.
    private _target = GVAR(targetContainer);

    if (!isNull _target && {_target in _order}) then {
        _order = [_target] + (_order - [_target]);
    };
};

// What a tile of it would look like in a container.
private _probe = createHashMapFromArray [
    ["class", _class], ["count", 1], ["ammo", _capacity], ["capacity", _capacity], ["attachments", []], ["container", objNull]
];

// How many of the wanted ones a container takes: by weight, then by the cells the new tiles need.
private _fnc_fits = {
    params ["_target", "_wanted"];

    private _fnc_room = {
        params ["_n"];

        private _entry = +_probe;

        _entry set ["count", _n];

        [_target, _entry] call EFUNC(storage,hasRoom)
    };

    private _byMass = _wanted;

    if !([_wanted] call _fnc_room) then {
        if !([1] call _fnc_room) then {
            _byMass = 0;
        } else {
            private _low = 1;
            private _high = _wanted;

            while {_high - _low > 1} do {
                private _mid = floor ((_low + _high) / 2);

                if ([_mid] call _fnc_room) then {
                    _low = _mid;
                } else {
                    _high = _mid;
                };
            };

            _byMass = _low;
        };
    };

    if (_byMass == 0 || {([_target] call EFUNC(storage,getBlocks)) isEqualTo []}) exitWith {_byMass};

    // Piles with room take their share without a cell; the rest needs tiles of its own.
    private _existing = [_target] call EFUNC(storage,getContents);
    private _join = 0;

    {
        if (
            toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo (toLowerANSI _class)
            && {(_x getOrDefault ["attachments", []]) isEqualTo []}
            && {(_x getOrDefault ["ammo", 0]) == _capacity}
            && {(_x getOrDefault ["count", 1]) < _stack}
        ) then {
            _join = _join + _stack - (_x getOrDefault ["count", 1]);
        };
    } forEach _existing;

    private _rest = _byMass - _join;

    if (_rest <= 0) exitWith {_byMass};

    private _tiles = ceil (_rest / _stack);
    private _probes = [];

    for "_i" from 1 to _tiles do {
        private _tile = +_probe;

        _tile set ["count", [_stack, _rest - (_tiles - 1) * _stack] select (_i == _tiles)];
        _probes pushBack _tile;
    };

    [_target, _existing + _probes, false] call EFUNC(storage,getLayout);

    private _placed = _probes select {!(_x getOrDefault ["overflow", false])};
    private _room = _join;

    {
        _room = _room + (_x get "count");
    } forEach _placed;

    _room min _byMass
};

// ----- Adding, container after container -----
private _remaining = _count;
private _added = 0;
private _used = [];

{
    if (_remaining > 0) then {
        private _fit = [_x, _remaining] call _fnc_fits;

        if (_fit > 0) then {
            private _did = [_class, _fit, _x, [], true] call FUNC(addItem);

            if (_did > 0) then {
                _added = _added + _did;
                _remaining = _remaining - _did;
                _used pushBack _x;
            };
        };
    };
} forEach _order;

if (_added == 0) exitWith {
    [format [LLSTRING(Hint_NoRoomFor), _name]] call EFUNC(gui,flashHint);

    0
};

["move", _class] call EFUNC(gui,playSound);

if (_added < _count && {!_fill}) then {
    [format [LLSTRING(Hint_OnlySome), _added, _count]] call EFUNC(gui,flashHint);
} else {
    private _what = [_name, format ["%1× %2", _added, _name]] select (_added > 1);

    if (count _used == 1) then {
        [format [LLSTRING(Hint_AddedTo), _what, [_used select 0] call EFUNC(gui,containerName)]] call FUNC(message);
    } else {
        [format [LLSTRING(Hint_Added), _what]] call FUNC(message);
    };
};

call EFUNC(gui,requestRebuild);

_added
