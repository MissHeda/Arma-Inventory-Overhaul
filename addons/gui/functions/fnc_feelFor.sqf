#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How one move of the window sounds once it has happened (fnc_sendMoves works it out when the move is
 * sent, fnc_feelAnswer plays it when the answer is finished). The action by the kind of move:
 *   move    - "drop" when it goes onto the ground or a pile, else "move"
 *   equip   - into a slot without a part "equip"; a magazine into a weapon "loadMag" (and "loadMagHandgun",
 *             "loadMagLauncher" by the weapon, "loadMagUgl" for the grenade launcher's second slot); any
 *             other part (muzzle, rail, optic, bipod) "attach"
 *   unequip - out of a magazine slot "unloadMag", off a weapon "detach", onto the ground "drop", else "unequip"
 *   swap    - "equip"
 * A sort and anything else make no sound of their own (a sort is heard when it is sent).
 *
 * Arguments:
 * 0: The move, see fnc_sendMoves - "kind", "entry", "to", "slot", "unit" <HASHMAP>
 *
 * Return Value:
 * [action, item class, the holder it went to or objNull, slot, unit] <ARRAY>
 *
 * Example:
 * [createHashMapFromArray [["kind", "move"], ["entry", _tile], ["to", _crate]]] call aio_gui_fnc_feelFor;
 *
 * Public: No
 */

params [["_move", createHashMap, [createHashMap]]];

private _kind = _move getOrDefault ["kind", "move"];
private _entry = _move getOrDefault ["entry", createHashMap];
private _to = _move getOrDefault ["to", objNull];
private _slot = _move getOrDefault ["slot", ""];
private _unit = _move getOrDefault ["unit", objNull];

// An item that leaves a slot is not in the move: it is what the slot holds now.
private _class = if (_kind in ["unequip", "swap"]) then {
    ([_unit, _slot] call EFUNC(storage,getSlot)) getOrDefault ["class", ""]
} else {
    _entry getOrDefault ["class", ""]
};

private _holder = if (_to isEqualType objNull) then {_to} else {objNull};

// A pile on the ground, or the ground itself.
private _onGround = _to isEqualTo "ground" || {!isNull _holder && {[_holder] call EFUNC(storage,isGroundHolder)}};

(_slot splitString "_") params [["_base", "", [""]], ["_part", "", [""]]];

private _action = switch (_kind) do {
    case "move": {
        ["move", "drop"] select _onGround
    };
    case "equip": {
        switch (true) do {
            case (_part isEqualTo ""): {"equip"};
            case (_part isEqualTo "mag2"): {"loadMagUgl"};
            case (_part isEqualTo "mag"): {
                switch (_base) do {
                    case "handgun": {"loadMagHandgun"};
                    case "launcher": {"loadMagLauncher"};
                    default {"loadMag"};
                }
            };
            default {"attach"};
        }
    };
    case "unequip": {
        switch (true) do {
            case (_part in ["mag", "mag2"]): {"unloadMag"};
            case (_part isNotEqualTo ""): {"detach"};
            case (_onGround): {"drop"};
            default {"unequip"};
        }
    };
    case "swap": {"equip"};
    default {""};
};

[_action, _class, _holder, _slot, _unit]
