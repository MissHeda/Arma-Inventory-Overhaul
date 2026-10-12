// Eden's Tools menu: the setup wizard, for mission makers. What they save there goes into the scenario
// (CBA's mission source), so it ships with the mission once the scenario is saved.
//
// The wizard opens over the editor in direct mode at its first step. Nothing here waits for a frame:
// CBA's frame handlers do not run in Eden (the wizard defers with its own means where it has to).

class ctrlMenuStrip;

class Display3DEN {
    class Controls {
        class MenuStrip: ctrlMenuStrip {
            class Items {
                class Tools {
                    items[] += {QGVAR(openWizard)};
                };
                class GVAR(openWizard) {
                    text = CSTRING(OpenWizard);
                    data = QGVAR(openWizard);
                    picture = QPATHTOEF(gui,ui\icon_setup_ca.paa);
                    action = QUOTE([ARR_4(findDisplay 313,'direct',0,'')] call (uiNamespace getVariable [ARR_2(QQFUNC(open),{})]));
                    enable = 1;
                    opensNewWindow = 1;
                };
            };
        };
    };
};
