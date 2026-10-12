#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The keys the footer names (the "footerKeys" hook): close, menu, add or give back, equip, give back, hide
 * and the game's night vision key as the player has set it. In the Eden editor Escape cancels instead of
 * closing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Keys [[key, text], ...] <ARRAY>
 *
 * Example:
 * call einv_arsenal_fnc_footerKeys;
 *
 * Public: No
 */

private _keys = [
    [LELSTRING(gui,Key_Escape), [LELSTRING(gui,Close), LLSTRING(Button_Cancel)] select is3DEN],
    [LELSTRING(gui,Key_RightClick), LELSTRING(gui,Menu)],
    [LELSTRING(gui,Key_CtrlClick), LLSTRING(Key_AddGiveBack)],
    [LELSTRING(gui,Key_AltClick), LELSTRING(gui,Equip)],
    [LELSTRING(gui,Key_Delete), LLSTRING(Key_GiveBack)],
    [LLSTRING(Key_Backspace), LLSTRING(Key_Hide)]
];

// The name of the key, without the quotes the game puts round it; none set, none shown.
private _vision = ((actionKeysNamesArray "nightvision") param [0, ""]) splitString """" joinString "";

if (_vision isNotEqualTo "") then {
    _keys pushBack [_vision, LLSTRING(Key_Vision)];
};

_keys
