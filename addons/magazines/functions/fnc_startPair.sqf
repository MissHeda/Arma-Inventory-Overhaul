#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A magazine dropped onto another of its kind (einv_gui_fnc_endDrag): asked again whether it may
 * (fnc_canRepack - a refusal with a reason is shown in the hint), then started (fnc_begin) with ACE's
 * order: the fuller magazine is filled from the emptier one, the fewest rounds to move. Of two with the
 * same rounds the one dropped on is filled - it comes last, and the last one receives.
 *
 * Arguments:
 * 0: Grid the dragged tile lies in <HASHMAP>
 * 1: The dragged tile <HASHMAP>
 * 2: Grid of the tile it was dropped on <HASHMAP>
 * 3: The tile it was dropped on <HASHMAP>
 *
 * Return Value:
 * A repack started <BOOL>
 *
 * Example:
 * [_sourceGrid, _entry, _targetGrid, _under] call einv_magazines_fnc_startPair;
 *
 * Public: No
 */

params [["_sourceGrid", createHashMap, [createHashMap]], ["_sourceTile", createHashMap, [createHashMap]], ["_targetGrid", createHashMap, [createHashMap]], ["_targetTile", createHashMap, [createHashMap]]];

([_sourceGrid, _sourceTile, _targetGrid, _targetTile] call FUNC(canRepack)) params ["_fits", "_why"];

if (!_fits) exitWith {
    if (_why isNotEqualTo "") then {
        [_why] call EFUNC(gui,flashHint);
    };

    false
};

private _fnc_part = {
    params ["_grid", "_tile"];

    [
        _grid get "container",
        [_tile get "col", _tile get "row", _tile getOrDefault ["block", 0], _tile get "w", _tile get "h"],
        _tile get "ammo",
        _tile getOrDefault ["count", 1],
        [_grid] call FUNC(domain)
    ]
};

private _source = [_sourceGrid, _sourceTile] call _fnc_part;
private _target = [_targetGrid, _targetTile] call _fnc_part;

private _parts = if ((_source select 2) > (_target select 2)) then {[_target, _source]} else {[_source, _target]};

[_sourceTile get "class", _parts, _source select 4] call FUNC(begin)
