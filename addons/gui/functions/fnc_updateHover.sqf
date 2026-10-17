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
 * lies in a container or hangs on a body, not the player's own worn one - the
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
 * A frame costs as little as it can: where every grid, slot and info area lies is kept (fnc_hoverGeometry,
 * worked out again only when a column scrolled, a window moved or the lists changed), only the grids whose
 * cells lie under the mouse are asked for a cell, and a mouse that moves inside the cell of the tile found
 * last (or inside its slot), with nothing else reaching into it, finds the same and ends at once - no
 * lookup, no hint, no name at the mouse made again. Nothing is made or deleted unless what the mouse is
 * on changed.
 *
 * Tiles are found through their grid (fnc_screenToCell, fnc_tileAt), so scrolling is taken into
 * account; slots through the areas they registered in (uiNamespace getVariable [QGVAR(slots), []]). A slot that also registered where
 * it lies in its group - a fourth element, the HashMap with "rel" and "parent" fnc_gridOrigin takes -
 * is found where its scrolled group shows it now, and only on the part that shows (fnc_slotRect). A
 * tile gets brighter and, as a slot does, an outline in the accent colour: a tile gets the square frame
 * of the Ctrl selection, two pixels thick (fnc_hoverOutline) - or the cells of a shaped tile (fnc_uiShape) -
 * a slot (weapon, attachment, worn gear, hotbar) a ring with its own round corners (fnc_uiRing); a free
 * cell of a grid that holds things (hover ["cell", grid, column, row]) gets the square frame around that
 * one cell, and no hint but the idle one; there is one outline at a time,
 * for the tile, slot or cell under the mouse, made in the group it lies in so it scrolls and
 * clips with it, and deleted when the mouse leaves (a drag takes the tile's outline away,
 * fnc_startDrag; the footprint shows then). The name at the mouse always lies over that outline: one made
 * on the display itself comes after the name, so the name is made again over it (fnc_raiseTooltip).
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

// What this call did, for the tally of the timing line (fnc_logFrame): "new" unless it ends sooner.
GVAR(hoverNote) = "new";

// What lies on top under the mouse: the inspect card hides all of the inventory under it (fnc_drawInspect),
// a kit window all but its own grids - "inspect" is no grid's window.
private _layer = [_mouse] call FUNC(topAt);
private _held = false;

if (_mouse isNotEqualTo [] && {_layer isNotEqualTo "inspect"}) then {
    _mouse params ["_mouseX", "_mouseY"];

    // Where the grids, slots and info areas lie on the screen (fnc_hoverGeometry): worked out again only when
    // something moved them, not for every mouse move.
    private _geometry = [_force] call FUNC(hoverGeometry);

    _geometry params ["_grids", "", "", "", "", "", "", "_gridBoxes", "_slotBoxes", "_areaBoxes"];

    // Still on the tile or slot found last time, with nothing moved: there is nothing more to look for. The
    // box is the cell (or the slot) with nothing else reaching into it, worked out when it was found.
    private _hold = uiNamespace getVariable [QGVAR(hoverHold), []];

    if (
        !_force && {_hold isNotEqualTo []} && {(_hold select 0) isEqualRef _geometry} && {(_hold select 1) isEqualTo _layer}
        && {GVAR(hover) isEqualTo (_hold select 2)} && {
            (_hold select 3) params ["_holdLeft", "_holdTop", "_holdRight", "_holdBottom"];

            _mouseX >= _holdLeft && {_mouseX < _holdRight} && {_mouseY >= _holdTop} && {_mouseY < _holdBottom}
        }
    ) exitWith {
        _held = true;
    };

    // The first grid of this layer that has a cell under the mouse: only grids whose cells that show lie
    // there are asked.
    private _cell = [];
    private _gridIndex = _gridBoxes findIf {
        _x params ["_grid", "_window", "_visible", "_originX", "_originY", "_box"];
        _box params ["_boxLeft", "_boxTop", "_boxRight", "_boxBottom"];

        _window isEqualTo _layer && {_mouseX >= _boxLeft} && {_mouseX < _boxRight} && {_mouseY >= _boxTop} && {_mouseY < _boxBottom} && {
            _cell = [_grid, _mouse, false, [_visible, _originX, _originY]] call FUNC(screenToCell);
            _cell isNotEqualTo []
        }
    };

    if (_gridIndex >= 0) exitWith {
        private _grid = _grids select _gridIndex;
        private _tileIndex = [_grid, _cell] call FUNC(tileAt);

        // A free cell of a grid that holds things is found too, to get its outline; a grid that only shows
        // (a list, the overflow row) has no free cell to point at.
        if (_tileIndex >= 0) then {
            _found = ["tile", _gridIndex, _tileIndex];
        } else {
            if (!(_grid getOrDefault ["virtual", true]) && {!(_grid getOrDefault ["overflow", false])}) then {
                _found = ["cell", _gridIndex, _cell select 0, _cell select 1];
            };
        };

        if (_found isNotEqualTo []) then {
            // The cell it lies on, the part of it that shows, unless an earlier grid of the layer reaches into it.

            (_gridBoxes select _gridIndex) params ["", "", "_visible", "_originX", "_originY"];
            _cell params ["_col", "_row"];

            private _pitchW = _grid get "cellW";
            private _pitchH = _grid get "cellH";
            private _holdLeft = _originX + ((_grid getOrDefault ["colX", []]) param [_col, _col * _pitchW]);
            private _holdTop = _originY + ((_grid getOrDefault ["rowY", []]) param [_row, _row * _pitchH]);
            private _holdRight = _holdLeft + _pitchW;
            private _holdBottom = _holdTop + _pitchH;

            if (_visible isNotEqualTo []) then {
                _visible params ["_visibleX", "_visibleY", "_visibleW", "_visibleH"];

                _holdLeft = _holdLeft max _visibleX;
                _holdTop = _holdTop max _visibleY;
                _holdRight = _holdRight min (_visibleX + _visibleW);
                _holdBottom = _holdBottom min (_visibleY + _visibleH);
            };

            private _clear = true;

            for "_i" from 0 to _gridIndex - 1 do {
                (_gridBoxes select _i) params ["", "_otherWindow", "", "", "", "_otherBox"];
                _otherBox params ["_otherLeft", "_otherTop", "_otherRight", "_otherBottom"];

                if (
                    _otherWindow isEqualTo _layer && {_otherLeft < _holdRight} && {_otherRight > _holdLeft}
                    && {_otherTop < _holdBottom} && {_otherBottom > _holdTop}
                ) exitWith {
                    _clear = false;
                };
            };

            uiNamespace setVariable [QGVAR(hoverHold), [[], [_geometry, _layer, _found, [_holdLeft, _holdTop, _holdRight, _holdBottom]]] select _clear];
        };
    };

    // The slots all lie in the columns and on the equipment cards, under every window.
    if (_layer isNotEqualTo "") exitWith {};

    private _slotIndex = _slotBoxes findIf {
        _x params ["_left", "_top", "_right", "_bottom"];

        _mouseX >= _left && {_mouseX < _right} && {_mouseY >= _top} && {_mouseY < _bottom}
    };

    if (_slotIndex >= 0) then {
        _found = ["slot", _slotIndex];

        // Its box, unless a grid of the columns or an earlier slot reaches into it.
        (_slotBoxes select _slotIndex) params ["_holdLeft", "_holdTop", "_holdRight", "_holdBottom"];

        private _clear = (_gridBoxes findIf {
            _x params ["", "_window", "", "", "", "_other"];
            _other params ["_otherLeft", "_otherTop", "_otherRight", "_otherBottom"];

            _window isEqualTo "" && {_otherLeft < _holdRight} && {_otherRight > _holdLeft} && {_otherTop < _holdBottom} && {_otherBottom > _holdTop}
        }) < 0 && {
            (_slotBoxes select [0, _slotIndex]) findIf {
                _x params ["_otherLeft", "_otherTop", "_otherRight", "_otherBottom"];

                _otherLeft < _holdRight && {_otherRight > _holdLeft} && {_otherTop < _holdBottom} && {_otherBottom > _holdTop}
            } < 0
        };

        uiNamespace setVariable [QGVAR(hoverHold), [[], [_geometry, _layer, _found, [_holdLeft, _holdTop, _holdRight, _holdBottom]]] select _clear];
    } else {
        // The weight card and the captions (fnc_infoHint).
        private _infoIndex = _areaBoxes findIf {
            _x params ["_left", "_top", "_right", "_bottom"];

            _mouseX >= _left && {_mouseX < _right} && {_mouseY >= _top} && {_mouseY < _bottom}
        };

        if (_infoIndex >= 0) then {
            _found = ["info", _infoIndex];
        };
    };
};

// Nothing else to do: the hover is what it was.
if (_held) exitWith {
    GVAR(hoverNote) = "held";
};

private _fnc_tile = {
    params ["", "_gridIndex", "_tileIndex"];

    (((uiNamespace getVariable [QGVAR(grids), []]) param [_gridIndex, createHashMap]) getOrDefault ["tiles", []]) param [_tileIndex, createHashMap]
};

// Whether a ring was made on the display itself just now: it lies over what was made before it, the name at
// the mouse included, which is then made again over it (fnc_raiseTooltip).
private _ringMade = false;

// A tile in its own colour, or a little brighter; the outline around a tile, a slot or a free cell, or hidden.
private _fnc_light = {
    params ["_hover", "_on"];

    // Only tiles, slots and free cells light up.
    if !((_hover param [0, ""]) in ["tile", "slot", "cell"]) exitWith {};

    // The outline goes with the hover, whichever it was.
    if (!_on) then {
        {ctrlDelete _x} forEach (uiNamespace getVariable [QGVAR(hoverRing), []]);
        uiNamespace setVariable [QGVAR(hoverRing), []];
    };

    // A slot: a ring with the slot's round corners (fnc_uiRing) - made in its column's group where it has
    // one, so it scrolls and clips with the slot. It stays while the mouse is on that slot and goes with it.
    if ((_hover select 0) isEqualTo "slot") exitWith {
        if (!_on) exitWith {};

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

        // The ring follows the round corners of the slot's own panel (fnc_drawSlot's radius).
        private _radius = (GVAR(theme) getOrDefault ["radius", 0]) min ((_rect select 3) / 4);

        uiNamespace setVariable [QGVAR(hoverRing), [
            _display, _parent, _rect, GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]], _radius
        ] call FUNC(uiRing)];

        // In a group it lies under the name anyway: the group was made before it.
        if (isNull _parent) then {
            _ringMade = true;
        };
    };

    // A free cell: the same outline around that one cell, in the group of its grid so it scrolls with it.
    if ((_hover select 0) isEqualTo "cell") exitWith {
        if (!_on) exitWith {};

        if ((uiNamespace getVariable [QGVAR(hoverRing), []]) isNotEqualTo []) exitWith {};

        _hover params ["", "_cellGridIndex", "_cellCol", "_cellRow"];

        private _cellGrid = (uiNamespace getVariable [QGVAR(grids), []]) param [_cellGridIndex, createHashMap];

        if (count _cellGrid == 0) exitWith {};

        private _cellParent = _cellGrid getOrDefault ["parent", controlNull];
        private _cellRect = [_cellGrid, _cellGrid get "rel", _cellCol, _cellRow] call FUNC(spanRect);

        uiNamespace setVariable [QGVAR(hoverRing), [_display, _cellParent, _cellRect] call FUNC(hoverOutline)];

        if (isNull _cellParent) then {
            _ringMade = true;
        };
    };

    private _tile = _hover call _fnc_tile;

    // A tile: the same outline around its footprint, wide and high as it lies (turned too), in the group of
    // its column so it scrolls with the tile.
    if (_on && {(uiNamespace getVariable [QGVAR(hoverRing), []]) isEqualTo []}) then {
        private _tileGrid = (uiNamespace getVariable [QGVAR(grids), []]) param [_hover select 1, createHashMap];
        private _box = _tile getOrDefault ["rect", []];

        if (_box isNotEqualTo [] && {count _tileGrid > 0}) then {
            private _tileParent = _tileGrid getOrDefault ["parent", controlNull];
            private _tileHoles = _tile getOrDefault ["holes", []];
            private _outline = [];

            // A shaped tile on its own cells, as its border is drawn (fnc_createTile), two pixels thick.
            if (
                _tileHoles isNotEqualTo [] && {((_tile getOrDefault ["col", 0]) + (_tile getOrDefault ["w", 1])) <= (_tileGrid getOrDefault ["cols", 0])}
            ) then {
                private _footprint = [_tile getOrDefault ["w", 1], _tile getOrDefault ["h", 1], _tileHoles];
                private _onGrid = [_tileGrid, _tile getOrDefault ["col", 0], _tile getOrDefault ["row", 0]];
                private _accent = GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]];

                {
                    _outline append ([
                        _display, _tileParent, [_box select 0, _box select 1], _tileGrid get "cellW", _tileGrid get "cellH",
                        _footprint, _accent, "frame", _x, _onGrid
                    ] call FUNC(uiShape));
                } forEach [0, 1];
            } else {
                _outline = [_display, _tileParent, _box] call FUNC(hoverOutline);
            };

            uiNamespace setVariable [QGVAR(hoverRing), _outline];

            // In a group it lies under the name anyway: the group was made before it.
            if (isNull _tileParent) then {
                _ringMade = true;
            };
        };
    };

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
    GVAR(hoverNote) = "same";

    // A slot that did not change still moves when its column scrolls under a mouse that stands still - and
    // gets its ring again when a part was drawn anew under it (fnc_redrawPart), over the name at the mouse.
    // A tile gets its outline back after a drag that left it where it was (fnc_endDrag).
    if ((_found param [0, ""]) in ["slot", "tile", "cell"]) then {
        [_found, true] call _fnc_light;

        if (_ringMade) then {
            [] call FUNC(raiseTooltip);
        };
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

    // Not over a context menu or the inspect card, nor while something is dragged (a hotbar slot's binding too).
    if ((uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [] || {GVAR(dragging)} || {GVAR(stripDrag) isNotEqualTo []}) then {
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

    // The ring made above lies over the name just set: the name is made again over it.
    if (_ringMade) then {
        [] call FUNC(raiseTooltip);
    };
};

// A hotbar slot's binding being dragged writes its own hint (fnc_updateStripDrag).
if (isNull (uiNamespace getVariable [QGVAR(hint), controlNull]) || {GVAR(stripDrag) isNotEqualTo []}) exitWith {};

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

        // The size it takes - a row of ACE's list (a source grid's tile) brings the item's true size, the
        // row itself being one cell.
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

        // Waiting for the hands (fnc_queueMoves): a click on it cancels.
        if ((_tile getOrDefault ["queued", 0]) > 0) then {
            [LLSTRING(Hint_Queued), "accent"] call _fnc_add;
        };

        // Where the settings "Use items from ..." limit what can be used: said on an item of the player's own
        // uniform, vest or backpack that cannot be used from there, or that was whitelisted for it.
        if (missionNamespace getVariable [QEGVAR(storage,useActive), false]) then {
            private _useGrid = (uiNamespace getVariable [QGVAR(grids), []]) param [_shown select 1, createHashMap];
            private _useKind = [_useGrid getOrDefault ["container", objNull]] call EFUNC(storage,useKind);

            switch ([_class, _useKind] call EFUNC(storage,useState)) do {
                case "blocked": {
                    // Kept out of the container altogether (Strict mode), or only not usable from it.
                    private _hint = [LLSTRING(Hint_UseBlocked), LLSTRING(Hint_UseHidden)] select (_tile getOrDefault ["hidden", false]);

                    [format [_hint, [_useKind] call EFUNC(storage,useKindName)], "warn"] call _fnc_add;
                };
                case "allowed": {
                    [format [LLSTRING(Hint_UseAllowed), [_useKind] call EFUNC(storage,useKindName)], "accent"] call _fnc_add;
                };
            };
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

        // To be taken off once the hands are free (fnc_queueMoves): a click on the slot cancels.
        if (([_record param [6, objNull], _record param [5, ""]] call FUNC(queuedSlot)) > 0) then {
            [LLSTRING(Hint_Queued), "accent"] call _fnc_add;
        };

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
