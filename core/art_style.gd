class_name ArtStyle
## One switch for the HeartGold-style look test (PROJECT_LOG entry 17). With `handheld`
## on, the 3D world renders at the 480x270 base resolution and is scaled up with sharp
## pixels, the camera is steeper and closer, people have chibi proportions and paving
## is chunkier. Set it false to get the previous look back; nothing else changes.

static var handheld := true

## Camera (FollowCamera reads these when handheld is on).
const CAM_PITCH := 52.0
const CAM_DISTANCE := 27.0
const CAM_FOV := 30.0
## People drawn larger than life against the buildings, as handheld RPGs do.
const FIGURE_SCALE := 1.25
## Figure proportions: head size, leg length, arm length.
const HEAD := 1.38
const LEGS := 0.78
const ARMS := 0.88
## Cobble size on wet_ground (metres).
const STONE := 0.45
