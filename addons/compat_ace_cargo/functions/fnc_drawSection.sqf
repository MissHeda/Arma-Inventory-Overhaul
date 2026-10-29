#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Draws a cargo section in the loot column (einv_gui_fnc_drawSection hands it over by the section's
 * "drawer"): under the vehicle or crate it belongs to, a caption "CARGO" with the space used and in all,
 * and a card for every loaded thing, in the order ACE keeps them - its picture, its name as ACE has it
 * (the custom name too), its size and damage, and two buttons: Open (or Close) for a crate that has an
 * inventory, which then shows as a section of its own, and Unload.
 *
 * Laid out beside the blocks of the sections above it: the same cell, the same width, the same left edge.
 * Its texts and the rows that hold them (caption line, names, details, buttons) grow with the tile scale as
 * the sections' do (TEXT_UNIT, einv_gui_fnc_textScale), and its tab and hairline take the theme's loot colours.
 * The cards hold no grid - nothing to hover, drag onto or right-click. A button that may not act now is
 * drawn muted and says why in its tooltip and in the hint when pressed (fnc_rowState). While a thing
 * unloads (fnc_startUnload) its Unload button is a bar of the time ACE takes, and a click on it stops it.
 *
 * What a click needs is kept with the cards of this build (uiNamespace); a click from an older build does
 * nothing. The buttons run their code a frame later, so a rebuild from them is safe.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in - the column's <CONTROL>
 * 2: Top of the section in the group <NUMBER>
 * 3: Width the section may take <NUMBER>
 * 4: Section, see fnc_getSections <HASHMAP>
 * 5: Theme <HASHMAP>
 *
 * Return Value:
 * Height used <NUMBER>
 *
 * Example:
 * [_display, _group, 0, 0.3, _section, _theme] call einv_compat_ace_cargo_fnc_drawSection;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_top", "_width", "_section", "_theme"];

private _holder = _section getOrDefault ["vehicle", objNull];

// What is loaded; an object that is gone since the list was made is left out.
private _items = (_section getOrDefault ["items", []]) select {!(_x isEqualType objNull) || {!isNull _x}};

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _colorMuted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _colorLoss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _colorLine = _theme getOrDefault ["line", [1, 1, 1, 0.07]];

// ---------------------------------------------------------------------------
// The block: as wide and where the blocks of the sections above it are (einv_gui_fnc_drawSection).
// ---------------------------------------------------------------------------
([] call EFUNC(gui,getCell)) params ["_cellW", "_cellH"];

private _gridW = STORAGE_COLS * _cellW;
private _gapX = SQUARE(UNIT * 0.35);
private _boxCells = (floor (((_width - _gridW - _gapX) / _cellW) * 2) / 2) min 3;
private _hasBox = _boxCells >= 1.5;
private _blockW = _gridW + ([0, _boxCells * _cellW + _gapX] select _hasBox);
private _blockX = ((_width - _blockW) / 2) max 0;

// ---------------------------------------------------------------------------
// Caption line: the tab on the left, space used and in all on the right, a hairline under both.
// ---------------------------------------------------------------------------
// The caption line and every text of the cards grow with the tile scale (TEXT_UNIT), as einv_gui_fnc_drawSection's do.
private _textUnit = TEXT_UNIT;
private _lineH = _textUnit * 0.62;
private _lineSize = _textUnit * 0.46;
private _tabPad = SQUARE(_lineH * 0.5);

private _used = 0;

{
    _used = _used + (((_x call ACEFUNC(cargo,getSizeItem))) max 0);
} forEach _items;

private _space = format ["%1 / %2", _used, _used + (_holder call ACEFUNC(cargo,getCargoSpaceLeft))];
private _spaceW = (_space getTextWidth [_font, _lineSize]) * TEXT_SLACK + SQUARE(_textUnit * 0.3);

private _caption = [_section getOrDefault ["title", ""], _theme] call EFUNC(gui,caption);
private _tabRoom = _blockW - _spaceW;
private _shown = [_caption, _tabRoom - _tabPad, _fontBold, _lineSize] call EFUNC(gui,fitText);
private _tabW = (((_shown getTextWidth [_fontBold, _lineSize]) * TEXT_SLACK) + _tabPad) min _tabRoom;

// What is looted has its tab and hairline in the theme's loot colours where it has them (lootTab, lootLine; issue 7), as
// the sections above: the cargo is always the loot column's.
private _tabColor = _theme getOrDefault ["lootTab", []];

if (_tabColor isEqualTo []) then {
    _tabColor = _theme getOrDefault ["slotCaptionBg", [0, 0, 0, 0.5]];
};

if ((_theme getOrDefault ["lootLine", []]) isNotEqualTo []) then {
    _colorLine = _theme get "lootLine";
};

if (_shown isNotEqualTo "") then {
    [
        _display, _parent, [_blockX, _top, _tabW, _lineH], _tabColor,
        (_theme getOrDefault ["radius", 0]) min (_lineH / 2)
    ] call EFUNC(gui,uiPanel);
    [_display, _parent, [_blockX, _top, _tabW, _lineH], _shown, _lineSize, _colorText2, _fontBold, 2, "heading"] call EFUNC(gui,uiLabel);
};

[_display, _parent, [_blockX + _blockW - _spaceW, _top, _spaceW, _lineH], _space, _lineSize, _colorText2, _font, 1, "value"] call EFUNC(gui,uiLabel);

private _spaceTip = [_display, "EINV_Hitbox", _parent, [_blockX + _blockW - _spaceW, _top, _spaceW, _lineH]] call EFUNC(gui,uiCreate);
[_spaceTip, LLSTRING(Tip_Space)] call EFUNC(gui,setTooltip);

[_display, _parent, [_blockX, _top + _lineH, _blockW, pixelH], _colorLine] call EFUNC(gui,uiPanel);

// ---------------------------------------------------------------------------
// The cards
// ---------------------------------------------------------------------------
private _cardH = _cellH * 2;
private _cardGap = UNIT * 0.2;
private _cardsTop = _top + _lineH + UNIT * 0.25;
private _radius = (_theme getOrDefault ["radius", 0]) min (_cardH / 4);
private _buttonH = _textUnit * 0.9;
private _buttonGap = SQUARE(UNIT * 0.25);
private _pad = SQUARE(_cardH * 0.1);

// What a click needs, kept for this build only (the buttons find their card by its place in the list).
private _store = uiNamespace getVariable [QGVAR(cards), [-1, []]];

if ((_store select 0) isNotEqualTo EGVAR(gui,buildCount)) then {
    _store = [EGVAR(gui,buildCount), []];
    uiNamespace setVariable [QGVAR(cards), _store];
};

private _cards = _store select 1;

// One button: its label and icon, and the tooltip it says why not with. Muted when it may not act now -
// a press then says why instead (the code below asks fnc_rowState again).
private _fnc_button = {
    params ["_kind", "_at", "_rect", "_text", "_icon", "_enabled", "_tip"];

    private _controls = [
        _display, _parent, _rect, format ["%1|%2|%3", _kind, _at, EGVAR(gui,buildCount)], _text, _icon, _theme,
        {
            params ["_direction", "_buttonId"];

            if (_direction != 1) exitWith {};

            (_buttonId splitString "|") params ["_what", "_index", ["_build", ""]];

            // The click runs a frame later: a window built again meanwhile has other cards at those places.
            if (_build isNotEqualTo str EGVAR(gui,buildCount)) exitWith {};

            ((uiNamespace getVariable [QGVAR(cards), [-1, []]]) select 1) param [parseNumber _index, []] params [["_cardHolder", objNull], ["_cardItem", objNull]];

            if (isNull _cardHolder) exitWith {};

            private _state = [_cardHolder, _cardItem, ACE_player] call FUNC(rowState);

            if (_what isEqualTo "open") exitWith {
                if (_state get "isOpen" || {_state get "canOpen"}) then {
                    [_cardHolder, _cardItem] call FUNC(toggleOpen);
                } else {
                    [_state get "openTip"] call EFUNC(gui,flashHint);
                };
            };

            if (_state get "canUnload") then {
                [_cardHolder, _cardItem] call FUNC(startUnload);
            } else {
                [_state get "unloadTip"] call EFUNC(gui,flashHint);
            };
        },
        false, _lineSize
    ] call EFUNC(gui,uiButton);

    if (!_enabled) then {
        {
            if (ctrlClassName _x in ["EINV_Icon", "EINV_Label"]) then {
                _x ctrlSetTextColor _colorMuted;
            };
        } forEach _controls;
    };

    if (_tip isNotEqualTo "") then {
        [(_controls select -1), _tip] call EFUNC(gui,setTooltip);
    };

    _controls
};

{
    private _item = _x;
    private _isObject = _item isEqualType objNull;
    private _cardTop = _cardsTop + _forEachIndex * (_cardH + _cardGap);
    private _class = _item;

    if (_isObject) then {
        _class = typeOf _item;
    };

    private _state = [_holder, _item, ACE_player] call FUNC(rowState);
    private _size = _item call ACEFUNC(cargo,getSizeItem);
    private _at = _cards pushBack [_holder, _item];

    [_display, _parent, [_blockX, _cardTop, _blockW, _cardH], _theme getOrDefault ["card", [1, 1, 1, 0.055]], _radius] call EFUNC(gui,uiPanel);

    // The picture: what the editor shows of it on its own grey, else the crate icon on a plain box.
    private _pictureRect = [_blockX, _cardTop, 2 * _cellW, _cardH];
    private _preview = [getText (configFile >> "CfgVehicles" >> _class >> "editorPreview")] call EFUNC(gui,safePicture);

    // As the rules draw the class (picture=, icon=): a picture of their own instead of the editor's, and either
    // one larger, smaller or moved inside the box.
    private _cardInfo = [_class] call EFUNC(items,getInfo);
    private _ruled = _cardInfo getOrDefault ["pictureOverride", ""];
    private _own = "";

    if (_ruled isNotEqualTo "" && {(_cardInfo getOrDefault ["picture", ""]) == _ruled}) then {
        _own = [_ruled] call EFUNC(gui,safePicture);
    };

    if (_own isNotEqualTo "" || {_preview isNotEqualTo ""}) then {
        [_display, _parent, _pictureRect, _theme, _own, _preview, _cardInfo getOrDefault ["icon", ICON_PLAIN], _radius] call EFUNC(gui,uiBoxPicture);
    } else {
        _pictureRect params ["_pictureX", "_pictureY", "_pictureW", "_pictureH"];

        [_display, _parent, _pictureRect, _theme getOrDefault ["slot", [1, 1, 1, 0.06]], _radius, _theme getOrDefault ["slotBorder", []]] call EFUNC(gui,uiPanel);
        [
            _display, _parent, [_pictureX + _pictureW * 0.25, _pictureY + _pictureH * 0.25, _pictureW * 0.5, _pictureH * 0.5],
            GUI_TEX(icon_crate_ca), _colorMuted
        ] call EFUNC(gui,uiIcon);
    };

    private _textX = _blockX + (_pictureRect select 2) + _pad;
    private _textW = _blockX + _blockW - _pad - _textX;

    // Its name as ACE has it, the custom name too - in the loss colour when ACE cannot unload it at all.
    private _name = [[_item, true] call ACEFUNC(cargo,getNameItem), _textW, _font, _textUnit * 0.5] call EFUNC(gui,fitText);

    [
        _display, _parent, [_textX, _cardTop + _cardH * 0.1, _textW, _textUnit * 0.7], _name, _textUnit * 0.5,
        [_colorText, _colorLoss] select (_size < 0), _font, 0, "name"
    ] call EFUNC(gui,uiLabel);

    // Size and damage, on the line of the buttons.
    private _details = format [LLSTRING(Size), _size max 0];

    if (_isObject) then {
        _details = _details + "  ·  " + format [LLSTRING(Damage), ((damage _item) * 100) toFixed 0, "%"];
    };

    private _buttonTop = _cardTop + _cardH - _buttonH - _cardH * 0.1;
    private _unloadW = (3 * _cellW) max (((localize "STR_ACE_Cargo_unloadObject") getTextWidth [_font, _lineSize]) * TEXT_SLACK + SQUARE(_buttonH * 1.4));
    private _openText = [LLSTRING(Button_Open), LLSTRING(Button_Close)] select (_state get "isOpen");
    private _openW = (2.5 * _cellW) max ((_openText getTextWidth [_font, _lineSize]) * TEXT_SLACK + SQUARE(_buttonH * 1.4));
    private _unloadX = _blockX + _blockW - _pad - _unloadW;
    private _openX = _unloadX - _buttonGap - _openW;

    [
        _display, _parent, [_textX, _buttonTop, (_openX - _buttonGap - _textX) max 0, _buttonH],
        [_details, (_openX - _buttonGap - _textX) max 0, _font, _textUnit * 0.42] call EFUNC(gui,fitText), _textUnit * 0.42, _colorText2, _font, 0, "hint"
    ] call EFUNC(gui,uiLabel);

    // Open or Close - Close is always possible.
    [
        "open", _at, [_openX, _buttonTop, _openW, _buttonH], _openText, GUI_TEX(icon_inventory_ca),
        _state get "isOpen" || {_state get "canOpen"}, [_state get "openTip", ""] select (_state get "isOpen")
    ] call _fnc_button;

    // Unload - or, while this thing unloads, the bar of ACE's time: a click on it stops.
    private _unloadRect = [_unloadX, _buttonTop, _unloadW, _buttonH];

    if (GVAR(unloading) isNotEqualTo [] && {(GVAR(unloading) select 0) isEqualTo _item}) then {
        GVAR(unloading) params ["", "", "_start", "_duration"];

        private _fraction = ((CBA_missionTime - _start) / (_duration max 0.01)) max 0 min 1;

        [_display, _parent, _unloadRect, _theme getOrDefault ["barTrack", [1, 1, 1, 0.08]], (_theme getOrDefault ["radius", 0]) min (_buttonH / 2)] call EFUNC(gui,uiPanel);

        private _fill = [_display, "EINV_PanelRect", _parent, _unloadRect] call EFUNC(gui,uiCreate);
        _fill ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]);
        _fill ctrlSetPosition [_unloadX, _buttonTop, (_unloadW * _fraction) max pixelW, _buttonH];
        _fill ctrlCommit 0;

        private _label = [
            _display, _parent, _unloadRect, format [LLSTRING(Unloading), ceil (_duration - (CBA_missionTime - _start))],
            _lineSize, _theme getOrDefault ["buttonText", _colorText], _font, 2, "never"
        ] call EFUNC(gui,uiLabel);

        private _stop = [_display, "EINV_Hitbox", _parent, _unloadRect] call EFUNC(gui,uiCreate);
        [_stop, LLSTRING(Tip_Stop)] call EFUNC(gui,setTooltip);
        _stop ctrlAddEventHandler ["ButtonClick", {
            [{["", true] call FUNC(stopUnload)}, []] call EFUNC(gui,later);
        }];

        uiNamespace setVariable [QGVAR(bar), [_fill, _label, _unloadRect]];
    } else {
        [
            "unload", _at, _unloadRect, localize "STR_ACE_Cargo_unloadObject", GUI_TEX(icon_unload_ca),
            _state get "canUnload", _state get "unloadTip"
        ] call _fnc_button;
    };
} forEach _items;

(_lineH + UNIT * 0.25 + (count _items) * _cardH + (((count _items) - 1) max 0) * _cardGap)
