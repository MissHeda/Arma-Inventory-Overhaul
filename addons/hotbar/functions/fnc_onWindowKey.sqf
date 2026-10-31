#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A key pressed in the inventory window (its onKeyDown asks first). CBA's keybinds do not run while a
 * dialog is open, so the window's keys are read here: the key of a slot puts what the mouse is on there,
 * the drop key (the window's, G by default) empties the slot the mouse is on.
 *
 *   Over a tile, or a slot of the own equipment: the item goes on that slot, from where it lies
 *   (fnc_bind says why not).
 *   Over a slot of the hotbar: the two slots swap.
 *   The drop key over a slot of the hotbar: it is emptied.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift held <BOOL> (default: false)
 * 3: Ctrl held <BOOL> (default: false)
 * 4: Alt held <BOOL> (default: false)
 *
 * Return Value:
 * The key was used here, the window does nothing more with it <BOOL>
 *
 * Example:
 * [_display, 6, false, false, false] call aio_hotbar_fnc_onWindowKey;
 *
 * Public: No
 */

params ["", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false]];

if (!(call FUNC(isActive))) exitWith {false};

private _hover = EGVAR(gui,hover);
private _slots = uiNamespace getVariable [QEGVAR(gui,slots), []];

// The record of the hotbar slot under the mouse, [] when it is something else.
private _record = [];

if ((_hover param [0, ""]) isEqualTo "slot" && {(_hover param [1, -1]) >= 0}) then {
    _record = _slots param [_hover select 1, []];
};

private _onStrip = _record isNotEqualTo [] && {(_record param [7, -1]) >= 0};

// The drop key (aio_gui_fnc_isDropKey, set in Configure Addons) empties a slot of the bar.
if (_onStrip && {[_key, [_shift, _ctrl, _alt]] call EFUNC(gui,isDropKey)}) exitWith {
    [_record select 7] call FUNC(unbind);

    true
};

private _index = [_key, [_shift, _ctrl, _alt]] call FUNC(keyIndex);

if (_index < 0) exitWith {false};

// Another slot's key over a slot of the bar: they swap.
if (_onStrip) exitWith {
    [_record select 7, _index] call FUNC(moveSlot);

    true
};

switch (_hover param [0, ""]) do {
    case "tile": {
        private _grid = (uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_hover select 1, createHashMap];
        private _tile = (_grid getOrDefault ["tiles", []]) param [_hover select 2, createHashMap];
        private _class = _tile getOrDefault ["class", ""];

        // What has not been searched yet is not known - there is nothing to put on a key.
        if (_class isEqualTo "" || {_tile getOrDefault ["hidden", false]}) exitWith {false};

        [_index, _class, ["grid", _grid]] call FUNC(bind);

        true
    };
    case "slot": {
        private _class = _record param [1, ""];

        if (_class isEqualTo "" || {(_record param [5, ""]) isEqualTo ""}) exitWith {false};

        [_index, _class, ["slot", _record]] call FUNC(bind);

        true
    };
    default {false};
}
