#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a tile dragged out of the panel lands (the "dragCheck" hook). Inside the panel the engine's own
 * verdict stands: a free spot, another one of its kind to stack on, or the reason it does not go. Outside
 * the panel - over ACE's list, the 3D middle, anywhere - nothing goes to the ground: it is taken out of the
 * container, shown as ACE's list lit in the loss colour, and the hint line says so once as the drag gets
 * there (fnc_onDrop does it).
 *
 * An item dragged out of ACE's list (fnc_listDrag) goes in only on a grid of the panel - the open
 * container's or the staging space's, where the engine's verdict stands as well -, or over a kit's tile
 * there into that kit, as that kit says (fnc_listToKit: Enhanced First Aid Kits' rules and the kit's
 * room - its capacity, or the cells of a grid a rule or its config gives it). Anywhere else there is no
 * target: let go there, nothing happens, which the hint line says once.
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

params [["_target", [], [[]]], ["_entry", createHashMap, [createHashMap]], ["_grid", createHashMap, [createHashMap]]];

private _kind = _target param [0, ""];

if ((_grid getOrDefault ["source", ""]) isEqualTo "aceList") exitWith {
    // The panel folded to its title row has no grid to put it in: held over the row it unfolds (fnc_onFrame).
    if (GVAR(collapsed)) exitWith {
        if (GVAR(dragZone) isNotEqualTo "unfold") then {
            GVAR(dragZone) = "unfold";
            [LLSTRING(Hint_ListUnfold), "muted"] call EFUNC(gui,showHint);
        };

        []
    };

    if (_kind isEqualTo "grid") exitWith {
        private _intoKit = [_target, _entry] call FUNC(listToKit);

        if (_intoKit isNotEqualTo []) exitWith {_intoKit};

        GVAR(dragZone) = "";
        nil
    };

    if (GVAR(dragZone) isNotEqualTo "cancel") then {
        GVAR(dragZone) = "cancel";
        [LLSTRING(Hint_ListCancel), "muted"] call EFUNC(gui,showHint);
    };

    []
};

if (!(_kind in ["ground", "zone"]) || {GVAR(removeZone) < 0}) exitWith {
    GVAR(dragZone) = "";
    nil
};

if (GVAR(dragZone) isNotEqualTo "remove") then {
    GVAR(dragZone) = "remove";
    [LLSTRING(Hint_DropRemove), "loss"] call EFUNC(gui,showHint);
};

["zone", GVAR(removeZone), 0, 0, true, "", "loss"]
