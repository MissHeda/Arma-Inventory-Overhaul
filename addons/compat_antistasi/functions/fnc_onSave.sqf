#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi collects the player's own save data (its plugin event A3A_event_clientPlayerSave, on this machine): its
 * save keeps the loadout as getUnitLoadout gives it, which knows nothing of the cells nor of what Strict mode keeps
 * out of the containers. Both go along in the plugin data: where everything lies (fnc_layoutOf) and the hidden
 * holder's lists (aio_storage_fnc_hiddenLists) - those only while the player is alive and not unconscious, as
 * Antistasi strips the loadout of a dead player (fnc_onLoad gives them back).
 *
 * Arguments:
 * 0: The plugin data to fill <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_data] call aio_compat_antistasi_fnc_onSave;
 *
 * Public: No
 */

params [["_data", createHashMap, [createHashMap]]];

private _unit = player;

if (isNull _unit) exitWith {};

_data set [QGVAR(layout), [_unit] call FUNC(layoutOf)];

private _hidden = [];

if (alive _unit && {!(_unit getVariable ["incapacitated", false])}) then {
    _hidden = ([_unit] call EFUNC(storage,hiddenLists)) select 0;
};

_data set [QGVAR(hidden), _hidden];
