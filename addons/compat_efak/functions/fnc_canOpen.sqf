#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a kit may open in the window (fnc_open), and why not.
 *
 * A kit nobody has carried yet (a prototype) has no contents of its own. Enhanced First Aid Kits makes
 * it real once a soldier carries it: the player's own at once, an AI's when asked
 * (efak_core_fnc_requestUnitKits) - "try again in a moment". One in a crate or on the ground cannot be
 * made real from here: that mod's own words, "pick it up first".
 *
 * Someone else's kit only as that mod allows it, and never one in the uniform, vest or backpack another
 * living player wears - his machine writes it (fnc_mayReach). Asked first: a kit out of reach is
 * refused as such, also one nobody has carried yet - since the window opens the living, it shows
 * another player's kits as well. Contents that have not reached this machine yet are no reason: its
 * window opens and says so, the notice in place of its grid (einv_gui_fnc_drawWindow).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Container its tile lies in, objNull inside another kit - which was reached already <OBJECT>
 *
 * Return Value:
 * [may open, reason - "" when it may or when it is no kit] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", backpackContainer player] call einv_compat_efak_fnc_canOpen;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_container", objNull, [objNull]]];

if !([_class] call FUNC(isKit)) exitWith {[false, ""]};
if !([_container] call FUNC(mayReach)) exitWith {[false, LLSTRING(NotYours)]};

if (toLowerANSI _class in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])) exitWith {
    private _owner = ([_container] call EFUNC(storage,getOwner)) select 0;

    switch (true) do {
        case (isNull _owner): {[false, localize "STR_efak_gui_Error_NotOpenedYet"]};
        case (_owner isEqualTo EGVAR(gui,unit)): {[false, LLSTRING(Preparing)]};
        case (!isPlayer _owner): {
            if (!isNil QEFAKFUNC(core,requestUnitKits)) then {
                [_owner] call EFAKFUNC(core,requestUnitKits);
            };

            [false, LLSTRING(Preparing)]
        };
        default {[false, localize "STR_efak_gui_Error_NotOpenedYet"]};
    }
};

[true, ""]
