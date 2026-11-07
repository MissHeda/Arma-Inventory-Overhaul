#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the window leaves out a row of CBA's item context menu (aio_gui_fnc_cbaOptions): GreenMag Rework's own "Unpack" of a box
 * of rounds, which this addon's row replaces (XEH_postInit, fnc_unpackHere).
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: The row's name <STRING>
 *
 * Return Value:
 * Left out <BOOL>
 *
 * Example:
 * ["gmr_pack_556x45_basic_30", "Unpack"] call aio_compat_greenmag_fnc_hideCbaOption;
 *
 * Public: No
 */

params [["_item", "", [""]], ["_displayName", "", [""]]];

!isNil "gmr_handling_fnc_unpack"
    && {_displayName isEqualTo localize "STR_gmr_handling_Unpack"}
    && {_item isKindOf ["gmr_pack_base", configFile >> "CfgWeapons"]}
