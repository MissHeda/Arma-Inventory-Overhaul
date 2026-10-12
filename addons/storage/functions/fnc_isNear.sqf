#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an object lies near a point and in sight of it: within the range from the feet, measured flat,
 * on the same floor (NEARBY_DZ) and nothing in the way from the eyes - no walls, no floors. What a drop
 * onto the ground picks is always something the player could see (fnc_getGroundHolder).
 *
 * What lies in the object is never in the way of it: a backpack on the ground is an object of its own,
 * with a shape the line of sight hits, lying right where its pile is. Counted as a wall, a pile holding a
 * backpack was out of sight - it never showed in the loot column, and a backpack dropped on the ground
 * looked as if it had vanished (Mia, 0.2.3).
 *
 * Arguments:
 * 0: Eyes, position ASL <ARRAY>
 * 1: Feet, position ASL <ARRAY>
 * 2: Object <OBJECT>
 * 3: Range, metres <NUMBER>
 * 4: Object the line of sight ignores - the player <OBJECT> (default: objNull)
 *
 * Return Value:
 * Near and in sight <BOOL>
 *
 * Example:
 * [eyePos player, getPosASL player, cursorObject, 3, player] call einv_storage_fnc_isNear;
 *
 * Public: No
 */

params [
    ["_eye", [], [[]]],
    ["_feet", [], [[]]],
    ["_object", objNull, [objNull]],
    ["_range", 0, [0]],
    ["_ignore", objNull, [objNull]]
];

if (isNull _object || {count _eye < 3} || {count _feet < 3}) exitWith {false};

private _at = getPosASL _object;

(_feet distance2D _at) <= _range
&& {abs ((_at select 2) - (_feet select 2)) <= NEARBY_DZ}
&& {
    // In sight from the eyes: nothing through walls or floors. modelToWorld rather than the visual one -
    // the server asks this too, and has no visual state. A hit on a uniform, vest or backpack lying in the
    // object, or on a part of it, is the object itself.
    private _inside = (everyContainer _object) apply {_x select 1};

    (lineIntersectsSurfaces [_eye, AGLToASL (_object modelToWorld [0, 0, 0.25]), _ignore, _object, true, 8, "GEOM", "NONE"]) findIf {
        _x params ["", "", ["_hit", objNull], ["_parent", objNull]];

        !(_hit in _inside) && {!(_parent in _inside)} && {_parent isNotEqualTo _object} && {objectParent _hit isNotEqualTo _object}
    } < 0
}
