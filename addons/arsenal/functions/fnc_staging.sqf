#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The staging space: a scratch place for this fitting only, shown under the open container's grid
 * (fnc_layout). A full backpack is rearranged by moving things down there and back, without putting
 * them on the ground first. Made the first time the panel is drawn and deleted with whatever lies in it
 * when ACE's window closes (fnc_onClosed).
 *
 * It is a crate of the game's own, made on this machine only (createVehicleLocal), hidden and without
 * simulation at the soldier's feet - in reach, so the storage's moves accept it like any crate nearby -,
 * emptied of what the class brings along and given a grid of its own (einv_grid) and no search
 * (einv_noSearch). Nobody else ever sees it, and the storage runs its moves here (einv_storage_localOnly,
 * einv_storage_fnc_isLocalRoot). It is nothing of the soldier's: loadouts never carry it, and ACE's
 * rebuilds of the uniform, vest or backpack leave it alone.
 *
 * Arguments:
 * 0: Make it when there is none <BOOL> (default: true)
 *
 * Return Value:
 * The staging crate, objNull for none <OBJECT>
 *
 * Example:
 * [] call einv_arsenal_fnc_staging;
 *
 * Public: No
 */

params [["_make", true, [true]]];

if (!isNull GVAR(staging) || {!_make}) exitWith {GVAR(staging)};

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

// Its moves run on this machine: the soldier has to be this machine's too.
if (isNull _center || {!local _center}) exitWith {objNull};

private _holder = STAGING_CLASS createVehicleLocal [0, 0, 0];

if (isNull _holder) exitWith {objNull};

_holder hideObject true;
_holder enableSimulation false;
_holder allowDamage false;

clearItemCargo _holder;
clearMagazineCargo _holder;
clearWeaponCargo _holder;
clearBackpackCargo _holder;

_holder setPosATL (getPosATL _center);

_holder setVariable [QGVARMAIN(grid), STAGING_GRID];
_holder setVariable [QEGVAR(storage,localOnly), true];

// What the player put there himself is never searched for again (einv_gui_fnc_isSearched).
_holder setVariable [QGVARMAIN(noSearch), true];

GVAR(staging) = _holder;

_holder
