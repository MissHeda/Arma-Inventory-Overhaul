// Taking over from the vanilla inventory
PREP(initUnit);
PREP(guardVanilla);
PREP(closeDisplay);
PREP(onInventoryOpened);
PREP(canOpenVehicle);

// Living persons: the scroll action, who may do what, and their gear changed where they are local
PREP(addPersonAction);
PREP(personActionCondition);
PREP(addAgentAction);
PREP(agentActionCondition);
PREP(openPerson);
PREP(canOpenPerson);
PREP(isHelpless);
PREP(canTouchPerson);
PREP(checkTouch);
PREP(personOf);
PREP(personInReach);
PREP(notifyPerson);
PREP(personGuard);

// The window: opening, building, closing, following the mouse
PREP(open);
PREP(attach);
PREP(startFrame);
PREP(stopFrame);
PREP(build);
PREP(onUnload);
PREP(onKeyDown);
PREP(onFrame);
PREP(updateHover);
PREP(getSignature);
PREP(requestRebuild);
PREP(isCovered);
PREP(isInventoryMode);
PREP(later);
PREP(coalesce);
PREP(coalesceRun);
PREP(coalesceTick);
PREP(coalesceDrop);
PREP(buildSoon);
PREP(filterSoon);
PREP(windowsSoon);
PREP(hook);
PREP(showHint);
PREP(readNearby);
PREP(redrawTiles);
PREP(refresh);
PREP(drawPart);
PREP(redrawPart);
PREP(drawWeightCard);

// Moving items with the mouse and keys
PREP(onMouseButton);
PREP(startDrag);
PREP(updateDrag);
PREP(endDrag);
PREP(logDrag);
PREP(makeGhost);
PREP(rotateDrag);
PREP(onMouseZ);
PREP(passWheel);
PREP(unscroll);
PREP(quickMove);
PREP(dropToGround);
PREP(applyMove);
PREP(afterAction);
PREP(quickEquip);
PREP(quickUnequip);
PREP(splitStack);

// Moves as transactions: sent, shown under way, answered, and drift reported to the authorities
PREP(sendMoves);
PREP(sendPlan);
PREP(applySwap);
PREP(swapPlan);
PREP(onAnswer);
PREP(drawPending);
PREP(requestNormalize);

// Selecting several: click, Ctrl, Shift and a frame, moved together and Sort
PREP(select);
PREP(selectSection);
PREP(clearSelection);
PREP(selectionTiles);
PREP(drawSelection);
PREP(groupMode);
PREP(quickMoveGroup);
PREP(sortHolder);
PREP(sortText);
PREP(sortChip);
PREP(sortButtons);

// The context menu
PREP(openMenu);
PREP(closeMenu);
PREP(raiseMenu);
PREP(contextMenu);
PREP(containerName);
PREP(flashHint);
PREP(doEquip);
PREP(doUnequip);
PREP(canSwap);
PREP(canPutOn);
PREP(doSwap);
PREP(itemName);

// The CBA item context menu: other mods' choices for an item, in this window's menu
PREP(cbaTileTarget);
PREP(cbaSlotTarget);
PREP(cbaOptions);
PREP(cbaRun);

// Searching loot
PREP(isSearched);
PREP(isSealed);
PREP(searchKind);
PREP(searchTime);
PREP(sortSearch);
PREP(searchFirst);
PREP(searchMarks);
PREP(searchRecord);
PREP(statusWords);
PREP(setSearchable);
PREP(onZeusPlaced);
PREP(hookCurators);
PREP(markHidden);
PREP(learn);
PREP(findTile);
PREP(boxTile);
PREP(updateStatus);
PREP(animateStatus);
PREP(stopStatus);
PREP(revealTile);
PREP(animateSearch);
PREP(revealFx);

// The categories at the side of a loot box
PREP(itemGroup);
PREP(groupTexture);
PREP(boxGroup);
PREP(setGroup);
PREP(matchesGroup);
PREP(drawGroupStrip);
PREP(paintGroupStrip);
PREP(stripEntries);
PREP(stripMore);
PREP(drawBadge);

// The hands' queue: what is not dragged waits its turn - quick moves, group moves, drops, as far as the settings say; its tiles are tinted and the box's caption line counts
PREP(queueColor);
PREP(boxStep);
PREP(unmarkQueued);
PREP(queueTime);
PREP(queueMoves);
PREP(queueTiles);
PREP(queuedSlot);
PREP(queueIndex);
PREP(queueWaits);
PREP(roomFor);
PREP(drawQueue);
PREP(animateQueue);
PREP(runQueue);
PREP(cancelQueued);
PREP(flashTile);
PREP(openNested);
PREP(playSound);
PREP(drawFilter);
PREP(applyFilter);
PREP(matchesFilter);
PREP(showTargets);
PREP(glowSlot);
PREP(warmTargets);
PREP(inspect);
PREP(drawInspect);
PREP(closeInspect);
PREP(toggleSection);
PREP(toggleRows);
PREP(closeNested);

// The sound dropdown under the speaker in the header: volumes per kind of sound and a master volume
PREP(soundMuted);
PREP(soundGroup);
PREP(soundGain);
PREP(soundSet);
PREP(soundSettle);
PREP(soundSlide);
PREP(playClass);
PREP(openSoundMenu);
PREP(updateSoundMenu);
PREP(updateSoundButton);
PREP(headerStyle);

// The feel: every kind of gear sounds like itself, others hear the looting, and the soldier looks into his gear
PREP(soundFamily);
PREP(containerFamily);
PREP(soundDef);
PREP(resolveLayers);
PREP(playLayer);
PREP(delay);
PREP(groundSurface);
PREP(soundFile);
PREP(reloadSound);
PREP(playReload);
PREP(sendNoise);
PREP(onNoise);
PREP(feelFor);
PREP(feelAnswer);
PREP(checkTaken);
PREP(reloadGesture);

// Styles
PREP(themeBase);
PREP(accentColour);

// The palette behind the header's palette button: the player's accent, secondary colour, panels and their transparency, cells,
// tiles, text and lines
PREP(palette);
PREP(paletteAllowed);
PREP(panelColour);
PREP(paletteInfo);
PREP(paletteSet);
PREP(paletteSettle);
PREP(paletteSlide);
PREP(hsv);
PREP(openPaletteMenu);
PREP(updatePaletteMenu);
PREP(updatePaletteButton);

// Weight: what lifting something previews on the weight card, the words for what a pick-up makes of the
// soldier, and the comparison of a vest, uniform, helmet or backpack with the one worn
PREP(previewWeight);
PREP(clearWeightPreview);
PREP(weightText);
PREP(weightColor);
PREP(dragHint);
PREP(infoHint);
PREP(isOwnStorage);
PREP(compareRows);
PREP(drawCompare);

// UI kit
PREP(uiCreate);
PREP(uiPanel);
PREP(uiLabel);
PREP(uiIcon);
PREP(uiPicture);
PREP(safePicture);
PREP(uiFrame);
PREP(uiShape);
PREP(shapeRects);
PREP(uiRing);
PREP(uiSurface);
PREP(uiOutline);
PREP(paintSurface);
PREP(gridCorner);
PREP(cornerRadii);
PREP(clearCells);
PREP(uiItemPicture);
PREP(uiPictureTurned);
PREP(turnPicture);
PREP(syncTurned);
PREP(uiPictureCut);
PREP(uiPictureRounded);
PREP(uiBoxPicture);
PREP(uiBar);
PREP(uiButton);
PREP(buttonWidth);
PREP(uiKeyHint);
PREP(uiHatch);
PREP(caption);
PREP(fitText);
PREP(textScale);
PREP(ownerName);

// Grids and tiles
PREP(getCell);
PREP(capCell);
PREP(createGrid);
PREP(createTile);
PREP(drawTiles);
PREP(drawCells);
PREP(loadText);
PREP(drawAttachments);
PREP(gridOrigin);
PREP(slotRect);
PREP(screenToCell);
PREP(spanRect);
PREP(hitsHole);
PREP(tileAt);

// Building blocks the layouts share
PREP(drawSlot);
PREP(drawCountBackdrop);
PREP(drawColumn);
PREP(drawHeader);
PREP(drawFooter);

// Floating windows: open kits and pouches
PREP(flowCompartments);
PREP(viewBlocks);
PREP(pageRows);
PREP(pageRanges);
PREP(pageOf);
PREP(pageCounts);
PREP(setWindow);
PREP(drawPagePanel);
PREP(drawPageBar);
PREP(updatePageBars);
PREP(showPage);
PREP(setPage);
PREP(turnPage);
PREP(pageSoon);
PREP(pageStep);
PREP(drawCompartments);
PREP(scrollPixels);
PREP(drawWindows);
PREP(drawWindow);
PREP(clearWindows);
PREP(drawTopLayer);
PREP(makeTooltip);
PREP(setTooltip);
PREP(fitHint);
PREP(raiseTooltip);
PREP(startStripDrag);
PREP(updateStripDrag);
PREP(endStripDrag);
PREP(stripTarget);
PREP(openWindow);
PREP(closeWindow);
PREP(raiseWindow);
PREP(placeWindow);
PREP(dragHandle);
PREP(topAt);
PREP(hoverGeometry);
PREP(hoverOutline);
PREP(frame);
PREP(logFrame);
PREP(notePhase);
PREP(tileRect);


// The look: Enhanced First Aid Kits' glass, the equipment as cards with every attachment slot
PREP(theme);
PREP(layoutGlass);
PREP(drawEquipmentCards);
PREP(drawEquipmentDoll);
PREP(drawSection);

// Other mods' answers and dialogs: the radios of TFAR and ACRE2 ask the same questions, and open dialogs the window
// cannot stay open over
PREP(compatCollect);
PREP(stepAside);
PREP(isQuickKey);
PREP(quickKeyName);
PREP(isDropKey);
PREP(dropKeyName);
PREP(tileColour);
PREP(paletteStyles);
PREP(gradientText);
PREP(setTipText);
PREP(panelGradient);
PREP(isRotateKey);
PREP(rotateKeyName);
PREP(quickAction);
PREP(takeFocus);
PREP(isFinite);
