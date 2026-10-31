#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The lowercase classes the hidden holder keeps for a container (Strict mode), each once - what a reader of
 * getItemCargo must add to see the merged view fnc_getContents shows (einv_compat_efak finding a kit by the
 * container it lies in). [] for a container that is not one of a unit's uniform, vest or backpack, or whose
 * unit has no holder.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Lowercase classes <ARRAY of STRING>
 *
 * Example:
 * [backpackContainer player] call einv_storage_fnc_hiddenClasses;
 *
 * Public: Yes
 */

params [["_container", objNull, [objNull]]];

keys ([_container] call FUNC(hiddenCounts))
