# Installing keti

This guide covers installing keti and getting it running on your Mac. For
anything about the study itself, please contact the researcher who sent you
this file.

## What you need

- A Mac running **macOS 12 (Monterey) or later**
- Your **participant code** — the researcher sends this to you separately

## 1. Install the app

1. Open the **keti-1.0.0.dmg** file you were sent.
2. Drag **keti** onto the **Applications** shortcut in that window.
3. Eject the disk image: in Finder's sidebar, click the ⏏ next to **keti**.

Please don't run keti from inside the disk image — drag it into Applications
first, then start it from there.

## 2. Allow it to open (once only)

keti is code-signed but not *notarized*. Notarization requires a paid Apple
developer subscription, so macOS will refuse to open the app the first time and
show a warning. This is expected, and the steps below are the standard way to
allow a trusted app.

1. Open **Applications** and double-click **keti**. macOS shows:

   > "Apple cannot check 'keti' for malicious software."

   Click **Done**. (Don't click "Move to Trash" — that deletes the app.)

2. Open **Terminal**. Press `⌘ Space`, type `Terminal`, and press Return. Paste
   the following line exactly, then press Return:

   ```sh
   xattr -dr com.apple.quarantine /Applications/keti.app
   ```

   Nothing will appear to happen. That's correct — the command has no output.

3. Open **keti** again. It now starts normally, and will keep working from here
   on. You don't need to repeat this step.

### If you would rather not use Terminal

Open keti once (it will be blocked), then go to **System Settings → Privacy &
Security**, scroll down to **Security**, and click **Open Anyway** next to
*keti*. You'll be asked for your Mac password.

Two things to know about this route:

- The **Open Anyway** button only appears for about an hour after a failed
  attempt. If it isn't there, try to open keti once more and look again.
- If you're on macOS 14 or earlier, you can instead **right-click keti → Open**,
  then click **Open** in the dialog. (Apple removed this shortcut in macOS 15.)

## If something goes wrong

| What you see | What to do |
|---|---|
| "Apple cannot check 'keti' for malicious software" | Do **Step 2** above. This is expected on first launch. |
| "keti is damaged and can't be opened" | Usually an incomplete download. Delete the `.dmg`, download it again, and reinstall. Don't keep retrying — it won't fix itself. |
| Double-clicking does nothing at all | Make sure keti is in **Applications** and not still inside the disk image. |
| It opened yesterday but not today | Open **Terminal** and re-run the command from **Step 2**. |

## Removing keti afterwards

Drag **keti** from Applications to the Trash. To also remove the data stored on
your Mac, delete the folder
`~/Library/Containers/app.keti.keti` (in Finder: press `⌘ ⇧ G`, paste that path,
and press Return).

If you have any trouble at all, contact the researcher who sent you this file —
it's much better to ask than to guess.
