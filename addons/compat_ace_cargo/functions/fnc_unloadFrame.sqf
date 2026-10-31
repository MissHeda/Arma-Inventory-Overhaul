#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Every frame of an unloading (fnc_startUnload): stops it when the window is gone or ACE would not unload
 * it any more - the same per-frame condition ACE's own progress bar applies, without looking for a free
 * place every frame -, finishes it when the time is up, else moves the bar and its seconds on.
 *
 * Arguments:
 * 0: Arguments of the handler, unused <ARRAY>
 * 1: Handle of the handler <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [aio_compat_ace_cargo_fnc_unloadFrame, 0, []] call CBA_fnc_addPerFrameHandler;
 *
 * Public: No
 */

GVAR(unloading) params [["_item", objNull], ["_holder", objNull], ["_start", 0], ["_duration", 0]];

// Nothing is being unloaded any more (it was stopped meanwhile): the handler has no work.
if (GVAR(unloading) isEqualTo []) exitWith {
    ["", false] call FUNC(stopUnload);
};

// The window closed, the player went down or away: stopped, quietly - as ACE's bar stops on Escape.
if (isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])) exitWith {
    ["", false] call FUNC(stopUnload);
};

// ACE's own per-frame condition, without the search for a free place.
if !([_item, _holder, ACE_player, false, true] call ACEFUNC(cargo,canUnloadItem)) exitWith {
    [[localize "STR_ACE_Cargo_UnloadingFailed", [_item, true] call ACEFUNC(cargo,getNameItem)] call FUNC(aceText), true] call FUNC(stopUnload);
};

private _fraction = (CBA_missionTime - _start) / (_duration max 0.01);

if (_fraction >= 1) exitWith {
    [_holder, _item] call FUNC(finishUnload);
};

(uiNamespace getVariable [QGVAR(bar), []]) params [["_fill", controlNull], ["_label", controlNull], ["_rect", []]];

if (!isNull _fill && {_rect isNotEqualTo []}) then {
    _rect params ["_left", "_top", "_width", "_height"];

    _fill ctrlSetPosition [_left, _top, (_width * _fraction) max pixelW, _height];
    _fill ctrlCommit 0;
    _label ctrlSetText format [LLSTRING(Unloading), ceil (_duration - (CBA_missionTime - _start))];
};
