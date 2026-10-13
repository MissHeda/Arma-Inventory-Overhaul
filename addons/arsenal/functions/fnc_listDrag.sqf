#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Starts a drag of the item on the row of ACE's list (IDC 15) the mouse was pressed on, once it left the
 * press sideways (fnc_onFrame): the engine's drag of a new item, which has no container behind it. The row
 * is the one ACE picked for that press (lnbCurSelRow), its class the one ACE keeps in the row's data. A row
 * ACE would not add either - an item the arsenal does not have, only the soldier - is not dragged.
 *
 * The item is put on a source grid of its own (einv_gui's "source", here "aceList"), off the screen, as a
 * tile that brings the entry that is dragged: the item at its true size, a whole stack at most, one at
 * first or the whole stack with Shift. From there it is the engine's drag - the ghost with its footprint,
 * R to turn it, the wheel for how many with the count on the ghost (einv_gui_fnc_onMouseZ) - and the
 * engine leaves its end to the "drop" hook (fnc_onDrop, fnc_addTo). The focus leaves ACE's list, which the
 * engine would otherwise draw over the ghost (fnc_onFrame).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Where the mouse was pressed [x, y] <ARRAY>
 * 2: Shift - the whole stack <BOOL> (default: false)
 *
 * Return Value:
 * A drag started <BOOL>
 *
 * Example:
 * [_display, [0.6, 0.4], false] call einv_arsenal_fnc_listDrag;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_pressed", [], [[]]], ["_shift", false, [false]]];

private _list = _display displayCtrl ARSENAL_IDC_LIST;

if (isNull _list || {_pressed isEqualTo []} || {EGVAR(gui,dragging)} || {GVAR(panelRect) isEqualTo []}) exitWith {false};

private _row = lnbCurSelRow _list;

if (_row < 0) exitWith {false};

private _class = _list lnbData [_row, 0];

if (_class isEqualTo "" || {(_list lnbValue [_row, 2]) == 1}) exitWith {false};

private _info = [_class] call EFUNC(items,getInfo);

(_info getOrDefault ["size", [1, 1]]) params [["_w", 1], ["_h", 1]];

private _stack = (_info getOrDefault ["stack", 1]) max 1;
private _capacity = _info getOrDefault ["capacity", 0];
private _grab = [floor (_w / 2), floor (_h / 2)];

private _entry = createHashMapFromArray [
    ["class", _class], ["w", _w], ["h", _h], ["col", 0], ["row", 0], ["count", _stack],
    ["ammo", _capacity], ["capacity", _capacity], ["attachments", []], ["container", objNull], ["controls", []]
];

(call EFUNC(gui,getCell)) params ["_cellW", "_cellH"];

// Virtual and off the screen: never a target, never under the mouse.
private _grid = createHashMapFromArray [
    ["source", "aceList"], ["virtual", true], ["container", objNull], ["window", ""],
    ["parent", controlNull], ["rel", [-10, -10]], ["cols", 1], ["rows", 1], ["cellW", _cellW], ["cellH", _cellH],
    ["cells", []], ["holes", []], ["section", createHashMap],
    ["tiles", [createHashMapFromArray [
        ["class", _class], ["col", 0], ["row", 0], ["w", 1], ["h", 1], ["count", 1],
        ["ammo", _capacity], ["capacity", _capacity], ["attachments", []], ["container", objNull],
        ["size", [_w, _h]], ["grab", _grab], ["dragStart", 1], ["dragEntry", _entry], ["controls", []]
    ]]]
];

private _grids = uiNamespace getVariable [QEGVAR(gui,grids), []];
private _index = _grids pushBack _grid;

uiNamespace setVariable [QEGVAR(gui,grids), _grids];

GVAR(dragZone) = "";

// The press as the engine notes one on a tile of a source grid (einv_gui_fnc_onMouseButton).
EGVAR(gui,press) = [_index, 0, _pressed, _grab, false, [], false, _shift];

// The ghost lies over ACE's list as it starts: the list must not keep the focus (fnc_onFrame).
private _mouseArea = _display displayCtrl ARSENAL_IDC_MOUSE_AREA;

if (!isNull _mouseArea) then {
    ctrlSetFocus _mouseArea;
};

[_display] call EFUNC(gui,startDrag);

EGVAR(gui,dragging)
