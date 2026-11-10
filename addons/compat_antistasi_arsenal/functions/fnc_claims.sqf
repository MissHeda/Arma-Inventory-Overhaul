#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Is this opening of the vanilla Virtual Arsenal Antistasi's arsenal (JNA)? JNA's action (jn_fnc_arsenal_handleAction)
 * sets uiNamespace jn_type to "arsenal", the server sends the stock (jna_dataList) and JNA opens the vanilla arsenal with
 * its box, jna_object, as the cargo. Its other two arsenals are not claimed: the vehicle arsenal (jn_type
 * "containerArsenal", a vehicle's cargo against the stock) and Antistasi Ultimate's loadout arsenal (isLoadoutArsenal,
 * which edits a saved loadout rather than the soldier's gear).
 *
 * Arguments:
 * 0: BIS_fnc_arsenal "Open"'s arguments [full, box, unit, ...], or [] at the arsenalOpened event <ARRAY or BOOL>
 *
 * Return Value:
 * JNA's arsenal <BOOL>
 *
 * Example:
 * [[nil, jna_object, player, false]] call aio_compat_antistasi_arsenal_fnc_claims;
 *
 * Public: No
 */

params [["_args", []]];

private _box = missionNamespace getVariable ["jna_object", objNull];

if (
    isNull _box || {isNil "jna_dataList"} || {isNil "jn_fnc_arsenal_removeItem"}
    || {(uiNamespace getVariable ["jn_type", ""]) isNotEqualTo "arsenal"}
    || {uiNamespace getVariable ["isLoadoutArsenal", false]}
) exitWith {false};

// The box the vanilla arsenal is opened for: from the call, else the one it noted when it opened.
private _cargo = if (_args isEqualType [] && {count _args > 1}) then {
    _args select 1
} else {
    missionNamespace getVariable ["BIS_fnc_arsenal_cargo", objNull]
};

!isNil "_cargo" && {_cargo isEqualTo _box}
