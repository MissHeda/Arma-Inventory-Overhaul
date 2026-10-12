#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens a kit's tile in a floating window of its own, beside the tile, or closes that window - a double
 * click on the tile (einv_gui_fnc_onMouseButton) or Open / Close in its context menu (fnc_menuChoices).
 * Works for a kit in any grid the window shows, inside another kit's window as well. Only the kit
 * windows are drawn again (einv_gui_fnc_openWindow, einv_gui_fnc_closeWindow): nothing in the columns
 * moves.
 *
 * A double click only while Enhanced First Aid Kits' own setting for it is on, as in the vanilla
 * inventory. A kit that may not open says why (fnc_open) - and the double click is taken all the same:
 * it never moves the kit away by surprise.
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 * 2: A double click <BOOL> (default: false)
 *
 * Return Value:
 * Handled - false for anything that is no kit, which the caller handles its own way <BOOL>
 *
 * Example:
 * [1, 4, true] call einv_compat_efak_fnc_toggle;
 *
 * Public: No
 */

params ["_gridIndex", "_tileIndex", ["_doubleClick", false, [false]]];

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _class = _tile getOrDefault ["class", ""];

if (
    count _tile == 0 || {_tile getOrDefault ["hidden", false]} || {_grid getOrDefault ["virtual", true]}
    || {!([_class] call FUNC(isKit))}
) exitWith {false};

if (_doubleClick && {!(missionNamespace getVariable [QEFAKGVAR(core,doubleClickOpen), true])}) exitWith {false};

if ((GVAR(opened) findIf {_x == _class}) >= 0) exitWith {
    ["kit:" + toLowerANSI _class] call EFUNC(gui,closeWindow);
    true
};

[_class, _grid getOrDefault ["container", objNull], _grid getOrDefault ["kit", ""], [_grid, _tile] call EFUNC(gui,tileRect)] call FUNC(open);

true
