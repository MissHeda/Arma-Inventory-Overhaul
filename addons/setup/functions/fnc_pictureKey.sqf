#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What two ways of writing the same texture path have in common: lowercase, every backslash a slash, no
 * slash at the start. "\A3\Soft_F\MRAP_01\Data\UI\MRAP_01_Base_ca.paa" and "a3/soft_f/mrap_01/data/ui/mrap_01_base_ca.paa"
 * are the same file to the engine and give the same key. The picture picker (fnc_drawPicturePicker) finds
 * the picture in use by it - the whole path, never a class that merely owns a similar one - and the
 * catalog (fnc_pictureCatalog) lists a file once however its owners write it.
 *
 * Arguments:
 * 0: Texture path <STRING>
 *
 * Return Value:
 * The key, "" for no path <STRING>
 *
 * Example:
 * ["\A3\Weapons_F\Data\UI\gear_acc_rail_ca.paa"] call einv_setup_fnc_pictureKey;
 *
 * Public: No
 */

params [["_path", "", [""]]];

private _key = ((toLowerANSI _path) splitString "\") joinString "/";

_key regexReplace ["^/+", ""]
