#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Rolls what a piece of furniture holds, as Ravage's search does (loot_action.sqf, fn_checkLoot.sqf), into the
 * hidden box: the furniture's category (its _bldCategory, else the nearest building's), one kind of find by
 * Ravage's chances (spawnClassChance_list) - food only in a fridge or icebox (foodCtnrs) - and from Ravage's
 * lists one item, one weapon, two or three magazines or one backpack. A roll can find nothing: the box stays
 * empty.
 *
 * Arguments:
 * 0: The box <OBJECT>
 * 1: The furniture <OBJECT>
 * 2: Its model, as Ravage's scan names it <STRING>
 *
 * Return Value:
 * Something found <BOOL>
 *
 * Example:
 * [_box, cursorObject, "fridge_01_f.p3d"] call aio_compat_ravage_fnc_fill;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]], ["_object", objNull, [objNull]], ["_model", "", [""]]];

if (isNull _box || {isNil "spawnClassChance_list"} || {isNil "lootVital_list"}) exitWith {false};

private _category = _object getVariable ["_bldCategory", -1];

if (_category < 0) then {
    _category = [0, player call fnc_findNearestBldCat] select (!isNil "fnc_findNearestBldCat");
};

private _chances = spawnClassChance_list select _category;
private _type = [0, 1, 2, 3, 4] selectRandomWeighted _chances;

if (random 100 > (_chances select _type)) exitWith {false};

if (!isNil "foodCtnrs" && {_model in foodCtnrs}) then {
    _type = 5;
};

private _fnc_pick = {(_this select _category) select 1};

switch (_type) do {
    case 0: {_box addItemCargoGlobal [selectRandom (lootVital_list call _fnc_pick), 1]};
    case 1: {
        // Ravage's spread: the start of the list far more often than its end.
        private _list = lootWeapon_list call _fnc_pick;
        private _last = count _list - 1;
        _box addWeaponCargoGlobal [_list select (((floor random [_last * -1.5, _last * 0.5, _last * 1.5]) max 0) min _last), 1];
    };
    case 2: {
        private _list = lootMagazine_list call _fnc_pick;

        for "_i" from 0 to (1 + floor random 2) do {
            _box addMagazineCargoGlobal [selectRandom _list, 1];
        };
    };
    case 3: {_box addItemCargoGlobal [selectRandom (lootItem_list call _fnc_pick), 1]};
    case 4: {_box addBackpackCargoGlobal [selectRandom (lootBackpack_list call _fnc_pick), 1]};
    case 5: {_box addItemCargoGlobal [selectRandom lootFoodOnly_list, 1]};
};

true
