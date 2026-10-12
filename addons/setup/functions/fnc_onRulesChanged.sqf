#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The setup in use changed while the wizard is open (einv_items_rulesChanged): saved from here, by an
 * admin, by a mission script.
 *
 * With nothing changed in the draft, the wizard simply shows the new setup. With changes of its own, it
 * keeps them and shows a banner instead - Reload, or keep mine; Save then asks what to do (fnc_save).
 * Who may save is worked out anew as well: an admin may just have logged in or out.
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
 * call einv_setup_fnc_onRulesChanged;
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

if (call FUNC(isDirty)) then {
    private _active = call FUNC(getActive);
    private _now = [[_active] call EFUNC(items,parseRules)] call EFUNC(items,writeRules);

    // What changed is what this draft says already - saved from here, or someone had the same idea.
    if (_now isEqualTo GVAR(draftText)) then {
        GVAR(origin) = _active;
        GVAR(originSource) = call FUNC(targetValue);
        GVAR(clean) = GVAR(draftText);
        GVAR(sourceEmpty) = call FUNC(sourceEmpty);
    } else {
        GVAR(banner) = true;
    };
} else {
    call FUNC(reload);
};

[GVAR(step)] call FUNC(showStep);
