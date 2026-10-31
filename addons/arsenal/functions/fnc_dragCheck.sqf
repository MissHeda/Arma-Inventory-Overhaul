#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a tile dragged out of the panel lands (the "dragCheck" hook). Inside the panel the engine's own
 * verdict stands: a free spot, another one of its kind to stack on, or the reason it does not go. Outside
 * the panel - over ACE's list, the 3D middle, anywhere - nothing goes to the ground: it is taken out of the
 * container, shown as ACE's list lit in the loss colour, and the hint line says so once as the drag gets
 * there (fnc_onDrop does it).
 *
 * An item dragged out of ACE's list or the list of Enhanced First Aid Kits' kits tab (fnc_listDrag) goes in only
 * on a grid of the panel - a container's or the staging space's, where the engine's verdict stands as well -,
 * on the kit's grid in the kits tab or over a kit's tile there into that kit, as that kit says (fnc_listToKit:
 * whether it may be filled in the arsenal, Enhanced First Aid Kits' rules and the kit's room - its capacity, or the
 * cells of a grid a rule or its config gives it). Anywhere else there is no target: let go there, nothing happens,
 * which the hint line says once.
 *
 * A tile of the kit's grid that leaves the kit - onto another grid or kit, or out of the panel to be taken away -
 * goes only where the kit lets things out in the arsenal (aio_compat_efak_fnc_arsenalEditable: the kit type's
 * Arsenal setting, a kit that follows the default contents): red at once, with why. Within its own grid it only
 * changes its place, which is always allowed.
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
 * [["ground", -1, 0, 0, true, ""], _entry, _grid, []] call aio_arsenal_fnc_dragCheck;
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

// Out of the kit's grid: only where the kit lets things out. Its own grid - a place within the kit - is not leaving.
private _fromKit = _grid getOrDefault ["kit", ""];
private _locked = "";

if (_fromKit isNotEqualTo "" && {!isNil QEFUNC(compat_efak,arsenalEditable)}) then {
    private _toKit = ((uiNamespace getVariable [QEGVAR(gui,grids), []]) param [_target param [1, -1], createHashMap]) getOrDefault ["kit", ""];

    if (_kind in ["ground", "zone", "kitTile"] || {_kind isEqualTo "grid" && {_toKit isNotEqualTo _fromKit}}) then {
        _locked = [_fromKit, false] call EFUNC(compat_efak,arsenalEditable);
    };
};

if (!(_kind in ["ground", "zone"]) || {GVAR(removeZone) < 0}) exitWith {
    GVAR(dragZone) = "";

    if (_locked isEqualTo "" || {(_target param [4, false]) isEqualTo false}) exitWith {nil};

    private _answer = +_target;

    _answer set [4, false];
    _answer set [5, _locked];
    _answer
};

if (_locked isNotEqualTo "") exitWith {
    if (GVAR(dragZone) isNotEqualTo "locked") then {
        GVAR(dragZone) = "locked";
        [_locked] call EFUNC(gui,flashHint);
    };

    ["zone", GVAR(removeZone), 0, 0, false, _locked, "loss"]
};

if (GVAR(dragZone) isNotEqualTo "remove") then {
    GVAR(dragZone) = "remove";
    [LLSTRING(Hint_DropRemove), "loss"] call EFUNC(gui,showHint);
};

["zone", GVAR(removeZone), 0, 0, true, "", "loss"]
