	include	"exec/types.i"
	include	"exec/memory.i"
	include	"exec/libraries.i"
	include	"exec/execbase.i"

	include "dos/dos.i"
	include "dos/var.i"
	include "dos/dostags.i"
	include "dos/dosextens.i"
	include "intuition/intuition.i"
	include	"hardware/cia.i"
	include	"hardware/custom.i"
	include	"hardware/intbits.i"
	include	"graphics/gfxbase.i"
	include	"graphics/videocontrol.i"
	include	"graphics/view.i"
	include	"devices/console.i"
	include	"devices/conunit.i"
	include	"libraries/lowlevel.i"
	INCLUDE	"workbench/workbench.i"
	INCLUDE	"workbench/startup.i"
	
	include "lvo/exec.i"
	include "lvo/dos.i"
	include "lvo/lowlevel.i"
	include "lvo/graphics.i"
	
    
    include "whdload.i"
    include "whdmacros.i"

    incdir "../sprites"
    incdir "../sounds"


INTERRUPTS_ON_MASK = $E038
    
	STRUCTURE	Character,0
	ULONG	previous_address
	UWORD	xpos
	UWORD	ypos
    UWORD   frame
	UWORD	active
	UWORD	extra_y_counter
	LABEL	Character_SIZEOF

	STRUCTURE	Player,0
	STRUCT      BaseCharacter1,Character_SIZEOF
	ULONG	score
	ULONG	previous_score
	ULONG	displayed_score
	UWORD	level_number
	UWORD	nb_missions_completed
	UBYTE	nb_lives
	UBYTE	one_button_control_option
	UBYTE	is_player_two
	UBYTE	pad
    LABEL   Player_SIZEOF
    
	STRUCTURE	GfxObject,0
	STRUCT      BaseCharacter2,Character_SIZEOF
	ULONG	custom_field_1
	ULONG	custom_field_2
	ULONG	custom_field_3
    LABEL   GfxObject_SIZEOF
    
	
; aliases for different kind of objects
nb_explosion_cycles = custom_field_1    
explosion_type = custom_field_2
move_index = custom_field_1
mystery_sprite = custom_field_1
plane_address = custom_field_3
    ;Exec Library Base Offsets


;graphics base

StartList = 38

Execbase  = 4



; ******************** start test defines *********************************

; ---------------debug/adjustable variables

; uncomment to mark scroll columns with letters	
;SCROLL_DEBUG

; if set skips intro, game starts immediately
;DIRECT_GAME_START

;X_SHIP_START = 57
;Y_SHIP_START = 99
;HIGHSCORES_TEST

;START_NB_LIVES = 1
;START_SCORE = 525670/10
;START_LEVEL = 6
;START_FUEL = 40
; no destructions, can bomb object forever if set
;BOMB_TEST_MODE
; uncomment to test demo mode right now
;TEST_DEMO_MODE
; speed up intro if < 60
;INTRO_TICKS_PER_SEC = 20

; temp if nonzero, then records game input, intro music doesn't play
; and when one life is lost, blitzes and a0 points to move record table
; a1 points to the end of the table
; 100 means 100 seconds of recording at least (not counting the times where
; the player (me :)) isn't pressing any direction at all.
;RECORD_INPUT_TABLE_SIZE = 100*ORIGINAL_TICKS_PER_SEC
; 1 or 2, 2 is default, 1 is to record level 1 demo moves


; ******************** end test defines *********************************

; don't change the values below, change them above to test!!

	IFD	HIGHSCORES_TEST
EXTRA_LIFE_SCORE = 1000/10
;EXTRA_LIFE_PERIOD = 7000/10
DEFAULT_HIGH_SCORE = 10000/10
	ELSE
EXTRA_LIFE_SCORE = 10000/10
;EXTRA_LIFE_PERIOD = 70000/10
DEFAULT_HIGH_SCORE = 10000/10
	ENDC
NB_HIGH_SCORES = 10
	
	IFND	START_SCORE
START_SCORE = 0
	ENDC
	IFND	START_NB_LIVES
START_NB_LIVES = 3
	ENDC
	IFND	START_LEVEL
START_LEVEL = 1
	ENDC
	IFND	START_FUEL
START_FUEL = 255
	ENDC

NB_RECORDED_MOVES = 100

; --------------- end debug/adjustable variables

; actual nb ticks (PAL)
NB_TICKS_PER_SEC = 50
; game logic ticks
ORIGINAL_TICKS_PER_SEC = 60

ARCADE_SCREEN_LAYOUT

	IFND	INTRO_TICKS_PER_SEC
INTRO_TICKS_PER_SEC = ORIGINAL_TICKS_PER_SEC
	ENDC
	

NB_BYTES_PER_LINE = 40
NB_BYTES_PER_PLAYFIELD_LINE = 30
NB_BYTES_PER_SCROLL_SCREEN_LINE = NB_BYTES_PER_PLAYFIELD_LINE*2+6
BOB_16X16_PLANE_SIZE = 64
BOB_32X16_PLANE_SIZE = 96
BOB_8X8_PLANE_SIZE = 16

NB_LINES = 256
SCREEN_PLANE_SIZE = NB_BYTES_PER_LINE*NB_LINES
SCROLL_PLANE_SIZE = NB_BYTES_PER_SCROLL_SCREEN_LINE*NB_LINES
NB_PLANES   = 3

	IFND	X_SHIP_START
X_SHIP_START = 8+X_SHIP_MIN
	ENDC
	IFND	Y_SHIP_START
Y_SHIP_START = 57
	ENDC
X_MAX=240
Y_MAX=224
X_SHIP_MIN=16	; min so we can see it fully
X_MIN=X_SHIP_MIN
X_SHIP_MAX=84
Y_SHIP_MIN=28
Y_SHIP_MAX=Y_MAX-24
Y_START_UFO = 108
X_EXHAUST_WIDTH = 10	; 10 first pixels of ship don't trigger collision

MAX_NB_BOMBS = 2
MAX_NB_SHOTS = 4
MAX_NB_EXPLOSIONS = 16
MAX_NB_SCORES = 5
MAX_NB_AIRBORNE_ENEMIES = 4

SHOT_SPEED = 3

; tile types
EMPTY_TILE = 0
STANDARD_TILE = 1
ROCKET_TILE = 2
FUEL_TILE = 3
MYSTERY_TILE = 4
BASE_TILE = 5
FILLER_TILE = -1

; positions enumerates, allow to decode tile position in a composite object
; made of 4 tiles (rocket, fuel, ...)
; we only have to provide value for left (if not set, then it's right)
; and top (if not set then it's bottom)
LEFT_CORNER_B = 6
TOP_CORNER_B = 7
LEFT_CORNER_F = 1<<LEFT_CORNER_B
TOP_CORNER_F = 1<<TOP_CORNER_B
BOTH_CORNERS_MASK = ~(LEFT_CORNER_F|TOP_CORNER_F)&$FF

; messages from update routine to display routine
MSG_NONE = 0
MSG_SHOW = 1
MSG_HIDE = 2

FILL_TILE_1 = 33
FILL_TILE_2 = FILL_TILE_1+1
GROUND_TILE = 10

PLAYER_KILL_TIMER = 16*4*3
ENEMY_KILL_TIMER = ORIGINAL_TICKS_PER_SEC*2
GAME_OVER_TIMER = ORIGINAL_TICKS_PER_SEC*3


; extra enumerate for fire (demo mode)
FIRE = 4
BOMB = 5

; direction enumerates (for replay)
RIGHT = 0
LEFT = 1<<2
UP = 2<<2
DOWN = 3<<2

; possible direction bits, clockwise
DIRB_RIGHT = 0
DIRB_DOWN = 1
DIRB_LEFT = 2
DIRB_UP = 3
; direction masks
DIRF_RIGHT = 1<<DIRB_RIGHT
DIRF_DOWN = 1<<DIRB_DOWN
DIRF_LEFT = 1<<DIRB_LEFT
DIRF_UP = 1<<DIRB_UP

; states, 4 by 4, starting by 0

STATE_PLAYING = 0
STATE_GAME_OVER = 1*4
STATE_NEXT_LEVEL = 2*4
STATE_LIFE_LOST = 3*4
STATE_INTRO_SCREEN = 4*4
STATE_GAME_START_SCREEN = 5*4

; if you change that color index, make sure
; that you also change it in the tiles json
; specific palette
;
; this color is set as 3 different values:
; - for the magenta level rectangle fill color
; - normal operation
; - fuel bar blue filler
;
; but just why would you need to change it?
DYN_COLOR = 4

; offset for enemy animations

KILL_FIRST_FRAME = 8
SCORE_FIRST_FRAME = 8

; macro to add/sub 1 every 4 moves
; let's hope that the optimizer changes add.w #-1 to subq #1
;
; < 1 or -1 to add
; < object structure index address register
; < index of target data register
; < index of work data register
EXTRA_ADD_TO_DX:MACRO
	IFLT	\1
    subq.w 	#-(\1),d\3
	ELSE
    addq.w 	#\1,d\3
	ENDC
	move.w	extra_y_counter(a\2),d\4
	addq.w	#1,d\4
	cmp.w	#4,d\4
	bne.b	.no_extra_y\@
	clr.w	d\4
	IFLT	\1
    subq.w 	#-(\1),d\3
	ELSE
    addq.w 	#\1,d\3
	ENDC
.no_extra_y\@
	move.w	d\4,extra_y_counter(a\2)
	ENDM
	

; macro requires A5 to point on custom
WAIT_BLITTER:MACRO
	TST.B	$BFE001
.wait\@
	BTST	#6,(dmaconr,a5)
	BNE.S	.wait\@
	ENDM
	
; jump table macro, used in draw and update
DEF_STATE_CASE_TABLE:MACRO
    move.w  current_state(pc),d0
    lea     .case_table(pc),a0
    move.l     (a0,d0.w),a0
    jmp (a0)
    
.case_table
    dc.l    .playing
    dc.l    .game_over
    dc.l    .next_level
    dc.l    .life_lost
    dc.l    .intro_screen
    dc.l    .game_start_screen

    ENDM
    
; write current PC value to some address
LOGPC:MACRO
     bsr    .next_\1
.next_\1
      addq.l    #6,(a7) ; skip this & next instruction
      move.l    (a7)+,$\1
      ENDM

MUL_TABLE:MACRO
mul\1_table
	rept	256
	dc.w	REPTN*\1
	endr
    ENDM
    
ADD_XY_TO_A1:MACRO
    lea mul40_table(pc),\1
    add.w   d1,d1
    lsr.w   #3,d0
    move.w  (\1,d1.w),d1
    add.w   d0,a1       ; plane address
    add.w   d1,a1       ; plane address
    ENDM


    
Start:
	; if D0 contains "WHDL"
	; A0 contains resload
	
    cmp.l   #'WHDL',D0
    bne.b   .standard
    move.l a0,_resload
    move.b  d1,_keyexit
    ;move.l  a0,a2
    ;lea	_tags(pc),a0
    ;jsr	resload_Control(a2)

    bsr load_highscores
    
    bra.b   .startup
.standard
    ; open dos library, graphics library
    move.l  $4.W,a6
    lea dosname(pc),a1
    moveq.l #0,d0
    jsr _LVOOpenLibrary(a6)
    move.l  d0,_dosbase
    lea graphicsname(pc),a1
    moveq.l #0,d0
    jsr _LVOOpenLibrary(a6)
    move.l  d0,_gfxbase

    bsr load_highscores

    ; check if "floppy" file is here
    
    move.l  _dosbase(pc),a6
    move.l   #floppy_file,d1
    move.l  #MODE_OLDFILE,d2
    jsr     _LVOOpen(a6)
    move.l  d0,d1
    beq.b   .no_floppy
    
    ; "floppy" file found
    jsr     _LVOClose(a6)
    ; wait 2 seconds for floppy drive to switch off
    move.l  #100,d1
    jsr     _LVODelay(a6)
.no_floppy
	; stop cdtv device if found, avoids that cd device
	; sends spurious interrupts
    move.l  #CMD_STOP,d0
    bsr send_cdtv_command
.startup

    lea  _custom,a5
	bsr	_detect_controller_types
	tst.b	controller_joypad_1
	; if zero, no joypad detected => one button control
	; by default
	seq	player_1+one_button_control_option
	clr.b	player_1+is_player_two
	tst.b	controller_joypad_1
	; if zero, no joypad detected => one button control
	; by default
	tst.b	controller_joypad_0
	seq	player_2+one_button_control_option
	st.b	player_2+is_player_two
	; don't shut off extra joypad buttons, reading the joypad costs cycles
	; but AFTER vblank interrupt so we can afford it.


; no multitask
    tst.l   _resload
    bne.b   .no_forbid
    move.l  _gfxbase(pc),a4
    move.l StartList(a4),gfxbase_copperlist

    move.l  4,a6
    jsr _LVOForbid(a6)
    
	sub.l	A1,A1
	jsr	_LVOFindTask(a6)		;find ourselves
	move.l	D0,A0
	move.l	#-1,pr_WindowPtr(A0)	; no more system requesters (insert volume, write protected...)

    
.no_forbid
    
;    sub.l   a1,a1
;    move.l  a4,a6
;    jsr (_LVOLoadView,a6)
;    jsr (_LVOWaitTOF,a6)
;    jsr (_LVOWaitTOF,a6)

    move.w  #STATE_INTRO_SCREEN,current_state
    
    IFND    RECORD_INPUT_TABLE_SIZE
	IFD		TEST_DEMO_MODE
    st.b    demo_mode
	ENDC
    ENDC
    
    move.w  #-1,high_score_position

    bsr init_sound
    
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    move.w  #$7FFF,(intreq,a5)

    bsr init_interrupts
	
    ; shut off dma
    move.w #$03E0,dmacon(A5)
    ; intro screen
    
    bsr	init_bitplanes_copperlist

   

;COPPER init
		
    move.l	#coplist,cop1lc(a5)
    clr.w copjmp1(a5)

;playfield init
	; will be modified later
;   move.w #$3081,diwstrt(a5)
;   move.w #$30C1,diwstop(a5)
;   move.w #$0038,ddfstrt(a5)
;   move.w #$00D0,ddfstop(a5)
	
	
	; one of ross' magic value so the screen is centered
    move.w #$30b1,diwstrt(a5)
    move.w #$3091,diwstop(a5)
    move.w #$0048,ddfstrt(a5)
    move.w #$00B8,ddfstop(a5)
BPLMOD = $A		; bplmod needs to be altered too
   
	; dual playfield
    move.w #$6600,bplcon0(a5) ; 6 bitplanes, dual playfield
    ;;clr.w bplcon2(a5)                     ; no priority (sprites behind)
    move.w #BPLMOD,bpl1mod(a5)                ; one of ross' magic value so the screen is centered

intro:
    lea _custom,a5
    clr.w bplcon1_value                   ; reset scrolling shift to 0 in copperlist
    move.w #BPLMOD,bpl2mod(a5)                ; modulo of 2nd playfield, one of ross' magic value 
	; (to be able to draw ships with a "classic" blit routine in the "SCORE" screen)
	clr.w	d0
	bsr		set_playfield_planes	; no scroll offset
	
    move.w  #$7FFF,(intena,a5)
    move.w  #$7FFF,(intreq,a5)

	bsr		load_menu_palette
	
    
    bsr clear_screen
    bsr	clear_playfield_planes
	
	;bsr	init_scroll_mask_sprite
	bsr	init_stars
	
    bsr draw_score_and_player_title

    clr.l  state_timer
    clr.w  vbl_counter

   
    bsr wait_bof
    ; init sprite, bitplane, whatever dma but not sprites
    move.w #$83C0,dmacon(a5)
    move.w #INTERRUPTS_ON_MASK,intena(a5)    ; enable level 6!!
    
    IFD DIRECT_GAME_START
	move.w	#1,cheat_keys	; enable cheat in that mode, we need to test the game
    bra.b   .restart
    ENDC

.intro_loop    
    cmp.w   #STATE_INTRO_SCREEN,current_state
    bne.b   .out_intro
    tst.b   quit_flag
    bne.b   .out
    move.l  joystick_state(pc),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .exit_intro
    btst    #JPB_BTN_BLU,d0
    beq.b   .intro_loop
	; started with blue or second button joy: 2 button control
	move.l	current_player(pc),a0
	clr.b	one_button_control_option(a0)
.exit_intro
    clr.b   demo_mode
.out_intro

	clr.b	play_start_music_message
    clr.l   state_timer
    move.w  #STATE_GAME_START_SCREEN,current_state
	clr.b	game_started_flag
    
.release
    move.l  joystick_state(pc),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .release
    btst    #JPB_BTN_BLU,d0
    bne.b   .release

    tst.b   demo_mode
    bne.b   .no_credit
    

.game_start_loop
    bsr random      ; so the enemies aren't going to do the same things at first game
    move.l  joystick_state(pc),d0
    tst.b   quit_flag
    bne.b   .out
    btst    #JPB_BTN_RED,d0
    bne.b   .wait_fire_release
    btst    #JPB_BTN_BLU,d0
    beq.b   .game_start_loop
	move.l	current_player(pc),a0
	clr.b	one_button_control_option(a0)

.wait_fire_release
    move.l  joystick_state(pc),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .wait_fire_release
    btst    #JPB_BTN_BLU,d0
    bne.b   .wait_fire_release
.no_credit
	move.b	#1,play_start_music_message
	clr.b	display_player_one_message
	
	move.w	#1,start_music_countdown	; default: no wait (demo mode / moves record)
	
	IFND		RECORD_INPUT_TABLE_SIZE
	tst.b	demo_mode
	bne.b	.wait_end_of_music
	
	move.w	#3*ORIGINAL_TICKS_PER_SEC+ORIGINAL_TICKS_PER_SEC/2,start_music_countdown
	ENDC
.wait_end_of_music
	cmp.w	#STATE_PLAYING,current_state
	bne.b	.wait_end_of_music
	
.restart    
    lea _custom,a5
    move.w  #$1FFF,(intena,a5)

	move.l	#player_1,current_player
    
    bsr init_new_play

.new_mission
	bsr	load_game_palette
	
    clr.l   state_timer

    bsr clear_screen
    
    bsr init_level
    lea _custom,a5
    move.w  #$1FFF,(intena,a5)

    bsr wait_bof
    
    bsr draw_score_and_player_title

    ; for debug
    ;;bsr draw_bounds
    
    move.w  level_number(a4),d0

    ; enable copper interrupts, mainly
    moveq.l #0,d0
    bra.b   .from_level_start
.new_life
    moveq.l #1,d0
.from_level_start
    move.b  d0,new_life_restart ; used by init player
    bsr init_enemies
    bsr init_player
	
    bsr wait_bof

	; set playfield modulo in scroll mode (wider)
	; following ross value changes to get the screen centered, I empirically
	; added $C to make display correct (that's magic, I don't know what I'm doing)
    move.w #NB_BYTES_PER_SCROLL_SCREEN_LINE-NB_BYTES_PER_LINE+BPLMOD,bpl2mod(a5)
	bsr	init_bitplanes_copperlist
    
	bsr	draw_ground	
    bsr draw_lives
	bsr	clear_mission_flags
	bsr	draw_mission_flags
	move.w	#$EE0,d0
    bsr draw_fuel_with_text
	IFND	SCROLL_DEBUG
	bsr	draw_level_map
	bsr	draw_current_level
	ENDC
	
    move.w  #STATE_PLAYING,current_state
    move.w #INTERRUPTS_ON_MASK,intena(a5)
.mainloop
    tst.b   quit_flag
    bne.b   .out
    DEF_STATE_CASE_TABLE
    
	; from mainloop: return to intro loop
.game_start_screen
.intro_screen
    bra.b   intro

.playing
    bra.b   .mainloop

.game_over
    bra.b   .mainloop
.next_level
	tst.b	do_restart_game_message
	beq.b	.mainloop
	clr.b	do_restart_game_message
	move.l	current_player(pc),a4
	; award extra life
	addq.b	#1,nb_lives(a4)
	; one more mission under the belt
	addq.w	#1,nb_missions_completed(a4)
	; restart at level 1
	clr.w	level_number(a4)
	bsr	update_level_set_data
	bsr	play_ambient_sound

    bra.b   .new_mission
.life_lost
    IFD    RECORD_INPUT_TABLE_SIZE
    lea record_input_table,a0
    move.l  record_data_pointer(pc),a1
    ; pause so debugger can grab data
    blitz
    ENDC

    tst.b   demo_mode
    beq.b   .no_demo
    ; lose one life in demo mode: return to intro
	bsr		set_game_over
	st.b	fast_game_over_flag
    bra.b   .game_over
.no_demo
	move.l	current_player(pc),a4
   
    tst.b   infinite_lives_cheat_flag
    bne.b   .new_life
    subq.b   #1,nb_lives(a4)
    bne.b   .new_life

    ; game over: check if score is high enough 
    ; to be inserted in high score table
    move.l  score(a4),d0
    lea     hiscore_table(pc),a0
	move.l	a0,$110
    moveq.w  #NB_HIGH_SCORES-1,d1
    move.w   #-1,high_score_position
.hiloop
    cmp.l  (a0)+,d0
    bcs.b   .lower
    ; higher or equal to a score
    ; shift all scores below to insert ours
    st.b    highscore_needs_saving
    move.l  a0,a1
    subq.w  #4,a0
    move.l  a0,a2   ; store for later
    tst.w   d1
    beq.b   .storesc    ; no lower scores: exit (else crash memory!)
	move.w	d1,d2
	; set a0 and a1 at the end of the score memory
	subq.w	#1,d2
	lsl.w	#2,d2
	add.w	d2,a1
	add.w	d2,a0	
    move.w  d1,d2       ; store insertion position
	addq.w	#4,a0
	addq.w	#4,a1
.hishift_loop
    move.l  -(a0),-(a1)
    dbf d2,.hishift_loop
.storesc
    move.l  d0,(a2)
    ; store the position of the highscore just obtained
    neg.w   d1
    add.w   #NB_HIGH_SCORES-1,d1
    move.w  d1,high_score_position
    bra.b   .hiout
.lower
    dbf d1,.hiloop
.hiout    
        ; high score

    ; save highscores if whdload
    tst.b   highscore_needs_saving
    beq.b   .no_save
    tst.l   _resload
    beq.b   .no_save
    tst.w   cheat_keys
    bne.b   .no_save
    bsr     save_highscores
.no_save
    ; 3 seconds
    bsr		set_game_over
    bra.b   .game_over
.out      
    ; quit
    tst.l   _resload
    beq.b   .normal_end
    
    ; quit whdload
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
.normal_end
    lea _custom,a5
    bsr     restore_interrupts
    bsr     wait_blit
    bsr     finalize_sound
	; restart CDTV device
    move.l  #CMD_START,d0
    bsr send_cdtv_command

    bsr     save_highscores

    move.l  _gfxbase,a1
    move.l  gfxbase_copperlist,StartList(a1) ; adresse du début de la liste
    move.l  gfxbase_copperlist,cop1lc(a5) ; adresse du début de la liste
    clr.w  copjmp1(a5)
    ;;move.w #$8060,dmacon(a5)        ; réinitialisation du canal DMA
    
    move.l  4.W,A6
    move.l  _gfxbase,a1
    jsr _LVOCloseLibrary(a6)
    move.l  _dosbase,a1
    jsr _LVOCloseLibrary(a6)
    
    jsr _LVOPermit(a6)                  ; Task Switching autorisé
    moveq.l #0,d0
    rts

init_bitplanes_copperlist:
    moveq #NB_PLANES-1,d4
    lea	bitplanes,a0              ; copperlist address
    move.l #screen_data,d1
    move.l #scroll_data,d2
    move.w #bplpt,d3        ; first register in d3

		; 8 bytes per plane:32 + end + bplcontrol
.mkcl:
    move.w d3,(a0)+           ; BPLxPTH
    addq.w #2,d3              ; next register
    swap d1
    move.w d1,(a0)+           ; 
    move.w d3,(a0)+           ; BPLxPTL
    addq.w #2,d3              ; next register
    swap d1
    move.w d1,(a0)+           ; 
    add.l #SCREEN_PLANE_SIZE,d1       ; next plane

    move.w d3,(a0)+           ; BPLxPTH
    addq.w #2,d3              ; next register
    swap d2
    move.w d2,(a0)+           ; 
    move.w d3,(a0)+           ; BPLxPTL
    addq.w #2,d3              ; next register
    swap d2
    move.w d2,(a0)+           ; 
    add.l #SCROLL_PLANE_SIZE,d2       ; next plane

    dbf d4,.mkcl
	rts

set_game_over:
	clr.b	fast_game_over_flag
    move.w  #STATE_GAME_OVER,current_state
    move.l  #GAME_OVER_TIMER,state_timer
	rts

load_menu_palette	
    lea menu_palette,a0
	move.w	#8,d0		; 8 colors
	bsr		load_palette	
	move.w	#$FF0,yellow_color
	move.w	#$FFF,white_color	
	rts
	
load_game_palette
    lea objects_palette,a0
	move.w	#8,d0		; 8 colors
	bsr		load_palette		
	move.w	#$CCD,white_color
	move.w	#$EE0,yellow_color
	rts

; < A0: palette
; < D0: nb colors

load_palette
    lea _custom+color,a1
	move.w	d0,current_nb_colors
	move.l	a0,current_palette
	move.w	(DYN_COLOR*2,a0),dyn_color_reset
    subq.w	#1,d0
	
.copy
    move.w  (a0)+,(a1)+
    dbf d0,.copy
	rts
	
wait_bof
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#260<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#260<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts    
    
clear_debug_screen
    movem.l d0-d1/a1,-(a7)
    lea	screen_data+SCREEN_PLANE_SIZE*3,a1 
    move.w  #NB_LINES-1,d1
.c0
    move.w  #NB_BYTES_PER_PLAYFIELD_LINE/4-1,d0
.cl
    clr.l   (a1)+
    dbf d0,.cl
    add.w   #NB_BYTES_PER_LINE-NB_BYTES_PER_PLAYFIELD_LINE,a1
    dbf d1,.c0
    movem.l (a7)+,d0-d1/a1
    rts
    
clear_screen
    lea screen_data,a1
    moveq.l #NB_PLANES-1,d0
.cp
    move.w  #(NB_BYTES_PER_LINE*NB_LINES)/4-1,d1
    move.l  a1,a2
.cl
    clr.l   (a2)+
    dbf d1,.cl
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d0,.cp
    rts


clear_playfield_planes
    lea screen_data,a1
	move.w	#NB_PLANES-1,d0
.loop
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
	dbf		d0,.loop
	
    lea scroll_data,a1
	move.w	#NB_PLANES-1,d0
.loop2
    bsr clear_scroll_plane
    add.w   #SCROLL_PLANE_SIZE,a1
	dbf		d0,.loop2
    rts
	
; < A1: plane start
clear_playfield_plane
    movem.l d0/a1,-(a7)
    move.w #SCREEN_PLANE_SIZE/4-1,d0
.cl
    clr.l   (a1)+
    dbf d0,.cl
    movem.l (a7)+,d0/a1
    rts

; < A1: plane start
clear_scroll_plane
    movem.l d0/a1,-(a7)
    move.w #SCROLL_PLANE_SIZE/4-1,d0
.cl
    clr.l   (a1)+
    dbf d0,.cl
    movem.l (a7)+,d0/a1
    rts

update_level_set_data	
	move.l	current_player(pc),a4
	move.w	#10,d1
	move.w	nb_missions_completed(a4),d0
	beq.b	.store
	subq.w	#2,d1
	cmp.w	#1,d0
	beq.b	.store
	subq.w	#2,d1
.store
	move.b	d1,fuel_depletion_timer
	; continue for level itself (first level)
update_level_data:
	move.l	current_player(pc),a4
	clr.l	base_dest_address
	clr.w	base_frame_subcounter
	clr.w	base_frame_counter
	move.w	level_number(a4),d0
	beq.b	.rockets_fly
	cmp.w	#3,d0
.rockets_fly
	seq		rockets_fly_flag
	
	; stars show/hide
	lea	.stars_active_table(pc),a0
	move.b	(a0,d0.w),d1
	cmp.b	stars_on(pc),d1
	beq.b	.no_change
	; change when ceiling tile reaches the first position
	; or .. whatever value looks good...
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE*4,stars_state_change_timer
.no_change
	move.b	d1,stars_next_state
	add.w	d0,d0
	add.w	d0,d0
	lea	.hitbox_margin_data(pc),a0
	move.w	(a0,d0.w),d1
	move.w	d1,enemy_hitbox_x_margin
	neg.w	d1
	add.w	d1,d1
	add.w	#16,d1	; len = 16-2*margin
	move.w	d1,enemy_hitbox_x_len
	move.w	(2,a0,d0.w),d1
	move.w	d1,enemy_hitbox_y_margin
	neg.w	d1
	add.w	d1,d1
	add.w	#16,d1	; len = 16-2*margin
	move.w	d1,enemy_hitbox_y_len
	rts
	
.stars_active_table:
	dc.b	1
	dc.b	0	; level 2 - caverns
	dc.b	1	; level 3
	dc.b	1	; level 4
	dc.b	0	; level 5 - tunnels
	dc.b	1	; level 6
	even
; x/y hitbox margin on 16x16 enemies
.hitbox_margin_data
	dc.w	4,0	; rockets
	dc.w	2,4	; ufos
	dc.w	4,3	; fireballs
	dc.w	4,0	; rockets
	dc.w	0,0	; no enemies
	dc.w	0,0	; no enemies
init_new_play:
	move.l	current_player(pc),a4
	clr.w	nb_missions_completed(a4)
    move.b  #START_NB_LIVES,nb_lives(a4)

    clr.b   new_life_restart
    clr.b   extra_life_awarded
    clr.b    music_played
    move.l  #EXTRA_LIFE_SCORE,score_to_track
    move.w  #START_LEVEL-1,level_number(a4)
	IFD		DIRECT_GAME_START
	bsr		play_ambient_sound
	ENDC
 
	bsr		update_level_set_data
	
    ; global init at game start
	
	tst.b	demo_mode
	beq.b	.no_demo
	; toggle demo
	move.w	#START_LEVEL-1,level_number(a4)
	btst	#0,d0
	lea		demo_moves_1,a0
	lea		demo_moves_1_end,a1
.rset
	move.l	a0,record_data_pointer
	move.l	a1,record_data_end

	
.no_demo
    move.l  #START_SCORE,score(a4)
    clr.l   previous_score(a4)
    clr.l   displayed_score(a4)
    rts
    
init_level: 
	clr.l	state_timer

 
    rts

; clear planes used for score (score hidden in acts)
clear_scores
    lea	screen_data+SCREEN_PLANE_SIZE*1,a1
    move.w  #232,d0
    move.w  #16,d1
    move.w  #8,d2
    move.w  #4,d3
.loop
    lea	screen_data+SCREEN_PLANE_SIZE*1,a1
    bsr clear_plane_any_blitter
    add.w	#SCREEN_PLANE_SIZE,a1
    bsr clear_plane_any_cpu
    add.w   #16,d1
    dbf d3,.loop
    rts
    
draw_score_and_player_title
	moveq	#1,d0
	bsr	draw_player_title
	bsr	draw_score
	rts
	
; draw score with highscore title and extra 0
draw_score:
	move.l	current_player(pc),a4
	IFND	ARCADE_SCREEN_LAYOUT
	; legacy compact score display at the bottom
    lea p1_string(pc),a0
    move.w  #24,d0
    move.w  #Y_MAX-8,d1
    move.w  white_color(pc),d2
    bsr write_color_string

    lea high_score_string(pc),a0
    move.w  #136,d0
    bsr write_color_string
	
	move.w	yellow_color(pc),d2
    lea score_string(pc),a0
    move.w  #48,d0
    bsr write_color_string

    ; extra 0
    lea score_string(pc),a0
    move.w  #128+24,d0
    bsr write_color_string

    move.l  score(a4),d2
    bsr     draw_current_score


    move.l  high_score(a4),d2
    bsr     draw_high_score
    
	rts
	
; < D2 score
; trashes D0-D3
draw_current_score:
    move.w  #56,d0
    move.w  #Y_MAX-8,d1
    move.w  #6,d3
	move.w	yellow_color(pc),d4
    bra write_color_decimal_number
; < D2: highscore
draw_high_score
    move.w  #120+40,d0
    move.w  #Y_MAX-8,d1
    move.w  #6,d3
    move.w  yellow_color(pc),d4    
    bra write_color_decimal_number	
	

    ELSE

; arcade layout

    lea high_score_string(pc),a0
    move.w  #72+16,d0
    bsr write_color_string
	
	move.w	yellow_color(pc),d2
    lea score_string(pc),a0
    move.w  #16,d0
    move.w  #-16,d1
    bsr write_color_string

    ; extra 0
    lea score_string(pc),a0
    move.w  #80+16,d0
    bsr write_color_string

    bsr     draw_current_score

    move.l  high_score(pc),d2
    bra     draw_high_score    

; trashes D0-D3
draw_current_score:
	move.l	current_player(pc),a4
    move.l  score(a4),d2

    move.w  #16,d0
    move.w  #-16,d1
    move.w  #6,d3
	move.w	yellow_color(pc),d4
    bra write_color_decimal_number
; < D2: highscore
draw_high_score
    move.w  #80+16,d0
    move.w  #-16,d1
    move.w  #6,d3
    move.w  yellow_color(pc),d4    
    bra write_color_decimal_number	
	
    ENDC

; < D0: 0 clear, 1 draw

draw_player_title
	move.b	d0,d2
    lea p1_string(pc),a0
    move.w  #24+16,d0
	
	tst.b	is_player_two(a4)
	beq.b	.player_1
    lea p2_string(pc),a0
    move.w  #108+16,d0		; TODO	
.player_1
	tst.b	d2
	bne.b	.draw
	lea	pc_string(pc),a0	; erase
.draw
    move.w  #-24,d1
    move.w  white_color(pc),d2
    bra write_blanked_color_string

	
	
stars_palette_size = (end_stars_palette-stars_palette)
NB_STAR_LINES = 53
star_copperlist_size = (end_stars_sprites_copperlist-stars_sprites_copperlist)/NB_STAR_LINES

; remove stars (levels 2 and 5, where there's a ceiling)
no_stars
	lea	stars_sprites_copperlist,a1
	move.w	#NB_STAR_LINES-1,d7
.loop
	; D0 is the sprite pos/control word
	clr.w	18-8(a1)		; change offset if struct changes
	clr.w	22-8(a1)		; change offset if struct changes

	add.w	#star_copperlist_size,a1
	dbf		d7,.loop
	rts

	
show_stars
	lea	stars_sprites_copperlist,a1
	lea	stars_palette(pc),a2
	
	move.w	#NB_STAR_LINES-1,d7
	clr.w	d2
.loop
	; pick random x

	
.rx
	bsr		random
	btst	#15,d0
	beq.b	.skip_pos	; 50% chance of displaying a star
	and.w	#$FF,d0
	cmp.w	#X_MAX-X_SHIP_MIN,d0
	bcc.b	.rx
	add.w	#X_SHIP_MIN+6*8,d0	; add 48 offset because of screen centering
	move.w	#100,d1	; doesn't matter
	bsr		store_sprite_pos
	; store color
	move.w	(a2,d2.w),(14-8,a1)		; change offset if struct changes
	addq.w	#2,d2
	cmp.w	#stars_palette_size,d2
	bne.b	.write_pos
	clr.w	d2
.write_pos

	; D0 is the sprite pos/control word
	move.w	d0,18-8(a1)		; change offset if struct changes
	swap	d0
	move.w	d0,22-8(a1)		; change offset if struct changes

	add.w	#star_copperlist_size,a1
	dbf		d7,.loop
	rts
.skip_pos
	clr.l	d0
	bra.b	.write_pos
	
init_stars
	move.w	#-1,stars_state_change_timer
	st.b	stars_on
	bra.b	show_stars
	
update_stars
	tst.w	stars_state_change_timer
	bmi.b	.update
	bne.b	.decrease
	; set stars state
	clr.w	stars_timer
	move.b	stars_next_state(pc),stars_on
	; change ambient sound loop at this moment too
	bsr		play_ambient_sound
.decrease
	subq.w	#1,stars_state_change_timer
.update
	move.w	stars_timer(pc),d0
	addq.w	#1,d0
	cmp.w	#ORIGINAL_TICKS_PER_SEC,d0
	bne.b	.nowrap
	
	tst.b	stars_on
	bne.b	.show
	bsr.b	no_stars
	clr.w	d0
	bra.b	.nowrap
.show
	bsr		show_stars
	clr.w	d0
.nowrap
	move.w	d0,stars_timer
	rts
	
store_sprite_copperlist    
    move.w  d0,(6,a0)
    swap    d0
    move.w  d0,(2,a0)
    rts

		
init_enemies
    ; empty pools
	; just in case remove all pending objects
	lea	bombs,a4
	move.w	#MAX_NB_BOMBS-1,d7
	bsr	free_all_slots
	lea	shots,a4
	move.w	#MAX_NB_SHOTS-1,d7
	bsr	free_all_slots
	lea	explosions,a4
	move.w	#MAX_NB_EXPLOSIONS-1,d7
	bsr	free_all_slots
	lea	mystery_scores,a4
	move.w	#MAX_NB_SCORES-1,d7
	bsr	free_all_slots	
	
	bsr	free_enemy_slots

	clr.b	enemy_launch_cyclic_counter
    
	; clear rocket heights
	lea	screen_ground_rocket_table,a0
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE-1,d0
.c
	clr.w	(a0)+
	dbf	d0,.c
	
    rts


init_player:
	lea	bombs,a4
	move.w	#MAX_NB_BOMBS-1,d7
	bsr	free_all_slots

	move.w	#-1,mission_completed_countdown
    clr.w   death_frame_offset
	clr.w	fireball_sound_timer
	move.w	#1,low_fuel_sound_timer
	move.w	#START_FUEL,fuel
    tst.b   new_life_restart
    bne.b   .no_clear
.no_clear
	move.l	current_player(pc),a0
    move.w	level_number(a0),d0
	add.w	d0,d0
	add.w	d0,d0
	lea		level_tiles(pc),a0
	move.l	(a0,d0.w),map_pointer
	move.w	#15,scroll_shift

	move.b	fuel_depletion_timer(pc),fuel_depetion_current_timer

	clr.w	delayed_fx_countdown
	clr.w	scroll_offset
	clr.w	playfield_palette_index
	clr.w	d0
	bsr		next_playfield_palette

    move.l	current_player(pc),a0

    clr.l   previous_address(a0)   ; no previous position
	clr.w	extra_y_counter(a0)
	

    move.w  #X_SHIP_START,xpos(a0)
	move.w	#Y_SHIP_START,ypos(a0)
    
	
    clr.b	alive_timer
    move.w  #0,frame(a0)

    
    move.w  #ORIGINAL_TICKS_PER_SEC,D0   
    tst.b   music_played
    bne.b   .played
    st.b    music_played


    IFD    RECORD_INPUT_TABLE_SIZE
    ELSE
    IFND     DIRECT_GAME_START
    tst.b   demo_mode
    beq.b   .no_demo
    ENDC

.no_demo
    ENDC
.played
    IFD    RECORD_INPUT_TABLE_SIZE
    move.l  #record_input_table,record_data_pointer ; start of table
    move.l  #-1,prev_record_joystick_state	; impossible previous value, force record
    clr.l   previous_random
    ENDC

    clr.w   record_input_clock                      ; start of time

	clr.b	next_level_flag
    move.w  #-1,player_killed_timer
 


    
    rts
    	    

    
DEBUG_X = 16     ; 232+8
DEBUG_Y = 140


        
draw_debug
    move.l current_player(pc),a2
    move.w  #DEBUG_X,d0
    move.w  #DEBUG_Y,d1
    lea	screen_data+SCREEN_PLANE_SIZE,a1 
    lea .px(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w xpos(a2),d2
    move.w  #5,d3
    bsr write_decimal_number
	
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .py(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w ypos(a2),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0
	
	IFEQ	1
	lea	shots,a2
    lea .sx(pc),a0
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w xpos(a2),d2
    move.w  #5,d3
    bsr write_decimal_number
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .sy(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w ypos(a2),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0

	lea	bombs,a2
    lea .bx(pc),a0
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w xpos(a2),d2
    move.w  #5,d3
    bsr write_decimal_number
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .by(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w ypos(a2),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0
    
    ;;
	; count airborne slots
	lea	airborne_enemies,a4
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	clr.l	d2
.loop
	tst.b	active(a4)
	beq.b	.next
	addq.l	#1,d2
	
.next
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
  
    lea .nbe(pc),a0
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    move.w  #2,d3
    bsr write_decimal_number	
    ;;
    ;;
	ENDC
    lea .sshift(pc),a0
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    move.w  #3,d3
	move.w	scroll_shift(pc),d2
    bsr write_decimal_number	

	; show airborne enemies info
	lea	airborne_enemies,a4
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	clr.l	d2
.loop
	tst.b	active(a4)
	bne.b	.out
	
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	; erase data
    lea .ex(pc),a0
	move.w	xpos(a4),d2
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    lea	.na(pc),a0
    bsr write_string	
    lea .ey(pc),a0
	move.w	ypos(a4),d2
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    lea	.na(pc),a0
    bsr write_string	
	
	bra.b	.no_nmes
.out
    lea .ex(pc),a0
	move.w	xpos(a4),d2
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    move.w  #3,d3
    bsr write_decimal_number	
    lea .ey(pc),a0
	move.w	ypos(a4),d2
    add.w  #8,d1
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    move.w  #3,d3
    bsr write_decimal_number	
.no_nmes


    rts
.nbe
		dc.b	"NMES ",0
.px
        dc.b    "PX ",0
.py
        dc.b    "PY ",0
.sx
		dc.b	"SX ",0
.sy
		dc.b	"SY ",0
.bx
        dc.b    "BX ",0
.by
        dc.b    "BY ",0
.ex
        dc.b    "EX ",0
.ey
        dc.b    "EY ",0
.na
		dc.b	"N/A",0
.sshift
		dc.b	"SSHIFT",0
        even

     
draw_all
    DEF_STATE_CASE_TABLE

; draw intro screen
.intro_screen
    bra.b   draw_intro_screen
; draw game start screen
    
.game_start_screen
    tst.l   state_timer
    beq.b   draw_start_screen
	tst.b	demo_mode
	bne.b	.wait_for_start
	
	tst.b	game_started_flag
	beq.b	.wait_for_start
	tst.b	display_player_one_message
	beq.b	.no_play
	clr.b	display_player_one_message
    bsr clear_screen
    bsr	clear_playfield_planes
	
	; set game palette
	
	bsr		load_game_palette
	
	lea	player_one_string(pc),a0
	move.w	#72,d0
	move.w	#160-24,d1
    move.w  white_color(pc),d2
    bsr write_color_string
	
	; artifically display all 3 lives at start
	; (player is not initialized yet)
	
	move.b	#START_NB_LIVES+1,nb_lives(a4)
	bsr	draw_lives
	clr.w	nb_missions_completed(a4)
	bsr	draw_mission_flags
	; real number of remaining lives (plus the one in play)
.no_play
	; controller option (amiga specific)
	lea	one_button_control_text(pc),a0
	tst.b	one_button_control_option(a4)
	bne.b	.select
	lea	two_button_control_text(pc),a0	
.select
	move.w	#32,d0
	move.w	#160,d1
    move.w  white_color(pc),d2
    bsr write_blanked_color_string

.wait_for_start
    rts
    
.life_lost
	rts
	
.next_level
	; should be 0 but it's 1 for some reason
	; it doesn't matter, just draw if <= 2 and that
	; will work
	cmp.l	#2,state_timer
	bcs	draw_mission_completed
    rts
PLAYER_ONE_X = 72
PLAYER_ONE_Y = 102-14

    
.game_over
	tst.b	fast_game_over_flag
    bne.b   .draw_complete		; don't draw anything (ESC pressed, demo ended)

    cmp.l   #GAME_OVER_TIMER,state_timer
    bne.b   .draw_complete
    bsr clear_playfield_planes
	; re-set stars if was off
	bsr		init_stars
	; color0: force to black
	move.w	#$0,colors+2
    move.w  #72,d0
    move.w  #136,d1
    move.w  white_color(pc),d2
    lea player_one_string(pc),a0
    bsr write_color_string
    move.w  #72,d0
    add.w   #16,d1
    lea game_over_string(pc),a0
    bsr write_color_string
    bra.b   .draw_complete
	
.playing
	; main game draw
	; draw/update scrolling must absolutely
	; be done first thing, else we can experience
	; a lot of scrolling flicker
	;
	; not so important on explosions and score
	bsr	draw_scrolling_tiles

	tst.b	next_level_flag
	beq.b	.same_level
	; level change, remove remaining flying enemies
	move.l	current_player(pc),a4
	move.w	level_number(a4),d0
	bne.b	.no_first
	moveq.w	#6,d0
.no_first
	subq.w	#1,d0		; erase previous level enemies
	bsr	erase_enemies
	bsr	free_enemy_slots
	; draw current progress (top screen map)
	bsr		draw_current_level
	clr.b	next_level_flag
.same_level
	bsr	erase_bombs
	
	; erase stuff depending on the level
	move.l	current_player(pc),a4
	move.w	level_number(a4),d0

	bsr	erase_enemies
	bsr	erase_explosions
    bsr draw_player
	bsr	draw_bombs
	bsr	draw_shots
	bsr	draw_explosions
	
	move.l	current_player(pc),a4

	move.w	level_number(a4),d0
	add.w	d0,d0
	add.w	d0,d0
	lea		draw_table(pc),a0
	move.l	(a0,d0.w),a0
	jsr		(a0)

	move.b	draw_player_title_message(pc),d0
	beq.b	.nothing
	cmp.b	#1,d0
	seq		d0
	clr.b	draw_player_title_message
	bsr	draw_player_title
.nothing
	bsr	draw_score
	tst.b	update_fuel_message
	beq.b	.no_fuel_draw
	bsr		draw_fuel
	clr.b	update_fuel_message
.no_fuel_draw
.skip_draw
	IFD	SCROLL_DEBUG
	bsr	draw_scroll_debug
	ENDC
	
.after_draw
        
    ; timer not running, animate

    cmp.w   #MSG_SHOW,extra_life_message
    bne.b   .no_extra_life
    clr.w   extra_life_message
    bsr     draw_last_life
.no_extra_life

	move.l	current_player(pc),a4
    ; score
    lea	screen_data+SCREEN_PLANE_SIZE*3,a1  ; white
    
    move.l  score(a4),d0
    move.l  displayed_score(a4),d1
    cmp.l   d0,d1
    beq.b   .no_score_update
    
    move.l  d0,displayed_score(a4)
	
    bsr draw_current_score
    
    ; handle highscore in draw routine eek
    move.l  high_score(pc),d4
    cmp.l   score(a4),d4
    bcc.b   .no_score_update
    
    move.l  score(a4),high_score
    bsr draw_high_score
.no_score_update
.draw_complete
    rts

stop_sounds

    lea _custom,a6
    clr.b   music_playing
    bra _mt_end

; < D0: level number
erase_enemies:
	add.w	d0,d0
	add.w	d0,d0
	lea		erase_table(pc),a0
	move.l	(a0,d0.w),a0
	jmp		(a0)
	
erase_table
	dc.l	erase_flying_rockets
	dc.l	erase_ufos
	dc.l	erase_fireballs
	dc.l	erase_flying_rockets
	dc.l	nothing
	dc.l	nothing
	
draw_table
	dc.l	draw_flying_rockets
	dc.l	draw_ufos
	dc.l	draw_fireballs
	dc.l	draw_flying_rockets
	dc.l	nothing
	dc.l	draw_base

nothing
	rts
	
; < A4: pointer on cell to update in screen rocket scroll list
; < A5: pointer on column to update in screen scroll tilemap
; < A6: map pointer
; < D0: x offset in bytes
; > A6: new map pointer
draw_tiles:
	movem.l	d0-d7/A0-A5,-(a7)
	lea		tiles,a0
	clr.w	(a4)	; zero coord: no rocket in the column by default
	move.w	d0,d5	; save X-offset for later on
	IFD		ARCADE_SCREEN_LAYOUT
	lea		scroll_data+NB_BYTES_PER_SCROLL_SCREEN_LINE*40,a1	; 2nd playfield
	ELSE
	lea		scroll_data+NB_BYTES_PER_SCROLL_SCREEN_LINE*16,a1	; 2nd playfield
	ENDC
	add.w	d5,a1		; add x offset

	move.w	#16,d6	; current y	

	
	move.w	#NB_BYTES_PER_SCROLL_SCREEN_LINE*8,d4	; we'll need this value
	move.w	(a6)+,d2	; number of vertical tiles to draw - upper part
	beq.b	.lower
	bpl.b	.okay
	; level/game ending (-1/-2)
	; should be detected outside this routine
	blitz
.okay	
	; upper part
	subq.w	#1,d2
	move.w	(a6)+,d1	; y start	
	add.w	d6,d1

	move.l	a1,a2						; first dest plane
	lea		(SCROLL_PLANE_SIZE,a1),a3	; second dest plane
	
	; fill upper part
	move.w	d1,d7
	bsr.b		.fill

.upperloop:
	move.w	(a6)+,d0	; tile id

	bsr		.copy_tile

	dbf		d2,.upperloop	
	; one tile drawn
	; lower part
.lower
	move.w	(a6)+,d2		; number of vertical tiles to draw
	beq.b	.out	; not really possible, though
	subq.w	#1,d2
	
	move.w	(a6)+,d1	; y start
	add.w	#16,d1		; add offset
	; clear the space above ground
	move.l	a1,a2
	lea		(SCROLL_PLANE_SIZE,a1),a3
.clear
	cmp.w	d1,d6
	beq.b	.no_clear	; reached
	REPT	8
	clr.b	(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a3)
	clr.b	(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a2)
	ENDR
	clr.b	(a5)
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE,a5
	addq.w	#8,d6
	add.w	d4,a1
	add.w	d4,a2
	add.w	d4,a3
	bra.b	.clear

.no_clear
	
.lowerloop:
	move.w	(a6)+,d0	; tile id
	tst.b	rockets_fly_flag
	beq.b	.no_rocket
	; check if not rocket top/left
	cmp.b	#ROCKET_TOP_LEFT_TILEID,d0
	bne.b	.no_rocket
	; store rocket position
	move.w	d6,(a4)
.no_rocket
	; check if not rocket top/left
	cmp.b	#BASE_TOP_LEFT_TILEID,d0
	bne.b	.no_base
	; store base X/Y position
	move.l	a1,base_dest_address
	; how many pixels before hiding and not blitting
	; the base?
	move.w	#(NB_BYTES_PER_PLAYFIELD_LINE-2)*8,base_x_pos
.no_base
	bsr		.copy_tile

	dbf		d2,.lowerloop
	move.w	#Y_MAX-8,d7
	bsr.b		.fill


.out
	movem.l	(a7)+,d0-d7/A0-a5
	rts
	
; < D7: y max

.fill
	; now fill the rest with filler tile or nothing
	move.l	a0,-(a7)
	move.l	current_player(pc),a0
	cmp.w	#3,level_number(a0)
	movem.l	(a7)+,a0
	bcc.b	.fill_with_tile
	; empty
	cmp.w	d7,d6
	bcc.b	.fend
	REPT	8
	st.b	(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a3)
	clr.b	(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a2)
	ENDR
	st.b	(a5)
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE,a5
	addq.w	#8,d6
	add.w	d4,a1
	add.w	d4,a2
	add.w	d4,a3
	bra.b	.fill
.fend
	rts
.fill_with_tile
	move.w	a1,d0
	btst	#0,d0
	beq.b	.ft1
	move.w	#FILL_TILE_2,d0
	bra.b	.fill_with_tile_loop
.ft1
	move.w	#FILL_TILE_1,d0

.fill_with_tile_loop
	cmp.w	d7,d6
	bcc.b	.fend
	bsr		.copy_tile
	bra.b	.fill_with_tile_loop
	
.copy_tile
	move.l	a0,-(a7)
	lsl.w	#4,d0
	lea		(a0,d0.w),a0	; graphics
	lsr.w	#4,d0
	; cpu copy
	move.l	a1,a2						; first dest plane
	lea		(SCROLL_PLANE_SIZE,a1),a3	; second dest plane

	; copy both planes
	REPT	8
	move.b	(8,a0),(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a3)
	move.b	(a0)+,(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a2)
	ENDR
	move.b	d0,(a5)
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE,a5

	add.w	d4,a1
	add.w	d4,a2
	add.w	d4,a3
	addq.w	#8,d6	; advance y
	move.l	(a7)+,a0
	rts
	
draw_base
	move.l	base_dest_address(pc),d0
	beq.b	.no_draw
	move.l	d0,a1
	move.l	d0,.previous
	lea		base_table(pc),a0
	move.w	base_frame_counter(pc),d0
	move.l	(a0,d0.w),a0
	bsr		blit_16x16_scroll_object
	rts
.no_draw
	move.l	.previous(pc),d0
	beq.b	.out
	move.l	d0,a1
	bsr		.clear_object
	move.l	d0,a1
	sub.w	#NB_BYTES_PER_PLAYFIELD_LINE,a1
	cmp.l	#scroll_data,a1
	bcc.b	.do
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE*2,a1
.do
	bsr		.clear_object
.out
	rts
.clear_object
	moveq.w	#1,d1
.cloop
	REPT	16
	;clr.b	(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE,a1)
	;clr.b	(REPTN*NB_BYTES_PER_SCROLL_SCREEN_LINE+1,a1)
	ENDR
	add.w	#SCROLL_PLANE_SIZE,a1
	dbf	d1,.cloop
	rts
.previous
	dc.l	0



; < D0: fuel: positive or negative
add_to_fuel:
	move.l	d1,-(a7)
	move.w	fuel(pc),d1
	add.w	d0,d1
	bmi.b	.skip	; if negative no more fuel
	cmp.w	#$100,d1
	bcs.b	.ok
	move.w	#$FF,d1	; clip to 255
.ok
	move.w	d1,fuel
	st.b	update_fuel_message
.skip
	move.l	(a7)+,d1
	rts
	
; < D0: score (/10)
; trashes: nothing

add_to_score:
	movem.l	d1/a4,-(a7)
	tst.b	demo_mode
	bne.b	.below
	move.l	current_player(pc),a4
    move.l  score(a4),previous_score(a4)

    add.l   d0,score(a4)
    move.l  score_to_track(pc),d1
    ; was below, check new score
    cmp.l   score(a4),d1    ; is current score above xtra life score
    bcc.b   .below        ; not yet
    ; above next extra life score
    cmp.l   previous_score(a4),d1
    bcs.b   .below
    
	
    move.w  #MSG_SHOW,extra_life_message
    addq.b   #1,nb_lives(a4)
.below
	movem.l	(a7)+,d1/a4
    rts
    
random:
    move.l  previous_random(pc),d0
	;;; EAB simple random generator
    ; thanks meynaf
    mulu #$a57b,d0
    addi.l #$bb40e62d,d0
    rol.l #6,d0
	tst.b	random_stop_flag
	bne.b	.same
    move.l  d0,previous_random
.same
    rts

    
draw_start_screen
    bsr clear_screen
    bsr	clear_playfield_planes
    lea menu_palette,a0
	move.w	#8,d0		; 8 colors
	bsr		load_palette		
	bsr		draw_score_and_player_title
	
    lea .psb_string(pc),a0
    move.w  #48,d0
    move.w  #96,d1
    move.w  yellow_color(pc),d2
    bsr write_color_string
    
    lea .opo_string(pc),a0
    move.w  #48,d0
    move.w  #116,d1
    move.w  white_color(pc),d2
	
    bsr write_color_string
    lea .bp1_string(pc),a0
    move.w  #16,d0
    move.w  #148,d1
    move.w  #$0f40,d2
    bsr write_color_string

    
    rts
    
.psb_string
    dc.b    "PUSH START BUTTON",0
.opo_string:
    dc.b    "ONE OR TWO PLAYERS",0
.bp1_string
    dc.b    "BONUS JET  FOR 10000 PTS",0

    even
    
    
INTRO_Y_SHIFT=68
ENEMY_Y_SPACING = 24

draw_intro_screen
    tst.b   intro_state_change
    beq.b   .no_change
    clr.b   intro_state_change
    move.b  intro_step(pc),d0
    cmp.b   #1,d0
    beq.b   .init1
    cmp.b   #2,d0
    beq.b   .init2
    cmp.b   #3,d0
    beq.b   .init3
    bra.b   .no_change  ; should not be reached
.init1    
    bsr clear_screen
	
	bsr	load_menu_palette
	
    bsr draw_score_and_player_title
    

        
    lea    .play(pc),a0
    move.w  #96,d0
    move.w  #48-24,d1
    move.w  #$ff0,d2
    bsr write_color_string    
    bsr draw_title
    lea    .how_far_1(pc),a0
    move.w  #24,d0
    move.w  #136-24,d1
    move.w  #$0f40,d2
    bsr write_color_string 
	
    lea    .how_far_2(pc),a0
    move.w  #24,d0
    move.w  #136,d1
    bsr write_color_string 
	
    ; first update, don't draw enemies or anything as they're not initialized
    ; (draw routine is called first)
    rts
.init2
    bsr clear_screen
    bsr draw_score_and_player_title
    ; high scores
    
    move.w  #40,d0
    move.w  #8,d1
    lea .score_ranking(pc),a0
    move.w  #$0F0,d2
    bsr     write_color_string
    
    ; write high scores & position
    move.w  #24,D1
    lea     .color_table(pc),a2
    lea     .pos_table(pc),a3
    lea     hiscore_table(pc),a4
    move.w  #9,d5
.ws
    move.w  (a2)+,d2    ; color
    move.l  (a3)+,a0
    move.w  #32,d0
    bsr write_color_string
    
    move.w  d2,d4
    move.w  #64,d0
    move.l  (a4)+,d2
    move.w  #7,d3
    bsr write_color_decimal_number
    
    move.w  d4,d2
    move.w  #120,d0
    lea .pts(pc),a0
    bsr write_color_string
    
    add.w   #16,d1
    dbf d5,.ws
    
    bra draw_copyright
    
.init3
	
    bsr clear_screen
	bsr	draw_score_and_player_title
    ; characters
    move.w  #56,d0
    move.w  #56-24,d1
    lea     .score_table(pc),a0
    move.w  #$FF0,d2
    bsr write_color_string

	; load playfield palette, almost same as menu palette, just
	; one color difference to be able to display enemies with
	; accurate palette, since all enemies require 9 colors

    lea objects_palette,a0
	move.w	#8,d0		; 8 colors
	bsr		load_palette	

	lea	objects_palette(pc),a0
    lea _custom+color+16,a1	; second playfield
    moveq.w	#7,d0
.copy
    move.w  (a0)+,(a1)+
    dbf d0,.copy
	; change one color (mystery ship)
	move.w	#$00E,_custom+color+16+10
    
	lea	enemies_1,a0
	lea	screen_data,a1
	move.w	#2,d3
	move.w	#64,d0
	IFD		ARCADE_SCREEN_LAYOUT
	move.w	#74,d1
	ELSE
	move.w	#50,d1
	ENDC
.draw1
	
    movem.l d0-d6/a0-a5,-(a7)
    lea $DFF000,A5
	moveq.l #-1,d3
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #60,d4      ; 16 pixels height
    bsr blit_plane_any_internal
    movem.l (a7)+,d0-d6/a0-a5
	add.w	#4*60,a0
	add.w	#SCREEN_PLANE_SIZE,a1
	dbf		d3,.draw1
	
	lea	enemies_2,a0
	lea	scroll_data,a1
	move.w	#2,d3
	move.w	#64,d0
	move.w	#64,d0
	IFD		ARCADE_SCREEN_LAYOUT
	move.w	#146,d1
	ELSE
	move.w	#146-24,d1
	ENDC
.draw2
	
    movem.l d0-d6/a0-a5,-(a7)
    lea $DFF000,A5
	moveq.l #-1,d3
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #64,d4      ; 16 pixels height
    bsr blit_plane_any_internal
    movem.l (a7)+,d0-d6/a0-a5
	add.w	#4*64,a0
	add.w	#SCROLL_PLANE_SIZE,a1
	dbf		d3,.draw2
	
    bra draw_copyright
    
    
.no_change
    ; just draw single cattle
    move.b  intro_step(pc),d0
    cmp.b   #1,d0
    bne.b   .no_part1

	nop
    
    ; paint is done in the update part
	; the draw part misses bits because it's updated at 50 Hz
	; where the update part is updated at 60 Hz to follow original
	; game speed
    
.no_part1
    
    cmp.b   #3,d0
    bne.b   .no_part3
	
    lea draw_char_command(pc),a1
    tst.b   (5,a1)
    beq.b   .nothing_to_print

    lea .onechar(pc),a0
    move.w  (a1)+,d0
    move.w  (a1)+,d1
    move.b  (a1)+,(a0)
    clr.b   (a1)    ; ack
    move.w  white_color(pc),d2
    bsr write_color_string
.nothing_to_print
    rts
    
.no_part3
; part 2 highscores
    tst.w   high_score_position
    bmi.b   .out3
    
    lea high_score_highlight_color_table(pc),a0
    move.w  high_score_highlight_color_index(pc),d0
    add.w   d0,d0
    move.w  (a0,d0.w),d2
    
    move.w  d2,d4
    move.w  #32,d0

    lea     .pos_table(pc),a3
    move.w  high_score_position(pc),d5
    add.w   d5,d5
    add.w   d5,d5
    move.l  (a3,d5.w),a0
    move.w  high_score_highlight_y(pc),d1
    bsr     write_blanked_color_string
    
    lea     hiscore_table(pc),a4
    move.l  (a4,d5.w),d2
    
    move.w  #64,d0
    move.w  #7,d3
    bsr write_blanked_color_decimal_number

    move.w  d4,d2
    move.w  #120,d0
    lea .pts(pc),a0
    bsr write_blanked_color_string

.out3
    rts

    
    rts

    

.color_table
	REPT	3
    dc.w    $FF0
	ENDR
	REPT	3
	dc.w	$0DD
	ENDR
	REPT	4
	dc.w	$80D
	ENDR
	
.pos_table  
    dc.l    .pos1
    dc.l    .pos2
    dc.l    .pos3
    dc.l    .pos4
    dc.l    .pos5
    dc.l    .pos6
    dc.l    .pos7
    dc.l    .pos8
    dc.l    .pos9
    dc.l    .pos10
    

.onechar
    dc.b    0,0
.toggle
    dc.b    0
.score_table
    dc.b    "-- SCORE TABLE --",0
.play
    dc.b    "PLAY",0
.pts
    dc.b    "0 PTS  ...",0
.how_far_1
	dc.b	"HOW FAR CAN YOU INVADE",0
.how_far_2
	dc.b	" OUR SCRAMBLE SYSTEM ?",0
    
.pos1
    dc.b    "1ST",0
.pos2
    dc.b    "2ND",0
.pos3
    dc.b    "3RD",0
.pos4
    dc.b    "4TH",0
.pos5
    dc.b    "5TH",0
.pos6
    dc.b    "6TH",0
.pos7
    dc.b    "7TH",0
.pos8
    dc.b    "8TH",0
.pos9
    dc.b    "9TH",0
.pos10
    dc.b    "10TH",0
    
.score_ranking
    dc.b    "- SCORE RANKING -",0
    even

high_score_position
    dc.w    0
high_score_highlight_y
    dc.w    0
high_score_highlight_timer
    dc.w    0
high_score_highlight_color_index
    dc.w    0
high_score_highlight_color_table
    dc.w    $0FF
    dc.w    $0F0
    dc.w    $FF0
    dc.w    $FFF
high_score
    dc.l    DEFAULT_HIGH_SCORE
	dc.l	$DEADBEEF
hiscore_table:
    REPT    NB_HIGH_SCORES
	IFD		HIGHSCORES_TEST
    dc.l    (DEFAULT_HIGH_SCORE/10)*(10-REPTN)   ; decreasing score for testing	
	ELSE
    dc.l    DEFAULT_HIGH_SCORE
	ENDC
    ENDR
	dc.l	$DEADBEEF

draw_char_command
    dc.w    0,0 ; X,Y
    dc.b    0   ; char
    dc.b    0   ; command set (0: no, $FF: yes)
intro_frame_index
    dc.w    0
intro_step
    dc.b    0
intro_state_change
    dc.b    0
    even
    
draw_title
    lea    .title(pc),a0
    move.w  #64,d0
    move.w  #72-24,d1
    move.w  #$0dd,d2
    bsr write_color_string 
	
	
	
    bra.b   draw_copyright

.title
    dc.b    '- SCRAMBLE -',0
    even
draw_copyright
    lea    .copyright(pc),a0
    move.w  #64,d0
    move.w  #221-16,d1
    move.w  white_color(pc),d2
    bra write_color_string    
.copyright
    dc.b    'c KONAMI  1981',0
    even

; what: clears a plane of any width (not using blitter, no shifting, start is multiple of 8), 16 height
; args:
; < A1: dest (must be even)
; < D0: X (multiple of 8)
; < D1: Y
; < D2: blit width in bytes (even, 2 must be added same interface as blitter)
; trashes: none

clear_plane_any_cpu
    move.w  d3,-(a7)
    move.w  #16,d3
    bsr     clear_plane_any_cpu_any_height
    move.w  (a7)+,d3
    rts
    
clear_plane_any_cpu_any_height 
    movem.l d0-D3/a0-a2,-(a7)
    subq.w  #1,d3
    bmi.b   .out
    lea mul40_table(pc),a2
    add.w   d1,d1
    beq.b   .no_add
    move.w  (a2,d1.w),d1
    add.w   d1,a1
.no_add

    lsr.w   #3,d0
    add.w   d0,a1
	move.l	a1,d1
    btst    #0,d1
    bne.b   .odd
    cmp.w   #4,d2
    bcs.b   .odd
	btst	#0,d2
	bne.b	.odd
	btst	#1,d2
	beq.b	.even
.odd    
    ; odd address
    move.w  d3,d0
    subq.w  #1,d2
.yloop
    move.l  a1,a0
    move.w  d2,d1   ; reload d1
.xloop
    clr.b   (a0)+
    dbf d1,.xloop
    ; next line
    add.w   #NB_BYTES_PER_LINE,a1
    dbf d0,.yloop
.out
    movem.l (a7)+,d0-D3/a0-a2
    rts

.even
    ; even address, big width: can use longword erase
    move.w  d3,d0
    lsr.w   #2,d2
    subq.w  #1,d2
.yloop2
    move.l  a1,a0
    move.w  d2,d1
.xloop2
    clr.l   (a0)+
    dbf d1,.xloop2
    ; next line
    add.w   #NB_BYTES_PER_LINE,a1
    dbf d0,.yloop2
    bra.b   .out
    

; what: clears a plane of any width (using blitter), 16 height
; args:
; < A1: dest
; < D0: X (not necessarily multiple of 8)
; < D1: Y
; < D2: rect width in bytes (2 is added)
; trashes: none
    
clear_plane_any_blitter:
    movem.l d0-d6/a1/a5,-(a7)
    lea _custom,a5
    moveq.l #-1,d3
    move.w  #16,d4
    bsr clear_plane_any_blitter_internal
    movem.l (a7)+,d0-d6/a1/a5
    rts

;; C version
;;   UWORD minterm = 0xA;
;;
;;    if (mask_base) {
;;      minterm |= set_bits ? 0xB0 : 0x80;
;;    }
;;    else {
;;      minterm |= set_bits ? 0xF0 : 0x00;
;;    }
;;
;;    wait_blit();
;;
;;    // A = Mask of bits inside copy region
;;    // B = Optional bitplane mask
;;    // C = Destination data (for region outside mask)
;;    // D = Destination data
;;    custom.bltcon0 = BLTCON0_USEC | BLTCON0_USED | (mask_base ? BLTCON0_USEB : 0) | minterm;
;;    custom.bltcon1 = 0;
;;    custom.bltbmod = mask_mod_b;
;;    custom.bltcmod = dst_mod_b;
;;    custom.bltdmod = dst_mod_b;
;;    custom.bltafwm = left_word_mask;
;;    custom.bltalwm = right_word_mask;
;;    custom.bltadat = 0xFFFF;
;;    custom.bltbpt = (APTR)mask_start_b;
;;    custom.bltcpt = (APTR)dst_start_b;
;;    custom.bltdpt = (APTR)dst_start_b;
;;    custom.bltsize = (height << BLTSIZE_H0_SHF) | width_words;
;;  }
  
; < A5: custom
; < D0,D1: x,y
; < A1: plane pointer
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: blit height
; trashes D0-D6
; > A1: even address where blit was done
clear_plane_any_blitter_internal:
    ; pre-compute the maximum of shit here
    lea mul40_table(pc),a2
    add.w   d1,d1
    beq.b   .d1_zero    ; optim
    move.w  (a2,d1.w),d1
    swap    d1
    clr.w   d1
    swap    d1
.d1_zero
    move.l  #$030A0000,d5   ; minterm useC useD & rect clear (0xA) 
    move    d0,d6
    beq.b   .d0_zero
    and.w   #$F,d6
    and.w   #$1F0,d0
    lsr.w   #3,d0
    add.w   d0,d1

    swap    d6
    clr.w   d6
    lsl.l   #8,d6
    lsl.l   #4,d6
    or.l    d6,d5            ; add shift
.d0_zero    
    add.l   d1,a1       ; plane position (always even)

	move.w #NB_BYTES_PER_LINE,d0
    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height


    ; now just wait for blitter ready to write all registers
	bsr	wait_blit
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
    move.w  d0,bltdmod(a5)	;D modulo
	move.w  #-1,bltadat(a5)	;source graphic top left corner
	move.l a1,bltcpt(a5)	;destination top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    rts

MAP_X = 32

draw_level_map
    lea $DFF000,A5

	lea	level_number_tiles,a0
	clr.w	d1		; Y=0
	move.w	#MAP_X,d0	; X=32
	move.w	#5,d7	; 6 tiles

	moveq.l #-1,d3		; no mask
    move.w  #6,d2       ; 32 pixels + 2 shift bytes
    move.w  #8,d4      ; 8 pixels height
.lloop
	move.w	#2,d5		; 3 planes
	;;move.l	a2,a0	; next level pic
	lea		screen_data,a1
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24*NB_BYTES_PER_LINE,a1
	ENDC
.ploop
    movem.l d0-d6/a1-a4,-(a7)
    bsr blit_plane_any_internal
    movem.l (a7)+,d0-d6/a1-a4
	add.w	#6*8,a0
	add.w	#SCREEN_PLANE_SIZE,a1
	dbf		d5,.ploop
	add.w	#32,d0
	dbf		d7,.lloop
	
	rts
	
draw_current_level
    lea $DFF000,A5
	move.l	current_player(pc),a4
	move.w	#MAP_X,d0	; X=16
	move.w	#8,d1
	move.w	#5,d7	; 6 tiles
	clr.w	d6
	moveq.l #-1,d3		; no mask
    move.w  #6,d2       ; 32 pixels + 2 shift bytes
    move.w  #8,d4      ; 8 pixels height
.lloop
	move.w	#2,d5		; 3 planes
	lea		screen_data,a1
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24*NB_BYTES_PER_LINE,a1
	ENDC
	lea		red_level_mark,a0
	cmp.w	level_number(a4),d6
	beq.b	.ploop
	bcs.b	.ploop
	lea		purple_level_mark,a0
.ploop
    movem.l d0-d6/a1-a4,-(a7)
    bsr blit_plane_any_internal
    movem.l (a7)+,d0-d6/a1-a4
	add.w	#6*8,a0
	add.w	#SCREEN_PLANE_SIZE,a1
	dbf		d5,.ploop
	add.w	#32,d0
	addq.w	#1,d6
	dbf		d7,.lloop
	rts
	
	IFND	ARCADE_SCREEN_LAYOUT
FUEL_Y = Y_MAX
	ELSE
FUEL_Y = 240
	ENDC
	
FUEL_OFFSET = FUEL_Y*NB_BYTES_PER_LINE+10
    
; draw fuel text & full amount
; < d0: color of yellow
draw_fuel_with_text
	move.w	d0,d2
	lea	fuel_text(pc),a0
	move.w	#24+16,d0
	move.w	#FUEL_Y-24,d1
	bsr		write_color_string
draw_fuel:
	moveq.w	#15,d6
	move.w  fuel(pc),d7	
	lsr.w	#1,d7	; only shows rounded value
	clr.w	d0
.lloop	
	lea	screen_data+FUEL_OFFSET,a1
	add.w	d0,a1
	tst.w	d7
	beq.b	.zero
	subq.w	#8,d7
	bcs.b	.lower_than_8
	; full fuel icon
	lea	fl_8(pc),a0
	bra.b	.draw_fuel_tile
.zero
	lea	fl_0(pc),a0
	bra.b	.draw_fuel_tile
.lower_than_8
	add.w	#8,d7
	lea		fuel_levels(pc),a2
	move.w	d7,d1
	add.w	d1,d1
	add.w	d1,d1
	move.l	(a2,d1.w),a0
	clr.w	d7
.draw_fuel_tile
    
	moveq.w	#NB_PLANES-1,d2
.ploop
    move.l  a1,a2
    REPT    8
    move.b  (a0)+,(a2)
    add.w   #NB_BYTES_PER_LINE,a2
    ENDR
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf     d2,.ploop
	addq.w	#1,d0
	dbf	d6,.lloop

.out
	rts
fuel_text
	dc.b	"FUEL",0
	even
	IFD	ARCADE_SCREEN_LAYOUT
LIVES_OFFSET = 248*NB_BYTES_PER_LINE+2	
	ELSE
LIVES_OFFSET = 236*NB_BYTES_PER_LINE+2
	ENDC
	
draw_last_life
	move.l	current_player(pc),a4
    move.w   #1,d0      ; draw only last life
    bra.b   draw_the_lives
    
draw_lives:
	move.l	current_player(pc),a4
    moveq.w #NB_PLANES-1,d7
    lea	screen_data+LIVES_OFFSET,a1
.cloop
    moveq.l #0,d0
    moveq.l #0,d1
    move.l  #12,d2
    bsr clear_plane_any_cpu
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf d7,.cloop
    
    clr D0
	
draw_the_lives

    move.b  nb_lives(a4),d7
    ext     d7
    subq.w  #2,d7
    bmi.b   .out
	cmp.w	#8,d7
	bcs.b	.lloop
	move.w	#8,d7	; no more than 8 lives displayed
.lloop
    lea lives,a0
    lea	screen_data+LIVES_OFFSET,a1
    add.w   d7,a1
    add.w   d7,a1
    moveq   #NB_PLANES-1,d2    
.ploop
    move.l  a1,a2
    REPT    8
    move.b  (a0)+,(a2)
    move.b  (a0)+,(1,a2)
    add.w   #NB_BYTES_PER_LINE,a2
    ENDR
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf     d2,.ploop
    tst d0
    bne.b   .out    ; just draw last life
    dbf d7,.lloop
.out
    rts

MF_OFFSET = LIVES_OFFSET+NB_BYTES_PER_PLAYFIELD_LINE-3
    
draw_mission_flags:
	move.l	current_player(pc),a4

	lea	screen_data+MF_OFFSET,a1
	lea	mission_flag,a0
    move.w  nb_missions_completed(a4),d2
    cmp.w   #8,d2
    bcs.b   .ok
    move.w  #8,d2
.ok
.mloop
	move.l	a1,a3
	move.l	a0,a2
	move.w	#2,d3
.ploop
	REPT	8
	move.b	(a2)+,(NB_BYTES_PER_LINE*REPTN,a3)
	ENDR
	add.w	#SCREEN_PLANE_SIZE,a3
	dbf	d3,.ploop
	; next flag
	subq.w	#1,a1
	dbf	d2,.mloop
    rts
   
clear_mission_flags:
	lea	screen_data+MF_OFFSET,a1
    move.w  #8,d2

.mloop
	move.l	a1,a3
	move.w	#2,d3
.ploop
	REPT	8
	clr.b	(NB_BYTES_PER_LINE*REPTN,a3)
	ENDR
	add.w	#SCREEN_PLANE_SIZE,a3
	dbf	d3,.ploop
	; next flag
	subq.w	#1,a1
	dbf	d2,.mloop
    rts   

    
draw_ground:
    bsr clear_playfield_planes
    
	move.w	#0,d0
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE-1,d7
	lea		ground_table(pc),a6
	lea		screen_tile_table,a5
	; draw_tiles will write zero to (a4)
	; as there is only ground, but we still need this address to be valid	
	lea		screen_ground_rocket_table,a4
	; clear level number so draw_tiles won't fill with bricks
	; in higher levels
	move.l	current_player(pc),a0
	
	move.w	level_number(a0),-(a7)
	clr.w	level_number(a0)
.tileloop
	bsr	draw_tiles
	addq.w	#1,D0
	addq.w	#1,a5
	dbf	d7,.tileloop
	move.l	current_player(pc),a0
	move.w	(a7)+,level_number(a0)
	rts
	
	
	IFD	SCROLL_DEBUG
; what: writes an decimal number with a given color
; args:
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; < D4: RGB4 color
; > D0: number of characters written

draw_scroll_debug
	lea	.scrollpos(pc),a0
	move.w	#0,d1
	move.w	#16,d0
	move.w	white_color(pc),d2
	bsr		write_color_string
	move.w	scroll_offset(pc),d2
	ext.l	d2
	move.W	#3,d3
	move.w	#0,d1
	move.w	#96,d0
	move.w	white_color(pc),d4
	bsr		write_color_decimal_number
	

    rts    
.scrollpos
	dc.b	"SCROLLPOS",0


	ENDC
	
init_sound
    ; init phx ptplayer, needs a6 as custom, a0 as vbr (which is zero)
    sub.l   a0,a0
    moveq.l #1,d0
    lea _custom,a6
    jsr _mt_install_cia
    rts
    
init_interrupts
    lea _custom,a6
    sub.l   a0,a0

    move.w  (dmaconr,a6),saved_dmacon
    move.w  (intenar,a6),saved_intena

    sub.l   a0,a0
    ; assuming VBR at 0
    lea saved_vectors(pc),a1
    move.l  ($8,a0),(a1)+
    move.l  ($c,a0),(a1)+
    move.l  ($10,a0),(a1)+
    move.l  ($68,a0),(a1)+
    move.l  ($6C,a0),(a1)+

    lea   exc8(pc),a1
    move.l  a1,($8,a0)
    lea   excc(pc),a1
    move.l  a1,($c,a0)
    lea   exc10(pc),a1
    move.l  a1,($10,a0)
    
    lea level2_interrupt(pc),a1
    move.l  a1,($68,a0)
    
    lea level3_interrupt(pc),a1
    move.l  a1,($6C,a0)
    
    
    rts
    
exc8
    lea .bus_error(pc),a0
    bra.b lockup
.bus_error:
    dc.b    "BUS ERROR AT",0
    even
excc
    lea .linea_error(pc),a0
    bra.b lockup
.linea_error:
    dc.b    "LINEA ERROR AT",0
    even

exc10
    lea .illegal_error(pc),a0
    bra.b lockup
.illegal_error:
    dc.b    "ILLEGAL INSTRUCTION AT",0
    even

lockup
    move.l  (2,a7),d3
    move.w  white_color(pc),d2
    move.w   #16,d0
    clr.w   d1
    bsr write_color_string

    lsl.w   #3,d0
    lea screen_data,a1
    move.l  d3,d2
    moveq.w #8,d3
    bsr write_hexadecimal_number    
.lockup
    bra.b   .lockup
finalize_sound
    bsr stop_sounds
    ; assuming VBR at 0
    sub.l   a0,a0
    lea _custom,a6
    jsr _mt_remove_cia
    move.w  #$F,dmacon(a6)   ; stop sound
    rts
    
restore_interrupts:
    lea _custom,a5
    ; assuming VBR at 0
    sub.l   a0,a0
    
    lea saved_vectors(pc),a1
    move.l  (a1)+,($8,a0)
    move.l  (a1)+,($c,a0)
    move.l  (a1)+,($10,a0)
    move.l  (a1)+,($68,a0)
    move.l  (a1)+,($6C,a0)



    move.w  saved_dmacon,d0
    bset    #15,d0
    move.w  d0,(dmacon,a5)
    move.w  saved_intena,d0
    bset    #15,d0
    move.w  d0,(intena,a5)


    rts
    
saved_vectors
        dc.l    0,0,0   ; some exceptions
        dc.l    0   ; keyboard
        dc.l    0   ; vblank
        dc.l    0   ; cia b
saved_dmacon
    dc.w    0
saved_intena
    dc.w    0

; what: level 2 interrupt (keyboard)
; args: none
; trashes: none
;
; cheat keys
; F1: skip level
; F2: toggle invincibility
; F3: toggle infinite lives
; F4: show debug info
; F5: toggle infinite fuel
; F6: stop scrolling (and no fuel depletion)
; F7: add 5000 to score
; F8: toggle randomness
; F9: stop flying enemy movement
; TAB: fast-forward (no player controls during that)

level2_interrupt:
	movem.l	D0/A0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
    
    lea keyboard_table(pc),a0
	
    bclr    #7,d0
    seq (a0,d0.w)       ; updates keyboard table
    bne.b   .no_playing     ; we don't care about key release
    ; cheat key activation sequence
    move.l  cheat_sequence_pointer(pc),a0
    cmp.b   (a0)+,d0
    bne.b   .reset_cheat
    move.l  a0,cheat_sequence_pointer
    tst.b   (a0)
    bne.b   .cheat_end
    move.w  #$0FF,_custom+color    
    st.b    cheat_keys
	; in case cheat is enabled after a legit hiscore
	clr.b	highscore_needs_saving
.reset_cheat
    move.l  #cheat_sequence,cheat_sequence_pointer
.cheat_end
    
    cmp.b   #$45,d0
    bne.b   .no_esc
    cmp.w   #STATE_INTRO_SCREEN,current_state
    beq.b   .no_esc
    cmp.w   #STATE_GAME_START_SCREEN,current_state
    beq.b   .no_esc
    bsr		set_game_over
	st.b	fast_game_over_flag
.no_esc
    
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .no_playing
    tst.b   demo_mode
    bne.b   .no_kb_pause
    cmp.b   #$19,d0
    bne.b   .no_kb_pause
	; in that game we need pause even if music
	; is playing, obviously
;    tst.b   music_playing
;    bne.b   .no_pause
    bsr	toggle_pause
.no_kb_pause
    tst.w   cheat_keys
    beq.b   .no_playing
        
    cmp.b   #$50,d0
    seq.b   game_completed_flag

    cmp.b   #$51,d0
    bne.b   .no_invincible
    eor.b   #1,invincible_cheat_flag
    move.b  invincible_cheat_flag(pc),d0
    beq.b   .x
    move.w  #$F,d0
.x
    and.w   #$FF,d0
    or.w  #$0F0,d0
    move.w  d0,_custom+color
    bra.b   .no_playing
.no_invincible
    cmp.b   #$52,d0
    bne.b   .no_infinite_lives
    eor.b   #1,infinite_lives_cheat_flag
    move.b  infinite_lives_cheat_flag(pc),d0
    beq.b   .y
    move.w  #$F,d0
.y
    and.w   #$FF,d0
    or.w  #$0F0,d0
    move.w  d0,_custom+color
    bra.b   .no_playing
.no_infinite_lives
    cmp.b   #$53,d0     ; F4
    bne.b   .no_debug
    ; show/hide debug info
    eor.b   #1,debug_flag
    ; clear left part of white plane screen
    bsr     clear_debug_screen
    bra.b   .no_playing
.no_debug
    cmp.b   #$54,d0     ; F5
    bne.b   .no_fuel
    move.w  #$0F0,_custom+color

	eor.b	#1,no_fuel_depletion_flag
.no_fuel
    cmp.b   #$55,d0     ; F6
    bne.b   .no_scroll_stop_toggle
    ; free cheat slot
	eor.b	#1,scroll_stop_flag
    bra.b   .no_playing
.no_scroll_stop_toggle
    cmp.b   #$56,d0     ; F7
    bne.b   .no_add_to_score
	move.w	#500,d0		; add 5000
	bsr		add_to_score
.no_add_to_score
    cmp.b   #$57,d0     ; F8
    bne.b   .no_random_toggle
	eor.b	#1,random_stop_flag
.no_random_toggle
    cmp.b   #$58,d0     ; F9
    bne.b   .no_enemy_movement
    eor.b	#1,enemy_movement_stop_flag
.no_enemy_movement

.no_playing

    cmp.b   _keyexit(pc),d0
    bne.b   .no_quit
    st.b    quit_flag
.no_quit

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a0/a5
	move.w	#8,_custom+intreq
	rte
	
toggle_pause
	movem.l	d0/a6,-(a7)
	bsr.b		.x
	movem.l	(a7)+,d0/a6
	rts
	
.x
	eor.b   #1,pause_flag
	bne.b	stop_sounds
	bra		play_ambient_sound
	
    
; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

    
; what: level 3 interrupt (vblank/copper)
; args: none
; trashes: none
    
level3_interrupt:
    movem.l d0-a6,-(a7)
    lea  _custom,a5
    move.w  (intreqr,a5),d0
    btst    #5,d0
    bne.b   .vblank
    move.w  (intreqr,a5),d0
    btst    #4,d0
    beq.b   .blitter
    tst.b   demo_mode
    bne.b   .no_pause
    tst.b   pause_flag
    bne.b   .outcop
.no_pause
    ; copper
	bsr	update_stars
    bsr draw_all
    tst.b   debug_flag
    beq.b   .no_debug
    bsr draw_debug
.no_debug
    bsr update_all
    move.w  vbl_counter(pc),d0
    addq.w  #1,d0
    cmp.w   #5,d0
    bne.b   .normal
    ; update a second time, simulate 60Hz
    bsr update_all
    moveq.w #0,d0    
.normal
    move.w  d0,vbl_counter
	tst.w	cheat_keys
	beq.b	.outcop
	; check tab key
	move.b	$BFEC01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$42,d0
	beq.b	.no_pause
.outcop
	; a5 has been used by update
    move.w  #$0010,_custom+intreq
    movem.l (a7)+,d0-a6
    rte    
.vblank
    moveq.l #1,d0
    bsr _read_joystick
    move.l	current_player(pc),a4
	
    move.l  joystick_state(pc),d2
    btst    #JPB_BTN_PLAY,d0
    beq.b   .no_play
    btst    #JPB_BTN_PLAY,d2
    bne.b   .no_play

    ; no pause if not in game
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .no_play
    tst.b   demo_mode
    bne.b   .no_play

    bsr		toggle_pause
.no_play
    lea keyboard_table(pc),a0
    tst.b   ($63,a0)    ; ctrl key
    beq.b   .no_fire
    bset    #JPB_BTN_RED,d0
.no_fire 
    tst.b   ($64,a0)    ; l-alt key
    beq.b   .no_fire2
	; using bomb on keyboard sets 2-button control
	clr.b	one_button_control_option(a4)
    bset    #JPB_BTN_BLU,d0
.no_fire2
    tst.b   ($4C,a0)    ; up key
    beq.b   .no_up
    bset    #JPB_BTN_UP,d0
    bra.b   .no_down
.no_up    
    tst.b   ($4D,a0)    ; down key
    beq.b   .no_down
	; set DOWN
    bset    #JPB_BTN_DOWN,d0
.no_down    
    tst.b   ($4F,a0)    ; left key
    beq.b   .no_left
	; set LEFT
    bset    #JPB_BTN_LEFT,d0
    bra.b   .no_right   
.no_left
    tst.b   ($4E,a0)    ; right key
    beq.b   .no_right
	; set RIGHT
    bset    #JPB_BTN_RIGHT,d0
.no_right    
	; store previous joystick AND keyboard state
	move.l	d2,previous_joy1
    move.l  d0,joystick_state
    move.w  #$0020,(intreq,a5)
    movem.l (a7)+,d0-a6
    rte
.blitter
    move.w  #$0040,(intreq,a5) 
    movem.l (a7)+,d0-a6
    rte

vbl_counter:
    dc.w    0


INTRO_SONG_LENGTH = ORIGINAL_TICKS_PER_SEC*5

; what: updates game state
; args: none
; trashes: potentially all registers

update_all

    DEF_STATE_CASE_TABLE

.intro_screen
    bra update_intro_screen
    
    
    
.game_start_screen
	addq.l	#1,state_timer
	tst.b	play_start_music_message
	beq.b	.not_started
	tst.b	demo_mode
	bne.b	.play
	cmp.b	#2,play_start_music_message
	beq.b	.no_play
	st.b	game_started_flag
	moveq	#0,d0
    bsr.b	play_music
	move.b	#2,play_start_music_message
	st.b	display_player_one_message
	; re-detect controllers just in case they were switched at this point
	bsr		_detect_controller_types
.no_play
	move.w	start_music_countdown(pc),d0
	subq.w	#1,d0
	bne.b	.out
.play
	move.w	#STATE_PLAYING,current_state
.out
	move.w	d0,start_music_countdown
.continue
	tst.b	game_started_flag
	beq.b	.not_started
	move.l	joystick_state(pc),d0
	move.l	previous_joy1(pc),d1
	move.l	#JPF_BTN_LEFT|JPF_BTN_RIGHT|JPF_BTN_UP|JPF_BTN_DOWN,d2
	and.l	d2,d0
	beq.b	.no_dir_change
	and.l	d2,d1
	cmp.l	d1,d0
	beq.b	.no_dir_change
	move.l	current_player(pc),a0
	eor.b	#$FF,one_button_control_option(a0)
.no_dir_change
.not_started
    rts
    
.life_lost
    rts

	; from within interrupt, tick until timeout
	; (end text could be read)
.next_level
	; wait a while, then send signal to restart game
	addq.l	#1,state_timer
	cmp.l	#ORIGINAL_TICKS_PER_SEC*4,state_timer
	bne.b	.no_change
	st.b	do_restart_game_message
.no_change
    rts
     
.game_over
    cmp.l   #GAME_OVER_TIMER,state_timer
    bne.b   .no_first
    bsr stop_sounds
.no_first
    tst.l   state_timer
    bne.b   .cont
    bsr stop_sounds
    move.w  #STATE_INTRO_SCREEN,current_state
.cont
	tst.b	fast_game_over_flag
	beq.b	.normal
	clr.l	state_timer
	rts
.normal
    subq.l  #1,state_timer
    rts
    ; update
.playing
	tst.b	game_completed_flag
	beq.b	.no_completed
	clr.b	game_completed_flag

    bsr stop_sounds

    move.w  #STATE_NEXT_LEVEL,current_state
    clr.l   state_timer     ; without this, bonus level isn't drawn

    rts
.no_completed

    tst.l   state_timer
    bne.b   .no_first_tick
	nop

.no_first_tick
    ; for demo mode
    addq.w  #1,record_input_clock

	; palette timer
	move.w	playfield_palette_timer(pc),d0
	add.w	#1,d0
	cmp.w	#ORIGINAL_TICKS_PER_SEC*8,d0
	bne.b	.no_palette_change
	; change palette
	clr.w	d0
	bsr		next_playfield_palette
	clr.w	d0
.no_palette_change
	move.w	d0,playfield_palette_timer
	

	bsr	update_shots
	bsr	update_bombs
	bsr	update_explosions
	bsr	update_mystery_scores
	
	; specific/enemy update according to level
	move.l	current_player(pc),a4
	lea		update_table(pc),a0
	move.w	level_number(a4),d0
	add.w	d0,d0
	add.w	d0,d0
	move.l	(a0,d0.w),a0
	jsr		(a0)
	
	; play pending fx if any
	move.w	delayed_fx_countdown(pc),d0
	beq.b	.no_fx_pending
	subq.w	#1,d0
	bne.b	.no_fx
	move.l	delayed_fx(pc),a0
	bsr		play_fx_if_player_alive
	clr.w	d0
.no_fx
	move.w	d0,delayed_fx_countdown
.no_fx_pending

	move.l	state_timer(pc),d0
	move.l	d0,d1
	and.l	#$F,d1
	bne.b	.no_blink
	moveq.b	#1,d1
	btst	#5,d0		; one out of 2 blinks
	beq.b	.wdm
	moveq.b	#2,d1
.wdm
	move.b	d1,draw_player_title_message
.no_blink

	bsr	update_fuel_alarm
    bsr update_player
    tst.w   player_killed_timer
    bpl.b   .skip_cc     ; player killed, no collisions	
	move.l	current_player(pc),a4
	cmp.w	#4,level_number(a4)
	bcc.b	.no_airborne_enemies

	; collision with airborne enemies
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	move.w	#23,d2		; last pixel is forgiving
	move.w	#8,d3
	addq.w	#8,d0
	addq.w	#4,d1
	clr		d4
	bsr		object_to_enemy_collision
	tst.b	d0
	beq.b	.no_airborne_enemies
	bsr		player_killed
.no_airborne_enemies
	
	tst.b	scroll_stop_flag
	bne.b	.no_scroll
	bsr	update_scrolling
.no_scroll
 
    bsr check_collisions
.skip_cc
    
    tst.w   player_killed_timer
    bpl.b   .skip_a_lot
    
    bsr check_collisions

    

.skip_a_lot

    addq.l  #1,state_timer
    rts
.ready_off


    rts

.intro_music_played
    dc.b    0
    even

update_table
	dc.l	update_rockets
	dc.l	update_ufos
	dc.l	update_fireballs
	dc.l	update_rockets
	dc.l	nothing
	dc.l	update_base
	
start_music_countdown
    dc.w    0

draw_mission_completed
    bsr clear_screen
    bsr	clear_playfield_planes
	; set mixed palette so the text has the proper colors
	; but so have lives/missions
    lea end_screen_palette,a0
	move.w	#8,d0		; 8 colors
	bsr		load_palette	

	; some colors are wrong but it doesn"t matter much
	; for it to be correct we'd have to change it dynamically
	; but that ain't worth it
	move.w	#$FF0,d0
	bsr	draw_fuel_with_text
	bsr	draw_lives
	bsr	draw_mission_flags
	IFD	ARCADE_SCREEN_LAYOUT
	bsr	draw_score_and_player_title
	ENDC
	
	; the palette of the text is correct (menu palette)
	move.w	#56,d0
	move.w	#96-24,d1
	lea	.congrats_text(pc),a0
    move.w  #$0f40,d2
    bsr write_color_string 
	move.w	#16,d0
	add.w	#16,d1
	lea	.you_completed_text(pc),a0
    move.w  #$0ff0,d2
    bsr write_color_string 
	move.w	#16,d0
	add.w	#16,d1
	lea	.good_luck_text(pc),a0
    move.w  #$0dd,d2
    bsr write_color_string 
	rts
	
.congrats_text:
	dc.b	"CONGRATULATIONS",0
	
.you_completed_text:
	dc.b	"YOU COMPLETED YOUR DUTIES",0
	
.good_luck_text:
	dc.b	"GOOD LUCK NEXT TIME AGAIN",0
	
	even
	
update_base:
	tst.w	mission_completed_countdown
	bmi.b	.out
	subq.w	#1,mission_completed_countdown
	bne.b	.out
	; mission is complete
	st.b	game_completed_flag
.out
	subq.w	#1,base_x_pos
	bne.b	.no_left
	clr.l	base_dest_address
.no_left
	move.w	base_frame_subcounter(pc),d0
	addq.w	#1,d0
	cmp.w	#6,d0
	bne.b	.no_wrap
	move.w	base_frame_counter(pc),d1
	addq.w	#4,d1
	cmp.w	#12,d1
	bne.b	.no_wrap_2
	clr.w	d1
.no_wrap_2
	move.w	d1,base_frame_counter
	clr.w	d0
.no_wrap
	move.w	d0,base_frame_subcounter
	rts
	
update_fuel_alarm
	cmp.w	#80,fuel
	bcc.b	.still_enough_fuel
	subq.w	#1,low_fuel_sound_timer
	bne.b	.no_sound
	move.w	#ORIGINAL_TICKS_PER_SEC,low_fuel_sound_timer
	lea	low_fuel_sound,a0
	bsr	play_fx
.no_sound
	rts
.still_enough_fuel
	move.w	#1,low_fuel_sound_timer
	rts
	

copy_tiles
	; source offset
	move.w	scroll_offset(pc),d1
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE-2,d0
	add.w	d1,d0
	
	IFD		ARCADE_SCREEN_LAYOUT
	lea		scroll_data+NB_BYTES_PER_SCROLL_SCREEN_LINE*40,a2	; base
	ELSE
	lea		scroll_data+NB_BYTES_PER_SCROLL_SCREEN_LINE*16,a2	; base
	ENDC
	lea		(a2,d0.w),a0	; source
	lea		(-2,a2,d1.w),a1	; dest
	

    lea $DFF000,A5
	moveq.l #-1,d3	;masking of first/last word : no mask   

    move.l  #$09f00000,d5    ;A->D copy, ascending mode

	; 16 pixels + no shift bytes (word aligned blit)
	move.w #NB_BYTES_PER_SCROLL_SCREEN_LINE-2,d0
 
	move.w	#((Y_MAX-16)<<6)+1,d4	; height + width are hardcoded
	; now we have 2 blits to perform, one per plane
	
    ; now just wait for blitter ready to write all registers
	WAIT_BLITTER
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	move.w d0,bltamod(a5)		;A modulo=bytes to skip between lines	
    move.w  d0,bltdmod(a5)	;D modulo
	
	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
	
	add.w	#SCROLL_PLANE_SIZE,a0
	add.w	#SCROLL_PLANE_SIZE,a1
	
	; second plane
	
	WAIT_BLITTER
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	move.w d0,bltamod(a5)		;A modulo=bytes to skip between lines	
    move.w  d0,bltdmod(a5)	;D modulo
	
	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
	rts
		
	; this is the old tile copy routine, using only CPU
	IFEQ	1
copy_tiles_cpu
	; source offset
	move.w	scroll_offset(pc),d1
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE-2,d0
	add.w	d1,d0
	
	lea		scroll_data+NB_BYTES_PER_SCROLL_SCREEN_LINE*16,a2	; base
	lea		(a2,d0.w),a0	; source
	lea		(-2,a2,d1.w),a1	; dest
	; copy the whole column, aligned so can use word copy
    moveq #1,d4	; copy only 2 planes
	move.w	#NB_BYTES_PER_SCROLL_SCREEN_LINE*8,d5
	move.w	#SCROLL_PLANE_SIZE,d6
.ploop
	move.l	a0,a3
	move.l	a1,a4
	move.w	#(Y_MAX-16)/8-1,d0
.copy
	REPT	8
	move.w	(NB_BYTES_PER_SCROLL_SCREEN_LINE*REPTN,a3),(NB_BYTES_PER_SCROLL_SCREEN_LINE*REPTN,a4)
	ENDR
	add.w	d5,a3
	add.w	d5,a4	
	dbf	d0,.copy
	add.w	d6,a0
	add.w	d6,a1
	dbf		d4,.ploop
	rts
	ENDC
	
; draws zero or one tile column
; each time we scroll by 8 pixels

draw_scrolling_tiles
	; update screen pointer for playfield 2
	move.w	scroll_offset(pc),d0
	bsr		set_playfield_planes
	move.w	scroll_shift(pc),d0
	lsl.w	#4,d0
	move.w	d0,bplcon1_value

	tst.b	draw_tile_column_message
	beq.b	.no_new_tiles
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE-2,d0
	add.w	scroll_offset(pc),d0
	move.l	map_pointer(pc),a6
	; tiles are 8 pixels wide. shift is 0-16 we have to
	; issue 2 tile columns at a time
	lea		screen_ground_rocket_table+NB_BYTES_PER_PLAYFIELD_LINE*2-4,a4
	lea	screen_tile_table+NB_BYTES_PER_PLAYFIELD_LINE-2,a5
	cmp.b	#1,draw_tile_column_message
	bne.b	.no_correct
	addq.w	#2,a4
	addq.w	#1,a5
	addq.w	#1,d0
.no_correct
	bsr	draw_tiles
	tst.w	(a6)
	bpl.b	.no_end
	addq.w	#2,a6
	; peek on the next value
	tst.w	(a6)
	bpl.b	.level_completed
	; -2 (two negatives in a row) means loop over last level
	lea		level6map(pc),a6
	bra.b	.no_end
.level_completed
	move.l	current_player(pc),a4
	addq.w	#1,level_number(a4)
	st.b	next_level_flag
	bsr		update_level_data

.no_end
	move.l	a6,map_pointer
	
	; acknowledge draw tile message
	clr.b	draw_tile_column_message
	
	
	

.no_new_tiles	
	rts
	
play_ambient_sound
	moveq.w	#1,d0
	move.l	current_player(pc),a0
	cmp.w	#1,level_number(a0)
	bne.b	.no_special_sound_loop
	moveq.w	#2,d0
.no_special_sound_loop
	bra		play_music
	

; < D0: scroll offset
set_playfield_planes:
    moveq #1,d4		; no need for the third plane. scrolling playfield only needs 2 planes
    lea	bitplanes,a0              ; copperlist address
    lea scroll_data,a1
	add.w	d0,a1
	move.l	a1,d2
    move.w #bplpt,d3        ; first register in d3

		; 8 bytes per plane:32 + end + bplcontrol
.mkcl:
	addq.w	#8,a0
	addq.w	#4,d3
	
    move.w d3,(a0)+           ; BPLxPTH
    addq.w #2,d3              ; next register
    swap d2
    move.w d2,(a0)+           ; 
    move.w d3,(a0)+           ; BPLxPTL
    addq.w #2,d3              ; next register
    swap d2
    move.w d2,(a0)+           ; 
    add.l #SCROLL_PLANE_SIZE,d2       ; next plane
    dbf d4,.mkcl
	rts
	
update_scrolling
	; now we have to copy what we just created so when we
	; reach hard right with the tiles we just have to reset
	; the bitplane pointers at the start and the illusion of
	; continuity is here
	;
	; do that copy in the "update" part not the draw part as
	; this isn't critical if it doesn't fit in the vertical display blank
	; time, on the contrary better put it during game "computation"
	tst.w	scroll_offset
	beq.b	.no_copy
	cmp.w	#2,scroll_shift
	bne.b	.no_copy
	; copy on shift 2 of scroll, so both tile columns
	; are drawn, and it doesn't overload scroll 15 and scroll 8
	; position computations.
	bsr	copy_tiles
.no_copy


	move.w	scroll_shift(pc),d0
	
	subq.w	#1,d0
	beq.b	.next_tile
	cmp.w	#7,d0
	bne.b	.no_next_tile
	; mid tile: draw a tile
	move.b	#1,draw_tile_column_message
	bra.b	.no_next_tile
.next_tile
	move.w	#15,d0
	; draw the other tile
	move.b	#2,draw_tile_column_message
	; scroll logical rocket y map
	lea	screen_ground_rocket_table,a0

	move.w	#NB_BYTES_PER_PLAYFIELD_LINE/2-1,d2
.lloop
	move.l	(4,a0),(a0)+
	dbf		d2,.lloop
	
	; scroll logical tile screen map
	
	lea	screen_tile_table,a0
	move.w	#NB_LINES-1,d1
.yloop
	move.l	a0,a1
	move.w	#NB_BYTES_PER_PLAYFIELD_LINE/2-2,d2
.xloop
	move.w	(2,a1),(a1)+
	dbf		d2,.xloop
	lea		(NB_BYTES_PER_PLAYFIELD_LINE,a0),a0	; next line
	dbf		d1,.yloop
	
	addq.w	#2,scroll_offset
	cmp.w	#NB_BYTES_PER_PLAYFIELD_LINE,scroll_offset
	bne.b	.no_next_tile
	; reset scroll
	clr.w	scroll_offset
.no_next_tile
	move.w	d0,scroll_shift
	rts

update_rockets
	move.b	enemy_launch_cyclic_counter(pc),d0
	addq.b	#1,d0
	move.b	d0,enemy_launch_cyclic_counter
	and.b	#$3F,d0
	bne.b	.no_launch

	; check if a rocket is ready to launch
	;;airborne_enemies
	; see if there are rockets that we could launch that
	; could hit the player ship
	; original code ranges Y from $60 to $E8
	; this is actually corresponding to reversed X, $E8 being the
	; top left position of the screen, which leaves max X to 136 for us
	lea	screen_ground_rocket_table,a2
	move.l	a2,a1
	move.w	#136/8-1,d2	; 17 slots to check
.check
	move.w	(a2)+,d1	; y of rocket
	beq.b	.no_rocket
	subq.w	#8,d1		; correction
	move.l	a2,d0
	; now we have to check if that rocket wasn't destroyed
	sub.l	a1,d0	; convert to tile offset to make X
	add.w	d0,d0
	add.w	d0,d0	; times 4 to get proper X value (but not scroll-shifted)
	move.w	d0,d3
	add.w	#8,d3	; empiric make-up offset
	add.w	scroll_shift(pc),d0		; cancel scroll shift bias
	move.w	d1,d4	; save for later
	bsr		get_tile_type
	tst.b	(a0)	; rocket has been shot or launched
	beq.b	.no_rocket
	cmp.b	#ROCKET_TOP_LEFT_TILEID,(-1,a0)	
	bne.b	.no_rocket
	; coords are ok but map needs correction
	; this is empiric and this is probably making up for another
	; error in the code but that works and that's the important thing
	; (already spent too much time trying to make that damn rocket part right)
	;
	subq.w	#1,a0
.rocket
	; there's a rocket to be launched
	; remove y from list
	clr.w	(-2,a2)
	; launch a rocket
	subq.w	#8,d3
	move.w	d3,d0
	move.w	d4,d1
	add.w	#4,d1	; Y is slightly shifted
	; create flying rocket
	bsr.b	create_enemy
	tst.w	d7
	bmi.b	.no_rocket	; no slot available
	; success!
	; returns A4 if successfully created
	; remove object from playfield (and from logical map)
	move.w	d3,d0
	move.w	d4,d1
	bsr		remove_object
	; remove_object returns the address of
	; the object in the scroll field (first plane)
	; store that in our newly created flying rocket as a starting drawing
	; point
	move.l	a0,plane_address(a4)
	; and bail out
	bra.b	.no_launch
.no_rocket
	dbf	d2,.check
.no_launch
	tst.b	enemy_movement_stop_flag
	bne.b	nothing

	; update existing rockets
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a4
.loop	
	tst.b	active(a4)
	beq.b 	.no_update
	bmi.b	.no_update
	addq.w	#1,frame(a4)
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	subq.w	#1,d1	; up
	cmp.w	#8,d1
	bcs.b	.stop_rocket
	tst.b	scroll_stop_flag
	bne.b	.no_scroll
	subq.w	#1,d0	; left
	cmp.w	#X_MIN,d0
	bcs.b	.stop_rocket
	move.w	d0,xpos(a4)		; if no scroll (cheat), don't move x-wise
.no_scroll
	move.w	d1,ypos(a4)
	move.l	plane_address(a4),d0
	; change plane address too (draw doesn't use coords in scroll planes)
	sub.l   #NB_BYTES_PER_SCROLL_SCREEN_LINE,d0
	move.w	extra_y_counter(a4),d1
	addq.w	#1,d1
	cmp.w	#4,d1
	bne.b	.no_extra_y
	; once out of 4 times, move up, part of the y speed
	; kludge started with player ship y move
	clr.w	d1
	sub.l   #NB_BYTES_PER_SCROLL_SCREEN_LINE,d0
	subq.w	#1,ypos(a4)
.no_extra_y
	move.w	d1,extra_y_counter(a4)
	move.l	d0,plane_address(a4)
.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.stop_rocket
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update

	
		

check_collisions
	
	move.w	ypos(a3),d0
	
	clr.w	d0
    move.l	current_player(pc),a3
	; testing 2 tiles on ship only, let's see how it goes
	; front
    move.w  xpos(a3),d2
	add.w	#X_EXHAUST_WIDTH,d2	; skip exhaust
    move.w  ypos(a3),d3
	cmp.w	#Y_SHIP_MAX+8,d3		; just in case cheat on and no more fuel
	bcc.b	player_really_killed
	
	move.w	d2,d0
	add.w	#16,d0	; top-front
	move.w	d3,d1
	bsr		get_tile_type
	tst.b	(a0)	
	; non-zero means deadly
	bne.b	player_killed
	
	move.w	d2,d0
	move.w	d3,d1	; upper
	sub.w	#4,d1
	bsr		get_tile_type
	tst.b	(a0)
	bne.b	player_killed

	rts
	
   
player_killed:
    tst.b   invincible_cheat_flag
    bne.b   would_be_killed
player_really_killed
	move.w	#PLAYER_KILL_TIMER,player_killed_timer
	clr.w	death_frame_offset
	clr.w	player_1+frame
	clr.w	player_2+frame
	lea	player_killed_sound,a0
	bsr	play_fx
	rts
would_be_killed
	move.w	#$F00,$DFF180
	rts
	
    
CHARACTER_X_START = 88

update_intro_screen
    move.l   state_timer(pc),d0
    bne.b   .no_first
    
.first
    tst.w   high_score_position
    bpl.b   .second
    
    move.b  #1,intro_step
    st.b    intro_state_change


    bra.b   .cont
.no_first 
    cmp.l   #INTRO_TICKS_PER_SEC*6,d0
    bne.b   .no_second
.second
    move.w   high_score_position(pc),d0
    bmi.b   .no_init_second
    lsl.w   #4,d0   ; times 16
    add.w   #24,d0  ; plus offset
    move.w  d0,high_score_highlight_y
    clr.w   high_score_highlight_timer
    clr.w   high_score_highlight_color_index
.no_init_second
    move.b  #2,intro_step
    st.b    intro_state_change
    bra.b   .cont
.no_second
    cmp.l   #INTRO_TICKS_PER_SEC*12,d0
    bne.b   .cont
.third
    ; highscore highlight => first screen
    tst.w   high_score_position
    bmi.b   .really_third
    bra.b   .reset_first
.really_third
    ; third screen init
    st.b    intro_state_change
    move.b  #3,intro_step
    clr.w   intro_frame_index

    move.w  #INTRO_TICKS_PER_SEC,.cct_countdown
    move.w  #CHARACTER_X_START,.cct_x
    move.w  #80-24,.cct_y

    clr.w   .cct_text_index
    move.w   #6,.cct_counter
    clr.w   .cct_char_index
   
.cont    
    move.l  state_timer(pc),d0
    add.l   #1,D0
    cmp.l   #INTRO_TICKS_PER_SEC*22,d0
    bne.b   .no3end
.reset_first
	clr.l	state_timer
	; test if game was just played
	; with a hiscore highlight
	
	tst.w   high_score_position
    bmi.b   .demo		  ; screen 3 end => demo mode
    move.w  #-1,high_score_position	
    bra.b	.first ; from highscore highlight: just revert to title
.no3end
    move.l  d0,state_timer
    
    cmp.b   #2,intro_step
    beq.b   .step2
    cmp.b   #3,intro_step
    beq.b   .step3
    

.no_animate
    rts

.step2
    tst.w   high_score_position
    bmi.b   .out
    add.w   #1,high_score_highlight_timer
    cmp.w   #4,high_score_highlight_timer
    bne.b   .out
    clr.w   high_score_highlight_timer
    add.w   #1,high_score_highlight_color_index
    cmp.w   #4,high_score_highlight_color_index
    bne.b   .out
    clr.w   high_score_highlight_color_index
    rts
.step3
    add.w   #1,intro_frame_index
    move.w  .cct_countdown(pc),d0
    beq.b   .text_print
    subq.w  #1,d0
    move.w  d0,.cct_countdown
    rts
.text_print
    cmp.w   #24,.cct_text_index
    beq.b   .no_text        ; stop printing
    
    subq.w  #1,.cct_counter
    bne.b   .no_text
    ; reload
    move.w  #6,.cct_counter
    ; print a character
    move.w  .cct_text_index(pc),d0
    lea .text_table(pc),a0
    move.l  (a0,d0.w),a0        ; current text
    move.w  .cct_char_index(pc),d1
    add.w   d1,a0   ; current text char
    move.b  (a0),d2
    beq.b   .next_text
    
    lea draw_char_command(pc),a1
    move.l  .cct_x(pc),(a1)+    ; X & Y
    move.b  d2,(a1)+
    st.b    (a1)    ; enable
    add.w   #8,.cct_x
    add.w   #1,d1
    move.w  d1,.cct_char_index
    rts
    
.next_text
    addq.w  #4,.cct_text_index    
    add.w   #24,.cct_y
    move.w  #CHARACTER_X_START,.cct_x
    clr.w   .cct_char_index
.out    
.no_text
    rts


.demo
    ; change state
    clr.l   state_timer
    move.w  #STATE_PLAYING,current_state
    ; in demo mode
    st.b    demo_mode
    rts

.cct_countdown
    dc.w    0
.cct_x:
    dc.w    0
.cct_y:
    dc.w    0
.cct_text_index:
    dc.w    0
.cct_counter:
    dc.w    0
.cct_char_index
    dc.w    0
.text_table
    dc.l    .text1
    dc.l    .text2
    dc.l    .text3
    dc.l    .text4
    dc.l    .text5
    dc.l    .text6
.text1:
    dc.b    "... 50 PTS",0
.text2:
    dc.b    "... 80 PTS",0
.text3:
    dc.b    "... 100 PTS",0
.text4:
    dc.b    "... 150 PTS",0
.text5:
    dc.b    "... 800 PTS",0
.text6:
    dc.b    "... MYSTERY",0
    even

ship_explosion_table:
	dc.l	ship_explosion_1,ship_explosion_2,ship_explosion_1,ship_explosion_2
	dc.l	ship_explosion_1,ship_explosion_2,ship_explosion_3,ship_explosion_4
	
	; 4 frames per pointer
bomb_animation_table:
	dc.l	bomb_1
	dc.l	bomb_2
	dc.l	bomb_1
	dc.l	bomb_2
	dc.l	bomb_3,bomb_3
	dc.l	bomb_4,bomb_4
	dc.l	bomb_5
bomb_animation_table_end
	
explosion_animation_table_part_1
	REPT	9
	dc.l	explosion_1
	ENDR
	REPT	9
	dc.l	explosion_2
	ENDR
	REPT	9
	dc.l	explosion_3
	ENDR
	REPT	9
	dc.l	explosion_4
	ENDR
explosion_animation_table_part_2
	; second part
	REPT	9
	dc.l	explosion_5
	ENDR
	REPT	9
	dc.l	explosion_6
	ENDR
	REPT	9
	dc.l	explosion_7
	ENDR
	REPT	9
	dc.l	explosion_8
	ENDR

	; directly copied from reverse-engineered arcade source
	; X and Y are swapped (90 degree rotated display)
	
ufo_move_table

    dc.b  $FF,$00         ; XDelta = -1, YDelta = 0          
    dc.b  $FE,$00         ; XDelta = -2, YDelta = 0
    dc.b  $FE,$00       
    dc.b  $FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$02,$FE,$00
    dc.b  $FE,$02,$FE,$00,$FE,$02,$FE,$02,$FE,$02,$FE,$02,$00,$02,$00,$02
    dc.b  $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$00,$02,$02
    dc.b  $02,$00,$02,$02,$02,$00,$02,$02,$02,$00,$02,$00,$02,$00,$02,$00
    dc.b  $02,$00,$02,$02,$02,$00,$02,$00,$02,$00,$02,$02,$02,$00,$02,$00
    dc.b  $02,$00,$02,$00,$02,$02,$02,$00,$02,$02,$02,$00,$02,$00,$02,$02
    dc.b  $02,$02,$02,$02,$00,$02,$00,$02,$00,$02,$FE,$02,$FE,$02,$FE,$02
    dc.b  $FE,$02,$FE,$00,$FE,$02,$FE,$00,$FE,$02,$FE,$00,$FE,$02,$FE,$00
    dc.b  $FE,$02,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00,$FE,$00
    dc.b  $80,$80      ; marker byte specifying "end of path"
	
bomb_move_table
    dc.b  $00,$00         ; X delta = 0, Y delta = 0 
    dc.b  $01,$00         ; X delta = 1, Y delta = 0  
    dc.b  $00,$FF         ; X delta = 0, Y delta = -1 (remember, bytes are signed)
    ; .. you get the idea.. Now here's the rest of the deltas
    dc.b  $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
    dc.b  $00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF
    dc.b  $00,$FF,$01,$FF,$00,$FF,$00,$FF,$00,$FF,$01,$FF,$00,$FF,$00,$FF
    dc.b  $01,$FF,$00,$FF,$01,$FF,$01,$FF,$00,$FF,$01,$FF,$01,$FF,$01,$FF
    dc.b  $01,$00,$01,$00,$01,$FF,$01,$FF,$01,$00,$01,$FF,$01,$00,$01,$FF
    dc.b  $01,$00,$01,$00,$01,$FF,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00
    dc.b  $01,$00,$01,$00,$01,$00
    dc.b  $80,$80      ; marker byte specifying "end of path"
	even
	

     
animate_enemy
    move.w  frame(a4),d1
    addq.w  #1,d1
    and.w   #$F,d1
    move.w  d1,frame(a4)
    rts

    
play_loop_fx
    tst.b   demo_mode
    bne.b   .nosfx
    lea _custom,a6
    bra _mt_loopfx
.nosfx
    rts
    


    
    
update_player
    move.l  current_player(pc),a4
    move.w  player_killed_timer(pc),d6
    bmi.b   .alive

	subq.w	#1,d6
	beq.b	.restart_level
	move.w	d6,player_killed_timer
	
	btst	#0,d6
	beq.b	.no_palette_switch
	moveq	#1,d0
	bsr		next_playfield_palette
.no_palette_switch
	
	move.w	frame(a4),d0
	addq.w	#1,d0
	cmp.w	#$80,d0
	bne.b	.no_reset
	clr.w	d0
.no_reset
	move.w	d0,frame(a4)
	
	lsr.w	#4,d0
	move.w	d0,death_frame_offset   ; 0,1,2,3
    rts
.restart_level
	move.w  #STATE_LIFE_LOST,current_state
	rts

	
.alive
	move.b	fuel_depetion_current_timer(pc),d0
	subq.b	#1,d0
	bne.b	.no_fuel_dec
	tst.b	no_fuel_depletion_flag
	bne.b	.no_fuel_dec
	tst.b	scroll_stop_flag
	bne.b	.no_fuel_dec
	move.w	#-1,d0
	bsr		add_to_fuel
	move.b	fuel_depletion_timer(pc),d0
.no_fuel_dec
	move.b	d0,fuel_depetion_current_timer
	
	move.b	alive_timer(pc),d0
	addq.b	#1,d0
	move.b	d0,alive_timer
	and.b	#$3F,d0
	bne.b	.no_points
	; adding 10 points each 64 ticks just because player is alive
	moveq.l	#1,d0
	bsr		add_to_score
.no_points
    bsr animate_player    


    move.l  joystick_state(pc),d0
    IFD    RECORD_INPUT_TABLE_SIZE
    bsr     record_input
    ENDC
    tst.b   demo_mode
    beq.b   .no_demo
    ; if fire is pressed, end demo, goto start screen
    btst    #JPB_BTN_RED,d0
    bne.b   .demo_end
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_demo_end
	; demo ended with "blue" => sets 2-button control
	move.l	current_player(pc),a0
	clr.b	one_button_control_option(a0)
.demo_end
	bsr		set_game_over
	st.b	fast_game_over_flag
	
    clr.b   demo_mode
	clr.b	game_started_flag
	clr.l	state_timer
	clr.b	play_start_music_message
    move.w  #STATE_GAME_START_SCREEN,current_state
    rts

.no_demo_end
    clr.l   d0
    ; demo running
    ; read next timestamp
    move.l  record_data_pointer(pc),a0
    cmp.l   record_data_end(pc),a0
    bcc.b   .no_demo        ; no more input
    move.b  (a0),d2
    lsl.w   #8,d2
    move.b  (1,a0),d2
    ;;add.b   #3,d2   ; correction???
    cmp.w  record_input_clock(pc),d2
    bne.b   .repeat        ; don't do anything now
    ; new event
    move.b  (2,a0),d2
    addq.w  #3,a0
    move.l  a0,record_data_pointer
	move.b	d2,previous_move
	bra.b	.cont
.repeat
	move.b	previous_move(pc),d2
.cont
    btst    #LEFT>>2,d2
    beq.b   .no_auto_left
    bset    #JPB_BTN_LEFT,d0
    bra.b   .no_auto_right
.no_auto_left
    btst    #RIGHT>>2,d2
    beq.b   .no_auto_right
    bset    #JPB_BTN_RIGHT,d0
.no_auto_right
    btst    #UP>>2,d2
    beq.b   .no_auto_up
    bset    #JPB_BTN_UP,d0
    bra.b   .no_auto_down
.no_auto_up
    btst    #DOWN>>2,d2
    beq.b   .no_auto_down
    bset    #JPB_BTN_DOWN,d0
.no_auto_down
    btst    #FIRE,d2
    beq.b   .no_auto_fire
    bset    #JPB_BTN_RED,d0
.no_auto_fire
    btst    #BOMB,d2
    beq.b   .no_auto_bomb
    bset    #JPB_BTN_BLU,d0
.no_auto_bomb
    
    ; read live or recorded controls
.no_demo
    move.w	xpos(a4),d2
    move.w	ypos(a4),d3

	tst.w	fuel
	beq.b	.force_move

    tst.l   d0
    beq.b   .no_move        ; nothing is currently pressed: optimize
.force_move
	move.l	previous_joy1(pc),d1
    btst    #JPB_BTN_RED,d0
    beq.b   .no_fire
	btst	#JPB_BTN_RED,d1
	bne.b	.no_fire
	bsr.b	create_shot
	move.l	current_player(pc),a0
	tst.b	one_button_control_option(a0)
	beq.b	.no_fire
	bset	#JPB_BTN_BLU,d0
.no_fire
    btst    #JPB_BTN_BLU,d0
    beq.b   .no_bomb
    btst    #JPB_BTN_BLU,d1
    bne.b   .no_bomb
	bsr.b	create_bomb
.no_bomb
	tst.w	fuel
	bne.b	.controllable
    addq.w  #1,d3
    bra.b   .out
.controllable
	; directions
    btst    #JPB_BTN_RIGHT,d0
    beq.b   .no_right
    addq.w  #1,d2
    bra.b   .vertical
.no_right
    btst    #JPB_BTN_LEFT,d0
    beq.b   .vertical
    subq.w  #1,d2
	; here goes the infamous vertical tweak
	;
	; I don't know if it's a sprite vs playfield thing but
	; the original game vertical speed is greater than the horizontal
	; speed. Original source code doesn't explain that (1 is added/subbed
	; identically from X or Y axis). But if we don't add 1 one out of 4 times
	; the vertical speed isn't correct and even if it's not noticeable
	; in most stages, level 5 is near to impossible to pull through without
	; the extra speed, whether in the arcade game it's possible to master the
	; tunnel moves with a bit of training and never fail.
	;
	; I'm convinced that it is hardware related (and maybe amidar has
	; the same behaviour) because rockets and bombs have the same speed
	; as the ship.
	
.vertical
    btst    #JPB_BTN_UP,d0
    beq.b   .no_up
	EXTRA_ADD_TO_DX	-1,4,3,5
    bra.b   .out
.no_up

    btst    #JPB_BTN_DOWN,d0
    beq.b   .no_down
	EXTRA_ADD_TO_DX	1,4,3,5
.no_extra_y_2
	move.w	d5,extra_y_counter(a4)
.no_down
.out
.no_move
	cmp.w	#X_SHIP_MIN,d2
	bcs.b	.x_invalid
	cmp.w	#X_SHIP_MAX,d2
	bcc.b	.x_invalid

    move.w  d2,xpos(a4)
.x_invalid
	cmp.w	#Y_SHIP_MIN,d3
	bcs.b	.y_invalid
	cmp.w	#Y_SHIP_MAX,d3
	bcc.b	.y_invalid

    move.w  d3,ypos(a4)
.y_invalid
    rts
    
 


    
; < A0: pointer to rectangle structure

    
    IFD    RECORD_INPUT_TABLE_SIZE
record_input:
	cmp.l	prev_record_joystick_state(pc),d0
	beq.b	.no_input	; no need to re-record same input
	tst.l	d0
	bne.b	.store
    ; no input twice: ignore (saves space, same result)
    tst.l   prev_record_joystick_state
    beq.b   .no_input
.store
    move.l  d0,prev_record_joystick_state
    clr.b   d1
    ; now store clock & joystick state, "compressed" to 5 bits (up,down,left,right,fire)
    btst    #JPB_BTN_RIGHT,d0
    beq.b   .norr
    bset    #RIGHT>>2,d1
    bra.b   .norl
.norr
    btst    #JPB_BTN_LEFT,d0
    beq.b   .norl
    bset    #LEFT>>2,d1
.norl
    btst    #JPB_BTN_UP,d0
    beq.b   .noru
    bset    #UP>>2,d1
    bra.b   .nord
.noru
    btst    #JPB_BTN_DOWN,d0
    beq.b   .nord
    bset    #DOWN>>2,d1
.nord
    btst    #JPB_BTN_RED,d0
    beq.b   .norf
    bset    #FIRE,d1
.norf
    btst    #JPB_BTN_BLU,d0
    beq.b   .nobf
    bset    #BOMB,d1
.nobf
    move.l record_data_pointer(pc),a0
    cmp.l   #record_input_table+RECORD_INPUT_TABLE_SIZE-4,a0
    bcc.b   .no_input       ; overflow!!!
    
    ; store clock
    move.b  record_input_clock(pc),(a0)+
    move.b  record_input_clock+1(pc),(a0)+
	; store move
    move.b  d1,(a0)+
    ; update pointer
    move.l  a0,record_data_pointer
.no_input
    rts
    ENDC
    

; < A4: player
animate_player
	move.w	frame(a4),d0
    addq.w  #4,d0
	cmp.w	#24*4,d0
	bne.b	.ok
	clr.w	d0
.ok
	move.w	d0,frame(a4)
    rts

create_bomb:
	movem.l	a4/d0/d7,-(a7)
	; check if there's a free slot, here first or second
	move.w	#MAX_NB_BOMBS-1,d7
	lea	bombs(pc),a4
	bsr	find_slot
	tst	d7
	bmi.b	.no_bomb	; no more bomb slots
.found_bomb_slot
	; launch the bomb
	clr.w	frame(a4)
	clr.w	move_index(a4)
	; init bomb with ship position plus something
	move.l	current_player(pc),a0
	move.w	xpos(a0),d0
	add.w	#8,d0
	move.w	d0,xpos(a4)
	move.w	ypos(a0),d0
	add.w	#8,d0
	move.w	d0,ypos(a4)
	; play fall sound
	lea 	bomb_falling_sound,a0
	bsr		play_fx
.no_bomb
	movem.l	(a7)+,a4/d0/d7
	rts
	
create_ufo:
	movem.l	d0/d7/a4,-(a7)
	move.w	#X_MAX,d0
	move.w	#Y_START_UFO,d1
	bsr.b	create_enemy
	tst	d7
	bmi.b	.no_slots	; no more slots
	clr.w	move_index(a4)
.no_slots
	movem.l	(a7)+,d0/d7/a4
	rts
	
create_fireball:
	movem.l	d0/d7/a4,-(a7)
	bsr		random
	and.w	#$7F,d0
	; not too low, else the fireballs will cross the highest
	; mountain edges and game becomes unfair!
	add.w	#Y_SHIP_MIN-12,d0
	move.w	d0,d1
	move.w	#X_MAX,d0
	bsr.b	create_enemy
	clr.w	move_index(a4)
	movem.l	(a7)+,d0/d7/a4
	rts
	
	
create_enemy
	; check if there's a free slot, here first or second
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a4
	bsr	find_slot
	tst	d7
	bmi.b	.no_fly	; no more slots
	
	clr.w	frame(a4)
	clr.w	extra_y_counter(a4)
	; init bomb with ship position plus something
	move.w	d0,xpos(a4)
	move.w	d1,ypos(a4)
.no_fly
	rts
	

create_shot
	movem.l	a4/d0/d7,-(a7)
	; find free slot
	move.w	#MAX_NB_SHOTS-1,d7
	lea	shots(pc),a4
	bsr	find_slot
	tst.w	d7
	bmi.b	.out
	move.l	current_player(pc),a0
	; set the coords
	move.w	xpos(a0),d0
	add.w	#4*8,d0
	move.w	d0,xpos(a4)
	move.w	ypos(a0),d0
	add.w	#4,d0
	move.w	d0,ypos(a4)
	lea		shoot_sound,a0
	bsr		play_fx
.out
	movem.l	(a7)+,a4/d0/d7
	rts


	
	
; < D0/D1: coords
; < D2: 0 if explosion 1, != 0 explosion 2
create_explosion
	movem.l	a4/d7,-(a7)
	; find free slot
	move.w	#MAX_NB_EXPLOSIONS-1,d7
	lea	explosions(pc),a4
	bsr	find_slot
	tst.w	d7
	bmi.b	.out
	; set the coords
	move.w	d0,xpos(a4)
	move.w	d1,ypos(a4)
	clr.w	frame(a4)
	move.w	#1,nb_explosion_cycles(a4)	; number of explosions: 2
	move.w	d2,explosion_type(a4)	; explosions type (color)
.out
	movem.l	(a7)+,a4/d7
	rts


free_enemy_slots
	lea	airborne_enemies,a4
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
; what: set all objects to free
; < D7: number of items to search minus one
; < A4: start of array
; > A4/D7 trashed	
free_all_slots:

.loop	
	clr.b	active(a4)
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
	
; what: find a free gfx object in a list
; < D7: number of items to search minus one
; < A4: start of array
; > A4: found free slot (marks active to 1)
; > D7: -1 if not found, positive otherwise

; cheap factorization of a loop we find a lot since
; there are a lot of object lists in this game
find_slot:
.loop	
	tst.b	active(a4)
	beq.b	.found
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	bra.b	.out	; no free slot...
.found
	; init base stuff
	move.b	#1,active(a4)
	clr.l	previous_address(a4)
	clr.w	extra_y_counter(a4)
.out
	rts
	
update_mystery_scores:
	move.w	#MAX_NB_SCORES-1,d7
	lea	mystery_scores(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update		; wait for clear ack from draw

    tst.w   player_killed_timer
    bpl.b   .no_update     ; player killed no scroll
	tst.b	scroll_stop_flag
	bne.b	.no_update
	move.w	xpos(a4),d0
	subq.w	#1,d0
	bmi.b	.stop	; out of scroll
	move.w	d0,xpos(a4)
.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
	
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update


update_explosions:
	move.w	#MAX_NB_EXPLOSIONS-1,d7
	lea	explosions(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update		; wait for clear ack from draw
	move.w	frame(a4),d0
	addq.w	#4,d0
	cmp.w	#9*16,d0
	bne.b	.no_wrap
	clr.w	d0
	subq.w	#1,nb_explosion_cycles(a4)
	beq.b	.stop
.no_wrap
	move.w	d0,frame(a4)
    tst.w   player_killed_timer
    bpl.b   .no_update     ; player killed no scroll
	tst.b	scroll_stop_flag
	bne.b	.no_update
	move.w	xpos(a4),d0
	subq.w	#1,d0
	bmi.b	.stop	; out of scroll
	move.w	d0,xpos(a4)
.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
	
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update

	

update_shots:
	move.w	#MAX_NB_SHOTS-1,d7
	lea	shots(pc),a4
	move.l	current_player(pc),a1
	move.w	level_number(a1),d5
	lea		tile_type_table(pc),a1
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update
	move.w	xpos(a4),d0
	add.w	#SHOT_SPEED,d0
	cmp.w	#X_MAX-24,d0
	bcc.b	.stop
	move.w	d0,xpos(a4)
	; test if hitting something (scenery)
	move.w	ypos(a4),d1
	move.w	d0,d3
	move.w	d1,d4
	bsr		get_tile_type
	tst.b	(a0)
	beq.b	.try_enemies
	clr.w	d2
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	bsr.b	something_was_hit
	; shot disables on scenery or targets
	bra.b	.stop
.try_enemies
	cmp.w	#2,d5
	beq.b	.no_update	; no effect on fireballs
	; see if the shot collides with an active 16x16 enemy
	move.w	d3,d0
	move.w	d4,d1
	moveq.w	#2,d2	; small dimension
	moveq.w	#2,d3	; small dimension
	st.b	d4
	bsr		object_to_enemy_collision
	tst		d0
	bne.b	.stop
.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update


; < D0-D1: coordinates of projectile object
; < A0: pointer on screen tile map
; (obviously contains non-zero tile)
; < A1: pointer on tile type to tile flags conversion table
; < D2: 0 if shot, 1 if bomb
; trashes: a lot

something_was_hit
	move	d2,d6
	move.b	(a0),d2
	cmp.b	#FILLER_TILE,d2
	beq.b	.scenery_shot	; sometimes bomb go through the surface
	ext.w	d2
	move.b	(a1,d2.w),d2
	cmp.b	#STANDARD_TILE,d2
	beq.b	.scenery_shot
	; now compute the x,y tile coords from a0
	move.w	d0,d3
	move.w	d1,d4
	; this is an alien ground object we shot/bombed
	move.b	d2,d1
	; remove object from logical map
	; that's where corners will be useful
	; we have to reframe a0 so it points to the upper left corner
	; of the object (also allows to center explosion and remove object
	; from screen

	sub.w	scroll_shift(pc),d3		; take scroll shift into account
	addq.w	#8,d3		; compensate...
	; align on tile
	and.w	#$F8,d3
	and.w	#$F8,d4
	
	btst	#LEFT_CORNER_B,d2
	bne.b	.left_corner
	subq.w	#1,a0		; to the left
	subq.w	#8,d3		; correct x-8
.left_corner
	btst	#TOP_CORNER_B,d2
	bne.b	.top_corner
	sub.w	#NB_BYTES_PER_PLAYFIELD_LINE,a0
	subq.w	#8,d4		; correct y-8
.top_corner
	move.w	d3,d0
	move.w	d4,d1
	IFND	BOMB_TEST_MODE
	bsr		remove_object
	ENDC
	; don't trash A0 as it may be used (mystery ship)
	; re-add scroll shift to center the explosion on the object
	; (because explosion is not on the scrolling playfield)
	add.w	scroll_shift(pc),d0
	subq.w	#8,d0
	addq.w	#4,d1
	move.w	d0,d3
	move.w	d1,d4
	; get rid of corners for now
	and.b	#BOTH_CORNERS_MASK,d2
	cmp.b	#ROCKET_TILE,d2
	beq.b	.rocket_shot
	cmp.b	#FUEL_TILE,d2
	beq.b	.fuel_shot
	cmp.b	#MYSTERY_TILE,d2
	beq.b	.mystery_shot
	cmp.b	#BASE_TILE,d2
	beq.b	.base_shot
	; in some rare cases we land here
	; scenery hit below the surface or stuff...
	; not a big deal. Just ignore
	bra.b	.object_shot
.mystery_shot
	; random scoring, original games awards:
	; 100 2 out of 4 times
	; 200 3 out of 4 times
	; 300 3 out of 4 times
	bsr		random
	and.w	#3,d0
	move.w	d0,d1
	add.w	d1,d1
	add.w	d1,d1

	lea		.mystery_score(pc),a1
	move.l	(a1,d1.w),d0
	bsr		add_to_score
	lea		mystery_sprite_table(pc),a1
	
	move.l	(a1,d1.w),a1	; graphics
	exg.l	a0,a1			; swap as A0 is source and A1 dest
	bsr		blit_16x16_scroll_object
	bra.b	.object_shot
.base_shot
	moveq.w	#1,d2
	bsr		create_explosion

	move.l	#80,d0		; 800 points
	bsr		add_to_score
	; mission is now completed
	clr.l	base_dest_address
	move.w	#ORIGINAL_TICKS_PER_SEC*2,mission_completed_countdown
	bra.b	.object_shot
.fuel_shot
	; create an explosion for the object
	moveq.w	#1,d2
	bsr		create_explosion

	move.l	#15,d0		; fuel: 150 points
	bsr		add_to_score
	move.w	#48,d0
	bsr		add_to_fuel

	; explode if shot
	tst		d6
	bne.b	.no_shot
	; same sound as bomb
	lea		bomb_hits_ground_sound,a0
	bsr		play_fx_if_player_alive	
.no_shot	
	bra.b	.object_shot
.rocket_shot
	; create an explosion for the object
	
	moveq.w	#1,d2
	bsr		create_explosion

	moveq.l	#5,d0		; ground rocket: 50 points
	bsr		add_to_score

	tst		d6
	beq.b	.play_now
	; bomb: explode once and delay the other explosion
	lea		rocket_explodes_sound,a0
	move.w	#12,d0		; short delay
	bsr		play_delayed_fx
	bra.b	.object_shot
.play_now
	lea		rocket_explodes_sound,a0
	bsr		play_fx_if_player_alive
.scenery_shot
	rts
.object_shot
	tst		d6
	beq.b	.shot
	; bomb: explode once and delay the other explosion
	lea		bomb_hits_ground_sound,a0
	bsr		play_fx_if_player_alive	
.shot
	rts

.mystery_score
	dc.l	10,10,20,30
		
; < a0: logical pointer on top left logical object tile
; (in screen_tile_table)
; < D0/D1 coords in non scrolling playfield (pointed by screen_data)
; > A0: first bitplane address of object in scrolling plane (warning: can be odd)
; (note that mirror bitplane address must be computed)
; trashes: none

remove_object
	movem.l	d0-d3/a1-a3,-(a7)
	; now clear all 4 parts in logical tile table
	; (easy as a0 is provided aligned on top/left table item)
	clr.b	(a0)
	clr.b	(1,a0)
	clr.b	(NB_BYTES_PER_PLAYFIELD_LINE,a0)
	clr.b	(NB_BYTES_PER_PLAYFIELD_LINE+1,a0)
	; now transpose d0/d1 (d1 doesn't change) to scroll playfield
	lea scroll_data,a1
	;add.w	scroll_shift(pc),d0		; shift has no positive effect
	move.w	scroll_offset(pc),d2
	lsr.w	#3,d0
	add.w	d0,d2
	subq.w	#1,d2	; empiric???
	; add bytes x shift
	add.w	d2,a1

	lea		mulNB_BYTES_PER_SCROLL_SCREEN_LINE_table(pc),a0
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24+8,d1
	ELSE
	addq.w	#8,d1	; y shift (empiric)
	ENDC
	add.w	d1,d1
	; add y offset
	add.w	(a0,d1.w),a1
	move.l	a1,a3		; save
	move.l	a1,a0		; save to return it
	bsr		.clear_rect
	; now clear mirror rect (scrolling)
	; for this we need to know the offset
	sub.w	#NB_BYTES_PER_PLAYFIELD_LINE,a3
	cmp.l	#scroll_data,a3
	bcc.b	.do
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE*2,a3
.do
	move.l	a3,a1
	bsr		.clear_rect
	movem.l	(a7)+,d0-d3/a1-a3	
	rts
	
.clear_rect
	move.l	a1,a2
	moveq.w	#NB_PLANES-2,d3
.ploop
	move.l	a2,a1
	move.w	#7,d4
.cloop
	clr.b	(a1)
	clr.b	(1,a1)
	clr.b	(NB_BYTES_PER_SCROLL_SCREEN_LINE,a1)
	clr.b	(NB_BYTES_PER_SCROLL_SCREEN_LINE+1,a1)
	add.w	#NB_BYTES_PER_SCROLL_SCREEN_LINE*2,a1
	dbf		d4,.cloop
	add.w	#SCROLL_PLANE_SIZE,a2
	dbf		d3,.ploop
	rts
	

; update bombs/explosions/shots routines set a negative active flag
; when they're done. Then it's the drawing routine that clears that flag
; it's done that way because drawing routine sometimes skips 1 frame (1 out of 6)
; because updates are 60Hz and screen updates are 50Hz (PAL)
;
; doing everything from the update routines would leave one unerased object from
; time to time

update_bombs:
	move.w	#MAX_NB_BOMBS-1,d7
	move.l	current_player(pc),a1
	move.w	level_number(a1),d5
	lea		tile_type_table(pc),a1
	lea	bombs(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update
	addq.w	#1,frame(a4)	; no brainer add 1
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	move.w	move_index(a4),d2	; move index
	lea		bomb_move_table(pc),a0
	move.b	(a0,d2.w),d3
	cmp.b	#$80,d3
	beq.b	.no_update	; end of table, not going to happen
	ext.w	d3
	beq.b	.no_y_add
	; add one more y every 4 y moves (y speed kludge)
	clr.w	d3
	EXTRA_ADD_TO_DX	1,4,3,5
	add.w	d3,d1
	cmp.w	#Y_MAX-16,d1	; can't happen
	bcc.b	.stop
.no_y_add
	move.b	(1,a0,d2.w),d3
	ext.w	d3
	sub.w	d3,d0
	addq.w	#2,move_index(a4)
	move.w	d0,xpos(a4)
	move.w	d1,ypos(a4)
	move.w	d0,d3
	move.w	d1,d4
	addq.w	#8,d0		; compensate (again!!)
	; test if hitting something (scenery)
	bsr		get_tile_type
	tst.b	(a0)
	beq.b	.try_enemies
	; bomb explodes on scenery
	clr.w	d2
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	bsr		create_explosion
	move.w	xpos(a4),d0
	addq.w	#8,d0		; compensate (again!!)
	move.w	ypos(a4),d1
	moveq	#1,d2
	bsr		something_was_hit
	
	lea		bomb_hits_ground_sound,a0
	bsr		play_fx_if_player_alive	
	

	bra.b	.stop
.try_enemies
	cmp.w	#2,d5
	beq.b	.no_update

	; see if the shot collides with an active 16x16 enemy
	move.w	d3,d0
	move.w	d4,d1
	addq.w	#5,d0
	addq.w	#5,d1
	moveq.w	#6,d2	; big dimension
	moveq.w	#6,d3	; big dimension
	st.b	d4
	bsr		object_to_enemy_collision
	tst		d0
	bne.b	.stop
.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update


update_ufos:
	move.b	enemy_launch_cyclic_counter(pc),d0
	addq.b	#1,d0
	move.b	d0,enemy_launch_cyclic_counter
	and.b	#$3F,d0
	bne.b	.no_launch
	; insert an ufo in playfield
	bsr		create_ufo
.no_launch
	; move existing enemies
	tst.b	enemy_movement_stop_flag
	bne.b	nothing
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea		airborne_enemies(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update

	move.w	move_index(a4),d2	; move index
	move.w	d2,d0
	addq.w	#2,d0		; next pos
	move.w	d0,move_index(a4)
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	lea		ufo_move_table(pc),a0
.retry
	move.b	(a0,d2.w),d3
	cmp.b	#$80,d3
	bne.b	.no_reset
	; end of table, loop
	clr.w	move_index(a4)
	move.b	(a0),d3
	clr.w	d2
.no_reset
	ext.w	d3
	beq.b	.no_y_move
	
	move.w	extra_y_counter(a4),d5
	addq.w	#1,d5
	cmp.w	#4,d5
	bne.b	.no_extra_y
	tst.w	d3
	bmi.b	.negative
	addq.w	#1,d3
	bra.b	.no_extra_y
.negative
	subq.w	#1,d3
.no_extra_y
	; once out of 4 times, move up, part of the y speed
	; kludge started with player ship y move
	move.w	d1,extra_y_counter(a4)
.no_y_move
	add.w	d3,d1
	move.b	(1,a0,d2.w),d3
	ext.w	d3
	sub.w	d3,d0
	;subq.w	#1,d0
	bmi.b	.stop
	
	move.w	d0,xpos(a4)
	move.w	d1,ypos(a4)

.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update


update_fireballs:
	; play sound in fake loop unless player is killed
    tst.w  player_killed_timer
    bpl.b   .no_sound_play

	move.w	fireball_sound_timer(pc),d0
	addq.w	#1,d0
	cmp.w	#ORIGINAL_TICKS_PER_SEC,d0
	bne.b	.no_sound_play
	lea	fireballs_sound,a0
	bsr	play_fx
	clr.w	d0
.no_sound_play
	move.w	d0,fireball_sound_timer
	
	move.b	enemy_launch_cyclic_counter(pc),d0
	addq.b	#1,d0
	move.b	d0,enemy_launch_cyclic_counter
	and.b	#$F,d0		; spawn every 16 ticks
	bne.b	.no_launch
	; insert an ufo in playfield
	bsr		create_fireball
.no_launch
	tst.b	enemy_movement_stop_flag
	bne.b	nothing

	; move existing enemies
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea		airborne_enemies(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update

	move.w	move_index(a4),d0
	
	addq.w	#1,d0
	cmp.w	#5,d0
	bne.b	.no_reset
	move.w	frame(a4),d1
	addq.w	#4,d1
	cmp.w	#24,d1
	bne.b	.no_reset2
	clr.w	d1
.no_reset2
	move.w	d1,frame(a4)
	clr.w	d0
.no_reset
	move.w	d0,move_index(a4)
	
	move.w	xpos(a4),d0
	subq.w	#4,d0
	
	bmi.b	.stop
	move.w	d0,xpos(a4)

.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update


; what: 16x16 flying object collision with bomb/shot/ship
; depends on the level because objects don't have the same shape
; (ufos, rockets)
; < D0,D1: x,y of bomb/shot/ship
; < D2: width of colliding object of bomb/shot/ship (4 for bomb, 2 for shot)
; < D3: height of colliding object
; < D4: should we score if collided
; trashes: nothing
; returns: D0.b	!= 0 if something was hit

object_to_enemy_collision:
	movem.l	d1-d7/a4,-(a7)
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea		airborne_enemies(pc),a4


	move.w	D0,d5
	move.w	D1,d6
	add.w	d2,d5
	add.w	d3,d6	; d0-d5 / d1-d6: X/Y bounding box for projectile
.loop	
	tst.b	active(a4)
	beq.b	.no_update
	bmi.b	.no_update

; condition for intersection
;
; !(r2.left > r1.right
;        || r2.right < r1.left
;        || r2.top > r1.bottom
;        || r2.bottom < r1.top);
		
	move.w	enemy_hitbox_x_len(pc),d2	; hitbox size of enemy
	move.w	xpos(a4),d3
	add.w	enemy_hitbox_x_margin(pc),d3
; !(r2.left > r1.right
	cmp.w	d5,d3	 ; D5: x obj max, d3: x nme min
	bcc.b	.no_update	; D3 >= D5: skip
	add.w	d2,d3
;        || r2.right < r1.left
	cmp.w	d3,d0	; D0: x obj min, d3: x nme max
	bcc.b	.no_update	; D3+D2 < D5: skip
	
	; vertical part
	move.w	enemy_hitbox_y_len(pc),d2	; hitbox size of enemy
	move.w	ypos(a4),d3
	add.w	enemy_hitbox_y_margin(pc),d3

	cmp.w	d6,d3	 ; D5: x obj max, d3: x nme min
	bcc.b	.no_update	; D3 >= D5: skip
	add.w	d2,d3
;        || r2.right < r1.left
	cmp.w	d3,d1	; D1: y obj min, d3: y nme max
	bcc.b	.no_update	; D3+D2 < D5: skip
	
	; insersection validated
	move.w	xpos(a4),d0
	move.w	ypos(a4),d1
	moveq	#1,d2
	bsr		create_explosion
	
	tst	d4
	beq.b	.no_scoring
	moveq.l	#8,D0	; 80 points
	move.l	current_player(pc),a0
	cmp.w	#1,level_number(a0)
	bne.b	.no_ufos
	move.l	#10,d0
.no_ufos
	bsr	add_to_score
	; enemy hit explosion + score
	lea	rocket_explodes_sound,a0	; TODO not the right sound
	bsr	play_fx
.no_scoring
	st.b	active(a4)	; last clear, no draw
	st.b	d0
	bra.b	.out
	
.no_update
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	clr.l	d0
.out
	movem.l	(a7)+,d1-d7/a4
	rts
.stop
	st.b	active(a4)	; last clear, no draw
	bra.b	.no_update
	
draw_explosions:
	move.w	#MAX_NB_EXPLOSIONS-1,d7
	lea	explosions(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_draw
    lea screen_data,a1
	bmi.b	.erase
	lea	explosion_animation_table_part_1(pc),a0
	move.w	frame(a4),d0
	tst.w	explosion_type(a4)
	beq.b	.okay
	add.w	#explosion_animation_table_part_2-explosion_animation_table_part_1,d0	; second explosion type
.okay
	move.l	(a0,d0.w),a0	; get proper frame
.do_draw
	move.w	xpos(a4),d3
	move.w	ypos(a4),d4
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24,d4
	ENDC
    move.w d3,d0
    move.w d4,d1
    ; plane 0
    move.l  a1,a2
    lea (BOB_16X16_PLANE_SIZE*3,a0),a3	; only 3 planes
    bsr blit_16x16_plane_cookie_cut
    move.l  a1,previous_address(a4)
    ; plane 2 & 4
    ; a3 is already computed from first cookie cut blit
	REPT	2
	lea	(SCREEN_PLANE_SIZE,a2),a1
	move.l	a1,a2
    lea (BOB_16X16_PLANE_SIZE,a0),a0
    move.w d3,d0
    move.w d4,d1
    bsr blit_16x16_plane_cookie_cut
	ENDR
	
.no_draw
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.erase
	; ack last draw message, disable explosion
	clr.b	active(a4)
	lea		empty_16x16_bob,a0
	bra.b	.do_draw

draw_shots:
	move.w	#MAX_NB_SHOTS-1,d7
	lea	shots(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_draw
    lea screen_data,a1
	; erase
	move.l	previous_address(a4),d0
	beq.b	.no_erase
	; erase
	move.l	d0,a1
	moveq.w	#2,d3
.cloop
	clr.b	(NB_BYTES_PER_LINE,a1)
	clr.b	(a1)
	clr.b	(1+NB_BYTES_PER_LINE,a1)
	clr.b	(1,a1)
	add.w	#SCREEN_PLANE_SIZE,a1
	dbf		d3,.cloop
.no_erase
	tst.b	active(a4)
	bpl.b	.draw
	clr.b	active(a4)	; ack erase message
	bra.b	.no_draw
.draw
	move.w	xpos(a4),d2
	move.w	ypos(a4),d3
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24,d3
	ENDC
    lea screen_data,a1
	move.l	d2,d0
	move.l	d3,d1
	addq.w	#4,d1	; draw slightly below
	ADD_XY_TO_A1	a0
	move.l	a1,previous_address(a4)
	; A1 is the address, now check x to shift data
	move.l	d2,d0
	move.b	#$C0,d2
	and.w	#$7,d0	; 8 possible shifts
	lsr.b	d0,d2
	scs		d4
	moveq.w	#2,d3
.ploop
	; write one extra bit
	or.b	d2,(a1)
	or.b	d2,(NB_BYTES_PER_LINE,a1)
	tst.b	d4
	beq.b	.no_extra_bit
	bset	#7,(1,a1)
	bset	#7,(1+NB_BYTES_PER_LINE,a1)
.no_extra_bit
	add.w	#SCREEN_PLANE_SIZE,a1
	dbf		d3,.ploop
.no_draw
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts

	
draw_flying_rockets:
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_draw
	bmi.b	.clear

	move.w	frame(a4),d0
	and.w	#$10,d0
	lsr.w	#2,d0	; 0 or 4 each 16 frames
.okay
	lea		flying_rocket_sprite_table(pc),a0
	move.l	(a0,d0.w),a0	; get proper frame
.draw
	move.l	plane_address(a4),a1
	move.l	a1,previous_address(a4)	; save for later (erase)
	bsr		blit_16x16_scroll_object
	
.no_draw
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.clear
	; last draw of that object
	; erase_flying_rockets did the job, just ack the flag
	clr.b	active(a4)
	bra.b	.no_draw	
	
erase_explosions:
	move.w	#MAX_NB_EXPLOSIONS-1,d7
	lea	explosions(pc),a0
	bra	erase_16x16_objects
	
erase_ufos:
erase_fireballs:
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a0
	bra		erase_16x16_objects

erase_bombs:	
	move.w	#MAX_NB_BOMBS-1,d7
	lea	bombs(pc),a0
erase_16x16_objects:	
	; 0 coords (we're using exact bitplane addresses)
	clr.l	d0
	clr.l	d1
	moveq.l	#4,d2	; 4 bytes: blitter width 16 bits + 16 extra shift bits
.loop
	tst.b	active(a0)
	beq.b	.no_erase

    move.l  previous_address(a0),d5
    beq.b   .no_erase

    ; first, restore plane 0
    ; erase plane 0
  
	bclr	#0,d5		; align on even planes
	move.l	d5,a1

	; first clear using the blitter
	bsr.b	clear_plane_any_blitter
	
	; the use the CPU while the blitter is working
	add.w	#SCREEN_PLANE_SIZE,a1
	bsr.b	clear_plane_any_cpu
	
	; then use the blitter again
	add.w	#SCREEN_PLANE_SIZE,a1
	bsr.b	clear_plane_any_blitter
.no_erase
	add.w	#GfxObject_SIZEOF,a0
	dbf		d7,.loop
	rts
	
; < A0: data
; < A4: enemy struct
; < D3: X
; < D4: Y

; shared between bombs, ufos, fireballs, internal use
; trashes: pretty much every register :)

internal_blit_3_object_planes:
    lea screen_data,a1
	move.w	xpos(a4),d3
	move.w	ypos(a4),d4
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24,d4
	ENDC
    move.w d3,d0
    move.w d4,d1
    ; plane 0
    move.l  a1,a2
    lea (BOB_16X16_PLANE_SIZE*3,a0),a3	; only 3 planes
    bsr blit_16x16_plane_cookie_cut
    move.l  a1,previous_address(a4)
    ; plane 2 & 4
    ; a3 is already computed from first cookie cut blit
	REPT	2
	lea	(SCREEN_PLANE_SIZE,a2),a1
	move.l	a1,a2
    lea (BOB_16X16_PLANE_SIZE,a0),a0
    move.w d3,d0
    move.w d4,d1
    bsr blit_16x16_plane_cookie_cut
	ENDR
	rts
	
draw_bombs:
	move.w	#MAX_NB_BOMBS-1,d7
	lea	bombs(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_draw
	bmi.b	.clear
	lea	bomb_animation_table(pc),a0
	move.w	frame(a4),d0
	and.b	#$FC,d0		; round on 4
	cmp.w	#bomb_animation_table_end-bomb_animation_table-4,d0
	bcs.b	.okay
	; last frame sticks
	move.w	#bomb_animation_table_end-bomb_animation_table-4,d0
.okay
	move.l	(a0,d0.w),a0	; get proper frame
.draw
	bsr	internal_blit_3_object_planes

.no_draw
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.clear
	; last draw of that object, clears it
	clr.b	active(a4)
	lea	 empty_16x16_bob,a0
	bra.b	.draw

draw_fireballs:
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_draw
	bmi.b	.clear
	lea	fireball_table(pc),a0
	move.w	frame(a4),d0
	move.l	(a0,d0.w),a0
.draw
	bsr		internal_blit_3_object_planes
	
.no_draw
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.clear
	; last draw of that object, clears it
	clr.b	active(a4)
	lea	 empty_16x16_bob,a0
	bra.b	.draw
	

draw_ufos:
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a4
.loop	
	tst.b	active(a4)
	beq.b	.no_draw
	bmi.b	.clear
	lea	ufo,a0
.draw
	bsr		internal_blit_3_object_planes
	
.no_draw
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
.clear
	; last draw of that object, clears it
	clr.b	active(a4)
	lea	 empty_16x16_bob,a0
	bra.b	.draw
	

	
erase_flying_rockets:
	move.w	#MAX_NB_AIRBORNE_ENEMIES-1,d7
	lea	airborne_enemies(pc),a4
.loop
	tst.b	active(a4)
	beq.b	.no_erase
	
    move.l  previous_address(a4),d5
	beq.b	.no_erase
.not_first_draw
	; we can't just erase a big square around the rocket as
	; that would destroy landscape & other objects around launching site
	; instead we blit an empty bob with a mask made of rocket enveloppe
	lea		flying_rocket_mask,a0
	move.l	d5,a1
	bsr		blit_16x16_scroll_object

.no_erase
	add.w	#GfxObject_SIZEOF,a4
	dbf		d7,.loop
	rts
	

	
old_erase_bombs:
	move.w	#MAX_NB_BOMBS-1,d7
	lea	bombs(pc),a0
.loop
	tst.b	active(a0)
	beq.b	.no_erase
    move.l  previous_address(a0),d5
    bne.b   .not_first_draw
    moveq.l #-1,d5
	bra.b	.no_erase
.not_first_draw
    ; first, restore plane 0
    ; erase plane 0
    lea screen_data,a1
    sub.l   a1,d5       ; d5 is now the offset
	bclr	#0,d5
	add.w	d5,a1
	REPT	2
	bsr.b	clear_bomb_plane
	add.w	#SCREEN_PLANE_SIZE,a1
	ENDR
	bsr.b	clear_bomb_plane
.no_erase
	add.w	#GfxObject_SIZEOF,a0
	dbf		d7,.loop
	rts

	
; draw player, dual playfield, skipping 2 planes each time

draw_player:
    move.l	current_player(pc),a4
    move.l  previous_address(a4),d5
    bne.b   .not_first_draw
    moveq.l #-1,d5
	bra.b	.no_erase
.not_first_draw
    ; first, restore plane 0
    ; erase plane 0
    lea screen_data,a1
    sub.l   a1,d5       ; d5 is now the offset
	bclr	#0,d5
	add.w	d5,a1
	bsr		clear_ship_plane
    
.no_erase

    tst.w  player_killed_timer
    bmi.b   .normal
    lea     ship_explosion_table(pc),a0
    move.w  death_frame_offset(pc),d0
	add.w	d0,d0
	add.w	d0,d0
    add.w   d0,a0       ; proper frame to blit
    move.l  (a0),a0
    bra.b   .shipblit
.normal

	lea		ship_sprite_table(pc),a0
	move.w	frame(a4),d0
	move.l	(a0,d0.w),a0
.shipblit
    move.w  xpos(a4),d3
    move.w  ypos(a4),d4
	IFD		ARCADE_SCREEN_LAYOUT
	add.w	#24,d4
	ENDC
    lea	screen_data,a1

    
    move.l  a1,a6
    move.w d3,d0
    move.w d4,d1

    ; plane 0
    move.l  a1,a2
    lea (BOB_32X16_PLANE_SIZE*3,a0),a3
    bsr blit_ship_cookie_cut
    move.l  a1,previous_address(a4)
    
    ; remove previous second plane before blitting the new one
    ; nice as it works in parallel with the first plane blit started above
    lea	screen_data+SCREEN_PLANE_SIZE,a1
    move.l  a1,a2   ; just restored background
    tst.l   d5
    bmi.b   .no_erase2
    add.w	d5,a1
	; clear plane 2
	bsr	clear_ship_plane
	move.l	a2,a1
.no_erase2    
    ; plane 2
    ; a3 is already computed from first cookie cut blit
    lea (BOB_32X16_PLANE_SIZE,a0),a0
    move.w d3,d0
    move.w d4,d1

    bsr blit_ship_cookie_cut
    lea (BOB_32X16_PLANE_SIZE,a0),a0
 
    lea	screen_data+SCREEN_PLANE_SIZE*2,a1
    move.l  a1,a2   ; just restored background
    tst.l   d5
    bmi.b   .no_erase4
    add.w	d5,a1
        
	; clear plane 4
	bsr	clear_ship_plane
	move.l	a2,a1
.no_erase4
    ; plane 2
    ; a3 is already computed from first cookie cut blit
    move.w d3,d0
    move.w d4,d1

    ;;bra blit_ship_cookie_cut
    
blit_ship_cookie_cut
    movem.l d2-d7/a2/a4/a5,-(a7)
    lea $DFF000,A5
	moveq.l #-1,d3	;masking of first/last word    
    move.w  #6,d2       ; 32 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height   
    bsr blit_plane_any_internal_cookie_cut
    movem.l (a7)+,d2-d7/a2/a4/a5
	rts
	
clear_ship_plane
	REPT	16
	clr.l	(NB_BYTES_PER_LINE*REPTN,a1)
	clr.w	(4+NB_BYTES_PER_LINE*REPTN,a1)
	ENDR
	rts
	
clear_bomb_plane
	REPT	12
	clr.l	(NB_BYTES_PER_LINE*(REPTN+2),a1)
	ENDR
	rts
	
	
clear_16x16_plane_cpu
	REPT	16
	clr.l	(NB_BYTES_PER_LINE*REPTN,a1)
	ENDR
	rts
	
    
; < d0.w: x
; < d1.w: y
; > d0.L: control word
store_sprite_pos
    movem.l  d1/a0/a1,-(a7)

    lea	HW_SpriteXTable(pc),a0
    lea	HW_SpriteYTable(pc),a1

    add.w	d0,d0
    add.w	d0,d0
    move.l	(a0,d0.w),d0
    add.w	d1,d1
    add.w	d1,d1
    or.l	(a1,d1.w),d0
    movem.l  (a7)+,d1/a0/a1
    rts


direction_speed_table
    ; right
    dc.w    1,0
    ; left
    dc.w    -1,0
    ; up
    dc.w    0,-1
    ; down
    dc.w    0,1
    
    
HW_SpriteXTable
  rept 320
x   set REPTN+$80
    dc.b  0, x>>1, 0, x&1
  endr


HW_SpriteYTable
  rept 260
ys  set REPTN+$2c
ye  set ys+16       ; size = 16
    dc.b  ys&255, 0, ye&255, ((ys>>6)&%100) | ((ye>>7)&%10)
  endr

    
; what: checks what is below x,y
; returns 0 out of the grid
; (allows to handle edges, with a limit given by
; the move methods)
; args:
; < d0 : x (screen coords)
; < d1 : y
; > a0: points on byte value to read (can be written to unless it points on negative value!!)
; which is 0 if empty space 
; -1 if filler (not really possible to reach, though)
; tile id for the rest (needs to be decoded with "tile_table"
; if not just checking for collision with the scenery, ex: shots & bombs
; need to know what they're hitting)
;
; trashes: d0,d1

get_tile_type:
	sub.w	scroll_shift(pc),d0		; take scroll shift into account
    cmp.w   #Y_MAX+1,d1
    bcc.b   .out_of_bounds
    cmp.w   #X_MAX+1,d0
    bcc.b   .out_of_bounds
    ; no need to test sign (bmi) as bcc works unsigned so works on negative!
    ; apply x,y offset
	IFD		ARCADE_SCREEN_LAYOUT
	;add.w	#8,d1
	ENDC
	
    lsr.w   #3,d1       ; 8 divide : tile
	subq.w	#1,d1		; correct 1 tile up (empiric)
    lea     mulNB_BYTES_PER_PLAYFIELD_LINE_table(pc),a0
    add.w   d1,d1
    move.w  (a0,d1.w),d1    ; times 28 or 30 or whatever the value
    lea		screen_tile_table,a0
    
    add.w   d1,a0
    lsr.w   #3,d0   ; 8 divide
    add.w   d0,a0
    rts
.out_of_bounds
    lea .minus_one(pc),a0  ; allowed, the move routine already has bounds, points on -1
    rts
   
.minus_one:
    dc.b    -1
    even
    
	
; what: blits 16x16 data on one plane
; args:
; < A0: data (16x16)
; < A1: plane
; < D0: X
; < D1: Y
; < D2: blit mask (disabled in API)
; trashes: D0-D1
; returns: A1 as start of destination (A1 = orig A1+40*D1+D0/8)

blit_16x16_plane
    movem.l d2-d6/a2-a5,-(a7)
    lea $DFF000,A5
	moveq.l #-1,d3	; no need for a different partial mask
    moveq.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height
    bsr blit_plane_any_internal
    movem.l (a7)+,d2-d6/a2-a5
    rts
    
; what: blits 16x16 data on one plane, cookie cut
; args:
; < A0: data (16x16)
; < A1: plane  (40 rows)
; < A2: background (40 rows) to mix with cookie cut
; < A3: source mask for cookie cut (16x16)
; < D0: X
; < D1: Y
; < D2: blit mask (removed from API)
; trashes: D0-D1
; returns: A1 as start of destination (A1 = orig A1+40*D1+(D0/16)*2)

blit_16x16_plane_cookie_cut
    movem.l d2-d7/a2/a4/a5,-(a7)
    lea $DFF000,A5
	moveq.l #-1,d3	;masking of first/last word : no mask   
    moveq.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height   
    bsr blit_plane_any_internal_cookie_cut
    movem.l (a7)+,d2-d7/a2/a4/a5
    rts
    
    
; what: blits (any width)x(any height) data on one plane
; args:
; < A0: data (width x height)
; < A1: plane
; < D0: X
; < D1: Y
; < D2: blit width in bytes (+2)
; < D3: blit mask
; < D4: blit height
; trashes: D0-D1, A1
;
; if A1 is already computed with X/Y offset and no shifting, an optimization
; skips the XY offset computation

blit_plane_any:
    movem.l d2-d6/a2-a5,-(a7)
    lea $DFF000,A5
    bsr blit_plane_any_internal
    movem.l (a7)+,d2-d6/a2-a5
    rts

; < A5: custom
; < D0,D1: x,y
; < A0: source
; < A1: plane pointer
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: blit height
; trashes D0-D6
; > A1: even address where blit was done
blit_plane_any_internal:
    ; pre-compute the maximum of shit here
    lea mul40_table(pc),a2
    swap    d1
    clr.w   d1
    swap    d1
    add.w   d1,d1
    beq.b   .d1_zero    ; optim
    move.w  (a2,d1.w),d1
.d1_zero
    move.l  #$09f00000,d5    ;A->D copy, ascending mode
    move    d0,d6
    beq.b   .d0_zero
    and.w   #$F,d6
    and.w   #$1F0,d0
    lsr.w   #3,d0
    add.w   d0,d1

    swap    d6
    clr.w   d6
    lsl.l   #8,d6
    lsl.l   #4,d6
    or.l    d6,d5            ; add shift
.d0_zero    
    add.l   d1,a1       ; plane position (always even)

	move.w #NB_BYTES_PER_LINE,d0
    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height


    ; now just wait for blitter ready to write all registers
	WAIT_BLITTER
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines
    move.w  d0,bltdmod(a5)	;D modulo
	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    rts


; quoting mcgeezer:
; "You have to feed the blitter with a mask of your sprite through channel A,
; you feed your actual bob bitmap through channel B,
; and you feed your pristine background through channel C."

; < D0.W,D1.W: x,y
; < A0: source
; < A1: destination
; < A2: background to mix with cookie cut
; < A3: source mask for cookie cut
; < A5: custom
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: height
; returns: start of destination in A1 (computed from old A1+X,Y)
; trashes: a2,a3,a4

blit_plane_any_internal_cookie_cut:
    movem.l d0-d7,-(a7)
    ; pre-compute the maximum of shit here
    lea mul40_table(pc),a4
    swap    d1
    clr.w   d1
    swap    d1
    add.w   d1,d1
    move.w  d1,d6   ; save it
    beq.b   .d1_zero    ; optim
    move.w  (a4,d1.w),d1
.d1_zero
    move.l  #$0fca0000,d5    ;B+C-A->D cookie cut   

    move    d0,d7
    beq.b   .d0_zero
    and.w   #$F,d7
    and.w   #$1F0,d0
    lsr.w   #3,d0

    lsl.l   #8,d7
    lsl.l   #4,d7
    or.w    d7,d5            ; add shift to mask (bltcon1)
    swap    d7
    clr.w   d7
    or.l    d7,d5            ; add shift
    
    move.w  d0,d7
    add.w   d0,d1
    
.d0_zero
    ; make offset even. Blitter will ignore odd address
    ; but a 68000 CPU doesn't and since we RETURN A1...
    bclr    #0,d1
    add.l   d1,a1       ; plane position (long: allow unsigned D1)

    ; a4 is a multiplication table
    ;;beq.b   .d1_zero    ; optim
    move.w  (a4,d6.w),d1
    add.w   d7,a2       ; X
;;.d1_zero    
    ; compute offset for maze plane
    add.l   d1,a2       ; Y maze plane position

	move.w #NB_BYTES_PER_LINE,d0

    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height

    ; always the same settings (ATM)

    ; now just wait for blitter ready to write all registers
	WAIT_BLITTER
    
    ; blitter registers set

    move.l  d3,bltafwm(a5)
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines
	clr.w bltbmod(a5)		;A modulo=bytes to skip between lines
	move.l d5,bltcon0(a5)	; sets con0 and con1

    move.w  d0,bltcmod(a5)	;C modulo
    move.w  d0,bltdmod(a5)	;D modulo

	move.l a3,bltapt(a5)	;source graphic top left corner (mask)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a2,bltcpt(a5)	;pristine background
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    
    movem.l (a7)+,d0-d7
    rts


; what: blits 16x16 data 2 planes/2 locations, no shifting
; args:
; < A0: source (16x16)
; < A1: destination (56 rows, assuming address is correct (no XY))
; trashes: D0-D1

blit_16x16_scroll_object_no_cookie_cut
    movem.l d2-d7/a2-a3/a5,-(a7)
    lea $DFF000,A5
	move.l	a1,d1
	moveq.l #-1,d3	;masking of first/last word : no mask   
    moveq.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height   
	

    move.l  #$09f00000,d5    ;A->D copy, ascending mode
	btst	#0,d1
	beq.b	.no_shift
	bclr	#0,d1
	move.l	d1,a1	; even address
	; 8 bit shift for source A
	bset	#31,d5
.no_shift
	move.l	a1,a2

	move.w #NB_BYTES_PER_SCROLL_SCREEN_LINE,d0
    sub.w   d2,d0       ; blit width

    lsl.w   #6,d4
    lsr.w   #1,d2
    add.w   d2,d4       ; blit height

	; now we have 4 blits to perform
	; 1 blit to a1 (and a1+SCROLL_PLANE_SIZE)
	; 1 blit to a3 (and a3+SCROLL_PLANE_SIZE)
	
	
    ; now just wait for blitter ready to write all registers
	WAIT_BLITTER
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines	
    move.w  d0,bltdmod(a5)	;D modulo
	
	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit

	; let a2 point to graphics second plane
	lea	(BOB_16X16_PLANE_SIZE,a0),a2

	move.l	a1,a3
	; now compute mirror rect (scrolling)
	; for this we need to know the offset
	sub.w	#NB_BYTES_PER_PLAYFIELD_LINE,a3
	cmp.l	#scroll_data,a3
	bcc.b	.do
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE*2,a3
.do
	
	WAIT_BLITTER

	move.l a0,bltapt(a5)	;source graphic top left corner
	move.l a3,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit

	; now second plane
	add.l	#SCROLL_PLANE_SIZE,a1
	add.l	#SCROLL_PLANE_SIZE,a3
	
	WAIT_BLITTER

	move.l a2,bltapt(a5)	;source graphic top left corner
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
	
	WAIT_BLITTER

	move.l a2,bltapt(a5)	;source graphic top left corner
	move.l a3,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
	
    movem.l (a7)+,d2-d7/a2-a3/a5
    rts
    

; what: blits 16x16 data 2 planes/2 locations, no shifting
; args:
; < A0: 2-plane source (16x16) with mask as third plane
; < A1: destination (56 rows, assuming address is correct (no X,Y in D0/D1))
;       but can be odd (so 8 bits shifting will be added)

; (will use A1 as background for cookie cut too)
; trashes: D0-D1

blit_16x16_scroll_object
    movem.l d2-d7/a0-a5,-(a7)
    lea $DFF000,A5
	move.l	a1,d1
	moveq.l #-1,d3	;masking of first/last word : no mask   
	lea	(BOB_16X16_PLANE_SIZE*2,a0),a4	; mask

    move.l  #$0fca0000,d5    ;B+C-A->D cookie cut   
	btst	#0,d1
	beq.b	.no_shift
	bclr	#0,d1
	move.l	d1,a1	; even address
	; 8 bit shift for both A and B
	or.l	#$80008000,d5
.no_shift

	move.w #NB_BYTES_PER_SCROLL_SCREEN_LINE-4,d0

    move.w   #16<<6+2,d4       ; blit height

	; now we have 4 blits to perform
	; 1 blit to a1 (and a1+SCROLL_PLANE_SIZE)
	; 1 blit to a3 (and a3+SCROLL_PLANE_SIZE)
	
	
    ; now just wait for blitter ready to write all registers
	WAIT_BLITTER
    
    ; blitter registers set
    move.l  d3,bltafwm(a5)
	move.l d5,bltcon0(a5)	
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines	
    move.w  d0,bltcmod(a5)	;C modulo
    move.w  d0,bltdmod(a5)	;D modulo
	
	move.l a4,bltapt(a5)	;source graphic top left corner (mask, remains set for all 4 blits)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a1,bltcpt(a5)	;pristine background
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit


	; now compute mirror rect (scrolling)
	; for this we need to know if the currently passed 
	; address is first half of scroll buffer or second
	; so we can compute the mirror address and replicate the draw
	move.l	a1,a3
	sub.w	#NB_BYTES_PER_PLAYFIELD_LINE,a3
	cmp.l	#scroll_data,a3
	bcc.b	.do
	add.w	#NB_BYTES_PER_PLAYFIELD_LINE*2,a3
.do
	
	WAIT_BLITTER

	; note: even if bltapt is the same between all blits, it MUST be set at each
	; blit because blitter probably increases value internally
	move.l a4,bltapt(a5)	;source graphic top left corner (mask, remains set for all 4 blits)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a3,bltcpt(a5)	;pristine background
	move.l a3,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit

	; now second plane
	add.w	#SCROLL_PLANE_SIZE,a1

	; let a0 point to graphics second plane
	lea	(BOB_16X16_PLANE_SIZE,a0),a0
	
	WAIT_BLITTER

	move.l a4,bltapt(a5)	;source graphic top left corner (mask, remains set for all 4 blits)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a1,bltcpt(a5)	;pristine background
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit

	; now second plane
	add.w	#SCROLL_PLANE_SIZE,a3
	
	WAIT_BLITTER

	move.l a4,bltapt(a5)	;source graphic top left corner (mask, remains set for all 4 blits)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a3,bltcpt(a5)	;pristine background
	move.l a3,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
	
    movem.l (a7)+,d2-d7/a0-a5
    rts
    

wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,_custom+dmaconr
	BNE.S	.wait
	rts

; what: writes an hexadecimal number (or BCD) in a single plane
; args:
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; > D0: number of characters written

write_hexadecimal_number

    movem.l A0/D2-d5,-(a7)
    cmp.w   #7,d3
    bcs.b   .padok
    move.w  #7,d3
.padok
    bsr     .write_num
    movem.l (a7)+,A0/D2-d5
    rts
.write_num
    lea .buf+8(pc),a0

    
.loop
    subq    #1,d3    
    move.b  d2,d5
    and.b   #$F,d5
    cmp.b   #10,d5
    bcc.b   .letter
    add.b   #'0',d5
    bra.b   .ok
.letter
    add.b   #'A'-10,d5
.ok
    move.b  d5,-(a0)
    lsr.l   #4,d2
    beq.b   .write
    bra.b   .loop
.write
    tst.b   d3
    beq.b   .w
    bmi.b   .w
    subq    #1,d3
.pad
    move.b  #' ',-(a0)
    dbf d3,.pad
.w
    bra write_string
.buf
    ds.b    8
    dc.b    0
    even
    
; what: writes an decimal number in a single plane
; args:
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; > D0: number of characters written
    
write_decimal_number
    movem.l A0/D2-d5,-(a7)
    cmp.w   #18,d3
    bcs.b   .padok
    move.w  #18,d3
.padok
    cmp.l   #655361,d2
    bcs.b   .one
    sub.l   #4,d3
    move.w  d0,d5
    ; first write high part    
    divu    #10000,d2
    swap    d2
    moveq.l #0,d4
    move.w   d2,d4
    clr.w   d2
    swap    d2
    bsr     .write_num
    lsl.w   #3,d0
    add.w   d5,d0   ; new xpos
    
    move.l  d4,d2
    moveq   #4,d3   ; pad to 4
.one
    bsr     .write_num
    movem.l (a7)+,A0/D2-d5
    rts
.write_num
    bsr convert_number
    bra write_string
 
; what: writes an decimal number with a given color
; args:
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; < D4: RGB4 color
; > D0: number of characters written
 
write_color_decimal_number
    movem.l A0-A1/D2-d6,-(a7)
    lea     write_color_string(pc),a1
    bsr.b     write_color_decimal_number_internal
    movem.l (a7)+,A0-A1/D2-d6
    rts
write_blanked_color_decimal_number
    movem.l A0-A1/D2-d6,-(a7)
    lea     write_blanked_color_string(pc),a1
    bsr.b     write_color_decimal_number_internal
    movem.l (a7)+,A0-A1/D2-d6
    rts
    
write_color_decimal_number_internal
    cmp.w   #18,d3
    bcs.b   .padok
    move.w  #18,d3
.padok
    cmp.l   #655361,d2
    bcs.b   .one
    sub.l   #4,d3
    move.w  d0,d5
    ; first write high part    
    divu    #10000,d2
    swap    d2
    moveq.l #0,d6
    move.w   d2,d6
    clr.w   d2
    swap    d2
    bsr     .write_num
    lsl.w   #3,d0
    add.w   d5,d0   ; new xpos
    
    move.l  d6,d2
    moveq   #4,d3   ; pad to 4
.one
    bsr     .write_num
    rts
.write_num
    bsr convert_number
    move.w  d4,d2
    jmp     (a1) 
    
    
; < D2: value
; > A0: buffer on converted number
convert_number
    lea .buf+20(pc),a0
    tst.w   d2
    beq.b   .zero
.loop
    divu    #10,d2
    swap    d2
    add.b   #'0',d2
    subq    #1,d3
    move.b  d2,-(a0)
    clr.w   d2
    swap    d2
    tst.w   d2
    beq.b   .write
    bra.b   .loop
.zero
    subq    #1,d3
    move.b  #'0',-(a0)
.write
    tst.b   d3
    beq.b   .w
    bmi.b   .w
    subq    #1,d3
.pad
    move.b  #' ',-(a0)
    dbf d3,.pad
.w
    rts
    
.buf
    ds.b    20
    dc.b    0
    even
    

; what: writes a text in a given color, clears
; non-written planes (just in case another color was
; written earlier)
; args:
; < A0: c string
; < D0: X (multiple of 8)
; < D1: Y
; < D2: RGB4 color (must be in palette!)
; > D0: number of characters written
; trashes: none

write_blanked_color_string:
    movem.l D1-D7/A1,-(a7)
    ; compute string length first in D6
    clr.w   d6
.strlen
    tst.b   (a0,d6.w)
    beq.b   .outstrlen
    addq.w  #1,d6
    bra.b   .strlen
.outstrlen
    ; D6 has string length
    move.l current_palette(pc),a1
    move.w  current_nb_colors(pc),d3
	subq.w	#1,d3
    moveq   #0,d5
.search
    move.w  (a1)+,d4
    cmp.w   d4,d2
    beq.b   .color_found
    addq.w  #1,d5
    dbf d3,.search
    moveq   #0,d0   ; nothing written
    bra.b   .out
.color_found
    ; d5: color index
    lea screen_data,a1
	move.w	#SCREEN_PLANE_SIZE,d7
	moveq   #2,d3		; 8 colors (DPF)
    move.w  d0,d4
.plane_loop
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; > D0: number of characters written
    move.w  d4,d0
    btst    #0,d5
    beq.b   .clear_plane
    bsr write_string
    bra.b   .next_plane
.clear_plane
    movem.l d0-d6/a1/a5,-(a7)
    move.w  d6,d2   ; width in bytes = string length
    ;lea _custom,a5
    ;moveq.l #-1,d3
    move.w  #8,d3

    bsr clear_plane_any_cpu_any_height
    movem.l (a7)+,d0-d6/a1/a5
.next_plane
    lsr.w   #1,d5
    add.w   D7,a1
    dbf d3,.plane_loop
.out
    movem.l (a7)+,D1-D7/A1
    rts
    
; what: writes a text in a given color
; args:
; < A0: c string
; < D0: X (multiple of 8)
; < D1: Y or Y-24 (if ARCADE_SCREEN_LAYOUT)
; < D2: RGB4 color (must be in palette!)
; > D0: number of characters written
; trashes: none

write_color_string:
    movem.l D1-D5/A1,-(a7)
    move.l	current_palette(pc),a1
    move.w  current_nb_colors(pc),d3
	subq.w	#1,d3
    moveq   #0,d5
.search
    move.w  (a1)+,d4
    cmp.w   d4,d2
    beq.b   .color_found
    addq.w  #1,d5
    dbf d3,.search
    moveq   #0,d0   ; nothing written
    bra.b   .out
.color_found
    ; d5: color index
    lea screen_data,a1
	move.w	#SCREEN_PLANE_SIZE,d7
	moveq   #2,d3		; 8 colors (DPF)
    move.w  d0,d4
.plane_loop
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8)
; < D1: Y
; > D0: number of characters written
    btst    #0,d5
    beq.b   .skip_plane
    move.w  d4,d0
    bsr write_string
.skip_plane
    lsr.w   #1,d5
    add.w	d7,a1
    dbf d3,.plane_loop
.out
    movem.l (a7)+,D1-D5/A1
    rts
    
; what: writes a text in a single plane
; args:
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8 else it's rounded)
; < D1: Y-24
; > D0: number of characters written
; trashes: none

write_string:
    movem.l A0-A2/d1-D2,-(a7)
    clr.w   d2
	IFD	ARCADE_SCREEN_LAYOUT
	add.w	#24,d1
	ENDC
    ADD_XY_TO_A1    a2
    moveq.l #0,d0
.loop
    move.b  (a0)+,d2
    beq.b   .end
    addq.l  #1,d0

    cmp.b   #'0',d2
    bcs.b   .special
    cmp.b   #'9'+1,d2
    bcc.b   .try_letters
    ; digits
    lea digits(pc),a2
    sub.b   #'0',d2
    bra.b   .wl
    
.try_letters: 
    cmp.b   #'A',d2
    bcs.b   .special
    cmp.b   #'Z'+1,d2
    bcc.b   .special
    lea letters(pc),a2
    sub.b   #'A',d2
.wl
    lsl.w   #3,d2   ; *8
    add.w   d2,a2
	REPT	8
    move.b  (a2)+,(NB_BYTES_PER_LINE*REPTN,a1)
	ENDR
    bra.b   .next
.special
    cmp.b   #' ',d2
    bne.b   .nospace
    lea space(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nospace    
    cmp.b   #'!',d2
    bne.b   .noexcl
    lea exclamation(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noexcl
    cmp.b   #'/',d2
    bne.b   .noslash
    lea slash(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noslash
    cmp.b   #'-',d2
    bne.b   .nodash
    lea dash(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nodash
    cmp.b   #'.',d2
    bne.b   .nodot
    lea dot(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nodot
    cmp.b   #'"',d2
    bne.b   .noquote
    lea quote(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noquote
    cmp.b   #'?',d2
    bne.b   .noqmark
    lea qmark(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noqmark
    cmp.b   #'c',d2
    bne.b   .nocopy
    lea copyright(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.nocopy



.next   
    addq.l  #1,a1
    bra.b   .loop
.end
    movem.l (a7)+,A0-A2/d1-D2
    rts

	IFD		HIGHSCORES_TEST
load_highscores
save_highscores
	rts
	ELSE
    
load_highscores
    lea scores_name(pc),a0
    move.l  _resload(pc),d0
    beq.b   .standard
    move.l  d0,a2
    jsr (resload_GetFileSize,a2)
    tst.l   d0
    beq.b   .no_file
    ; file is present, read it
    lea scores_name(pc),a0    
    lea hiscore_table(pc),a1
    move.l #40,d0   ; size
    moveq.l #0,d1   ; offset
    jsr  (resload_LoadFileOffset,a2)
    bra.b	.update_highest
.standard
    move.l  _dosbase(pc),a6
    move.l  a0,d1
    move.l  #MODE_OLDFILE,d2
    jsr     (_LVOOpen,a6)
    move.l  d0,d1
    beq.b   .no_file
    move.l  d1,d4
    move.l  #4,d3
    move.l  #hiscore_table,d2
    jsr (_LVORead,a6)
    move.l  d4,d1
    jsr (_LVOClose,a6)
.update_highest
	move.l	hiscore_table(pc),high_score
.no_file
    rts


; < D0: command to send to cdtv 
send_cdtv_command:
	tst.l	_resload
	beq.b	.go
	rts		; not needed within whdload (and will fail)
.go
	movem.l	d0-a6,-(a7)
    move.l  d0,d5
    
	; alloc some mem for IORequest

	MOVEQ	#40,D0			
	MOVE.L	#MEMF_CLEAR|MEMF_PUBLIC,D1
	move.l	$4.W,A6
	jsr	_LVOAllocMem(a6)
	move.l	D0,io_request
	beq	.Quit

	; open cdtv.device

	MOVEA.L	D0,A1
	LEA	cdtvname(PC),A0	; name
	MOVEQ	#0,D0			; unit 0
	MOVE.L	D0,D1			; flags
	jsr	_LVOOpenDevice(a6)
	move.l	D0,D6
	ext	D6
	ext.l	D6
	bne	.Quit		; unable to open

    ; wait a while if CMD_STOP
    cmp.l   #CMD_STOP,d5
    bne.b   .nowait
	move.l	_dosbase(pc),A6
	move.l	#20,D1
	JSR	_LVODelay(a6)		; wait 2/5 second before launching
.nowait
	; prepare the IORequest structure

	MOVEQ	#0,D0
	MOVEA.L	io_request(pc),A0
	MOVE.B	D0,8(A0)
	MOVE.B	D0,9(A0)
	SUBA.L	A1,A1
	MOVE.L	A1,10(A0)
	MOVE.L	A1,14(A0)
	CLR.L	36(A0)

	move.l	io_request(pc),A0

	move.l	A0,A1
	move.w	d5,(IO_COMMAND,a1)
	move.l	$4.W,A6
	JSR		_LVODoIO(a6)

.Quit:
	; close cdtv.device if open

	tst.l	D6
	bne	.Free
	MOVE.L	io_request(pc),D1
	beq	.End
	move.l	D1,A1
	move.l	$4.W,A6
	jsr	_LVOCloseDevice(a6)

.Free:		
	; free the memory

	MOVEQ	#40,D0
	move.l	io_request(pc),A1
	move.l	$4.W,A6
	JSR		_LVOFreeMem(a6)
.End:
	movem.l	(a7)+,d0-a6
	rts
	
save_highscores
    tst.w   cheat_keys
    bne.b   .out
    tst.b   highscore_needs_saving
    beq.b   .out
    lea scores_name(pc),a0
    move.l  _resload(pc),d0
    beq.b   .standard
    move.l  d0,a2
    lea scores_name(pc),a0    
    lea hiscore_table(pc),a1
    move.l #4*NB_HIGH_SCORES,d0   ; size
    jmp  (resload_SaveFile,a2)
.standard
    move.l  _dosbase(pc),a6
    move.l  a0,d1
    move.l  #MODE_NEWFILE,d2
    jsr     (_LVOOpen,a6)
    move.l  d0,d1
    beq.b   .out
    move.l  d1,d4
    move.l  #40,d3
    move.l  #hiscore_table,d2
    jsr (_LVOWrite,a6)
    move.l  d4,d1
    jsr (_LVOClose,a6)    
.out
    rts
    ENDC
    
_dosbase
    dc.l    0
_gfxbase
    dc.l    0
_resload
    dc.l    0
io_request:
	dc.l	0
_keyexit
    dc.b    $59
scores_name
    dc.b    "scramble.high",0
cdtvname:
	dc.b	"cdtv.device",0
highscore_needs_saving
    dc.b    0
graphicsname:   dc.b "graphics.library",0
dosname
        dc.b    "dos.library",0
            even

    include ReadJoyPad.s
    
    ; variables
gfxbase_copperlist
    dc.l    0
    
previous_random
    dc.l    0
joystick_state
    dc.l    0
record_data_pointer
    dc.l    0
record_data_end
	dc.l	0
record_input_clock
    dc.w    0
previous_move
	dc.b	0
	even
    IFD    RECORD_INPUT_TABLE_SIZE
prev_record_joystick_state
    dc.l    0

    ENDC

white_color
	dc.w	0
yellow_color
	dc.w	0
	
current_state:
    dc.w    0

score_to_track:
    dc.l    0


; general purpose timer for non-game states (intro, game over...)
state_timer:
    dc.l    0
intro_text_message:
    dc.w    0



extra_life_sound_counter
    dc.w    0
extra_life_sound_timer
    dc.w    0
; 0: level 1
enemy_kill_timer
    dc.w    0
player_killed_timer:
    dc.w    -1
bonus_score_timer:
    dc.w    0
cheat_sequence_pointer
    dc.l    cheat_sequence

cheat_keys
    dc.w    0
death_frame_offset
    dc.w    0

enemy_kill_frame
    dc.w    0

stars_timer
	dc.w	0
stars_state_change_timer:
	dc.w	0
stars_on
	dc.b	0
stars_next_state:
	dc.b	0
	even
current_nb_colors:
	dc.w	0
base_x_pos:
	dc.w	0
current_palette
	dc.l	0
base_frame_counter:
	dc.w	0
base_frame_subcounter:
	dc.w	0
base_dest_address:
	dc.l	0
map_pointer
	dc.l	0
current_player:
	dc.l	player_1
scroll_offset
	dc.w	0
scroll_shift
	dc.w	0
playfield_palette_index
	dc.w	0
playfield_palette_timer
	dc.w	0
delayed_fx_countdown
	dc.w	0
delayed_fx
	dc.l	0
fuel:
	dc.w	0
low_fuel_sound_timer
	dc.w	0
fireball_sound_timer
	dc.w	0
mission_completed_countdown
	dc.w	0
enemy_hitbox_x_margin:
	dc.w	0
enemy_hitbox_y_margin:
	dc.w	0
enemy_hitbox_x_len:
	dc.w	0
enemy_hitbox_y_len:
	dc.w	0
draw_player_title_message:
	dc.b	0
play_start_music_message:
	dc.b	0
display_player_one_message
	dc.b	0
draw_tile_column_message
	dc.b	0
do_restart_game_message:
	dc.b	0
fuel_depletion_timer
	dc.b	0
fuel_depetion_current_timer:
	dc.b	0
update_fuel_message:
	dc.b	0
alive_timer
	dc.b	0
fast_game_over_flag:
	dc.b	0
rockets_fly_flag:
	dc.b	0
game_started_flag:
	dc.b	0
enemy_launch_cyclic_counter
	dc.b	0
game_completed_flag
	dc.b	0
new_life_restart:
    dc.b    0
next_level_flag:
	dc.b	0
music_playing:    
    dc.b    0
pause_flag
    dc.b    0
quit_flag
    dc.b    0
shoot_lock
	dc.b	0


invincible_cheat_flag
    dc.b    0
infinite_lives_cheat_flag
    dc.b    0
debug_flag
    dc.b    0
scroll_stop_flag
	dc.b	0
random_stop_flag
	dc.b	0
enemy_movement_stop_flag
	dc.b	0
demo_mode
    dc.b    0
no_fuel_depletion_flag
	dc.b	0
extra_life_awarded
    dc.b    0
music_played
    dc.b    0

    even


bonus_score_display_message:
    dc.w    0
extra_life_message:
    dc.w    0

flying_rocket_sprite_table:
	dc.l	flying_rocket_1,flying_rocket_2
mystery_sprite_table:
	dc.l	score_100,score_100,score_200,score_300

base_table
	dc.l	base_1,base_2,base_3
fireball_table:
	dc.l	fireball_1,fireball_2,fireball_3,fireball_4,fireball_3,fireball_2

player_kill_anim_table:
    REPT    ORIGINAL_TICKS_PER_SEC/2
    dc.b    0
    ENDR
    REPT    ORIGINAL_TICKS_PER_SEC/2
    dc.b    1
    ENDR
    REPT    ORIGINAL_TICKS_PER_SEC/2
    dc.b    2
    ENDR
    even
    
    even
    

cheat_sequence
    dc.b    $26,$18,$14,$22,0
    even



digits:
    incbin  "0.bin"
    incbin  "1.bin"
    incbin  "2.bin"
    incbin  "3.bin"
    incbin  "4.bin"
    incbin  "5.bin"
    incbin  "6.bin"
    incbin  "7.bin"
    incbin  "8.bin"
    incbin  "9.bin"
letters
    incbin	"A.bin"
    incbin	"B.bin"
    incbin	"C.bin"
    incbin	"D.bin"
    incbin	"E.bin"
    incbin	"F.bin"
    incbin	"G.bin"
    incbin	"H.bin"
    incbin	"I.bin"
    incbin	"J.bin"
    incbin	"K.bin"
    incbin	"L.bin"
    incbin	"M.bin"
    incbin	"N.bin"
    incbin	"O.bin"
    incbin	"P.bin"
    incbin	"Q.bin"
    incbin	"R.bin"
    incbin	"S.bin"
    incbin	"T.bin"
    incbin	"U.bin"
    incbin	"V.bin"
    incbin	"W.bin"
    incbin	"X.bin"
    incbin	"Y.bin"
    incbin	"Z.bin"    
exclamation
    incbin  "exclamation.bin"
slash
    incbin  "slash.bin"
dash
    incbin  "dash.bin"
dot
    incbin  "dot.bin"
quote
    incbin  "quote.bin"
qmark
    incbin  "qmark.bin"
copyright
    incbin  "copyright.bin"
	even
fuel_levels:
	dc.l	fl_0
	dc.l	fl_1
	dc.l	fl_2
	dc.l	fl_3
	dc.l	fl_4
	dc.l	fl_5
	dc.l	fl_6
	dc.l	fl_7
	
fl_0:
	incbin	"fuel_level_8.bin"
fl_1:
	incbin	"fuel_level_7.bin"
fl_2:
	incbin	"fuel_level_6.bin"
fl_3:
	incbin	"fuel_level_5.bin"
fl_4:
	incbin	"fuel_level_4.bin"
fl_5:
	incbin	"fuel_level_3.bin"
fl_6:
	incbin	"fuel_level_2.bin"
fl_7:
	incbin	"fuel_level_1.bin"
fl_8:
	incbin	"fuel_level_0.bin"	
space
    ds.b    8,0
    
high_score_string
	IFD	ARCADE_SCREEN_LAYOUT
    dc.b    "HIGH SCORE",0
	ELSE
    dc.b    "HIGH",0
	ENDC
pc_string
	dc.b	"   ",0
p1_string
    dc.b    "1UP",0
p2_string
    dc.b    "2UP",0
score_string
    dc.b    "     00",0
game_over_string
    dc.b    "GAME##OVER",0
player_one_string
    dc.b    "PLAYER ONE",0
one_button_control_text
	dc.b	"ONE BUTTON JOYSTICK",0
two_button_control_text
	dc.b	"TWO BUTTON JOYSTICK",0
	
player_one_string_clear
    dc.b    "          ",0



    even
ground_table:
	REPT	NB_BYTES_PER_PLAYFIELD_LINE
	dc.w	0
	dc.w	1,200-24-16,GROUND_TILE
	ENDR

    MUL_TABLE   40
    MUL_TABLE   NB_BYTES_PER_PLAYFIELD_LINE
    MUL_TABLE   NB_BYTES_PER_SCROLL_SCREEN_LINE
	
;square_table:
;	rept	256
;	dc.w	REPTN*REPTN
;	endr

; 6x4 moves
ship_sprite_table
	REPT	6
	dc.l	ship_1
	ENDR
	REPT	6
	dc.l	ship_2
	ENDR
	REPT	6
	dc.l	ship_3
	ENDR
	REPT	6
	dc.l	ship_4
	ENDR



	STRUCTURE	Sound,0
    ; matches ptplayer
    APTR    ss_data
    UWORD   ss_len
    UWORD   ss_per
    UWORD   ss_vol
    UBYTE   ss_channel
    UBYTE   ss_pri
    LABEL   Sound_SIZEOF
    
; < A0: sound struct
; < D0: ticks before triggering play
play_delayed_fx  
	move.w	d0,delayed_fx_countdown
	move.l	a0,delayed_fx
	rts
; < A0: sound struct
play_fx:
    tst.b   demo_mode
    bne.b   .no_sound
    lea _custom,a6
    bra _mt_playfx
.no_sound
    rts
play_fx_if_player_alive
	tst.w	player_killed_timer
	bmi.b	play_fx
	rts

; < D0: track start number
play_music:
	tst.b	demo_mode
	bne.b	.out
    movem.l d0-a6,-(a7)
    lea _custom,a6
    lea music,a0
    sub.l   a1,a1
    bsr _mt_init
    ; set master volume a little less loud
    move.w  #12,d0
    bsr _mt_mastervol
    bsr _mt_start
    st.b    music_playing
    movem.l (a7)+,d0-a6
.out
    rts
	
; < D0: if != 0 don't change sky color at all
next_playfield_palette:
	move.w	playfield_palette_index(pc),d1
	lea	playfield_palettes(pc),a0
	add.w	d1,a0
	tst		d0
	bne.b	.skip_background
	; load it
	; first color is different
	move.w	(a0),colors+2	; first color, in copperlist
.skip_background
	addq.w	#2,a0
	lea		_custom+color+2+16,a1
	move.w	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	; next
	addq.w	#8,d1
	cmp.w	#NB_PLAYFIELD_PALETTES*8,d1
	bne.b	.no_wrap
	clr.w	d1
.no_wrap
	move.w	d1,playfield_palette_index
	rts

    
    

    
       
;base addr, len, per, vol, channel<<8 + pri, loop timer, number of repeats (or -1), current repeat, current vbl

FXFREQBASE = 3579564
SOUNDFREQ = 22050

SOUND_ENTRY:MACRO
\1_sound
    dc.l    \1_raw
    dc.w    (\1_raw_end-\1_raw)/2,FXFREQBASE/\3,\4
    dc.b    \2
    dc.b    $01
    ENDM
    
    ; radix, ,channel (0-3)
    SOUND_ENTRY low_fuel,3,SOUNDFREQ,38
    SOUND_ENTRY player_killed,2,SOUNDFREQ,56
    SOUND_ENTRY rocket_explodes,3,SOUNDFREQ,40
    SOUND_ENTRY bomb_falling,2,SOUNDFREQ,17
    SOUND_ENTRY shoot,1,SOUNDFREQ,9
    SOUND_ENTRY bomb_hits_ground,2,SOUNDFREQ,64
    SOUND_ENTRY fireballs,3,SOUNDFREQ,4
	
	include	"blocks.s"

NB_PLAYFIELD_PALETTES = (end_playfield_palettes-playfield_palettes)/8
	even

playfield_palettes
	include	"playfield_palettes.s"
end_playfield_palettes

stars_palette
	include	"stars_palette.s"
end_stars_palette

menu_palette
    include "menu_palette.s"

objects_palette
	include	"objects_palette.s"
	
end_screen_palette
	include	"end_screen_palette.s"
	

	include	"tilemap.s"
    
	even
player_1:
    ds.b    Player_SIZEOF
player_2:
    ds.b    Player_SIZEOF

keyboard_table:
    ds.b    $100,0
bombs:
	ds.b	GfxObject_SIZEOF*MAX_NB_BOMBS
shots:
	ds.b	GfxObject_SIZEOF*MAX_NB_SHOTS
explosions:
	ds.b	GfxObject_SIZEOF*MAX_NB_EXPLOSIONS
mystery_scores:
	ds.b	GfxObject_SIZEOF*MAX_NB_SCORES
airborne_enemies:
	ds.b	GfxObject_SIZEOF*MAX_NB_AIRBORNE_ENEMIES


    
    
floppy_file
    dc.b    "floppy",0

    even

; table with 2 bytes: 60hz clock, 1 byte: move mask for the demo
demo_moves_1:
	incbin	"moves.bin"
demo_moves_1_end:
demo_moves_2:

demo_moves_2_end:
    even
	
; BSS --------------------------------------
    SECTION  S3,BSS
HWSPR_TAB_XPOS:	
	ds.l	512			

HWSPR_TAB_YPOS:
	ds.l	512
    

screen_ground_rocket_table
	ds.w	NB_BYTES_PER_PLAYFIELD_LINE
	
    IFD   RECORD_INPUT_TABLE_SIZE
record_input_table:
    ds.b    RECORD_INPUT_TABLE_SIZE
    ENDC
    
    

screen_tile_table
	ds.b	NB_LINES*NB_BYTES_PER_PLAYFIELD_LINE
    

    SECTION  S4,CODE
    include ptplayer.s

    SECTION  S5,DATA,CHIP



; main copper list
coplist

bitplanes:
	REPT	12
	dc.w	bplpt+REPTN*2,0
	ENDR

STAR_SPRITE_INDEX = 7
BLANKER_SPRITE_INDEX = 5

colors:
   dc.w color,0     ; fix black (so debug can flash color0)
   dc.w color+DYN_COLOR*2
   dc.w	$80D	; force magenta on color 4 (level filler)
   IFD	ARCADE_SCREEN_LAYOUT
   dc.b	$30+15+24
   ELSE
	dc.b	$30+15	; wait till we pass the purple rectangles
   ENDC
	dc.b	1
	dc.w	$FFFE   
	; and reset the color to what it was in the palette
   dc.w color+DYN_COLOR*2
dyn_color_reset:
	dc.w	$1c0     ; green or gray
end_color_copper:
   ; we don't need to set it here
   dc.w  bplcon1
bplcon1_value:
   dc.w		$0000            ;  BPLCON1 := 0x0000
   ; proper sprite priority: below bitplanes for the stars effect
   dc.w  bplcon2,$0000            ;  BPLCON2


sprites:

;scroll_mask_sprite
;    dc.w    spr+sd_SIZEOF*BLANKER_SPRITE_INDEX+sd_ctl,0
;    dc.w    spr+sd_SIZEOF*BLANKER_SPRITE_INDEX+sd_pos,0
;    dc.w    spr+sd_SIZEOF*BLANKER_SPRITE_INDEX+sd_dataa,-1
;    dc.w    spr+sd_SIZEOF*BLANKER_SPRITE_INDEX+sd_dataB,0
;	dc.w	color+(BLANKER_SPRITE_INDEX/2)*8+34,$0	; black color
	
stars_sprites_copperlist:
	REPT	NB_STAR_LINES
	dc.b	$2C+REPTN*4+2
	dc.b	1
	dc.w	$FFFE
    ; we use sprite #7 (last) for the stars, multiplexing it
	dc.w	color+(STAR_SPRITE_INDEX/2)*8+34,$F00	; 4
    dc.w    spr+sd_SIZEOF*STAR_SPRITE_INDEX+sd_ctl,0 ; 16
    dc.w    spr+sd_SIZEOF*STAR_SPRITE_INDEX+sd_pos,0 ; 20
	; sprite pattern
    dc.w    spr+sd_SIZEOF*STAR_SPRITE_INDEX+sd_dataa,$8000	; 24
    dc.w    spr+sd_SIZEOF*STAR_SPRITE_INDEX+sd_dataB,$0000	; 28
 	dc.b	$2C+REPTN*4+3	; 32
	dc.b	1
	dc.w	$FFFE
    dc.w    spr+sd_SIZEOF*7+sd_dataa,0	; 36
    dc.w    spr+sd_SIZEOF*7+sd_dataB,0	; 40	
	ENDR
end_stars_sprites_copperlist
	;;dc.b	$2C+(NB_STAR_LINES-1)*4+2,1
	 
   IFND	ARCADE_SCREEN_LAYOUT
   dc.w color+DYN_COLOR*2,$00E     ; blue (fuel)
   ENDC

   dc.w  $FFDF,$FFFE            ; PAL wait (256)
   dc.w  $2001,$FFFE            ; PAL extra wait (around 288)
   IFD	ARCADE_SCREEN_LAYOUT
   dc.w color+DYN_COLOR*2,$00E     ; blue (fuel)
   ENDC
   dc.w intreq,$8010            ; generate copper interrupt
    dc.l    -2				; end of copperlist


empty_16x16_bob
    ds.l    16*3,0
	; full mask (following bob or used alone to debug)
full_mask
	REPT	16
	dc.l	-1
	ENDR
	
lives:
    incbin  "life.bin"

mission_flag
	incbin	"mission_flag.bin"
	
enemies_1
	incbin	"enemies_1.bin"
enemies_2
	incbin	"enemies_2.bin"
	
ship_1:
	incbin	"ship_1.bin"
ship_2:
	incbin	"ship_2.bin"
ship_3:
	incbin	"ship_3.bin"
ship_4:
	incbin	"ship_4.bin"

bomb_1:
	incbin	"bomb_1.bin"
bomb_2:
	incbin	"bomb_2.bin"
bomb_3:
	incbin	"bomb_3.bin"
bomb_4:
	incbin	"bomb_4.bin"
bomb_5:
	incbin	"bomb_5.bin"
	
	
fireball_1:
	incbin	"fireball_1.bin"
fireball_2:
	incbin	"fireball_2.bin"
fireball_3:
	incbin	"fireball_3.bin"
fireball_4:
	incbin	"fireball_4.bin"
	
flying_rocket_1:
	incbin	"rocket_1.bin"
flying_rocket_2:
	incbin	"rocket_2.bin"
flying_rocket_mask
	ds.w	64,0	; 2 empty planes, then mask
	incbin	"rocket_mask.bin"

FULL_16X16_MASK:MACRO
	REPT	16
	dc.l	-1
	ENDR
	ENDM
	
base_1:
	incbin	"boss_1.bin"
	FULL_16X16_MASK
base_2:
	incbin	"boss_2.bin"
	FULL_16X16_MASK
base_3:
	incbin	"boss_3.bin"
	FULL_16X16_MASK
		
score_100
	incbin	"score_100.bin"
score_200
	incbin	"score_200.bin"
score_300
	incbin	"score_300.bin"
	
ship_explosion_1:
	incbin	"ship_explosion_1.bin"
ship_explosion_2:
	incbin	"ship_explosion_2.bin"
ship_explosion_3:
	incbin	"ship_explosion_3.bin"
ship_explosion_4:
	incbin	"ship_explosion_4.bin"
	
explosion_1:
	incbin	"explosion_1.bin"
explosion_2:
	incbin	"explosion_2.bin"
explosion_3:
	incbin	"explosion_3.bin"
explosion_4:
	incbin	"explosion_4.bin"
explosion_5:
	incbin	"explosion_5.bin"
explosion_6:
	incbin	"explosion_6.bin"
explosion_7:
	incbin	"explosion_7.bin"
explosion_8:
	incbin	"explosion_8.bin"
	
ufo:
	incbin	"ufo.bin"
	
level_number_tiles:
	incbin	"levels_1b_0.bin"
	incbin	"levels_25_0.bin"
	incbin	"levels_25_1.bin"
	incbin	"levels_25_2.bin"
	incbin	"levels_25_3.bin"
	incbin	"levels_1b_1.bin"
	
purple_level_mark
	incbin	"purple_level_mark.bin"

red_level_mark
	incbin	"red_level_mark.bin"

; sounds
low_fuel_raw
    incbin  "low_fuel.raw"
    even
low_fuel_raw_end

player_killed_raw
    incbin  "player_killed.raw"
    even
player_killed_raw_end

rocket_explodes_raw
    incbin  "rocket_explodes.raw"
    even
rocket_explodes_raw_end

bomb_falling_raw
    incbin  "bomb_falling.raw"
    even
bomb_falling_raw_end

fireballs_raw
    incbin  "fireballs.raw"
    even
fireballs_raw_end


shoot_raw
    incbin  "shoot.raw"
    even
shoot_raw_end

bomb_hits_ground_raw
    incbin  "bomb_hits_ground.raw"
    even
bomb_hits_ground_raw_end

; end sounds

star_sprite:
	dc.l	-1
	dc.w	0
	dc.l	0
	
empty_sprite
    dc.l    0,0


	
music
	incbin	"scramble_intro.mod"
	
    SECTION S_4,BSS,CHIP

screen_data:
    ds.b    SCREEN_PLANE_SIZE*NB_PLANES,0
	; scroll data has only 2 planes (4 colors)
	; except when used to display the enemies, lets leave it to 3 planes
scroll_data
	ds.b	SCROLL_PLANE_SIZE*NB_PLANES,0
scroll_data_end

    	