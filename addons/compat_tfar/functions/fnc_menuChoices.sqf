#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The right-click choices of a radio: "Open radio" (TFAR's own dialog for it) and "Use as active radio" -
 * only for the player's own radios, which are the ones TFAR lets them handle: the radio slot, the
 * uniform, vest and backpack, and the long-range radio of the backpack they wear. A radio lying in a crate
 * or on someone else gets nothing. A prototype of the player's own - the vanilla radio in the radio slot, a radio TFAR has
 * not swapped for one of theirs yet - gets "Open radio" too: TFAR is asked to swap it now, and the radio it gives is opened
 * (fnc_openPrototype).
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The backpack object, for a long-range radio <OBJECT> (default: objNull)
 * 2: It is the player's own - in their uniform, vest or backpack, or their slot <BOOL> (default: false)
 * 3: It is asked from a slot, not a tile <BOOL> (default: false)
 *
 * Return Value:
 * Choices for einv_gui_fnc_openMenu, [text, arguments, code] each <ARRAY>
 *
 * Example:
 * ["TFAR_anprc152_1", objNull, true, false] call einv_compat_tfar_fnc_menuChoices;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]], ["_own", false, [false]], ["_inSlot", false, [false]]];

private _choices = [];

switch ([_class] call FUNC(radioType)) do {
    // A short-range radio of the player's own: open it, and make it the one in use if it is not.
    case 1: {
        if (!_own) exitWith {};

        _choices pushBack [LLSTRING(Menu_Open), [_class], {_this call FUNC(open)}];

        private _active = [] call TFAR_fnc_activeSwRadio;

        if (!_inSlot && {isNil "_active" || {_class != _active}}) then {
            _choices pushBack [LLSTRING(Menu_MakeActive), [_class], {_this call FUNC(makeActive)}];
        };
    };

    // A prototype of the player's own: made a radio of theirs first.
    case 2: {
        if (!_own) exitWith {};

        _choices pushBack [LLSTRING(Menu_Open), [_class], {_this call FUNC(openPrototype)}];
    };

    // The long-range radio on the player's own back.
    case 3: {
        if (!isNull _holder && {_holder isEqualTo backpackContainer EGVAR(gui,unit)}) then {
            _choices pushBack [LLSTRING(Menu_Open), [[_holder, "radio_settings"]], {_this call FUNC(open)}];
        };
    };
};

_choices
