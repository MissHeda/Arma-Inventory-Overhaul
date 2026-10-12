#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts a text in the clipboard: through ACE's extension in multiplayer, the game's own in single player.
 *
 * Arguments:
 * 0: The text <STRING>
 *
 * Return Value:
 * Written <BOOL>
 *
 * Example:
 * ["arifle_MX_F"] call einv_arsenal_fnc_clipboardWrite;
 *
 * Public: No
 */

params [["_text", "", [""]]];

if (_text isEqualTo "") exitWith {false};

// The extension takes a text a piece at a time: a call has room for so many bytes.
if (isMultiplayer) exitWith {
    private _chunk = 2500;
    private _written = true;

    for "_at" from 0 to (count _text) - 1 step _chunk do {
        private _answer = "ace" callExtension ["clipboard:append", [_text select [_at, _chunk]]];

        if ((_answer param [1, -1]) != 0) exitWith {
            _written = false;
        };
    };

    if (_written) then {
        "ace" callExtension ["clipboard:complete", []];
    };

    _written
};

copyToClipboard _text;

true
