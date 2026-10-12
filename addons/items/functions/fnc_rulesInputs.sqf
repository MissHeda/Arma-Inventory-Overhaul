#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Everything the rules in effect are compiled from, as the settings hold it now: the rules text, the
 * three older tables and the two older sliders. Comparing this with what was compiled last tells
 * whether to compile again (fnc_currentRules, fnc_loadRules). Before the settings exist - another
 * mod asking for an item in its own preInit - each reads as its default. A text given to
 * fnc_loadRules for testing stands in for the setting's until it is cleared.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [rules text (the test text, else the setting's), size table, stack table, container table, small
 * items per tile, mass per cell] <ARRAY>
 *
 * Example:
 * call einv_items_fnc_rulesInputs;
 *
 * Public: No
 */

[
    missionNamespace getVariable [QGVAR(rulesOverride), missionNamespace getVariable [QGVAR(rules), DEFAULT_RULES]],
    missionNamespace getVariable [QGVAR(sizeTable), ""],
    missionNamespace getVariable [QGVAR(stackTable), ""],
    missionNamespace getVariable [QEGVAR(storage,containerTable), ""],
    missionNamespace getVariable [QGVAR(stackSmall), DEFAULT_STACK_SMALL],
    missionNamespace getVariable [QGVAR(massPerCell), DEFAULT_MASS_PER_CELL]
]
