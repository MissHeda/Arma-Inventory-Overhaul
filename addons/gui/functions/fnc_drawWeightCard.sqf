#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the weight card at the top of the equipment column (fnc_drawEquipmentCards): what the unit carries,
 * and how hard that is on it. Counted the way ACE counts it: what the engine weighs, plus ACE's virtual load
 * on the unit and its uniform, vest and backpack (einv_weight_fnc_getLoad). That holds the weight overrides
 * of the rules (weight=, handed to ACE by the weight addon), which the storage sections weigh by too, and
 * what Enhanced First Aid Kits' kits hold - so the total here is the one ACE shows and tires the unit by.
 *
 * The bar runs from nothing to the Critical limit and carries no marks: a tick or a strip in yellow and red
 * looked bad on a bar that is mostly empty. The tier shows in the fill's colour (fnc_weightColor, blending
 * into the next one just before a limit), in the word on the right with what the tier does to the soldier,
 * and in the kilograms on the left after the load: where the next tier starts. Where the limits are comes
 * from the weight addon (einv_weight_fnc_getLimits); this card only draws it. While something from outside
 * the soldier's own gear is dragged, a preview of its weight lies on the bar (fnc_previewWeight), found
 * through uiNamespace weightBar; the hint over the card is registered in uiNamespace infoAreas.
 *
 * A function of its own so the card can be drawn again alone, in its own group, when only what the unit
 * carries changed (fnc_drawPart, fnc_redrawPart, fnc_refresh): a move into or out of the backpack no longer
 * builds the whole window (a tester, 0.4.7: a small stutter on every move).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to draw in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] in it - the card fills it <ARRAY>
 * 3: Unit <OBJECT>
 * 4: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, [0, 0, 0.3, 0.06], player, _theme] call einv_gui_fnc_drawWeightCard;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_unit", "_theme"];
_rect params ["_left", "_top", "_width", "_statH"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];
private _colorMuted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _colorStrip = _theme getOrDefault ["slotCaptionBg", [1, 1, 1, 0.1]];
private _colorCard = _theme getOrDefault ["card", [1, 1, 1, 0.035]];
private _barTrack = _theme getOrDefault ["barTrack", [1, 1, 1, 0.06]];
private _border = _theme getOrDefault ["slotBorder", []];
private _radius = _theme getOrDefault ["radius", 0];
private _flat = _radius <= 0;

private _limits = [_unit] call EFUNC(weight,getLimits);
private _mass = [_unit] call EFUNC(weight,getLoad);
private _tier = [_unit, _mass] call EFUNC(weight,getTier);
private _end = (_limits get "critical") max 1;

([_tier, _limits] call EFUNC(weight,tierText)) params ["_word", "_effect"];

// The fill and the words take the tier's colour.
private _fill = [_unit, _mass, _theme] call FUNC(weightColor);

// The tier that starts next and where, for the text beside the load. Heavy only counts as a tier of its own
// where it starts before Overloaded; Critical has nothing above it.
private _nextTier = -1;

for "_i" from _tier + 1 to TIER_CRITICAL do {
    if (_i != TIER_HEAVY || {(_limits get "heavyKg") < (_limits get "overloadedKg")}) exitWith {
        _nextTier = _i;
    };
};

// Its words and the rows that hold them grow with the tiles (TEXT_UNIT, fnc_textScale).
private _textUnit = TEXT_UNIT;
private _cursor = _top;
private _statPadY = _textUnit * 0.22;
private _statPadX = SQUARE(_textUnit * 0.3);
private _stripH = _textUnit * 0.68;
private _statBarH = (2 max round (_textUnit * 0.2 / pixelH)) * pixelH;
private _statBarY = _cursor + _statH - _statPadY - _statBarH;
private _statBarW = _width - _statPadX * 2;

if (_flat) then {
    // The caption on a strip of its own across the top.
    [_display, _parent, [_left, _cursor, _width, _statH], _colorCard] call FUNC(uiPanel);
    [_display, _parent, [_left, _cursor, _width, _stripH], _colorStrip] call FUNC(uiPanel);
} else {
    [_display, _parent, [_left, _cursor, _width, _statH], _colorCard, _radius min (_statH / 4)] call FUNC(uiPanel);
};

[
    _display, _parent, [_left + _statPadX, _cursor, _statBarW, _stripH], [LLSTRING(Stat_Weight), _theme] call FUNC(caption),
    _textUnit * 0.42, _colorText2, _font, 0, true
] call FUNC(uiLabel);

private _valueY = _cursor + _stripH;
private _valueH = _statBarY - _valueY;
private _wordSize = _textUnit * 0.46;

// The load, and after it where the next tier starts, in kilograms.
private _valueText = format ["%1 kg", (_mass * MASS_TO_KG) toFixed 1];
private _valueSize = _textUnit * 0.66;
private _valueW = (_valueText getTextWidth [_fontBold, _valueSize]) * TEXT_SLACK;
private _nextText = "";

if (_nextTier >= 0 && {_limits getOrDefault ["enabled", true]}) then {
    _nextText = format [
        LLSTRING(Load_Next), ([_nextTier, _limits] call EFUNC(weight,tierText)) select 0,
        (_limits get (["", "heavyKg", "overloadedKg", "criticalKg"] select _nextTier)) toFixed 1
    ];
};

// The word with its effect on the right, the next limit beside the load. On a narrow column they would run
// into each other, so the next limit goes first, then the effect: the tier itself always stays.
private _fnc_width = {
    params ["_text", "_textFont", "_textSize"];

    (_text getTextWidth [_textFont, _textSize]) * TEXT_SLACK
};

private _nextGap = SQUARE(_textUnit * 0.2);
private _nextW = 0;

if (_nextText isNotEqualTo "") then {
    _nextW = ([_nextText, _font, _textUnit * 0.46] call _fnc_width) + _nextGap;
};

private _wordFull = [_word, format [LLSTRING(Tier_Effect), _word, _effect]] select (_effect isNotEqualTo "");
private _room = _statBarW - _valueW - SQUARE(_textUnit * 0.4);
private _fullW = [[_wordFull, _theme] call FUNC(caption), _fontBold, _wordSize] call _fnc_width;

if (_nextText isNotEqualTo "" && {_nextW + _fullW > _room}) then {
    _nextText = "";
    _nextW = 0;
};

if (_fullW > _room - _nextW) then {
    _wordFull = _word;
};

private _wordText = [_wordFull, _theme] call FUNC(caption);
private _wordW = [_wordText, _fontBold, _wordSize] call _fnc_width;

[_display, _parent, [_left + _statPadX + _statBarW - _wordW, _valueY, _wordW, _valueH], _wordText, _wordSize, _fill, _fontBold, 1, "value"] call FUNC(uiLabel);
[_display, _parent, [_left + _statPadX, _valueY, _statBarW - _wordW, _valueH], _valueText, _valueSize, _colorText, _fontBold, 0, "value"] call FUNC(uiLabel);

if (_nextText isNotEqualTo "") then {
    [
        _display, _parent, [_left + _statPadX + _valueW + _nextGap, _valueY, _nextW, _valueH],
        _nextText, _textUnit * 0.46, _colorMuted, _font, 0, "hint"
    ] call FUNC(uiLabel);
};

private _barRect = [_left + _statPadX, _statBarY, _statBarW, _statBarH];

if (_flat) then {
    // In a square look the bar is cut into segments with a small gap between them, each filling in turn.
    private _segments = 10;
    private _segmentGap = pixelW * 2;
    private _segmentW = (_statBarW - _segmentGap * (_segments - 1)) / _segments;
    private _share = (_mass / _end) min 1;

    for "_i" from 0 to (_segments - 1) do {
        [
            _display, _parent, [_left + _statPadX + _i * (_segmentW + _segmentGap), _statBarY, _segmentW, _statBarH],
            ((_share * _segments - _i) max 0) min 1, _barTrack, _fill, 0
        ] call FUNC(uiBar);
    };
} else {
    [_display, _parent, _barRect, (_mass / _end) min 1, _barTrack, _fill, _statBarH / 2] call FUNC(uiBar);
};

if (_flat) then {
    // Last, so nothing covers it.
    if (_border isNotEqualTo []) then {
        [_display, _parent, [_left, _cursor, _width, _statH], _border] call FUNC(uiFrame);
    };
};

// What a drag previews on the bar and where (fnc_previewWeight), and the hint over the whole card (fnc_infoHint).
uiNamespace setVariable [QGVAR(weightBar), createHashMapFromArray [
    ["parent", _parent], ["rect", _barRect], ["load", _mass], ["limits", _limits], ["unit", _unit]
]];

private _cardRect = [_left, _cursor, _width, _statH];
private _cardAnchor = createHashMap;

if (!isNull _parent) then {
    _cardAnchor = createHashMapFromArray [["rel", [_left, _cursor]], ["parent", _parent]];

    ([_cardAnchor] call FUNC(gridOrigin)) params ["_screenX", "_screenY"];

    _cardRect = [_screenX, _screenY, _width, _statH];
};

(uiNamespace getVariable [QGVAR(infoAreas), []]) pushBack [_cardRect, "", "", _cardAnchor, "weight", [_unit]];
