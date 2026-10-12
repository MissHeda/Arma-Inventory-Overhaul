#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The one rule for what a container takes by weight: what it holds plus what goes in must stay within its
 * maximum load. Whether it fits, why not, how much it needs and has left, and how many of a stack would still
 * fit - so the previews, the hints, the quick moves and the check a move meets on the machine that runs it
 * can never disagree (fnc_hasRoom asks this and keeps the yes or no).
 *
 * The cargo commands add whatever they are given, so this is the only check. The ground has no limit and
 * takes everything; a backpack takes no backpack (the engine's own inventory refuses that too). With
 * einv_storage_gridOnly on, volume counts instead of mass: there is no limit, the compartments alone decide
 * what goes in, and whoever asks has to ask the grid as well (fnc_hasSpace). Items still weigh what they
 * weigh for the soldier carrying them - the weight tiers see to that (einv_weight).
 *
 * Arguments:
 * 0: Container <OBJECT>
 * 1: Entry <HASHMAP>
 * 2: How many of a stack, -1 for all of it <NUMBER> (default: -1)
 *
 * Return Value:
 * The answer <HASHMAP>
 *   "fits"     - it can take it <BOOL>
 *   "reason"   - "" when it fits, else "TooHeavy", "NoBackpack" (a backpack into a backpack) or "Failed"
 *                (no container) <STRING>
 *   "need"     - what would go in, config mass <NUMBER>
 *   "free"     - maximum load less what it holds, config mass; -1 for no limit (the ground, or only the
 *                grid counts) <NUMBER>
 *   "perItem"  - what one of the stack weighs, config mass <NUMBER>
 *   "maxCount" - how many of the stack fit by weight, 0 up to the whole stack; the whole stack where there
 *                is no limit <NUMBER>
 *   "maxLoad", "held" - config mass; -1 and -1 for no limit <NUMBER>
 *
 * Example:
 * [vestContainer player, _entry, 5] call einv_storage_fnc_roomByWeight;
 *
 * Public: Yes
 */

params [["_container", objNull, [objNull]], ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]]];

private _stack = (_entry getOrDefault ["count", 1]) max 1;
private _taking = [_stack, _count] select (_count > 0 && {_count < _stack});

private _answer = createHashMapFromArray [
    ["fits", true], ["reason", ""], ["need", 0], ["free", -1], ["perItem", 0], ["maxCount", _stack],
    ["maxLoad", -1], ["held", -1]
];

if (isNull _container) exitWith {
    _answer set ["fits", false];
    _answer set ["reason", "Failed"];
    _answer set ["maxCount", 0];

    _answer
};

// A backpack never goes into a backpack - the engine's own inventory refuses that too.
if (
    (([_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo)) get "kind") isEqualTo "backpack"
    && {getNumber (configOf _container >> "isBackpack") == 1}
) exitWith {
    _answer set ["fits", false];
    _answer set ["reason", "NoBackpack"];
    _answer set ["maxCount", 0];

    _answer
};

private _whole = [[_entry]] call FUNC(getMass);
private _perItem = _whole / _stack;
private _need = _perItem * _taking;

_answer set ["need", _need];
_answer set ["perItem", _perItem];

// Volume over mass: no weight limit at all, the grid is the limit.
if (GVAR(gridOnly)) exitWith {_answer};

private _maxLoad = [_container] call FUNC(getMaxLoad);

if (_maxLoad < 0) exitWith {_answer};

private _held = [[_container] call FUNC(getContents)] call FUNC(getMass);
private _free = _maxLoad - _held;

_answer set ["maxLoad", _maxLoad];
_answer set ["held", _held];
_answer set ["free", _free];

// The same tolerance as ever: a crumb over the limit still fits.
private _fits = _held + _need <= _maxLoad + 0.001;

_answer set ["fits", _fits];
_answer set ["reason", ["TooHeavy", ""] select _fits];

// How many of the stack: whole ones that still fit, none below zero.
if (_perItem > 0) then {
    _answer set ["maxCount", ((floor ((_free + 0.001) / _perItem)) max 0) min _stack];
};

_answer
