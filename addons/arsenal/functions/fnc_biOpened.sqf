#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The vanilla Virtual Arsenal opened and stays (arsenalOpened, fnc_biSafetyNet): the grid panel moves in as it does on ACE
 * Arsenal (fnc_onOpened) - the open uniform's, vest's or backpack's grid beside the list on the right, items dragged out of
 * that list into it, the staging space, the menu and the wheel. Without ACE this is the arsenal's grid; with ACE it is the
 * setting "Vanilla with grids", or a vanilla arsenal a mission keeps for itself.
 *
 * What ACE tells by its events, the panel looks for here (fnc_biWatch). BI's display closes with its own Close and Escape:
 * nothing is asked first, and what does not fit goes on to the soldier's next container with room, or is named, once it
 * closed (fnc_biLeaveAlone). One arsenal at a time: an ACE Arsenal still open keeps the panel.
 *
 * Arguments:
 * 0: The vanilla arsenal's display (RscDisplayArsenal) <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [uiNamespace getVariable "RscDisplayArsenal"] call aio_arsenal_fnc_biOpened;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (isNull _display || {is3DEN} || {!isNull (uiNamespace getVariable [QGVAR(display), displayNull])}) exitWith {};

GVAR(kind) = "bi";
GVAR(biSeen) = [];

[_display] call FUNC(initState);

_display displayAddEventHandler ["KeyDown", {_this call FUNC(onKey)}];
_display displayAddEventHandler ["KeyUp", {(_this + [false]) call FUNC(onKey)}];
_display displayAddEventHandler ["Unload", {call FUNC(onClosed)}];

// The cargo lists - one per tab of the right side, the one of the open tab enabled - each with the "-" and "+" over its row.
{
    private _list = _display displayCtrl (BI_IDC_LIST + _x);

    if (isNull _list) then {continue};

    _list setVariable [QGVAR(arrows), [BI_IDC_MINUS, BI_IDC_PLUS]];
    _list ctrlAddEventHandler ["LBSelChanged", {
        GVAR(listSel) = [_this select 1, diag_frameNo, ctrlIDC (_this select 0)];
    }];
    _list ctrlAddEventHandler ["MouseButtonDown", {
        params ["_list", "_button", "", "", ["_shift", false]];

        [_list, _button, _shift] call FUNC(onListPress);
    }];
} forEach BI_CARGO_TABS;

// The engine a frame later, once BI's own start is done; once more if another window of the inventory is still closing.
private _fnc_attach = {
    params ["_display", "_tries", "_fnc_attach"];

    if (isNull _display || {GVAR(attached)}) exitWith {};

    private _current = uiNamespace getVariable [QEGVAR(gui,display), displayNull];

    if (!isNull _current && {_current isNotEqualTo _display}) exitWith {
        if (_tries > 0) exitWith {
            [_fnc_attach, [_display, _tries - 1, _fnc_attach]] call EFUNC(gui,later);
        };

        WARNING("Another window of the inventory is open - the vanilla arsenal opens without the grid panel.");
    };

    private _center = call FUNC(center);

    if (isNull _center || {!local _center}) exitWith {};

    if !([_display, _center, objNull, objNull, call FUNC(hooks), "draw3d"] call EFUNC(gui,attach)) exitWith {
        WARNING("The inventory's engine did not attach to the vanilla arsenal - it opens without the grid panel.");
    };

    GVAR(attached) = true;

    [] call FUNC(snapshot);
    [] call FUNC(settle);
};

[_fnc_attach, [_display, 1, _fnc_attach]] call EFUNC(gui,later);
