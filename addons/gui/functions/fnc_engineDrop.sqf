#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts an item of the player's own uniform, vest or backpack on the ground by the engine's own action
 * (DropMagazine, DropWeapon) instead of through the storage, so that the engine's "Put" event comes as in the
 * vanilla inventory - and every mod that answers it (a drone deployed from its item, ...) works without a compat
 * addon. Only when the server setting "Drop on the ground by the engine" (GVAR(enginePut)) says so: "always", or
 * "auto" while another mod has a "Put" handler of its own on the unit (fnc_hasForeignPut).
 *
 * Only for a magazine or an item (no weapon, which would lose its attachments to the engine's pick), only on
 * foot, only out of the unit's own uniform, vest or backpack - never a kit, a worn slot, another unit's gear.
 * One piece at a time: the next goes once the engine took the last (the action plays its animation). Should the
 * engine not take one within ENGINE_DROP_WAIT seconds, what is left goes through the storage as usual
 * (fnc_applyMove), so nothing stays behind that was asked to go.
 *
 * Arguments:
 * 0: Container it lies in <OBJECT>
 * 1: Tile, as the grid has it <HASHMAP>
 * 2: How many of a stack, -1 for all of it <NUMBER>
 *
 * Return Value:
 * Taken here <BOOL>
 *
 * Example:
 * [vestContainer player, _tile, -1] call aio_gui_fnc_engineDrop;
 *
 * Public: No
 */

#define ENGINE_DROP_WAIT 3

params [["_from", objNull, [objNull]], ["_tile", createHashMap, [createHashMap]], ["_count", -1, [0]]];

private _unit = GVAR(unit);
private _mode = missionNamespace getVariable [QGVAR(enginePut), "auto"];

if (_mode isEqualTo "never" || {isNull _unit} || {!local _unit} || {!alive _unit} || {vehicle _unit != _unit}) exitWith {false};
if !(_from in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]) exitWith {false};

private _class = _tile getOrDefault ["class", ""];
private _kind = ([_class] call EFUNC(items,getInfo)) getOrDefault ["kind", ""];

if (_class isEqualTo "" || {_kind in ["rifle", "handgun", "launcher", "binocular", "uniform", "vest", "backpack"]}) exitWith {false};

private _isMagazine = isClass (configFile >> "CfgMagazines" >> _class);

if (!_isMagazine && {!isClass (configFile >> "CfgWeapons" >> _class)}) exitWith {false};

if (_mode isEqualTo "auto" && {!([_unit] call FUNC(hasForeignPut))}) exitWith {false};

private _stack = _tile getOrDefault ["count", 1];
private _want = [_count min _stack, _stack] select (_count < 0);

if (_want < 1) exitWith {false};

// How many of the class the container holds now.
private _fnc_held = {
    params ["_from", "_class", "_isMagazine"];

    private _list = [itemCargo _from, magazineCargo _from] select _isMagazine;
    {_x == _class} count _list
};

// One piece onto a plain ground holder at the feet, as the vanilla inventory makes it; then wait until the
// engine took it, and go on with the next - or hand the rest to the storage.
private _fnc_step = {
    params ["_unit", "_from", "_class", "_isMagazine", "_left", "_tile", "_fnc_held", "_fnc_step"];

    if (_left < 1) exitWith {call FUNC(requestRebuild)};

    private _before = [_from, _class, _isMagazine] call _fnc_held;

    if (_before < 1 || {!alive _unit} || {vehicle _unit != _unit}) exitWith {call FUNC(requestRebuild)};

    private _holder = createVehicle ["GroundWeaponHolder", getPosATL _unit, [], 0, "CAN_COLLIDE"];

    _unit action [["DropWeapon", "DropMagazine"] select _isMagazine, _holder, _class];

    [{
        params ["_unit", "_from", "_class", "_isMagazine", "", "", "_fnc_held", "", "_before"];
        ([_from, _class, _isMagazine] call _fnc_held) < _before
    }, {
        params ["_unit", "_from", "_class", "_isMagazine", "_left", "_tile", "_fnc_held", "_fnc_step"];
        [_unit, _from, _class, _isMagazine, _left - 1, _tile, _fnc_held, _fnc_step] call _fnc_step;
    }, [_unit, _from, _class, _isMagazine, _left, _tile, _fnc_held, _fnc_step, _before], ENGINE_DROP_WAIT, {
        params ["_unit", "_from", "_class", "_isMagazine", "_left", "_tile"];

        WARNING_2("The engine did not drop %1 - %2 go through the storage.",_class,_left);

        // An empty holder of the engine's own goes by itself; the rest the usual way.
        [_from, "ground", _tile, _left, []] call FUNC(applyMove);
    }] call CBA_fnc_waitUntilAndExecute;
};

[_unit, _from, _class, _isMagazine, _want, _tile, _fnc_held, _fnc_step] call _fnc_step;

true
