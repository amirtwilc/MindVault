# Feature Spec: Pinning notes

## Indrotuction

When notes are displayed in All Notes section, inside a category and in widget, they are ordered by their last created/seen time (lastest first).
User might want to pin notes so they are always on top.

## Goal

Allow pin/unpin notes. Pinned notes should be allowed to be reordered.

---

## Requirements

### Pin/unpin button location

The ability to pin/unpin a note would be available only outside of a note (preview), and only in All Notes section (not inside a category, not inside a note and not in the widget).
When pin is first created, it is unpinned by default.
Unpinned note would have a pin button, and when clicking it the button would change to an unpin button (same place).

### Behavior when note is pinned/unpinned

When a note is pinned, it will instantly move to the top of the list, ignoring the last created/seen time. If other notes are already pinned, this note will be placed at the bottom of all pinned notes.

Unpinning a note will return to be ordered according to it's last created/seen time, thus instantly returning it to it's appropriate spot.

The order depicted in All Notes section should be depicted in widget as well as inside a specific category

### Ability to order pinned notes

A pinned note will gain a two-dash visual and the ability to be dragged-and-dropped, very similar to this ability inside the Category section. 
This ability is only possible from the All Notes section.
Releasing a note beyond pinned notes should be handled gracefully.

### Clarification regarding notes order inside a category

Notes cannot be pinned, unpinned or reordered inside their respective category, but their status should still take effect.

Example:

Category: Letters

Assuming no pinned notes, this is current order based on last created/seen time:
- A
- B
- C
- D

Inside All Notes section, user pinned notes A and C, and ordered C to be on top of A.

The order of notes now inside Letters category:
- C
- A
- B
- D
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