#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A short line for the player about what the "Use items from ..." settings refused: ACE's structured text
 * when ACE has it, the game's hint otherwise.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Cannot reload from the backpack."] call aio_storage_fnc_useHint;
 *
 * Public: No
 */

params [["_text", "", [""]]];

if (_text isEqualTo "") exitWith {};

if (isNil QACEFUNC(common,displayTextStructured)) then {
    hintSilent _text;
} else {
    [_text, 2] call ACEFUNC(common,displayTextStructured);
};
