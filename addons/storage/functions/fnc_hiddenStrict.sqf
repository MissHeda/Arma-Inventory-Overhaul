#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether one of a unit's containers keeps what may not be used from it in the unit's hidden holder (fnc_opStrict,
 * fnc_hiddenRoute, fnc_hiddenDue): its setting is Strict - or the unit is an AI, AI may not ignore the settings
 * (aio_storage_aiIgnoresUse off) and the setting limits anything at all (Only whitelisted, Nothing). An AI cannot be
 * held back by keys or padlocks, so what it may not use is kept out of its cargo, where the engine would hand it over.
 * Whether the holder is in force for the unit at all is fnc_hiddenActive's.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container: "uniform", "vest" or "backpack" <STRING>
 *
 * Return Value:
 * Kept in the holder <BOOL>
 *
 * Example:
 * [_unit, "backpack"] call aio_storage_fnc_hiddenStrict;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_kind", "", [""]]];

private _mode = [_kind] call FUNC(useMode);

if (_mode isEqualTo USE_STRICT) exitWith {true};

_mode in [USE_LIST, USE_NONE]
&& {!(missionNamespace getVariable [QGVAR(aiIgnoresUse), true])}
&& {!isNull _unit}
&& {!isPlayer _unit}
