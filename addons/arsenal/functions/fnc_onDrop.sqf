#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A tile of the panel let go (the "drop" hook). Within the panel the engine moves it as in the inventory -
 * to a free spot, turned or not, onto another of its kind - a move of place only, the container's own
 * (einv_storage). Let go outside the panel, where fnc_dragCheck pointed it at ACE's list, it is taken out
 * of the container: as much of the stack as was dragged (fnc_remove).
 *
 * Arguments:
 * 0: Kind of target <STRING>
 * 1: Index of the grid it comes from <NUMBER>
 * 2: Index of its tile <NUMBER>
 * 3: The slot it comes from, [] for a tile <ARRAY>
 * 4: What is dragged <HASHMAP>
 * 5: How many of a stack, -1 for all <NUMBER>
 *
 * Return Value:
 * Handled - the engine does nothing more <BOOL>
 *
 * Example:
 * ["zone", 0, 3, [], _entry, -1] call einv_arsenal_fnc_onDrop;
 *
 * Public: No
 */

params [
    ["_kind", "", [""]], ["_sourceIndex", -1, [0]], ["_tileIndex", -1, [0]], ["_slotSource", [], [[]]],
    ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]]
];

GVAR(dragZone) = "";

if !(_kind in ["zone", "ground"]) exitWith {false};

// Only the panel's own tiles are dragged here; a slot has nothing to take out.
if (_slotSource isEqualTo []) then {
    [[_sourceIndex, _tileIndex], _count] call FUNC(remove);
};

true
