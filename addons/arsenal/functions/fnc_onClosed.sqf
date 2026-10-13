#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal's display closes (ace_arsenal_displayClosed, raised first thing in its unload, while ACE's
 * unit is still known): the engine lets go of it (einv_gui_fnc_onUnload - the next window, the inventory,
 * has no hooks again), the panel's state is forgotten, and a helper that carried a vanilla box's items
 * (fnc_openBI) is deleted a frame later, once ACE is done with it. So is the staging space (fnc_staging)
 * with whatever still lies in it: it was for this fitting only, as its caption and the hint line said.
 *
 * If the soldier walks off with more in a uniform, vest or backpack than its grid has room for - a loadout
 * brought it, say - it is said once more on the screen (fnc_reportOverflow). Not in the Eden editor, where
 * ACE dressed a copy.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_onClosed;
 *
 * Public: No
 */

disableSerialization;

// The engine is let go of whether or not its frame already saw the display go: only this takes its hooks
// away.
if (GVAR(attached)) then {
    GVAR(attached) = false;
    call EFUNC(gui,onUnload);
};

uiNamespace setVariable [QGVAR(display), displayNull];

GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;
GVAR(snapshot) = [objNull, createHashMap];
GVAR(cargoPending) = false;
GVAR(dirty) = false;
GVAR(dragZone) = "";
GVAR(listPress) = [];
GVAR(watch) = [];
GVAR(scrollHold) = [];
GVAR(ctrlHeld) = false;
GVAR(stagingCount) = 0;

{
    if (!isNull _x) then {
        [{deleteVehicle (_this select 0)}, [_x]] call EFUNC(gui,later);
    };
} forEach [GVAR(biHelper), GVAR(staging)];

GVAR(biHelper) = objNull;
GVAR(staging) = objNull;

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (isNull _center || {is3DEN} || {!GVAR(ready)}) exitWith {};

[{
    params ["_center"];

    [_center, displayNull] call FUNC(reportOverflow);
}, [_center]] call EFUNC(gui,later);
