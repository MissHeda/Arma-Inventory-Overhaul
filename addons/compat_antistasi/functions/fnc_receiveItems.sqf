#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The Bazaar's ABZ_fnc_receiveItems (a purchase arrives on the player's machine): it puts the purchase into the
 * player's gear when the engine says there is room, else into a pile beside them with a line in the chat. Its room
 * checks count the grid as well (fnc_canTake), so what the grid cannot hold goes beside the player at once, as that
 * mod means, instead of past the grid. Antistasi's own file otherwise (fnc_patched).
 *
 * Arguments:
 * As ABZ_fnc_receiveItems: [class, count, rounds]
 *
 * Return Value:
 * As ABZ_fnc_receiveItems
 *
 * Public: No
 */

private _call = QFUNC(canTake);

_this call (["receiveItems", A3A_FILE_RECEIVEITEMS, [
    ["player canAddItemToBackpack _c", format ["([player, _c, ""backpack""] call %1)", _call]],
    ["player canAddItemToVest _c", format ["([player, _c, ""vest""] call %1)", _call]],
    ["player canAddItemToUniform _c", format ["([player, _c, ""uniform""] call %1)", _call]],
    ["player canAdd _class", format ["([player, _class] call %1)", _call]]
]] call FUNC(patched))
