#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit's player is a logged-in admin. On the player's own machine that is the hosting player
 * or whoever may use #shutdown (a voted admin cannot); on the server about someone else the engine knows
 * who logged in. A client cannot tell about another client: it says no.
 *
 * Single player has no admin: locks work there as for any player, which is how a mission maker tests them.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Admin <BOOL>
 *
 * Example:
 * [player] call einv_locks_fnc_isAdmin;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isMultiplayer || {isNull _unit}) exitWith {false};

// On the player's own machine: the hosting player, or a logged-in admin.
if (local _unit && {hasInterface}) exitWith {isServer || {serverCommandAvailable "#shutdown"}};

// On the server about someone else: the engine knows who logged in.
if (isServer) exitWith {(admin owner _unit) == 2};

false
