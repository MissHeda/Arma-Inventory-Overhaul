#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Lights the chosen category of a loot box's strip (fnc_drawGroupStrip): its picture in white on a lighter field, the
 * others in the quiet text colour and no field - neutral, no accent colour. "All" is lit when none is chosen. Only colours
 * are set, on the strip's own controls (the section's info "strip").
 *
 * Arguments:
 * 0: The box's container <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate] call einv_gui_fnc_paintGroupStrip;
 *
 * Public: No
 */

disableSerialization;

params [["_holder", objNull, [objNull]]];

private _infos = uiNamespace getVariable [QGVAR(sectionInfo), []];
private _info = _infos param [_infos findIf {(_x getOrDefault ["holder", objNull]) isEqualTo _holder && {"strip" in _x}}, createHashMap];

if (count _info == 0) exitWith {};

private _chosen = [_holder] call FUNC(boxGroup);

if (_chosen isEqualTo "") then {
    _chosen = "all";
};

private _theme = GVAR(theme);
private _white = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _lit = [1, 1, 1, 0.15];
private _quiet = +(_theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]);

_quiet set [3, 0.62];

// A category on another group of the strip lights the field that turns to it.
private _ids = (_info get "strip") apply {_x select 0};

{
    _x params ["_id", "_field", "_picture"];

    // A field a short last group leaves over has no id: nothing to light.
    private _on = _id isNotEqualTo "" && {_id isEqualTo _chosen || {_id isEqualTo "more" && {!(_chosen in _ids)}}};

    _picture ctrlSetTextColor ([_quiet, _white] select _on);

    [_field, [[0, 0, 0, 0], _lit] select _on] call FUNC(paintSurface);
} forEach (_info get "strip");
