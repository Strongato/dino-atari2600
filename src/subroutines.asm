;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle object horizontal position with fine offset
;; A is the target x-coordinate position in pixels of our object
;; Y is the object type (0:player0, 1:player1, 2:missile0, 3:missile1, 4:ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos subroutine     ; 23 cycles + 5 cycles for each loop iteration
    sta WSYNC                ; Wait for a fresh scanline to start
    nop                      ; Waste 2 cycles to align timing
    sec                      ; Set Carry flag before subtraction loop

.Div15Loop:
    sbc #PIXELS_PER_STEP     ; Rough Position: Subtract 15 pixels at a time
    bcs .Div15Loop           ; Keep looping until the Accumulator wraps below 0
                             ; EXAMPLE (Target X = 63):
                             ; 63 - 15 = 48
                             ; 48 - 15 = 33
                             ; 33 - 15 = 18
                             ; 18 - 15 = 3
                             ; 3 - 15  = -12
                             ; Loop ends. Accumulator is now -12.

    ; In Two's Complement, -12 is represented as binary %11110100.

    eor #%00000111           ; Exclusive OR with 7 (%00000111) flips the bottom 3 bits.
                             ; %11110100 EOR %00000111 = %11110011

    asl                      ; Shift 1: %11100110
    asl                      ; Shift 2: %11001100
    asl                      ; Shift 3: %10011000
    asl                      ; Shift 4: %00110000
                             ; The hardware expects the fine-tune value in the top 4 bits.
                             ; The top 4 bits are now %0011, which equals exactly +3.
                             ; (Rough loop landed at 60 + 3 fine pixels = 63 perfect target)

    sta RESP0,Y              ; Hardware trigger: "DROP SPRITE HERE" Sets the rough 15-pixel position.
    sta HMP0,Y               ; Store the %00110000 fraction into the horizontal motion register

    rts                      ; Return from Subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Game Over subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameOver subroutine
    lda #COLOR_RED           ; Load sky red color
    sta GameBgColor          ; Set the background variable to visually indicate death

    lda #0                   ; Load a 0
    sta Score                ; Reset the player's score to 0

    lda #1
    sta JustDiedFlag         ; Set flag to skip scoring on the next cactus wrap

.PlayHitSound:
    lda #SOUND_PURE_TONE     ; Audio Control: Pure Square Wave
    sta AUDC1
    lda #SOUND_HIT_VOLUME    ; Audio Volume: Steady medium volume
    sta AUDV1
    lda #SOUND_HIT_PITCH_START ; Audio Frequency: Start pitch
    sta AUDF1

    lda #SOUND_HIT_DURATION  ; Load hit sound duration
    sta HitSoundTimer        ; Start the timer

.ResetSpeed:
    lda #CACTUS_START_SPEED  ; Load the initial easy speed
    sta CactusSpeed          ; Reset the dynamic speed so the next game doesn't start at impossible speed
    lda #POINTS_PER_SPEEDUP  ; Load the countdown constant
    sta PointsTillNextSpeedup ; Reset the difficulty countdown timer

    rts                      ; Return from Subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle scoreboard digits to be displayed on the screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This converts the high and low nibbles of the Score variable
;; into the offsets of digits lookup table so the values can be displayed.
;; Each digit has a height of 20 bytes in the lookup table.
;;
;; For the low nibble we need to multiply by 20 (height of the sprite)
;;   - N*20 = N*16 + N*4
;;   - we shift left 4 times to get N*16, save N*4 first, then add together
;;
;; For the upper nibble, the value is already stored as N*16 after the mask:
;;   - N*20 = N*16 + N*4
;;   - we shift right twice to get N*4, save N*16, then add together
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CalculateDigitOffset subroutine
    lda Score                ; Load the BCD score
    and #$0F                 ; Mask out the tens digit, keeping ONLY the ones digit (0-9)
    asl                      ; N * 2
    asl                      ; N * 4
    sta OnesDigitOffset      ; Save N*4 temporarily
    asl                      ; N * 8
    asl                      ; N * 16
    clc                      ; Clear Carry before addition
    adc OnesDigitOffset      ; (N * 16) + (N * 4) = N * 20 (Exactly the height of our graphics)
    sta OnesDigitOffset      ; Save the final offset to point to the correct row in our graphics table

    lda Score                ; Load the BCD score
    and #$F0                 ; Mask out the ones digit, keeping ONLY the tens digit (Already N * 16 due to bit position)
    sta TensDigitOffset      ; Save N*16 temporarily
    lsr                      ; N * 8
    lsr                      ; N * 4
    clc                      ; Clear Carry before addition
    adc TensDigitOffset      ; (N * 4) + (N * 16) = N * 20
    sta TensDigitOffset      ; Save the final offset to point to the correct row in our graphics table

    rts                      ; Return from Subroutine
