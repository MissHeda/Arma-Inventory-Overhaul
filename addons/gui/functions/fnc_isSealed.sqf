#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a container is drawn sealed (issue 6, as Tarkov does it): a body's or a living person's uniform, vest or
 * backpack that this player has to search (fnc_isSearched) and has not searched to its end yet. Sealed, its section is
 * one fixed block marked "Unsearched" (fnc_drawSection): neither how big it is nor what it holds shows, not in the grid,
 * the caption's weight, the hint or the search's time. Its search runs as any box's (fnc_markHidden queues its items and
 * a last entry for the seal); when that last entry is done fnc_animateSearch unseals it and the window is built with the
 * real grid.
 *
 * Unsealed is this player's own knowledge, kept on the container and not broadcast (QGVAR(unsealed)), as what is known of
 * a container's items is (fnc_learn). Crates, vehicles, the ground and what lies about as an object of its own stay
 * boxes with hatched tiles.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Sealed <BOOL>
 *
 * Example:
 * [uniformContainer cursorObject] call einv_gui_fnc_isSealed;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {_container getVariable [QGVAR(unsealed), false]}) exitWith {false};

private _owner = ([_container] call EFUNC(storage,getOwner)) select 0;

!isNull _owner && {_owner isNotEqualTo GVAR(unit)} && {_owner isKindOf "CAManBase"} && {[_container] call FUNC(isSearched)}
