#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which group of the picture picker's chips (fnc_drawPicturePicker) a class's pictures belong to, by the
 * wizard's kind of it (fnc_classKind):
 *   "items"    - rifles, handguns, launchers, binoculars, night vision, magazines, attachments, kits, other items
 *                and goggles: the small icons of things carried (CfgWeapons, CfgMagazines, CfgGlasses)
 *   "gear"     - uniforms, vests, headgear and backpacks
 *   "vehicles" - crates and vehicles: their editor pictures (CfgVehicles)
 *
 * Arguments:
 * 0: The class's kind, as the class index has it (ROW_KIND) <STRING>
 *
 * Return Value:
 * "items", "gear" or "vehicles" <STRING>
 *
 * Example:
 * ["uniform"] call aio_setup_fnc_pictureCategory;
 *
 * Public: No
 */

params [["_kind", "", [""]]];

switch (true) do {
    case (_kind in ["uniform", "vest", "headgear", "backpack"]): {"gear"};
    case (_kind in ["crate", "vehicle"]): {"vehicles"};
    default {"items"};
}
