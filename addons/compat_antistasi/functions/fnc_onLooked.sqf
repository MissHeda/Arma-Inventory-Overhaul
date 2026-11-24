#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player looked into a container through the window (aio_gui_containerOpened, aio_gui_fnc_noteLooked): Antistasi's
 * undercover check, as its InventoryOpened handler makes it for what the engine opens (core\functions\init\
 * fn_initClient, proxy\fn_onPlayerRespawn) - a box looted from the nearby column never raises that event. An undercover
 * player who looks into a dead body or an ammo box of the occupants, the invaders or the rivals loses their cover
 * when an enemy knows enough of them, else - inside a town - by the town's chance. Antistasi's numbers and globals;
 * nothing happens when one of them is missing.
 *
 * Arguments:
 * 0: The player's unit <OBJECT>
 * 1: The container <OBJECT>
 * 2: Its root - the body, crate, vehicle or pile <OBJECT>
 *
 * Return Value:
 * The cover was lost <BOOL>
 *
 * Example:
 * [player, _box, _box] call aio_compat_antistasi_fnc_onLooked;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], "", ["_root", objNull, [objNull]]];

if (isNull _unit || {isNull _root} || {!captive _unit}) exitWith {false};

private _boxes = [];

{
    private _faction = missionNamespace getVariable [_x, createHashMap];

    if (_faction isEqualType createHashMap) then {
        _boxes pushBack (_faction getOrDefault ["ammobox", ""]);
    };
} forEach ["A3A_faction_occ", "A3A_faction_inv", "A3A_faction_riv"];

if !((_root isKindOf "CAManBase" && {!alive _root}) || {(typeOf _root) in (_boxes - [""])}) exitWith {false};

if (isNil "Invaders" || {isNil "Occupants"}) exitWith {false};

private _invaders = Invaders;
private _occupants = Occupants;

private _fnc_expose = {
    [_unit, false] remoteExec ["setCaptive", 0, _unit];
    _unit setCaptive false;
    true
};

// An enemy who knows enough of them: the cover is gone.
if ((allUnits findIf {(side _x) in [_invaders, _occupants] && {(_x knowsAbout _unit) > 1.4}}) >= 0) exitWith {
    call _fnc_expose
};

// Else in a town, by its chance (Antistasi's town data, its third value).
private _cities = missionNamespace getVariable ["citiesX", []];
private _towns = missionNamespace getVariable ["A3A_townData", createHashMap];

if (_cities isEqualTo [] || {!(_towns isEqualType createHashMap)} || {isNil "A3A_fnc_sizeMarker"}) exitWith {false};

private _city = [_cities, _unit] call BIS_fnc_nearestPosition;
private _data = _towns getOrDefault [_city, []];
private _chance = _data param [2, 0];

if !(_chance isEqualType 0) exitWith {false};

if (random 100 < _chance && {(_unit distance getMarkerPos _city) < ([_city] call A3A_fnc_sizeMarker) * 1.5}) exitWith {
    call _fnc_expose
};

false
