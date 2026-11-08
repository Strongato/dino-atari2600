    processor 6502

    include "vcs.h"
    include "macro.h"

    seg.u Variables
    org $80

    include "variables.asm"
    include "constants.asm"

    seg Code
    org $F000

Start:
    CLEAN_START

    lda #DINO_START_X
    sta DinoXPos

    lda #DINO_START_Y
    sta DinoYPosWhole

    lda #CACTUS_START_X
    sta CactusXPos

    lda #CACTUS_START_Y
    sta CactusYPos

    lda #COLOR_BLACK
    sta GameBgColor

    lda #ANIM_DELAY
    sta DisplayAnimTimer

    lda #CACTUS_START_SPEED
    sta CactusSpeed

    lda #POINTS_PER_SPEEDUP
    sta PointsTillNextSpeedup

RenderFrame:

VSync: ; Tells the console that a new frame started
    lda #VSYNC_ON
    sta VBLANK
    sta VSYNC

    REPEAT LINES_VSYNC
        sta WSYNC
    REPEND

    lda #VSYNC_OFF
    sta VSYNC

VBlank:
    REPEAT LINES_VBLANK
        sta WSYNC
    REPEND

    lda DinoXPos
    ldy #PLAYER_0
    jsr SetObjectXPos

    lda CactusXPos
    ldy #PLAYER_1
    jsr SetObjectXPos

    jsr CalculateDigitOffset

    sta WSYNC
    sta HMOVE ; Apply fine offset

    lda #VBLANK_OFF
    sta VBLANK

Scoreboard:
    lda #0
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    sta CTRLPF

    lda #COLOR_WHITE
    sta COLUPF

    ldx #DIGITS_HEIGHT
.DrawDigits:
    ldy TensDigitOffset
    lda Digits,Y
    and #$F0
    sta ScoreSprite

    ldy OnesDigitOffset
    lda Digits,Y
    and #$0F

    ora ScoreSprite
    sta ScoreSprite

    sta WSYNC
    sta PF1

    inc TensDigitOffset
    inc OnesDigitOffset
    dex
    bne .DrawDigits

    sta WSYNC

    lda #0
    sta PF1

    ; Create a visual gap between the score and the game
    REPEAT LINES_SCORE_GAP
        sta WSYNC
    REPEND

Kernel: ; 2-line kernel
    ldx #LINES_KERNEL
.GameLoop:

.AreWeInsideDino:
    txa
    sec
    sbc DinoYPosWhole
    cmp #DINO_HEIGHT
    bcc .LoadDinoState
    lda #0
.LoadDinoState:
    tay
    lda DinoAnimState
    bne .LoadDinoFrame2
.LoadDinoFrame1:
    lda DinoSprite,Y
    jmp .DrawDino
.LoadDinoFrame2:
    lda DinoSprite2,Y
.DrawDino:
    sta WSYNC                ; (0)
    sta GRP0                 ; (3)

.LoadBackgroundColor:
    lda GameBgColor          ; (6)
    bne .SetBackground       ; (8)  if not taken / (9) if taken
    lda SkyColorByLine,X     ; (12)
.SetBackground:
    sta COLUBK               ; (15) if not taken / (12) if taken

.DrawDinoColor:
    lda DinoColor,Y          ; (19) if not taken / (16) if taken
    sta COLUP0               ; (22) if not taken / (19) if taken
; MUST BE SET HERE TO BE INSIDE FIRST 23 CYCLES OF VBLANK

.AreWeInsideCactus:
    txa
    sec
    sbc CactusYPos
    cmp #CACTUS_HEIGHT
    bcc .DrawCactus
    lda #0
.DrawCactus:
    tay
    lda CactusSprite,Y
    sta WSYNC                ; (0)
    sta GRP1                 ; (3)
    lda CactusColor,Y        ; (7)
    sta COLUP1               ; (10)
; MUST BE SET HERE TO BE INSIDE FIRST 23 CYCLES OF VBLANK
.NextLine:
    dex
    bne .GameLoop

Overscan:
    lda #VBLANK_ON
    sta VBLANK
    REPEAT LINES_OVERSCAN
        sta WSYNC
    REPEND

UpdateAnim:
    dec DisplayAnimTimer
    bne .AnimDone

    lda #ANIM_DELAY
    sta DisplayAnimTimer

    lda DinoAnimState
    eor #1
    sta DinoAnimState

.AnimDone:
    sta WSYNC

UpdatePhysics:
    lda DinoYVelFraction
    clc
    adc #<GRAVITY
    sta DinoYVelFraction
    
    ; if previous adc set carry flag, add it into whole part
    lda DinoYVelWhole
    adc #>GRAVITY 
    sta DinoYVelWhole

    lda DinoYPosFraction
    clc
    adc DinoYVelFraction
    sta DinoYPosFraction

    ; if previous adc set carry flag, add it into whole part
    lda DinoYPosWhole
    adc DinoYVelWhole

    ; Ground Collision
    ; If the player falls too fast and wraps past zero (e.g., Y drops 
    ; from 10 to -1, instantly becoming 255), BMI catches it because 
    ; values > 127 are read as negative.
    ; If it is a normal drop (e.g., Y drops from 10 to 5), BCC catches 
    ; it because 5 is simply less than GROUND_LEVEL.
    bmi .ClampToGround  
    cmp #GROUND_LEVEL   
    bcc .ClampToGround

.SavePosition:
    sta DinoYPosWhole
    jmp .PhysicsDone

.ClampToGround:
    lda #DINO_START_Y
    sta DinoYPosWhole

    lda #0
    sta DinoYVelWhole
    sta DinoYVelFraction
    sta DinoYPosFraction

.PhysicsDone:

HandleInput:
.Up:
    lda #JOY_UP
    bit SWCHA
    bne .Down

    lda DinoYPosWhole
    cmp #GROUND_LEVEL
    bcs .Down

    lda #>JUMP_VELOCITY
    sta DinoYVelWhole
    lda #<JUMP_VELOCITY
    sta DinoYVelFraction
    sta DinoYPosFraction

.PlayJumpSound:
    lda #SOUND_PURE_TONE
    sta AUDC0
    lda #SOUND_JUMP_PITCH
    sta AUDF0
    lda #SOUND_JUMP_VOLUME
    sta AUDV0

    lda #SOUND_JUMP_DURATION
    sta JumpSoundTimerAndVolume

.Down:
    lda #JOY_DOWN
    bit SWCHA
    bne .HandleInputDone

    lda DinoYVelFraction
    clc
    adc #<STOMP_VELOCITY
    sta DinoYVelFraction

    lda DinoYVelWhole
    adc #>STOMP_VELOCITY
    sta DinoYVelWhole

.HandleInputDone:

MoveCactus:
    ldx CactusSpeed

.MoveLeftOnePixel:
    dec CactusXPos
    beq .HitLeftEdge

.CheckSpeedCounter:
    dex
    bne .MoveLeftOnePixel

    jmp .MoveDone

.HitLeftEdge:
    lda #CACTUS_RESET_X
    sta CactusXPos

    lda JustDiedFlag
    beq .ScorePoint
    lda #0
    sta JustDiedFlag
    jmp .MoveDone

.ScorePoint:
    sed
    lda Score
    clc
    adc #1
    cld
    sta Score

    dec PointsTillNextSpeedup
    bne .MoveDone

    inc CactusSpeed
    lda #POINTS_PER_SPEEDUP
    sta PointsTillNextSpeedup

.PlaySpeedUpSound:
    lda #SOUND_PURE_TONE
    sta AUDC0
    lda #SOUND_SPEEDUP_VOLUME
    sta AUDV0

    lda #SOUND_SPEEDUP_DURATION
    sta SpeedUpSoundTimer

    jmp .MoveDone

.MoveDone: ; TODO: ne svida mi se sta .MoveDone je kraj i za score i za move

UpdateChannel0Sound:
.UpdateSpeedUpSound:
    lda SpeedUpSoundTimer
    beq .UpdateJumpSound

    dec SpeedUpSoundTimer
    beq .SpeedUpMute

    lda SpeedUpSoundTimer
    cmp #SOUND_SPEEDUP_SWAP_FRAME
    bcs .SpeedUpPitchLow

.SpeedUpPitchHigh:
    lda #SOUND_SPEEDUP_PITCH_HIGH
    sta AUDF0
    jmp .Channel0SoundDone

.SpeedUpPitchLow:
    lda #SOUND_SPEEDUP_PITCH_LOW
    sta AUDF0
    jmp .Channel0SoundDone

.SpeedUpMute:
    lda #0
    sta AUDV0
    jmp .Channel0SoundDone

.UpdateJumpSound:
    lda JumpSoundTimerAndVolume
    beq .Channel0SoundDone

    dec JumpSoundTimerAndVolume
    lda JumpSoundTimerAndVolume
    sta AUDV0

.Channel0SoundDone:

UpdateChannel1Sound:
.UpdateHitSound:
    lda HitSoundTimer
    beq .Channel1SoundDone

    dec HitSoundTimer
    beq .HitMute

    lda HitSoundTimer
    cmp #SOUND_HIT_DROP_FRAME
    bne .Channel1SoundDone

    lda #SOUND_HIT_PITCH_END
    sta AUDF1
    jmp .Channel1SoundDone

.HitMute:
    lda #0
    sta AUDV1

.Channel1SoundDone:

CheckCollision:
    lda #COLLISION_P0_P1
    bit CXPPMM
    bne .Collided

    ; The GameOver subroutine consumes significantly more CPU cycles.
    ; We must stall this shorter branch with WSYNC so that both execution
    ; paths output the exact same total number of scanlines per frame.
    sta WSYNC
.ResetColor:
    lda #COLOR_BLACK
    sta GameBgColor
    jmp .CollisionDone

.Collided:
    jsr GameOver

.CollisionDone:
    sta CXCLR

    jmp RenderFrame

    include "subroutines.asm"
    include "graphics.asm"

    org $FFFC
    word Start
    word Start
