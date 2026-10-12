#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A unit's own storage as sections for the window, top to bottom: uniform, vest, backpack - only those
 * it has. Works for a body just the same.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Sections <ARRAY of HASHMAPs>
 *   "id"        - "uniform", "vest" or "backpack" <STRING>
 *   "title"     - the uniform's, vest's or backpack's name <STRING>
 *   "class"     - its class, for the picture on the header <STRING>
 *   "container" - its container object <OBJECT>
 *   "maxLoad"   - what it can hold (fnc_getMaxLoad) <NUMBER>
 *
 * Example:
 * [player] call einv_storage_fnc_getSections;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _sections = [];

{
    _x params ["_id", "_class", "_container"];

    // A uniform without its container object cannot be looked into, and would read as "no limit".
    if (_class isNotEqualTo "" && {!isNull _container}) then {
        // The engine cannot tell whose it is (fnc_getOwner).
        _container setVariable [QGVAR(owner), _unit];

        _sections pushBack createHashMapFromArray [
            ["id", _id],
            ["title", ([_class] call EFUNC(items,getInfo)) get "name"],
            ["class", _class],
            ["container", _container],
            ["maxLoad", [_container] call FUNC(getMaxLoad)]
        ];
    };
} forEach [
    ["uniform", uniform _unit, uniformContainer _unit],
    ["vest", vest _unit, vestContainer _unit],
    ["backpack", backpack _unit, backpackContainer _unit]
];

_sections
