#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whose uniform, vest or backpack a container is. The engine does not say: objectParent of a uniform's
 * container is no unit (seen in the game, 2026-10-08 - a uniform came out as a crate). So
 * fnc_getSections marks every container it hands out with its unit, on this machine, and this reads
 * the mark - with objectParent only as a second guess.
 *
 * A mark is only written anew where fnc_getSections runs, so it goes stale once the container changes
 * hands - a backpack dropped and worn by someone else is still marked with its old owner here. A mark
 * whose unit no longer wears the container counts for nothing, and objectParent - right for a worn
 * backpack - is asked as if there were none.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * [unit, "uniform" / "vest" / "backpack"], [objNull, ""] for a container of no unit <ARRAY>
 *
 * Example:
 * [uniformContainer player] call aio_storage_fnc_getOwner;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {[objNull, ""]};

private _owner = _container getVariable [QGVAR(owner), objNull];

if (isNull _owner || {!(_container in [uniformContainer _owner, vestContainer _owner, backpackContainer _owner])}) then {
    _owner = objectParent _container;
};

if (isNull _owner || {!(_owner isKindOf "CAManBase")}) exitWith {[objNull, ""]};

switch (true) do {
    case (_container isEqualTo uniformContainer _owner): {[_owner, "uniform"]};
    case (_container isEqualTo vestContainer _owner): {[_owner, "vest"]};
    case (_container isEqualTo backpackContainer _owner): {[_owner, "backpack"]};
    default {[objNull, ""]};
}
