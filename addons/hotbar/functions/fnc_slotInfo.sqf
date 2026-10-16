#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Everything the bar and the window's row show of one slot: the class, what it does, how many there
 * are, its names, its picture, a line that says what the key does, and the key itself.
 *
 * Arguments:
 * 0: Slot index <NUMBER>
 * 1: Count, when it is known already (fnc_counts); -1 to count it here <NUMBER> (default: -1)
 *
 * Return Value:
 * The slot <HASHMAP>
 *   "class" <STRING>, "kind" <STRING> (fnc_useOf), "count" <NUMBER>, "name" <STRING>, "short" <STRING>,
 *   "picture" <STRING>, "icon" [scale, across, down] <ARRAY> (how the rules draw the picture, icon=; the
 *   plain picture when none), "does" <STRING>, "key" <STRING> ("" for no key)
 *
 * Example:
 * [2] call einv_hotbar_fnc_slotInfo;
 *
 * Public: No
 */

params [["_index", 0, [0]], ["_count", -1, [0]]];

private _class = GVAR(slots) param [_index, ""];
private _info = createHashMapFromArray [
    ["class", _class], ["kind", ""], ["count", 0], ["name", ""], ["short", ""], ["picture", ""], ["icon", ICON_PLAIN], ["does", ""],
    ["key", [_index] call FUNC(keyName)]
];

if (_class isEqualTo "") exitWith {_info};

([_class] call FUNC(useOf)) params ["_kind", "_data"];

_info set ["kind", _kind];

if (_count < 0) then {
    _count = [_class] call FUNC(count);
};

_info set ["count", _count];
_info set ["name", [_class] call EFUNC(gui,itemName)];
_info set ["short", [_class, true] call EFUNC(gui,itemName)];
private _item = [_class] call EFUNC(items,getInfo);

_info set ["picture", _item getOrDefault ["picture", ""]];
_info set ["icon", _item getOrDefault ["icon", ICON_PLAIN]];

// What the key does with it, in a few words.
private _does = switch (_kind) do {
    case "kit": {LLSTRING(Does_Kit)};
    case "throw": {
        [LLSTRING(Does_ThrowVanilla), LLSTRING(Does_Throw)] select (missionNamespace getVariable ["ace_advanced_throwing_enabled", false])
    };
    case "consume": {LLSTRING(Does_Consume)};
    case "reload": {LLSTRING(Does_Reload)};
    case "medical": {
        switch ((_data param [0, ["", "any"]]) select 1) do {
            case "bandage": {LLSTRING(Does_Bandage)};
            case "tourniquet": {LLSTRING(Does_Tourniquet)};
            case "splint": {LLSTRING(Does_Splint)};
            default {LLSTRING(Does_Treat)};
        }
    };
    default {""};
};

_info set ["does", _does];

_info
