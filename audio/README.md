# Audio placeholders

No audio assets exist yet. `core/audio_manager.gd` (autoload `Audio`) looks for these
files by name and stays silent, without errors, when one is missing. Add a file with the
right name and it is used; nothing else needs to change.

| File | Used for | Until it exists |
|---|---|---|
| `audio/music/title.ogg` | Title screen theme. Looping; slow, spacious, slightly melancholic, comforting. | Silence |
| `audio/music/game.ogg` | In-game ambience or score (requested when play begins). | Silence |
| `audio/ui/move.wav` | Menu highlight moves. | Soft synthesised tone |
| `audio/ui/accept.wav` | Menu item chosen. | Soft synthesised two-note tone |
| `audio/ui/back.wav` | Back or cancel. | Soft synthesised falling tone |
| `audio/ui/adjust.wav` | Slider or toggle changed. | Soft synthesised tick |

Music may also be `.mp3` or `.wav`; interface sounds may also be `.ogg`. Set music files
to loop in their import settings.
