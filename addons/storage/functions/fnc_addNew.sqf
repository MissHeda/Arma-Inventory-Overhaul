#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts something that did not exist before into a container - what ACE Arsenal's grid panel puts in
 * when the engine refused ACE's own add by weight - and says whether it arrived. Checked first: it is
 * no backpack for a backpack (fnc_backpackIntoBackpack), and, when no cell is given, the grid has a free
 * spot (fnc_hasSpace): nothing new may land beside the grid. Counted before and after (fnc_countClass):
 * fewer than asked for arrived, and it is a failure, with one line in the RPT; what did arrive stays.
 *
 * With a cell the entry's place is written there (fnc_setPlace) - the caller has checked that the cells are
 * free. Of a class that stacks the new ones are a stack of their own there (a full stack at most, the rest
 * joins the other stacks as the cargo's total says, fnc_getContents) beside any stack of the class that
 * lies elsewhere. With no cell they join the last stack that has room, then open new ones.
 *
 * A uniform, vest or backpack comes empty, a magazine full unless its rounds are given, a weapon without
 * attachments (fnc_makePayload).
 * Runs where the container is local, as the cargo commands do - the player's own gear, a unit being
 * dressed in the editor.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Cell [col, row, compartment, width, height] - the size as it lies there, turned or not - or [] for
 *    wherever the layout finds a spot <ARRAY> (default: [])
 * 4: Rounds in each magazine, -1 for full ones; not read for anything but a magazine <NUMBER> (default: -1)
 *
 * Return Value:
 * "" it is there; "NoBackpack" a backpack for a backpack; "NoRoom" no free spot on the grid; "Failed" not
 * all of it arrived <STRING>
 *
 * Example:
 * [vestContainer player, "ACE_fieldDressing", 5] call aio_storage_fnc_addNew;
 *
 * Public: Yes
 */

params [["_container", objNull, [objNull]], ["_class", "", [""]], ["_count", 1, [0]], ["_cell", [], [[]]], ["_rounds", -1, [0]]];

if (isNull _container || {_class isEqualTo ""}) exitWith {"Failed"};

_count = _count max 1;

private _info = [_class] call EFUNC(items,getInfo);
private _capacity = _info getOrDefault ["capacity", 0];

// What it will be, as a tile of the container would see it: a magazine full, or with the rounds asked for.
private _ammo = [_capacity, (_rounds min _capacity) max 0] select (_rounds >= 0 && {_capacity > 0});
private _probe = createHashMapFromArray [
    ["class", _class], ["count", _count], ["ammo", _ammo], ["capacity", _capacity],
    ["attachments", []], ["container", objNull]
];

if ([_container, _probe] call FUNC(backpackIntoBackpack)) exitWith {"NoBackpack"};

if (_cell isEqualTo [] && {!([_container, _probe] call FUNC(hasSpace))}) exitWith {"NoRoom"};

// A weapon and a backpack are one thing each, whatever the count; the rest goes in as one payload.
private _payloads = if ((_info getOrDefault ["kind", ""]) in ["rifle", "handgun", "launcher", "binocular", "backpack"]) then {
    private _each = [];

    for "_i" from 1 to _count do {
        _each pushBack ([_class, 1, _rounds] call FUNC(makePayload));
    };

    _each
} else {
    [[_class, _count, _rounds] call FUNC(makePayload)]
};

private _before = [_container, _class] call FUNC(countClass);

{
    [_container, _x] call FUNC(addPayload);
} forEach _payloads;

private _arrived = ([_container, _class] call FUNC(countClass)) - _before;

if (_arrived < _count) exitWith {
    WARNING_4("Only %1 of %2 %3 arrived in %4.",_arrived,_count,_class,typeOf _container);
    "Failed"
};

if (_cell isNotEqualTo []) then {
    [_container, _probe, _cell, true] call FUNC(setPlace);
};

""
