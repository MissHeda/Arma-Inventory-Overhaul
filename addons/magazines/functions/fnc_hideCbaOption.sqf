#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an option other mods put into CBA's item context menu is left out of the window's menu because
 * this addon does it itself: ACE's "Repack Magazines" takes every magazine of the kind out of the unit and
 * puts them back wherever the engine finds room, after closing the window - ours keeps them in place.
 * While repacking is off the option shows and behaves as in the vanilla inventory
 * (einv_gui_fnc_cbaOptions asks).
 *
 * Arguments:
 * 0: Item class <STRING>
 * 1: The option's display name, localized <STRING>
 *
 * Return Value:
 * Leave it out <BOOL>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag", "Repack Magazines"] call einv_magazines_fnc_hideCbaOption;
 *
 * Public: No
 */

params ["", ["_displayName", "", [""]]];

([] call FUNC(isEnabled)) && {_displayName isEqualTo localize "STR_ACE_MagazineRepack_RepackMagazines"}
