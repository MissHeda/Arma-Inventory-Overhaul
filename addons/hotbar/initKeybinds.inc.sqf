// The keys of the slots: 4 5 6 7 8 9 0 by default, each one changeable in Configure Addons. The code of
// each is made once, here, and calls the function by its name, so a recompiled function still runs.
// Whether the key is taken or left to Arma and ACE is fnc_onKey's answer, which the keybind hands to CBA
// (a handler that reports true blocks the key).
{
    private _index = _forEachIndex;

    [
        [CBA_SETTINGS_AIO, LLSTRING(SubCategory)],
        format [QGVAR(slot%1), _index + 1],
        [format [LLSTRING(Keybind_Slot), _index + 1, _x select 1], LLSTRING(Keybind_Slot_Tooltip)],
        compile format ["[%1] call %2", _index, QFUNC(onKey)],
        {},
        [_x select 0, [false, false, false]]
    ] call CBA_fnc_addKeybind;
} forEach DEFAULT_KEYS;

// Shows the bar for a few seconds. Not bound to a key unless the player wants one.
[
    [CBA_SETTINGS_AIO, LLSTRING(SubCategory)],
    QGVAR(show),
    [LLSTRING(Keybind_Show), LLSTRING(Keybind_Show_Tooltip)],
    {call FUNC(hudPing); false},
    {},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;
