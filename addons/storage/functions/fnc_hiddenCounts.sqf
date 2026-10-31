#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of each class the hidden holder keeps for a container (Strict mode): lowercase class -> count,
 * magazines of every rounds added up. Empty for a container that is not one of a unit's uniform, vest or
 * backpack, or whose unit has no holder. For whoever counts a container's cargo by hand (fnc_countClass,
 * the Arsenal panel's aio_arsenal_fnc_countAll) and must see the merged view fnc_getContents shows.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Lowercase class -> count <HASHMAP>
 *
 * Example:
 * [backpackContainer player] call aio_storage_fnc_hiddenCounts;
 *
 * Public: Yes
 */

params [["_container", objNull, [objNull]]];

private _counts = createHashMap;

if (isNull _container) exitWith {_counts};

([_container] call FUNC(getOwner)) params ["_unit", "_kindName"];

if (isNull _unit || {_kindName isEqualTo ""} || {isNil {_unit getVariable QGVAR(hidden)}}) exitWith {_counts};

{
    _x params ["_class", "_count"];

    private _key = toLowerANSI _class;

    _counts set [_key, (_counts getOrDefault [_key, 0]) + _count];
} forEach ((([_unit] call FUNC(hiddenLists)) select 0) select (USE_KINDS find _kindName));

_counts
