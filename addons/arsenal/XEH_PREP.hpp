// ACE Arsenal's grid panel: ACE's display opened and closed, the open container and the panel's place
PREP(onOpened);
PREP(initState);
PREP(center);
PREP(onClosed);
PREP(selected);
PREP(panelRect);
PREP(isOver);

// The hook table the inventory's engine is attached with, and the hooks themselves
PREP(hooks);
PREP(layout);
PREP(footer);
PREP(toggleCollapse);
PREP(onFrame);
PREP(hoverConfirm);
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

// Enhanced First Aid Kits' kits tab: whether it is open and the kit picked, its list in ACE's right column, the
// note where the kit has no grid, and that list's rows greyed by the kit's cells
PREP(focusedKit);
PREP(rightList);
PREP(drawNote);
PREP(ungreyKit);

// Taking things out of the open container or the staging space
PREP(remove);
PREP(removeKind);

// Following ACE's adds and removals: what the container held, what had no room, ACE's list kept right
PREP(countAll);
PREP(keepPlaces);
PREP(stageOverflow);
PREP(snapshot);
PREP(onCargoChanged);
PREP(onItemsChanged);
PREP(reconcile);
PREP(sayNoRoom);
PREP(tellAce);
PREP(settle);
PREP(syncAce);
PREP(noteOpen);
PREP(ungrey);
PREP(pictures);

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

// What does not fit when ACE's window closes: asked first (ACE's Close button and Escape are taken over), then taken out
PREP(findOverflow);
PREP(dropOverflow);
PREP(interceptClose);
PREP(onCloseButton);
PREP(onAceKey);
PREP(confirmClose);
PREP(answerConfirm);
PREP(closeConfirm);
PREP(onConfirmMouse);

// The vanilla Virtual Arsenal: the wrapper's question, the items of a vanilla box, the safety net, the red
// screen, and what is left alone
PREP(compatCheck);
PREP(handleBIOpen);
PREP(biItems);
PREP(biInit);
PREP(biOpened);
PREP(biWatch);
PREP(biSafetyNet);
PREP(biCountHandlers);
PREP(biMissionHooks);
PREP(biLeaveAlone);
PREP(checkBIOverride);
PREP(showBlocked);
PREP(onBlockedLoad);
PREP(onBlockedKey);
