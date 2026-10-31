#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * "Repack all" from the context menu of a magazine in the player's own gear: every partly filled magazine
 * of that class in the uniform, vest and backpack (fnc_ownPartials, a loaded one never) is repacked in
 * place, with the same progress as a dropped pair. Nothing starts with fewer than two.
 *
 * Arguments:
 * 0: Magazine class <STRING>
 *
 * Return Value:
 * A repack started <BOOL>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag"] call aio_magazines_fnc_startAll;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if !([] call FUNC(isEnabled)) exitWith {false};
if ([] call FUNC(isBusy)) exitWith {false};

private _parts = [_class] call FUNC(ownPartials);

if (count _parts < 2) exitWith {false};

[_class, _parts, EGVAR(gui,unit)] call FUNC(begin)
