#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows, the moment something is lifted, which containers cannot carry it by weight - before the mouse gets
 * anywhere near. Every container on the screen (the registry fnc_drawSection keeps, uiNamespace loadBars)
 * is asked what a drop of this many would do (einv_storage_fnc_roomByWeight):
 *
 *   - its load bar gets a preview of what the item would add, red where it does not fit, light where it
 *     does;
 *   - one that cannot take it turns its free cells red (the theme's cellBlocked) and its load text reads
 *     "Too heavy - 0.1 kg left", the icon and the chip beside it out of the way;
 *   - when the item comes from outside the unit's own gear - another container, a body, a catalog - the
 *     weight card gets a preview of the weight it would add, in the colour of the tier it would put the soldier
 *     in.
 *
 * Called at lift with create true (fnc_startDrag; the previews are made before the ghost, which has to stay
 * the last control made) and again after every change of count (fnc_onMouseZ), when it only moves, colours and
 * words what lift made. Not for several tiles at once (fnc_groupMode shows those), nor for what lies in a
 * kit's grid (Enhanced First Aid Kits decides for itself). fnc_clearWeightMarks puts everything back.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Entry that is dragged <HASHMAP>
 * 2: How many of a stack, at least 1 <NUMBER>
 * 3: Make the previews - at lift <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _entry, 5, true] call einv_gui_fnc_markWeight;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_entry", createHashMap, [createHashMap]], ["_count", 1, [0]], ["_create", false, [false]]];

if (count _entry == 0) exitWith {};

private _theme = GVAR(theme);
private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _records = uiNamespace getVariable [QGVAR(loadBars), []];

// Where it comes from: none for a slot's item.
GVAR(press) params ["_sourceIndex", "", "", "", "", ["_slotSource", []]];

private _sourceGrid = if (_slotSource isEqualTo []) then {_grids param [_sourceIndex, createHashMap]} else {createHashMap};
private _sourceBox = _sourceGrid getOrDefault ["container", objNull];

// What goes, in config mass.
private _stack = (_entry getOrDefault ["count", 1]) max 1;
private _taking = (_count max 1) min _stack;
private _need = ([[_entry]] call EFUNC(storage,getMass)) * _taking / _stack;

private _fnc_kg = {
    params ["_mass"];

    private _kg = (_mass max 0) * MASS_TO_KG;

    _kg toFixed ([1, 2] select (_kg < 1))
};

// ---------------------------------------------------------------------------
// The containers
// ---------------------------------------------------------------------------
if ((_sourceGrid getOrDefault ["kit", ""]) isEqualTo "") then {
    {
        private _record = _x;
        private _container = _record getOrDefault ["container", objNull];

        if (isNull _container || {_container isEqualTo _sourceBox}) then {continue};

        // A kit's own grid is the kit's to judge.
        if ((_record get "grids") findIf {((_grids param [_x, createHashMap]) getOrDefault ["kit", ""]) isNotEqualTo ""} >= 0) then {continue};

        private _room = [_container, _entry, _taking] call EFUNC(storage,roomByWeight);
        private _fits = _room get "fits";

        (_record get "bar") params ["_barX", "_barY", "_barW", "_barH"];

        private _maxLoad = _record get "maxLoad";
        private _mass = _record get "mass";
        private _from = 1;
        private _to = 1;

        if (_maxLoad > 0) then {
            _from = (_mass / _maxLoad) min 1;
            _to = ((_mass + _need) / _maxLoad) min 1;
        };

        private _rect = [_barX + _barW * _from, _barY, (_barW * (_to - _from)) max pixelW, _barH];

        private _color = _theme getOrDefault [["text", "loss"] select !_fits, [1, 1, 1, 1]];
        _color = [_color select 0, _color select 1, _color select 2, PREVIEW_ALPHA];

        private _preview = _record get "preview";

        // At lift: one panel in the bar's own group, over the fill.
        if (_create && {isNull _preview}) then {
            _preview = [_display, "EINV_PanelRect", _record get "parent", _rect] call FUNC(uiCreate);
            _record set ["preview", _preview];
        };

        if (!isNull _preview) then {
            _preview ctrlSetPosition _rect;
            _preview ctrlSetBackgroundColor _color;
            _preview ctrlCommit 0;
        };

        private _tinted = _record get "tinted";
        private _label = _record get "label";

        if (_fits) then {
            // Back to what it was - the wheel took fewer, and these fit now.
            {
                _x ctrlSetBackgroundColor (_record get "cellColor");
            } forEach _tinted;

            _record set ["tinted", []];

            if (!isNull _label && {_record get "worded"}) then {
                _label ctrlSetText (_record get "text");
                _label ctrlSetTextColor (_record get "color");
                _label ctrlSetPosition (_record get "labelRect");
                _label ctrlCommit 0;

                {_x ctrlShow true} forEach (_record get "extras");
                _record set ["worded", false];
            };
        } else {
            // Its free cells red - the ones under a tile are hidden and stay so. They go back to the colour the
            // section drew them in (the record's cellColor).
            if (_tinted isEqualTo []) then {
                private _blocked = _theme getOrDefault ["cellBlocked", [0.941, 0.333, 0.353, 0.18]];

                {
                    {
                        if (ctrlShown _x) then {
                            _tinted pushBack _x;
                            _x ctrlSetBackgroundColor _blocked;
                        };
                    } forEach ((_grids param [_x, createHashMap]) getOrDefault ["cells", []]);
                } forEach (_record get "grids");

                _record set ["tinted", _tinted];
            };

            // Its load text says how much room is left, over the icon and the chip.
            if (!isNull _label) then {
                (_record get "labelRect") params ["_labelX", "_labelY", "_labelW", "_labelH"];

                private _text = [format [LLSTRING(Load_TooHeavy), [_room get "free"] call _fnc_kg], _theme] call FUNC(caption);
                private _textW = ((_text getTextWidth [_theme getOrDefault ["font", "PuristaMedium"], UNIT * 0.46]) * TEXT_SLACK) + SQUARE(UNIT * 0.3);
                private _wider = _textW max _labelW;

                _label ctrlSetText _text;
                _label ctrlSetTextColor (_theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]]);
                _label ctrlSetPosition [_labelX + _labelW - _wider, _labelY, _wider, _labelH];
                _label ctrlCommit 0;

                {_x ctrlShow false} forEach (_record get "extras");
                _record set ["worded", true];
            };
        };
    } forEach _records;
};

// ---------------------------------------------------------------------------
// The weight card: what it would add to the soldier, from outside his own gear
// ---------------------------------------------------------------------------
private _bar = uiNamespace getVariable [QGVAR(weightBar), createHashMap];

private _external = switch (true) do {
    case ((_sourceGrid getOrDefault ["kit", ""]) isNotEqualTo ""): {false};
    case (_slotSource isNotEqualTo []): {(_slotSource select 0) isNotEqualTo GVAR(unit)};
    case ((_sourceGrid getOrDefault ["source", ""]) isNotEqualTo ""): {true};
    default {!isNull _sourceBox && {!([_sourceBox] call FUNC(isOwnStorage))}};
};

// fnc_updateDrag warns what a pick-up would make of the soldier only for what comes from outside his gear.
uiNamespace setVariable [QGVAR(dragExternal), _external];

if (count _bar > 0 && {_external}) then {
    private _limits = _bar get "limits";
    private _load = _bar get "load";
    private _end = (_limits get "critical") max 1;
    private _tier = [_bar get "unit", _load + _need] call EFUNC(weight,getTier);

    (_bar get "rect") params ["_barX", "_barY", "_barW", "_barH"];

    private _from = (_load / _end) min 1;
    private _to = ((_load + _need) / _end) min 1;
    private _rect = [_barX + _barW * _from, _barY, (_barW * (_to - _from)) max pixelW, _barH];

    private _color = _theme getOrDefault [["text", "warn", "loss", "loss"] select _tier, [1, 1, 1, 1]];
    _color = [_color select 0, _color select 1, _color select 2, PREVIEW_ALPHA];

    private _preview = uiNamespace getVariable [QGVAR(weightPreview), controlNull];

    if (_create && {isNull _preview}) then {
        _preview = [_display, "EINV_PanelRect", _bar get "parent", _rect] call FUNC(uiCreate);
        uiNamespace setVariable [QGVAR(weightPreview), _preview];
    };

    if (!isNull _preview) then {
        _preview ctrlSetPosition _rect;
        _preview ctrlSetBackgroundColor _color;
        _preview ctrlCommit 0;
    };
};
