#include "script_component.hpp"

// Zeus Enhanced's menu and modules exist on the game master's machine only.
if (!hasInterface) exitWith {};

// The right-click menu: "Inventory lock" on crates and vehicles, and who it is for.
private _parent = [
    QGVAR(lock), LLSTRING(Action_Lock), GUI_TEX(icon_lock_ca), {},
    {
        params ["", "_objects", "", "", "", "_hoveredEntity"];

        ([_objects, _hoveredEntity] call FUNC(targets)) isNotEqualTo []
    }
] call zen_context_menu_fnc_createAction;

private _parentPath = [_parent, [], 0] call zen_context_menu_fnc_addAction;

// The choices, first one on top (the menu sorts by priority, highest first).
private _choices = [
    [QGVAR(open), LLSTRING(Action_Everyone), "", ""],
    [QGVAR(west), format [LLSTRING(Action_Side), LELSTRING(locks,Side_West)], "side", west],
    [QGVAR(east), format [LLSTRING(Action_Side), LELSTRING(locks,Side_East)], "side", east],
    [QGVAR(independent), format [LLSTRING(Action_Side), LELSTRING(locks,Side_Independent)], "side", independent],
    [QGVAR(civilian), format [LLSTRING(Action_Side), LELSTRING(locks,Side_Civilian)], "side", civilian],
    [QGVAR(admins), LLSTRING(Action_Admins), "admins", ""],
    [QGVAR(group), LLSTRING(Action_Group), "pick", ""]
];

{
    _x params ["_id", "_name", "_mode", "_who"];

    private _action = [_id, _name, "", {
        params ["", "_objects", "", "", "", "_hoveredEntity", "_args"];

        _args params ["_mode", "_who"];

        [[_objects, _hoveredEntity] call FUNC(targets), _mode, _who] call FUNC(apply);
    }, {true}, [_mode, _who]] call zen_context_menu_fnc_createAction;

    [_action, _parentPath, count _choices - _forEachIndex] call zen_context_menu_fnc_addAction;
} forEach _choices;

// Searching on a crate or a vehicle: the server's settings decide for every object that has no mark of its own, and this
// is the mark (aio_gui_fnc_setSearchable). Two choices that say what they will do, each shown while some target would
// change (fnc_canSetSearch). The conditions are written out, not given arguments: they do not depend on what the menu hands on.
private _off = [
    QGVAR(searchOff), LLSTRING(Action_SearchOff), GUI_TEX(icon_eye_off_ca), {
        params ["", "_objects", "", "", "", "_hoveredEntity"];

        [[_objects, _hoveredEntity] call FUNC(targets), false] call FUNC(setSearch);
    }, {
        params ["", "_objects", "", "", "", "_hoveredEntity"];

        [[_objects, _hoveredEntity] call FUNC(targets), false] call FUNC(canSetSearch)
    }
] call zen_context_menu_fnc_createAction;

private _on = [
    QGVAR(searchOn), LLSTRING(Action_SearchOn), GUI_TEX(icon_eye_ca), {
        params ["", "_objects", "", "", "", "_hoveredEntity"];

        [[_objects, _hoveredEntity] call FUNC(targets), true] call FUNC(setSearch);
    }, {
        params ["", "_objects", "", "", "", "_hoveredEntity"];

        [[_objects, _hoveredEntity] call FUNC(targets), true] call FUNC(canSetSearch)
    }
] call zen_context_menu_fnc_createAction;

[_off, [], 0] call zen_context_menu_fnc_addAction;
[_on, [], -1] call zen_context_menu_fnc_addAction;

// The module "Lock inventory", placed on an object.
[LLSTRING(Category), LLSTRING(Module_Lock), {
    params ["", "_object"];

    [_object] call FUNC(module);
}, GUI_TEX(icon_lock_ca)] call zen_custom_modules_fnc_register;
