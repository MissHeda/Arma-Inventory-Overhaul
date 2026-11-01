#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A short message to the player at the bottom of the screen: ACE's own (ace_common_fnc_displayTextPicture with a picture,
 * ace_common_fnc_displayTextStructured without) when ACE is loaded, else a silent hint - ACE is no requirement of the mod.
 *
 * Arguments:
 * 0: The text, plain or structured <STRING, TEXT>
 * 1: A picture shown with it, "" for none <STRING> (default: "")
 * 2: Its colour, for the picture <ARRAY> (default: [1, 1, 1, 1])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Not with a weapon in your hands"] call aio_main_fnc_showText;
 *
 * Public: No
 */

params [["_text", "", ["", text ""]], ["_picture", "", [""]], ["_colour", [1, 1, 1, 1], [[]]]];

if (_text isEqualTo "" || {!hasInterface}) exitWith {};

if (_picture isNotEqualTo "" && {!isNil QACEFUNC(common,displayTextPicture)}) exitWith {
    [_text, _picture, _colour, PLAYER_UNIT, 2] call ACEFUNC(common,displayTextPicture);
};

if (!isNil QACEFUNC(common,displayTextStructured)) exitWith {
    [_text] call ACEFUNC(common,displayTextStructured);
};

hintSilent ([_text, parseText _text] select (_text isEqualType ""));
