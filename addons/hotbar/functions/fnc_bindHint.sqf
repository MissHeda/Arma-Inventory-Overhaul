#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The hotbar's entry in the key hints beside the mouse (einv_gui_fnc_hoverKeys): "4-0  Hotbar", for an
 * item that may go on the bar from where it lies (fnc_canBindFrom) - the keys the player really has on
 * the first and the last slot, as the footer names them (fnc_footerHint). Nothing for an item the bar has
 * no use for or cannot reach.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Where it lies, as fnc_canBindFrom takes it <ARRAY>
 *
 * Return Value:
 * [key, text] as the key hints are, ["", ""] for none <ARRAY>
 *
 * Example:
 * ["ACE_elasticBandage", ["grid", _grid]] call einv_hotbar_fnc_bindHint;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_from", [], [[]]]];

if (_class isEqualTo "" || {!(call FUNC(isActive))}) exitWith {["", ""]};

if !(([_class, _from] call FUNC(canBindFrom)) select 0) exitWith {["", ""]};

[] call FUNC(footerHint)
