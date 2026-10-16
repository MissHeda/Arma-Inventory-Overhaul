#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the rows of ACE's list right by the grid. ACE greys the rows the open uniform, vest or backpack
 * cannot take by weight, and disables its "+" for them (ace_arsenal_fnc_updateRightPanel, the engine's
 * canAdd - a container whose maximumLoad is 0, like ACE's Telescopic Ladder, refuses every item, so all
 * rows go grey), and leaves every other row lit, however the cells lie. Cells are the only limit here, so
 * both ways: a row ACE greyed whose item the grid would take is lit again, and a row ACE left lit whose
 * item the grid has no spot for is greyed, as ACE greys one - a 2x2 magazine does not fit into a vest with
 * four cells free in singles. Asked as an add asks it (einv_storage_fnc_hasSpace, the layout fnc_addNew
 * and fnc_addTo place a new item by): a free spot of the item's shape, upright or turned, in one of the
 * compartments, or a pile of the same kind (class and rounds) with room left. The "+" of the row picked
 * is enabled or disabled the same way.
 *
 * Items the box does not offer (ACE's unique ones, lnbValue 1) and backpacks are left to ACE.
 *
 * Run after ACE's own look: a frame after its events (fnc_settle) and a frame after a row is picked
 * (fnc_onOpened). ACE looks again at every pick (ace_arsenal_fnc_onSelChangedRightListnBox) and greys the
 * whole list by weight anew, so the rows are put right after a pick too, not only the "+". One look at the
 * grid per item shape (per class where it stacks) and pass. The list can hold thousands of rows, so they
 * are done in turns of UNGREY_BUDGET seconds a frame; a newer pass takes over from one that is still going.
 * Should ACE's list or arrow not be where this addon expects them, nothing is changed and the RPT says so
 * once.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: The row to go on from - only for the pass that goes on by itself <NUMBER> (default: 0)
 * 2: The pass it belongs to, -1 to start a new one <NUMBER> (default: -1)
 * 3: What the grid said so far, shape or class to answer - only for the pass that goes on by itself
 *    <HASHMAP> (default: empty)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_ungrey;
 *
 * Public: No
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]], ["_from", 0, [0]], ["_pass", -1, [0]],
    ["_asked", createHashMap, [createHashMap]]
];

if (!GVAR(attached) || {isNull _display}) exitWith {};

if (_pass >= 0 && {_pass != GVAR(ungreyPass)}) exitWith {};

(call FUNC(selected)) params ["", "_container"];

if (isNull _container) exitWith {};

private _list = _display displayCtrl ARSENAL_IDC_LIST;
private _plus = _display displayCtrl ARSENAL_IDC_PLUS;

if (isNull _list || {isNull _plus}) exitWith {
    if !("ungrey" in GVAR(missingSaid)) then {
        GVAR(missingSaid) pushBack "ungrey";
        WARNING("ACE Arsenal's list or its + arrow is not where this addon looks - rows stay as ACE has them.");
    };
};

if (_pass < 0) then {
    GVAR(ungreyPass) = GVAR(ungreyPass) + 1;
    _pass = GVAR(ungreyPass);
};

// Whether one more of a class would be taken: asked as fnc_addNew asks it, with a magazine full. What
// stacks answers by its own pile, so it is asked per class; the rest only needs a free spot of its shape,
// asked once per shape. 1 it fits, 0 it does not, -1 not for this addon to say (no class, a backpack).
private _fnc_fits = {
    params ["_class"];

    if (_class isEqualTo "") exitWith {-1};

    private _info = [_class] call EFUNC(items,getInfo);

    if ((_info getOrDefault ["kind", ""]) isEqualTo "backpack") exitWith {-1};

    private _capacity = _info getOrDefault ["capacity", 0];
    private _which = if ((_info getOrDefault ["stack", 1]) > 1) then {
        toLowerANSI _class
    } else {
        // Size and holes: the shape string says both.
        _info getOrDefault ["shape", str (_info getOrDefault ["size", [1, 1]])]
    };
    private _known = _asked get _which;

    if (!isNil "_known") exitWith {_known};

    private _fits = parseNumber ([_container, createHashMapFromArray [
        ["class", _class], ["count", 1], ["ammo", _capacity], ["capacity", _capacity],
        ["attachments", []], ["container", objNull]
    ]] call EFUNC(storage,hasSpace));

    _asked set [_which, _fits];

    _fits
};

// The "+" of the row picked first, so it is right whatever the list takes to be done.
if (_from == 0) then {
    private _row = lnbCurSelRow _list;

    if (_row >= 0 && {(_list lnbValue [_row, 2]) != 1}) then {
        private _fit = [_list lnbData [_row, 0]] call _fnc_fits;

        if (_fit == 1 && {!ctrlEnabled _plus}) then {
            _plus ctrlEnable true;
        };

        if (_fit == 0 && {ctrlEnabled _plus}) then {
            _plus ctrlEnable false;
        };
    };
};

private _size = (lnbSize _list) select 0;
private _row = _from;
private _until = diag_tickTime + UNGREY_BUDGET;

while {_row < _size && {diag_tickTime < _until}} do {
    if ((_list lnbValue [_row, 2]) != 1) then {
        private _color = _list lnbColor [_row, 1];
        private _alpha = _color param [3, 1];
        private _fit = [_list lnbData [_row, 0]] call _fnc_fits;

        // How ACE greys: seen on the rows it greyed.
        if (_alpha < 1) then {
            GVAR(greyAlpha) = _alpha;
        };

        // Greyed by ACE and room for it: lit again.
        if (_fit == 1 && {_alpha < 1}) then {
            _color set [3, 1];
            _list lnbSetColor [[_row, 1], _color];
            _list lnbSetColor [[_row, 2], [1, 1, 1, 1]];
        };

        // Lit by ACE and no room for it: grey as ACE greys.
        if (_fit == 0 && {_alpha >= 1}) then {
            _color set [3, GVAR(greyAlpha)];
            _list lnbSetColor [[_row, 1], _color];
            _list lnbSetColor [[_row, 2], [1, 1, 1, GVAR(greyAlpha)]];
        };
    };

    _row = _row + 1;
};

// Not done within the budget: the rest a frame later.
if (_row < _size) then {
    [{_this call FUNC(ungrey)}, [_display, _row, _pass, _asked]] call EFUNC(gui,later);
};
