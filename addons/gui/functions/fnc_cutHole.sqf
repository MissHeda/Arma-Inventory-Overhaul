#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lets the game's own view show through the window where the modding view films the weapon with the main camera
 * (fnc_drawInspect, fnc_inspect3D): every control of the window that reaches into the given area is hidden - the card's
 * band of the content, so the loot column under the card goes whole. Only the window's own controls on the display, not
 * those in the inspect card, and never the name at the mouse. The dim layer leaves out the hole itself: the world around
 * the window stays as dim as ever, the weapon in the hole is not (fnc_dimAround - drawn by the next build, under
 * everything). With no area, everything hidden shows again and the dim layer is whole once more.
 *
 * A build makes the window anew, its controls shown: the card cuts the hole again after it (fnc_drawTopLayer).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The area [x, y, w, h] on the screen to clear, [] to show everything again <ARRAY> (default: [])
 * 2: The hole [x, y, w, h] on the screen the dim layer leaves out <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.2, 0.3, 0.8, 0.4]] call aio_gui_fnc_cutHole;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_hole", [], [[]]], ["_clear", [], [[]]]];

// The dim layer's hole: drawn by a build (fnc_dimAround), so one comes when it changed - a frame later, as this runs inside
// one.
if ((uiNamespace getVariable [QGVAR(dimHole), []]) isNotEqualTo _clear) then {
    uiNamespace setVariable [QGVAR(dimHole), +_clear];

    if (!isNull _display) then {
        [{[] call FUNC(buildSoon)}] call FUNC(later);
    };
};

{
    if (!isNull _x) then {
        _x ctrlShow true;
    };
} forEach (uiNamespace getVariable [QGVAR(holeHidden), []]);

uiNamespace setVariable [QGVAR(holeHidden), []];

if (isNull _display) exitWith {};

if (count _hole < 4) exitWith {};

_hole params ["_holeX", "_holeY", "_holeW", "_holeH"];

private _keep = [
    uiNamespace getVariable [QGVAR(inspectGroup), controlNull],
    uiNamespace getVariable [QGVAR(tooltip), controlNull],
    uiNamespace getVariable [QGVAR(tipShown), controlNull]
] + (uiNamespace getVariable [QGVAR(dimStrips), []]);
private _hidden = [];

{
    if (!isNull ctrlParentControlsGroup _x || {ctrlIDC _x in [IDC_DIM, IDC_FIRST]} || {_x in _keep} || {!ctrlShown _x}) then {continue};

    (ctrlPosition _x) params ["_ctrlX", "_ctrlY", "_ctrlW", "_ctrlH"];

    if (_ctrlX < _holeX + _holeW && {_holeX < _ctrlX + _ctrlW} && {_ctrlY < _holeY + _holeH} && {_holeY < _ctrlY + _ctrlH}) then {
        _x ctrlShow false;
        _hidden pushBack _x;
    };
} forEach (allControls _display);

uiNamespace setVariable [QGVAR(holeHidden), _hidden];
