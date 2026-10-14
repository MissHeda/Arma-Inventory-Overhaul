#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Starts a drag of the item on the row of ACE's list (IDC 15) the mouse was pressed on, once it left the
 * press sideways (fnc_onFrame): the engine's drag of a new item, which has no container behind it. Its class
 * is the one ACE keeps in the row's data. A row ACE would not add either - an item the arsenal does not
 * have, only the soldier - is not dragged, nor is one the list no longer has (a filter shortened it since
 * the press), nor the blank area under a short list.
 *
 * The row is the one pressed, though the list may not have picked it yet: a press on a row that was not
 * picked found lnbCurSelRow still on the row before, and only a second press dragged. So the row ACE picked
 * counts only when the list picked one since the press (GVAR(listSel), noted by its LBSelChanged handler,
 * fnc_onOpened) - else the row under the press, from the list's top, the height of its rows and how far it
 * is scrolled.
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
 * 3: The frame of the press (diag_frameNo) <NUMBER> (default: -1, the row picked)
 *
 * Return Value:
 * A drag started <BOOL>
 *
 * Example:
 * [_display, [0.6, 0.4], false, diag_frameNo] call einv_arsenal_fnc_listDrag;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_pressed", [], [[]]], ["_shift", false, [false]], ["_frame", -1, [0]]];

private _list = _display displayCtrl ARSENAL_IDC_LIST;

if (isNull _list || {_pressed isEqualTo []} || {EGVAR(gui,dragging)} || {GVAR(panelRect) isEqualTo []}) exitWith {false};

private _rows = (lnbSize _list) select 0;
private _row = lnbCurSelRow _list;

// The list picked no row since the press: lnbCurSelRow is the row before, the pressed one lies under it.
if (_frame >= 0 && {(GVAR(listSel) param [1, -1]) < _frame}) then {
    // The rows are all as high as the list's config says (found once, by its IDC, in ACE's display); left
    // to the font (0), as high as its text - ACE's 7 units.
    private _rowH = _list getVariable [QGVAR(rowHeight), -1];

    if (_rowH <= 0) then {
        private _config = (format ["getNumber (_x >> 'idc') == %1", ARSENAL_IDC_LIST] configClasses (configFile >> "ace_arsenal_display" >> "controls")) param [0, configNull];

        _rowH = getNumber (_config >> "rowHeight");

        if (_rowH <= 0) then {
            _rowH = getNumber (_config >> "sizeEx");
        };

        if (_rowH <= 0) then {
            _rowH = ACE_ROW_SIZE;
        };

        _list setVariable [QGVAR(rowHeight), _rowH];
    };

    // Scrolled, the rows above the top edge are the scroll bar's place (0 to 1) times what the rows reach
    // past the list's height.
    (ctrlPosition _list) params ["", "_listY", "", "_listH"];

    private _offset = (((ctrlScrollValues _list) select 0) max 0) * ((_rows * _rowH - _listH) max 0);

    _row = floor (((_pressed select 1) - _listY + _offset) / _rowH);
};

if (_row < 0 || {_row >= _rows}) exitWith {false};

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

// The ghost lies over ACE's list as it starts: the list must not keep the focus - the panel's sink takes it
// (fnc_layout, fnc_onFrame).
private _sink = uiNamespace getVariable [QGVAR(focusSink), controlNull];

if (!isNull _sink) then {
    ctrlSetFocus _sink;
};

[_display] call EFUNC(gui,startDrag);

EGVAR(gui,dragging)
