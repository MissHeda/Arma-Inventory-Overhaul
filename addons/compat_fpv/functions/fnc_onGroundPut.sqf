#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The storage's event "aio_storage_groundPut" (fnc_opPutGround, on the machine that made the pile): a payload has been
 * laid on the ground. A drone item of Ukraine FPV Drone in it is taken out of the pile again, a moment later (the phase's
 * own bookkeeping is done by then), and the machine of the unit that dropped it is asked to deploy the drone (fnc_deploy),
 * as the mod's "Put" handler would have done. Its items are magazines, one drone for each.
 *
 * Arguments:
 * 0: Unit that dropped it <OBJECT>
 * 1: Payload that went onto the ground <ARRAY>
 * 2: Piles it went onto <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["magazine", "UA_Item_EMPTY", [1]], [_pile]] call aio_compat_fpv_fnc_onGroundPut;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_payload", [], [[]]], ["_piles", [], [[]]]];

if (isNull _unit || {(_payload param [0, ""]) isNotEqualTo "magazine"}) exitWith {};

private _class = _payload param [1, ""];

if !(_class in (missionNamespace getVariable ["UA_fpv_dronesArray_items", []])) exitWith {};

[{
    params ["_unit", "_payload", "_piles"];

    private _class = _payload param [1, ""];

    {
        private _pile = _x;

        if (!isNull _pile && {local _pile}) then {
            {
                private _rounds = _x;

                if ((magazinesAmmoCargo _pile) findIf {_x isEqualTo [_class, _rounds]} >= 0) then {
                    _pile addMagazineAmmoCargo [_class, -1, _rounds];

                    [QGVAR(deploy), [_unit, getPosATL _pile, _class], _unit] call CBA_fnc_targetEvent;
                };
            } forEach (_payload param [2, []]);

            [_pile] call EFUNC(storage,pruneScriptedPile);
        };
    } forEach _piles;
}, [_unit, _payload, _piles], 0.2] call CBA_fnc_waitAndExecute;
