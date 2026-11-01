#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The right-click menu of the player's own backpack slot with BackpackOnChest loaded (fnc_api): with a backpack and
 * a pack on the chest the two swap places, with a backpack alone it goes onto the chest, with the pack on the chest
 * alone - an empty backpack slot - it goes onto the back. Each runs that mod's own action, so what it does with the
 * cargo, the radios and the animation stays its own; the window shows the new backpack as the gear changes. On foot
 * only, as that mod's actions are. A menu entry rather than a button of its own (Mia, issue #34).
 *
 * Arguments:
 * 0: Unit whose slot it is <OBJECT>
 *
 * Return Value:
 * Menu choices, [text, arguments, code] each <ARRAY>
 *
 * Example:
 * [player] call aio_compat_boc_fnc_menuChoices;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _prefix = call FUNC(api);

if (_prefix isEqualTo "" || {isNull _unit} || {!local _unit} || {!isNull objectParent _unit}) exitWith {[]};

private _chest = [_unit] call (missionNamespace getVariable [_prefix + "_fnc_chestpack", {""}]);
private _back = backpack _unit;

if (_chest isEqualTo "" && {_back isEqualTo ""}) exitWith {[]};

private _fnc_name = {getText (configFile >> "CfgVehicles" >> _this >> "displayName")};
private _action = switch (true) do {
    case (_chest isNotEqualTo "" && {_back isNotEqualTo ""}): {["actionSwap", format [LLSTRING(Menu_Swap), _chest call _fnc_name]]};
    case (_back isNotEqualTo ""): {["actionOnChest", LLSTRING(Menu_OnChest)]};
    default {["actionOnBack", format [LLSTRING(Menu_OnBack), _chest call _fnc_name]]};
};

_action params ["_function", "_text"];

[[_text, [_unit, _prefix + "_fnc_" + _function], {
    params ["_unit", "_function"];

    [_unit] call (missionNamespace getVariable [_function, {}]);
}]]
