#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the player may change what a kit holds, and if not, why - by the window's rules for a living
 * person's gear (aio_gui_fnc_checkTouch). A kit lying in their uniform, vest or backpack, or packed in
 * a kit that does, is part of their gear: taking out of it and packing into it follow the server's
 * "Take and put items" and their reach, as everything else they carry does. Looking into it changes
 * nothing and is never refused here. Another living player's kits are refused before this is asked
 * (fnc_mayReach).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Where it lies, [container, kit] - [] for where the window found it (fnc_locate) <ARRAY>
 *    (default: [])
 *
 * Return Value:
 * "" when allowed, else the reason the hint shows - "LookOnly" or "Failed" <STRING>
 *
 * Example:
 * ["efak_IFAK_7"] call aio_compat_efak_fnc_checkTouch;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_holder", [], [[]]]];

if (_kit isEqualTo "") exitWith {""};

[([_kit, _holder] call FUNC(locate)) select 1, "items"] call EFUNC(gui,checkTouch)
