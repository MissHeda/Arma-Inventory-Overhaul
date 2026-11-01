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
 * [] call aio_arsenal_fnc_settle;
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
private _begin = diag_tickTime;
private _first = _begin;

[(call FUNC(center))] call FUNC(stageOverflow);
["settle/stageOverflow", _begin] call FUNC(noteOpen);

_begin = diag_tickTime;
[] call FUNC(snapshot);
["settle/snapshot", _begin] call FUNC(noteOpen);

_begin = diag_tickTime;
[_display] call FUNC(syncAce);
["settle/syncAce", _begin] call FUNC(noteOpen);

_begin = diag_tickTime;
[_display] call FUNC(ungrey);
["settle/ungrey (first turn)", _begin] call FUNC(noteOpen);

_begin = diag_tickTime;
[_display] call FUNC(pictures);
["settle/pictures (first turn)", _begin] call FUNC(noteOpen);

// The engine's unit is ACE's: in the Eden editor a copy ACE made after its display opened.
private _center = (call FUNC(center));

if (!isNull _center) then {
    EGVAR(gui,unit) = _center;
};

if ((uiNamespace getVariable [QEGVAR(gui,display), displayNull]) isNotEqualTo _display) exitWith {};

if (EGVAR(gui,dragging) || {EGVAR(gui,press) isNotEqualTo []}) exitWith {
    GVAR(dirty) = true;
};

_begin = diag_tickTime;
[_display] call EFUNC(gui,build);
["settle/build", _begin] call FUNC(noteOpen);
["settle (whole)", _first] call FUNC(noteOpen);
