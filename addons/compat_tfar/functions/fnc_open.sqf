#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens TFAR's dialog for a radio. TFAR refuses to open any dialog while another one is open, so the
 * window steps aside first (einv_gui_fnc_stepAside): it closes, TFAR's own radio menus wait just as long
 * before they open one, and when the dialog is closed the window comes back on the same containers.
 *
 * The radio goes into TFAR's variable and TFAR's dialog function opens it, as TFAR's own menus do: a
 * short-range radio by its class, a long-range one by [backpack object, "radio_settings"].
 *
 * Arguments:
 * 0: The radio - a class name, or [backpack object, "radio_settings"] <STRING or ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["TFAR_anprc152_1"] call einv_compat_tfar_fnc_open;
 *
 * Public: No
 */

params ["_radio"];

[{
    params ["_radio"];

    if (_radio isEqualType "") then {
        TF_sw_dialog_radio = _radio;
        [] call TFAR_fnc_onSwDialogOpen;
    } else {
        TF_lr_dialog_radio = _radio;
        [] call TFAR_fnc_onLrDialogOpen;
    };
}, [_radio]] call EFUNC(gui,stepAside);
