#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How full a container is by weight, as one word the window can draw from - the caption, the bar under it,
 * the cells and the hint all read this and agree:
 *
 *   "none"  - no limit: the ground, a container with none, or only the grid counting (einv_storage_gridOnly)
 *   "ok"    - room left
 *   "near"  - at least NEAR_FULL of its load is used
 *   "full"  - less than FULL_FREE_MASS config mass (or FULL_SHARE of its load, whichever is more) is left
 *             while it holds something, or its load is 0: nothing more fits, whatever the grid says
 *   "over"  - above its load (scripts and other mods can do that)
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: What it holds, config mass - -1 to work it out (fnc_getContents, fnc_getMass) <NUMBER> (default: -1)
 *
 * Return Value:
 * The state <HASHMAP>
 *   "state"    - see above <STRING>
 *   "mass"     - what it holds, config mass <NUMBER>
 *   "maxLoad"  - what it can hold, -1 for no limit <NUMBER>
 *   "free"     - maxLoad less mass, -1 for no limit <NUMBER>
 *   "fraction" - mass / maxLoad, 0 for no limit <NUMBER>
 *
 * Example:
 * [vestContainer player] call einv_storage_fnc_getLoadState;
 *
 * Public: Yes
 */

params [["_container", objNull, [objNull]], ["_mass", -1, [0]]];

if (_mass < 0) then {
    _mass = 0;

    if (!isNull _container) then {
        _mass = [[_container] call FUNC(getContents)] call FUNC(getMass);
    };
};

private _maxLoad = -1;

if (!isNull _container && {!GVAR(gridOnly)}) then {
    _maxLoad = [_container] call FUNC(getMaxLoad);
};

if (_maxLoad < 0) exitWith {
    createHashMapFromArray [["state", "none"], ["mass", _mass], ["maxLoad", -1], ["free", -1], ["fraction", 0]]
};

private _free = _maxLoad - _mass;
private _fraction = 1;

if (_maxLoad > 0) then {
    _fraction = _mass / _maxLoad;
};

private _state = switch (true) do {
    // A load of 0 takes nothing.
    case (_maxLoad <= 0): {"full"};
    case (_mass > _maxLoad + 0.001): {"over"};
    // Not empty: a container too small for even the least item is not "full" before anything is in it.
    case (_mass > 0 && {_free < (FULL_FREE_MASS max (_maxLoad * FULL_SHARE))}): {"full"};
    case (_fraction >= NEAR_FULL): {"near"};
    default {"ok"};
};

createHashMapFromArray [["state", _state], ["mass", _mass], ["maxLoad", _maxLoad], ["free", _free], ["fraction", _fraction]]
