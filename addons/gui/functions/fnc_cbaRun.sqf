#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs an option of CBA's item context menu that was chosen in this window's menu (fnc_cbaOptions) -
 * the way CBA runs it (cba_ui_fnc_openItemContextMenu): its condition asked once more, the item used
 * up first when the option says so (CBA_fnc_consumeItem), the statement run apart from this function's
 * own variables. A statement that returns true asks for the menu to stay open: it opens again where it
 * was, now that the option has done its part. Otherwise the window looks at once whether anything
 * changed (fnc_requestRebuild).
 *
 * A statement that closes the window - ACE's progress bar does - closes it as it closes the vanilla
 * inventory.
 *
 * Arguments:
 * 0: Condition <CODE>
 * 1: Statement <CODE>
 * 2: Use the item up first <BOOL>
 * 3: What CBA hands the condition and statement: [unit, container, item, slot, arguments, id] <ARRAY>
 *
 * Return Value:
 * The menu asked to stay open <BOOL>
 *
 * Example:
 * [{true}, {systemChat str _this}, false, [player, vestContainer player, "ACE_EarPlugs", "VEST_CONTAINER", [], "0"]] call einv_gui_fnc_cbaRun;
 *
 * Public: No
 */

params ["_condition", "_statement", ["_consume", false], ["_args", []]];

if !([_args call _condition] param [0, false]) exitWith {false};

if (_consume) then {
    _args params ["_unit", "_container", "_item", "_slot"];

    if !([_unit, _item, _slot, _container] call CBA_fnc_consumeItem) then {
        ERROR_2("Cannot consume %1 from %2.",_item,_slot);
        _statement = {true};
    };
};

// Apart from this function's variables, as CBA runs it: a statement that reads or sets one of the same
// name must not touch these.
private _keepOpen = ([nil] apply {
    private _args = [_args, _statement];
    private ["_condition", "_statement", "_consume"];

    (_args select 0) call (_args select 1)
}) param [0, false];

_keepOpen = _keepOpen isEqualTo true;

if (_keepOpen) then {
    private _at = +GVAR(menuAt);

    [{
        params ["_at"];

        private _display = uiNamespace getVariable [QGVAR(display), displayNull];

        if (!isNull _display) then {
            [_display, _at] call FUNC(contextMenu);
        };
    }, [_at]] call CBA_fnc_execNextFrame;
} else {
    call FUNC(requestRebuild);
};

_keepOpen
