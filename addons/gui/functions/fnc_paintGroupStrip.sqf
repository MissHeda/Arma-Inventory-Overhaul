#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Lights the chosen category of a loot box's strip (fnc_drawGroupStrip): its picture in the accent colour on a soft
 * accent field, the others in the quiet text colour and no field. "All" is lit when none is chosen. Only colours are set,
 * on the strip's own controls (the section's info "strip").
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
private _accent = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
private _soft = _theme getOrDefault ["accentSoft", [0.84, 0.54, 0.1, 0.2]];
private _quiet = +(_theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]);

_quiet set [3, 0.62];

{
    _x params ["_id", "_field", "_picture"];

    private _on = _id isEqualTo _chosen;

    _picture ctrlSetTextColor ([_quiet, _accent] select _on);

    {
        if (ctrlClassName _x isEqualTo "EINV_PanelCorner") then {
            _x ctrlSetTextColor ([[0, 0, 0, 0], _soft] select _on);
        } else {
            _x ctrlSetBackgroundColor ([[0, 0, 0, 0], _soft] select _on);
        };
    } forEach _field;
} forEach (_info get "strip");
