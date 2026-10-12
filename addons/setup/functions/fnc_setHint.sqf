#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts a message into the footer, in a colour of the theme: what a click did - saved, imported, nothing to
 * save. It stays through redraws until the next one replaces it.
 *
 * Arguments:
 * 0: Message, "" for none <STRING>
 * 1: Theme colour: "text2", "gain", "loss", "accent" <STRING> (default: "text2")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Saved.", "gain"] call einv_setup_fnc_setHint;
 *
 * Public: No
 */

disableSerialization;

params [["_text", "", [""]], ["_color", "text2", [""]]];

GVAR(hint) = [_text, _color];

private _ctrl = uiNamespace getVariable [QGVAR(hintCtrl), controlNull];

if (isNull _ctrl) exitWith {};

// Fitted to its place between the keys and the buttons; the whole message is in its tooltip.
_ctrl ctrlSetText ([_text, (ctrlPosition _ctrl) select 2, GVAR(theme) getOrDefault ["font", "PuristaMedium"], TEXT_SMALL] call EFUNC(gui,fitText));
_ctrl ctrlSetTextColor (GVAR(theme) getOrDefault [_color, [0.698, 0.734, 0.784, 1]]);
_ctrl ctrlSetTooltip _text;
