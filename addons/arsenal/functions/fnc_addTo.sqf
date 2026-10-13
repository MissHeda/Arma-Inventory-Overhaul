#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts new things of a class into the open uniform, vest or backpack or into the staging space, from
 * nothing - an item dragged out of ACE's list (fnc_onDrop), or one more with Ctrl and the wheel
 * (fnc_onWheel) - onto a given cell, turned as it was dragged, or where there is room.
 *
 * Into the soldier's container the way ACE's "+" does it, with the engine's addItemToUniform, addItemToVest
 * or addItemToBackpack, which refuse by the container's weight; what of it did not land is put in past
 * that with einv_storage_fnc_addNew, as for ACE's own adds (fnc_onCargoChanged) - cells are the only limit.
 * Into the staging space with addNew alone. The places written so far are pinned first
 * (einv_storage_fnc_normalize), so the new thing is the last of its kind and the cell's record is its own
 * (einv_storage_fnc_setPlace). ACE is told afterwards as after a removal (fnc_syncAce, fnc_tellAce) - for
 * the staging space only the panel is built again: nothing of the soldier's changed.
 *
 * Arguments:
 * 0: The open container or the staging crate <OBJECT>
 * 1: Class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Cell [col, row, compartment, width, height], [] for where there is room <ARRAY> (default: [])
 *
 * Return Value:
 * "" when it went in, else why not ("NoRoom", "NoBackpack", "Failed") <STRING>
 *
 * Example:
 * [backpackContainer player, "ACE_fieldDressing", 5, [2, 0, 0, 1, 1]] call einv_arsenal_fnc_addTo;
 *
 * Public: No
 */

disableSerialization;

params [["_to", objNull, [objNull]], ["_class", "", [""]], ["_count", 1, [0]], ["_cell", [], [[]]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

(call FUNC(selected)) params ["_id", "_open"];

if (
    isNull _to || {_class isEqualTo ""} || {_count < 1} || {isNull _center} || {!local _center}
    || {_to isNotEqualTo _open && {_to isNotEqualTo GVAR(staging)}}
) exitWith {"Failed"};

private _intoSoldier = _to isEqualTo _open;
private _capacity = ([_class] call EFUNC(items,getInfo)) getOrDefault ["capacity", 0];

// What it will be as a tile there: a magazine full, nothing on it.
private _probe = createHashMapFromArray [
    ["class", _class], ["count", _count], ["ammo", _capacity], ["capacity", _capacity],
    ["attachments", []], ["container", objNull]
];

if ([_to, _probe] call EFUNC(storage,backpackIntoBackpack)) exitWith {
    ["NoBackpack"] call EFUNC(gui,flashHint);
    "NoBackpack"
};

if (_cell isEqualTo [] && {!([_to, _probe] call EFUNC(storage,hasSpace))}) exitWith {
    if (_intoSoldier) then {
        [_display, _id, _class] call FUNC(sayNoRoom);
    } else {
        ["NoRoom"] call EFUNC(gui,flashHint);
    };

    "NoRoom"
};

[_to] call EFUNC(storage,normalize);

private _before = [_to, _class] call EFUNC(storage,countClass);
private _arrived = 0;

if (_intoSoldier) then {
    for "_i" from 1 to _count do {
        switch (_id) do {
            case "uniform": {_center addItemToUniform _class};
            case "vest": {_center addItemToVest _class};
            default {_center addItemToBackpack _class};
        };
    };

    _arrived = (([_to, _class] call EFUNC(storage,countClass)) - _before) max 0;
};

private _why = "";

// Nothing landed yet: addNew writes the cell itself. Some did: the rest goes where there is room, and
// the cell is written below for all of it.
if (_arrived < _count) then {
    _why = [_to, _class, _count - _arrived, [[], _cell] select (_arrived == 0)] call EFUNC(storage,addNew);
};

private _after = [_to, _class] call EFUNC(storage,countClass);

if (_after <= _before) exitWith {
    [[_why, "Failed"] select (_why isEqualTo "")] call EFUNC(gui,flashHint);
    [_why, "Failed"] select (_why isEqualTo "")
};

if (_arrived > 0 && {_cell isNotEqualTo []}) then {
    _probe set ["count", _after - _before];
    [_to, _probe, _cell, true] call EFUNC(storage,setPlace);
};

["move", _class, objNull, false] call EFUNC(gui,playSound);

if (_intoSoldier) then {
    // ACE's list, load bar and current items, then ACE's own event for what changed.
    [_display] call FUNC(syncAce);
    [_class, _before, _after] call FUNC(tellAce);

    if (_why isEqualTo "NoRoom") then {
        [_display, _id, _class] call FUNC(sayNoRoom);
    };
} else {
    [] call FUNC(settle);
};

_why
