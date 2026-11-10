#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The vanilla arsenal is asked to open (fnc_handleBIOpen) or opened (fnc_biSafetyNet): is it an arsenal with a stock of
 * its own that a compat addon registered a pool for (GVAR(poolAdapters), fnc_registerPool)? The first adapter whose
 * "claims" answers true is noted in GVAR(biClaim) until the vanilla window closes. A claimed arsenal always stays the
 * vanilla one, whatever the setting "Vanilla Virtual Arsenal" says: the mission's stock lives in it. The grid panel lies
 * beside its list when the adapter's "panel" answers true (fnc_biOpened), and every add and take of the panel is then
 * counted against that stock (fnc_poolCensus, fnc_poolSettle).
 *
 * Arguments:
 * 0: The arguments of BIS_fnc_arsenal "Open", or [] when asked from the arsenalOpened event <ARRAY or BOOL>
 *
 * Return Value:
 * Claimed <BOOL>
 *
 * Example:
 * [[nil, _box, player, false]] call aio_arsenal_fnc_poolClaim;
 *
 * Public: No
 */

params [["_args", []]];

if (count GVAR(biClaim) > 0) exitWith {true};

if (!hasInterface || {is3DEN}) exitWith {false};

private _claim = GVAR(poolAdapters) findIf {
    _x isEqualType createHashMap && {([_args] call (_x getOrDefault ["claims", {false}])) isEqualTo true}
};

if (_claim < 0) exitWith {false};

GVAR(biClaim) = GVAR(poolAdapters) select _claim;

true
