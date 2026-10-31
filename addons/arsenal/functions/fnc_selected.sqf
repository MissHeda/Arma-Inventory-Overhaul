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
private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];
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
