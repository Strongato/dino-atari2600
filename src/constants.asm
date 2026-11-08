PLAYER_HEIGHT            = 12
DINO_HEIGHT              = PLAYER_HEIGHT
CACTUS_HEIGHT            = PLAYER_HEIGHT
DIGITS_HEIGHT            = 20

GROUND_Y                 = 6

DINO_START_X             = 10
DINO_START_Y             = GROUND_Y

CACTUS_START_X           = 152
CACTUS_RESET_X           = 160
CACTUS_START_Y           = GROUND_Y

CACTUS_START_SPEED       = 1
POINTS_PER_SPEEDUP       = 5

COLOR_BLACK              = $00
COLOR_RED                = $30
COLOR_WHITE              = $0F
COLOR_SKY_BLUE_1         = $80
COLOR_SKY_BLUE_2         = $82
COLOR_SKY_BLUE_3         = $84
COLOR_SKY_BLUE_4         = $86
COLOR_GROUND_GREY        = $08

GROUND_LEVEL             = GROUND_Y+1

ANIM_DELAY               = 8

PIXELS_PER_STEP          = 15

LINES_VBLANK             = 34
LINES_OVERSCAN           = 26
LINES_KERNEL             = 84

LINES_VSYNC              = 3
LINES_SCORE_GAP          = 3

VBLANK_ON                = %00000010
VBLANK_OFF               = 0
VSYNC_ON                 = %00000010
VSYNC_OFF                = 0

; Velocities are 16-bit fixed-point: high byte = whole, low byte = fraction
; Fraction overflows carry into whole, enabling sub-integer values per frame
GRAVITY                  = $FFA0 ; whole=$FF (-1), fraction=$A0 (0.625) = -0.375/frame
STOMP_VELOCITY           = $FF80 ; whole=$FF (-1), fraction=$80 (0.5)   = -0.5/frame boost down
JUMP_VELOCITY            = $03FF ; whole=$03 (+3), fraction=$FF (0.996) = +3.996/frame launch up

PLAYER_0                 = 0
PLAYER_1                 = 1

JOY_UP                   = %00010000
JOY_DOWN                 = %00100000

COLLISION_P0_P1          = %10000000

SOUND_PURE_TONE          = 12

SOUND_JUMP_VOLUME        = 6
SOUND_JUMP_PITCH         = 10
SOUND_JUMP_DURATION      = 6

SOUND_SPEEDUP_VOLUME     = 12
SOUND_SPEEDUP_PITCH_LOW  = 10
SOUND_SPEEDUP_PITCH_HIGH = 5
SOUND_SPEEDUP_DURATION   = 8
SOUND_SPEEDUP_SWAP_FRAME = 4

SOUND_HIT_VOLUME         = 8
SOUND_HIT_PITCH_START    = 24
SOUND_HIT_PITCH_END      = 31
SOUND_HIT_DURATION       = 6
SOUND_HIT_DROP_FRAME     = 4
