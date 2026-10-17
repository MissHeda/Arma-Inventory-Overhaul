#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Folds a section of a column away to its caption, or opens it again - a click on its caption tab
 * (fnc_drawSection). What is kept per container for as long as the mission runs (GVAR(collapsed)) is the
 * change from how the section starts: own sections start open, the crates found lying around start
 * folded (their "folded"), so a container in the list is one the player turned the other way round.
 * Open kits have windows of their own (fnc_drawWindow), which do not fold. A window that attached may keep
 * its folds itself (the "fold" hook - the Arsenal's panel, per container class while ACE's window is open):
 * then the list is left alone and the window is only drawn again.
 *
 * Arguments:
 * 0: The section's container <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [backpackContainer player] call einv_gui_fnc_toggleSection;
 *
 * Public: No
 */

disableSerialization;

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {};

// The window that attached keeps its own folds: the inventory's, kept for the mission, stay as they were.
if ((["fold", [_container], false] call FUNC(hook)) isNotEqualTo true) then {
    private _index = GVAR(collapsed) find _container;

    if (_index >= 0) then {
        GVAR(collapsed) deleteAt _index;
    } else {
        GVAR(collapsed) pushBack _container;
    };

    // Containers that are gone go with them.
    GVAR(collapsed) = GVAR(collapsed) select {_x isEqualType objNull && {!isNull _x}};
};

// The state is changed; the window is built once for a run of clicks (fnc_buildSoon).
[] call FUNC(buildSoon);
