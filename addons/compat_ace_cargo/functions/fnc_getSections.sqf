#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Adds the cargo sections to the loot column's list as the window builds it: under every crate or vehicle
 * the player may look into that has things loaded by ACE cargo, a section "CARGO" with a card for each
 * loaded thing (fnc_drawSection). It sits right under its vehicle, before the crates opened from it
 * (their sections name the vehicle as their parent too; einv_storage_fnc_orderSections keeps the order).
 *
 * A locked section has no container any more (einv_locks_fnc_decorate), so what lies in a vehicle that is
 * locked to the player is not listed at all. Nothing is added while ACE cargo is switched off
 * (ace_cargo_enable) or nothing is loaded. A crate opened from the cargo (fnc_toggleOpen) is shown as a
 * crate - its picture and ACE's name for it, custom name included - not as an item.
 *
 * The section carries no container, no grid and no places: "vehicle" is the holder whose cargo it shows,
 * "items" the loaded things (objects and class names, as ACE keeps them), and "drawer" the function that
 * draws it, which einv_gui_fnc_drawSection calls instead of drawing a block of its own.
 *
 * Arguments:
 * 0: Sections of the loot column <ARRAY of HASHMAPs>
 *
 * Return Value:
 * The sections, the cargo ones added <ARRAY of HASHMAPs>
 *
 * Example:
 * [_lootSections] call einv_compat_ace_cargo_fnc_getSections;
 *
 * Public: No
 */

params [["_lootSections", [], [[]]]];

if !(missionNamespace getVariable [QACEGVAR(cargo,enable), true]) exitWith {_lootSections};

private _result = [];

{
    private _section = _x;
    private _holder = _section getOrDefault ["container", objNull];

    // A crate loaded in a vehicle and opened from it: the crate's own picture and the name ACE gives it.
    if (!isNull _holder && {!isNull (_holder getVariable [QGVAR(openedFrom), objNull])}) then {
        _section set ["class", ""];
        _section set ["title", [_holder, true] call ACEFUNC(cargo,getNameItem)];
    };

    _result pushBack _section;

    // A vehicle or crate the player may look into (a locked one has no container any more) with things
    // loaded; a person's gear never has cargo.
    if (isNull _holder || {(_section getOrDefault ["id", ""]) isNotEqualTo "container"} || {_holder isKindOf "CAManBase"}) then {
        continue
    };

    private _loaded = _holder getVariable [QACEGVAR(cargo,loaded), []];

    if (_loaded isEqualTo []) then {
        continue
    };

    _result pushBack createHashMapFromArray [
        ["id", "cargo"],
        ["title", localize "STR_ACE_Cargo_openMenu"],
        ["class", ""],
        ["container", objNull],
        ["vehicle", _holder],
        ["parent", _holder],
        ["side", "loot"],
        ["items", +_loaded],
        ["drawer", QFUNC(drawSection)]
    ];
} forEach _lootSections;

_result
