#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes an open context menu again on top of the display: the same choices at the same place
 * (fnc_openMenu), the row under the mouse lit. The engine draws what is made later over what was made
 * before, and the menu is no longer the last control once anything was made on the display after it - a
 * slot's hover ring, a tile drawn again. Asked every frame (fnc_onFrame) and after the loot column's tiles
 * were drawn again (fnc_redrawTiles); it only acts when the menu's layer is no longer the last control
 * registered on the display (einv_gui_created, fnc_uiCreate), or when told to.
 *
 * Arguments:
 * 0: Make it again even when nothing was made after it <BOOL> (default: false)
 *
 * Return Value:
 * Made again <BOOL>
 *
 * Example:
 * [true] call einv_gui_fnc_raiseMenu;
 *
 * Public: No
 */

disableSerialization;

params [["_force", false, [false]]];

private _layer = (uiNamespace getVariable [QGVAR(menu), []]) param [0, controlNull];

if (GVAR(menuState) isEqualTo [] || {isNull _layer}) exitWith {false};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _created = uiNamespace getVariable [QGVAR(created), []];

if (isNull _display) exitWith {false};
if (!_force && {(_created param [(count _created - 1) max 0, controlNull]) isEqualTo _layer}) exitWith {false};

GVAR(menuState) params ["_choices", "_at"];

[_display, _choices, _at] call FUNC(openMenu);

true
