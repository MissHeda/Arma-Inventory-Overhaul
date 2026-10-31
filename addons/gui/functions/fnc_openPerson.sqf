#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens a living person for the player - what they wear, then their uniform, vest and backpack, or only
 * the backpack where the server's settings say so (fnc_canOpenPerson) - and tells them (fnc_notifyPerson).
 * Reach and permission are checked again: the person action (fnc_addPersonAction) runs it a frame
 * after it was chosen, and a mission may call it as well.
 *
 * Arguments:
 * 0: Person <OBJECT>
 * 1: Quiet - do not tell the person, who was told already <BOOL> (default: false)
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [cursorObject] call aio_gui_fnc_openPerson;
 *
 * Public: Yes
 */

params [["_person", objNull, [objNull]], ["_quiet", false, [false]]];

private _player = ACE_player;

if (!hasInterface || {!alive _player} || {_person isEqualTo _player}) exitWith {false};
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {false};

private _mode = [_person] call FUNC(canOpenPerson);

if (_mode isEqualTo "" || {!([_player, _person, true] call FUNC(personInReach))}) exitWith {false};

private _container = [backpackContainer _person, _person] select (_mode isEqualTo "whole");

if !([_player, _container, objNull] call FUNC(open)) exitWith {false};

if (!_quiet) then {
    [_player, _person, false] call FUNC(notifyPerson);
};

true
