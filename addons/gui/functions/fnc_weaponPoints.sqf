#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where a weapon's parts sit in the inspect card's 3D scene (fnc_inspect3D), for the modding view's points
 * (fnc_drawHotspots): read from the weapon's model, made once as a simple object of its own, and carried over
 * onto the weapon lying on the scene's holder.
 *
 * Each part is looked for in the model's own names, as Arma's arsenal puts the parts on:
 *   muzzle - the muzzle proxy (weapon_slots\muzzle), else the memory point the main muzzle fires from (its
 *            muzzlePos, "usti hlavne" by default)
 *   optic  - the top proxy (weapon_slots\top)
 *   rail   - the side proxy (weapon_slots\side)
 *   bipod  - the underbarrel proxy (weapon_slots\bipod or \underbarrel)
 *   mag    - the magazine proxy (a proxy named for a magazine)
 *   mag2   - the second muzzle's muzzlePos memory point (a grenade launcher's "usti granatometu")
 * A part the model names nowhere - or that would lie farther from the weapon than its frame - is left out: the
 * modding view lists it beside the picture only.
 *
 * The weapon lies on the holder's weapon proxy, turned as that proxy is: a point of the model goes onto the holder
 * by the proxy's place and its direction and up, then into the world by the holder.
 *
 * The places in the weapon's own model are kept as well ("modelPoints").
 *
 * Arguments:
 * 0: The scene, GVAR(scene3D) <HASHMAP>
 * 1: The places in the weapon's model instead <BOOL> (default: false)
 *
 * Return Value:
 * part -> position ASL (or in the model) <HASHMAP>, or nil while the holder's model is not loaded yet - asked again later
 *
 * Example:
 * [GVAR(scene3D)] call aio_gui_fnc_weaponPoints;
 *
 * Public: No
 */

params [["_scene", createHashMap, [createHashMap]], ["_inModel", false, [false]]];

if (!_inModel && {"points" in _scene}) exitWith {_scene get "points"};

private _class = _scene getOrDefault ["class", ""];
private _config = configFile >> "CfgWeapons" >> _class;

// ----- In the weapon's model, once per scene -----
if !("modelPoints" in _scene) then {
    private _inWeapon = createHashMap;

    _scene set ["modelPoints", _inWeapon];

    private _model = [_class] call FUNC(itemModel);
    private _probe = if (_model isEqualTo "" || {!isClass _config}) then {objNull} else {createSimpleObject [_model, [0, 0, 0], true]};

    if (isNull _probe) exitWith {};

    private _visual = (selectionNames _probe) apply {toLowerANSI _x};
    private _memory = (_probe selectionNames "Memory") apply {toLowerANSI _x};

    // A proxy's place in the model: in the first resolution LOD it is in, whatever that LOD's resolution is.
    private _fnc_proxy = {
        params ["_patterns"];

        private _name = _visual param [_visual findIf {private _selection = _x; "proxy:" in _selection && {_patterns findIf {_x in _selection} >= 0}}, ""];

        if (_name isEqualTo "") exitWith {[]};

        private _found = [];

        {
            private _at = _probe selectionPosition [_name, _x];

            if (_at isNotEqualTo [0, 0, 0]) exitWith {_found = _at};
        } forEach [0, 1, 0.5, 2];

        _found
    };

    private _fnc_memory = {
        params ["_name"];

        _name = toLowerANSI _name;

        if (_name isEqualTo "" || {!(_name in _memory)}) exitWith {[]};

        _probe selectionPosition [_name, "Memory"]
    };

    // The second muzzle: the first one besides the weapon's own ("this") that loads magazines - a grenade launcher.
    private _second = (getArray (_config >> "muzzles")) select {
        _x != "this" && {_x != "safe"} && {isClass (_config >> _x)} && {(getArray (_config >> _x >> "magazines")) isNotEqualTo []}
    };
    private _mainMuzzle = getText (_config >> "muzzlePos");

    if (_mainMuzzle isEqualTo "") then {
        _mainMuzzle = "usti hlavne";
    };

    private _found = [
        ["muzzle", [["weapon_slots\muzzle"]] call _fnc_proxy],
        ["optic", [["weapon_slots\top"]] call _fnc_proxy],
        ["rail", [["weapon_slots\side"]] call _fnc_proxy],
        ["bipod", [["weapon_slots\bipod", "weapon_slots\underbarrel"]] call _fnc_proxy],
        ["mag", [["magazine"]] call _fnc_proxy],
        ["mag2", [[getText (_config >> (_second param [0, "none"]) >> "muzzlePos"), ""] select (_second isEqualTo [])] call _fnc_memory]
    ];

    if ((_found select 0 select 1) isEqualTo []) then {
        (_found select 0) set [1, [_mainMuzzle] call _fnc_memory];
    };

    deleteVehicle _probe;

    {
        _x params ["_part", "_at"];

        if (count _at == 3) then {
            _inWeapon set [_part, _at];
        };
    } forEach _found;
};

if (_inModel) exitWith {_scene get "modelPoints"};

// ----- On the holder of the scene far off -----
private _holder = (_scene getOrDefault ["objects", []]) param [1, objNull];
private _points = createHashMap;

if (isNull _holder) exitWith {
    _scene set ["points", _points];
    _points
};

private _proxy = "proxy:\a3\characters_f\proxies\weapon.001";
private _base = _holder selectionPosition [_proxy, 0.5];

// The holder's model is not loaded yet: asked again on a later frame - a few seconds at most.
if (_base isEqualTo [0, 0, 0]) exitWith {
    private _tries = (_scene getOrDefault ["pointTries", 0]) + 1;

    _scene set ["pointTries", _tries];

    if (_tries > 300) then {
        _scene set ["points", _points];
        _points
    } else {
        nil
    };
};

(_holder selectionVectorDirAndUp [_proxy, 0.5]) params [["_dir", [0, 1, 0]], ["_up", [0, 0, 1]]];

private _right = _dir vectorCrossProduct _up;

// Onto the holder, then into the world - none farther from where the camera aims than the weapon's frame.
private _target = _scene getOrDefault ["origin", getPosASL _holder];
private _limit = (_scene getOrDefault ["frame", INSPECT_3D_FRAME]) * 1.2;

{
    private _part = _x;

    _y params ["_atX", "_atY", "_atZ"];

    private _onHolder = _base vectorAdd (_right vectorMultiply _atX) vectorAdd (_dir vectorMultiply _atY) vectorAdd (_up vectorMultiply _atZ);
    private _world = _holder modelToWorldWorld _onHolder;

    if (count _world == 3 && {_world distance _target <= _limit}) then {
        _points set [_part, _world];
    };
} forEach (_scene get "modelPoints");

_scene set ["points", _points];

_points
