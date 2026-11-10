#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ravage's "Search" done (fnc_patchAction): the window opens on a hidden box at the furniture looked at
 * (rvg_lootTarget), and the search of its contents is the window's own - item by item, by the server's search
 * times for crates (aio_gui_fnc_isSearched).
 *
 * Ravage's rules for a piece of furniture hold, kept in its own variables under the furniture's position, so its
 * scripts and other players see the same: the first search of the day rolls what it holds (fnc_fill; nothing is a
 * roll too), every later one that day opens the same box again - what was put into it stays. On a new day the old
 * box goes and the furniture holds something new. A box Ravage's cleanup took (loot_to_clean) is made again,
 * empty. A pile Ravage's own search left there before is opened as it is.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The box opened, or objNull <OBJECT>
 *
 * Example:
 * call aio_compat_ravage_fnc_search;
 *
 * Public: No
 */

if (isNil "rvg_lootTarget") exitWith {objNull};

rvg_lootTarget params [["_object", objNull, [objNull]], ["_model", "", [""]]];

if (isNull _object) exitWith {objNull};

private _key = str getPosASL _object;
private _day = date select 2;
private _stamp = missionNamespace getVariable ["rvgLootTimeStamp_" + _key, _day];

if (_stamp isNotEqualTo _day) then {
    private _old = missionNamespace getVariable ["foundLoot" + _key, objNull];

    if (_old isEqualType objNull && {!isNull _old} && {_old getVariable [QGVAR(box), false]}) then {
        deleteVehicle _old;
    };

    {
        missionNamespace setVariable [_x + _key, nil, true];
    } forEach ["dailyLootManager_", "rvgLootTimeStamp_", "foundLoot"];
};

private _first = isNil {missionNamespace getVariable ("dailyLootManager_" + _key)};

if (_first) then {
    missionNamespace setVariable ["dailyLootManager_" + _key, getPosASL _object, true];
    missionNamespace setVariable ["rvgLootTimeStamp_" + _key, _day, true];
};

private _box = missionNamespace getVariable ["foundLoot" + _key, objNull];

if (!(_box isEqualType objNull) || {isNull _box} || {!alive _box}) then {
    _box = [_object] call FUNC(createBox);

    if (_first) then {
        [_box, _object, _model] call FUNC(fill);
    };

    missionNamespace setVariable ["foundLoot" + _key, _box, true];
};

[player, _box, objNull] call EFUNC(gui,open);

_box
