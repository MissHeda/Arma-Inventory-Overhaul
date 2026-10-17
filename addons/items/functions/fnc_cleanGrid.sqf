#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A grid spec (fnc_parseGrid) with the categories its compartments accept cut down to the ones that exist: a compartment that
 * names a category nobody defines (a text written for another setup, a category taken out since) would otherwise accept nothing
 * for good. What is left of a list that ends up empty accepts everything again - or stays a single slot with no categories.
 * A spec that names only categories that exist is given back as it is.
 *
 * Arguments:
 * 0: The spec, ["blocks", [[cols, rows, holes, pos, accepts, single], ...]] or any other <ARRAY>
 * 1: The categories there are, fnc_categories gives them <ARRAY of STRING> (default: the rules in effect)
 *
 * Return Value:
 * The spec <ARRAY>
 *
 * Example:
 * [["blocks", [[2, 2, [], [], ["bandit"], false]]], ["weapon"]] call einv_items_fnc_cleanGrid; // ["blocks", [[2, 2, [], []]]]
 *
 * Public: No
 */

params [["_spec", [], [[]]], ["_ids", nil, [[]]]];

if ((_spec param [0, ""]) isNotEqualTo "blocks") exitWith {_spec};

private _blocks = _spec param [1, []];

// The compartments of an ordinary container have four elements: nothing to look at.
if (_blocks findIf {count _x > 4} < 0) exitWith {_spec};

if (isNil "_ids") then {
    _ids = [] call FUNC(categories);
};

private _dirty = _blocks findIf {
    private _accepts = _x param [4, []];

    _accepts isNotEqualTo [] && {_accepts findIf {!(_x in _ids)} >= 0}
};

if (_dirty < 0) exitWith {_spec};

["blocks", _blocks apply {
    private _block = _x;
    private _accepts = _block param [4, []];

    if (_accepts isEqualTo [] || {_accepts findIf {!(_x in _ids)} < 0}) then {
        _block
    } else {
        private _kept = _accepts select {_x in _ids};
        private _copy = +_block;

        _copy set [4, _kept];

        // No category and no single slot left: a compartment like any other, with the four elements of one.
        if (_kept isEqualTo [] && {!(_block param [5, false])}) then {
            _copy resize 4;
        };

        _copy
    }
}]
