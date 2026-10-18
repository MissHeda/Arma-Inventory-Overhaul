#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * After ACE's events, once a frame: ACE's list is put right for what the open container holds (counts,
 * load bar, ACE's own record of it - fnc_syncAce), the rows are greyed or lit by whether the grid has a
 * spot for their item (fnc_ungrey), the rows get the pictures the rules give their items (fnc_pictures), what
 * has no cell goes to the staging space (fnc_stageOverflow), what
 * the container holds is noted for the next add (fnc_snapshot), and
 * the panel is built again for whatever tab is open now - unless something of it is held, then once it is
 * let go (fnc_onFrame).
 *
 * An ACE without ace_arsenal_itemsChanged: an add it made is followed up here (fnc_reconcile), a frame
 * after its ace_arsenal_cargoChanged.
 *
 * Called with no argument it asks for that pass, once however often it is asked within a frame.
 *
 * Arguments:
 * 0: Run it now <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_arsenal_fnc_settle;
 *
 * Public: No
 */

disableSerialization;

params [["_run", false, [false]]];

if (!_run) exitWith {
    if (GVAR(settleQueued)) exitWith {};

    GVAR(settleQueued) = true;

    [{[true] call FUNC(settle)}] call EFUNC(gui,later);
};

GVAR(settleQueued) = false;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!GVAR(attached) || {isNull _display}) exitWith {};

if (GVAR(cargoPending) && {!GVAR(itemsSeen)}) then {
    [_display] call FUNC(reconcile);
};

GVAR(cargoPending) = false;

// What found no cell, after another container was picked or on opening, goes to the staging space. Before the
// snapshot, which notes what the open container holds for the next add.
[missionNamespace getVariable [QACEGVAR(arsenal,center), objNull]] call FUNC(stageOverflow);

[] call FUNC(snapshot);
[_display] call FUNC(syncAce);
[_display] call FUNC(ungrey);
[_display] call FUNC(pictures);

// The engine's unit is ACE's: in the Eden editor a copy ACE made after its display opened.
private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (!isNull _center) then {
    EGVAR(gui,unit) = _center;
};

if ((uiNamespace getVariable [QEGVAR(gui,display), displayNull]) isNotEqualTo _display) exitWith {};

if (EGVAR(gui,dragging) || {EGVAR(gui,press) isNotEqualTo []}) exitWith {
    GVAR(dirty) = true;
};

[_display] call EFUNC(gui,build);
