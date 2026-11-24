#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes back where a unit's things lay (fnc_layoutOf) after Antistasi took the gear apart and added it again: the
 * records go onto the uniform, vest and backpack worn now, a frame later where the unit is local
 * (aio_storage_fnc_onLoadoutPlaces), and each item finds its cell again by its kind - a magazine with other rounds too.
 * What has no record any more is laid out first-fit, and the unit's surplus is looked at (aio_storage_fnc_queueMigrate).
 * Only the places: nothing is added or taken out here, and Strict mode's hidden holder is left as it is.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Layout, as fnc_layoutOf gives it <ARRAY>
 *
 * Return Value:
 * Something was written <BOOL>
 *
 * Example:
 * [player, _layout] call aio_compat_antistasi_fnc_restorePlaces;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_layout", [], [[]]]];

if (isNull _unit || {!local _unit}) exitWith {false};

[_unit] call EFUNC(storage,queueMigrate);

if !((_layout param [0, 0]) isEqualTo 1 && {(_layout param [1, []]) isEqualType []}) exitWith {false};

[_unit, _layout select 1] call EFUNC(storage,onLoadoutPlaces);

true
