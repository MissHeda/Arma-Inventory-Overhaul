#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The rules in use changed while the wizard is open (aio_items_rulesChanged): saved from here, by an admin, by a
 * mission script. The server settings follow changes of their own, setting by setting (fnc_onSettingChanged).
 *
 * With the rules unchanged in the draft, the wizard simply shows the new ones - the draft's server settings stay
 * as they are. With changes of its own, it keeps them and shows a banner instead - Reload, or keep mine; Save then
 * asks what to do (fnc_save). Who may save is worked out anew as well: an admin may just have logged in or out.
 *
 * Not in menu mode: there the wizard works on what CBA's menu holds, which nothing outside it changes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_setup_fnc_onRulesChanged;
 *
 * Public: No
 */

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};
if (GVAR(mode) isEqualTo "menu") exitWith {};

GVAR(target) = [GVAR(mode)] call FUNC(canEdit);
GVAR(readOnly) = !(GVAR(target) getOrDefault ["canSave", false]);

if !(GVAR(target) getOrDefault ["override", false]) then {
    GVAR(override) = false;
};

private _active = [] call FUNC(getActive);
private _now = [[_active] call EFUNC(items,parseRules)] call EFUNC(items,writeRules);

switch (true) do {
    // What changed is what this draft says already - saved from here, or someone had the same idea.
    case (_now isEqualTo GVAR(draftText)): {
        GVAR(origin) = _active;
        GVAR(originSource) = [] call FUNC(targetValues);
        GVAR(clean) = GVAR(draftText);
        GVAR(sourceEmpty) = [] call FUNC(sourceEmpty);
    };
    // The rules were not touched here: the new ones are taken, the draft before them onto the undo stack.
    case (GVAR(draftText) isEqualTo GVAR(clean)): {
        GVAR(undo) pushBack [GVAR(draftText), GVAR(draftSettingsText)];
        GVAR(redo) = [];

        if (count GVAR(undo) > UNDO_DEPTH) then {
            GVAR(undo) deleteAt 0;
        };

        GVAR(origin) = _active;
        GVAR(originSource) = [] call FUNC(targetValues);

        [_active] call FUNC(setDraft);

        GVAR(clean) = GVAR(draftText);
        GVAR(sourceEmpty) = [] call FUNC(sourceEmpty);
        GVAR(banner) = false;
    };
    default {
        GVAR(banner) = true;
    };
};

[GVAR(step)] call FUNC(showStep);
