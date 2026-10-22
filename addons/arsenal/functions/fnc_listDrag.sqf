#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Starts a drag of the item on the row of ACE's list (IDC 15) - or of the list of Enhanced First Aid Kits' kits
 * tab, which lies over it while that tab is open, built like it - the mouse was pressed on, once it moved
 * LIST_DRAG_PX pixels from the press with the button held (fnc_onFrame): the engine's drag of a new item,
 * which has no container behind it. Its class is the one ACE keeps in the row's data. A row ACE would not
 * add either - an item the arsenal does not have, only the soldier - is not dragged, and the hint line says
 * so, once for the press (a drag that silently does nothing reads as a press that was not heard); in the kits tab's
 * list such a row (lnbValue 1 there too) is one the picked kit cannot take, which its tooltip says. Nor is a
 * row the list no longer has (a filter shortened it since the press), nor the blank area under a short list.
 * A greyed row is dragged: ACE greys by weight, the grid has its own say at the drop, and the staging space
 * takes what the container cannot (fnc_ungrey, fnc_addTo).
 *
 * The row is the one fnc_onListPress worked out from where the press was - not the one the list picks:
 * that comes only after the press, and may follow the mouse as it moves. Only when that row is out of range
 * - the list shorter now, a press under its last row - does the row ACE picked count, and only when the
 * list picked one since the press (GVAR(listSel), noted by its LBSelChanged handler, fnc_onOpened): before
 * it, lnbCurSelRow is the row picked before.
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
 * 3: The row pressed, -1 for none (fnc_onListPress) <NUMBER> (default: -1)
 * 4: The frame of the press (diag_frameNo) <NUMBER> (default: -1)
 * 5: The IDC of the list pressed <NUMBER> (default: ACE's list, 15)
 *
 * Return Value:
 * A drag started <BOOL>
 *
 * Example:
 * [_display, [0.6, 0.4], false, 12, diag_frameNo] call einv_arsenal_fnc_listDrag;
 *
 * Public: No
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]], ["_pressed", [], [[]]], ["_shift", false, [false]], ["_row", -1, [0]], ["_frame", -1, [0]],
    ["_idc", ARSENAL_IDC_LIST, [0]]
];

private _list = _display displayCtrl _idc;

if (isNull _list || {_pressed isEqualTo []} || {EGVAR(gui,dragging)} || {GVAR(panelRect) isEqualTo []}) exitWith {false};

private _rows = (lnbSize _list) select 0;

// Out of range: the row the list picked, if it picked one since the press - else none.
if (_row < 0 || {_row >= _rows}) then {
    _row = [-1, lnbCurSelRow _list] select (
        _frame >= 0 && {(GVAR(listSel) param [1, -1]) >= _frame} && {(GVAR(listSel) param [2, ARSENAL_IDC_LIST]) == _idc}
    );
};

if (_row < 0 || {_row >= _rows}) exitWith {false};

private _class = _list lnbData [_row, 0];

if (_class isEqualTo "") exitWith {false};

// ACE's unique items: what the soldier has and the box does not. ACE would not add one; nor does the panel. In the
// kits tab's list: what the picked kit cannot take there (its rules, the arsenal does not have it, the type may not
// be filled) - that tab says why in the row's tooltip.
if ((_list lnbValue [_row, 2]) == 1) exitWith {
    [[LLSTRING(Hint_KitRowNotAllowed), LLSTRING(Hint_NotAllowed)] select (_idc == ARSENAL_IDC_LIST)] call EFUNC(gui,flashHint);
    false
};

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

// The ghost lies over ACE's list as it starts: the list must not keep the focus - the panel's sink takes it
// (fnc_layout, fnc_onFrame).
private _sink = uiNamespace getVariable [QGVAR(focusSink), controlNull];

if (!isNull _sink) then {
    ctrlSetFocus _sink;
};

[_display] call EFUNC(gui,startDrag);

// Which row it is and in which list, to lift it again should the folded panel unfold under it (fnc_onFrame).
if (EGVAR(gui,dragging)) then {
    GVAR(listDragClass) = _class;
    GVAR(listDragIdc) = _idc;
};

EGVAR(gui,dragging)
