#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What a unit stands on, for the sounds that follow the ground (a grenade landing, a hand on the
 * surface): one of "dirt", "grass", "gravel", "sand", "hard", "water", "wood", "metal" or "indoor". Read
 * again after SURFACE_CACHE seconds, or when the unit moved more than a metre.
 *
 *   1. water, when the feet are less than 0.4 m above it
 *   2. an object under the feet (a floor, a roof, a bridge): "metal" when it is a vehicle, else "indoor"
 *   3. the terrain's surface (CfgSurfaces soundEnviron): water, grass, sand and beach, gravel, rock and
 *      stone, concrete, tarmac, asphalt, road, tiles, pavement and interiors as hard, wood, metal - else dirt
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * The surface <STRING>
 *
 * Example:
 * [player] call aio_gui_fnc_groundSurface;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {"dirt"};

private _now = diag_tickTime;
private _place = getPosASL _unit;

GVAR(surfaceCache) params [["_at", -1e9, [0]], ["_where", [0, 0, 0], [[]]], ["_cached", "", [""]]];

if (_cached isNotEqualTo "" && {_now - _at < SURFACE_CACHE} && {(_place distance _where) < 1}) exitWith {_cached};

private _surface = "dirt";

call {
    // Standing in shallow water.
    if (surfaceIsWater _place && {((getPosASLW _unit) select 2) < 0.4}) exitWith {
        _surface = "water";
    };

    // Something solid under the feet that is no terrain.
    private _hit = lineIntersectsSurfaces [_place vectorAdd [0, 0, 0.5], _place vectorAdd [0, 0, -0.3], _unit, objNull, true, 1, "GEOM", "NONE"];

    if (_hit isNotEqualTo [] && {!isNull ((_hit select 0) select 2)}) exitWith {
        private _object = (_hit select 0) select 2;

        _surface = ["indoor", "metal"] select (_object isKindOf "AllVehicles" || {(((_hit select 0) param [3, objNull]) isKindOf "AllVehicles")});
    };

    // The terrain: the environment its surface sounds like.
    private _environ = toLowerANSI getText (configFile >> "CfgSurfaces" >> ((surfaceType _place) select [1]) >> "soundEnviron");

    {
        _x params ["_words", "_result"];

        if ((_words findIf {(_environ find _x) >= 0}) >= 0) exitWith {
            _surface = _result;
        };
    } forEach [
        [["water"], "water"],
        [["grass"], "grass"],
        [["sand", "beach"], "sand"],
        [["gravel", "rock", "ston"], "gravel"],
        [["concrete", "tarmac", "asphalt", "road", "tiles", "pavement", "int_"], "hard"],
        [["wood"], "wood"],
        [["metal"], "metal"]
    ];
};

GVAR(surfaceCache) = [_now, _place, _surface];

_surface
