#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What comes out of a kit, as a payload the window's storage puts anywhere (aio_storage_fnc_addPayload,
 * aio_storage_fnc_putOn): magazines each with its rounds, a backpack - a CBRN bag's breathing set - as
 * a backpack, anything else as items. A kit holds only classes, so whatever comes out is empty.
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: How many <NUMBER>
 * 2: The rounds of each magazine (fnc_takeRounds) <ARRAY> (default: [])
 *
 * Return Value:
 * Payload, see aio_storage_fnc_removeEntry <ARRAY>
 *
 * Example:
 * ["ACE_painkillers", 2, [7, 10]] call aio_compat_efak_fnc_payloadFor;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_count", 1, [0]], ["_rounds", [], [[]]]];

if (isClass (configFile >> "CfgMagazines" >> _class)) exitWith {["magazine", _class, _rounds]};
if (getNumber (configFile >> "CfgVehicles" >> _class >> "isBackpack") == 1) exitWith {["backpack", _class, []]};

["item", _class, _count, []]
