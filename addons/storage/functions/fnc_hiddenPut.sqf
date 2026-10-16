#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a payload into the hidden holder of the unit whose container this is, instead of into the container's
 * cargo (fnc_addPayload, when fnc_hiddenRoute says so): a magazine payload one entry per rounds, an item
 * payload by class and count. The container the things would have gone into is noted with the list
 * (fnc_hiddenLists), so fnc_opStrict can tell later whether that container is still the one worn. Written
 * back public at once (fnc_hiddenWrite).
 *
 * Only "magazine" and "item" payloads without contents of their own can live in the holder - the kinds a
 * setting ever limits (USE_ITEM_KINDS) are all of these. Anything else is handed back whole.
 *
 * Arguments:
 * 0: Container - one of the unit's uniform, vest or backpack <OBJECT>
 * 1: Payload <ARRAY>
 *
 * Return Value:
 * What did not go in - [] when all of it did, the payload itself when it cannot live here <ARRAY>
 *
 * Example:
 * [backpackContainer player, ["item", "ACE_fieldDressing", 3, []]] call einv_storage_fnc_hiddenPut;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]], ["_payload", [], [[]]]];

if (_payload isEqualTo []) exitWith {[]};
if (isNull _container) exitWith {_payload};

_payload params [["_type", "", [""]], ["_class", "", [""]]];

if (!(_type in ["magazine", "item"]) || {_class isEqualTo ""}) exitWith {_payload};
if (_type isEqualTo "item" && {(_payload param [3, []]) isNotEqualTo []}) exitWith {_payload};

([_container] call FUNC(getOwner)) params ["_unit", "_kindName"];

if (isNull _unit || {_kindName isEqualTo ""}) exitWith {_payload};

private _index = USE_KINDS find _kindName;
private _data = [_unit] call FUNC(hiddenLists);
private _list = (_data select 0) select _index;

if (_type isEqualTo "magazine") then {
    {
        [_list, _class, 1, [_class, _x] call FUNC(hiddenAmmo)] call FUNC(hiddenAdd);
    } forEach (_payload param [2, []]);
} else {
    [_list, _class, _payload param [2, 1], -1] call FUNC(hiddenAdd);
};

(_data select 1) set [_index, _container];

[_unit, _data] call FUNC(hiddenWrite);

[]
