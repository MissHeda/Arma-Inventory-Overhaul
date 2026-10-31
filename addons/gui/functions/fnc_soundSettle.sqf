#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The dropdown under the speaker in the header (fnc_openSoundMenu) closed, or the volumes were changed with it
 * closed: what the player set is written to the profile - once, here, not with every move of a slider - and
 * the speaker is drawn for the state it is in. Also asked when the window closes with the dropdown open
 * (fnc_onUnload), and by fnc_closeMenu whenever the menu it closes was the dropdown.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_soundSettle;
 *
 * Public: No
 */

// A volume slider still held is let go.
["end"] call FUNC(soundSlide);

if (GVAR(soundDirty)) then {
    GVAR(soundDirty) = false;

    // The first number was the master volume of the earlier dropdown, which is gone: always 1 now, so the saved
    // format stays [number, levels] and an older version reads it.
    profileNamespace setVariable [QGVAR(soundMix), [1, +GVAR(soundLevels)]];
    saveProfileNamespace;
};

uiNamespace setVariable [QGVAR(soundRows), []];

[] call FUNC(updateSoundButton);
