#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Single slots that grow (grid=1x1:grow, a seventh element true on the compartment, aio_items_fnc_parseGrid) as the window
 * shows them (issue #42): a slot with an item in it is as large as the item - its upright size, a rectangle -, an empty one
 * as it was drawn. The item lies in it at its own size, not scaled into the slot.
 *
 * Flowed compartments make room by themselves: the flow (fnc_flowCompartments) lays them out by their size. On a canvas
 * (compartments with a pos) the slot pushes the others aside: every compartment that starts right of where the slot ended
 * moves right by what it grew across, every one that starts below it moves down by what it grew down - as if that many
 * columns and rows were put into the drawing there, so nothing that did not overlap comes to overlap. A slot smaller than
 * drawn moves nothing.
 *
 * The view only: the places, the records and every machine's layout keep the slot as drawn - a single slot holds any item
 * whatever its size, so nothing about where things lie changes (aio_storage_fnc_getLayout). The compartments are copied, the
 * container type's own are never changed; the entries in a slot that grew get its size ("w", "h", no "holes"), as the
 * layout gives an entry in a single slot the slot's.
 *
 * Arguments:
 * 0: Layout (aio_storage_fnc_getLayout) <HASHMAP>
 *
 * Return Value:
 * The same layout, its "blocks" those shown <HASHMAP>
 *
 * Example:
 * _layout = [[_container, _entries] call aio_storage_fnc_getLayout] call aio_gui_fnc_growSlots;
 *
 * Public: No
 */

params [["_layout", createHashMap, [createHashMap]]];

private _blocks = _layout getOrDefault ["blocks", []];

if ((_blocks findIf {_x param [6, false]}) < 0) exitWith {_layout};

private _shown = +_blocks;

{
    private _entry = _x;
    private _index = _entry getOrDefault ["block", -1];
    private _block = _shown param [_index, []];

    if (_entry getOrDefault ["single", false] && {!(_entry getOrDefault ["overflow", false])} && {_block param [6, false]}) then {
        ((([_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]])) params ["_w", "_h"];

        _w = ((_w max 1) min STORAGE_COLS);
        _h = ((_h max 1) min MAX_ROWS);

        _block params ["_cols", "_rows", "", ["_pos", []]];

        // On a canvas: room after it, across and down.
        if (_pos isNotEqualTo [] && {_w > _cols || {_h > _rows}}) then {
            _pos params ["_slotX", "_slotY"];

            private _moreW = (_w - _cols) max 0;
            private _moreH = (_h - _rows) max 0;

            {
                private _place = _x param [3, []];

                if (_forEachIndex != _index && {_place isNotEqualTo []}) then {
                    _place params ["_placeX", "_placeY"];

                    _x set [3, [
                        _placeX + ([0, _moreW] select (_placeX >= _slotX + _cols)),
                        _placeY + ([0, _moreH] select (_placeY >= _slotY + _rows))
                    ]];
                };
            } forEach _shown;
        };

        _block set [0, _w];
        _block set [1, _h];
        _block set [2, []];

        _entry set ["w", _w];
        _entry set ["h", _h];
        _entry set ["holes", []];
    };
} forEach (_layout getOrDefault ["entries", []]);

_layout set ["blocks", _shown];

_layout
