#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rule for ACRE2's radio slot on every op of a transaction (aio_storage_guards), checked on the machine
 * that runs the op: taking the dummy radio off and putting anything on in its place are refused for any
 * transaction that reaches the slot, whoever sent it and whatever the window showed (fnc_isFixedSlot).
 * Settlement phases do not ask guards.
 *
 * Arguments:
 * 0: Op <STRING>
 * 1: Its arguments <ARRAY>
 * 2: Who asked <OBJECT>
 * 3: The root the phase runs on <OBJECT>
 *
 * Return Value:
 * "" when it may, "Failed" when it may not <STRING>
 *
 * Example:
 * ["takeOff", [player, "radio"], player, player] call aio_compat_acre_fnc_guard;
 *
 * Public: No
 */

params ["_op", ["_args", []], "_requester", "_root"];

if !(_op in ["takeOff", "putOn"]) exitWith {""};

if ([_args param [0, objNull], _args param [1, ""]] call FUNC(isFixedSlot)) exitWith {"Failed"};

""
