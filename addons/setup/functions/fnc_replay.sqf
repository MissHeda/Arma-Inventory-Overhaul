#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Someone else saved the rules while the wizard was open, and the player chose to keep their edits on top
 * of them: the new rules in use become the base, and the player's own edits since the wizard opened are
 * done to them again, statement by statement - what they added is added, what they took away is taken
 * away, and a header (preset, cell size) they changed is theirs. Everything else stays as the other person
 * saved it. The server settings need nothing of the kind: each one changed elsewhere was followed at once,
 * and the player's own changes are still in the draft (fnc_onSettingChanged).
 *
 * Nothing is saved yet: the result is the draft, to look over and save again.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_setup_fnc_replay;
 *
 * Public: No
 */

// The engine's own wording of each text, so the same statement compares equal whoever typed it.
private _fnc_canonical = {
    [[_this] call EFUNC(items,parseRules)] call EFUNC(items,writeRules)
};

private _active = [] call FUNC(getActive);

([GVAR(origin) call _fnc_canonical] call FUNC(statements)) params ["_originHead", "_originStatements"];
([GVAR(draftText)] call FUNC(statements)) params ["_draftHead", "_draftStatements"];
([_active call _fnc_canonical] call FUNC(statements)) params ["_activeHead", "_activeStatements"];

private _added = _draftStatements - _originStatements;
private _removed = _originStatements - _draftStatements;
private _head = [_activeHead, _draftHead] select (_draftHead isNotEqualTo _originHead);
private _statements = (_activeStatements - _removed) + (_added - _activeStatements);

GVAR(origin) = _active;
GVAR(originSource) = [] call FUNC(targetValues);
GVAR(clean) = _active call _fnc_canonical;
GVAR(sourceEmpty) = [] call FUNC(sourceEmpty);
GVAR(banner) = false;

[[(([_head] + _statements) select {_x isNotEqualTo ""}) joinString ", "] call EFUNC(items,parseRules), false] call FUNC(commit);
[GVAR(step)] call FUNC(showStep);

[LLSTRING(Conflict_Replayed), "accent"] call FUNC(setHint);
