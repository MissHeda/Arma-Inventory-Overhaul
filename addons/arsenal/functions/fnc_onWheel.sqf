#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mouse wheel over the panel while nothing is dragged (the "wheel" hook). Plain, it is the panel's
 * scroll, as ever. With Ctrl held over a tile it is ACE's arrows for that tile's class: turned up one more
 * of it goes into the same container where there is room (fnc_addTo), turned down one comes out of that
 * tile (fnc_remove). One more only of what the arsenal has (ace_arsenal_virtualItemsFlat, as ACE's own
 * "+" asks), and only into the open container or the staging space. While a drag out of ACE's list is on,
 * the engine's own wheel sets how many (einv_gui_fnc_onMouseZ) and this is not asked.
 *
 * The column under the mouse scrolls with every turn of the wheel whatever is answered here: where it
 * stood is held for the next frames (fnc_onFrame), so the tile stays under the mouse.
 *
 * Arguments:
 * 0: Turn, more than 0 up <NUMBER>
 * 1: Mouse [x, y] <ARRAY>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [1, getMousePosition] call einv_arsenal_fnc_onWheel;
 *
 * Public: No
 */

params [["_scroll", 0, [0]], ["_mouse", getMousePosition, [[]]]];

if (!GVAR(ctrlHeld) || {_scroll == 0} || {!([_mouse] call FUNC(isOver))}) exitWith {false};

EGVAR(gui,hover) params [["_type", ""], ["_gridIndex", -1], ["_tileIndex", -1]];

if (_type isNotEqualTo "tile") exitWith {false};

private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_gridIndex, createHashMap];
private _entry = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
private _container = _grid getOrDefault ["container", objNull];
private _class = _entry getOrDefault ["class", ""];

// A tile of a kit's grid (fnc_kitSections): one more of its class goes into the kit, one out of it.
private _kit = _grid getOrDefault ["kit", ""];

if (_kit isNotEqualTo "" && {_class isNotEqualTo ""} && {!(_entry getOrDefault ["pending", false])}) exitWith {
    if (_scroll < 0) then {
        [[_gridIndex, _tileIndex], 1, _class] call FUNC(remove);
    } else {
        if (!isNil QEFUNC(compat_efak,packNew)) then {
            ([_kit, _class, 1, [], _grid getOrDefault ["root", objNull]] call EFUNC(compat_efak,packNew)) params ["_added", "_why"];

            if (_added < 1) then {
                [[_why, "Failed"] select (_why isEqualTo "")] call EFUNC(gui,flashHint);
            } else {
                ["move", _class, objNull, false] call EFUNC(gui,playSound);
                [] call FUNC(settle);
            };
        };
    };

    true
};

if (_class isEqualTo "" || {isNull _container} || {_entry getOrDefault ["pending", false]}) exitWith {false};

// Where the column stands now, kept while the wheel's own step goes by.
private _column = (uiNamespace getVariable [QEGVAR(gui,created), []]) findIf {
    !isNull _x && {ctrlType _x == 15} && {(_x getVariable [QEGVAR(gui,column), ""]) isEqualTo "storage"}
};

if (_column >= 0) then {
    GVAR(scrollHold) = [[(uiNamespace getVariable [QEGVAR(gui,created), []]) select _column] call EFUNC(gui,scrollPixels), diag_frameNo + 3];
};

if (_scroll < 0) exitWith {
    [[_gridIndex, _tileIndex], 1, _class] call FUNC(remove);
    true
};

// By name as ACE keeps it, else in any case of letters - the cargo may spell a class differently. An ACE
// without the list is not second-guessed.
private _flat = missionNamespace getVariable QACEGVAR(arsenal,virtualItemsFlat);
private _known = isNil "_flat" || {_class in _flat} || {
    private _names = if (_flat isEqualType createHashMap) then {keys _flat} else {_flat};
    (_names findIf {_x isEqualType "" && {_x == _class}}) >= 0
};

if (!_known) exitWith {
    [LLSTRING(Hint_NotInArsenal)] call EFUNC(gui,flashHint);
    true
};

[_container, _class, 1] call FUNC(addTo);

true
