#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Splits a rules text written by the rules engine (einv_items_fnc_writeRules) into its header and its
 * statements, one string each - what the wizard compares statement by statement: changes counted, edits
 * replayed onto someone else's save, an import added to the own rules.
 *
 * Only for the engine's own text: a statement never holds a comma there - a name's comma is written
 * %2C - so the commas between them are where to cut.
 *
 * Arguments:
 * 0: Rules text, as einv_items_fnc_writeRules writes it <STRING>
 *
 * Return Value:
 * [header, [statement, ...]] <ARRAY>
 *
 * Example:
 * ["einv1 base=default, @grenade > stack=3"] call einv_setup_fnc_statements;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _parts = ((_text splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};

if (_parts isEqualTo []) exitWith {["", []]};

[_parts select 0, _parts select [1]]
