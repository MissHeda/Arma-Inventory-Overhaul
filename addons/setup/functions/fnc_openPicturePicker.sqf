#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the picture picker over the wizard (fnc_popover, in the middle of the screen over a dimmed wizard): a
 * search over every picture of the game's items with a page of thumbnails to click, and a field for any texture
 * path (fnc_drawPicturePicker). A click picks, a second click or "Use picture" takes it.
 *
 * Arguments:
 * 0: The picture set now, "" for none - it fills the path field <STRING> (default: "")
 * 1: Code run when a picture is taken, called with [path, arguments] <CODE>
 * 2: Arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["", {params ["_path"]; systemChat _path}] call einv_setup_fnc_openPicturePicker;
 *
 * Public: No
 */

disableSerialization;

params [["_current", "", [""]], ["_code", {}, [{}]], ["_arguments", []]];

// text - the search; page; picked - a thumbnail clicked; custom - the path field; source - which of the two
// counts, "list" or "custom"; last - the last click, [path, time], for the double click; customOk - the
// path field holds a file the game has
GVAR(picker) = createHashMapFromArray [
    ["text", ""], ["page", 0], ["picked", ""], ["custom", _current], ["source", ["list", "custom"] select (_current isNotEqualTo "")],
    ["last", ["", 0]], ["customOk", false], ["code", _code], ["arguments", _arguments]
];

[uiNamespace getVariable [QGVAR(display), displayNull], [], [SQUARE(UNIT * 34), UNIT * 21], LLSTRING(Pic_Title), {
    params ["_display", "_inner", "_theme"];

    uiNamespace setVariable [QGVAR(pickerArgs), [_display, _inner, _theme]];

    ["all"] call FUNC(drawPicturePicker);
}] call FUNC(popover);
