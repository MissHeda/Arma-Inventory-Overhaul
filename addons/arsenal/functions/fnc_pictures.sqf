#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the pictures the rules give to items (picture=, aio_picture; "pictureOverride" of
 * aio_items_fnc_getInfo) on ACE's own lists, so an item looks the same in ACE Arsenal as in the grid: the
 * rows of its left list (IDC 13), of the right list that holds items for the weapon tabs (IDC 14) and of the
 * right list of the container tabs (IDC 15, a listnbox). ACE fills every row with the picture its config
 * names (ace_arsenal_fnc_addListBoxItem, fnc_fillRightPanel); a row whose class has a picture of its own in
 * the rules is given that one, the picture of the grid's tiles (getInfo "picture" is it when the file is
 * there). Rows with no class (the "Empty" row), classes without a rule of that kind and rows that have the
 * picture already are left alone.
 *
 * Run a frame after ACE's events (fnc_settle), once ACE has sorted the rows. The lists can hold thousands of
 * rows (misc. items), and an item's info is worked out at its first look, so the rows are done in turns of
 * PICTURE_BUDGET seconds a frame; a newer pass takes over from one that is still going (ACE has filled its
 * lists anew meanwhile).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: The lists still to do and where they stand, [[list, is a listnbox, next row], ...] - only for the
 *    pass that goes on by itself <ARRAY> (default: [])
 * 2: The pass it belongs to, -1 to start a new one <NUMBER> (default: -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_arsenal_fnc_pictures;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_jobs", [], [[]]], ["_pass", -1, [0]]];

if (isNull _display || {GVAR(kind) isEqualTo "bi"}) exitWith {};

if (_pass < 0) then {
    GVAR(picturePass) = GVAR(picturePass) + 1;
    _pass = GVAR(picturePass);
    _jobs = [];
    GVAR(pictureStat) = [diag_tickTime, 0, 0, 0];

    {
        _x params ["_idc", "_isNbox"];

        private _list = _display displayCtrl _idc;

        if (!isNull _list) then {
            _jobs pushBack [_list, _isNbox, 0];
        };
    } forEach [[ARSENAL_IDC_LEFT_LIST, false], [ARSENAL_IDC_RIGHT_LIST, false], [ARSENAL_IDC_LIST, true]];
};

if (_pass != GVAR(picturePass)) exitWith {};

private _sliceBegin = diag_tickTime;
private _until = _sliceBegin + PICTURE_BUDGET;
private _more = [];
private _rowsDone = 0;
private _fresh = 0;

{
    _x params ["_list", "_isNbox", "_row"];

    private _size = if (_isNbox) then {(lnbSize _list) select 0} else {lbSize _list};

    while {_row < _size && {diag_tickTime < _until}} do {
        private _class = if (_isNbox) then {_list lnbData [_row, 0]} else {_list lbData _row};

        if (_class isNotEqualTo "") then {
            private _key = toLowerANSI _class;
            private _picture = GVAR(pictureCache) get _key;

            // Asked once per class while the window is open: the rules cannot change under it.
            if (isNil "_picture") then {
                _fresh = _fresh + 1;

                private _info = [_class] call EFUNC(items,getInfo);
                private _ruled = _info getOrDefault ["pictureOverride", ""];

                _picture = ["", _ruled] select (_ruled isNotEqualTo "" && {(_info getOrDefault ["picture", ""]) == _ruled});

                GVAR(pictureCache) set [_key, _picture];
            };

            if (_picture isNotEqualTo "") then {
                if (_isNbox) then {
                    if ((_list lnbPicture [_row, 0]) isNotEqualTo _picture) then {
                        _list lnbSetPicture [[_row, 0], _picture];
                    };
                } else {
                    if ((_list lbPicture _row) isNotEqualTo _picture) then {
                        _list lbSetPicture [_row, _picture];
                    };
                };
            };
        };

        _row = _row + 1;
        _rowsDone = _rowsDone + 1;
    };

    if (_row < _size) then {
        _more pushBack [_list, _isNbox, _row];
    };
} forEach _jobs;

// For the tester's numbers (aio_gui_debugTiming): what the whole pass spent, over all its frames, and how many
// classes it had to work out the rules' info of for the first time (the cost of a first look).
GVAR(pictureStat) params ["_passBegin", "_slices", "_spent", "_made"];
GVAR(pictureStat) = [_passBegin, _slices + 1, _spent + (diag_tickTime - _sliceBegin), _made + _fresh];

// Not done within the budget: the rest a frame later.
if (_more isNotEqualTo []) then {
    [{_this call FUNC(pictures)}, [_display, _more, _pass]] call EFUNC(gui,later);
} else {
    GVAR(pictureStat) params ["_passBegin", "_slices", "_spent", "_made"];

    ["pictures pass", diag_tickTime - _spent, format ["%1 classes first looked at, %2 frames, %3 ms in all, %4 ms from start to end", _made, _slices, (_spent * 1000) toFixed 1, ((diag_tickTime - _passBegin) * 1000) toFixed 0], true] call FUNC(noteOpen);
};
