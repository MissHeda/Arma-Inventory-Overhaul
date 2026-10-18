#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE's "+" or "-" for the open uniform, vest or backpack (ace_arsenal_cargoChanged) - raised after ACE
 * added or took out, before it tells what really changed (ace_arsenal_itemsChanged) and greys its list.
 *
 * ACE adds with the engine's own commands, which refuse by the container's weight (maximumLoad). Cells are
 * the only limit here, so whatever of the request did not land is put in past it while the grid has a free
 * spot (einv_storage_fnc_addNew), ACE's list is put right (fnc_syncAce) and ACE is told (fnc_tellAce);
 * with no spot for it, the message says what room to make (fnc_sayNoRoom). What did land but has no cell is taken back out by the follow-up of
 * itemsChanged (fnc_reconcile).
 *
 * A frame later the list and the panel are looked at again (fnc_settle) - and an ACE without itemsChanged
 * gets its follow-up there.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Class <STRING>
 * 2: 1 added, -1 taken out <NUMBER>
 * 3: Shift - five at once <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, "ACE_fieldDressing", 1, false] call einv_arsenal_fnc_onCargoChanged;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_item", "", [""]], ["_addOrRemove", 0, [0]], ["_shift", false, [false]]];

if (!GVAR(attached)) exitWith {};

[] call FUNC(keepPlaces);

GVAR(itemsSeen) = false;
GVAR(cargoPending) = true;
[] call FUNC(settle);

if (_addOrRemove <= 0 || {_item isEqualTo ""}) exitWith {};

(call FUNC(selected)) params ["_id", "_container"];

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (isNull _container || {!local _center}) exitWith {};

GVAR(snapshot) params ["_known", "_counts"];

// The container was swapped a moment ago: nothing to tell what landed from.
if (_known isNotEqualTo _container) exitWith {};

private _asked = [1, 5] select _shift;
private _before = _counts getOrDefault [toLowerANSI _item, 0];
private _now = [_container, _item] call EFUNC(storage,countClass);
private _missing = _asked - ((_now - _before) max 0);

if (_missing <= 0) exitWith {};

private _why = "";

for "_i" from 1 to _missing do {
    _why = [_container, _item, 1] call EFUNC(storage,addNew);

    if (_why isNotEqualTo "") exitWith {};
};

private _after = [_container, _item] call EFUNC(storage,countClass);

if (_after > _now) then {
    // ACE wrote its count before it raised this event.
    [_display] call FUNC(syncAce);
    [_item, _now, _after] call FUNC(tellAce);
};

if (_why isEqualTo "NoRoom" && {_after - _before < _asked}) then {
    [_display, _id, _item] call FUNC(sayNoRoom);
};
