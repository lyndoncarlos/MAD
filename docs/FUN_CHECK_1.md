# Fun check #1 (Jira: "Playtest check #1 (Decision)")

**Question to answer:** is 5 minutes of this loop fun with one hero and two weapons?
If not, fix the core loop now. Content, art and meta-progression will not rescue a loop that feels dead.

## How to run it
1. Play **three runs of about 5 minutes each**, on fixed seeds so you can repeat them:
   `godot --path . -- --seed=111`, then `222`, then `333`.
2. On the first level-up, take the second weapon (Asin) at least once. On another run, avoid it.
3. Right after each run, fill in one row below. Do it immediately; memory fades fast.
4. Open the run log (Editor: **Project → Open User Data Folder → run_logs**) and note the time of death and build.

## Record
| Seed | Died at | Level | Kills | Build (weapons / passives) | Felt: boring / fair / unfair / fun |
|---|---|---|---|---|---|
| 111 | | | | | |
| 222 | | | | | |
| 333 | | | | | |

## Questions
- Did you ever want to stop before 5 minutes? When, and why?
- Was there a moment of "ooh, that upgrade changed things"? Which one?
- Did level-ups arrive often enough to feel rewarding? Too fast? Too slow?
- Did any damage feel unfair (hits you couldn't avoid)?
- Did the two weapons feel different, or like the same weapon with different graphics?
- What felt dead (no feedback, no tension, nothing to decide)?

## Decision rule
- **Go:** you played at least one run to the end without wanting to quit, and can name one moment that felt good.
- **Fix first:** you quit early or felt nothing. List the top 3 problems as Jira bugs (label `gameplay`) and re-run.
- **Write the outcome** in the Jira Decision ticket in two or three sentences, including what you will change.

## Known placeholders (do not judge these yet)
Grey-box shapes, no sound, one enemy type, flat spawn rates, placeholder XP curve, no run end at 20:00 (that is M2).
