#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes the setup in use again as the draft (fnc_getActive), and as what is compared at Save: after
 * someone else changed it, or when the player asks for it after such a change. The draft it replaces goes
 * onto the undo stack, so nothing typed is lost for good. Does not draw - the caller does.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_setup_fnc_reload;
 *
 * Public: No
 */

private _active = call FUNC(getActive);
private _before = GVAR(draftText);

GVAR(origin) = _active;
GVAR(originSource) = call FUNC(targetValue);

[_active] call FUNC(setDraft);

if (_before isNotEqualTo "" && {_before isNotEqualTo GVAR(draftText)}) then {
    GVAR(undo) pushBack _before;
    GVAR(redo) = [];

    if (count GVAR(undo) > UNDO_DEPTH) then {
        GVAR(undo) deleteAt 0;
    };
};

GVAR(clean) = GVAR(draftText);
GVAR(sourceEmpty) = call FUNC(sourceEmpty);
GVAR(cleanOverride) = GVAR(override);
GVAR(banner) = false;
