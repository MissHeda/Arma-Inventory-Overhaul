#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi Ultimate's SCRT_fnc_loot_gatherLoot ("Loot around", run on the server), with the piles of this mod
 * taken in: that mod's own file with GroundWeaponHolder_Scripted added to the classes it loots - the piles everything
 * this mod puts on the ground lies in (aio_storage_fnc_getGroundHolder). It compares the exact class, so it passed them
 * over (fnc_patched).
 *
 * Arguments:
 * As SCRT_fnc_loot_gatherLoot: [vehicle, radius, override position]
 *
 * Return Value:
 * As SCRT_fnc_loot_gatherLoot
 *
 * Public: No
 */

private _classes = """WeaponHolderSimulated"", ""GroundWeaponHolder"", ""WeaponHolder""";

_this call (["gatherLoot", A3A_FILE_GATHERLOOT, [[_classes, _classes + ", ""GroundWeaponHolder_Scripted"""]]] call FUNC(patched))
