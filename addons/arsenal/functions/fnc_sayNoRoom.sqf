#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Says that something did not go into the open uniform, vest or backpack for want of free cells, and how
 * much room to make for it - "No room in the vest - move things to free a 1x2 space" - in ACE's message
 * line, and in the panel's hint line in the loss colour.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Which container, "uniform", "vest" or "backpack" <STRING>
 * 2: Class that did not go <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, "vest", "30Rnd_65x39_caseless_mag"] call einv_arsenal_fnc_sayNoRoom;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_id", "", [""]], ["_class", "", [""]]];

(([_class] call EFUNC(items,getInfo)) getOrDefault ["size", [1, 1]]) params [["_w", 1], ["_h", 1]];

private _where = switch (_id) do {
    case "uniform": {LLSTRING(Word_Uniform)};
    case "vest": {LLSTRING(Word_Vest)};
    default {LLSTRING(Word_Backpack)};
};

private _text = format [LLSTRING(Message_NoRoom), _where, _w, _h];

[_text, "loss"] call EFUNC(gui,showHint);

if (!isNull _display && {!isNil QACEFUNC(arsenal,message)}) exitWith {
    [_display, _text] call ACEFUNC(arsenal,message);
};

[_text, false, 5, 1] call ACEFUNC(common,displayText);
