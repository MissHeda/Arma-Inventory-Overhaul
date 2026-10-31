#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The context menu's choices for a kit's tile (aio_gui_fnc_contextMenu), wherever it lies - in a
 * container or inside another kit's window:
 *   Open <name> / Close <name> - in a window of its own (fnc_toggle). A kit that may not open is
 *                                greyed out, with the reason as its tooltip (fnc_canOpen).
 *   Unpack everything          - into the player's own gear, as far as there is room (fnc_unpackAll);
 *                                only for a kit with something in it, and not in a living person's
 *                                gear the player may only look at (fnc_checkTouch).
 *
 * Arguments:
 * 0: Grid index <NUMBER>
 * 1: Tile index <NUMBER>
 *
 * Return Value:
 * Choices for aio_gui_fnc_openMenu, [] for a tile that is no kit <ARRAY>
 *
 * Example:
 * [1, 4] call aio_compat_efak_fnc_menuChoices;
 *
 * Public: No
 */

params ["_gridIndex", "_tileIndex"];

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _class = _tile getOrDefault ["class", ""];

if (
    count _tile == 0 || {_tile getOrDefault ["hidden", false]} || {_grid getOrDefault ["virtual", true]}
    || {!([_class] call FUNC(isKit))}
) exitWith {[]};

private _container = _grid getOrDefault ["container", objNull];
private _parent = _grid getOrDefault ["kit", ""];
private _name = [_class] call EFUNC(gui,itemName);
private _isOpen = (GVAR(opened) findIf {_x == _class}) >= 0;
private _choices = [];

([_class, _container] call FUNC(canOpen)) params ["_ok", "_why"];

private _enabled = _isOpen || _ok;

_choices pushBack [
    format [[LELSTRING(gui,Menu_OpenContainer), LELSTRING(gui,Menu_CloseContainer)] select _isOpen, _name],
    [_gridIndex, _tileIndex],
    {_this call FUNC(toggle)},
    createHashMapFromArray [["enabled", _enabled], ["tooltip", ["", _why] select !_enabled]]
];

// Unpacking changes the kit - not in a living person's gear the player may only look at
// (fnc_checkTouch), like every choice there that would change it.
if (
    _ok
    && {missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true]}
    && {([_class] call EFAKFUNC(core,getContents)) isNotEqualTo []}
    && {([_class, [_container, _parent]] call FUNC(checkTouch)) isEqualTo ""}
) then {
    _choices pushBack [
        localize "STR_efak_core_Action_UnpackAll",
        [_class, [_container, _parent]],
        {_this call FUNC(unpackAll)}
    ];
};

_choices
