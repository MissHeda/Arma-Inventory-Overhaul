#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Ends the session: favorites are saved to the profile, every ACE global the session set is cleared exactly
 * as ACE's close clears them (ace_arsenal_virtualItemsFlat among them: Enhanced First Aid Kits treats a set
 * list as an open arsenal) and the HUD comes back.
 *
 * The ones that survive a close stay: the shared loadouts and the list of default ones (set once, shared
 * with ACE's own window), and ACE's camera position, which this window does not use.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_sessionEnd;
 *
 * Public: No
 */

// Kept for the next time, as ACE keeps them (the profile is saved by the game, as it is for ACE).
private _favorites = missionNamespace getVariable QACEGVAR(arsenal,favorites);

if (!isNil "_favorites") then {
    profileNamespace setVariable [QACEGVAR(arsenal,favorites), _favorites];
};

{
    missionNamespace setVariable [_x, nil];
} forEach [
    QACEGVAR(arsenal,camera),
    QACEGVAR(arsenal,mouseButtonState),
    QACEGVAR(arsenal,currentLeftPanel),
    QACEGVAR(arsenal,currentRightPanel),
    QACEGVAR(arsenal,leftSearchbarFocus),
    QACEGVAR(arsenal,rightSearchbarFocus),
    QACEGVAR(arsenal,liveUpdateSearch),
    QACEGVAR(arsenal,shiftState),
    QACEGVAR(arsenal,leftTabFocus),
    QACEGVAR(arsenal,rightTabFocus),
    QACEGVAR(arsenal,rightTabLnBFocus),
    QACEGVAR(arsenal,ignoreFirstSortPanelCall),
    QACEGVAR(arsenal,refreshing),
    QACEGVAR(arsenal,selectedWeaponType),
    QACEGVAR(arsenal,virtualItems),
    QACEGVAR(arsenal,virtualItemsFlat),
    QACEGVAR(arsenal,virtualItemsFlatAll),
    QACEGVAR(arsenal,currentItems),
    QACEGVAR(arsenal,currentFace),
    QACEGVAR(arsenal,currentVoice),
    QACEGVAR(arsenal,currentInsignia),
    QACEGVAR(arsenal,currentAction),
    QACEGVAR(arsenal,currentStatPage),
    QACEGVAR(arsenal,statsInfo),
    QACEGVAR(arsenal,currentActionPage),
    QACEGVAR(arsenal,actionsInfo),
    QACEGVAR(arsenal,favoritesOnly),
    QACEGVAR(arsenal,favorites),
    QACEGVAR(arsenal,center),
    QACEGVAR(arsenal,centerNotPlayer),
    QACEGVAR(arsenal,ignoredVirtualItems)
];

ACEGVAR(arsenal,currentBox) = objNull;

["einv_arsenal", []] call ACEFUNC(common,showHud);
