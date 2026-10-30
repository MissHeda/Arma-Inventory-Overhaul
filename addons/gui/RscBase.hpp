// The building blocks every look is made of, created at run time by the UI kit (fnc_ui*). They have no
// look of their own: colours, fonts and sizes come from the style's theme when a control is created,
// so one set of classes serves Tarkov and Glass alike.

class RscText;
class RscStructuredText;
class RscPicture;
class RscButton;
class RscEdit;
class RscControlsGroup {
    class VScrollbar;
    class HScrollbar;
};

// ---------------------------------------------------------------------------
// Surfaces. A panel with round corners is three rectangles and four quarter circles (fnc_uiPanel), so
// the corners stay round whatever the panel's size and the screen's shape.
// ---------------------------------------------------------------------------
class EINV_PanelRect: RscText {
    idc = -1;
    style = 0;
    text = "";
    shadow = 0;
    colorText[] = C_CLEAR;
    colorBackground[] = C_CLEAR;
};

// A corner texture stretched over its box (ST_PICTURE), tinted with the panel's colour.
class EINV_PanelCorner: RscPicture {
    idc = -1;
    style = 48;
    shadow = 0;
    colorBackground[] = C_CLEAR;
    colorText[] = C_CLEAR;
};

// A one pixel frame around a box (ST_FRAME), drawn in its text colour - a slot's or a tile's border.
class EINV_Frame: RscText {
    idc = -1;
    style = 64;
    text = "";
    shadow = 0;
    colorText[] = C_WHITE;
    colorBackground[] = C_CLEAR;
};

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------
class EINV_Label: RscText {
    idc = -1;
    style = 0;
    shadow = 0;
    font = "PuristaMedium";
    sizeEx = QUOTE(UNIT * 0.8);
    colorText[] = C_WHITE;
    colorBackground[] = C_CLEAR;
    tooltipColorText[] = C_TOOLTIP_TEXT;
    tooltipColorBox[] = C_TOOLTIP_BOX;
    tooltipColorShade[] = C_TOOLTIP_SHADE;
};

class EINV_LabelRight: EINV_Label {
    style = 1;
};

class EINV_LabelCenter: EINV_Label {
    style = 2;
};

// Several colours in one line - the hint. Its parts bring their own colours and font (fnc_updateHover).
class EINV_StructuredText: RscStructuredText {
    idc = -1;
    shadow = 0;
    size = QUOTE(UNIT * 0.7);
    colorBackground[] = C_CLEAR;
    tooltipColorText[] = C_TOOLTIP_TEXT;
    tooltipColorBox[] = C_TOOLTIP_BOX;
    tooltipColorShade[] = C_TOOLTIP_SHADE;
    class Attributes {
        font = "PuristaMedium";
        color = "#FFFFFF";
        align = "left";
        valign = "middle";
        shadow = 0;
    };
};

// A text field without a frame of its own (ST_NO_RECT): the search field lies on a surface drawn under
// it (fnc_drawFilter).
class EINV_Edit: RscEdit {
    idc = -1;
    style = 512;
    shadow = 0;
    font = "PuristaMedium";
    sizeEx = QUOTE(UNIT * 0.7);
    colorText[] = C_TOOLTIP_TEXT;
    colorBackground[] = C_CLEAR;
    // The accent (issue 14): the engine evaluates strings in a colour as script when the control is made, so the
    // selection follows the profile's active element colour as ACE's does; orange without one.
    colorSelection[] = {"(profileNamespace getVariable ['GUI_BCG_RGB_R',0.84])", "(profileNamespace getVariable ['GUI_BCG_RGB_G',0.54])", "(profileNamespace getVariable ['GUI_BCG_RGB_B',0.1])", 0.35};
    colorDisabled[] = {1, 1, 1, 0.3};
    autocomplete = "";
    maxChars = 40;
    tooltipColorText[] = C_TOOLTIP_TEXT;
    tooltipColorBox[] = C_TOOLTIP_BOX;
    tooltipColorShade[] = C_TOOLTIP_SHADE;
};

// The hint in the footer: the size of the key hints' words beside it (fnc_uiKeyHint, a 0.9 UNIT key at
// 0.62 of its height), so the line reads as one.
// Left, right after the key hints and a thin line that parts it from them: an "align" set on composed text by script does
// not reach the line, the control's own attributes do - for every hint written into it.
class EINV_FooterHint: EINV_StructuredText {
    size = QUOTE(UNIT * 0.558);
    class Attributes: Attributes {
        align = "left";
    };
};

// ---------------------------------------------------------------------------
// Pictures
// ---------------------------------------------------------------------------

// A white icon, tinted at run time. It keeps its shape whatever box it is given (ST_PICTURE +
// ST_KEEP_ASPECT_RATIO).
class EINV_Icon: RscPicture {
    idc = -1;
    style = 2096;
    shadow = 0;
    colorBackground[] = C_CLEAR;
    colorText[] = C_WHITE;
};

// An item's own picture, in its own colours, fitted into its box without stretching. Never tinted.
class EINV_Picture: EINV_Icon {
    colorText[] = C_WHITE;
};

// An item's picture turned a quarter (issue #24, fnc_uiPictureTurned): a plain ST_PICTURE that stretches its texture
// over the control. Keeping the shape (ST_KEEP_ASPECT_RATIO) is worked out on the turned box and squashed the picture;
// the control is made in the texture's own shape instead, so the stretch changes nothing.
class EINV_PictureTurned: EINV_Icon {
    style = 48;
    colorText[] = C_WHITE;
};

// ---------------------------------------------------------------------------
// A button with no look of its own: it only catches the mouse, over a surface, icon and label drawn by
// the controls under it. Hover and clicks are added at run time (fnc_uiButton), so every look can
// light its buttons up in its own colours.
// ---------------------------------------------------------------------------
class EINV_Hitbox: RscButton {
    idc = -1;
    style = 2;
    text = "";
    shadow = 0;
    borderSize = 0;
    colorText[] = C_CLEAR;
    colorDisabled[] = C_CLEAR;
    colorBackground[] = C_CLEAR;
    colorBackgroundDisabled[] = C_CLEAR;
    colorBackgroundActive[] = C_CLEAR;
    colorFocused[] = C_CLEAR;
    colorShadow[] = C_CLEAR;
    colorBorder[] = C_CLEAR;
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0;
    offsetPressedY = 0;
    soundEnter[] = {"", 0, 1};
    tooltipColorText[] = C_TOOLTIP_TEXT;
    tooltipColorBox[] = C_TOOLTIP_BOX;
    tooltipColorShade[] = C_TOOLTIP_SHADE;
};

// ---------------------------------------------------------------------------
// Groups. Controls inside one count their position from its corner and are cut off at its edges.
// ---------------------------------------------------------------------------

// Holds pieces together, never scrolls.
class EINV_Group: RscControlsGroup {
    idc = -1;
    x = 0;
    y = 0;
    w = 0;
    h = 0;
    shadow = 0;
    class VScrollbar: VScrollbar {
        width = 0;
        autoScrollEnabled = 0;
    };
    class HScrollbar: HScrollbar {
        height = 0;
    };
    class Controls {};
};

// A column that scrolls up and down once its content is taller than it is: a thin, quiet bar without
// arrows, the thumb a slim bar with round ends - as in Enhanced First Aid Kits' menus. Never sideways.
class EINV_ScrollGroup: RscControlsGroup {
    idc = -1;
    x = 0;
    y = 0;
    w = 0;
    h = 0;
    shadow = 0;
    class VScrollbar: VScrollbar {
        width = SCROLL_W;
        autoScrollEnabled = 0;
        color[] = {1, 1, 1, 0.3};
        colorActive[] = {1, 1, 1, 0.5};
        colorDisabled[] = {1, 1, 1, 0.08};
        thumb = UI_TEX(scroll_thumb_ca);
        arrowEmpty = "#(argb,8,8,3)color(0,0,0,0)";
        arrowFull = "#(argb,8,8,3)color(0,0,0,0)";
        border = "#(argb,8,8,3)color(0,0,0,0)";
        shadow = 0;
    };
    class HScrollbar: HScrollbar {
        height = 0;
    };
    class Controls {};
};
