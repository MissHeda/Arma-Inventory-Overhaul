#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The uniform, vest or backpack whose tab is open in ACE Arsenal's left bar (ace_arsenal_currentLeftPanel)
 * - the one the panel shows and ACE's list adds to. Any other tab, no arsenal open, or that slot empty: none.
 * None either while Enhanced First Aid Kits' kits tab lies over ACE's panels (fnc_focusedKit): ACE's current tab
 * stays the one it was then, but its list is hidden under that tab's and takes nothing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [id "uniform" / "vest" / "backpack" or "", container or objNull, ACE's tab IDC or -1, where its items lie
 * in ace_arsenal_currentItems or -1, where it lies in a getUnitLoadout array or -1] <ARRAY>
 *
 * Example:
 * (call aio_arsenal_fnc_selected) params ["_id", "_container"];
 *
 * Public: No
 */

private _none = ["", objNull, -1, -1, -1];

// The vanilla arsenal: the tab whose list is enabled of its uniform, vest and backpack ones.
if (GVAR(kind) isEqualTo "bi") exitWith {
    private _display = uiNamespace getVariable [QGVAR(display), displayNull];
    private _center = call FUNC(center);

    if (isNull _display || {isNull _center}) exitWith {_none};

    private _tab = ([BI_TAB_UNIFORM, BI_TAB_VEST, BI_TAB_BACKPACK] select {ctrlEnabled (_display displayCtrl (BI_IDC_LIST + _x))}) param [0, -1];
    private _selected = switch (_tab) do {
        case BI_TAB_UNIFORM: {["uniform", uniformContainer _center, _tab, -1, LOADOUT_UNIFORM]};
        case BI_TAB_VEST: {["vest", vestContainer _center, _tab, -1, LOADOUT_VEST]};
        case BI_TAB_BACKPACK: {["backpack", backpackContainer _center, _tab, -1, LOADOUT_BACKPACK]};
        default {_none};
    };

    [_selected, _none] select (isNull (_selected select 1))
};
private _center = (call FUNC(center));
private _panel = missionNamespace getVariable [QACEGVAR(arsenal,currentLeftPanel), -1];

if (isNull _center || {!(_panel isEqualType 0)}) exitWith {_none};

if (([] call FUNC(focusedKit)) select 0) exitWith {_none};

private _selected = switch (_panel) do {
    case ARSENAL_IDC_UNIFORM: {["uniform", uniformContainer _center, _panel, ARSENAL_ITEMS_UNIFORM, LOADOUT_UNIFORM]};
    case ARSENAL_IDC_VEST: {["vest", vestContainer _center, _panel, ARSENAL_ITEMS_VEST, LOADOUT_VEST]};
    case ARSENAL_IDC_BACKPACK: {["backpack", backpackContainer _center, _panel, ARSENAL_ITEMS_BACKPACK, LOADOUT_BACKPACK]};
    default {_none};
};

if (isNull (_selected select 1)) exitWith {_none};

_selected
