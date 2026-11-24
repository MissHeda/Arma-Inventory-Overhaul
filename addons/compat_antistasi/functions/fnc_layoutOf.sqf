#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a unit's uniform, vest and backpack keep their things, as a loadout carries it ("aio_layout",
 * aio_storage_fnc_onLoadoutGet): [1, [uniform, vest, backpack]], [] when nothing is placed. Kept before Antistasi
 * takes the gear apart and adds it back (a HALO jump, Mag Repack, a save), and written back after (fnc_restorePlaces).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * The layout <ARRAY>
 *
 * Example:
 * [player] call aio_compat_antistasi_fnc_layoutOf;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _extended = createHashMap;

[_unit, getUnitLoadout _unit, _extended] call EFUNC(storage,onLoadoutGet);

_extended getOrDefault ["aio_layout", []]
