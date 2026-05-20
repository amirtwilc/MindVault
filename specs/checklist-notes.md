# Feature Spec: Checklist notes

## Indrotuction

The default behavior of a note is plain text, where user can freely write text. A checklist note is a specific type of note, in which every row (divided by \n) has an empty sqaure that can be "checked". 

## Goal

Define the full behavior of how checklist work and displayed

---

## Requirements

### Transition from default "text" note type

Every note is by default a "text" note, but can be changed to be a "checklist" note. 
The ability to transition between note type is by a drop down selection, allowing to select the required note type (currently will show "text" or "checklist", but could have more options in the future).
In the app, the selection will sit next to the Category selection button, and will resemble this button. It will be available in both read mode and edit mode.
In the widget, the selection will sit below the Category selection, and will only be dispalyed in edit mode.

### Behavior when checklist note type is selected

If note already contains text, then each row (divided by \n) will automatically gain an empty square. Empty rows would be removed.
The direction in which the square will sit in each row will be according to the first strong character of that text (RTL=all squares are on the right, LTR=all squares are on the left)

If note does not contain any text, then the first row will be added an empty square in the side of the current app's language direction (RTL = right, LTR = left), and the cursor will sit right after the square, allowing user to type. This behavior will also happen when in edit mode, whenever user starts a new line (\n).
If user started writing the first task, and the first strong character is different then the current app's language, then one these two possibilities should occurr (preferably the first):
1. Square automatically moves to the other side, and each row after that adheres to the new side
2. Squares stay in the current position for all rows until edit mode is exited, but when re-entering the note, either in read mode or edit mode, the squares should be aligned to the correct side (RTL=all squares on the right, LTR=all squares on the left).

If user did not write anything on a line, pressing Enter (\n) should not do anything, hence not allowing to keep an empty task.

A checklist note should not be saved with empty tasks (same as empty text note)

### Ability to order tasks

Tasks are ordered according to the order they were added (If there are 3 tasks, and user clicked Enter after 2nd task and started writing, then the new task will now be the 3rd task and the previously 3rd task will now be 4th), but are able to be reordred by holding and dragging


### Marking and de-marking tasks

If a line is with an empty square, then user may click the square to mark it completed.
A marked line would show with a V inside the square and the line would visually imply the task was completed.
Clicking a marked square would remove the V and visualization, restoring it to it's former state.

Unmarked tasks and marked tasks should be divided (unmarked on top, marked on bottom), where unmarked tasks are displayed by their natural ordering. If a task is marked as completed - it will move from the top section to the bottom section, positioning itself on top of the completed tasks. Unmarking a marked task would place it at the bottom of the unmarked tasks

If at least one line is marked completed, a button would appear suggesting to remove done tasks from the note. Clicking the button would prompt an "Are your sure?" windows, and clicking yes would completely remove the finished tasks. 

Marking and de-marking should be possible in read mode and edit mode, in app and in widget


### Database structure

A new table for checklist items should be created, and a reference should be added from the existing `notes` table to the new table.
Every note created, whether it's text, checklist, or otherwise should have a `notes` table record.
If a note is deleted, it must be ensured that the referenced records are also removed from DB if exists.

---

## Done When

- Notes may be transitioned easily from text to checklist
- Tasks are correctly aligned to left or right based on first strong chracter of the note
- Marking and de-marking works a planned and conveniently
- Ability to hold and drag tasks works seamlessly
- Sufficiently covered unit and integration tests are created and passed
- Manual verification and approval