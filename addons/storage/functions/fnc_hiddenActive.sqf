#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the hidden holder is in force for a unit right now - whether a Strict container of it may keep
 * things out of the cargo (fnc_hiddenRoute, fnc_opStrict). Only a living player's unit: an AI uses what it
 * carries and nobody limits it, a body is looted from its containers. Not while an arsenal is open on this
 * machine (ARSENAL_OPEN): the arsenals read and write the cargo themselves, and a loadout saved there has to
 * hold everything - so the holder gives everything back for as long as one is open and takes it again
 * after. Never in Eden.
 *
 * Asked on the machine that runs the ops - the unit's owner, where the player's own arsenal is the one that
 * can be open.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * In force <BOOL>
 *
 * Example:
 * [player] call aio_storage_fnc_hiddenActive;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

!isNull _unit && {alive _unit} && {isPlayer _unit} && {!is3DEN} && {!ARSENAL_OPEN}
