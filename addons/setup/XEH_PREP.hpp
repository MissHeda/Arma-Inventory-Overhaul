// Opening and closing the wizard, and its keys
PREP(open);
PREP(onLoad);
PREP(onUnload);
PREP(onKeyDown);
PREP(onKeyUp);
PREP(onMouse);
PREP(close);

// Code a moment later - also in Eden and over the menus, where CBA's frame handlers do not run
PREP(defer);
PREP(runDeferred);

// Who may save where, what is in use, and the draft being edited
PREP(canEdit);
PREP(getActive);
PREP(targetValue);
PREP(setDraft);
PREP(commit);
PREP(undo);
PREP(reload);
PREP(onRulesChanged);
PREP(isDirty);
PREP(sourceEmpty);
PREP(countChanges);
PREP(changeRows);
PREP(statements);
PREP(sanitize);

// Saving, sharing and keeping
PREP(save);
PREP(replay);
PREP(importText);
PREP(openImport);
PREP(exportText);
PREP(personalPresets);
PREP(shippedPresets);
PREP(presetName);
PREP(describeRule);

// The window and its steps
PREP(drawFrame);
PREP(showStep);
PREP(drawStart);
PREP(drawChanges);
PREP(drawItems);
PREP(drawContainers);
PREP(drawReview);
PREP(setHint);
PREP(popover);
PREP(closePopover);
PREP(topLayer);
PREP(confirm);

// The Items and Containers steps: the class index, its lists, the editors, and the one rule per class
// they write
PREP(buildIndex);
PREP(indexChunk);
PREP(drawClassList);
PREP(drawResults);
PREP(drawItemEditor);
PREP(drawCellEditor);
PREP(drawCellBlocks);
PREP(drawSameAs);
PREP(cellChanged);
PREP(classBlocks);
PREP(drawPreview);
PREP(canvasFromBlocks);
PREP(canvasBlocks);
PREP(canvasBox);
PREP(answerText);
PREP(ownClassRules);
PREP(upsertRule);

// Widgets, on the inventory's UI kit
PREP(uiHit);
PREP(uiAction);
PREP(uiCard);
PREP(uiText);
PREP(uiToggle);
PREP(uiStepper);
PREP(uiEdit);
PREP(fitEditArea);
PREP(uiChip);
PREP(uiCanvas);
PREP(uiSegmented);
PREP(uiDropdown);
PREP(screenRect);
PREP(hex);
PREP(escape);

#include "XEH_PREP_entry.hpp"
