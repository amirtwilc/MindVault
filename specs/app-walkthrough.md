# Feature Spec: App Walkthrough

## Goal

Create an app walkthrough, making the app easier to understand

---

## Requirements

### Visual feel

App walkthrough should have the same visual feel of the app

### Translations

This spec is written in English, but walkthrough should be translated to all supported languages.

### When walkthrough should appear

Walkthrough should appear after user has signed in and after the PIN screen. 
Walkthrough should only appear on the first sign-in after app was installed, 
so if user has signed-out and then signed-in, they should not see the walkthrough.

### Skip option

User should be able to skip the walkthrough from the first screen and anywhere through the walkthrough

### Rewatch ability

The walkthrough should be allowed to be rewatched from the Settings section

### Walkthrough flow

This is the required flow. Write the messages better:
1. Welcome to MindVault, your mind assistant. For best experience allow MindVault to send you reminders (now asks for notification permissions)
2. In order to receive accurate reminders, some devices also require permission to work in the background. Click here so we try to locate these settings, if successful choose MindVault and return to the app.
3. (Point to Archive) This is where you write and watch all of your important memories, like your recipes, your to-dos, and any valuable memory you don't want to forget.
4. (Point to Clusters) This is where you categorize your memories, to keep them organized and color coded
5. (Point to Recall) This is where you can search specific memories, either by keywords or with our AI assistant. Do you have a favorite cake recipe in your memories? Try asking him "How much sugar do I need for my cake?", you will get the answer, not just the memory.
6. (Point to Sparks) Did you suddenly have a spark of thought but did not want to commit it into a memory? This is the place. Write here everything that comes to mind, organize it later. "I need to watch that movie", "Jack likes strawberries", "My colleague daughter name is Beth". Use our Spark AI organizer to suggest what is the best course of action for each thought.
7. Final tip: To get the most out of MindVault use our widgets! (Explain in short how to install widgets)

### Memory (note) walkthrough

Every memory (note), in app only, should have a question mark next to the top buttons.
Clicking the question mark should show a single screen explanation about the memory features: Record, Copy, Reminder, Lock, Cluster, Type (Record or Plan), Title (optional but recommended). Write a short description for each, all in the same screen, with the description pointing or near the corresponding feature.

---

## Done When

- New installation walkthrough is working
- Skippable at every step
- Able to go through installation walkthrough again from Settings
- Memory note single screen explanation is visually understandable and correct
- All languages are supported


