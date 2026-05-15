# Feature Spec: Checklist notes

## Indrotuction

The default behavior of a note is plain text, where user can freely write text. A checklist note is a specific type of note, in which every row (divided by \n) has an empty sqaure that can be "checked". 

## Goal

Define the full behavior of how checklist work and displayed

---

## Requirements

### Transition from default "text" note type

Every note is by default a "text" note, but can be changed to be a "checklist" note. 
The ability to transition between note type is by a drop down selection, allowing to select the required note type (currently will show "text" or "checklist", but could have more int the future).
In the app, the selection will sit next to the Category selection button, and will resemble this button. It will be available in both read mode and edit mode.
In the widget, the selection will sit below the Category selection, and will only be dispalyed in edit mode.

### Behavior when checklist note type is selected

If note already contains text, then each row (divided by \n) will automatically gain an empty square.
The direction in which the square will sit will follow the same rules regarding direction in "text" note types, meaning that:
- In read mode the square will sit in the side of the first strong character of that line (RTL = right, LTR = left), so each line might have a different side depending on the language, exactly like each line might adhere to another direction in "text" type.
- In edit mode the sqaure will always sit in one side for each line, dependent on the first strong character of the entire note, exactly like each note adheres to only one side.
The ability to highlight multiple rows (for example to copy), as well as using the Copy button, should work fine as in "text" type note. The square (whether checked or not) should not be copied to keyboard

If note does not contain any text, then the first row will be added an empty square in the side on the current app's language direction (RTL = right, LTR = left), and the cursor will sit right after the square, allowing user to type. This behavior will also happen when in edit mode, whenever user starts a new line (\n).
If user did not write anything on a line, and then pressend Enter (\n), the previous line would lost the square (since there is no task to perform) and the current row will now have a square, followed by the cursor.

### marking and de-marking tasks

If a line is with an empty square, then user may click the square to mark it completed.
A marked line would show with a V inside the square and the line would visually imply the task was completed.
Clicking a marked square would remove the V and visualization, restoring it to it's former state.

If at least one line is marked completed, a button would appear suggesting to remove done tasks from the note

### ability to order tasks


---

## Done When

- Pin and unpin buttons are positioned in All Notes section
- Pinned notes correctly positioned on top of unpinned notes
- Unpinning notes returns them to their correct spot
- Ability to reorder pinned notes works seamlessly and with not problems
- Order is correctly displayed across sections and widget
- Sufficiently covered unit and integration tests are created and passed
- Manual verification and approval

## Perform after completion

Once feature is finished and I approve it, update README.md with information about:
- What the requirement was, in short
- What challenges were met (if were any)
- What design choice was chosen and why
- What design alternatives were strongly considered (if were any) 