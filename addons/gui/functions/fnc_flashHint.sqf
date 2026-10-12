#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Says in the hint why a move did not happen, or how it went, in the loss colour. The next time the
 * mouse lands on something else, the hint names that instead (fnc_updateHover).
 *
 * The window's own reasons come as keys, the storage's as the status its ops answer (fnc_afterAction):
 * someone else was quicker ("Gone"), the cell was just taken ("Taken"), the holder moved meanwhile
 * ("Moved"), out of reach ("OutOfReach"), not into itself ("IntoItself"), several items cannot go into
 * one slot ("GroupNoSlot"), nothing to put it on here ("NoGround"), put elsewhere ("PlacedElsewhere"),
 * the server not ready yet ("NotReady"), locked to the player ("Locked", einv_locks), a backpack into a
 * backpack ("NoBackpack"). A put that
 * bounced never shows by itself - what went back or onto the ground does ("Returned", "Grounded",
 * "MovedSome", each with its counts). Any other text is a reason someone else already put into words -
 * Enhanced First Aid Kits', through einv_compat_efak - and shows as it is; "" says nothing.
 *
 * "TooHeavy" with its details says how much is missing (fnc_weightText), without them only that it is too
 * heavy.
 *
 * Arguments:
 * 0: Reason - "TooHeavy", "NoBackpack", "NoRoom", "NowhereToGo", "NoFit", "LookOnly" (a living person's
 *    gear the settings let the player only look at), "Failed", "Gone", "Taken", "Moved", "OutOfReach",
 *    "IntoItself", "GroupNoSlot", "NoGround", "PlacedElsewhere", "SharedHere", "NotReady", "Locked",
 *    "Waiting", "MovedSome", "Returned", "Grounded", or a text to show <STRING>
 * 1: What the text needs filled in - "MovedSome" how many of how many, "Returned" and "Grounded" how
 *    many, "TooHeavy" the container it did not fit, the tile (a HashMap, or its array as
 *    fnc_sendMoves keeps it) and how many of a stack, -1 for all <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TooHeavy"] call einv_gui_fnc_flashHint;
 * ["MovedSome", [3, 5]] call einv_gui_fnc_flashHint;
 *
 * Public: No
 */

disableSerialization;

params [["_reason", "Failed", [""]], ["_details", [], [[]]]];

private _hint = uiNamespace getVariable [QGVAR(hint), controlNull];

if (isNull _hint) exitWith {};

private _text = switch (_reason) do {
    case "TooHeavy": {
        if (_details isEqualTo []) then {
            LLSTRING(Hint_TooHeavy)
        } else {
            _details params [["_container", objNull, [objNull]], ["_entry", createHashMap, [createHashMap, []]], ["_count", -1, [0]]];

            if (_entry isEqualType []) then {
                _entry = [_entry] call EFUNC(storage,entryFromArray);
            };

            // Said in full, so nothing is filled in afterwards.
            _details = [];

            ["tooHeavy", _container, _entry, _count] call FUNC(weightText)
        }
    };
    case "NoBackpack": {LLSTRING(Hint_NoBackpack)};
    case "Locked": {LELSTRING(locks,Hint_Locked)};
    case "NoRoom": {LLSTRING(Hint_NoRoom)};
    case "NowhereToGo": {LLSTRING(Hint_NowhereToGo)};
    case "NoFit": {LLSTRING(Hint_NoFit)};
    case "LookOnly": {LLSTRING(Hint_LookOnly)};
    case "Gone": {LLSTRING(Hint_Gone)};
    case "Taken": {LLSTRING(Hint_Taken)};
    case "Moved": {LLSTRING(Hint_Moved)};
    case "OutOfReach": {LLSTRING(Hint_OutOfReach)};
    case "IntoItself": {LLSTRING(Hint_IntoItself)};
    case "GroupNoSlot": {LLSTRING(Hint_GroupNoSlot)};
    case "NoGround": {LLSTRING(Hint_NoGround)};
    case "PlacedElsewhere": {LLSTRING(Hint_PlacedElsewhere)};
    case "SharedHere": {LLSTRING(Hint_SharedHere)};
    case "NotReady": {LLSTRING(Hint_NotReady)};
    case "Waiting": {LLSTRING(Hint_Waiting)};
    case "MovedSome": {LLSTRING(Hint_MovedSome)};
    case "Returned": {LLSTRING(Hint_Returned)};
    case "Grounded": {LLSTRING(Hint_Grounded)};
    case "Failed": {LLSTRING(Hint_Failed)};

    // The storage's answers that only follow from another reason - should one ever come alone.
    case "Skipped": {LLSTRING(Hint_Failed)};
    case "NotLocal": {LLSTRING(Hint_Moved)};
    case "Bounced": {""};
    default {_reason};
};

if (_text isEqualTo "") exitWith {};

if (_details isNotEqualTo []) then {
    _text = format ([_text] + _details);
};

private _color = GVAR(theme) getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _hex = "#" + ((_color select [0, 3]) apply {
    private _value = round ((_x max 0 min 1) * 255);
    ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
} joinString "");

_hint ctrlSetStructuredText (text _text setAttributes ["color", _hex]);
