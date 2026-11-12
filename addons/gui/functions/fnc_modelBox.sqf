#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The box a model's visible shape takes, face by face - for framing a weapon on its card and in the 3D view (fnc_weaponBounds).
 * Arma's own box of a weapon model is no use for that as it is: every proxy in the model - the muzzle flash, the slots of the
 * attachments, the magazine - is a triangle with one corner where the proxy sits, one along the proxy's direction and one twice
 * as far along its up, a metre and two in most models, half or a quarter of that in others - and those far corners count into
 * the box. So the MX measured 4 m high and the P07's middle lay 47 cm beside the pistol (measured in game, 0.6.112), and a box
 * without them was guessed from the Memory LOD, whose points say little about the shape: the AKM's lowest is 11 cm under its
 * grip, and the card showed the weapon too high (measured in game, 0.7.10).
 *
 * Each of the box's six faces is taken from the first of these that a proxy's far corner does not make there - the first visual
 * LOD, the Geometry LOD, the Memory LOD. A face is a proxy's when it lies along that proxy's direction or up from its place, as
 * far as such a corner lies (PROXY_LEGS of the usual metre, twice that along its up), and whatever lies a metre beside or above
 * a weapon's own axis is no part of it either. A face no LOD has clean is the farthest proxy's own place on that side - a proxy
 * sits on the weapon.
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

// How long a proxy triangle's short leg is, least and most, in metres (its long leg is twice that): 1 in most models, 0.25 to 2
// measured in others (0.7.10).
#define PROXY_LEGS [0.2, 2.2]
// No weapon reaches this far beside or above its own axis (y, z), or along it (x), in metres.
#define FAR_ACROSS 0.9
#define FAR_ALONG 2.5
// How far out past the Geometry LOD's face the visual LOD's may lie to be the shape's still, along the barrel (x) and across it
// (y, z), in metres: a barrel is often longer than its plain block, a grip or a sight a little.
#define GEOMETRY_TRUST [0.2, 0.1, 0.1]
// How far out past the farthest proxy a face taken from the Memory LOD may lie, in metres.
#define MEMORY_PAST 0.1

params [["_probe", objNull, [objNull]]];

if (isNull _probe) exitWith {[[-0.3, -0.05, -0.1], [0.3, 0.05, 0.1]]};

// A LOD's box and its proxies: [least, most, proxies as [place, direction, up], has a box at all].
private _fnc_lod = {
    params ["_lod", "_box"];

    _box params [["_low", [0, 0, 0]], ["_high", [0, 0, 0]]];

    private _proxies = [];

    {
        if ("proxy:" in _x) then {
            // Its place first: selectionPosition loads the LOD of a model nothing shows yet, selectionVectorDirAndUp does not and
            // took the game down asked first (an attachment's model made a moment before - access violation, 0.7.10).
            private _place = _probe selectionPosition [_x, _lod];

            (_probe selectionVectorDirAndUp [_x, _lod]) params [["_dir", [0, 1, 0]], ["_up", [0, 0, 1]]];

            _proxies pushBack [_place, _dir, _up];
        };
    } forEach (_probe selectionNames _lod);

    [_low, _high, _proxies, _low isNotEqualTo _high]
};

// The first visual LOD the engine finds by its resolution (not every one is found by it), else the model's whole visual box
// with no proxies known.
private _lods = [];

{
    _x params ["", "", ["_resolution", -1]];

    if (_lods isEqualTo [] && {_resolution >= 0.5} && {_resolution < 900}) then {
        private _found = [_resolution, boundingBoxReal [_probe, _resolution]] call _fnc_lod;

        if (_found select 3) then {
            _lods pushBack _found;
        };
    };
} forEach (allLODs _probe);

if (_lods isEqualTo []) then {
    (0 boundingBoxReal _probe) params [["_low", [0, 0, 0]], ["_high", [0, 0, 0]]];

    _lods pushBack [_low, _high, [], _low isNotEqualTo _high];
};

_lods pushBack (["Geometry", boundingBoxReal [_probe, "Geometry"]] call _fnc_lod);
_lods pushBack (["Memory", boundingBoxReal [_probe, "Memory"]] call _fnc_lod);

private _least = [];
private _most = [];

{
    private _axis = _x;
    private _far = [FAR_ALONG, FAR_ACROSS, FAR_ACROSS] select _axis;

    {
        _x params ["_side", "_into"];

        // What each LOD says of this face, where a proxy's far corner does not make it: [] or [value].
        private _clean = _lods apply {
            _x params ["_low", "_high", "_proxies", "_there"];

            private _value = ([_low, _high] select _side) param [_axis, 0];

            // A proxy's far corner: along its direction by a leg, or along its up by two.
            private _proxys = _proxies findIf {
                _x params ["_place", "_dir", "_up"];

                private _off = _value - (_place select _axis);
                private _along = _dir select _axis;
                private _above = _up select _axis;

                (abs _along > 0.3 && {(_off / _along) >= (PROXY_LEGS select 0)} && {(_off / _along) <= (PROXY_LEGS select 1)})
                || {abs _above > 0.3 && {(_off / (2 * _above)) >= (PROXY_LEGS select 0)} && {(_off / (2 * _above)) <= (PROXY_LEGS select 1)}}
            } >= 0;

            [[], [_value]] select (_there && {!_proxys} && {abs _value < _far})
        };

        _clean params [["_visual", []], ["_geometry", []], ["_memory", []]];

        // The first of them that has it clean. (The Memory LOD's where it lies farther out than the Geometry LOD's was tried:
        // its lowest points lie well under most rifles, and they sat too high on their cards - measured in game, 0.7.10.)
        //
        // The visual LOD's own is not taken where it lies far out past the Geometry LOD's (GEOMETRY_TRUST): parts that are hidden
        // while the weapon lies somewhere count into its box - a folded-out sight, another barrel, proxies turned some other way -,
        // and RHS's M4 measured 51 cm deep, its ACOG 26 cm high, and came out small on their cards (measured in game, 0.7.13).
        private _picked = call {
            if (_visual isNotEqualTo [] && {_geometry isNotEqualTo []}) exitWith {
                private _out = ((_visual select 0) - (_geometry select 0)) * ([-1, 1] select _side);

                [_visual, _geometry] select (_out > (GEOMETRY_TRUST select _axis))
            };

            if (_visual isNotEqualTo []) exitWith {_visual};
            if (_geometry isNotEqualTo []) exitWith {_geometry};

            // The Memory LOD's points lie on the weapon, but a few far off it - an eye point for a grenade launcher's sight 26 cm
            // over RHS's M4 with an M203, which then came out half as large as its card (measured in game, 0.7.13): no farther
            // out than MEMORY_PAST beyond the farthest proxy on that side, where the model has proxies.
            private _places = [];

            {
                _places append ((_x select 2) apply {(_x select 0) select _axis});
            } forEach _lods;

            if (_memory isEqualTo [] || {_places isEqualTo []}) exitWith {_memory};

            [
                [(_memory select 0) max ((selectMin _places) - MEMORY_PAST)],
                [(_memory select 0) min ((selectMax _places) + MEMORY_PAST)]
            ] select _side
        };

        // No LOD has this face clean: the farthest proxy's own place on that side.
        if (_picked isEqualTo []) then {
            private _places = [];

            {
                _places append ((_x select 2) apply {(_x select 0) select _axis});
            } forEach _lods;

            if (_places isNotEqualTo []) then {
                _picked = [[selectMin _places, selectMax _places] select _side];
            };
        };

        _into pushBack (_picked param [0, ([[-0.3, -0.05, -0.1], [0.3, 0.05, 0.1]] select _side) select _axis]);
    } forEach [[0, _least], [1, _most]];
} forEach [0, 1, 2];

// Never inside out: a face from one LOD may lie past its opposite from another.
{
    if ((_least select _x) > (_most select _x)) then {
        private _middle = ((_least select _x) + (_most select _x)) / 2;

        _least set [_x, _middle];
        _most set [_x, _middle];
    };
} forEach [0, 1, 2];

[_least, _most]
