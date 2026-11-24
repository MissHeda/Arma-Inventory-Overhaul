#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player's funds for the window's footer (aio_gui_footerInfo), as Antistasi writes them on the vanilla inventory:
 * HALs_money_fnc_getFunds with two decimals and the currency of the civilian faction. "" without HALs' money.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * call aio_compat_antistasi_fnc_moneyText;
 *
 * Public: No
 */

if (isNil "HALs_money_fnc_getFunds" || {isNull player}) exitWith {""};

private _funds = [player] call HALs_money_fnc_getFunds;

if (isNil "_funds" || {!(_funds isEqualType 0)}) exitWith {""};

private _symbol = "";
private _civ = missionNamespace getVariable ["A3A_faction_civ", createHashMap];

if (_civ isEqualType createHashMap) then {
    _symbol = _civ getOrDefault ["currencySymbol", ""];
};

if !(_symbol isEqualType "") then {
    _symbol = "";
};

trim format ["%1 %2", _funds toFixed 2, _symbol]
