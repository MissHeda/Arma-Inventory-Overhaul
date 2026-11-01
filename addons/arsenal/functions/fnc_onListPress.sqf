#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A mouse button pressed on ACE's list (IDC 15), or on the list of Enhanced First Aid Kits' kits tab that lies
 * over it while that tab is open (fnc_onOpened) - the list's own handler, as the display's may not hear a
 * press on one of ACE's controls. A left press on its rows is noted - where, in which frame, on which
 * row and in which list -, and nothing else: the click and the row it picks are the list's. Should the mouse then move further
 * than LIST_DRAG_PX pixels, in any direction, with the button held, the frame hook makes a drag of that
 * row's item (fnc_onFrame, fnc_listDrag); let go first, the note goes. The list scrolls with the wheel and
 * its scroll bar, never by dragging its rows, so a held button that moves is a drag, up and down too. Not on
 * the scroll bar along its right edge, not on the "-" and "+" over the right end of the row picked (ACE's IDC
 * 101 and 102, the kits tab's own - each list names its pair: the player aimed at those), and only while there is
 * a panel beside it to drag to.
 *
 * The row is worked out here, from where the press is, and not read from the list: this handler runs
 * before the list moves its selection to the row pressed, so lnbCurSelRow still names the row picked
 * before (or none), and in the frames after it the selection may follow the mouse down the list. The
 * rows are all as high as the list's config says, and the list is scrolled by a share of what its rows
 * reach past its height:
 *
 *     content  = rows * rowH                       how high all rows are
 *     range    = max(0, content - listH)           how far it can scroll
 *     offset   = clamp(scroll, 0, 1) * range       what lies above its top edge (ctrlScrollValues
 *                                                  select 0, a share 0 to 1 - or -1 with no bar)
 *     row      = floor((pressY - listY + offset) / rowH)
 *
 * By hand, at 1080p (ACE's row 7 of its grid units of 4 px, 28 px): 100 rows in a list 944 px high,
 * scrolled to the middle (0.5). content 2800 px, range 1856, offset 928 - row 33 (924 to 952) shows
 * its lowest 24 px at the top. A press 100 px under the top: (100 + 928) / 28 = 36.7, row 36 - the
 * fourth row seen, 80 to 108 px from the top. Unscrolled, the same press is row 3.
 *
 * A row past the last - the blank area under a short list - is noted as none (-1): fnc_listDrag then
 * takes the row the list picked since the press, if it picked one.
 *
 * Arguments:
 * 0: ACE's list, or the kits tab's <CONTROL>
 * 1: Button, 0 left, 1 right <NUMBER>
 * 2: Shift - a drag starts with a whole stack <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_list, 0, false] call aio_arsenal_fnc_onListPress;
 *
 * Public: No
 */

disableSerialization;

params [["_list", controlNull, [controlNull]], ["_button", 0, [0]], ["_shift", false, [false]]];

GVAR(listPress) = [];

if (_button != 0 || {isNull _list} || {!GVAR(attached)} || {GVAR(panelRect) isEqualTo []} || {EGVAR(gui,dragging)}) exitWith {};

private _mouse = getMousePosition;
private _rows = (lnbSize _list) select 0;

(ctrlPosition _list) params ["_listX", "_listY", "_listW", "_listH"];
_mouse params ["_mouseX", "_mouseY"];

if (
    _rows == 0 || {_mouseX < _listX} || {_mouseX >= _listX + _listW * LIST_ROWS_SHARE}
    || {_mouseY < _listY} || {_mouseY >= _listY + _listH}
) exitWith {};

// The list's "-" and "+" lie over the right end of the row picked - shown and not faded out. A press there is
// theirs, even with the "+" disabled for an item the box does not have.
private _display = ctrlParent _list;

private _onArrow = (_list getVariable [QGVAR(arrows), [ARSENAL_IDC_MINUS, ARSENAL_IDC_PLUS]]) findIf {
    private _arrow = _display displayCtrl _x;

    !isNull _arrow && {ctrlShown _arrow} && {ctrlFade _arrow < 1} && {
        (ctrlPosition _arrow) params ["_arrowX", "_arrowY", "_arrowW", "_arrowH"];

        _mouseX >= _arrowX && {_mouseX < _arrowX + _arrowW} && {_mouseY >= _arrowY} && {_mouseY < _arrowY + _arrowH}
    }
} >= 0;

if (_onArrow) exitWith {};

// The height of the list's rows, found once by its IDC in ACE's display config: its rowHeight or - ACE
// leaves it at RscListNBox's 0, rows as high as their text - its sizeEx, 7 of ACE's grid units (the kits tab's
// list is a child of ACE's, the same). Both may be expressions, which getNumber does not work out; failing all,
// ACE's 7 units as ACE_ROW_SIZE has them.
private _rowH = _list getVariable [QGVAR(rowHeight), -1];

if (_rowH <= 0) then {
    private _root = [configFile >> "ace_arsenal_display" >> "controls", configFile >> "RscDisplayArsenal" >> "controls"] select (GVAR(kind) isEqualTo "bi");
    private _config = (format ["getNumber (_x >> 'idc') == %1", ctrlIDC _list] configClasses _root) param [0, configNull];

    private _fnc_read = {
        if (isText _this) exitWith {[call compile getText _this] param [0, 0, [0]]};

        getNumber _this
    };

    _rowH = (_config >> "rowHeight") call _fnc_read;

    if (_rowH <= 0) then {
        _rowH = (_config >> "sizeEx") call _fnc_read;
    };

    if (_rowH <= 0) then {
        _rowH = ACE_ROW_SIZE;
    };

    _list setVariable [QGVAR(rowHeight), _rowH];
};

private _offset = ((((ctrlScrollValues _list) select 0) max 0) min 1) * ((_rows * _rowH - _listH) max 0);
private _row = floor ((_mouseY - _listY + _offset) / _rowH);

if (_row >= _rows) then {
    _row = -1;
};

GVAR(listPress) = [_mouse, _shift, diag_frameNo, _row, ctrlIDC _list];
