#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The order the window's panels are drawn in, back to front: what comes later lies over what came before. The player sets it in the
 * edit mode (fnc_openLayoutEditor, "front" and "back" of fnc_layoutDrag), kept in aio_gui_layoutRects as an entry "order:" with the
 * ids from back to front. What it does not name stays where the usual order has it, behind what it names.
 *
 * Arguments:
 * 0: The ids drawn, in the usual order <ARRAY>
 *
 * Return Value:
 * The same ids, back to front <ARRAY>
 *
 * Example:
 * [["equipment", "storage", "loot"]] call aio_gui_fnc_layerOrder;
 *
 * Public: No
 */

params [["_ids", [], [[]]]];

private _order = [];

{
    private _parts = _x splitString ":";

    if (count _parts == 2 && {(_parts select 0) isEqualTo "order"}) exitWith {
        _order = (_parts select 1) splitString ",";
    };
} forEach ((missionNamespace getVariable [QGVAR(layoutRects), ""]) splitString ";");

private _keyed = _ids apply {[_order find _x, _forEachIndex, _x]};

_keyed sort true;

_keyed apply {_x select 2}
