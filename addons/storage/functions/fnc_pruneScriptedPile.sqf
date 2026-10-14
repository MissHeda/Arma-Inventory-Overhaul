#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Deletes a pile of ours that has been emptied: a GroundWeaponHolder_Scripted (fnc_getGroundHolder) that
 * is local here and, a frame later, still holds no item, weapon, magazine or backpack. The engine deletes
 * an ordinary pile it takes for empty - and a pile holding only a backpack, an object of its own and no
 * item cargo, counts as empty to it, backpack and all (0.4.0) -, which is why the piles are scripted ones
 * now; the engine leaves those alone, so whoever emptied one has to remove it, or every Take all and every
 * bounced put-down would leave an empty object lying there for good.
 *
 * Called by fnc_execute for each pile a phase touched and by fnc_opPutGround for the piles a bounced
 * put-down left empty. A frame later, so the transaction's own bookkeeping and the window's rebuild are done
 * with the pile first - and looked at again then: a pile something was put into since stays. Never an
 * engine-made GroundWeaponHolder (the engine does that itself) and never a WeaponHolderSimulated.
 *
 * Arguments:
 * 0: Pile <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_pile] call einv_storage_fnc_pruneScriptedPile;
 *
 * Public: No
 */

params [["_pile", objNull, [objNull]]];

if (isNull _pile || {!local _pile} || {typeOf _pile != "GroundWeaponHolder_Scripted"}) exitWith {};

[{
    params ["_pile"];

    if (isNull _pile || {!local _pile}) exitWith {};

    // The engine's own cargo lists, not fnc_getContents: nothing it writes, and a backpack is an object of
    // its own in a pile, in no list but everyBackpack.
    private _empty = ((getItemCargo _pile) param [0, []]) isEqualTo []
        && {((getWeaponCargo _pile) param [0, []]) isEqualTo []}
        && {((getMagazineCargo _pile) param [0, []]) isEqualTo []}
        && {(everyBackpack _pile) isEqualTo []};

    if (!_empty) exitWith {};

    deleteVehicle _pile;
}, [_pile]] call FUNC(nextFrame);
