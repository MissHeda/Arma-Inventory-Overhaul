#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * For missions: takes what a unit has in one of its equipment slots (ids as in fnc_getSlot) off and puts
 * it into a holder, as a transaction (fnc_request): "takeOff" where the unit is local, then "put" (or a
 * kit's own op) where the holder's root is - at the cell given, else the first free spot. Given no
 * holder it goes to the ground at the unit's feet ("putGround" on the server), or into the cargo of what
 * the unit sits in. Should it not fit after all, it settles like anything else that found no place. The
 * window no longer calls this.
 *
 * A backpack into a backpack (fnc_backpackIntoBackpack) and, with no cell given, a free spot
 * (fnc_hasSpace) are asked here first; the machine that runs it asks again and decides.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 * 2: Holder it goes to - a container, a kit's key, or objNull for the ground <OBJECT or STRING>
 *    (default: objNull)
 * 3: Cell [col, row, block] - with [.., w, h] when it lies turned there -, [] for the first free spot
 *    <ARRAY> (default: [])
 *
 * Return Value:
 * "" when it was taken off and put there here and then, "Requested" when it went to the server and is
 * done shortly, else why not ("NoBackpack", "NoRoom", "IntoItself", "NoGround", "Gone", "OutOfReach",
 * "Moved", "NotReady", "Bounced" - it went somewhere else -, "Failed") <STRING>
 *
 * Example:
 * [player, "headgear", backpackContainer player] call einv_storage_fnc_unequip;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_slotId", "", [""]],
    ["_to", objNull, [objNull, ""]],
    ["_cell", [], [[]]]
];

if (isNull _unit) exitWith {"Failed"};

private _entry = [_unit, _slotId] call FUNC(getSlot);

if (count _entry == 0) exitWith {"Failed"};

private _vehicle = objectParent _unit;
private _ground = _to isEqualType objNull && {isNull _to};
private _container = _to isEqualType objNull && {!isNull _to};
private _inside = _entry getOrDefault ["container", objNull];

// Nothing under the feet - swimming, falling: a pile made there would be out of reach for good.
if (_ground && {isNull _vehicle} && {([_unit] call FUNC(groundPos)) isEqualTo []}) exitWith {"NoGround"};

// A uniform, vest or backpack never goes into itself, or into anything lying in it.
if (_container && {!isNull _inside} && {[_to, _inside] call FUNC(liesIn)}) exitWith {"IntoItself"};

// A backpack never goes into a backpack.
if (_container && {[_to, _entry] call FUNC(backpackIntoBackpack)}) exitWith {"NoBackpack"};

// Nothing may land beside the grid: with no cell given it needs a free spot.
if (_container && {_cell isEqualTo []} && {!([_to, _entry] call FUNC(hasSpace))}) exitWith {"NoRoom"};

private _takeOff = ["takeOff", [_unit, _slotId]];
private _ref = ["#ref", 0, 0, 0];
private _phases = [];

if (_ground) then {
    // Seated, the cargo of what the unit sits in, as in the engine's own inventory; on foot the surface
    // under the feet.
    _phases = if (isNull _vehicle) then {
        [[_unit, [_takeOff]], [objNull, [["putGround", [_ref]]]]]
    } else {
        [[_unit, [_takeOff]], [_vehicle, [["put", [_vehicle, _ref, [], false]]]]]
    };
} else {
    private _toRoot = [_to] call FUNC(rootOf);
    private _put = if (_to isEqualType "") then {
        (GVAR(holderTypes) getOrDefault [(_to splitString ":") param [0, ""], createHashMap]) getOrDefault ["put", ""]
    } else {
        "put"
    };

    if (!isNull _toRoot && {_put isNotEqualTo ""}) then {
        private _putOp = [_put, [[_to, _ref, _cell, false], [_to, _ref, _cell]] select (_to isEqualType "")];

        // One root: one phase. Else the item travels from the unit's machine to the holder's.
        _phases = if (_toRoot isEqualTo _unit) then {
            [[_unit, [_takeOff, _putOp]]]
        } else {
            [[_unit, [_takeOff]], [_toRoot, [_putOp]]]
        };
    };
};

if (_phases isEqualTo []) exitWith {"Failed"};

// Answered here and now when every phase ran here; else the server's hub answers later.
private _answers = [];
private _id = [_phases, {(_this select 3) pushBack (_this select 1)}, _answers, false, _unit] call FUNC(request);

if (_id isEqualTo "") exitWith {"Failed"};
if (_answers isEqualTo []) exitWith {"Requested"};

private _status = "";

{
    {
        if ((_x param [0, ""]) isNotEqualTo "") exitWith {
            _status = _x select 0;
        };
    } forEach _x;

    if (_status isNotEqualTo "") exitWith {};
} forEach ((_answers select 0) param [0, []]);

_status
