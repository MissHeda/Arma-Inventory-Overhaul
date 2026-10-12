#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The text in the clipboard: through ACE's extension in multiplayer, where the game's own command does not
 * work for a client, the game's own in single player.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * call einv_arsenal_fnc_clipboardRead;
 *
 * Public: No
 */

// ACE's extension reads it for a client in multiplayer, where the game's own command does not work; the
// editor and single player have the game's.
if (isMultiplayer) exitWith {
    ("ace" callExtension ["clipboard:loadout", []]) params [["_text", "", [""]], ["_code", -1, [0]]];

    // No extension, or it could not read: nothing.
    if (_code != 0) then {
        _text = "";
    };

    _text
};

copyFromClipboard
