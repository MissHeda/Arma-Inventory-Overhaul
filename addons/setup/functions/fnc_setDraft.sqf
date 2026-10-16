#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes a rules text the draft: read by the rules engine, written out again in its own words - the way
 * the wizard compares, counts and shows it - and compiled, with an empty cache for what items come out
 * as under it. The game is not touched: what is in use changes only with Save.
 *
 * What the engine left out of the text is kept to show on the General step (GVAR(parseWarnings)). Raises
 * einv_setup_draftChanged with the new text, for the steps listening to it.
 *
 * Arguments:
 * 0: Rules text <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["einv1 base=default cell=4"] call einv_setup_fnc_setDraft;
 *
 * Public: No
 */

params [["_text", RULES_DEFAULT, [""]]];

private _ast = [_text] call EFUNC(items,parseRules);

if (isNil "_ast" || {!(_ast isEqualType createHashMap)}) then {
    ERROR_1("The rules engine could not read '%1' - the draft starts from the default.",_text);
    _ast = [RULES_DEFAULT] call EFUNC(items,parseRules);
};

private _canonical = [_ast] call EFUNC(items,writeRules);
private _compiled = [_canonical] call EFUNC(items,compileRules);

if (isNil "_compiled" || {!(_compiled isEqualType createHashMap)}) then {
    _compiled = createHashMap;
};

GVAR(draft) = [_canonical] call EFUNC(items,parseRules);
GVAR(draftText) = _canonical;
GVAR(draftRules) = _compiled;
GVAR(draftCache) = createHashMap;
GVAR(parseWarnings) = +(_ast getOrDefault ["warnings", []]);

[QGVAR(draftChanged), [_canonical]] call CBA_fnc_localEvent;
