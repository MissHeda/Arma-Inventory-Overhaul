#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The keys that work on what the mouse is on, for the key hints beside the name at the mouse
 * (fnc_drawTipKeys) - only those that apply to this tile or slot:
 *
 *   G         Drop       - an item that can be dropped (not one lying on the ground already)
 *   4-0       Hotbar     - an item that may go on the hotbar from where it lies (einv_hotbar_fnc_bindHint), the
 *                          keys the player really has
 *   Double click  Quick move / Open / Equip - what a double click does with this one
 *   Shift+Click   Split  - a stack, where the storage keeps stacks apart (fnc_splitStack); else Shift+Drag
 *                          Half stack
 *   Ctrl+Click    Take off - the item of a worn slot
 *   Right click   Options - every one that has a menu
 *
 * A slot of the hotbar: G clears it, dragging it out removes the binding. None outside the inventory (a window
 * that attached has its own keys, the "footerKeys" hook), while something is dragged or a menu is open, and
 * for a tile that was not searched yet.
 *
 * Arguments:
 * 0: What the mouse is on, ["tile", grid index, tile index] or ["slot", slot index] <ARRAY>
 *
 * Return Value:
 * Key hints [[key, text], ...], [] for none <ARRAY>
 *
 * Example:
 * [["tile", 0, 3]] call einv_gui_fnc_hoverKeys;
 *
 * Public: No
 */

params [["_shown", [], [[]]]];

if (
    !(call FUNC(isInventoryMode)) || {GVAR(dragging)} || {GVAR(stripDrag) isNotEqualTo []}
    || {(uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo []}
) exitWith {[]};

private _keys = [];

switch (_shown param [0, ""]) do {
    case "tile": {
        private _grid = (uiNamespace getVariable [QGVAR(grids), []]) param [_shown select 1, createHashMap];
        private _tile = (_grid getOrDefault ["tiles", []]) param [_shown select 2, createHashMap];
        private _class = _tile getOrDefault ["class", ""];
        private _holder = _grid getOrDefault ["container", objNull];
        private _kit = _grid getOrDefault ["kit", ""];

        if (count _tile == 0 || {_class isEqualTo ""} || {_tile getOrDefault ["hidden", false]}) exitWith {};

        // A body's worn gear that shows as tiles: its menu only.
        if (_grid getOrDefault ["virtual", true]) exitWith {
            _keys pushBack [LLSTRING(Key_RightClick), LLSTRING(Menu)];
        };

        // A move of it under way: nothing but the menu (what it is, and opening it).
        if (_tile getOrDefault ["pending", false]) exitWith {
            _keys pushBack [LLSTRING(Key_RightClick), LLSTRING(Menu)];
        };

        private _ground = _kit isEqualTo "" && {[_holder] call EFUNC(storage,isGroundHolder)};

        // What a living person's gear allows is asked once more by every move itself (fnc_checkTouch): a key
        // shown here that the settings refuse says why when pressed.
        if (!_ground) then {
            _keys pushBack [LLSTRING(Key_Drop), LLSTRING(Drop)];
        };

        if (!isNil QEFUNC(hotbar,bindHint)) then {
            private _bind = [_class, ["grid", _grid]] call EFUNC(hotbar,bindHint);

            if ((_bind param [0, ""]) isNotEqualTo "") then {
                _keys pushBack _bind;
            };
        };

        // The double click: a uniform, vest or backpack opens, what can be worn on the ground is put on, the
        // rest moves over (fnc_onMouseButton).
        private _double = LLSTRING(QuickMove);

        if (!isNull (_tile getOrDefault ["container", objNull])) then {
            _double = LLSTRING(Keys_Open);
        } else {
            if (_ground) then {
                private _wearSlot = [GVAR(unit), _class] call EFUNC(storage,slotFor);

                if (_wearSlot isNotEqualTo "" && {(_wearSlot find "_") < 0}) then {
                    _double = LLSTRING(Equip);
                };
            };
        };

        _keys pushBack [LLSTRING(Key_DoubleClick), _double];

        // A stack: split in two where stacks lie apart, else lifted by half.
        if ((_tile getOrDefault ["count", 1]) > 1 && {_kit isEqualTo ""}) then {
            if (missionNamespace getVariable [QEGVAR(storage,stackSplits), false]) then {
                _keys pushBack [LLSTRING(Key_ShiftClick), LLSTRING(Keys_Split)];
            } else {
                _keys pushBack [LLSTRING(Key_ShiftDrag), LLSTRING(Keys_Half)];
            };
        };

        _keys pushBack [LLSTRING(Key_RightClick), LLSTRING(Menu)];
    };
    case "slot": {
        private _record = (uiNamespace getVariable [QGVAR(slots), []]) param [_shown select 1, []];
        private _class = _record param [1, ""];

        if (_record isEqualTo [] || {_class isEqualTo ""}) exitWith {};

        // A slot of the hotbar: clear it, or drag it off the bar.
        if ((_record param [7, -1]) >= 0) exitWith {
            _keys pushBack [LLSTRING(Key_Drop), LLSTRING(Keys_Clear)];
            _keys pushBack [LLSTRING(Key_Drag), LLSTRING(Keys_MoveOrRemove)];
            _keys pushBack [LLSTRING(Key_RightClick), LLSTRING(Menu)];
        };

        private _owner = _record param [6, objNull];

        if (isNull _owner || {(_record param [5, ""]) isEqualTo ""}) exitWith {};

        // The radio slot ACRE2 keeps for itself: nothing to do with it but look.
        if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_owner, _record param [5, ""]] call EFUNC(compat_acre,isFixedSlot)}) exitWith {
            _keys pushBack [LLSTRING(Key_RightClick), LLSTRING(Menu)];
        };

        _keys pushBack [LLSTRING(Key_Drop), LLSTRING(Drop)];

        if (!isNil QEFUNC(hotbar,bindHint)) then {
            private _bind = [_class, ["slot", _record]] call EFUNC(hotbar,bindHint);

            if ((_bind param [0, ""]) isNotEqualTo "") then {
                _keys pushBack _bind;
            };
        };

        _keys pushBack [LLSTRING(Key_CtrlClick), LLSTRING(Keys_TakeOff)];
        _keys pushBack [LLSTRING(Key_RightClick), LLSTRING(Menu)];
    };
};

_keys
