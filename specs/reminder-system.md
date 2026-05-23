# Feature Spec: Reminder system for notes

## Goal

This feature should allow user to set up a reminders (notifications) for a specific note

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

## Before planning

Assume the requirements are not thought out completely, and some gaps might be present. It is your job to mediate these gaps before starting to code.
Make sure you understand the task completely. Ask questions to clarify ambigious or untouched areas.
Feel free to give suggestions for things that were not considered and give your opinion if you believe things should be handled differently.

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

---

## Completion notes

### Implemented behavior

- Each note supports one non-recurring reminder.
- Reminder data is synced through the local-first notes architecture using Drift, Supabase, pending operations, Realtime updates, and soft-delete tombstones.
- Each Android device schedules its own local alarm for active reminders.
- Reminder buttons are available in the main note editor and widget note view/edit flows.
- Future reminders show an active bell state. Once the scheduled time has passed, the reminder is treated as inactive in the UI and is cleaned up so it does not block setting a new reminder.
- When a reminder fires, Android posts a native notification with the note title, or the first four body words when the title is empty.
- Notification body text is localized according to the app language.
- Tapping a reminder notification opens the matching note. When the user leaves that note with either the app back button or the device back button, the app returns to All Notes.
- Notification permission is requested once after the signed-in app is ready. If denied, app startup does not keep prompting, but tapping the reminder bell requests permission again.
- If notification permission is still not granted while scheduling, the app shows: "Notification permission must be granted for reminders." This message is localized.

### Challenges met

- Android clears scheduled alarms on reboot, so the implementation adds boot/package-replaced rescheduling for remembered future alarms.
- App-closed reminder delivery required native Android alarm and notification receivers instead of relying on Dart timers.
- Notification taps initially reached GoRouter as raw `mindvault://...` locations, causing route errors. The final design disables Flutter's raw deep-link forwarding for this activity, maps native reminder links to `/reminder-note`, and also keeps a router redirect fallback.
- Cold-start notification taps bypassed the splash screen, which meant the AES key was not loaded before resolving the note. The reminder resolver now loads the stored key and waits for auth/session readiness before loading the note.
- Opening an editor directly from a notification produced an empty navigation stack, so device back could fall through to a black screen. Reminder-opened editors now explicitly return to All Notes.
- Android notification channels are sticky once created. A new high-importance reminder channel was used so existing test installs pick up sound, vibration, and lights.
- Android notification permission requests are asynchronous. The native method channel now waits for `onRequestPermissionsResult` before Dart decides whether scheduling can continue.

### Design choices

- Reminder records are synced, but alarm scheduling is device-local. This keeps cross-device intent consistent while respecting Android's per-device alarm system.
- Reminder notification deep links carry only `noteId`. Flutter resolves the category locally at open time, avoiding stale `categoryId` values after note moves or sync updates.
- Expired reminders are not shown as active after their scheduled time. This was chosen for the user experience: once a reminder has fired, the bell should behave as if no active reminder exists.
- Reminder-opened notes return to All Notes instead of trying to reconstruct the previous category or editor stack. This is predictable and avoids black screens from direct notification launches.
- Exact alarms are used when Android allows them; otherwise reminders fall back to inexact alarm APIs and the app warns that delivery may be delayed.
- The initial notification permission prompt is tied to signed-in app readiness rather than raw first launch, so the prompt appears at a meaningful time and does not run too early during auth/bootstrap.

### Alternatives considered

- A cloud/server-triggered notification system was considered, but local Android alarms were chosen because reminders must work while the app is closed and remain local-first.
- Storing `categoryId` in the notification deep link was considered, but resolving it from the local note was safer because notes can move categories after a reminder is scheduled.
- Keeping overdue reminders active for a grace window was considered in the initial plan, but device testing showed this made the bell feel stale after a reminder fired. The final behavior treats due/past reminders as inactive.
- Reusing the first notification channel was considered, but Android would preserve old silent channel settings on existing installs. A new channel id was chosen to reliably enable sound/lights for testers.
