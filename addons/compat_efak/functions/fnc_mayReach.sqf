#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the player may reach into the kits in a container, by Enhanced First Aid Kits' own rule for
 * the kits of others (its ACE actions): the player's own and those lying about always; another
 * soldier's only while that mod lets players use other people's kits, and while he is awake only when
 * it says so as well - a body never is.
 *
 * Never into the uniform, vest or backpack another living player wears, awake or not
 * (fnc_isPlayerGear): the kits in it are his, by Mia's rule. Asked when a kit opens and again before
 * anything is sent into or out of one - a soldier looted while down may be up again, and a container
 * looted may have been put on.
 *
 * Arguments:
 * 0: Container the kit lies in - objNull inside another kit, which was reached already <OBJECT>
 *
 * Return Value:
 * May reach <BOOL>
 *
 * Example:
 * [vestContainer cursorObject] call aio_compat_efak_fnc_mayReach;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

private _unit = EGVAR(gui,unit);

if (isNull _container || {_container in [uniformContainer _unit, vestContainer _unit, backpackContainer _unit]}) exitWith {true};
if ([_container] call FUNC(isPlayerGear)) exitWith {false};

private _owner = ([_container] call EFUNC(storage,getOwner)) select 0;

if (isNull _owner || {_owner isEqualTo _unit}) exitWith {true};

missionNamespace getVariable [QEFAKGVAR(core,interactWithOthers), true]
&& {missionNamespace getVariable [QEFAKGVAR(core,interactWithAwake), false] || {!([_owner] call ACEFUNC(common,isAwake))}}
