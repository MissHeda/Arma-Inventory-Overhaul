#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Sets ACE's globals for the session, as ACE's own window does when it opens, from the arguments
 * fnc_openWindow handed over: the unit, the box, the lists of what is offered (copied, flattened, with the
 * unique ones added in ACE's order), the shared and default loadouts, the current face, voice and insignia,
 * the favorites. Nothing of this addon's own is worked out from the lists yet - the handlers of
 * ace_arsenal_displayOpened may still change them (fnc_readSupply).
 *
 * The order of the lists is ACE's: the box's list copied, flattened, the flat list kept as "everything
 * offered or carried", and only then the unique items added - flattening again after that would turn the
 * unique items into offered ones.
 *
 * Arguments:
 * 0: What fnc_openWindow stored: [box, unit, full, virtual items, source] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * (uiNamespace getVariable "einv_arsenal_openArgs") call einv_arsenal_fnc_sessionStart;
 *
 * Public: No
 */

params [
    ["_box", objNull, [objNull]],
    ["_center", objNull, [objNull]],
    ["_full", false, [false]],
    ["_items", createHashMap, [createHashMap]],
    ["_source", "ace", [""]]
];

// ----- This addon's own state -----

GVAR(box) = _box;
GVAR(center) = _center;
GVAR(full) = _full;
GVAR(source) = _source;

GVAR(hidden) = false;
GVAR(targetSlot) = "";
GVAR(targetContainer) = objNull;
GVAR(armed) = ["", -1];
GVAR(lastWeapons) = [];
GVAR(lastGear) = [];
GVAR(uniqueCache) = createHashMap;
GVAR(pendingFlash) = [];

// What the catalog worked out for the last session (the category lists, what the soldier carried) belongs
// to that session's supply and unit.
GVAR(lists) = createHashMap;
GVAR(carried) = createHashMap;

// What the last session checked in the Loadouts view was checked against that session's supply, and what
// was picked there was picked for that soldier.
GVAR(verified) = createHashMap;
GVAR(verifyQueue) = [];
GVAR(loadoutsDirty) = false;
GVAR(loadoutSelected) = "";
GVAR(loadoutName) = "";

// ----- ACE's session, as onArsenalOpen sets it -----

ACEGVAR(arsenal,center) = _center;
ACEGVAR(arsenal,currentBox) = _box;
ACEGVAR(arsenal,mouseButtonState) = [[], []];

// The lists of other players' and the editor's loadouts, as ACE makes them when its display opens.
if (isNil QACEGVAR(arsenal,sharedLoadoutsNamespace)) then {
    ACEGVAR(arsenal,sharedLoadoutsNamespace) = true call CBA_fnc_createNamespace;
    publicVariable QACEGVAR(arsenal,sharedLoadoutsNamespace);
};

if (isNil {ACEGVAR(arsenal,sharedLoadoutsNamespace) getVariable QACEGVAR(arsenal,sharedLoadoutsVars)}) then {
    ACEGVAR(arsenal,sharedLoadoutsNamespace) setVariable [QACEGVAR(arsenal,sharedLoadoutsVars), [], true];
};

if (isNil QACEGVAR(arsenal,defaultLoadoutsList)) then {
    if (is3DEN) then {
        ACEGVAR(arsenal,defaultLoadoutsList) = QACEGVAR(arsenal,DummyCategory) get3DENMissionAttribute QACEGVAR(arsenal,DefaultLoadoutsListAttribute);

        if (isNil QACEGVAR(arsenal,defaultLoadoutsList)) then {
            ACEGVAR(arsenal,defaultLoadoutsList) = [];
        };
    } else {
        ACEGVAR(arsenal,defaultLoadoutsList) = [];
    };
};

if (isNil {profileNamespace getVariable QACEGVAR(arsenal,saved_loadouts)}) then {
    profileNamespace setVariable [QACEGVAR(arsenal,saved_loadouts), []];
};

// What is offered: a full arsenal offers the game's whole config, anything else the list it was given.
ACEGVAR(arsenal,virtualItems) = _items;

if (_full) then {
    ACEGVAR(arsenal,virtualItemsFlat) = +(uiNamespace getVariable [QACEGVAR(arsenal,configItemsFlat), createHashMap]);
    ACEGVAR(arsenal,ignoredVirtualItems) = true;
} else {
    call ACEFUNC(arsenal,updateVirtualItemsFlat);
    ACEGVAR(arsenal,ignoredVirtualItems) = nil;
};

// Includes items not in the arsenal but carried (updateUniqueItemsList adds them).
ACEGVAR(arsenal,virtualItemsFlatAll) = +ACEGVAR(arsenal,virtualItemsFlat);

ACEGVAR(arsenal,currentFace) = face _center;
ACEGVAR(arsenal,currentVoice) = (speaker _center) call ACEFUNC(common,getConfigName);
ACEGVAR(arsenal,currentInsignia) = _center call BIS_fnc_getUnitInsignia;

ACEGVAR(arsenal,currentAction) = "Stand";
ACEGVAR(arsenal,shiftState) = false;

ACEGVAR(arsenal,currentStatPage) = 0;
ACEGVAR(arsenal,statsInfo) = [true, controlNull, nil, nil];

ACEGVAR(arsenal,currentActionPage) = 0;
ACEGVAR(arsenal,actionsInfo) = [controlNull, nil, nil];

call ACEFUNC(arsenal,updateCurrentItemsList);

// The favorites, shown or not at first as the setting says (ACE's first run of buttonFavorites).
ACEGVAR(arsenal,favoritesOnly) = missionNamespace getVariable [QACEGVAR(arsenal,defaultToFavorites), false];
ACEGVAR(arsenal,favorites) = profileNamespace getVariable [QACEGVAR(arsenal,favorites), createHashMap];

// What the unit carries and the arsenal does not offer is unique.
call ACEFUNC(arsenal,updateUniqueItemsList);

// Whether the unit is somebody else's: a script's other unit, a Zeus's remote controlled one. The editor
// has no player, so ACE leaves it unset there.
if (!is3DEN) then {
    ACEGVAR(arsenal,centerNotPlayer) = _center isNotEqualTo player;
};
