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

### Adding a quick thought

Adding a quick thought is possible via the following ways:
- Inside Quick Thoughts section (new section) - A plus button, similar to the one in All Notes section, would open a quick dialog to insert a thought.
- A quick button from inside each of the existing two widgets - Will open a floating window where only text can be inputted, along with a save button and an X button to dismiss the thought. Dismissing via X button or clicking outside of the window should not open a dialog asking if should dismiss, but rather simply dismiss the thought and not saving it at all.
- A new widget - Widget will LOOK like a one line text receiver (similar idea to Google search widget), welcoming user to type a thought. Clicking it will open the same floating window like in the other widgets, allowing to save a thought

Clicking `Save` when user finished the thought should write a quick `Thought Saved` message.

### Quick thought limit

A quick thought should not be longer than 100 characters (should be easily changed later, maybe Pro user will have higher limit).
When writing a quick thought, once user reaches 50% on the length, an indicator showing the number of characters typed should be displayed, along with how many left, for example: `85/100 characters`.
Exceeding the 100th character should not be possible, typing should not do anything and `100/100 characters` should be displayed in red.

### Quick Thought section layout

Section should display all unhandled thoughts, encouraging user to handle them by organizing each one.
Thoughts would be displayed sorted by created time, oldest first by default, but may be changed to newest first (if changed, then will stay like this if app refreshes).

A special button on top would allow to send all* quick thoughts to AI, for suggesting how to handle each one.
The button should be allowed to use only once a day. Pro users would be able to use it more. As a tester I should be able to reset it manually.
Button will have an info button describing how this AI feature works. Should mention for example that only category names and note titles are passed to AI, and that not all notes or thoughts might be sent.
If AI already made suggestions, another button would allow to accept all suggestions in a click of a button.

*only send thoughts that were not yet sent to AI. Limit thoughts to 30 (oldest 30), and tell user if has to limit.

Each thought text would be completely visible in the section, along with a created timestamp.
For each thought, an action button would be visible, opening a small window (with the section in the background), that allows to perform a number of actions.
The layout of the small window is described in `Thought actions window layout` section
Only when `Accept` button is pressed on the actions window will the actions take effect, thought will be removed from the section (except for specific actions) and the small window will close.

Long pressing a thought would select this thought and allows to pick additional thoughts. A delete button would appear after long pressing a thoguht, allowing to completely delete all selected thoughts.

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
    - Lock: Should the note be locked
- Add to existing note: Will add "thought" as a new line at the end of the body
    - Cateogry: Able to choose which category the note is in (default at General)
    - Note: Able to choose an existing note from chosen category
- Create alert: Will open a date and time picker to choose when alert will pop. If chosen along with create/add to existing note, then first create/add and then put alert inside said note. If not, then create alert as part of this thought, and do not delete it from section
- Delete thought: Delete this thought without performing ANY action

To clarify:
* "Create note" cannot be performed with "add to note" or "delete", but can be performed with "create alert".
* "Add to note" cannot be performed with "Create note" or "delete", but can be performed with "create alert".
* "Create alert" cannot be performed with "delete".

If AI gave a suggestion about a specific thought, then opening this actions window will auto-fill the suggestions, for example: 
* Title for new note already typed.
* Category for either create note or add to note, already chosen.
* Time picker for alert already set.
Window should also have a special color and info text that says these actions were suggested by AI.


### How AI works

Disclaimer: This is a delicate part of the system that I am not completely sure how it should be implemented. Feel free to change or suggest ideas that might be smarter in your opinion.

AI prompt should receive a limited number of thoughts (maybe 30? prioritize oldest) and all the actions he may suggest to perform (as described in `Thought actions window layout`, but without a delete option). Prompt should also receieve as many Category names and corresponding note titles so it can suggest to "add to existing note", but since we don't want the prompt to get too large, then a limit should be enforced, and probably only take last created/seen notes.

AI should support multiple languages. Maybe even some thoughts in the same prompt will be in different languages, and maybe category names and titles might be in different languages.

AI should not make a suggestion it is not sure of, and avoid hallucinations. Not giving a suggestion is completely acceptable.

One of the possible actions is creating an alert for a thought (or note), so AI should give a specific time (if it believes there should be one), even if thought did not explicitly said when. It should also do schedule it smartly. For example, a thought like "Doctor appointment on 10.9", could probably set an alert for the morning of 10.9, but a smarter alternative is setting it to the night of the 9.9. Prompt should probably also be aware of date structures (10.9 can be September 10th or October 9th). Perhaps decide it based on device language? If in German/UK english then 10.9 is Spetember 10th, but if US English then 10.9 is October 9th.

Section should gracefully handle these scenarios that might occurr with AI:
- No new thoughts are available: If there are no thoguhts, or if all current thoughts already went throught AI (even if not all received suggestions), then should not run AI at all.
- AI gave all/some thoughts suggestions: a message should appear saying that X suggestions were provided, allowing to accept all NEW suggestions (not from older AI run) from the message window, or choose to close message window and perform it manually.
- AI was not able to give any suggestions: a message should appear saying the 0 suggestions were provided, advising user to write more specific thoughts in the future.

### Organize thoughts reminder

At the end of each day (20:00), if user has written new thoughts that were not yet handled, an app notification should pop, saying:
"You added X thoughts today, want to handle them?"
Clicking the notification should bring user to the Quick Thoughts section inside the app



---

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