# Feature Spec: Handling a situation where user does not provide a title on note

## Indrotuction

Title of a note is mandatory in the system. Without it user experience is lacking, for example when viewing notes via the widget.
Despite that, user should not be forced to write a title, and should be given a default one in that scenario.

## Goal

Enforce the correct behavior of the system if user does not supply a title on note.
This should be supported via creation/editing via the app and widget

---

## Requirements

### Picking up the default title

Title would be the (up to) first 4 space-seperated tokens, from the first line that has non-whitespace characters (a note with only whitespaces should not be saved at all).

Examples:
- ?? this will 8e my title -> title=?? this will 8e
- a -> title=a

### Support editing note

If note was saved without a title, changing the note's first 4 tokens in edit mode should update the title.

Example flow:
1. Note was saved with this first line: This is => title is: This is
2. Note was updated, now first line: Hello, this is my name => title is: Hello, this is my

### Title is only a placeholder

The picked-up title will be displayed as the title of the note when outside of the note (All Notes section/inside a category/widget), but when user actually dives into the note, they do not see it where the actual title is supposed to be, but rather the title space should be empty and they can put a title that will replace the placeholder title.

### Handling title and body in preview

Since (up to) first 4 tokens are used to form the title, when previewing a note from All Notes section or inside a specific category, we should avoid writing the same 4 tokens in title area AND in body area.
If first line has 4 tokens or less and one of the following lines has non-whitespace characters -> write this following line in body area.
Currently, app does not allow first line to be whitespaced (trimms it on save), so there is no need to handle this scenario.

Examples:

| First line | Second line | Title | Content |
|-------|------|-----|------|
| My first ever note in MindVault | This is working | My first ever note | in MindVault |
| My first | ever note in MindVault | My first | ever note in MindVault |

### cursor placement when creating a new note

When creating a new note, the cursor should automatically be on the body and not the title. User will have to actively click the title in order to change it

---

## Examples and Edge Cases

These examples assume app show only

| First line | Second line | Third line | Displayed title outside the note | Content shown outside the note |
|-------|------|-----|------|------|
| This is my 1 | rule | - | This is my 1 | rule |
| ?! is my | 1 | rule | ?! is my | 1 |
| This is | <5 spaces> | my rule | This is | my rule |
| a | <\n> | b | a | b |
| This is a long story | And it continues | - | This is a long | story |


d. First line: This is a really long story => displayed title outside the note: This is a really, Content shown outside the note: long story
e. First line: this is => displayed title outside the note: This is => note was updated, now first line is: hello there => displayed title is now: hello there.
In addition, change the behavior when creating a new note, so the cursor is on the body and not the title (the user will need to actively click the title in order to write it).

---

## Done When

- Unit and integration tests, fully covering the described behavior, are created and passed 
- Manual testing passes for all examples and edge cases described in this document

## Perform after completion

Once feature is finished and I approve it, update README.md with information about:
- What the requirement was, in short
- What challenges were met (if were any)
- What design choice was chosen and why
- What design alternatives were strongly considered (if were any) 