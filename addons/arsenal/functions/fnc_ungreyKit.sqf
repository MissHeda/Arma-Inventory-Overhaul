#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The rows of Enhanced First Aid Kits' kits tab - its list of what the picked kit may hold, in ACE's right column
 * while that tab is open - greyed or lit by whether the kit in the panel takes one more of the row's item
 * (einv_compat_efak_fnc_canPackNew: the kit may be filled there, that mod's rules for it, and its room). Only
 * while the kit's room is the cells of a grid of its own (einv_compat_efak_fnc_roomMode "cells"): that mod greys
 * its list by its capacity, which is the kit's room otherwise, and is left alone then. With cells, a row that mod
 * greyed for the capacity is lit where a cell is free - the item is dragged in, as the "+" of that list still goes
 * by the capacity -, and a row it left lit is greyed where no cell is free; the "+" over the row picked is turned
 * off then (never on). Rows that cannot be added at all (lnbValue [row, 2] 1 - not allowed, not in the arsenal)
 * stay as that mod has them.
 *
 * That mod writes its own greying whenever it fills or counts its list (a pick, a click, a change of the kit), so
 * this runs again every KIT_UNGREY_EVERY seconds while the tab is open (fnc_onFrame), and a frame after a row is
 * picked (fnc_onOpened, fnc_ungrey). The kit's answers are kept per class while everything they depend on stays
 * the same (GVAR(kitVerdicts), einv_compat_efak_fnc_arsenalState: its contents, its places, the rules, its lock),
 * so a look again costs a comparison per row, and only a row whose alpha differs is written. New answers are asked
 * in turns of UNGREY_BUDGET seconds a frame, as fnc_ungrey asks ACE's list; a newer pass takes over.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: The row to go on from - only for the pass that goes on by itself <NUMBER> (default: 0)
 * 2: The pass it belongs to, -1 to start a new one <NUMBER> (default: -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_arsenal_fnc_ungreyKit;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_from", 0, [0]], ["_pass", -1, [0]]];

if (!GVAR(attached) || {isNull _display} || {isNil QEFUNC(compat_efak,canPackNew)}) exitWith {};

if (_pass >= 0 && {_pass != GVAR(ungreyPass)}) exitWith {};

// The kit the panel shows - only once it shows the tab's pick: right after another pick the list already lists what
// the new kit may hold while the panel's build is still to come.
private _kit = GVAR(focusKit);
private _focus = [_display] call FUNC(focusedKit);

if (_kit isEqualTo "" || {!(_focus select 0)} || {_focus isNotEqualTo GVAR(focusBuilt)}) exitWith {};

if (([_kit] call EFUNC(compat_efak,roomMode)) isNotEqualTo "cells") exitWith {};

([_display] call EFUNC(compat_efak,arsenalControls)) params [["_list", controlNull], "", ["_arrows", []]];

if (isNull _list) exitWith {};

if (_pass < 0) then {
    GVAR(ungreyPass) = GVAR(ungreyPass) + 1;
    _pass = GVAR(ungreyPass);
};

// The answers kept for the kit as it is now; anything it depends on changed, they are asked anew.
private _state = [_kit] call EFUNC(compat_efak,arsenalState);

if ((GVAR(kitVerdicts) select 0) isNotEqualTo _state) then {
    GVAR(kitVerdicts) = [_state, createHashMap];
};

private _asked = GVAR(kitVerdicts) select 1;

// 1 one more fits, 0 it does not, -1 not for the panel to say (no class).
private _fnc_fits = {
    params ["_class"];

    if (_class isEqualTo "") exitWith {-1};

    private _key = toLowerANSI _class;
    private _known = _asked get _key;

    if (!isNil "_known") exitWith {_known};

    private _fits = parseNumber ((([_kit, _class, 1] call EFUNC(compat_efak,canPackNew)) select 0) > 0);

    _asked set [_key, _fits];

    _fits
};

// The "+" of the row picked first: off where no cell is free for its item.
if (_from == 0) then {
    private _picked = lnbCurSelRow _list;
    private _plus = _display displayCtrl (_arrows param [1, -1]);

    if (
        _picked >= 0 && {!isNull _plus} && {ctrlEnabled _plus} && {(_list lnbValue [_picked, 2]) != 1}
        && {([_list lnbData [_picked, 0]] call _fnc_fits) == 0}
    ) then {
        _plus ctrlEnable false;
    };
};

private _size = (lnbSize _list) select 0;
private _row = _from;
private _until = diag_tickTime + UNGREY_BUDGET;

while {_row < _size && {diag_tickTime < _until}} do {
    if ((_list lnbValue [_row, 2]) != 1) then {
        private _fit = [_list lnbData [_row, 0]] call _fnc_fits;

        if (_fit >= 0) then {
            private _alpha = [KIT_GREY_ALPHA, 1] select (_fit == 1);
            private _color = _list lnbColor [_row, 1];

            if ((_color param [3, 1]) != _alpha) then {
                _color set [3, _alpha];
                _list lnbSetColor [[_row, 1], _color];
                _list lnbSetColor [[_row, 2], [1, 1, 1, _alpha]];
            };
        };
    };

    _row = _row + 1;
};

// Not done within the budget: the rest a frame later.
if (_row < _size) then {
    [{_this call FUNC(ungreyKit)}, [_display, _row, _pass]] call EFUNC(gui,later);
};
