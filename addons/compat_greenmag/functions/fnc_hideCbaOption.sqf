#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the window leaves out a row of CBA's item context menu (aio_gui_fnc_cbaOptions): GreenMag Rework's own "Unpack" of a box
 * of rounds, which this addon's row replaces (XEH_postInit, fnc_unpackHere). Both have the same name, so the id tells them apart:
 * this addon's row ("greenmag_unpack") is never left out - left out with GreenMag's, its double click found no row and the box was
 * moved instead (Mia, 0.6.75).
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: The row's name <STRING>
 * 2: The row's id <STRING>
 *
 * Return Value:
 * Left out <BOOL>
 *
 * Example:
 * ["gmr_pack_556x45_basic_30", "Unpack"] call aio_compat_greenmag_fnc_hideCbaOption;
 *
 * Public: No
 */

params [["_item", "", [""]], ["_displayName", "", [""]], ["_id", "", [""]]];

!(_id in ["greenmag_unpack", "greenmag_strip"])
    && {!isNil "gmr_handling_fnc_unpack"}
    && {
        (_displayName isEqualTo localize "STR_gmr_handling_Unpack" && {_item isKindOf ["gmr_pack_base", configFile >> "CfgWeapons"]})
        || {_displayName isEqualTo localize "STR_gmr_handling_StripClip" && {_item isKindOf ["gmr_clip_base", configFile >> "CfgWeapons"]}}
    }
