# Feature Spec: Reminder system for notes

## Goal

This feature should allow user to set up a reminders (notification) for a specific note

---

## Requirements

### Button layout

A reminder button should be visible in the top section, next to the rest of the buttons, like Copy and Record.
The button would be visible in both the app and the widget, and in both ream mode and edit mode.

If a reminder was set, the button should visually indicate this

### Button functionality

If  reminder is not currently set up for this note, then clicking the reminder button should open a date and time picker, allowing to choose when  reminder will pop on the device.

If  reminder was set for this note, then clicking the reminder button should display a small window, showing when a reminder was set, allowing to close it or edit/remove the  reminder

### Reminder functionality

When a reminder pops up on a device, the title of the reminder should be the title of the note (or the first 4 words if has not title).
Clicking the reminder should open the corresponding note.

### Cross-device handling

If a reminder was set on a note, and app is installed on multiple devices, all devices should pop the reminder.
Canceling a reminder should cancel the reminder in all devices

### Making sure reminder will pop

The app should not allow reminders to be forgotten. This should be achieved mainly by:
- Rescheduling reminder on device startup
- Occasionaly (~every hour) fetch set-up reminders and make sure they are still scheduled

### Asking permissions

When app is installed, then first time it is opened it should ask appropriate permissions so notifications will pop.
If ignored, the permission should not be asked again when opening the app.

Whenever scheduling a reminder (clicking the alert button), app should check if permissions were given, and if not then ask for them again


---

## Done When

- Reminder button and time picker works in app and widget
- Reminders are fired correctly and without fail, even if app is closed
- Sufficiently covered unit and integration tests are created and passed
- Manual verification and approval

## Perform after completion

Once feature is finished and I approve it, update this spec by adding a new section with information about:
- What challenges were met (if were any)
- What design choice was chosen and why
- What design alternatives were strongly considered (if were any) 