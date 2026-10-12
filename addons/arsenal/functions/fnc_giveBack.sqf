#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes something from the soldier and returns it to the arsenal: a tile or the item in a slot, with a
 * weapon's parts and loaded magazines and a container's contents. What this arsenal does not offer is only
 * destroyed after the second click (fnc_arm). Removed with the count checked (the record of a whole tile
 * first, then einv_storage_fnc_removeEntry or fnc_takeOff), ACE's cargo event raised for each item that
 * leaves the uniform, vest or backpack, kit ids freed, the sound played and the hint written. Also what the
 * inventory's "ground" hook calls: nothing of an Arsenal session ever goes to the ground.
 *
 * The source is [grid index, tile index] (a tile of the window), [unit, slot] (the item in a slot) or
 * [container, entry] (a tile found by the caller, as einv_storage_fnc_getContents gives it, placed by
 * einv_storage_fnc_getLayout). A tile in an open kit's window comes out of the kit
 * (einv_compat_efak_fnc_onGivenBack) when the kit's arsenal setting lets the arsenal take things out of it
 * (take out only or everything); otherwise the kit "cannot be changed in the arsenal".
 *
 * Quiet is for a caller that checked what is unique itself and says what happened itself: no question, no
 * sound, no hint, no event, no look at the window.
 *
 * Arguments:
 * 0: Where it is: [grid index, tile index], [unit, slot] or [container, entry] <ARRAY>
 * 1: How many of a stack, -1 for all <NUMBER> (default: -1)
 * 2: Quiet <BOOL> (default: false)
 *
 * Return Value:
 * Given back <BOOL>
 *
 * Example:
 * [[0, 3]] call einv_arsenal_fnc_giveBack;
 *
 * Public: No
 */

params [["_source", [], [[]]], ["_count", -1, [0]], ["_quiet", false, [false]]];

private _unit = GVAR(center);

if (isNull _unit || {count _source < 2}) exitWith {false};

private _container = objNull;
private _entry = createHashMap;
private _slot = "";
private _kit = "";

// ----- What it is -----
switch (true) do {
    case ((_source select 0) isEqualType 0): {
        private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_source select 0, createHashMap];

        _entry = (_grid getOrDefault ["tiles", []]) param [_source select 1, createHashMap];

        _kit = _grid getOrDefault ["kit", ""];

        if (_kit isNotEqualTo "") then {
            // A kit's window: what the kit's setting for the arsenal allows.
            if (isNil QEFUNC(compat_efak,arsenalEditing) || {([_kit] call EFUNC(compat_efak,arsenalEditing)) < EDIT_REMOVE}) then {
                [LLSTRING(Hint_KitLocked)] call EFUNC(gui,flashHint);
                _entry = createHashMap;
            };
        } else {
            if (_grid getOrDefault ["virtual", true]) then {
                _entry = createHashMap;
            } else {
                _container = _grid getOrDefault ["container", objNull];
            };
        };
    };
    case ((_source select 1) isEqualType createHashMap): {
        _container = _source select 0;
        _entry = _source select 1;
    };
    default {
        _slot = _source select 1;
        _entry = [_source select 0, _slot] call EFUNC(storage,getSlot);
    };
};

if (count _entry == 0 || {_slot isEqualTo "" && {isNull _container} && {_kit isEqualTo ""}} || {_entry getOrDefault ["pending", false]}) exitWith {false};

private _class = _entry getOrDefault ["class", ""];
private _name = [_class] call EFUNC(gui,itemName);

// ----- Something this arsenal does not have asks for a second click -----
if (!_quiet && {[_entry] call FUNC(isUnique)}) then {
    private _text = if ([_class] call FUNC(isUnique)) then {
        format [LLSTRING(Hint_ConfirmUnique), _name]
    } else {
        format [LLSTRING(Hint_ConfirmContents), _name]
    };

    if !([format ["give|%1|%2|%3|%4|%5", _class, _slot, _entry getOrDefault ["col", -1], _entry getOrDefault ["row", -1], _kit], _text] call FUNC(arm)) then {
        _class = "";
    };
};

if (_class isEqualTo "") exitWith {false};

// ----- Out of the soldier -----
private _payload = [];
private _whole = true;
private _failure = "Failed";
private _stack = _entry getOrDefault ["count", 1];

_whole = _count < 1 || {_count >= _stack};

if (_slot isNotEqualTo "") then {
    _payload = [_source select 0, _slot] call EFUNC(storage,takeOff);
} else {
    if (_kit isNotEqualTo "") then {
        // Out of the kit, which the kit's own mod keeps: the tile's record goes with it, and an emptied kit
        // that is set to go goes too.
        ([_kit, _entry, [_count, -1] select _whole, _unit] call EFUNC(compat_efak,onGivenBack)) params ["_status", "_out"];

        if (_status isEqualTo "") then {
            _payload = _out;
        } else {
            _failure = [_status, LLSTRING(Hint_KitLocked)] select (_status isEqualTo "ReadOnly");
        };
    } else {
        // The record of a whole tile goes first: left in, the tiles after it would take the record before theirs.
        if (_whole) then {
            [_container, _entry, []] call EFUNC(storage,setPlace);
        };

        _payload = [_container, _entry, [_count, -1] select _whole] call EFUNC(storage,removeEntry);
    };
};

if (_payload isEqualTo []) exitWith {
    if (!_quiet) then {
        [_failure] call EFUNC(gui,flashHint);
    };

    false
};

// What really left.
private _given = switch (_payload select 0) do {
    case "magazine": {count (_payload param [2, [], [[]]])};
    case "item": {_payload param [2, 1, [0]]};
    default {1};
};

// A kit that left frees its id, the kits packed in a container that left with it.
[[_payload]] call FUNC(freeKits);

if (_quiet) exitWith {true};

// The cargo event, for each item of the uniform, vest and backpack: a weapon with its parts.
if (!isNull _container && {_container in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]}) then {
    [_class, -1, _given] call FUNC(aceCargoEvent);

    {
        private _part = if (_x isEqualType []) then {_x param [0, ""]} else {_x};

        if (_part isEqualType "" && {_part isNotEqualTo ""}) then {
            [_part, -1, 1] call FUNC(aceCargoEvent);
        };
    } forEach ((_entry getOrDefault ["attachments", []]) select [1]);
};

["giveBack", _class] call EFUNC(gui,playSound);

[format [LLSTRING(Hint_GivenBack), [_name, format ["%1× %2", _given, _name]] select (_given > 1)]] call FUNC(message);

call EFUNC(gui,requestRebuild);

true
