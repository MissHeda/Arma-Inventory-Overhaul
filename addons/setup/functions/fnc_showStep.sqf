#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws a step of the wizard, with the header and footer around it (fnc_drawFrame): the old step's group
 * goes, a new one is made, and the step's function draws into it ([display, group, theme, arguments]).
 * Every change of the draft ends here, so what is shown is always the draft as it is.
 *
 * A step that is not there (out of range) opens General instead. Drawn again in the same step,
 * its scrolling lists - the General page too - keep where they were scrolled (each one named by QGVAR(scrollId) on its
 * group), put back by fnc_restoreScroll a moment later and again until it holds: right after it is made a group does not
 * know its height yet, and the engine puts it back to the top (seen in the inventory, 2026-10-08).
 * The General page does not even go: drawn again in the same step, its content group and the scroll group in it stay
 * (fnc_drawGeneral draws the new page's controls first and deletes the old ones after), so the engine keeps the page
 * where it was and nothing shows at the top for a moment. Every other group is new and put back as said.
 *
 * Arguments:
 * 0: Step, 0 (General) to 2 (Containers) <NUMBER> (default: the open step)
 * 1: Arguments for the step <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call einv_setup_fnc_showStep;
 *
 * Public: No
 */

disableSerialization;

params [["_step", GVAR(step), [0]], ["_arguments", [], [[]]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

call FUNC(closePopover);

private _steps = GVAR(steps);

if (_step < 0 || {_step >= count _steps}) then {
    _step = 0;
};

// Where its lists were scrolled, when it is the same step drawn again.
private _scroll = createHashMap;
private _old = uiNamespace getVariable [QGVAR(content), controlNull];

if (!isNull _old && {_step == GVAR(step)}) then {
    {
        private _id = _x getVariable [QGVAR(scrollId), ""];

        if (_id isNotEqualTo "") then {
            _scroll set [_id, [((ctrlScrollValues _x) select 0) max 0, _x getVariable [QGVAR(contentH), -1], (ctrlPosition _x) select 3]];
        };
    } forEach ((allControls _display) select {ctrlType _x == CTRL_TYPE_GROUP});
};

// The General page is one scroll group, and a group made anew starts at the top and only learns its height a frame later, so
// the page would show at its top for a few frames before fnc_restoreScroll could put it back. Drawn again in the same step, the
// content group and the page in it (fnc_drawGeneral) therefore stay: only what stands on the page is drawn anew, and the scroll
// group keeps its own place the whole time.
private _keep = !isNull _old && {_step == GVAR(step)} && {((_steps select _step) select 0) isEqualTo "general"};

GVAR(step) = _step;
GVAR(drawn) = GVAR(drawn) + 1;
GVAR(stepKey) = {false};

if (!_keep) then {
    ctrlDelete _old;
};
uiNamespace setVariable [QGVAR(editAreas), (uiNamespace getVariable [QGVAR(editAreas), []]) select {!isNull _x}];
uiNamespace setVariable [QGVAR(rawState), controlNull];
uiNamespace setVariable [QGVAR(textArea), controlNull];

private _rect = [_display] call FUNC(drawFrame);
private _group = _old;

if (_keep) then {
    _group ctrlSetPosition _rect;
    _group ctrlCommit 0;
} else {
    _group = [_display, "EINV_Group", uiNamespace getVariable [QGVAR(root), controlNull], _rect] call EFUNC(gui,uiCreate);
};

uiNamespace setVariable [QGVAR(content), _group];

[_display, _group, GVAR(theme), _arguments] call (missionNamespace getVariable [(_steps select _step) select 2, {}]);

if (count _scroll > 0) then {
    [FUNC(restoreScroll), [_scroll, GVAR(drawn)], 0.03] call FUNC(defer);
};

// The top layer anew, after everything of this step: the last control of the display (fnc_topLayer).
[_display] call FUNC(topLayer);

// The cursor goes nowhere: a text field it was in went with the old step.
ctrlSetFocus (uiNamespace getVariable [QGVAR(sink), controlNull]);
