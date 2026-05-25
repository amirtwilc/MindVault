# Feature Spec: Jots Section

## Introduction

App should encourage user to quickly add any thought popping to their head, with no hassle or too much thinking, like choosing a category.
This means that user might have at some point many unorganized thoughts, and it's the app objective to order them.
The section will make use of AI API (Gemini) to organize the thoughts and advise how to handle each one, for example:
- Creating a new note under X category
- Create and alert
- Create a checklist note

## Goal

Adding a new section to the app, called Jots, handling short thoughts user has and handling them manually, or in bulk using AI API

---

## Requirements

### Section language

As for any part of the app, everything should be translated and match the supported languages of the app

### Adding a quick thought (jot)

Adding a quick thought is possible via the following ways:
- Inside Quick Thoughts section (new section) - A plus button, similar to the one in All Notes section, would open a quick dialog to insert a thought.
- A quick button from inside each of the existing two widgets - Will open a floating window where only text can be inputted, along with a save button and an X button to dismiss the thought. Dismissing via X button or clicking outside of the window should not open a dialog asking if should dismiss, but rather simply dismiss the thought and not saving it at all.
- A new widget - Widget will LOOK like a one line text receiver (similar idea to Google search widget), welcoming user to type a thought. Clicking it will open the same floating window like in the other widgets, allowing to save a thought

Clicking `Save` when user finished the thought should write a quick `Thought Saved` message.

### Quick thought limit

A quick thought should not be longer than 100 characters (should be easily changed later, maybe Pro user will have higher limit).
When writing a quick thought, once user reaches 50% on the length, an indicator showing the number of characters typed should be displayed, along with how many left, for example: `85/100 characters`.
Exceeding the 100th character should not be possible, typing should not do anything and `100/100 characters` should be displayed in red.

### Jots section layout

Section should display all unhandled thoughts, encouraging user to handle them by organizing each one.
Thoughts would be displayed sorted by created time, oldest first by default, but may be changed to newest first (if changed, then will stay like this if app refreshes).

A special button on top would allow to send all* quick thoughts to AI, for suggesting how to handle each one.
The button should be allowed to use only once a day. Pro users would be able to use it more.
Button will have an info button describing how this AI feature works. Should mention for example that only category names and note titles are passed to AI, and that not all notes or thoughts might be sent.
If AI already made suggestions, another button would allow to accept all suggestions in a click of a button.

*only send thoughts that were not yet sent to AI. Limit thoughts to 30 (oldest 30), and tell user if has to limit.

Each thought text would be completely visible in the section, along with a created timestamp.
For each thought, an action button would be visible, opening a small window (with the section in the background), that allows to perform a number of actions.
The layout of the small window is described in `Thought actions window layout` section
Only when `Accept` button is pressed on the actions window will the actions take effect, thought will be removed from the section (except for specific actions) and the small window will close.

Long pressing a thought would select this thought and allows to pick additional thoughts. A delete button would appear after long pressing a thought, allowing to completely delete all selected thoughts.

### Thought actions window layout

Actions window allows the user to choose what they want to do for each thought.
Some actions can be chosen with other actions, while some cannot.
Only when `Accept` button is pressed will the actions take effect.
All actions will be displayed inside the same window, and some actions, once selected, will open additional actions inside. Unchecking such an action will close these additional actions (but will be remembered in case user checks that outer action again).

This is the actions layout and their capabilities:

- Create new note: Will create a new note, with this "thought" as the body.
    - Title: Allow to write a title for the new note (default empty)
    - Category: Allow to choose/create category for the new note (default General)
    - Note type: Default as `text`, able to change to `checklist`
    - Lock: Should the note be locked (default unlocked)
- Add to existing note: Will add "thought" as a new line at the end of the body
    - Cateogry: Able to choose which category the note is in (default at General)
    - Note: Able to choose an existing note from chosen category
- Create alert: Will open a date and time picker to choose when alert will pop. If chosen along with create/add to existing note, then first create/add and then put alert inside said note. If not, then create a reminder as part of this thought, and do not delete it from section (deleting this thought before reminder fired should delete the reminder)
- Delete thought: Delete this thought without performing ANY action

To clarify:
* "Create note" cannot be performed with "add to note" or "delete", but can be performed with "create reminder".
* "Add to note" cannot be performed with "Create note" or "delete", but can be performed with "create reminder".
* "Create reminder" cannot be performed with "delete".

If AI gave a suggestion about a specific thought, then opening this actions window will auto-fill the suggestions, for example: 
* Title for new note already typed.
* Category for either create note or add to note, already chosen.
* Time picker for reminder already set.
Window should also have a special color and info text that says these actions were suggested by AI.


### How AI works

Disclaimer: This is a delicate part of the system that I am not completely sure how it should be implemented. Feel free to change or suggest ideas that might be smarter in your opinion.

AI prompt should receive a limited number of thoughts (maybe 30? prioritize oldest) and all the actions he may suggest to perform (as described in `Thought actions window layout`, but without a delete option). Prompt should also receieve as many Category names and corresponding note titles so it can suggest to "add to existing note", but since we don't want the prompt to get too large, then a limit should be enforced, and probably only take last created/seen notes.

AI should support multiple languages. Maybe even some thoughts in the same prompt will be in different languages, and maybe category names and titles might be in different languages.

AI should not make a suggestion it is not sure of, and avoid hallucinations. Not giving a suggestion is completely acceptable.

One of the possible actions is creating an alert for a thought (or note), so AI should give a specific time (if it believes there should be one), even if thought did not explicitly said when. It should also do schedule it smartly. For example, a thought like "Doctor appointment on 10.9", could probably set an alert for the morning of 10.9, but a smarter alternative is setting it to the night of the 9.9. Prompt should probably also be aware of date structures (10.9 can be September 10th or October 9th). Perhaps decide it based on device language? If in German/UK English then 10.9 is Spetember 10th, but if US English then 10.9 is October 9th.

Section should gracefully handle these scenarios that might occurr with AI:
- No new thoughts are available: If there are no thoguhts, or if all current thoughts already went throught AI (even if not all received suggestions), then should not run AI at all.
- AI gave all/some thoughts suggestions: a message should appear saying that X suggestions were provided, allowing to accept all NEW suggestions (not from older AI run) from the message window, or choose to close message window and perform it manually.
- AI was not able to give any suggestions: a message should appear saying the 0 suggestions were provided, advising user to write more specific thoughts in the future.

### Organize thoughts reminder

At the end of each day (20:00), if user has written new thoughts that were not yet handled, an app notification should pop, saying:
"You added X thoughts today, want to organize them?"
Clicking the notification should bring user to the Quick Thoughts section inside the app

## Before planning

This is a complicated and the most important feature of the app, and therefore must be performed with the highest standards.
Assume the requirements are not thought out completely, and some gaps might be present. It is your job to mediate these gaps before starting to code.
Make sure you understand the task completely. Ask questions to clarify ambigious or untouched areas.
Feel free to give suggestions for things that were not considered and give your opinion if you believe things should be handled differently.

## Done When

- Thoughts are able to be created from app and widgets, and are visible from Quick Thoughts section
- New widget for Quick Thought was created
- Actions for thoughts are visible and working
- AI capability to suggests thought actions is working
- Sufficiently covered unit and integration tests are created and passed
- Manual verification and approval

## Perform after completion

Once feature is finished and I approve it, update this spec by adding a new section with information about:
- What challenges were met (if were any)
- What design choice was chosen and why
- What design alternatives were strongly considered (if were any) 

---

## Completion Notes

### Challenges Met

- **Local-first encrypted sync:** Jots were added as a new local-first entity using the existing Drift, Supabase, pending-op, and Realtime sync pattern. Plaintext stays local while remote jot text and AI suggestion JSON are encrypted.
- **Widget-to-app capture flow:** Existing widgets gained a jot action, and a dedicated 1x1 Jot widget was added. The floating compose window supports save/dismiss without discard confirmation, auto-growing text, the 100-character limit, and best-effort keyboard auto-open. Android launchers can still suppress automatic keyboard display when an app is opened from a widget PendingIntent, so the implementation explicitly requests focus and retries showing the IME after the transparent activity attaches.
- **Reminder reliability:** Jot reminders required separate native scheduling/storage so note reminder reconciliation would not cancel them. Later testing showed some devices also require background/autostart permission for exact reminders after the app is closed, so the reminder permission flow now explains this and opens manufacturer-specific settings where possible.
- **Reminder state cleanup:** Fired jot reminders now stop showing as active, deleting one jot no longer cancels unrelated jot reminders, and opening a jot with an active reminder pre-fills the alert option so the user can edit or uncheck it to cancel.
- **AI prompt size:** The Jots AI prompt was compacted with request-local aliases and reduced note/category duplication.
- **Tier usage correctness:** Jot AI usage was added to Settings and adjusted so the UI waits for resolved tier limits instead of temporarily rendering hardcoded Free defaults.
- **Localization gaps:** New Jots, reminder, widget, and Settings strings were added across supported ARB files so release builds no longer warn about missing translations for this feature.

### Design Choices

- **Section name:** The final app label is **Jots**, matching navigation, routes, localization, and domain naming.
- **Jot length:** Jots use a single `JotConstants.maxChars` value of 100. This keeps the current behavior simple while leaving a single expansion point for future tier-based limits.
- **Unhandled list behavior:** The Jots screen shows unhandled jots with full text and timestamp, oldest-first by default, with persisted newest/oldest sorting.
- **Action execution:** The action sheet remains an explicit review step. Create note, add to existing note, update thought text, create alert, and delete only take effect after `Accept`.
- **Update thought action:** Users and AI can optionally rewrite the jot text before placing it into a note/checklist or saving it back to the jot. This handles cases like converting “I want to see Lord of the Rings” to “Lord of the Rings”.
- **Alert handling:** Alert-only jots remain visible and store `jot.reminderAt`; alerts combined with note creation/addition become note reminders and clear/cancel any existing jot reminder.
- **Existing-note selection:** Untitled notes are omitted from the add-to-existing-note picker to avoid confusing destinations.
- **AI context:** Gemini receives unsent, unhandled jots, capped at the oldest 30; category names; and bounded recent/opened non-private note titles only. Private note titles are excluded.
- **AI output validation:** The client/edge mapping drops invalid, low-confidence, malformed, hallucinated, or unsupported suggestions, and marks sent jots as processed even if no suggestion is returned.
- **Production AI path:** The Jots AI organizer does not include tester debug flags, debug UI, request/response echoing, or usage reset tools in the app or edge function.
- **Widgets:** The dedicated Jot widget stays 1x1, with a top MindVault app-open target and a large lightning jot-create target below it. Existing widgets keep their configured size while using compact, balanced header controls.

### Alternatives Considered

- **Remote-only jots:** Rejected because it would break the app’s local-first/offline sync model and make quick capture less reliable.
- **No encryption for jots:** Rejected because jots may contain sensitive thoughts; remote text and AI suggestions follow the same privacy posture as notes.
- **Sending full note bodies to AI:** Rejected to reduce token usage and privacy exposure. Category names and non-private note titles are enough for routing suggestions.
- **Long UUIDs in the Gemini prompt:** Replaced with compact request-local aliases (`j1`, `c1`, `n1`) to reduce prompt size while mapping back to real IDs server-side.
- **Single shared reminder reconciliation for notes and jots:** Rejected after testing because note reconciliation could cancel jot alarms. Jot reminders now have separate native methods/storage.
- **Relying only on exact alarm permission:** Rejected after device testing. Some Android/OEM builds require background/autostart permission as well, so the app now guides users to those settings when scheduling reminders.
- **Showing fallback Free tier limits while loading:** Rejected because it caused visible usage flicker like `1/1` before the real `1/5` tier limit loaded. Settings now waits for actual tier data.
