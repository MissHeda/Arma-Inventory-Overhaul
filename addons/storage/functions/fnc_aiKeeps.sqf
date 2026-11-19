#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit is an AI whose surplus is kept (setting aio_storage_aiKeepSurplus, on by default): what lies on no
 * cell of its uniform, vest or backpack goes to any other of its containers with room - both ways (fnc_opMigrate,
 * "wide") - and what fits none stays in its inventory. Nothing is dropped, staged or removed for it, also not by ACE
 * Arsenal (aio_arsenal_fnc_onClosed, fnc_confirmClose, fnc_stageOverflow, fnc_reconcile). A player's unit never is.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Its surplus is kept <BOOL>
 *
 * Example:
 * [_unit] call aio_storage_fnc_aiKeeps;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

!isNull _unit && {_unit isKindOf "CAManBase"} && {!isPlayer _unit} && {missionNamespace getVariable [QGVAR(aiKeepSurplus), true]}
