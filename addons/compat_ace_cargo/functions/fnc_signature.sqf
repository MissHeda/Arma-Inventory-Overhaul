#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the window shows of ACE cargo, for the signature it compares to see that it must be built again
 * (aio_gui_fnc_getSignature): what is loaded in the containers it looks into, the crates opened from
 * cargo and what lies around, and what is being unloaded - so someone else loading or unloading redraws
 * the cards, and so does the unloading starting or stopping.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Parts of the signature <ARRAY>
 *
 * Example:
 * call aio_compat_ace_cargo_fnc_signature;
 *
 * Public: No
 */

private _objects = [EGVAR(gui,container), EGVAR(gui,secondary)];

_objects append (EGVAR(gui,opened) apply {_x select 1});
_objects append EGVAR(gui,nearby);

[
    (_objects select {!isNull _x}) apply {_x getVariable [QACEGVAR(cargo,loaded), []]},
    GVAR(unloading) select [0, 2]
]
