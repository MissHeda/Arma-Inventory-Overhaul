#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The wizard's display loaded: works out who may save where (fnc_canEdit), takes the setup in use as the
 * draft (fnc_getActive), and draws the window - a pane of Enhanced First Aid Kits' glass in the middle of
 * the screen with its header, the steps, the step itself and the footer (fnc_showStep).
 *
 * Everything is made inside the wizard's own controls group, never on the display itself: the inventory's
 * kit keeps what it makes on a display in a list its next build deletes (einv_gui_fnc_uiCreate).
 *
 * Opened by the pause menu's entry, nobody said how (fnc_open does): direct mode, at the first step.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_setup_fnc_onLoad;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

(uiNamespace getVariable [QGVAR(openArgs), []]) params [["_mode", "direct", [""]], ["_step", 0, [0]], ["_focusClass", "", [""]]];

uiNamespace setVariable [QGVAR(openArgs), nil];
uiNamespace setVariable [QGVAR(display), _display];
uiNamespace setVariable [QGVAR(deferred), []];
uiNamespace setVariable [QGVAR(popover), []];
uiNamespace setVariable [QGVAR(layer), controlNull];
uiNamespace setVariable [QGVAR(frame), []];
uiNamespace setVariable [QGVAR(content), controlNull];
uiNamespace setVariable [QGVAR(editAreas), []];

// The rules engine comes from the items addon, the window's kit from the gui addon. Without them there is
// nothing to show: closed again a moment later, not inside its own onLoad.
if (isNil QEFUNC(items,parseRules) || {isNil QEFUNC(items,writeRules)} || {isNil QEFUNC(items,compileRules)} || {isNil QEFUNC(gui,uiPanel)}) exitWith {
    ERROR("The setup wizard needs the rules engine (einv_items) and the window's kit (einv_gui) - closed again.");

    [{(uiNamespace getVariable [QGVAR(display), displayNull]) closeDisplay 2}] call FUNC(defer);
};

GVAR(mode) = _mode;
GVAR(theme) = call EFUNC(gui,theme);
GVAR(target) = [_mode] call FUNC(canEdit);
GVAR(readOnly) = !(GVAR(target) getOrDefault ["canSave", false]);

// Forced over the mission already, it stays so unless switched off: the switch starts as the source is.
GVAR(override) = (GVAR(target) getOrDefault ["override", false]) && {(GVAR(target) getOrDefault ["priority", 0]) >= 2};
GVAR(cleanOverride) = GVAR(override);

GVAR(focus) = _focusClass;
GVAR(selection) = createHashMap;
GVAR(stepKey) = {false};
GVAR(undo) = [];
GVAR(redo) = [];
GVAR(reviewDrafts) = false;
GVAR(reviewText) = false;
GVAR(exportMode) = 0;
GVAR(textEdit) = false;
GVAR(importText) = "";
GVAR(draftPick) = "";
GVAR(changeRefs) = createHashMap;
GVAR(banner) = false;
GVAR(hint) = ["", "text2"];
GVAR(listState) = createHashMap;
GVAR(cellWork) = createHashMap;
GVAR(itemWork) = createHashMap;
GVAR(sameAs) = createHashMap;
GVAR(treeState) = createHashMap;
GVAR(editScope) = createHashMap;
GVAR(classImportText) = "";

// The draft starts as what is in use there (fnc_getActive). What the source it saves to holds right now
// is kept beside it: should that change before Save, someone else saved in between (fnc_save).
private _active = call FUNC(getActive);

GVAR(origin) = _active;
GVAR(originSource) = call FUNC(targetValue);

[_active] call FUNC(setDraft);

// Taken from the setup in effect, it may not be stored where the wizard saves: Save is offered all the
// same (fnc_sourceEmpty).
GVAR(clean) = GVAR(draftText);
GVAR(sourceEmpty) = call FUNC(sourceEmpty);

// The pane, on whole pixels: every surface on it is see-through and must meet its neighbours exactly.
private _root = _display ctrlCreate ["EINV_Group", -1];
_root ctrlSetPosition [SNAP_X(WIZ_X), SNAP_Y(WIZ_Y), SNAP_W(WIZ_W), SNAP_H(WIZ_H)];
_root ctrlCommit 0;

uiNamespace setVariable [QGVAR(root), _root];

(ctrlPosition _root) params ["", "", "_width", "_height"];

[
    _display, _root, [0, 0, _width, _height],
    GVAR(theme) getOrDefault ["panel", [0.04, 0.045, 0.055, 0.85]], GVAR(theme) getOrDefault ["radius", 0]
] call EFUNC(gui,uiPanel);

// Somewhere for the cursor to go after every redraw: a button no one sees. Otherwise a control that had
// it and went with the redraw hands it on - perhaps to a text field, and the keys type into it.
uiNamespace setVariable [QGVAR(sink), [_display, "EINV_Hitbox", _root, [0, 0, 0, 0]] call EFUNC(gui,uiCreate)];

_display displayAddEventHandler ["KeyDown", {_this call FUNC(onKeyDown)}];
_display displayAddEventHandler ["KeyUp", {_this call FUNC(onKeyUp)}];
_display displayAddEventHandler ["MouseMoving", {call FUNC(onMouse)}];
_display displayAddEventHandler ["MouseHolding", {call FUNC(onMouse)}];

// A stroke of paint on the Containers step's drawing ends with the button's release, wherever that is
// (fnc_uiCanvas).
_display displayAddEventHandler ["MouseButtonUp", {
    uiNamespace setVariable [QGVAR(canvasStroke), []];

    false
}];

[_step] call FUNC(showStep);
