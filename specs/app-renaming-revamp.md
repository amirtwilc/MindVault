# Feature Spec: App sections renaming

## Introduction

This app idea is to be an extension of the user mind, and should therefore look the part.
Words like "Notes" and "Categories" make the app look like a generic note-taking app, but it is not the case

## Goal

Revamp the entire app, only via naming (not actual visual design), in order to achieve the experience that this app is the extension of the user mind. 

---

## Requirements

### Renaming scope

ENTIRE app should be went over, making sure every old name is renamed.
The change should not only be on client side, but on code side (file name, variables, comments, etc.)

## App design

The current app visual design should not change at all, only the describing words of things

## Languages

This spec is written in English, but every describing word should be translated to the supported languages (this include the Jots section, which is currently called Jots in all languages).
Unless specifically mentioned now or during development, other languages should not contain a mixture of said language + English.
Since I do not speak most of the other languages, I expect your help finding the best translations. This may sometimes require creativity. Adhere to the goal. 
You have full autonomy to decide, but you may ask me if conflicted.

## Sections/entities new names

| Old Section | New Section | 
| ------------ | ---------- | 
| All notes | Archive | 
| Jots | Sparks | 
| Categories | Clusters | 
| Search | Recall | 
| Settings | Settings (keep) |

* Regarding Jots/Sparks, only change the word jot(s) to spark(s). The word "Thought" should not be renamed.

| Old Entity | New Entity | 
| ---------- | ---------- | 
| Note | Memory |
| Text (note type) | Record |
| Checklist (note type) | Plan |

## Do not use "Replace All"

If I say one word should be changed to another, that does not mean to do it blindly.
For example, The "Search" section has been renamed to "Recall". But inside the section, where it now says "Search notes..." I do not expect to change the words, but rather to keep it as is.
So, changes should be made with care, and ask me about any part where you need my decision.

---

## Done When

- All names have been changed server side
- All names have been changed client side
- All tests pass


