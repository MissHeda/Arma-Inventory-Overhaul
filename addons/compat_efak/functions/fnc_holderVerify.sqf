#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a kit still lies under a root, asked by the machine that runs a phase on it before any op
 * touches it (aio_storage_holderTypes "kit" "verify", aio_storage_fnc_verifyChain): the kit's class
 * in a container under that root, or packed in a kit that lies there - as deep as kits go. Read off
 * the real cargo there (fnc_locate with the root), never from what a window remembers: a kit picked up
 * or moved in the meantime is no longer that root's, and the op says "Moved".
 *
 * Arguments:
 * 0: Holder, "kit:" + the lowercase class <STRING>
 * 1: Root <OBJECT>
 *
 * Return Value:
 * It lies there <BOOL>
 *
 * Example:
 * ["kit:efak_ifak_7", player] call aio_compat_efak_fnc_holderVerify;
 *
 * Public: No
 */

params [["_holder", "", [""]], ["_root", objNull, [objNull]]];

// A kit always lies in something: the server's own phases (root objNull) never name one.
if (isNull _root || {(_holder select [0, 4]) isNotEqualTo "kit:"}) exitWith {false};

!isNull (([_holder select [4], [], _root] call FUNC(locate)) select 1)
