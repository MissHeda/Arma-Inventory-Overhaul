#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Drops the crates the window looked into through their vehicle's cargo (fnc_toggleOpen) once they are no
 * longer in it: someone unloaded them, or the vehicle lost them. Everything else in the list - the
 * uniforms, vests and backpacks opened from inside a container - stays as it is.
 *
 * Arguments:
 * 0: What the window opened from inside containers, [[class, object, container it lies in, ...], ...] <ARRAY>
 *
 * Return Value:
 * The list without the crates that left their vehicle <ARRAY>
 *
 * Example:
 * [einv_gui_opened] call einv_compat_ace_cargo_fnc_pruneOpened;
 *
 * Public: No
 */

params [["_opened", [], [[]]]];

_opened select {
    private _object = _x select 1;
    private _from = _object getVariable [QGVAR(openedFrom), objNull];

    // A thing that was never opened from cargo, or one still loaded where it was opened from.
    isNull _from || {_object in (_from getVariable [QACEGVAR(cargo,loaded), []])}
}
