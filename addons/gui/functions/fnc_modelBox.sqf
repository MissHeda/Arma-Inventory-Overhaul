#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The box a model's visible shape takes, axis by axis - for framing a weapon on its card (fnc_cardScene). Arma's own box of a weapon
 * model is no use for that: most of them carry a helper point a metre or two off the gun, so the MX measured 4 m high and the P07's
 * middle lay 47 cm beside the pistol (measured in game, 0.6.112). Each axis is taken from the first of these that is sane there -
 * the visual LOD, the Geometry LOD, the Memory LOD - sane meaning no point farther than a helper's metre from the model's origin.
 *
 * Arguments:
 * 0: A simple object of the model <OBJECT>
 *
 * Return Value:
 * [[x, y, z] least, [x, y, z] most] in model space <ARRAY>
 *
 * Example:
 * [_probe] call aio_gui_fnc_modelBox;
 *
 * Public: No
 */

params [["_probe", objNull, [objNull]]];

if (isNull _probe) exitWith {[[-0.3, -0.05, -0.1], [0.3, 0.05, 0.1]]};

private _candidates = [0 boundingBoxReal _probe, boundingBoxReal [_probe, "Geometry"], boundingBoxReal [_probe, "Memory"]];
private _least = [];
private _most = [];

{
    private _axis = _x;
    private _picked = [];

    {
        _x params [["_low", [0, 0, 0]], ["_high", [0, 0, 0]]];

        private _from = _low param [_axis, 0];
        private _to = _high param [_axis, 0];

        if ((_to - _from) > 0.001 && {(_to - _from) < 1.9} && {((abs _from) max (abs _to)) < 0.97}) exitWith {
            _picked = [_from, _to];
        };
    } forEach _candidates;

    if (_picked isEqualTo []) then {
        _picked = [[-0.3, -0.05, -0.1] select _axis, [0.3, 0.05, 0.1] select _axis];
    };

    _least pushBack (_picked select 0);
    _most pushBack (_picked select 1);
} forEach [0, 1, 2];

[_least, _most]
