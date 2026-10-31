#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The right click on the panel (the "menu" hook): on a tile, "Remove" takes that tile out of the container
 * (fnc_remove) and "Remove all" every one of its kind there (fnc_removeKind) - in the staging space every
 * one lying in that. On a tile of the kit's grid in Enhanced First Aid Kits' kits tab (fnc_layout) only "Remove",
 * out of the kit and away (fnc_remove).
 * Nothing on free cells or on a tile still on its way somewhere.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * Choices [[text, arguments, code], ...], [] for no menu <ARRAY>
 *
 * Example:
 * [_display] call aio_arsenal_fnc_menu;
 *
 * Public: No
 */

EGVAR(gui,hover) params [["_type", ""], ["_gridIndex", -1], ["_tileIndex", -1]];

if (_type isNotEqualTo "tile") exitWith {[]};

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
private _entry = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];

if (count _entry == 0 || {_entry getOrDefault ["pending", false]}) exitWith {[]};

private _class = _entry getOrDefault ["class", ""];

// A kit's grid has no container: its tile comes out of the kit, as when dragged out of the panel.
if ((_grid getOrDefault ["kit", ""]) isNotEqualTo "") exitWith {
    [[LLSTRING(Menu_Remove), [[_gridIndex, _tileIndex], -1, _class], {_this call FUNC(remove)}]]
};

if (isNull (_grid getOrDefault ["container", objNull])) exitWith {[]};

[
    [LLSTRING(Menu_Remove), [[_gridIndex, _tileIndex], -1, _class], {_this call FUNC(remove)}],
    [
        format [LLSTRING(Menu_RemoveAll), [_class] call EFUNC(gui,itemName)],
        [_class, [_grid get "container", objNull] select ((_grid get "container") isEqualTo ((call FUNC(selected)) select 1))],
        {_this call FUNC(removeKind)}
    ]
]
