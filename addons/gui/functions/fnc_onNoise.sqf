#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Someone near loots (the CBA event einv_gui_noise, fnc_sendNoise): the resolved layers play where his
 * hands are, on this machine only. Heard where the camera is - a Zeus far away or a spectator does not get a
 * sound from the other end of the map -, never one's own (but for the single player test,
 * einv_gui_noiseSelf = true in the debug console).
 *
 * Arguments:
 * 0: The looter <OBJECT>
 * 1: Layers, [[file, volume, pitch, offset, length, delay], ...] <ARRAY>
 * 2: How far it carries, in metres <NUMBER>
 * 3: The looter is indoors <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_looter, _layers, 12, false] call einv_gui_fnc_onNoise;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_layers", [], [[]]], ["_range", 10, [0]], ["_inside", false, [false]]];

if (isNull _unit || {_unit isEqualTo ACE_player && {!(missionNamespace getVariable [QGVAR(noiseSelf), false])}}) exitWith {};

// Heard where the camera is.
if ((positionCameraToWorld [0, 0, 0]) distance _unit > _range + NOISE_MARGIN) exitWith {};

{
    if (_x isEqualTypeParams ["", 0, 0, 0, 0, 0]) then {
        [_x, 1, _unit, _range min 30, _inside] call FUNC(playLayer);
    };
} forEach (_layers select [0, 3]);
