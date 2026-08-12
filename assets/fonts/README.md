# Fonts

This folder is intentionally empty in git.

| Role | Family | File the project looks for |
| --- | --- | --- |
| Headings | Nunito Sans ExtraBold | `NunitoSans-ExtraBold.ttf` |
| UI + body | Nunito Sans SemiBold | `NunitoSans-SemiBold.ttf` |
| Tech data | Space Mono Regular | `SpaceMono-Regular.ttf` |
| Display / wordmark | *custom ruined face — not yet cut* | falls back to ExtraBold |

Run once after cloning:

```powershell
pwsh -File tools/fetch_fonts.ps1     # Windows
```
```bash
./tools/fetch_fonts.sh               # macOS / Linux
```

Both families are SIL Open Font License 1.1. They are not committed because
third-party binaries with their own licence terms belong outside the repo, and
because `src/ui/fonts.gd` degrades to Godot's default face when they are absent —
a fresh clone always runs, it just looks off-brand until you fetch them.

A variable `NunitoSans-Variable.ttf` is also accepted; `fonts.gd` will derive the
weights from it via `FontVariation`.
