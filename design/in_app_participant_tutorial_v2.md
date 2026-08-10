# In-App Participant Tutorial (Version 2)

## Researcher implementation note

This tutorial explains the participant’s required interactions without naming the precise experimental comparison (reminder location, presentation style, intrusiveness, or compliance). It is appropriate to explain the optional response card and dismissal gesture because participants need to understand how the prototype works.

Use neutral wording: do not call the response card a **“compliance card”** in participant-facing text. Refer to it as a **“brief follow-up card”** or **“response card.”** The consent/privacy materials must still accurately explain what interaction data are recorded, including reminder interactions and response-card entries.

Replace all text in `[square brackets]` before deployment.

---

## Screen 1 — Welcome

### Welcome to the health-reminder study

Thank you for taking part.

In this study, you will use a prototype that provides occasional on-screen reminders to support hydration and short movement breaks during normal computer work.

The session is designed to fit around your usual work. There are no right or wrong ways to react to reminders.

**[Button: Continue]**

---

## Screen 2 — Your Participant ID

### Enter your Participant ID

Please enter the Participant ID provided by the researcher.

Use exactly the same ID:
- in this prototype
- in the pre-study questionnaire
- in the end-of-session questionnaire
- in the final questionnaire

Do not enter your name or email address here.

**Participant ID:** `[Text field]`

**[Button: Continue]**

**Validation message if blank:** Please enter the Participant ID provided by the researcher. It starts with the letter 'P'

---

## Screen 3 — Before you begin

### Prepare for your session

Before starting, please:

1. Complete the pre-study questionnaire: **[Insert questionnaire link or QR code]**
2. Keep water within easy reach, if possible.
3. Choose a time when you expect to work at your computer for approximately 2 hours.
4. Work on your own usual tasks, such as reading, writing, coding, design work, or emails.

**[Button: I have completed the pre-study questionnaire]**

---

## Screen 4 — During the session

### Work as you normally would

The prototype will run in the background while you work.

From time to time, you may see a reminder to drink water or take a short movement break. Reminder appearances may vary during the study. This is an intended part of the prototype evaluation.

Please continue with your usual work routine. Do not deliberately change how you work for the study.

**[Button: Continue]**

---

## Screen 5 — How to respond to reminders

### Respond naturally

When a health reminder appears, respond in the way that feels most natural in your current situation.

- If it is convenient, you may follow the suggestion.
- If you are busy, you may dismiss or ignore it.
- You do not need to take a break or drink water every time.

Shortly after a reminder, you may see a brief response card asking whether you followed the suggested action.

- Please answer it honestly based on what you actually did.
- You may skip or ignore the card if you are busy.
- There is no “correct” response.

Honest, natural reactions are the most helpful for this study.

**[Button: Continue]**

---

## Screen 6 — Quickly dismissing a reminder

### Need to focus? You can dismiss a reminder quickly

If a reminder is bothering your work or appears at an inconvenient moment, move the mouse rapidly from side to side (a quick shake).

This will dismiss the reminder so that you can continue your work.


**[Button: Continue]**

---

## Screen 7 — Safety and comfort

### Your comfort comes first

Only take a movement break if it is safe and comfortable for you. You may adapt or skip any suggested action.

Stop the study session if you feel uncomfortable, unwell, or need to deal with an urgent task. You may withdraw as described in the consent information without any disadvantage.

For technical problems, use **[Help / Report a problem button]** or contact **[Lasan Gonsal Korala lasan@uni-bremen.de]**.

**[Button: Continue]**

---

## Screen 8 — Finishing the session

### At the end of the session

When the session timer ends:

1. Complete the End-of-Session Questionnaire: **[Insert link or QR code]**
2. Enter the same Participant ID you used in this app.
3. If you have another study session, follow the instructions from the researcher for when to complete it.

Please complete the questionnaire soon after finishing the session, based on your experience in this session.

**[Button: Start session]**

---

# Optional in-session text

## Session status area

**Study session in progress**

Please continue with your usual work. Health reminders may appear occasionally.

**[Optional: Time remaining: 01:23:45]**

**[Optional button: Report technical problem]**

---

# Optional response-card design

## Brief follow-up card

### Did you follow the suggested action?

- Yes
- No
- Skip

**Participant-facing helper text:** Please answer based on what you actually did. You may skip this card if you are busy.

**Researcher implementation note:** Keep this card brief and visually quieter than the reminder. If it appears automatically, allow it to be dismissed or to time out without recording a forced answer. Use the same response wording for hydration and micro-break reminders because reminder content is not a study factor.

---

## end-of-session screen

## Session complete

Thank you for completing this session.

Please complete the End-of-Session Questionnaire now. Use your Participant ID: **[display stored ID, e.g., P01]**.

**[Button: Open End-of-Session Questionnaire]**

If the button cannot open a browser, use this link:

**[Insert link]**

---

## end-of-study screen

## Study complete

Thank you for completing the study.

Please complete the End-of-Study Questionnaire now. Use your Participant ID: **[display stored ID, e.g., P01]**.

**[Button: Open End-of-Study Questionnaire]**

If the button cannot open a browser, use this link:

**[Insert link]**

---

# Optional technical-problem dialog

## Report a technical problem

Please briefly describe what happened. Do not include personal, sensitive, or confidential work information.

**What happened?** `[Paragraph field]`

**[Button: Send report]**  **[Button: Cancel]**

**Confirmation message:** Thank you. Your report has been saved. You may continue the session, restart the app if instructed by the researcher, or contact **[researcher contact]**.

---

# Researcher checklist

- Mention the response card because it is part of the participant’s interaction procedure, but call it a **brief follow-up card** or **response card**, not a compliance measure.
- State that response-card answers may be skipped and that no response is correct. This reduces pressure to change behaviour merely to satisfy the researcher.
- Explain the rapid mouse-shake gesture and offer a safe way to try it before the session. Participants need to know how to regain control of an interruptive reminder.
- Do not state that the study measures “intrusiveness,” “attention,” “compliance,” a preferred design, or particular screen locations/styles.
- Use neutral wording such as “reminder appearances may vary”; do not name cursor-proximate or system-tray locations, or ambient/character-based styles.
- In the consent/privacy materials, accurately disclose the procedure and all collected data, including reminder events, interactions, response-card answers/skips, and technical logs as applicable.
- Include the same Participant ID consistently in the app, questionnaires, response-card records, and study-event logs.
- Pilot the tutorial with one or two people. Verify that they understand the gesture, response card, links, Participant ID, end-of-session action, and support route—without inferring the exact hypothesis.
