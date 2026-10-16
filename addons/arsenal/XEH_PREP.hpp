// ACE Arsenal's grid panel: ACE's display opened and closed, the open container and the panel's place
PREP(onOpened);
PREP(onClosed);
PREP(selected);
PREP(panelRect);
PREP(isOver);

// The hook table the inventory's engine is attached with, and the hooks themselves
PREP(hooks);
PREP(layout);
PREP(footer);
PREP(onFrame);
PREP(onMouse);
PREP(onClick);
PREP(onWheel);
PREP(onKey);
PREP(dragCheck);
PREP(onDrop);
PREP(menu);

// The staging space under the container's grid
PREP(staging);
PREP(growStaging);

// Dragging an item out of ACE's list, and putting new things in - into a kit too
PREP(onListPress);
PREP(listDrag);
PREP(addTo);
PREP(listToKit);

// Taking things out of the open container or the staging space
PREP(remove);
PREP(removeKind);

// Following ACE's adds and removals: what the container held, what had no room, ACE's list kept right
PREP(countAll);
PREP(snapshot);
PREP(onCargoChanged);
PREP(onItemsChanged);
PREP(reconcile);
PREP(sayNoRoom);
PREP(tellAce);
PREP(settle);
PREP(syncAce);
PREP(ungrey);

// Opening an arsenal: from the inventory's menu, and ACE's with a vanilla box's items
PREP(canOpen);
PREP(open);
PREP(openBI);

// Arsenal boxes
PREP(isArsenalBox);
PREP(isBIBox);
PREP(canOpenBI);

// What does not fit the grid, said once
PREP(checkOverflow);
PREP(reportOverflow);

// The vanilla Virtual Arsenal: the wrapper's question, the items of a vanilla box, the safety net, the red
// screen, and what is left alone
PREP(compatCheck);
PREP(handleBIOpen);
PREP(biItems);
PREP(biInit);
PREP(biSafetyNet);
PREP(biCountHandlers);
PREP(biMissionHooks);
PREP(biLeaveAlone);
PREP(checkBIOverride);
PREP(showBlocked);
PREP(onBlockedLoad);
PREP(onBlockedKey);
