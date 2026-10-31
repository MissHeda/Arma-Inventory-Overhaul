// Eden: lock a crate or a vehicle to a side, a group or the admins. The expressions only keep the values
// on the object and queue it - fnc_applyEden makes the lock on the server once every object has its own
// values. They run in the running mission, not in the editor itself (!is3DEN).
class Cfg3DEN {
    class Object {
        class AttributeCategories {
            class AIO_Attributes {
                displayName = CSTRING(Eden_Category);
                collapsed = 1;

                class Attributes {
                    class GVAR(edenMode) {
                        displayName = CSTRING(Eden_Mode);
                        tooltip = CSTRING(Eden_Mode_Tooltip);
                        property = QGVAR(edenMode);
                        control = "Combo";
                        expression = QUOTE(if (!is3DEN && {_value isNotEqualTo ''}) then {_this setVariable [ARR_2(QQGVAR(edenMode),_value)]; if (isNil QQGVAR(edenQueue)) then {GVAR(edenQueue) = []}; GVAR(edenQueue) pushBackUnique _this});
                        defaultValue = "''";
                        typeName = "STRING";
                        condition = "objectHasInventoryCargo * (1 - objectBrain)";

                        class Values {
                            class Everyone {name = CSTRING(Eden_Everyone); value = ""; default = 1;};
                            class West {name = CSTRING(Side_West); value = "west";};
                            class East {name = CSTRING(Side_East); value = "east";};
                            class Independent {name = CSTRING(Side_Independent); value = "independent";};
                            class Civilian {name = CSTRING(Side_Civilian); value = "civilian";};
                            class Group {name = CSTRING(Eden_Group); value = "group";};
                            class Admins {name = CSTRING(Eden_Admins); value = "admins";};
                        };
                    };

                    class GVAR(edenGroup) {
                        displayName = CSTRING(Eden_Callsign);
                        tooltip = CSTRING(Eden_Callsign_Tooltip);
                        property = QGVAR(edenGroup);
                        control = "Edit";
                        expression = QUOTE(if (!is3DEN && {_value isNotEqualTo ''}) then {_this setVariable [ARR_2(QQGVAR(edenGroup),_value)]});
                        defaultValue = "''";
                        typeName = "STRING";
                        condition = "objectHasInventoryCargo * (1 - objectBrain)";
                    };
                };
            };
        };
    };
};
