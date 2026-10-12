#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a drop of a unit's lands, taken when a request is made (fnc_request, "where"): the first surface
 * under the feet - terrain, a floor, a roof - from half a metre above down to NEARBY_DZ below. Nothing
 * for a seated unit - its ground is the vehicle's cargo - or with nothing under the feet (swimming,
 * falling): a pile made in the air would be out of reach for good.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Position ASL, [] for none <ARRAY>
 *
 * Example:
 * [player] call einv_storage_fnc_groundPos;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

// Seated, "the ground" is the vehicle's cargo, as in the engine's own inventory. A pile has no physics:
// one made at a passenger's position would hang in the air.
if (isNull _unit || {!isNull objectParent _unit}) exitWith {[]};

private _feet = getPosASL _unit;

// The roadway LOD first - floors, roofs, bridges -, the geometry where an object has none. The terrain
// counts as a surface as well; water does not.
private _hits = lineIntersectsSurfaces [
    _feet vectorAdd [0, 0, 0.5],
    _feet vectorAdd [0, 0, -NEARBY_DZ],
    _unit,
    objNull,
    true,
    1,
    "ROADWAY",
    "GEOM"
];

if (_hits isEqualTo []) exitWith {[]};

(_hits select 0) select 0
