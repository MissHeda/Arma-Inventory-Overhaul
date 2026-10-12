#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A click that did not become a drag (the "click" hook): Ctrl and Shift+Ctrl on a card add, on an item of
 * the soldier's give back; Alt equips; a double click uses - weapons, gear and assigned items are put on,
 * attachments attached, magazines loaded, a kit or a container opened; Shift and a double click toggles the
 * favorite; a click on a slot browses its category; a click on a free cell chooses the container as the
 * target of quick adds.
 *
 * Faces, voices and insignia are applied by a double click or Ctrl+click and have no favorites. A plain
 * click on a card while the inspect card is open shows that item on it. Alt+click on a tile of his own, and
 * a double click in a kit's window, are the inventory's (equip; the kit's own rules): the answer is false
 * there, and the window goes on with it.
 *
 * Arguments:
 * 0: "single" or "double" <STRING>
 * 1: What was clicked: type, grid, tile, cell, slot and source <HASHMAP>
 * 2: Shift held <BOOL>
 * 3: Ctrl held <BOOL>
 * 4: Alt held <BOOL>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * ["single", _target, false, true, false] call einv_arsenal_fnc_onClick;
 *
 * Public: No
 */

params [
    ["_click", "single", [""]], ["_target", createHashMap, [createHashMap]], ["_shift", false, [false]],
    ["_ctrl", false, [false]], ["_alt", false, [false]]
];

private _unit = GVAR(center);

if (isNull _unit) exitWith {false};

private _grids = uiNamespace getVariable [QEGVAR(gui,grids), []];
private _gridIndex = _target getOrDefault ["grid", -1];
private _tileIndex = _target getOrDefault ["tile", -1];
private _grid = _grids param [_gridIndex, createHashMap];
private _handled = false;

switch (_target getOrDefault ["type", ""]) do {
    case "tile": {
        private _tile = (_grid getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];
        private _class = _tile getOrDefault ["class", ""];

        if (count _tile > 0 && {_class isNotEqualTo ""}) then {
            if ((_grid getOrDefault ["source", ""]) isNotEqualTo "") then {
                // ----- A card -----
                private _kind = _tile getOrDefault ["kind", ""];
                private _identity = _kind in ["face", "voice", "insignia"];

                _handled = true;

                if (_click isEqualTo "double") then {
                    if (_identity) then {
                        [_kind, _class] call FUNC(applyIdentity);
                    } else {
                        if (_shift) then {
                            [_class] call FUNC(toggleFavorite);
                        } else {
                            if (_kind in [
                                "rifle", "handgun", "launcher", "binocular", "headgear", "goggles", "nvg", "uniform", "vest", "backpack",
                                "map", "gps", "radio", "compass", "watch", "muzzle", "optic", "rail", "bipod"
                            ]) then {
                                [_class] call FUNC(equipItem);
                            } else {
                                // A magazine is loaded when the target is a magazine slot, else added.
                                private _slot = GVAR(targetSlot);

                                if (_kind in ["magazine", "grenade"] && {_slot isNotEqualTo ""} && {[_unit, _slot, _class] call EFUNC(storage,slotAccepts)}) then {
                                    [_class, _slot] call FUNC(equipItem);
                                } else {
                                    [_class, 1] call FUNC(quickAdd);
                                };
                            };
                        };
                    };
                } else {
                    switch (true) do {
                        case (_ctrl): {
                            if (_identity) then {
                                [_kind, _class] call FUNC(applyIdentity);
                            } else {
                                [_class, [1, missionNamespace getVariable [QGVAR(quickAddAmount), 5]] select _shift] call FUNC(quickAdd);
                            };
                        };
                        case (_alt && {!_identity}): {
                            [_class] call FUNC(equipItem);
                        };
                        default {
                            // The inspect card follows what is clicked, for quick browsing.
                            if (EGVAR(gui,inspect) isNotEqualTo [] && {!_identity}) then {
                                [_class] call EFUNC(gui,inspect);
                            };
                        };
                    };
                };
            } else {
                // ----- A tile of the soldier's -----
                if (_ctrl) then {
                    _handled = true;
                    [[_gridIndex, _tileIndex], -1] call FUNC(giveBack);
                } else {
                    // A kit's window keeps the inventory's rules; so does Alt+click.
                    if (_click isEqualTo "double" && {(_grid getOrDefault ["kit", ""]) isEqualTo ""} && {!_alt}) then {
                        _handled = true;

                        // A kit opens or closes, a uniform, vest or backpack lying in storage opens as a section,
                        // anything else is put on.
                        private _opened = !isNil QEFUNC(compat_efak,toggle) && {[_gridIndex, _tileIndex, true] call EFUNC(compat_efak,toggle)};

                        if (!_opened && {!([_gridIndex, _tileIndex] call EFUNC(gui,openNested))}) then {
                            [_gridIndex, _tileIndex] call EFUNC(gui,quickEquip);
                        };
                    };
                };
            };
        };
    };
    case "slot": {
        private _index = _target getOrDefault ["slot", -1];
        private _record = (uiNamespace getVariable [QEGVAR(gui,slots), []]) param [_index, []];
        private _slot = _record param [5, ""];

        if (_slot isNotEqualTo "" && {(_record param [6, objNull]) isEqualTo _unit}) then {
            if (_ctrl && {(_record param [1, ""]) isNotEqualTo ""}) then {
                _handled = true;
                [[_unit, _slot]] call FUNC(giveBack);
            } else {
                if (!_ctrl && {!_alt}) then {
                    _handled = [_index] call FUNC(onSlotClick);
                };
            };
        };
    };
    case "cell": {
        // Free cells of one of his containers: that container is where quick adds go.
        if (!_ctrl && {!_alt} && {_click isEqualTo "single"}) then {
            private _container = _grid getOrDefault ["container", objNull];

            if (!isNull _container && {(_grid getOrDefault ["kit", ""]) isEqualTo ""} && {!(_grid getOrDefault ["virtual", true])} && {(_grid getOrDefault ["window", ""]) isEqualTo ""}) then {
                _handled = true;

                if (GVAR(targetContainer) isEqualTo _container) then {
                    GVAR(targetContainer) = objNull;
                } else {
                    GVAR(targetContainer) = _container;
                    [LLSTRING(Hint_Target)] call FUNC(message);
                };

                [uiNamespace getVariable [QEGVAR(gui,display), displayNull]] call FUNC(drawTargets);
            };
        };
    };
    default {};
};

_handled
