#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Finds what the mouse is on - a tile on one of the grids, or a dedicated slot - lights it up and names
 * it in the hint: the item's name, its size in cells, a magazine's rounds, a weapon's attachments, and
 * for a slot what the slot is for. On nothing, the hint says what can be done - with several tiles
 * selected, what can be done with them.
 *
 * One more place has something to say, and is found after the slots: the areas that registered themselves
 * in uiNamespace infoAreas - the weight card, a section's caption line (hover ["info", index]) - explain
 * the tiers and what the container's contents weigh (fnc_infoHint). Everything else free, a free cell
 * included, says what can be done.
 *
 * What the pointer carries beside it: the item's name, or - over a vest, uniform, helmet or backpack, one that
 * lies in a container or hangs on a body or in the Arsenal's catalog, not the player's own worn one - the
 * comparison card with what the player wears there (fnc_compareRows, fnc_drawCompare), unless
 * einv_gui_compareTooltip is off. Both are placed beside the pointer by fnc_onFrame; the one that shows is
 * uiNamespace tipShown. A radio of TFAR or ACRE2 brings its channel and frequency after its name, and its
 * channel, frequency, alternate channel and state into the hint (einv_compat_tfar, einv_compat_acre, through
 * fnc_compatCollect - whichever is loaded).
 *
 * A window that attached (fnc_attach) adds to the hint: the "hint" hook is told what the mouse is on
 * ("tile", "slot" or "none", the class, the tile or the slot's record) and answers parts [[text, colour
 * key], ...] written after the window's own - on nothing, the whole hint. A tile may give its size to show
 * ("size") where it is no larger than its cell.
 *
 * Tiles are found through their grid (fnc_screenToCell, fnc_tileAt), so scrolling is taken into
 * account; slots through the areas they registered in (uiNamespace getVariable [QGVAR(slots), []]). A slot that also registered where
 * it lies in its group - a fourth element, the HashMap with "rel" and "parent" fnc_gridOrigin takes -
 * is found where its scrolled group shows it now, and only on the part that shows (fnc_slotRect). A
 * tile gets brighter, a slot an outline in the accent colour that follows its round corners (fnc_uiRing).
 *
 * The box of a uniform, vest or backpack opened from inside a container is named and hinted as its tile
 * in that container (fnc_boxTile), the comparison card included.
 * Only what lies on top there counts (fnc_topAt): over the inspect card nothing, over a kit window only
 * that window's tiles - never a tile or slot of a column or another window under it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Mouse position, [x, y] - [] for "on nothing" <ARRAY>
 * 2: Write the hint even if what the mouse is on did not change <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, getMousePosition] call einv_gui_fnc_updateHover;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_mouse", ["_force", false]];

private _found = [];

// What lies on top under the mouse: the inspect card hides all of the inventory under it (fnc_drawInspect),
// a kit window all but its own grids - "inspect" is no grid's window.
private _layer = [_mouse] call FUNC(topAt);

if (_mouse isNotEqualTo [] && {_layer isNotEqualTo "inspect"}) then {
    _mouse params ["_mouseX", "_mouseY"];

    private _cell = [];
    private _gridIndex = (uiNamespace getVariable [QGVAR(grids), []]) findIf {
        (_x getOrDefault ["window", ""]) isEqualTo _layer && {
            _cell = [_x, _mouse] call FUNC(screenToCell);
            _cell isNotEqualTo []
        }
    };

    if (_gridIndex >= 0) exitWith {
        private _tileIndex = [(uiNamespace getVariable [QGVAR(grids), []]) select _gridIndex, _cell] call FUNC(tileAt);

        if (_tileIndex >= 0) then {
            _found = ["tile", _gridIndex, _tileIndex];
        };
    };

    // The slots all lie in the columns and on the equipment cards, under every window.
    if (_layer isNotEqualTo "") exitWith {};

    private _slotIndex = (uiNamespace getVariable [QGVAR(slots), []]) findIf {
        ([_x] call FUNC(slotRect)) params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];

        _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
    };

    if (_slotIndex >= 0) then {
        _found = ["slot", _slotIndex];
    } else {
        // The weight card and the captions (fnc_infoHint).
        private _infoIndex = (uiNamespace getVariable [QGVAR(infoAreas), []]) findIf {
            ([_x] call FUNC(slotRect)) params [["_left", 0], ["_top", 0], ["_width", 0], ["_height", 0]];

            _mouseX >= _left && {_mouseX < _left + _width} && {_mouseY >= _top} && {_mouseY < _top + _height}
        };

        if (_infoIndex >= 0) then {
            _found = ["info", _infoIndex];
        };
    };
};

private _fnc_tile = {
    params ["", "_gridIndex", "_tileIndex"];

    (((uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap]) getOrDefault ["tiles", []]) param [_tileIndex, createHashMap]
};

// A tile in its own colour, or a little brighter; the slot frame around a slot, or hidden.
private _fnc_light = {
    params ["_hover", "_on"];

    // Only tiles and slots light up.
    if !((_hover param [0, ""]) in ["tile", "slot"]) exitWith {};

    // A slot: an outline in the accent colour that follows its round corners (fnc_uiRing) - made in its
    // column's group where it has one, so it scrolls and clips with the slot. It stays while the mouse is
    // on that slot and goes with it.
    if ((_hover select 0) isEqualTo "slot") exitWith {
        if (!_on) exitWith {
            {ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(hoverRing), []]);
            uiNamespace setVariable [QGVAR(hoverRing), []];
        };

        if ((uiNamespace getVariable [QGVAR(hoverRing), []]) isNotEqualTo []) exitWith {};

        private _slot = (uiNamespace getVariable [QGVAR(slots), []]) param [_hover select 1, []];

        if (_slot isEqualTo []) exitWith {};

        _slot params [["_slotRect", [0, 0, 0, 0]], "", "", ["_anchor", createHashMap]];

        private _parent = controlNull;
        private _rect = _slotRect;

        if (_anchor isEqualType createHashMap && {"rel" in _anchor} && {!isNull (_anchor getOrDefault ["parent", controlNull])}) then {
            _parent = _anchor get "parent";
            _rect = (_anchor get "rel") + [_slotRect select 2, _slotRect select 3];
        };

        private _radius = (GVAR(theme) getOrDefault ["radius", 0]) min ((_rect select 3) / 4);

        uiNamespace setVariable [QGVAR(hoverRing), [
            _display, _parent, _rect, GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]], _radius
        ] call FUNC(uiRing)];
    };

    private _tile = _hover call _fnc_tile;
    private _background = _tile getOrDefault ["background", controlNull];
    private _color = _tile getOrDefault ["color", []];

    if (isNull _background || {_color isEqualTo []}) exitWith {};

    if (_on) then {
        _color = +_color;
        _color set [3, ((_color select 3) + HOVER_ALPHA) min 1];
    };

    // A shaped tile has a surface per run of its cells (fnc_createTile): all of them light up.
    {
        _x ctrlSetBackgroundColor _color;
    } forEach (_tile getOrDefault ["backgrounds", [_background]]);
};

if (!_force && {_found isEqualTo GVAR(hover)}) exitWith {
    // A slot that did not change still moves when its column scrolls under a mouse that stands still.
    if ((_found param [0, ""]) isEqualTo "slot") then {
        [_found, true] call _fnc_light;
    };
};

[GVAR(hover), false] call _fnc_light;
GVAR(hover) = _found;
[_found, true] call _fnc_light;

// The box of a uniform, vest or backpack opened from inside a container is named and hinted as its tile
// there (fnc_boxTile) - it is lifted as that tile too -, though it lights up as the box it is.
private _shown = _found;

if ((_found param [0, ""]) isEqualTo "slot") then {
    private _asTile = [((uiNamespace getVariable [QGVAR(slots), []]) param [_found select 1, []]) param [8, objNull]] call FUNC(boxTile);

    if (_asTile isNotEqualTo []) then {
        _shown = ["tile"] + _asTile;
    };
};

// The name at the mouse, as in Tarkov - of what is known; fnc_onFrame keeps it beside the pointer. Over a
// vest, uniform, helmet or backpack that is not the player's own worn one, the comparison card instead.
private _tooltip = uiNamespace getVariable [QGVAR(tooltip), controlNull];

if (!isNull _tooltip) then {
    private _class = "";
    private _comparable = false;

    switch (_shown param [0, ""]) do {
        case "tile": {
            private _tile = _shown call _fnc_tile;

            if !(_tile getOrDefault ["hidden", false]) then {
                _class = _tile getOrDefault ["class", ""];
                _comparable = true;
            };
        };
        case "slot": {
            private _record = (uiNamespace getVariable [QGVAR(slots), []]) select (_shown select 1);

            _class = _record param [1, ""];

            // The soldier's own worn gear has nothing to be compared with, and a hotbar slot is no item.
            _comparable = (_record param [6, objNull]) isNotEqualTo GVAR(unit) && {(_record param [7, -1]) < 0};
        };
    };

    // Not over a context menu or the inspect card, nor while something is dragged.
    if ((uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [] || {GVAR(dragging)}) then {
        _class = "";
    };

    private _name = if (_class isEqualTo "") then {""} else {[_class] call FUNC(itemName)};

    // A radio: its channel and frequency after the name (einv_compat_tfar, einv_compat_acre).
    if (_name isNotEqualTo "") then {
        private _radioHolder = objNull;

        switch (_shown param [0, ""]) do {
            case "tile": {
                _radioHolder = (_shown call _fnc_tile) getOrDefault ["container", objNull];
            };
            case "slot": {
                private _radioRecord = (uiNamespace getVariable [QGVAR(slots), []]) select (_shown select 1);

                // The long-range radio on the back: the container object of the backpack worn.
                if ((_radioRecord param [5, ""]) isEqualTo "backpack" && {!isNull (_radioRecord param [6, objNull])}) then {
                    _radioHolder = backpackContainer (_radioRecord select 6);
                };
            };
        };

        private _extra = [[QEFUNC(compat_tfar,tooltip), QEFUNC(compat_acre,tooltip)], [_class, _radioHolder]] call FUNC(compatCollect);

        if (_extra isNotEqualTo []) then {
            _name = ([_name] + _extra) joinString "  ·  ";
        };
    };

    // The card of the last hover goes in any case: what it showed is not what the mouse is on now.
    ctrlDelete (uiNamespace getVariable [QGVAR(compare), controlNull]);
    uiNamespace setVariable [QGVAR(compare), controlNull];

    private _compare = [];

    if (_comparable && {_class isNotEqualTo ""} && {missionNamespace getVariable [QGVAR(compareTooltip), true]}) then {
        _compare = [GVAR(unit), _class] call FUNC(compareRows);
    };

    if (_compare isEqualType createHashMap) then {
        private _card = [_display, _compare] call FUNC(drawCompare);

        _tooltip ctrlShow false;
        uiNamespace setVariable [QGVAR(tipShown), _card];
    } else {
        if (_name isNotEqualTo "") then {
            private _font = GVAR(theme) getOrDefault ["font", "PuristaMedium"];
            private _width = (_name getTextWidth [_font, UNIT * 0.58]) * TEXT_SLACK + SQUARE(UNIT * 0.8);

            _tooltip ctrlSetText _name;
            _tooltip ctrlSetPosition [-10, -10, _width, UNIT * 0.85];
            _tooltip ctrlCommit 0;
            _tooltip setVariable [QGVAR(width), _width];
            _tooltip setVariable [QGVAR(height), UNIT * 0.85];
        };

        _tooltip ctrlShow (_name isNotEqualTo "");
        uiNamespace setVariable [QGVAR(tipShown), [controlNull, _tooltip] select (_name isNotEqualTo "")];
    };

    GVAR(tooltipAt) = [];
};

if (isNull (uiNamespace getVariable [QGVAR(hint), controlNull])) exitWith {};

// ----- The hint -----

private _theme = GVAR(theme);
private _font = _theme getOrDefault ["font", "PuristaMedium"];

// Structured text takes its colours as #RRGGBB.
private _fnc_hex = {
    params ["_color"];

    private _digits = "0123456789ABCDEF";

    "#" + (((_color select [0, 3]) apply {
        private _value = round ((_x max 0 min 1) * 255);
        (_digits select [floor (_value / 16), 1]) + (_digits select [_value mod 16, 1])
    }) joinString "")
};

private _parts = [];

private _fnc_add = {
    params ["_text", "_key"];

    if (_parts isNotEqualTo []) then {
        _parts pushBack "    ";
    };

    _parts pushBack (text _text setAttributes [
        "color", [_theme getOrDefault [_key, [1, 1, 1, 1]]] call _fnc_hex,
        "font", _font
    ]);
};

// The names of a weapon's attachments and loaded magazines: its weaponsItems entry less the weapon.
private _fnc_attachments = {
    params ["_weapon"];

    private _names = [];

    {
        private _part = if (_x isEqualType []) then {_x param [0, ""]} else {_x};

        if (_part isEqualType "" && {_part isNotEqualTo ""}) then {
            _names pushBack (([_part] call EFUNC(items,getInfo)) get "name");
        };
    } forEach (_weapon select [1]);

    _names joinString ", "
};

private _fnc_size = {
    params ["_w", "_h"];

    format ["%1×%2", _w, _h]
};

// A weight in kg, with a second decimal under one kg.
private _fnc_kg = {
    params ["_mass"];

    private _kg = _mass * MASS_TO_KG;

    format ["%1 kg", _kg toFixed ([1, 2] select (_kg < 1))]
};

// What the hint says on nothing: the window that attached says what can be done (the "hint" hook) - else, with
// several tiles selected, what can be done with them.
private _fnc_idle = {
    private _own = ["hint", ["none", "", []], []] call FUNC(hook);

    if (_own isNotEqualTo []) exitWith {
        {
            _x call _fnc_add;
        } forEach _own;
    };

    if (count GVAR(selection) >= 2) then {
        [format [LLSTRING(Hint_Selected), count GVAR(selection)], "text2"] call _fnc_add;
    } else {
        [LLSTRING(Hint_Idle), "muted"] call _fnc_add;
    };
};

switch (_shown param [0, ""]) do {
    case "tile": {
        private _tile = _shown call _fnc_tile;

        if (_tile getOrDefault ["hidden", false]) exitWith {
            [LLSTRING(Hint_Hidden), "text2"] call _fnc_add;
            [[_tile getOrDefault ["w", 1], _tile getOrDefault ["h", 1]] call _fnc_size, "muted"] call _fnc_add;
        };

        private _class = _tile getOrDefault ["class", ""];

        // A kit of Enhanced First Aid Kits by the name its player gave it (fnc_itemName), and at what it
        // really weighs - its contents count - and how full it is (einv_compat_efak, when loaded).
        private _kitMass = if (isNil QEFUNC(compat_efak,getMass)) then {-1} else {[_class] call EFUNC(compat_efak,getMass)};
        private _mass = if (_kitMass >= 0) then {_kitMass * (_tile getOrDefault ["count", 1])} else {[[_tile]] call EFUNC(storage,getMass)};

        [[_class] call FUNC(itemName), "text"] call _fnc_add;

        // The size it takes - a catalog card (a source grid's tile) brings the item's true size, the card
        // itself being one cell.
        [(_tile getOrDefault ["size", [_tile getOrDefault ["w", 1], _tile getOrDefault ["h", 1]]]) call _fnc_size, "muted"] call _fnc_add;
        [[_mass] call _fnc_kg, "muted"] call _fnc_add;

        if (!isNil QEFUNC(compat_efak,hintParts)) then {
            {
                _x call _fnc_add;
            } forEach ([_class] call EFUNC(compat_efak,hintParts));
        };

        private _capacity = _tile getOrDefault ["capacity", 0];
        private _count = _tile getOrDefault ["count", 1];

        if (_capacity > 1) then {
            [format ["%1/%2", _tile getOrDefault ["ammo", 0], _capacity], "text2"] call _fnc_add;
        };

        if (_count > 1) then {
            [format ["×%1", _count], "text2"] call _fnc_add;
        };

        private _attachments = _tile getOrDefault ["attachments", []];

        if (_attachments isNotEqualTo []) then {
            private _names = [_attachments] call _fnc_attachments;

            if (_names isNotEqualTo "") then {
                [_names, "text2"] call _fnc_add;
            };
        };

        if (_tile getOrDefault ["overflow", false]) then {
            [LLSTRING(Hint_Overflow), "loss"] call _fnc_add;
        };

        // On the ground a double click puts on what can be worn, and Ctrl+click opens a uniform, vest or
        // backpack (fnc_onMouseButton): said here, where it differs from the footer's keys.
        private _hoverGrid = (uiNamespace getVariable [QGVAR(grids), []]) param [_shown select 1, createHashMap];

        if (
            [] call FUNC(isInventoryMode) && {!(_hoverGrid getOrDefault ["virtual", true])}
            && {[_hoverGrid getOrDefault ["container", objNull]] call EFUNC(storage,isGroundHolder)}
        ) then {
            private _wearSlot = [GVAR(unit), _class] call EFUNC(storage,slotFor);

            if (_wearSlot isNotEqualTo "" && {(_wearSlot find "_") < 0}) then {
                [LLSTRING(Hint_GroundWear), "accent"] call _fnc_add;
            };

            if (!isNull (_tile getOrDefault ["container", objNull])) then {
                [LLSTRING(Hint_GroundOpen), "accent"] call _fnc_add;
            };
        };

        // A radio's channel, frequency, alternate channel and state (einv_compat_tfar, einv_compat_acre).
        {
            _x call _fnc_add;
        } forEach ([[QEFUNC(compat_tfar,hintParts), QEFUNC(compat_acre,hintParts)], [_class, _tile getOrDefault ["container", objNull]]] call FUNC(compatCollect));

        // What the window that attached adds, in the same colours (the "hint" hook).
        {
            _x call _fnc_add;
        } forEach (["hint", ["tile", _class, _tile], []] call FUNC(hook));
    };
    case "slot": {
        private _record = (uiNamespace getVariable [QGVAR(slots), []]) select (_shown select 1);

        // A slot of the hotbar (einv_hotbar - only when that addon is loaded): the hotbar says what it is
        // and what its key does.
        if ((_record param [7, -1]) >= 0 && {!isNil QEFUNC(hotbar,hintParts)}) exitWith {
            {
                _x call _fnc_add;
            } forEach ([_record select 7] call EFUNC(hotbar,hintParts));
        };

        _record params ["", "_class", "_caption", "", ["_weapon", [], [[]]]];

        if (_caption isNotEqualTo "") then {
            [[_caption, _theme] call FUNC(caption), "muted"] call _fnc_add;
        };

        if (_class isEqualTo "") exitWith {
            [LLSTRING(Hint_Empty), "text2"] call _fnc_add;

            {
                _x call _fnc_add;
            } forEach (["hint", ["slot", "", _record], []] call FUNC(hook));
        };

        private _info = [_class] call EFUNC(items,getInfo);

        [[_class] call FUNC(itemName), "text"] call _fnc_add;
        [(_info getOrDefault ["size", [1, 1]]) call _fnc_size, "muted"] call _fnc_add;

        // A weapon slot that did not bring its weapon along shows the unit's own: the attachments come
        // from what the unit wears.
        if (_weapon isEqualTo []) then {
            private _equipment = GVAR(context) getOrDefault ["equipment", createHashMap];

            {
                private _worn = _equipment getOrDefault [_x, []];

                if (_worn isNotEqualTo [] && {(_worn select 0) == _class}) exitWith {
                    _weapon = _worn;
                };
            } forEach ["primary", "handgun", "launcher", "binocular"];
        };

        if (_weapon isNotEqualTo []) then {
            private _names = [_weapon] call _fnc_attachments;

            if (_names isNotEqualTo "") then {
                [_names, "text2"] call _fnc_add;
            };
        };

        // A radio's channel, frequency, alternate channel and state - a long-range one on the back by the
        // backpack's container object (einv_compat_tfar, einv_compat_acre). The dummy radio ACRE2 keeps in
        // the radio slot says so.
        private _radioHolder = objNull;

        if ((_record param [5, ""]) isEqualTo "backpack" && {!isNull (_record param [6, objNull])}) then {
            _radioHolder = backpackContainer (_record select 6);
        };

        {
            _x call _fnc_add;
        } forEach ([[QEFUNC(compat_tfar,hintParts), QEFUNC(compat_acre,hintParts)], [_class, _radioHolder]] call FUNC(compatCollect));

        {
            _x call _fnc_add;
        } forEach (["hint", ["slot", _class, _record], []] call FUNC(hook));
    };
    case "info": {
        private _area = (uiNamespace getVariable [QGVAR(infoAreas), []]) param [_shown select 1, []];
        private _infoParts = [_area param [4, ""], _area param [5, []]] call FUNC(infoHint);

        if (_infoParts isEqualTo []) exitWith {
            call _fnc_idle;
        };

        {
            _x call _fnc_add;
        } forEach _infoParts;
    };
    default {
        call _fnc_idle;
    };
};

(uiNamespace getVariable [QGVAR(hint), controlNull]) ctrlSetStructuredText (composeText _parts setAttributes ["align", "center"]);
