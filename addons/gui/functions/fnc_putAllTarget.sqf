#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where "Put all in" puts things: the containers of the loot column in the order it shows them - what the
 * window was opened on, then what lies around - that take things: a crate, a vehicle, a body's or a
 * person's uniform, vest or backpack that the player may put into (fnc_checkTouch), and a uniform, vest or
 * backpack opened from inside one of them. Not a pile on the ground, not a body's doll, and not what the
 * unit carries itself (a container opened from its own storage).
 *
 * Read from the sections of the last build (GVAR(context)), so the button knows whether to show while the
 * columns are still being drawn - folded sections count: a crate lying nearby is a place to put things
 * whether or not it is unfolded.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Targets in order, [[holder, root], ...] <ARRAY>
 *
 * Example:
 * call einv_gui_fnc_putAllTarget;
 *
 * Public: No
 */

private _targets = [];

{
    private _container = _x getOrDefault ["container", objNull];
    private _root = _x getOrDefault ["root", objNull];

    if (
        isNull _container || {(_x getOrDefault ["id", ""]) in ["ground", "worn"]} || {_x getOrDefault ["placeholder", false]}
        || {_x getOrDefault ["virtual", false]} || {_root isEqualTo GVAR(unit)}
    ) then {continue};

    if (([_container, "items"] call FUNC(checkTouch)) isNotEqualTo "") then {continue};

    _targets pushBack [_container, _root];
} forEach (GVAR(context) getOrDefault ["lootSections", []]);

_targets
