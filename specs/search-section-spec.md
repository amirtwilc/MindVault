# Feature Spec: Regular search and AI search combined in one section

## Goal

One section only that handles searching within user notes (not seperating to regular search section and AI search section). 
Section should allow user to enter free text as search input, receiving initial results from regular search, and having the ability to perform an AI search if desired

---

## Requirements

### Regular search should try hard, but fast

Regular search should be smart as possible, but not OVER complicated.
It should try to find an answer without the need of AI, which is expensive, but not in the cost of being slow. It should be very fast.

The search should incorporate a scoring system, having high scored results appear on top. Each search option should score differently (for example, exact match should score highest), and title match should also score better than content match.
Pinned notes should also score better than unpinned notes, and recently created/seen notes should also score better than not recently created/seen.

Proposed search options, ranked by score (first=highest):
1. Exact match. For example, searching "banana sandwich" should find "banana sandwich recipe", but not "sandwich with banana"
2. All words match (AND). For example, searching "banana sandwich" should find "sandwich with banana", but not "banana cake"
3. Prefix Match. For example, searching "nan" will find "nano or "banana".
4. OR search. For example, searching "banana sandwich" will find "banana cake"

Suggest more options if you believe are important and not over costly.

### Integration with AI Search

Before Entering any search input, there will be an instruction in the middle of the screen saying "Search your notes. Type keywords or ask a question. Private notes are ignored". It then gives examples for questions that could be asked, like "How many spoons of sugar in lemon cake recipe?". Clicking an example places it in search (which automatically performs a regular search)

Once user enters search input (or clicked example), there should appear a button that asks if user would like to perform an AI search. If the regular search found results, then the button would appear right below the results with the wording "Not what you were looking for? Try AI search". If the regular search did not find results, then the button would appear in the middle of the screen with the wording "No results found. Click to perform an AI Search".

### AI search history

An history of the latest AI searches should be maintained and accessible from the Search section. A button on top of the Search section will change the page to an AI History page. If History is empty, then the button should not be visible. The History should display the latest 5 searches and their answers (no result=should not be in History).
If a note that is referenced from the History was deleted, then the result should be removed from History.
History page is available only from the app, and not the widget

### Search from widget

A Search button should appear on top of the widget, next to the + button. Clicking it should open a floating window, and not the app itself, allowing user to perform a search that is similar in capabilities to the search performed from the app, including the AI search. 
Although AI history is not accessible from the widget, the search and the result (assuming a result was found) should still be archived, and therefore accesible from the History page inside the app.

---

## Done When

- Regular Search and AI Search are integrally merged into one section
- AI History page is implemented
- Regular Search and AI Search are available from widget
- Sufficiently covered unit and integration tests are created and passed
- Manual testing are performed and approved

## Perform after completion

Once feature is finished and I approve it, update README.md with information about:
- What the requirement was, in short
- What challenges were met (if were any)
- What design choice was chosen and why
- What design alternatives were strongly considered (if were any) 