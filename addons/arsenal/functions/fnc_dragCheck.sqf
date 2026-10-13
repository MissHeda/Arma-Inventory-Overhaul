#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a tile dragged out of the panel lands (the "dragCheck" hook). Inside the panel the engine's own
 * verdict stands: a free spot, another one of its kind to stack on, or the reason it does not go. Outside
 * the panel - over ACE's list, the 3D middle, anywhere - nothing goes to the ground: it is taken out of the
 * container, shown as ACE's list lit in the loss colour, and the hint line says so once as the drag gets
 * there (fnc_onDrop does it).
 *
 * Arguments:
 * 0: The engine's target <ARRAY>
 * 1: What is dragged <HASHMAP>
 * 2: The grid it comes from <HASHMAP>
 * 3: The slot it comes from, [] for a tile <ARRAY>
 *
 * Return Value:
 * The target as it is to stand, nil to leave the engine's <ARRAY or NIL>
 *
 * Example:
 * [["ground", -1, 0, 0, true, ""], _entry, _grid, []] call einv_arsenal_fnc_dragCheck;
 *
 * Public: No
 */

params [["_target", [], [[]]]];

private _kind = _target param [0, ""];

if (!(_kind in ["ground", "zone"]) || {GVAR(removeZone) < 0}) exitWith {
    GVAR(dragZone) = "";
    nil
};

if (GVAR(dragZone) isEqualTo "") then {
    GVAR(dragZone) = "remove";
    [LLSTRING(Hint_DropRemove), "loss"] call EFUNC(gui,showHint);
};

["zone", GVAR(removeZone), 0, 0, true, "", "loss"]
