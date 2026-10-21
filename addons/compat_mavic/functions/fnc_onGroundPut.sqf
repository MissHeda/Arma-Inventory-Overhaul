#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The storage's event "einv_storage_groundPut" (fnc_opPutGround, on the machine that made the pile): a payload
 * has been laid on the ground. A drone item of Mavic 3 (Improved) in it is taken out of the pile again, a
 * moment later (the phase's own bookkeeping is done by then), and the machine of the unit that dropped it is
 * asked to deploy the drone (fnc_deploy), as the mod's "Put" handler would have done.
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
 * [player, ["magazine", "Item_Mavic3", [100]], [_pile]] call einv_compat_mavic_fnc_onGroundPut;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_payload", [], [[]]], ["_piles", [], [[]]]];

if (isNull _unit || {isNil "Mavic_fnc_createMavicOnItemCheck"}) exitWith {};

private _class = _payload param [1, ""];

if !(_class in MAVIC_ITEMS) exitWith {};

[{
    params ["_unit", "_payload", "_piles"];

    private _class = _payload param [1, ""];

    {
        private _pile = _x;

        if (!isNull _pile && {local _pile}) then {
            if ((_payload select 0) isEqualTo "magazine") then {
                // One drone for each magazine that went down, with its own charge (rounds = fuel in percent).
                {
                    private _rounds = _x;

                    if ((magazinesAmmoCargo _pile) findIf {_x isEqualTo [_class, _rounds]} >= 0) then {
                        _pile addMagazineAmmoCargo [_class, -1, _rounds];

                        [QGVAR(deploy), [_unit, getPosATL _pile, _class, _rounds], _unit] call CBA_fnc_targetEvent;
                    };
                } forEach (_payload param [2, []]);
            } else {
                if ((itemCargo _pile) findIf {_x == _class} >= 0) then {
                    _pile addItemCargoGlobal [_class, -1];

                    [QGVAR(deploy), [_unit, getPosATL _pile, _class, 100], _unit] call CBA_fnc_targetEvent;
                };
            };

            [_pile] call EFUNC(storage,pruneScriptedPile);
        };
    } forEach _piles;
}, [_unit, _payload, _piles], 0.2] call CBA_fnc_waitAndExecute;
