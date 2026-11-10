#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Watches a pile Ravage's search made until it is filled, then makes sure the window shows it. Ravage fills the
 * pile from its own InventoryOpened handler (fnc_checkLoot) and asks the engine to open it again; that second
 * asking did not always reach the window (0.7.2 report: it opened on the player's gear only). So:
 *
 *   - filled by Ravage within RAVAGE_FILL_WAIT seconds: fine
 *   - not filled by then: Ravage's own fnc_checkLoot fills it now (it also asks the engine again, as it does)
 *   - a moment later (RAVAGE_OPEN_WAIT): the window is open on the pile - done; open on something else (a guess
 *     on the player's gear) - closed and opened again on the pile; not open - opened on the pile
 *
 * One watch per pile; a pile deleted meanwhile ends it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Pile <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _pile] call aio_compat_ravage_fnc_watchPile;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_pile", objNull, [objNull]]];

if (isNull _unit || {isNull _pile} || {_pile getVariable [QGVAR(watched), false]}) exitWith {};

_pile setVariable [QGVAR(watched), true];

[{
    params ["", "_pile"];

    isNull _pile || {isNil {_pile getVariable "_uncheckedLoot"}}
}, {
    params ["_unit", "_pile"];

    [FUNC(watchOpen), [_unit, _pile], RAVAGE_OPEN_WAIT] call CBA_fnc_waitAndExecute;
}, [_unit, _pile], RAVAGE_FILL_WAIT, {
    params ["_unit", "_pile"];

    if (isNull _pile) exitWith {};

    // Ravage's handler never came: its own function fills the pile, as it would have.
    if (!isNil {_pile getVariable "_uncheckedLoot"} && {!isNil "fnc_checkLoot"}) then {
        INFO_1("Ravage did not fill %1 - filled by its own fnc_checkLoot now.",typeOf _pile);
        [_unit, _pile] call fnc_checkLoot;
    };

    [FUNC(watchOpen), [_unit, _pile], RAVAGE_OPEN_WAIT] call CBA_fnc_waitAndExecute;
}] call CBA_fnc_waitUntilAndExecute;
