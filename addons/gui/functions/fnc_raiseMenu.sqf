#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes an open context menu again on top of the display: the same choices at the same place
 * (fnc_openMenu), the row under the mouse lit. The engine draws what is made later over what was made
 * before, and the menu is no longer the last control once anything was made on the display after it - a
 * slot's hover ring, a tile drawn again. Asked every frame (fnc_onFrame) and after the loot column's tiles
 * were drawn again (fnc_redrawTiles); it only acts when the menu's layer is no longer the last control
 * registered on the display (aio_gui_created, fnc_uiCreate), or when told to.
 *
 * Arguments:
 * 0: Make it again even when nothing was made after it <BOOL> (default: false)
 *
 * Return Value:
 * Made again <BOOL>
 *
 * Example:
 * [true] call aio_gui_fnc_raiseMenu;
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
// The name at the mouse and the tips of the menu's own buttons lie over it on purpose (fnc_raiseTooltip): made after it, they are
// no reason to make it again - that made both again every frame, and a click pressed on one control was let go on its successor.
private _tips = [
    uiNamespace getVariable [QGVAR(tooltip), controlNull], uiNamespace getVariable [QGVAR(tipShown), controlNull],
    uiNamespace getVariable [QGVAR(compare), controlNull]
];
private _last = controlNull;

for "_i" from (count _created - 1) to 0 step -1 do {
    private _ctrl = _created select _i;

    if (!isNull _ctrl && {!(_ctrl in _tips)}) exitWith {
        _last = _ctrl;
    };
};

if (!_force && {_last isEqualTo _layer}) exitWith {false};

// The sound dropdown under the speaker (fnc_openSoundMenu) is made again from the volumes as they are.
if ((GVAR(menuFor) param [0, ""]) isEqualTo "sound") exitWith {
    [_display] call FUNC(openSoundMenu);

    true
};

// The palette popover (fnc_openPaletteMenu) likewise, with the choices as they are.
if ((GVAR(menuFor) param [0, ""]) isEqualTo "palette") exitWith {
    [_display] call FUNC(openPaletteMenu);

    true
};

// And the size popover (fnc_openSizeMenu), with the sizes as they are.
if ((GVAR(menuFor) param [0, ""]) isEqualTo "size") exitWith {
    [_display] call FUNC(openSizeMenu);

    true
};

GVAR(menuState) params ["_choices", "_at"];

[_display, _choices, _at] call FUNC(openMenu);

true
