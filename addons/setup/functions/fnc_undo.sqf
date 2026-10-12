#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Undoes the last change of the draft, or does again what was undone, and draws the step again. The
 * stacks hold whole texts: one step back is exactly the text before.
 *
 * Arguments:
 * 0: 1 undo, -1 redo <NUMBER> (default: 1)
 *
 * Return Value:
 * Something to undo or redo was there <BOOL>
 *
 * Example:
 * [1] call einv_setup_fnc_undo;
 *
 * Public: No
 */

params [["_direction", 1, [0]]];

private _from = [GVAR(redo), GVAR(undo)] select (_direction > 0);
private _to = [GVAR(undo), GVAR(redo)] select (_direction > 0);

if (_from isEqualTo []) exitWith {false};

private _text = _from deleteAt (count _from - 1);
_to pushBack GVAR(draftText);

[_text] call FUNC(setDraft);
[GVAR(step)] call FUNC(showStep);

true
