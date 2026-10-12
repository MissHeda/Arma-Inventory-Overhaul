#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Broadcasts the places of every own container written here and not yet sent (GVAR(dirty)). Armed
 * OWN_WRITE_DELAY seconds after the first such write, and called when the window closes
 * (einv_gui_fnc_onUnload) and when the player dies: a body's places must be public for its looters.
 *
 * Each holder goes out as it is now - its places, and for a uniform, vest or backpack lying in it or
 * lying in one of the player's own the tag and the copy of nested places on the outermost container
 * (fnc_tagNested) - so whatever was written meanwhile goes out once, the latest.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_storage_fnc_flushPlaces;
 *
 * Public: No
 */

private _dirty = GVAR(dirty);

GVAR(dirty) = [];

{
    private _object = _x;

    if (!isNull _object) then {
        {
            private _value = _object getVariable _x;

            if (!isNil "_value") then {
                _object setVariable [_x, _value, true];
            };
        } forEach [QGVAR(places), QGVAR(nested), QGVAR(tag)];
    };
} forEach _dirty;
