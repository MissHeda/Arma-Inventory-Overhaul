#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a picture from the picker (fnc_drawPicturePicker): closes the popover and hands the path to the code
 * the editor gave when it opened the picker (fnc_openPicturePicker), with that code's arguments. The editor puts
 * it into its working copy and draws itself again; nothing is written to the draft before its Apply.
 *
 * Arguments:
 * 0: The texture path <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["\A3\Weapons_F\Data\UI\gear_acc_rail_ca.paa"] call aio_setup_fnc_pickPicture;
 *
 * Public: No
 */

params [["_path", "", [""]]];

private _code = GVAR(picker) getOrDefault ["code", {}];
private _arguments = GVAR(picker) getOrDefault ["arguments", []];

call FUNC(closePopover);

[_path, _arguments] call _code;
