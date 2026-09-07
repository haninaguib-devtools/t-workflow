# 154 — Replace the project site with the human t-workflow guide
Issue: #154

## Asked
Replace the current GitHub Pages site with the standalone redesign on the latest commit
of the `site-redesign-preview` branch. The new site should explain t-workflow in a
clear, human voice: begin with the problem it solves, let the ordinary workflow unfold
naturally, and introduce its machinery only after the reader understands why it exists.
Its visual language should feel like a considered developer field guide rather than a
promotional product page. Installation must remain a prominent action rather than
becoming a footnote.

The artifact is available at
https://github.com/haninaguib-devtools/t-workflow/tree/site-redesign-preview. Copy the
approved files into the repository's real `site/` directory through the normal
t-workflow delivery path; do not merge the orphan preview branch wholesale.

## Done when
- `site/` contains the reviewed redesign from the latest commit on
  `site-redesign-preview`, adapted only where the existing Pages deployment requires it.
- The site provides complete light and dark themes, starts in the light theme for a new
  visitor, and remembers the visitor's explicit choice.
- The design reads as developer documentation: restrained typography and surfaces,
  clear technical structure, and no promotional landing-page treatment.
- The opening viewport prominently presents the interactive installer command from
  `README.md`, and the same installation path appears again near the end of the page.
- The narrative reads naturally in this order: why t-workflow exists, how an ordinary
  task moves, how initiatives and automation work, how outside collaboration fits, what
  the repository remembers, and what the supporting scripts enforce.
- The content is checked against the workflow after initiative #139 has landed. No
  proposed behavior is presented as current if the final implementation differs from
  the preview copy.
- The current site content and styling are replaced, with no stale duplicate pages or
  navigation paths left behind.
- The site remains a dependency-free static artifact and the existing GitHub Pages
  workflow publishes it successfully.
- Navigation, stage tabs, disclosure panels, copy buttons, keyboard operation, focus
  states, reduced-motion behavior, and no-JavaScript reading are verified.
- A maintainer checks the deployed site on desktop and mobile for readability, flow,
  visual hierarchy, and the intended human tone.

## Explicitly not
- Changing t-workflow skills, scripts, architecture, installer behavior, or delivery
  policy.
- Redesigning the preview through an unrelated framework or adding a build-time
  dependency.
- Merging the standalone artifact branch into `main` as repository history.
- Publishing workflow claims that initiative #139 did not ultimately deliver.

## Origin
none

## Verification
- role: maintainer — required: true
  what: Visual/UX review of the *deployed* GitHub Pages site (not just the PR diff) —
    readability, flow, visual hierarchy, and that the tone reads as a developer field
    guide rather than a promotional page — on both desktop and mobile.
  state: pending
  evidence: awaiting — revision: `none yet`
  by: — date: —

## Feedback
none

## Decisions made along the way
- none

## Deviations / notes
- none
