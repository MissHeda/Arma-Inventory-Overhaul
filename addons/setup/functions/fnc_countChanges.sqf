#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many changes the draft holds against what was last saved or loaded: each statement added or taken
 * away (a changed one counts as both), the header - preset and cell size - and the switch to force it
 * over the mission. For the header's "4 changes" and the dots on the steps.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [all changes, header changed, statements changed] <ARRAY>
 *
 * Example:
 * (call einv_setup_fnc_countChanges) select 0;
 *
 * Public: No
 */

([GVAR(clean)] call FUNC(statements)) params ["_cleanHead", "_cleanStatements"];
([GVAR(draftText)] call FUNC(statements)) params ["_draftHead", "_draftStatements"];

private _statements = count (_draftStatements - _cleanStatements) + count (_cleanStatements - _draftStatements);
private _head = _draftHead isNotEqualTo _cleanHead;
private _count = _statements + ([0, 1] select _head) + ([0, 1] select (GVAR(override) isNotEqualTo GVAR(cleanOverride)));

[_count, _head, _statements > 0]
