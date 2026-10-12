#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the hotbar's row in the inventory window: seven slots the size of the small gear slots, spread
 * over the width of the equipment column, each with the key on its key cap, the item's picture and the
 * number carried bottom right (red and the picture faded at none). They are slots like any other
 * (einv_gui_fnc_drawSlot) with the number of the hotbar slot in the record's eighth element, which is
 * what tells the window's mouse handling they take a class and do not hold an item.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] - the row <ARRAY>
 * 3: Width of one slot <NUMBER>
 * 4: Theme, the one without captions on the slots <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, controlNull, [0.1, 0.8, 0.5, 0.05], 0.05, _theme] call einv_hotbar_fnc_drawStrip;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_slotW", "_theme"];
_rect params ["_left", "_top", "_width", "_height"];

// Read once for all seven.
private _counts = call FUNC(counts);

for "_i" from 0 to (SLOT_COUNT - 1) do {
    private _info = [_i, _counts param [_i, 0]] call FUNC(slotInfo);
    private _class = _info get "class";
    private _count = _info get "count";
    private _key = _info get "key";

    [
        _display, _parent,
        [_left + _i * (_width - _slotW) / (SLOT_COUNT - 1), _top, _slotW, _height],
        _class,
        createHashMapFromArray [
            ["caption", format [LLSTRING(Strip_Caption), [str (_i + 1), _key] select (_key isNotEqualTo "")]],
            ["number", _key],
            ["count", ["", str _count] select (_class isNotEqualTo "")],
            ["faded", _class isNotEqualTo "" && {_count == 0}],
            ["hotbar", _i]
        ],
        _theme
    ] call EFUNC(gui,drawSlot);
};
