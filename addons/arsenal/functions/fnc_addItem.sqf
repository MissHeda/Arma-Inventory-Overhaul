#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates what a card stands for on a free cell of one of the soldier's containers - as many as the drag
 * carried - and flashes where it landed. A pile of the same class already there is joined.
 *
 * With no cell the container's layout finds a spot, as for a quick add; a pile that still has room is
 * joined even when no cell is free. Raises ACE's cargo event for each item that went into the uniform, vest
 * or backpack, notes where it landed for the flash after the next build (GVAR(pendingFlash), entries
 * [container, lower case class, row, col, cells, compartment] as einv_gui_fnc_flashTile takes them), says
 * what happened and asks for the window to be looked at again.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: How many <NUMBER>
 * 2: Container <OBJECT>
 * 3: Cell [col, row, compartment, width, height], [] for wherever there is room <ARRAY> (default: [])
 * 4: Quiet - no sound, no hint, no look at the window; the caller does that once <BOOL> (default: false)
 *
 * Return Value:
 * How many were added <NUMBER>
 *
 * Example:
 * ["ACE_fieldDressing", 3, uniformContainer player, [0, 0, 0, 1, 1]] call einv_arsenal_fnc_addItem;
 *
 * Public: No
 */

params [
    ["_class", "", [""]], ["_count", 1, [0]], ["_container", objNull, [objNull]], ["_cell", [], [[]]], ["_quiet", false, [false]]
];

if (_class isEqualTo "" || {isNull _container} || {_count < 1}) exitWith {0};

private _name = [_class] call EFUNC(gui,itemName);
private _before = [_container, _class] call EFUNC(storage,countClass);
private _result = [_container, _class, _count, _cell] call EFUNC(storage,addNew);

// No free cell, but a pile of the class with room joins: it is put where that pile lies.
if (_result isEqualTo "NoRoom" && {_cell isEqualTo []}) then {
    private _info = [_class] call EFUNC(items,getInfo);
    private _stack = _info getOrDefault ["stack", 1];
    private _capacity = _info getOrDefault ["capacity", 0];
    private _key = toLowerANSI _class;

    // The tiles as the window shows them, to find where the pile lies.
    private _entries = [_container] call EFUNC(storage,getContents);
    private _placed = ([_container, _entries] call EFUNC(storage,getLayout)) get "entries";

    private _pile = _placed select {
        toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key
        && {(_x getOrDefault ["attachments", []]) isEqualTo []}
        && {(_x getOrDefault ["count", 1]) < _stack}
        && {(_x getOrDefault ["ammo", 0]) == _capacity}
        && {!(_x getOrDefault ["overflow", false])}
    };

    if (_pile isNotEqualTo []) then {
        private _first = _pile select 0;

        _result = [_container, _class, _count, [_first get "col", _first get "row", _first getOrDefault ["block", 0], _first get "w", _first get "h"]] call EFUNC(storage,addNew);
    };
};

private _added = ([_container, _class] call EFUNC(storage,countClass)) - _before;

if (_added < 1) exitWith {
    if (!_quiet) then {
        private _reason = if (_result in ["NoBackpack", "NoRoom"]) then {format [LLSTRING(Hint_NoRoomFor), _name]} else {_result};

        [_reason] call EFUNC(gui,flashHint);
    };

    0
};

_added = _added min _count;

// The cargo event, for what went into the uniform, vest or backpack.
if (_container in [uniformContainer GVAR(center), vestContainer GVAR(center), backpackContainer GVAR(center)]) then {
    [_class, 1, _added] call FUNC(aceCargoEvent);
};

// Where it landed, as the layout shows it: the cell it was dropped on, else wherever the first tile of the
// class lies now.
private _row = -1;
private _col = -1;
private _block = 0;
private _cells = 1;

if (_cell isNotEqualTo []) then {
    _col = _cell select 0;
    _row = _cell select 1;
    _block = _cell param [2, 0];
    _cells = (_cell param [3, 1]) * (_cell param [4, 1]);
} else {
    private _key = toLowerANSI _class;
    private _placed = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) get "entries";
    private _index = _placed findIf {toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key && {!(_x getOrDefault ["overflow", false])}};

    if (_index >= 0) then {
        private _tile = _placed select _index;

        _col = _tile get "col";
        _row = _tile get "row";
        _block = _tile getOrDefault ["block", 0];
        _cells = (_tile get "w") * (_tile get "h");
    };
};

if (_row >= 0) then {
    GVAR(pendingFlash) pushBack [_container, toLowerANSI _class, _row, _col, _cells, _block];
};

if (!_quiet) then {
    ["move", _class] call EFUNC(gui,playSound);

    private _ownName = [_container] call EFUNC(gui,containerName);
    private _what = [_name, format ["%1× %2", _added, _name]] select (_added > 1);

    [format [LLSTRING(Hint_AddedTo), _what, _ownName]] call FUNC(message);

    call EFUNC(gui,requestRebuild);
};

_added
