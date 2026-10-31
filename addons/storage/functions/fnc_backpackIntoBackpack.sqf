#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an entry is a backpack and the container is a backpack too. That is the one kind rule left on
 * what a container takes besides its free cells: the engine's own inventory refuses a backpack in a
 * backpack as well, and the cargo commands would add it all the same. The ground and every other container
 * take a backpack.
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Entry <HASHMAP>
 *
 * Return Value:
 * It would be a backpack in a backpack <BOOL>
 *
 * Example:
 * [backpackContainer player, _entry] call aio_storage_fnc_backpackIntoBackpack;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]]];

if (isNull _container) exitWith {false};

(([_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo)) get "kind") isEqualTo "backpack"
&& {getNumber (configOf _container >> "isBackpack") == 1}
