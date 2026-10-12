// The bar on the screen, in the look of Arma's own HUD elements. The seven boxes are not here: the
// titles display holds one empty group, and fnc_hudCreate makes a box, a picture, a key, a count and
// a bar per slot in it - their colours are the player's interface colours (Options > Game > Colors),
// read when the bar is made.

class RscText;
class RscPictureKeepAspect;
class RscProgress;
class RscStructuredText;
class RscControlsGroupNoScrollbars;

class EINV_HotbarBox: RscText {
    idc = -1;
    text = "";
    colorBackground[] = {0, 0, 0, 0.5};
};

class EINV_HotbarPicture: RscPictureKeepAspect {
    idc = -1;
};

class EINV_HotbarKey: RscText {
    idc = -1;
    font = "PuristaSemibold";
    sizeEx = QUOTE(0.7 * GUI_GRID_H);
    shadow = 1;
};

// The number of items, bottom right.
class EINV_HotbarCount: EINV_HotbarKey {
    font = "PuristaMedium";
    style = 1;
};

// A thin bar along the bottom of a box: the progress of a treatment, a throwable's cooldown. Its
// colour is set when it is made (ctrlSetTextColor).
class EINV_HotbarBar: RscProgress {
    idc = -1;
    colorFrame[] = {0, 0, 0, 0};
    texture = "#(argb,8,8,3)color(1,1,1,1)";
};

// A line over the boxes: what was done, or why not.
class EINV_HotbarMessage: RscStructuredText {
    idc = -1;
    size = QUOTE(0.8 * GUI_GRID_H);
    shadow = 1;

    class Attributes {
        font = "PuristaMedium";
        align = "center";
    };
};

class RscTitles {
    class GVAR(RscHud) {
        idd = -1;
        duration = 1e+011;
        fadeIn = 0;
        fadeOut = 0;
        movingEnable = 0;
        onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(hud),_this select 0)]);
        onUnload = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(hud),displayNull)]);

        class controls {
            class Bar: RscControlsGroupNoScrollbars {
                idc = HUD_GROUP_IDC;
                x = QUOTE(HUD_X);
                y = QUOTE(HUD_Y);
                w = QUOTE(HUD_W);
                h = QUOTE(HUD_H);

                class controls {};
            };
        };
    };
};
