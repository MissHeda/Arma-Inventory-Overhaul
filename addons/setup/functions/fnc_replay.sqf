#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Someone else saved the setup while the wizard was open, and the player chose to keep their edits on top
 * of it: the new setup in use becomes the base, and the player's own edits since the wizard opened are
 * done to it again, statement by statement - what they added is added, what they took away is taken
 * away, and a header (preset, cell size) they changed is theirs - and server setting by server setting: a
 * setting they changed is theirs, one they took back to its default is the default. Everything else stays as
 * the other person saved it.
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


// The server settings, by setting: what the draft has over what was in use when the wizard opened.
private _activeSettingsText = [SETTINGS_SETTING] call FUNC(getActive);
private _activeSettings = ([_activeSettingsText] call EFUNC(main,parseSettings)) select 0;
private _originSettings = ([GVAR(originSettings)] call EFUNC(main,parseSettings)) select 0;
private _mergedSettings = +_activeSettings;

{
    private _name = _x;
    private _mine = GVAR(draftSettings) get _name;
    private _was = _originSettings get _name;

    if (isNil "_was" || {_mine isNotEqualTo _was}) then {
        _mergedSettings set [_name, _mine];
    };
} forEach (keys GVAR(draftSettings));

{
    if !(_x in GVAR(draftSettings)) then {
        _mergedSettings deleteAt _x;
    };
} forEach (keys _originSettings);

GVAR(origin) = _active;
GVAR(originSettings) = [([_activeSettingsText] call EFUNC(main,parseSettings)) select 0] call EFUNC(main,writeSettings);
GVAR(originSource) = [] call FUNC(targetValues);
GVAR(clean) = _active call _fnc_canonical;
GVAR(cleanSettings) = GVAR(originSettings);
GVAR(sourceEmpty) = [] call FUNC(sourceEmpty);
GVAR(banner) = false;

[[(([_head] + _statements) select {_x isNotEqualTo ""}) joinString ", "] call EFUNC(items,parseRules), false] call FUNC(commit);
[_mergedSettings, false] call FUNC(commitSettings);
[GVAR(step)] call FUNC(showStep);

[LLSTRING(Conflict_Replayed), "accent"] call FUNC(setHint);
