#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Tells a living person that someone is going through their gear, when the server wants that
 * (aio_gui_personNotify): ACE's own sign that someone is in your backpack - a zipper everyone near
 * hears, a tug for a player (ace_backpacks_fnc_backpackOpened) - and a line of text naming who it is.
 * Once per opening.
 *
 * Arguments:
 * 0: Who is looking <OBJECT>
 * 1: Person <OBJECT>
 * 2: ACE zipped already - the engine opened the backpack, which ACE answers itself <BOOL>
 *    (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [ACE_player, cursorObject] call aio_gui_fnc_notifyPerson;
 *
 * Public: No
 */

params [["_looter", objNull, [objNull]], ["_person", objNull, [objNull]], ["_zipped", false, [false]]];

if (!GVAR(personNotify) || {!alive _person}) exitWith {};

// Only for a real backpack, as ACE asks (ace_backpacks_fnc_isBackpack) - a parachute has no zipper.
private _backpack = backpackContainer _person;

if (!_zipped && {!isNull _backpack} && {!isNil QACEFUNC(backpacks,isBackpack)} && {[_backpack] call ACEFUNC(backpacks,isBackpack)}) then {
    ["ace_backpackOpened", [_person, _backpack], _person] call CBA_fnc_targetEvent;
};

// Shown only where the person is the player (ace_common_fnc_displayTextStructured), in their own
// language: ACE localizes the key there. Nothing to send for AI.
if ([_person] call ACEFUNC(common,isPlayer)) then {
    [QACEGVAR(common,displayTextStructured), [[LSTRING(Notify_Searched), [_looter] call ACEFUNC(common,getName)], 1.5, _person], _person] call CBA_fnc_targetEvent;
};
