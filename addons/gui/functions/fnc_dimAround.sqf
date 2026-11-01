#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The dim layer behind the window, in the look's colour - round the modding view's hole, while Modify is open
 * (uiNamespace QGVAR(dimHole), fnc_cutHole): then the layer itself is clear and four strips of the colour lie round the
 * hole, so the weapon shows undimmed and the world round the window as dim as ever. Made by fnc_build before anything
 * else on the display, so the strips lie under the columns as the layer does; the build sweeps them with everything else.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call aio_gui_fnc_dimAround;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_theme"];

private _dim = _display displayCtrl IDC_DIM;
private _color = _theme getOrDefault ["dim", [0, 0, 0, 0.35]];
private _hole = uiNamespace getVariable [QGVAR(dimHole), []];
private _strips = [];

uiNamespace setVariable [QGVAR(dimStrips), _strips];

if (count _hole < 4 || {(GVAR(inspect) param [6, false]) isNotEqualTo true}) exitWith {
    _dim ctrlSetBackgroundColor _color;
};

_dim ctrlSetBackgroundColor [0, 0, 0, 0];

_hole params ["_holeX", "_holeY", "_holeW", "_holeH"];

{
    private _strip = [_display, "AIO_PanelRect", controlNull, _x] call FUNC(uiCreate);
    _strip ctrlSetBackgroundColor _color;
    _strips pushBack _strip;
} forEach [
    [safezoneX, safezoneY, safezoneW, _holeY - safezoneY],
    [safezoneX, _holeY + _holeH, safezoneW, safezoneY + safezoneH - _holeY - _holeH],
    [safezoneX, _holeY, _holeX - safezoneX, _holeH],
    [_holeX + _holeW, _holeY, safezoneX + safezoneW - _holeX - _holeW, _holeH]
];
