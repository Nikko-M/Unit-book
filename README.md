# Unit Book

**Live:** <https://nikko-m.github.io/Unit-book/>

A personal sports betting tracker. Bets are logged in **units** at **decimal odds**, with
bonus-bet handling, cash-outs, a bankroll bar, a net-profit chart, breakdowns by sport /
league / month / reason / loss reason, a player check list and a searchable history.

Single self-contained `index.html` — no build step, no dependencies to install.

---

## Two back ends, one file

`index.html` detects where it is running:

| Where | Storage | Sign-in |
|---|---|---|
| Published as a Claude artifact | the artifact's own database | your Claude account |
| Hosted anywhere else (GitHub Pages, Netflify, a local file server) | Firebase Firestore | Google sign-in |

The app code is identical. Only the few lines in `startFirebase()` / `attachStorage()` differ,
and `fbAdapter()` presents Firestore in the same shape the artifact database uses.

---

## Setting up Firebase

You need a Google account. About ten minutes, all free tier.

1. **Create the project** — <https://console.firebase.google.com> → *Add project*.
   Call it anything; Google Analytics is not needed.

2. **Turn on Google sign-in** — *Build → Authentication → Get started → Sign-in method →
   Google → Enable*. Set a support email. Save.

3. **Create the database** — *Build → Firestore Database → Create database*.
   Pick a location near you (`australia-southeast1` is the closest to NZ).
   Start in **production mode** — the rules below replace the defaults anyway.

4. **Register the web app** — *Project settings* (the gear) → *Your apps* → the `</>` icon.
   Give it a nickname, skip Hosting. Copy the `firebaseConfig` object it shows you.

5. **Paste the config into `index.html`.** Search for `FIREBASE_CONFIG` and fill in the four
   values:

   ```js
   const FIREBASE_CONFIG={
     apiKey:"AIza...",
     authDomain:"your-project.firebaseapp.com",
     projectId:"your-project",
     appId:"1:123...:web:abc..."
   };
   ```

   These are **not secrets.** They identify the project, they do not grant access — anyone
   can read them out of any Firebase web app. What keeps your data private is the security
   rules in step 6. Committing them is normal and expected.

6. **Publish the security rules** — *Firestore Database → Rules*, paste the contents of
   [`firestore.rules`](firestore.rules), *Publish*.

   These say: a signed-in user may read and write `users/{their own uid}` and everything
   under it, and nothing else. Signed out, nothing is readable. Without this step Firestore's
   default rules will lock you out (production mode) or expose everything (test mode) — do
   not skip it.

7. **Authorise your domain** — *Authentication → Settings → Authorized domains → Add domain*.
   Add the host you publish on, e.g. `yourname.github.io`. `localhost` is there by default.
   Missing this is the usual cause of `auth/unauthorized-domain` on first sign-in.

---

## Publishing on GitHub Pages

1. Push this repo to GitHub.
2. *Settings → Pages → Build and deployment → Source: Deploy from a branch*, branch `main`,
   folder `/ (root)`. Save.
3. It appears at `https://<user>.github.io/<repo>/` within a minute or two.
4. Add that host to Firebase's authorized domains (step 7 above) if you haven't.

> The **site** is public — GitHub Pages always is, on every plan short of Enterprise Cloud.
> That is fine: the page is just the app. Your bets sit behind Google sign-in in Firestore
> and nobody else can read them. Do not confuse "the repo is private" with "the site is
> private" — a private repo on GitHub Pro still publishes a public site.

---

## Moving your bets across

Export files are deliberately **not** kept in this repo — a betting record does not belong in
public source control. `.gitignore` blocks `*-backup.json` so one is not committed by accident.

To bring an existing book across, keep the export file on your own device, then:

1. Open the hosted app and sign in.
2. *Settings → Import a backup* → choose the file.
3. It writes each bet under your account and applies the saved settings.

Bets keep their original ids, so importing the same file twice overwrites rather than
duplicates. Nothing already in your account is deleted.

The format, if you ever want to write one by hand:

```json
{
  "settings": { "startBankroll": 15, "unitValue": 10, "stakeMode": "cash", "sports": [] },
  "bets": {
    "<bet id>": { "date": "2026-09-28", "sport": "...", "selection": "...",
                  "odds": 1.9, "stake": 1, "status": "won" }
  }
}
```

Missing fields are filled with sane defaults on import.

---

## Reading a bet slip from a screenshot

There are three ways in: **paste** a slip with Ctrl/Cmd+V, **drag** the image onto
the page, or use the camera button beside **Log bet**. Pasting is usually quickest —
screenshot the slip, paste, done. However it arrives, it is read on your device with [Tesseract](https://tesseract.projectnaptha.com/),
then drops what it found into the normal bet form for you to check before logging.
Nothing is uploaded and no API key is involved; the recogniser downloads once
from a CDN and is then cached by the browser.

It reads the bookmaker, date, sport, odds, stake and what the bet was. A multi
comes in as one bet named for the match it is on, or for its selections when the
legs span different matches -- the odds and the stake are what the P/L turns on,
and leg by leg detail from a live slip was more noise than help. Legs can still be
added by hand on the bet form when one is worth tracking on the player check list.

Odds and handicap numbers are read several times at different scales and contrasts,
and the reading that wins the most votes is used — a single pass misreads `8.11` as
`8` often enough to matter. Even so the form always opens for a check: a scan never
saves a bet on its own.

If the recogniser cannot be downloaded — no connection, or a page policy that
blocks the CDN — it says so rather than failing quietly.

## Running it locally

Needs a server — ES module imports and Firebase auth will not work from a `file://` URL.

```sh
python3 -m http.server 8000
# then open http://localhost:8000
```

---

## Cost

Firestore's free tier is 50,000 document reads, 20,000 writes and 1 GiB stored per day.
A bet is one small document. Logging a few hundred bets a year will not come close —
this stays free unless something goes badly wrong.

---

## Notes

- **Units, not dollars.** Stakes and P/L are stored in units so the record stays comparable
  if your stake size changes. Setting a unit value in Settings adds NZ$ figures alongside.
- **Bonus bets** don't count toward turnover; a win pays `stake × (odds − 1)` in cash and a
  loss costs nothing. A cash-out paid *in* bonus bets settles the bet as a loss and records
  the credit separately, so its value isn't counted twice.
- **Offline.** Firestore's local cache is enabled, so the app opens and reads while offline
  and syncs when you're back.
