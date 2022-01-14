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

    STRUCTURE   SpritePalette,0
    UWORD   color0
    UWORD   color1
    UWORD   color2
    UWORD   color3
    LABEL   SpritePalette_SIZEOF
    
	STRUCTURE	Character,0
    ULONG   character_id
	UWORD	xpos
	UWORD	ypos
    UWORD   h_speed
    UWORD   v_speed
	UWORD	direction   ; sprite orientation
    UWORD   frame
    UWORD   turn_lock
	LABEL	Character_SIZEOF

	STRUCTURE	Player,0
	STRUCT      BaseCharacter1,Character_SIZEOF
    UWORD   prepost_turn
    LABEL   Player_SIZEOF
    
	STRUCTURE	Enemy,0
	STRUCT      BaseCharacter2,Character_SIZEOF
	STRUCT      palette,SpritePalette_SIZEOF
    APTR     frame_table
    APTR     copperlist_address
    APTR     color_register
    UWORD   speed_table_index
    UWORD   previous_xpos
    UWORD   previous_ypos
    UWORD   score_frame
	UWORD	respawn_delay
    UWORD    mode_timer     ; number of 1/50th to stay in the current mode (thief only)
    UWORD    mode           ; current mode
    UWORD    previous_mode           ; previous mode
    UWORD    score_display_timer
    UWORD    fall_hang_timer
    UWORD    fall_hang_toggle
	UBYTE	 fright_mode
	UBYTE	 pad
	LABEL	 Enemy_SIZEOF
    
    ;Exec Library Base Offsets


;graphics base

StartList = 38

Execbase  = 4

MODE_NORMAL = 0     ; police/cattle only. normal amidar movement
MODE_KILL = 1<<2


; ******************** start test defines *********************************

; ---------------debug/adjustable variables

; if set skips intro, game starts immediately
;DIRECT_GAME_START

; enemies not moving/no collision detection
;NO_ENEMIES

;HIGHSCORES_TEST

;START_NB_LIVES = 1
;START_SCORE = 1000/10
;START_LEVEL = 2

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
EXTRA_LIFE_SCORE = 3000/10
EXTRA_LIFE_PERIOD = 7000/10
DEFAULT_HIGH_SCORE = 10000/10
	ELSE
EXTRA_LIFE_SCORE = 30000/10
EXTRA_LIFE_PERIOD = 70000/10
DEFAULT_HIGH_SCORE = 10000/10
	ENDC
NB_HIGH_SCORES = 10
	
	IFND	START_SCORE
START_SCORE = 0
	ENDC
	IFND	START_NB_LIVES
START_NB_LIVES = 3+1
	ENDC
	IFND	START_LEVEL
START_LEVEL = 1
	ENDC
	
NB_RECORDED_MOVES = 100

; --------------- end debug/adjustable variables

; actual nb ticks (PAL)
NB_TICKS_PER_SEC = 50
; game logic ticks
ORIGINAL_TICKS_PER_SEC = 60


NB_BYTES_PER_LINE = 40
NB_BYTES_PER_MAZE_LINE = 26
BOB_16X16_PLANE_SIZE = 64
BOB_8X8_PLANE_SIZE = 16
MAZE_PLANE_SIZE = NB_BYTES_PER_LINE*NB_LINES
NB_LINES = 31*8
SCREEN_PLANE_SIZE = 40*NB_LINES
NB_PLANES   = 4

NB_TILES_PER_LINE = NB_BYTES_PER_MAZE_LINE
NB_TILE_LINES = 27
MAZE_HEIGHT = NB_TILES_PER_LINE*8
MAZE_ADDRESS_OFFSET = 6*NB_BYTES_PER_LINE+1
INTRO_MAZE_HEIGHT = 14*8-2
INTRO_MAZE_ADDRESS_OFFSET = 72*NB_BYTES_PER_LINE+1
BONUS_MAZE_ADDRESS_OFFSET = 14*NB_BYTES_PER_LINE+1

Y_MAX = MAZE_HEIGHT
X_MAX = (NB_BYTES_PER_MAZE_LINE-1)*8

STARS_OFFSET = NB_BYTES_PER_MAZE_LINE-4+(NB_BYTES_PER_LINE)*(MAZE_HEIGHT+18)

; maybe too many slots...
NB_ROLLBACK_SLOTS = 80
; messages from update routine to display routine
MSG_NONE = 0
MSG_SHOW = 1
MSG_HIDE = 2


PLAYER_KILL_TIMER = ORIGINAL_TICKS_PER_SEC*2
ENEMY_KILL_TIMER = ORIGINAL_TICKS_PER_SEC*2
GAME_OVER_TIMER = ORIGINAL_TICKS_PER_SEC*3

; direction enumerates, follows order of enemies in the sprite sheet
RIGHT = 0
LEFT = 1<<2
UP = 2<<2
DOWN = 3<<2
; one extra enumerate for fire (demo mode)
FIRE = 4

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
STATE_BONUS_SCREEN = 2*4
STATE_NEXT_LEVEL = 3*4
STATE_LIFE_LOST = 4*4
STATE_INTRO_SCREEN = 5*4
STATE_GAME_START_SCREEN = 6*4


; offset for enemy animations

JUMP_FIRST_FRAME = police1_jump_frame_table-police1_frame_table
HANG_FIRST_FRAME = police1_hang_frame_table-police1_frame_table
KILL_FIRST_FRAME = police1_kill_frame_table-police1_frame_table
FALL_FIRST_FRAME = police1_fall_frame_table-police1_frame_table
CRASH_FIRST_FRAME = FALL_FIRST_FRAME+8
SCORE_FIRST_FRAME = police1_score_frame_table-police1_frame_table

; jump table macro, used in draw and update
DEF_STATE_CASE_TABLE:MACRO
    move.w  current_state(pc),d0
    lea     .case_table(pc),a0
    move.l     (a0,d0.w),a0
    jmp (a0)
    
.case_table
    dc.l    .playing
    dc.l    .game_over
    dc.l    .bonus_screen
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
    beq.b   .startup
    
    ; "floppy" file found
    jsr     _LVOClose(a6)
    ; wait 2 seconds for floppy drive to switch off
    move.l  #100,d1
    jsr     _LVODelay(a6)
.startup

    lea  _custom,a5
    move.b  #0,controller_joypad_1
    

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
    ; uncomment to test demo mode right now
    ;;st.b    demo_mode
    ENDC
    
    move.w  #-1,high_score_position

    bsr init_sound
    
    ; shut off dma
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    move.w  #$7FFF,(intreq,a5)
    move.w #$03E0,dmacon(A5)

    bsr init_interrupts
    ; intro screen
    
    
    moveq #NB_PLANES-1,d4
    lea	bitplanes,a0              ; adresse de la Copper-List dans a0
    move.l #screen_data,d1
    move.w #bplpt,d3        ; premier registre dans d3

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
    add.l #SCREEN_PLANE_SIZE,d1       ; next plane of maze

    dbf d4,.mkcl
    

    lea game_palette,a0
    lea _custom+color,a1
    move.w  #31,d0
.copy
    move.w  (a0)+,(a1)+
    dbf d0,.copy
;COPPER init
		
    move.l	#coplist,cop1lc(a5)
    clr.w copjmp1(a5)

;playfield init

    move.w #$3081,diwstrt(a5)             ; valeurs standard pour
    move.w #$30C1,diwstop(a5)             ; la fenêtre écran
    move.w #$0038,ddfstrt(a5)             ; et le DMA bitplane
    move.w #$00D0,ddfstop(a5)
    move.w #$4200,bplcon0(a5) ; 4 bitplanes
    clr.w bplcon1(a5)                     ; no scrolling
    clr.w bplcon2(a5)                     ; pas de priorité
    move.w #0,bpl1mod(a5)                ; modulo de tous les plans = 40
    move.w #0,bpl2mod(a5)

intro:
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    move.w  #$7FFF,(intreq,a5)

    
    bsr hide_sprites

    bsr clear_screen
    
    bsr draw_score

    clr.l  state_timer
    clr.w  vbl_counter

   
    bsr wait_bof
    ; init sprite, bitplane, whatever dma
    move.w #$83E0,dmacon(a5)
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
    beq.b   .intro_loop
    clr.b   demo_mode
.out_intro    


    clr.l   state_timer
    move.w  #STATE_GAME_START_SCREEN,current_state
    
.release
    move.l  joystick_state(pc),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .release

    tst.b   demo_mode
    bne.b   .no_credit
    lea credit_sound(pc),a0
    bsr play_fx

.game_start_loop
    bsr random      ; so the enemies aren't going to do the same things at first game
    move.l  joystick_state(pc),d0
    tst.b   quit_flag
    bne.b   .out
    btst    #JPB_BTN_RED,d0
    beq.b   .game_start_loop

.no_credit

.wait_fire_release
    move.l  joystick_state(pc),d0
    btst    #JPB_BTN_RED,d0
    bne.b   .wait_fire_release    
.restart    
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)
    
    bsr init_new_play

.new_level  
    bsr clear_screen
    bsr draw_score    
    bsr init_level
    lea _custom,a5
    move.w  #$7FFF,(intena,a5)

    bsr wait_bof
    
    bsr draw_score
    tst.b   next_level_is_bonus_level
    beq.b   .normal_level

    bsr init_player     ; at least reset 3 stars

    bsr wait_bof

    move.w  #STATE_BONUS_SCREEN,current_state
    move.w #INTERRUPTS_ON_MASK,intena(a5)
    
    bra.b   .mainloop
.normal_level    
    ; for debug
    ;;bsr draw_bounds
    
    bsr hide_sprites
    move.w  level_number(pc),d0


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

    tst.b   new_life_restart

    move.w  level_number(pc),d0
    btst    #0,d0
    
    bsr draw_lives
    bsr draw_fuel
    move.w  #STATE_PLAYING,current_state
    move.w #INTERRUPTS_ON_MASK,intena(a5)
.mainloop
    tst.b   quit_flag
    bne.b   .out
    DEF_STATE_CASE_TABLE
    
.game_start_screen
.intro_screen       ; not reachable from mainloop
    bra.b   intro
.bonus_screen
.playing
    bra.b   .mainloop

.game_over
    bra.b   .mainloop
.next_level
    add.w   #1,level_number
    bra.b   .new_level
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
    move.w  #STATE_GAME_OVER,current_state
    move.l  #1,state_timer
    bra.b   .game_over
.no_demo
   
    tst.b   infinite_lives_cheat_flag
    bne.b   .new_life
    subq.b   #1,nb_lives
    bne.b   .new_life

    ; game over: check if score is high enough 
    ; to be inserted in high score table
    move.l  score(pc),d0
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
    move.l  #GAME_OVER_TIMER,state_timer
    move.w  #STATE_GAME_OVER,current_state
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
    bsr     restore_interrupts
    bsr     wait_blit
    bsr     finalize_sound
    bsr     save_highscores

    lea _custom,a5
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
    move.w  #NB_BYTES_PER_MAZE_LINE/4-1,d0
.cl
    clr.l   (a1)+
    dbf d0,.cl
    add.w   #NB_BYTES_PER_LINE-NB_BYTES_PER_MAZE_LINE,a1
    dbf d1,.c0
    movem.l (a7)+,d0-d1/a1
    rts
    
clear_screen
    lea screen_data,a1
    moveq.l #3,d0
.cp
    move.w  #(NB_BYTES_PER_LINE*NB_LINES)/4-1,d1
    move.l  a1,a2
.cl
    clr.l   (a2)+
    dbf d1,.cl
    add.l   #SCREEN_PLANE_SIZE,a1
    dbf d0,.cp
    rts


clear_playfield_planes
    lea screen_data,a1
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bsr clear_playfield_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bra clear_playfield_plane
    
; < A1: plane start
clear_playfield_plane
    movem.l d0-d1/a0-a1,-(a7)
    move.w #NB_LINES-1,d0
.cp
    move.w  #NB_BYTES_PER_MAZE_LINE/4-1,d1
    move.l  a1,a0
.cl
    clr.l   (a0)+
    dbf d1,.cl
    clr.w   (a0)
    add.l   #NB_BYTES_PER_LINE,a1
    dbf d0,.cp
    movem.l (a7)+,d0-d1/a0-a1
    rts

clear_maze
    lea screen_data,a1
    bsr clear_maze_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bsr clear_maze_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bsr clear_maze_plane
    add.w   #SCREEN_PLANE_SIZE,a1
    bra clear_maze_plane
    
; < A1: plane start
clear_maze_plane
    movem.l d0-d1/a0-a1,-(a7)
    add.w   #NB_BYTES_PER_LINE*4,a1
    move.w #MAZE_HEIGHT+7+6,d0
.cp
    move.w  #NB_BYTES_PER_MAZE_LINE/4,d1
    move.l  a1,a0
.cl
    clr.l   (a0)+
    dbf d1,.cl
    add.l   #NB_BYTES_PER_LINE,a1
    dbf d0,.cp
    movem.l (a7)+,d0-d1/a0-a1
    rts

    
init_new_play:
	clr.b	previous_move
    clr.l   state_timer
    IFD BONUS_SCREEN_TEST
    st.b	next_level_is_bonus_level
    ELSE
    clr.b   next_level_is_bonus_level
    ENDC
 
    move.b  #START_NB_LIVES,nb_lives
    clr.b   new_life_restart
    clr.b   extra_life_awarded
    clr.b    music_played
    move.l  #EXTRA_LIFE_SCORE,score_to_track
    move.w  #START_LEVEL-1,level_number
 
    ; global init at game start
	
	tst.b	demo_mode
	beq.b	.no_demo
	; toggle demo
	move.w	#START_LEVEL-1,level_number
	btst	#0,d0
	lea		demo_moves_1,a0
	lea		demo_moves_1_end,a1
.rset
	move.l	a0,record_data_pointer
	move.l	a1,record_data_end

	
.no_demo
    clr.b   bonus_sprites
    move.l  #START_SCORE,score
    clr.l   previous_score
    clr.l   displayed_score
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
    
; draw score with titles and extra 0
draw_score:
    lea p1_string(pc),a0
    move.w  #232,d0
    move.w  #16,d1
    move.w  #$FF,d2
    bsr write_color_string
    lea score_string(pc),a0
    move.w  #$FFF,d2
    move.w  #232,d0
    add.w  #8,d1
    bsr write_color_string
    
    move.w  #$FF,d2
    lea high_score_string(pc),a0
    move.w  #232,d0
    move.w  #48,d1
    bsr write_color_string
    
    ; extra 0
    move.w  #$FFF,d2
    lea score_string(pc),a0
    move.w  #232,d0
    add.w  #8,d1
    bsr write_color_string

    move.l  score(pc),d2
    bsr     draw_current_score
    
    move.l  high_score(pc),d2
    bsr     draw_high_score

    lea level_string(pc),a0
    move.w  #232,d0
    move.w  #48+24,d1
    move.w  #$FF,d2
    bsr write_color_string

    moveq.l #1,d2
    add.w  level_number(pc),d2
    move.w  #232+48,d0
    move.w  #48+24+8,d1
    move.w  #3,d3
    move.w  #$FFF,d4
    bra write_color_decimal_number

    rts
    
; < D2 score
; trashes D0-D3
draw_current_score:
    move.w  #232+16,d0
    move.w  #24,d1
    move.w  #6,d3
    move.w  #$FFF,d4
    bra write_color_decimal_number
    
    
hide_sprites:
    moveq.w  #7,d1
    lea  sprites,a0
    lea empty_sprite,a1
.emptyspr

    move.l  a1,d0
    bsr store_sprite_copperlist
    addq.l  #8,a0
    dbf d1,.emptyspr
    rts


store_sprite_copperlist    
    move.w  d0,(6,a0)
    swap    d0
    move.w  d0,(2,a0)
    rts

		
init_enemies
    move.b  d0,d4
	


    
    rts


init_player:
	clr.w	leaving_paint_tile_x
	clr.w	leaving_paint_tile_y
    clr.l   previous_valid_direction
    clr.w   death_frame_offset
	
    tst.b   new_life_restart
    bne.b   .no_clear
    clr.l   previous_player_address   ; no previous position
.no_clear
    lea player(pc),a0

    
    move.w  #NB_TILES_PER_LINE*4-2,xpos(a0)
	move.w	#Y_MAX,ypos(a0)
    
    ;move.w  #0*4,xpos(a0)
	;move.w	#192,ypos(a0)
    
    
	move.w 	#LEFT,direction(a0)

    clr.w  speed_table_index(a0)
    move.w  #-1,h_speed(a0)
    clr.w   v_speed(a0)
    clr.w   prepost_turn(a0)
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
    

    move.w  #-1,player_killed_timer
    clr.w   next_enemy_iteration_score
    clr.w   fright_timer    
    move.b  #3,nb_stars
    move.w  #-1,jump_index
    move.w  #JUMP_FIRST_FRAME,jump_frame
    
    rts
    	    

    
DEBUG_X = 8     ; 232+8
DEBUG_Y = 8

ghost_debug
    lea enemies(pc),a2
    move.w  #DEBUG_X,d0
    move.w  #DEBUG_Y+100,d1
    lea	screen_data+SCREEN_PLANE_SIZE*3,a1 

    bsr .debug_ghost

    move.w  #DEBUG_X,d0
    add.w  #8,d1
    lea .elroy(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.l  a2,a0

    
;    move.w  #DEBUG_X,d0
;    add.w  #8,d1
;    lea .dir(pc),a0
;    bsr write_string
;    lsl.w   #3,d0
;    add.w  #DEBUG_X,d0
;    clr.l   d2
;    move.w  direction(a2),d2
;    move.w  #0,d3
;    bsr write_decimal_number
;
;    move.w  #DEBUG_X,d0
;    add.w  #8,d1
;    lea .pdir(pc),a0
;    bsr write_string
;    lsl.w   #3,d0
;    add.w  #DEBUG_X,d0
;    clr.l   d2
;    move.w  possible_directions,d2
;    move.w  #4,d3
;    bsr write_hexadecimal_number
    rts
.debug_ghost
    rts
    
.mode
        dc.b    "MODE ",0

.elroy:
    dc.b    "ELROY ",0

.gx
        dc.b    "GX ",0
.gy
        dc.b    "GY ",0
        even

        
draw_debug
    lea player(pc),a2
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
    ;;
    add.w  #8,d1
    lea .ph(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w previous_valid_direction(pc),d2
    move.w  #5,d3
    bsr write_decimal_number
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .pv(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w previous_valid_direction+2(pc),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0
	
        IFEQ    1
    add.w  #8,d1
    lea .tx(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w xpos+enemies(pc),d2
    move.w  #5,d3
    bsr write_decimal_number
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .ty(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w ypos+enemies(pc),d2
    move.w  #3,d3
    bsr write_decimal_number
    move.l  d4,d0
    ENDC
    ;;
    ;;
    add.w  #8,d1
    lea .ato(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w  attack_timeout(pc),d2
    move.w  #4,d3
    bsr write_decimal_number
	
    add.w  #8,d1
    lea .pmi(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w  player_move_index(pc),d2
    move.w  #4,d3
    bsr write_decimal_number
    move.w  #DEBUG_X,d0
    add.w  #8,d1
    move.l  d0,d4
    lea .tmi(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w thief_move_index(pc),d2
    move.w  #4,d3
    bsr write_decimal_number
    move.l  d4,d0
    
    add.w  #8,d1
    lea .diff(pc),a0
    bsr write_string
    lsl.w   #3,d0
    add.w  #DEBUG_X,d0
    clr.l   d2
    move.w  player_move_index(pc),d2
    sub.w thief_move_index(pc),d2
    move.w  #4,d3
    bsr write_decimal_number
    move.l  d4,d0
    ;;

    clr.l   d2

    rts
    
.px
        dc.b    "PX ",0
.py
        dc.b    "PY ",0
.ph
		dc.b	"PREVH ",0
.pv
		dc.b	"PREVV ",0
.ato
		dc.b "ATO ",0
.tx
        dc.b    "TX ",0
.ty
        dc.b    "TY ",0

.pmi
        dc.b    "PMI ",0
.tmi
        dc.b    "TMI ",0
.diff
        dc.b    "DIFF ",0
.bottom_rect_string
        dc.b    "R2 20 ",0
.bonus
        dc.b    "BT ",0
.dottable:
        dc.b    "DOTS ",0
.nbrects
		dc.b	"NBRECTS ",0
        even

draw_enemies:
    lea enemies(pc),a0
    move.w  nb_enemies_but_thief(pc),d7   ; +thief
.gloop
    bsr .draw_enemy
.next_ghost_iteration
    add.l   #Enemy_SIZEOF,a0
    dbf d7,.gloop
    
    rts

.eyes
 

    bra.b   .end_anim

.draw_enemy
    move.w  xpos(a0),d0
    addq.w  #1,d0       ; compensate
    move.w  ypos(a0),d1
    addq.w  #3,d1   ; compensate
    ; center => top left
    bsr store_sprite_pos

    ; we cannot have white color for score
    ; that would trash the other enemy
    ;;move.w  #$00ff,_custom+color+32+8+2

    move.w  mode(a0),d3 ; normal/chase/fright/fall..
    IFD     DEBUG_MODE
    cmp.w   #MODE_LAST_ITEM,d3
    bcs.b   .in_range
    blitz
    illegal
.in_range
    ENDC
    lea     palette(a0),a2      ; normal ghost colors
    lea     .jump_table(pc),a1
    move.l  (a1,d3.w),a1
    jmp     (a1)
    
.draw_hang
    addq.w  #8,d1   ; compensate
    move.w  fall_hang_toggle(a0),d2
    add.w   #HANG_FIRST_FRAME,d2
    bra.b   .get_frame
.draw_fall
    move.w  fall_hang_toggle(a0),d2
    add.w   #FALL_FIRST_FRAME,d2
    bra.b   .get_frame
.draw_crash
    move.w  fall_hang_toggle(a0),d2
    add.w   #CRASH_FIRST_FRAME,d2
    bra.b   .get_frame
.draw_jump
    ; choose the frame among jump/hang/fall
    move.w  jump_frame(pc),d2
    bra.b   .get_frame
.draw_killed
    move.w  score_frame(a0),d2
    bra.b   .get_frame
.draw_kill
    move.w  enemy_kill_frame(pc),d2
    bra.b   .get_frame
.draw_normal
    move.w  frame(a0),d2
    
    lsr.w   #2,d2   ; 8 divide to get 0,1
    bclr    #0,d2   ; even
    add.w   d2,d2       ; times 2
.end_anim

.get_frame
    move.l  frame_table(a0),a1
    ; get proper frame from proper frame set
    move.l  (a1,d2.w),a1
    ; now if D6 is non-zero, handle shift
.store_sprite_pos
    move.l  d0,(a1)     ; store control word
    move.l  a1,d2    
    move.l  copperlist_address(a0),a1
    move.w  d2,(6,a1)
    swap    d2
    move.w  d2,(2,a1)    
    rts
.jump_table
    dc.l    .draw_normal
    dc.l    .draw_normal
    dc.l    .draw_normal
    dc.l    .draw_normal
    dc.l    .draw_hang
    dc.l    .draw_fall
    dc.l    .draw_jump
    dc.l    .draw_kill
    dc.l    .draw_killed
    dc.l    .draw_crash
    
     
draw_all
    DEF_STATE_CASE_TABLE

; draw intro screen
.intro_screen
    bra.b   draw_intro_screen
; draw bonus screen
.bonus_screen
    tst.w   bonus_text_screen_countdown
    beq.b   .maze_part
    bsr     hide_sprites
    move.w  #72,d0
    move.w  #40,d1
    lea     .bonus_stage_text(pc),a0
    move.w  #$FF,d2
    bsr     write_color_string
    move.w  #80,d0
    move.w  #96,d1
    lea     .5000_points_text(pc),a0
    move.w  #$FF0,d2
    bsr     write_color_string
    move.w  #48,d0
    move.w  #136,d1
    lea     .push_jump_button_text(pc),a0
    move.w  #$F0,d2
    bsr     write_color_string
    ; banana sprite at x=60
    move.w  #60,d0
    move.w  #96,d1
    bsr store_sprite_pos



    bsr draw_lives
    bsr draw_fuel
.skip_draw
    rts
.maze_part
    cmp.l   #1,state_timer      ; init done at first tick of update_intro_screen
    
    ; draw cattle
    lea enemies+Enemy_SIZEOF(pc),a0
    move.w  xpos(a0),d0
    add.w   #1,d0
    move.w  ypos(a0),d1
    add.w   #3-4,d1
    bsr store_sprite_pos
    
    
    move.l  d2,d0
    
    ; change sprite to first cattle jump
    lea cattle1_jump_0,a1
    bra.b  .store_cw
.lost
    lea cattle1_hang_1,a1
    ; change sprite to second cattle hang
    bra.b  .store_cw
.normal
    move.l  frame_table(a0),a1
    move.w  frame(a0),d2
    lsr.w   #2,d2   ; 8 divide to get 0,1
    bclr    #0,d2   ; even
    add.w   d2,d2       ; times 2

    ; get proper frame from proper frame set
    move.l  (a1,d2.w),a1

.store_cw
    move.l  d0,(a1)     ; store control word
    move.l  a1,d0
    lea intro_cattle_pink,a0
    bra store_sprite_copperlist

	
    
.bonus_stage_text
    dc.b    "BONUS  STAGE",0
.5000_points_text
    dc.b    ".... 5000 PTS",0
.push_jump_button_text:
    dc.b    "PUSH JUMP  BUTTON",0
    even
    
.game_start_screen
    tst.l   state_timer
    beq.b   draw_start_screen
    rts
    
.life_lost
.next_level

    ; don't do anything
    rts
PLAYER_ONE_X = 72
PLAYER_ONE_Y = 102-14

    
.game_over
    cmp.l   #GAME_OVER_TIMER,state_timer
    bne.b   .draw_complete
    bsr hide_sprites
    bsr clear_maze

    move.w  #72,d0
    move.w  #136,d1
    move.w  #$0f00,d2   ; red
    lea player_one_string(pc),a0
    bsr write_color_string
    move.w  #72,d0
    add.w   #16,d1
    lea game_over_string(pc),a0
    bsr write_color_string
    
    bra.b   .draw_complete
.playing
    tst.b   delete_last_star_message
    beq.b   .no_del_star
    bsr delete_last_star
    clr.b   delete_last_star_message
.no_del_star

    bsr draw_player
    bsr draw_enemies
   
    
.after_draw
        
    ; timer not running, animate

    cmp.w   #MSG_SHOW,extra_life_message
    bne.b   .no_extra_life
    clr.w   extra_life_message
    bsr     draw_last_life
.no_extra_life


    ; score
    lea	screen_data+SCREEN_PLANE_SIZE*3,a1  ; white
    
    move.l  score(pc),d0
    move.l  displayed_score(pc),d1
    cmp.l   d0,d1
    beq.b   .no_score_update
    
    move.l  d0,displayed_score

    move.l  d0,d2
    bsr draw_current_score
    
    ; handle highscore in draw routine eek
    move.l  high_score(pc),d4
    cmp.l   d2,d4
    bcc.b   .no_score_update
    
    move.l  d2,high_score
    bsr draw_high_score
.no_score_update
.draw_complete
    rts

stop_sounds

    lea _custom,a6
    clr.b   music_playing
    bra _mt_end



; < D2: highscore
draw_high_score
    move.w  #232+16,d0
    move.w  #24+32,d1
    move.w  #6,d3
    move.w  #$FFF,d4    
    bra write_color_decimal_number


    
; < D0: score (/10)
; trashes: D0,D1
add_to_score:
	tst.b	demo_mode
	bne.b	.below
    move.l  score(pc),previous_score

    add.l   d0,score
    move.l  score_to_track(pc),d1
    ; was below, check new score
    cmp.l   score(pc),d1    ; is current score above xtra life score
    bcc.b   .below        ; not yet
    ; above next extra life score
    cmp.l   previous_score(pc),d1
    bcs.b   .below
    
    add.l   #EXTRA_LIFE_PERIOD,d1
    move.l  d1,score_to_track
    
    move.w  #MSG_SHOW,extra_life_message
    addq.b   #1,nb_lives
	move.l	a0,d1	; save A0
    lea     extra_life_sound,a0
    bsr play_fx
	move.l	d1,a0	; restore A0
.below
    rts
    
random:
    move.l  previous_random(pc),d0
	;;; EAB simple random generator
    ; thanks meynaf
    mulu #$a57b,d0
    addi.l #$bb40e62d,d0
    rol.l #6,d0
    move.l  d0,previous_random
    rts

    
draw_start_screen
    bsr hide_sprites
    bsr clear_screen
    
    bsr draw_title
    
	
    lea .psb_string(pc),a0
    move.w  #48,d0
    move.w  #96,d1
    move.w  #$0F0,d2
    bsr write_color_string
    
    lea .opo_string(pc),a0
    move.w  #48+16,d0
    move.w  #116,d1
    move.w  #$0f00,d2
	
    bsr write_color_string
    lea .bp1_string(pc),a0
    move.w  #16,d0
    move.w  #148,d1
    move.w  #$0FF,d2
    bsr write_color_string
    lea .bp2_string(pc),a0
    move.w  #16,d0
    move.w  #192-24,d1
    move.w  #$FFF,d2
    bsr write_color_string
    
    rts
    
.psb_string
    dc.b    "PUSH START BUTTON",0
.opo_string:
    dc.b    "1 PLAYER ONLY",0
.bp1_string
    dc.b    "1ST BONUS AFTER 30000 PTS",0
.bp2_string
    dc.b    "AND BONUS EVERY 70000 PTS",0
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
    bsr hide_sprites
    

        
    lea    .play(pc),a0
    move.w  #96,d0
    move.w  #48-24,d1
    move.w  #$0f0,d2
    bsr write_color_string    
    bsr draw_title
    ; first update, don't draw enemies or anything as they're not initialized
    ; (draw routine is called first)
    rts
.init2
    bsr hide_sprites
    bsr clear_screen
    bsr draw_score
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
    ; characters
    move.w  #56,d0
    move.w  #56-24,d1
    lea     .characters(pc),a0
    move.w  #$0F0,d2
    bsr write_color_string
    bsr hide_sprites

    ; not the same configuration as game sprites:
    ; each sprite is there simultaneously

    lea game_palette+32(pc),a0  ; the sprite part of the color palette 16-31    
    moveq.w #0,d0
    ; first sprite palette
    bsr .load_palette

    lea game_palette+32+24(pc),a0  ; we cheat, use sprite 4 with palette of 6-7
    moveq.w #2,d0
    ; thief guard sprite palette
    bsr .load_palette
    
    ;;lea alt_sprite_palette+8(pc),a0  ; we cheat, use sprite 4 with palette of 6-7
    ; thief guard sprite palette
    ;;moveq.w #4,d0
    ;;bsr .load_palette
    
    bra draw_copyright
    

    ;;move.l  a3,a0
    
.no_change
    ; just draw single cattle
    move.b  intro_step(pc),d0
    cmp.b   #1,d0
    bne.b   .no_part1

    ; part 1: cattle drawing path in intro maze
    lea enemies+Enemy_SIZEOF(pc),a0
    
    move.w  xpos(a0),d0
    addq.w  #1,d0       ; compensate

    move.w  ypos(a0),d1
    add.w  #INTRO_Y_SHIFT+5,d1   ; compensate + add offset so logic coords match intro maze
    ; center => top left
    bsr store_sprite_pos

    move.l  frame_table(a0),a1
    move.w  frame(a0),d2
    lsr.w   #2,d2   ; 8 divide to get 0,1
    bclr    #0,d2   ; even
    add.w   d2,d2       ; times 2

    ; get proper frame from proper frame set
    move.l  (a1,d2.w),a1

    move.l  d0,(a1)     ; store control word
    move.l  a1,d2    
    move.l  copperlist_address(a0),a1
    move.w  d2,(6,a1)
    swap    d2
    move.w  d2,(2,a1)  
    
    ; paint is done in the update part
	; the draw part misses bits because it's updated at 50 Hz
	; where the update part is updated at 60 Hz to follow original
	; game speed
    
.no_part1
    
    cmp.b   #3,d0
    bne.b   .no_part3
    ; blit characters
    move.w  #56,d3
    move.w  #72-24,d4
    move.w  d3,d0
    move.w  d4,d1
    lea copier_anim_right,a0
    move.w  #$F,d2
    bsr .draw_bob

    add.w   #ENEMY_Y_SPACING,d4
    move.w  d4,d1
    add.w   #3,d1
    lea police1_frame_table,a0
    lea intro_green_police,a1
    move.w  #3,d2   ; 4 frames
    bsr .load_sprite
    
    move.w  d3,d0
    add.w   #ENEMY_Y_SPACING,d4
    move.w  d4,d1
    add.w   #3,d1
    lea police2_frame_table,a0
    lea thief_sprite,a1
    move.w  #3,d2   ; 4 frames
    bsr .load_sprite
    
    move.w  d3,d0
    add.w   #ENEMY_Y_SPACING,d4
    move.w  d4,d1
    
    lea rustler_anim_right,a0
    move.w  #$F,d2
    bsr .draw_bob
    
    move.w  d3,d0
    add.w   #ENEMY_Y_SPACING,d4
    move.w  d4,d1
    add.w   #3,d1
    lea cattle1_frame_table,a0
    lea intro_cattle_pink,a1
    move.w  #1,d2
    bsr .load_sprite
    
    move.w  d3,d0
    add.w   #ENEMY_Y_SPACING,d4
    move.w  d4,d1
    add.w   #3,d1
    lea cattle2_frame_table,a0
    lea intro_cyan_cattle,a1
    move.w  #1,d2
    bsr .load_sprite
    
    lea draw_char_command(pc),a1
    tst.b   (5,a1)
    beq.b   .nothing_to_print

    lea .onechar(pc),a0
    move.w  (a1)+,d0
    move.w  (a1)+,d1
    move.b  (a1)+,(a0)
    clr.b   (a1)    ; ack
    move.w  #$FF,d2
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
.draw_bob
    move.w intro_frame_index(pc),d6
    and.w   d2,d6
    add.w   d6,d6
    add.w   d6,d6
    move.l  (a0,d6.w),a0
    
    bsr blit_4_planes
    rts
    
.load_sprite
    bsr .get_frame
    move.l  a0,d2
    move.w  d2,(6,a1)
    swap    d2
    move.w  d2,(2,a1)
    bsr store_sprite_pos
    move.l  d0,(a0)
    
    rts
.get_frame
    move.w intro_frame_index(pc),d6
    lsr.w   #3,d6
    and.w   d2,d6
    add.w   d6,d6
    add.w   d6,d6
    move.l  (a0,d6.w),a0
    rts
    
.load_palette
    lea _custom+color+32,a1
    lsr.w   #1,d0
    lsl.w   #3,d0
    add.w   d0,a1

    move.l  (a0,d0.w),(a1)+
    move.l  (4,a0,d0.w),(a1)
    rts


.color_table
    dc.w    $0FF,$0FF,$FFF,$FFF,$FF0,$FF0,$0F0,$0F0,$F00,$F00
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
.characters
    dc.b    "-  CHARACTER  -",0
.play
    dc.b    'PLAY',0
.pts
    dc.b    "0 PTS  hhh",0
    
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
    move.w  #$0ff0,d2
    bsr write_color_string 
    bra.b   draw_copyright

.title
    dc.b    '-  SCRAMBLE  -',0
    even
draw_copyright
    lea    .copyright(pc),a0
    move.w  #64,d0
    move.w  #222-24,d1
    move.w  #$0fff,d2
    bra write_color_string    
.copyright
    dc.b    'c KONAMI  1982',0
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

    
    
delete_last_star
    move.b  nb_stars(pc),d7
    ext     d7
    lea	screen_data+STARS_OFFSET,a1
    add.w   d7,a1
    moveq   #3,d2
.ploop
    move.l  a1,a2
    REPT    8
    clr.b   (a2)
    add.w   #NB_BYTES_PER_LINE,a2
    ENDR
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf     d2,.ploop    
    rts
    
draw_fuel:
    move.b  nb_stars(pc),d7
    subq.b  #1,d7
    ext     d7    
.lloop
    lea star,a0
    lea	screen_data+STARS_OFFSET,a1
    add.l   d7,a1
    moveq   #3,d2
.ploop
    move.l  a1,a2
    REPT    8
    move.b  (a0)+,(a2)
    add.w   #NB_BYTES_PER_LINE,a2
    ENDR
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf     d2,.ploop
    dbf d7,.lloop
.out
    lea     .jump(pc),a0
    move.w  #(NB_BYTES_PER_MAZE_LINE-9)*8,d0
    move.w  #MAZE_HEIGHT+18,d1
    move.w  #$0F0,d2
    bsr     write_color_string
    rts
    
.jump
        dc.b    "JUMP",0
        even
        
LIVES_OFFSET = (MAZE_HEIGHT+18)*NB_BYTES_PER_LINE+1

draw_last_life
    move.w   #1,d0      ; draw only last life
    bra.b   draw_the_lives
    
draw_lives:
    moveq.w #3,d7
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
    move.b  nb_lives(pc),d7
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
    moveq   #3,d2    
.ploop
    move.l  a1,a2
    REPT    8
    move.b  (a0)+,(a2)
    add.w   #NB_BYTES_PER_LINE,a2
    ENDR
    add.w   #SCREEN_PLANE_SIZE,a1
    dbf     d2,.ploop
    tst d0
    bne.b   .out    ; just draw last life
    dbf d7,.lloop
.out
    rts
    
draw_bonuses:
    move.w #NB_BYTES_PER_MAZE_LINE*8,d0
    move.w #248-32,d1
    move.w  level_number(pc),d2
    cmp.w   #6,d2
    bcs.b   .ok
    move.w  #6,d2 
.ok
    move.w  #1,d4
.dbloopy
    move.w  #5,d3
.dbloopx
    ;;bsr draw_bonus
    subq.w  #1,d2
    bmi.b   .outb
    add.w   #16,d0
    dbf d3,.dbloopx
    move.w #NB_BYTES_PER_MAZE_LINE*8,d0
    add.w   #16,d1
    dbf d4,.dbloopy
.outb
    rts
    
maze_misc
    dc.l    level_1_maze,level_2_maze
    dc.l    level_3_maze,level_4_maze
    
level_1_maze
    dc.w    $F00,$CC9,$00F
level_2_maze
    dc.w    $0F0,$FF0,$F00
level_3_maze
    dc.w    $0F0,$f91,$F0F
level_4_maze
    dc.w    $F00,$FF0,$0F0
    
draw_maze:
    bsr wait_blit
    
    ; set colors
    ; the trick with dots is to leave them one plane 1 alone
    ; when the bits intersect with maze lines, we get the same color
    ; because the color entry is duplicated
    ;
    ; this allows to blit main character on planes 0, 2, 3 without any interaction
    ; (except very marginal visual color change) on plane 1
    lea _custom+color,a0
    move.w  level_number(pc),d0
    and.w   #3,d0
    add.w   d0,d0
    add.w   d0,d0

    
    bsr clear_playfield_planes
    
    
.no_clr
    rts    


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
    move.w  #$FFF,d2
    clr.w   d0
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
    ; assuming VBR at 0
    sub.l   a0,a0
    
    lea saved_vectors(pc),a1
    move.l  (a1)+,($8,a0)
    move.l  (a1)+,($c,a0)
    move.l  (a1)+,($10,a0)
    move.l  (a1)+,($68,a0)
    move.l  (a1)+,($6C,a0)


    lea _custom,a6

    move.w  saved_dmacon,d0
    bset    #15,d0
    move.w  d0,(dmacon,a6)
    move.w  saved_intena,d0
    bset    #15,d0
    move.w  d0,(intena,a6)


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
; F5: toggle power sequence
; F6: make power sequence longer
; F8: dump maze dot data (whdload only)
; F9: thief attacks now
; left-ctrl: fast-forward (no player controls during that)

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
    move.l  #1,state_timer
    move.w  #STATE_GAME_OVER,current_state
.no_esc
    
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .no_playing
    tst.b   demo_mode
    bne.b   .no_pause
    cmp.b   #$19,d0
    bne.b   .no_pause
	; in that game we need pause even if music
	; is playing, obviously
;    tst.b   music_playing
;    bne.b   .no_pause
    bsr	toggle_pause
.no_pause
    tst.w   cheat_keys
    beq.b   .no_playing
        
    cmp.b   #$50,d0
    seq.b   level_completed_flag

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
    bne.b   .no_bonus
    ; activate the "power pill" sequence or shut it
    tst.b  enemies+fright_mode
    bne.b   .shut_power
    move.w  #1,can_eat_enemies_mode_pending
    bra.b   .no_playing
.shut_power
	move.w	#1,power_state_counter
.no_bonus
    cmp.b   #$55,d0     ; F6
    bne.b   .no_longer_bonus
    ; free cheat slot

    bra.b   .no_playing
.no_longer_bonus
    cmp.b   #$56,d0     ; F7
    bne.b   .no_add_to_score
	move.w	#500,d0
	bsr		add_to_score
.no_add_to_score
    cmp.b   #$57,d0     ; F8
    bne.b   .no_maze_dump
    tst.l   _resload
    beq.b   .no_maze_dump
    movem.l d0-d1/a0-a2,-(a7)
    move.l maze_wall_table(pc),a1
    lea     maze_dump_file,a0
    move.l  _resload(pc),a2
    move.l  #26*27,D0
    jsr     (resload_SaveFile,a2)
    movem.l (a7)+,d0-d1/a0-a2
.no_maze_dump
    cmp.b   #$58,d0     ; F9
    bne.b   .no_attack
    move.w  #1,attack_timeout
.no_attack

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
	eor.b   #1,pause_flag
	beq.b	.out
	bsr		stop_sounds
	move.w	#1,start_music_countdown	; music will resume when unpaused
.out
	rts
	
    
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
	; check left CTRL
	move.b	$BFEC01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$63,d0
	beq.b	.no_pause
.outcop
    move.w  #$0010,(intreq,a5) 
    movem.l (a7)+,d0-a6
    rte    
.vblank
    moveq.l #1,d0
    bsr _read_joystick
    
    
    btst    #JPB_BTN_BLU,d0
    beq.b   .no_second
    move.l  joystick_state(pc),d2
    btst    #JPB_BTN_BLU,d2
    bne.b   .no_second

    ; no pause if not in game
    cmp.w   #STATE_PLAYING,current_state
    bne.b   .no_second
    tst.b   demo_mode
    bne.b   .no_second
    
    bsr		toggle_pause
.no_second
    lea keyboard_table(pc),a0
    tst.b   ($40,a0)    ; up key
    beq.b   .no_fire
    bset    #JPB_BTN_RED,d0
.no_fire 
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
    
    ; update_bonus_screen
.bonus_screen
  
    tst.l   state_timer
    bne.b   .no_first_bonus_tick

    addq.l  #1,state_timer

 
.no_first_bonus_tick


    bsr init_enemies
    lea enemies+Enemy_SIZEOF(pc),a0

    move.w  #0,xpos(a0)
    move.w  #8,ypos(a0)
    move.w  #DOWN,direction(a0)
    move.l  #$FFFF0001,h_speed(a0)   
.no_bonus_init
    rts
    
.bonus_playing
    addq.l  #1,state_timer
    
    tst.b   bonus_cattle_moving
    bne.b   .moving
    
    move.l  joystick_state(pc),d0
    cmp.l   #ORIGINAL_TICKS_PER_SEC*10,state_timer
    bne.b   .no_timeout
    ; timeout (if not already triggered)
    bset    #JPB_BTN_RED,d0
.no_timeout
    btst    #JPB_BTN_RED,d0
    beq.b   .no_fire
    st.b    bonus_cattle_moving
    
.no_fire
    ; just selecting lane

    ; play ping sound
    lea ping_sound,a0
    bsr play_fx
    ; advance lane
    lea enemies+Enemy_SIZEOF(pc),a0
    move.w  xpos(a0),d0
    add.w   #40,d0
    cmp.w   #240,d0
    bne.b   .no_wrap
    clr.w   d0
.no_wrap
    move.w  d0,xpos(a0)
.do_nothing
    rts
    
.moving
    lea enemies+Enemy_SIZEOF(pc),a0

	; paint maze
    move.w  xpos(a0),d0
    move.w  ypos(a0),d1
    ; don't bother about oring shit or whatnot: just copy the first plane into the second plane
    
    add.w   #2,d1
    
    lea screen_data,a1    
    ADD_XY_TO_A1    a2
    lea (SCREEN_PLANE_SIZE,a1),a2
    cmp.w   #LEFT,direction(a0)
    beq.b   .skipleft
    move.b  (a1),(a2)
    move.b  (NB_BYTES_PER_LINE,a1),(NB_BYTES_PER_LINE,a2)
.skipleft
    move.b  (1,a1),(1,a2)
    move.b  (NB_BYTES_PER_LINE+1,a1),(NB_BYTES_PER_LINE+1,a2)
   
    
.no_replay
    lea enemies+Enemy_SIZEOF(pc),a4

    move.w  ypos(a4),d0
    bmi.b   .down   ; not in the maze yet
    cmp.w   #200,d0
    beq.b   .out
    cmp.w   #190,d0
    bcc.b   .down   ; out of the maze
    rts
.no_animate
    rts
.down
    bsr animate_enemy
    addq.w  #1,ypos(a4)
    rts    
   
    
    
.game_start_screen
    tst.l   state_timer
    bne.b   .out
    addq.l   #1,state_timer
.out
    ; are we already in the bottom?
    tst.w   bottom_reached
    bne.b   .last_timeout
    ; stop music whatever the outcome
    bsr stop_sounds
    ; bottom is reached
    ; see if won
    ; arm timeout
    lea enemies+Enemy_SIZEOF(pc),a4
	
    ; win
     move.w  #ORIGINAL_TICKS_PER_SEC*4,last_bonus_timeout
    move.l  #500,d0     ; 5000 points
    bra add_to_score

.last_timeout
    move.w  last_bonus_timeout(pc),d0
    cmp.w   #ORIGINAL_TICKS_PER_SEC*2,d0
    bne.b   .no_stopmus
    
    bsr stop_sounds
.no_stopmus
    subq.w  #1,last_bonus_timeout
    bne.b   .continue
    ; next level
    bsr .bonus_level_completed
.continue
    rts
    
.life_lost
    rts

.bonus_level_completed
    bsr hide_sprites
    bsr     stop_sounds
.next_level
     move.w  #STATE_NEXT_LEVEL,current_state
     clr.b  bonus_sprites
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
    subq.l  #1,state_timer
    rts
    ; update
.playing
	tst.b	level_completed_flag
	beq.b	.no_completed1
	clr.b	level_completed_flag

	; avoids bonus music when level is completed with
	; one of the corners
	clr.w	can_eat_enemies_mode_pending
    bsr stop_sounds

    st.b    next_level_is_bonus_level
    move.w  #ORIGINAL_TICKS_PER_SEC*6,completed_music_timer
.no_completed1
    move.w   completed_music_timer(pc),d0
    beq.b   .no_completed2
    subq.w  #1,d0
    move.w  d0,completed_music_timer
    bne.b   .completed_music_playing
    
    bsr stop_sounds
	
    move.w  #STATE_NEXT_LEVEL,current_state
    clr.l   state_timer     ; without this, bonus level isn't drawn
    bsr     hide_sprites    ; hide sprites as bonus level only uses 1 or 2 sprites
.completed_music_playing
    rts
.no_completed2

    tst.l   state_timer
    bne.b   .no_first_tick
    st.b   .intro_music_played
    moveq.w   #1,d0
    tst.w  level_number
    bne.b   .no_delay
    ; first level: play start music
    clr.b   .intro_music_played
    

    move.w  #ORIGINAL_TICKS_PER_SEC*5,d0
.no_delay
    move.w  d0,start_music_countdown
.no_first_tick
    ; for demo mode
    addq.w  #1,record_input_clock

    bsr update_player
    
    IFND    NO_ENEMIES
    tst.w   player_killed_timer
    bpl.b   .skip_cc     ; player killed, no collisions	
    bsr check_collisions
.skip_cc
    bsr update_enemies
    
    tst.w   player_killed_timer
    bpl.b   .skip_a_lot     ; player killed, no music management, no collisions
    
    bsr check_collisions
    ENDC
    

.skip_a_lot

    addq.l  #1,state_timer
    rts
.ready_off


    rts

.intro_music_played
    dc.b    0
    even
start_music_countdown
    dc.w    0


	
; hacked quick tile collision detection
; trashes a lot of registers but is probably
; pretty fast specially when 7 enemies are around

check_collisions
    lea player(pc),a3
    move.l  xpos(a3),d0	; get X<<16 | Y
	moveq.l	#3,d3		; pre-load shift value
    lsr.l   d3,d0		; shift both X and Y
	move.w	#$1FFF,d1	; pre-load mask value
	and.w	d1,d0	; remove shifted X bits that propagated to Y LSW
    lea enemies(pc),a4
    move.w  nb_enemies_but_thief(pc),d7    ; plus one
.gloop
	; this is probably much faster than shifting X & Y to compute tile
    move.l  xpos(a4),d2		; get X and Y, same as for player (see above)
    lsr.l   d3,d2		; one shift
	and.w	d1,d2		; small masking operation
    cmp.l   d2,d0		; one comparison
    beq.b   .collision

    add.w   #Enemy_SIZEOF,a4
    dbf d7,.gloop
    rts
.collision
    ; is the enemy falling, hanging, whatever...
	
    ; player is killed
    tst.b   invincible_cheat_flag
    bne.b   .nomatch
    move.w  #MODE_KILL,mode(a4)
    move.w  #PLAYER_KILL_TIMER,player_killed_timer
    clr.w   enemy_kill_timer
    move.w  #KILL_FIRST_FRAME,enemy_kill_frame
.nomatch
    bsr stop_sounds
    lea     player_killed_sound(pc),a0
    bra     play_fx
   

    
CHARACTER_X_START = 88

update_intro_screen
    move.l   state_timer(pc),d0
    bne.b   .no_first
    
.first
	move.l	speed_table(pc),global_speed_table
    tst.w   high_score_position
    bpl.b   .second
    
    move.b  #1,intro_step
    st.b    intro_state_change

    move.w  #1,nb_enemies_but_thief
    st.b    bonus_sprites
    clr.l	d0
    bsr init_enemies
    
    lea enemies+Enemy_SIZEOF(pc),a0

    move.l   #-1,previous_xpos(a0)
	lea		.cattle_x_table(pc),a1
	; pick a random start position
	bsr		random
	and.w	#3,d0
	add.w	d0,d0
	move.w	(a1,d0.w),d0
    move.w  d0,xpos(a0)
    move.w  #-8,ypos(a0)     ; this is the logical coordinate
  
    move.w  #DOWN,direction(a0)
    move.l  #$FFFF0001,h_speed(a0)
    
    bra.b   .cont
.no_first 
    cmp.l   #ORIGINAL_TICKS_PER_SEC*9,d0
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
    cmp.l   #ORIGINAL_TICKS_PER_SEC*12,d0
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

    move.w  #ORIGINAL_TICKS_PER_SEC,.cct_countdown
    move.w  #CHARACTER_X_START,.cct_x
    move.w  #80-24,.cct_y

    clr.w   .cct_text_index
    move.w   #6,.cct_counter
    clr.w   .cct_char_index
   
.cont    
    move.l  state_timer(pc),d0
    add.l   #1,D0
    cmp.l   #ORIGINAL_TICKS_PER_SEC*22,d0
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
    
    cmp.l   #ORIGINAL_TICKS_PER_SEC,d0
    bcs.b   .no_animate
    cmp.l   #ORIGINAL_TICKS_PER_SEC*8,d0
    bcc.b   .no_animate
    
    lea enemies+Enemy_SIZEOF(pc),a4

	; paint here
    move.w  xpos(a4),d0
    move.w  ypos(a4),d1

    lea screen_data,a1
    add.w   #INTRO_Y_SHIFT+8,d1
    ADD_XY_TO_A1    a2
    lea (SCREEN_PLANE_SIZE,a1),a2
    cmp.w   #LEFT,direction(a4)
    beq.b   .skipleft
    move.b  (a1),(a2)
    move.b  (NB_BYTES_PER_LINE,a1),(NB_BYTES_PER_LINE,a2)
.skipleft
    move.b  (1,a1),(1,a2)
    move.b  (NB_BYTES_PER_LINE+1,a1),(NB_BYTES_PER_LINE+1,a2)


    move.w  ypos(a4),d0
    bmi.b   .down   ; not in the maze yet
	cmp.w	#4,d0
	bcs.b	.down
    cmp.w   #112,d0
    beq.b   .out
    cmp.w   #108,d0
    bcc.b   .down   ; out of the maze
    rts
.no_animate
    rts
.horiz
    addq.w  #1,xpos(a4)
    rts
.down
    bsr animate_enemy
    addq.w  #1,ypos(a4)
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

; not all start positions work properly
; but who cares? just omit the ones that fail
.cattle_x_table:
	dc.w	40,80,120,160
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
    dc.l    .text3
.text1:
    dc.b    "hhh  COPIER",0
.text2:
    dc.b    "hhh  POLICE",0
.text3:
    dc.b    "hhh  THIEF",0
.text4:
    dc.b    "hhh  RUSTLER",0
.text5:
    dc.b    "hhh  CATTLE",0
    even

    
    
update_enemies:
    rts
    

     
animate_enemy
    move.w  frame(a4),d1
    addq.w  #1,d1
    and.w   #$F,d1
    move.w  d1,frame(a4)
    rts


get_next_speed_index
    move.w  speed_table_index(a4),d0
    move.w  d0,d1
    add.w   #1,d0
    cmp.w   #20,d0
    bne.b   .no_wrap
    clr.w   d0
.no_wrap
    move.w  d0,speed_table_index(a4)
    
    move.l  global_speed_table(pc),a0
    move.b  (a0,d1.w),d0
    rts    
    



    
play_loop_fx
    tst.b   demo_mode
    bne.b   .nosfx
    lea _custom,a6
    bra _mt_loopfx
.nosfx
    rts
    
; what: sets game state when all 4 corners are completed
; trashes: A0,D0
all_four_corners_done
    movem.l  d1-d2/a1,-(a7)
	; reset crash respawn delay table
	lea	crash_respawn_delay_table(pc),a0
	moveq.w	#6,d0
.clr
	; 6*2 bytes
	clr.l	(a0)+
	dbf	d0,.clr	
    ; resets next enemy eaten score
    clr.w  next_enemy_iteration_score
    lea enemies(pc),a0
    move.w  nb_enemies_but_thief(pc),d7
    addq.w  #1,d7
    move.w  d7,nb_enemies_to_eat
    subq.w  #1,d7
.gloop
    move.w  mode(a0),d0

    add.w   #Enemy_SIZEOF,a0    
    dbf d7,.gloop
    

    movem.l (a7)+,d1-d2/a1
    rts
    

    
    
update_player
    lea     player(pc),a4
    ; no moves (zeroes horiz & vert)
    clr.l  h_speed(a4)  

    move.w  player_killed_timer(pc),d6
    bmi.b   .alive
    moveq.w #8,d0
    cmp.w   #2*PLAYER_KILL_TIMER/3,d6
    bcs.b   .no_first_frame
    moveq.w #4,d0
    bra.b   .frame_done
.no_first_frame
    cmp.w   #PLAYER_KILL_TIMER/3,d6
    bcs.b   .no_second_frame
    moveq.w #0,d0
.no_second_frame

.frame_done    
    move.w  d0,death_frame_offset   ; 0,4,8
    rts
.alive
    tst.w   fright_timer
    beq.b   .no_fright1
    sub.w   #1,fright_timer
    bne.b   .no_fright1
    ; fright mode just ended: resume normal sound loop
    nop
.no_fright1

    
.okmove

    move.l  joystick_state(pc),d0
    IFD    RECORD_INPUT_TABLE_SIZE
    bsr     record_input
    ENDC
    tst.b   demo_mode
    beq.b   .no_demo
    ; if fire is pressed, end demo, goto start screen
    btst    #JPB_BTN_RED,d0
    beq.b   .no_demo_end
    clr.b   demo_mode
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
    
    ; read live or recorded controls
.no_demo

    tst.l   d0
    beq.b   .out        ; nothing is currently pressed: optimize
    btst    #JPB_BTN_RED,d0
    beq.b   .no_fire

    lea     jump_sound,a0
    move.l  d0,-(a7)
    bsr     play_fx
    move.l  (a7)+,d0
    

.no_fire
    btst    #JPB_BTN_RIGHT,d0
    beq.b   .no_right
    move.w  #1,h_speed(a4)
    bra.b   .vertical
.no_right
    btst    #JPB_BTN_LEFT,d0
    beq.b   .vertical
    move.w  #-1,h_speed(a4)  
.vertical
    btst    #JPB_BTN_UP,d0
    beq.b   .no_up
    move.w  #-1,v_speed(a4)
    bra.b   .out
.no_up
    btst    #JPB_BTN_DOWN,d0
    beq.b   .no_down
    move.w  #1,v_speed(a4)
.no_down    
.out
    bsr     .move_attempt
    tst.w   d5
    beq.b   .no_move
    
    cmp.w   #3,d5
    beq.b   .valid_move
    ; invalid move
    ; first pass: check if there's an intersection nearby past the player
    ; for that we have to check against every facing direction
    move.w  direction(a4),d6
    lea     dircheck_table(pc),a0
    move.l  (a0,d6.w),a0
    jsr     (a0)
    
    ; second pass just try to see if latest move would work ("corner cut")
    move.l  previous_valid_direction(pc),d6
    beq.b   .no_move
	; it would work, store it
    move.l  d6,h_speed(a4)
    bsr     .move_attempt
    cmp.w   #3,d5
    beq.b   .valid_move
    ; nothing to do, previous move wasn't valid
    bra.b   .no_move
.valid_move
	; move is valid
    ; store for later
    move.l  h_speed(a4),previous_valid_direction
    bsr animate_player    
    move.w  d2,xpos(a4)
    move.w  d3,ypos(a4)

    rts
    
 
        

.no_move
  
    rts

    
.move_attempt
    ; cache xy in regs / save them
    move.w  xpos(a4),d2
    move.w  ypos(a4),d3

    clr.w   d5
    ;;move.w  direction(a4),d6
    ; test if player has requested an "up" move
    move.w  v_speed(a4),d6
    beq.b   .no_vertical
    bset    #0,d5   ; note that we attempted a move
    ; up/down move requested
    move.w  d2,d0
    and.b   #7,d0
    bne.b   .no_vertical    ; invalidated: not aligned in x
    move.w  d2,d0
    move.w  d3,d1
    add.w   d6,d1  ; change y
    bmi.b   .no_vertical
    cmp.w   #Y_MAX+1,d1
    bcc.b   .no_vertical
    tst.w   d6
    bmi.b   .up1
    ; to the right: add 7
    addq.w  #7,d1
.up1
    bsr     is_location_legal
    tst.b   d0
    beq.b   .no_vertical
    ; validate

    add.w   d6,d3  ; change y
    bset    #1,d5
    tst.w   d6
    bmi.b   .up
    move.w  #DOWN,direction(a4)
    bra.b   .no_vertical
.up
    move.w  #UP,direction(a4)
.no_vertical
    move.w   h_speed(a4),d6
    beq.b   .no_horizontal
    bset    #0,d5   ; note that we attempted a move
    ; left/right move requested
    move.w  d3,d1
    and.b   #7,d1
    bne.b   .no_horizontal    ; invalidated: not aligned in y
    move.w  d2,d0
    move.w  d3,d1
    add.w   d6,d0  ; change x
    bmi.b   .no_horizontal
    cmp.w   #X_MAX+1,d0
    bcc.b   .no_horizontal
    tst.w   d6
    bmi.b   .left1
    ; to the right: add 7
    addq.w  #7,d0
.left1
    bsr     is_location_legal
    tst.b   d0
    beq.b   .no_horizontal
    ; validate
    add.w   d6,d2  ; change x
    bset    #1,d5
    tst.w   d6
    bmi.b   .left
    move.w  #RIGHT,direction(a4)
    bra.b   .no_horizontal
.left
    move.w  #LEFT,direction(a4)
.no_horizontal
    rts

dircheck_table
    dc.l    dircheck_right
    dc.l    dircheck_left
    dc.l    dircheck_up
    dc.l    dircheck_down

CORRECTIVE_TEST_OFFSET = 8

	
; d2 contains X
; d3 contains Y
; we use d4
; those routines switch signs on previous_valid_direction if
; game senses that the player has missed a turn
; which complements the "continue" move when a turn is anticipated
;
; both mechanisms ensure that the player never misses a turn, which can
; be fatal in that kind of game
;
; this is still not right
dircheck_right
    move.w  v_speed(a4),d4
    beq.b   just_rts
    move.w  d2,d0
    move.w  d3,d1
    ; align on previous x tile
    and.w   #$F8,d0
    bra.b	dircheck_horiz
	
dircheck_left
    move.w  v_speed(a4),d4
    beq.b   just_rts
    move.w  d2,d0
    move.w  d3,d1
    ; align on previous x tile
    addq.w   #8,d0
dircheck_horiz    
    cmp.w   #1,d4
    bne.b   .no_down
    addq.w  #CORRECTIVE_TEST_OFFSET,d1
    bsr     is_location_legal
    tst.b   d0
    bne.b   .reverse_horiz_direction
    rts
.no_down
    ; has to be "up"
    ; up attempt
    subq.w  #CORRECTIVE_TEST_OFFSET,d1
    bsr     is_location_legal
    tst.b   d0
    bne.b	.reverse_horiz_direction
.no_up
    rts

.reverse_horiz_direction
    ; looks like player went past the "up" intersection: change direction
    neg.w  previous_valid_direction
	rts
	
dircheck_up
    move.w  h_speed(a4),d4
    beq.b   just_rts
    move.w  d2,d0
    move.w  d3,d1
    ; align on lower y tile
    
    addq.w   #8,d1
	bra.b	dircheck_vert
	
dircheck_down
    move.w  h_speed(a4),d4
    beq.b   just_rts
    move.w  d2,d0
    move.w  d3,d1
    ; align on upper y tile
    
    and.w   #$F8,d1

dircheck_vert
    cmp.w   #1,d4
    bne.b   .no_right
    addq.w  #CORRECTIVE_TEST_OFFSET,d0
    bsr     is_location_legal
    tst.b   d0
    bne.b   .reverse_vert_direction
    rts
.no_right
    ; has to be "left"
    ; left attempt
    subq.w  #CORRECTIVE_TEST_OFFSET,d0
    bsr     is_location_legal
    tst.b   d0
    bne.b   .reverse_vert_direction
    rts	

.reverse_vert_direction
    ; looks like player went past the "up" intersection: change direction
    neg.w  previous_valid_direction+2
	rts    

just_rts
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
    
; called when pacman moves
; < A4: pac player
animate_player
    addq.w  #1,frame(a4)
    cmp.w   #(rustler_anim_left_end-rustler_anim_left)/4,frame(a4)
    bne.b   .no_floop
    clr.w   frame(a4)
.no_floop
    rts



    
; the palette is organized so we only need to blit planes 0, 2 and 3 (not 1)
; plane 1 contains dots so it avoids to redraw it
; plane 0 contains the grid, that has been backed up
; plane 3 contains filled up rectangles, needs backing up too
draw_player:
    move.l  previous_player_address(pc),d5
    bne.b   .not_first_draw
    moveq.l #-1,d5
.not_first_draw
    ; first, restore plane 0
    tst.l   d5    
    bmi.b   .no_erase
    ; restore plane 0 using CPU
    lea grid_backup_plane,a0    
    lea screen_data,a1
    sub.l   a1,d5       ; d5 is now the offset
    ; d0 is the offset: add it
    add.l   d5,a1
    add.l   d5,a0
    ; now copy a rectangle of the saved screen
    REPT    18
    move.l   ((REPTN-1)*NB_BYTES_PER_LINE,a0),((REPTN-1)*NB_BYTES_PER_LINE,a1)
    ENDR

    tst.b   rustler_level
    beq.b   .no_erase
    add.w   #SCREEN_PLANE_SIZE,a1
    lea     paint_backup_plane,a0
    add.l   d5,a0
    ; now copy a rectangle of the saved screen
    REPT    18
    move.l   ((REPTN-1)*NB_BYTES_PER_LINE,a0),((REPTN-1)*NB_BYTES_PER_LINE,a1)
    ENDR
    
.no_erase

    lea     player(pc),a2
    tst.w  player_killed_timer
    bmi.b   .normal
    lea     copier_dead_table,a0
    tst.b   rustler_level
    beq.b   .no_rust
    lea     rustler_dead_table,a0
.no_rust
    move.w  death_frame_offset(pc),d0
    add.w   d0,a0       ; proper frame to blit
    move.l  (a0),a0
    bra.b   .pacblit
.normal

    move.w  direction(a2),d0
    lea  copier_dir_table(pc),a0
    tst.b   rustler_level
    beq.b   .cont
    lea  rustler_dir_table(pc),a0    
.cont
    move.l  (a0,d0.w),a0
    move.w  frame(a2),d0
    add.w   d0,d0
    add.w   d0,d0
    move.l  (a0,d0.w),a0
.pacblit

    move.w  xpos(a2),d3    
	addq.w	#1,d3	; X-offset
    move.w  ypos(a2),d4
    ; center => top left
    moveq.l #-1,d2 ; mask

    lea	screen_data,a1

    ; apply X offset
    addq.w #2,d0
    
    move.l  a1,a6
    move.w d3,d0
    move.w d4,d1

    ; plane 0
    move.l  a1,a2
    lea (BOB_16X16_PLANE_SIZE*4,a0),a3
    bsr blit_plane_cookie_cut
    move.l  a1,previous_player_address
    
    ; remove previous second plane before blitting the new one
    ; nice as it works in parallel with the first plane blit started above
    tst.l   d5
    bmi.b   .no_erase2
        
    ; restore plane 2
    lea   screen_data+SCREEN_PLANE_SIZE*2,a1
    lea rect_backup_plane,a4    
    add.l   d5,a4
    add.l   d5,a1
    ; now copy a rectangle of the saved screen
    REPT    18
    move.l   ((REPTN-1)*NB_BYTES_PER_LINE,a4),((REPTN-1)*NB_BYTES_PER_LINE,a1)
    ENDR

.no_erase2    
    tst.b   rustler_level
    beq.b   .no_plane_1
    lea	screen_data+SCREEN_PLANE_SIZE,a1
    move.l  a1,a2   ; just restored background
    ; plane 2
    ; a3 is already computed from first cookie cut blit
    lea (BOB_16X16_PLANE_SIZE,a0),a0
    move.l  a1,a6
    move.w d3,d0
    move.w d4,d1

    bsr blit_plane_cookie_cut
    lea (BOB_16X16_PLANE_SIZE,a0),a0
    bra.b   .plane_1
.no_plane_1
    
    lea (BOB_16X16_PLANE_SIZE*2,a0),a0
.plane_1
    lea	screen_data+SCREEN_PLANE_SIZE*2,a1
    move.l  a1,a2   ; just restored background
    ; plane 2
    ; a3 is already computed from first cookie cut blit
    move.l  a1,a6
    move.w d3,d0
    move.w d4,d1

    bsr blit_plane_cookie_cut
    
    ; delete third plane too
    tst.l   d5    
    bmi.b   .no_erase3
    
    ; clear plane 3
    lea   screen_data+SCREEN_PLANE_SIZE*3,a1
    add.l   d5,a1
    ; now copy a rectangle of the saved screen
    REPT    18
    clr.l   ((REPTN-1)*NB_BYTES_PER_LINE,a1)
    ENDR

.no_erase3
    
    move.w d3,d0
    move.w d4,d1

    lea (SCREEN_PLANE_SIZE,a6),a1
    lea (BOB_16X16_PLANE_SIZE,a0),a0    ; next plane for bitmap
    ; plane 3
    bra blit_plane

    
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
    
grid_align_table
    REPT    320
    dc.w    (REPTN&$1F8)+4
    ENDR
    
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

 
    
; what: returns which rectangle(s) contain the current x,y
; 
; args:
; < d0 : x (screen coords)
; < d1 : y
; > d4,d5,d6: pointers on linked rectangles (either can be NULL)
; trashes: none

get_dot_rectangles:
    cmp.w   #Y_MAX+1,d1
    bcc.b   .out_of_bounds
    cmp.w   #X_MAX+1,d0
    bcc.b   .out_of_bounds
    ; no need to test sign (bmi) as bcc works unsigned so works on negative!
    ; apply x,y offset
    add.w   #4,d1       ; center
    
    lsr.w   #3,d1       ; 8 divide : tile
    move.l  a0,-(a7)
    lea     mul26_table(pc),a0
    add.w   d1,d1
    move.w  (a0,d1.w),d1    ; times 26
    lsl.w   #4,d1   ; times 16 (4 32 bit longwords per slot)
    move.l dot_table(pc),a0
    add.w   d1,a0
    and.b   #$F8,d0   ; align on 8 (2 32 bit longwords per slot)
    
    add.w   d0,a0
    add.w   d0,a0
    
    move.l  (a0)+,D4    ; retrieve value of first pointer
    move.l  (a0)+,D5    ; retrieve value of second pointer
    move.l  (a0),D6    ; retrieve value of third pointer
    move.l  (a7)+,a0
    
    rts
.out_of_bounds
    moveq.l   #0,d0
    moveq.l   #0,d1
    moveq.l   #0,d2
    rts
    
; what: checks if x,y collides with maze
; returns valid location out of the maze
; (allows to handle edges, with a limit given by
; the move methods)
; args:
; < d0 : x (screen coords)
; < d1 : y
; > d0.b : not 0 if maze, 0 if no maze
; out of bounds returns -1 which makes it legal to move to (edges)
; trashes: a0,a1,d1

is_location_legal:
    moveq.l	#-1,d0
    rts
    
; what: checks what is below x,y
; returns 0 out of the maze
; (allows to handle edges, with a limit given by
; the move methods)
; args:
; < d0 : x (screen coords)
; < d1 : y
; > a0: points on byte value to read (can be written to unless it points on negative value!!)
; which is 0 if no maze, 
;                  1 if has dot (or needs painting)
;                  2 if temp paint or dot eaten
;                  3 if fully painted
; trashes: a1,d0,d1

get_tile_type:
    cmp.w   #Y_MAX+1,d1
    bcc.b   .out_of_bounds
    cmp.w   #X_MAX+1,d0
    bcc.b   .out_of_bounds
    ; no need to test sign (bmi) as bcc works unsigned so works on negative!
    ; apply x,y offset
    add.w   #4,d1       ; center

    lsr.w   #3,d1       ; 8 divide : tile
    lea     mul26_table(pc),a0
    add.w   d1,d1
    move.w  (a0,d1.w),d1    ; times 26
    move.l maze_wall_table(pc),a0
    
    
    add.w   d1,a0
    lsr.w   #3,d0   ; 8 divide
    add.w   d0,a0
    move.b  (a0),d0    ; retrieve value
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
; < D2: blit mask
; trashes: D0-D1
; returns: A1 as start of destination (A1 = orig A1+40*D1+D0/8)

blit_plane
    movem.l d2-d6/a2-a5,-(a7)
    lea $DFF000,A5
	move.l d2,d3
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
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
; < D2: blit mask
; trashes: D0-D1
; returns: A1 as start of destination (A1 = orig A1+40*D1+D0/16)

blit_plane_cookie_cut
    movem.l d2-d7/a2-a5,-(a7)
    lea $DFF000,A5
	move.l d2,d3	;masking of first/last word    
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
    move.w  #16,d4      ; 16 pixels height   
    bsr blit_plane_any_internal_cookie_cut
    movem.l (a7)+,d2-d7/a2-a5
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
	bsr	wait_blit
    
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

; < A5: custom
; < D0.W,D1.W: x,y
; < A0: source
; < A1: destination
; < A2: background to mix with cookie cut
; < A3: source mask for cookie cut
; < D2: width in bytes (inc. 2 extra for shifting)
; < D3: blit mask
; < D4: height
; blit mask set
; returns: start of destination in A1 (computed from old A1+X,Y)
; trashes: nothing

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
    or.w    d7,d5            ; add shift to mask (bplcon1)
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
	bsr	wait_blit
    
    ; blitter registers set

    move.l  d3,bltafwm(a5)
	clr.w bltamod(a5)		;A modulo=bytes to skip between lines
	clr.w bltbmod(a5)		;A modulo=bytes to skip between lines
	move.l d5,bltcon0(a5)	; sets con0 and con1

    move.w  d0,bltcmod(a5)	;C modulo (maze width != screen width but we made it match)
    move.w  d0,bltdmod(a5)	;D modulo

	move.l a3,bltapt(a5)	;source graphic top left corner (mask)
	move.l a0,bltbpt(a5)	;source graphic top left corner
	move.l a2,bltcpt(a5)	;pristine background
	move.l a1,bltdpt(a5)	;destination top left corner
	move.w  d4,bltsize(a5)	;rectangle size, starts blit
    
    movem.l (a7)+,d0-d7
    rts


; what: blits 16(32)x16 data on 4 planes (for bonuses), full mask
; args:
; < A0: data (16x16)
; < D0: X
; < D1: Y
; trashes: D0-D1

blit_4_planes
    movem.l d2-d6/a0-a1/a5,-(a7)
    lea $DFF000,A5
    lea     screen_data,a1
    moveq.l #3,d7
.loop
    movem.l d0-d1/a1,-(a7)
    move.w  #4,d2       ; 16 pixels + 2 shift bytes
    moveq.l #-1,d3  ; mask
    move.w  #16,d4      ; height
    bsr blit_plane_any_internal
    movem.l (a7)+,d0-d1/a1
    add.l   #SCREEN_PLANE_SIZE,a1
    add.l   #64,a0      ; 32 but shifting!
    dbf d7,.loop
    movem.l (a7)+,d2-d6/a0-a1/a5
    rts
    
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
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
; what: writes an decimal number with a given color
; args:
; < D0: X (multiple of 8)
; < D1: Y
; < D2: number value
; < D3: number of padding zeroes
; < D4: RGB4 color
; > D0: number of characters written
    
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
    movem.l D1-D6/A1,-(a7)
    ; compute string length first in D6
    clr.w   d6
.strlen
    tst.b   (a0,d6.w)
    beq.b   .outstrlen
    addq.w  #1,d6
    bra.b   .strlen
.outstrlen
    ; D6 has string length
    lea game_palette(pc),a1
    moveq   #15,d3
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
    moveq   #3,d3
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
    add.l   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop
.out
    movem.l (a7)+,D1-D6/A1
    rts
    
; what: writes a text in a given color
; args:
; < A0: c string
; < D0: X (multiple of 8)
; < D1: Y
; < D2: RGB4 color (must be in palette!)
; > D0: number of characters written
; trashes: none

write_color_string:
    movem.l D1-D5/A1,-(a7)
    lea game_palette(pc),a1
    moveq   #15,d3
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
    moveq   #3,d3
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
    add.l   #SCREEN_PLANE_SIZE,a1
    dbf d3,.plane_loop
.out
    movem.l (a7)+,D1-D5/A1
    rts
    
; what: writes a text in a single plane
; args:
; < A0: c string
; < A1: plane
; < D0: X (multiple of 8 else it's rounded)
; < D1: Y
; > D0: number of characters written
; trashes: none

write_string:
    movem.l A0-A2/d1-D2,-(a7)
    clr.w   d2
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
    move.b  (a2)+,(a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE,a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE*2,a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE*3,a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE*4,a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE*5,a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE*6,a1)
    move.b  (a2)+,(NB_BYTES_PER_LINE*7,a1)
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
    cmp.b   #'h',d2
    bne.b   .noheart
    lea heart(pc),a2
    moveq.l #0,d2
    bra.b   .wl
.noheart
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
_keyexit
    dc.b    $59
scores_name
    dc.b    "amidar.high",0
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

  
current_state:
    dc.w    0
score:
    dc.l    0
displayed_score:
    dc.l    0
previous_score:
    dc.l    0
score_to_track:
    dc.l    0


; general purpose timer for non-game states (intro, game over...)
state_timer:
    dc.l    0
intro_text_message:
    dc.w    0
last_ghost_eaten_state_timer
    dc.w    0
fruit_score_index:
    dc.w    0
next_enemy_iteration_score
    dc.w    0
previous_player_address
    dc.l    0
previous_valid_direction
    dc.l    0

global_speed_table
    dc.l    0
dot_table:
    dc.l    0
maze_wall_table:
    dc.l    0

maze_bitmap_plane_1
    dc.l    0
maze_bitmap_plane_2
    dc.l    0
extra_life_sound_counter
    dc.w    0
extra_life_sound_timer
    dc.w    0
; 0: level 1
level_number:
    dc.w    0
enemy_kill_timer
    dc.w    0
player_killed_timer:
    dc.w    -1
bonus_score_timer:
    dc.w    0
fright_timer:
    dc.w    0
cheat_sequence_pointer
    dc.l    cheat_sequence

cheat_keys
    dc.w    0
death_frame_offset
    dc.w    0

power_state_counter
    dc.w    0
; move every 10 ticks
bonus_level_lane_select_subcounter:
    dc.w    0
bonus_text_screen_countdown
    dc.w    0
bonus_music_replay_timer
    dc.w    0
player_move_index
    dc.w    0
thief_move_index
    dc.w    0

compatible_rectangles
    dc.l    0,0,0,0
bonus_vertical_table
    dc.l    0
bottom_reached
    dc.w    0
last_bonus_timeout
    dc.w    0
banana_x
    dc.w    0
nb_enemies_but_thief
    dc.w    0
nb_enemies_to_eat
    dc.w    0
jump_index
    dc.w   0
jump_frame
    dc.w    0
enemy_kill_frame
    dc.w    0
completed_music_timer:
    dc.w    0
maze_outline_color
    dc.w    0
can_eat_enemies_mode_pending
    dc.w    0
maze_fill_color
    dc.w    0
previous_temp_paint_direction:
    dc.w    0
attack_timeout:
    dc.w    0
nb_compatible_rectangles
	dc.w	0

thief_target_tile_x
    dc.w    0
thief_target_tile_y
    dc.w    0
thief_standby_timer:
    dc.w    0
; initial time for standby
thief_standby_time:
    dc.w    0
thief_attack_sound_count_timer:
    dc.w    0
thief_attacks:
    dc.b    0
thief_up_move_lock:
    dc.b    0
thief_attack_sound_count:
    dc.b    0
total_number_of_dots:
    dc.b    0
bonus_cattle_moving:
    dc.b    0
player_move_record
    dc.b    0
first_recorded_move
    dc.b    0
first_thief_objective
    dc.b    0
next_level_is_bonus_level
    dc.b    0
nb_lives:
    dc.b    0
level_completed_flag
	dc.b	0
rustler_level:
    dc.b    0
corner_sideeffect_paint
	dc.b	0
previous_tile_type:
    dc.b    0

was_playing_paint_sound:
    dc.b    0
new_life_restart:
    dc.b    0
bonus_sprites:
    dc.b    0
nb_stars:
    dc.b    0
nb_special_rectangles:
    dc.b    0
nb_rectangles:
    dc.b    0
music_playing:    
    dc.b    0
pause_flag
    dc.b    0
quit_flag
    dc.b    0
elroy_mode_lock:
    dc.b    0


invincible_cheat_flag
    dc.b    0
infinite_lives_cheat_flag
    dc.b    0
debug_flag
    dc.b    0
demo_mode
    dc.b    0
extra_life_awarded
    dc.b    0
music_played
    dc.b    0
delete_last_star_message
    dc.b    0

    even

power_song_countdown
     dc.w   0
bonus_score_display_message:
    dc.w    0
extra_life_message:
    dc.w    0
crash_respawn_delay_table
	ds.w	26		; 6 x positions spaced by 4 unused slots, but let's make it safe
score_table
    dc.w    0,1,5
nb_enemy_table
    dc.w    4,4,5,5,6,6
	; not sure it's accurate, well, doesn't matter, as the arcade
	; game came with different versions and skill levels.
standby_time_table
	dc.w	5*ORIGINAL_TICKS_PER_SEC
	dc.w	4*ORIGINAL_TICKS_PER_SEC
	dc.w	3*ORIGINAL_TICKS_PER_SEC
	dc.w	2*ORIGINAL_TICKS_PER_SEC
	dc.w	1*ORIGINAL_TICKS_PER_SEC
	dc.w	1	; 1 frame: no standby
	
	
fruit_score     ; must follow score_table
    dc.w    10
loop_array:
    dc.l    0,0,0,0
    
police_fright_palette
    dc.w    $0000,$0f00,$00F0,$0ff0
cattle_fright_palette
    dc.w    $0000,$F91,$0F0,$0c0f
police_fright_blink_palette
    dc.w    $0000,$0fFF,$0F00,$f91
cattle_fright_blink_palette
    dc.w    $0000,$0fff,$00ff,$0f00
    
fright_palette
    dc.l    0
fright_blink_palette
    dc.l    0
    
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

copier_dir_table
    dc.l    copier_anim_right,copier_anim_left,copier_anim_up,copier_anim_down
rustler_dir_table
    dc.l    rustler_anim_right,rustler_anim_left,rustler_anim_up,rustler_anim_down
    
COPIER_ANIM_TABLE:MACRO
copier_anim_\1

    dc.l    copier_\1_0,copier_\1_0,copier_\1_0,copier_\1_0,copier_\1_0,copier_\1_0,copier_\1_0,copier_\1_0
    dc.l    copier_\1_1,copier_\1_1,copier_\1_1,copier_\1_1,copier_\1_1,copier_\1_1,copier_\1_1,copier_\1_1
copier_anim_\1_end
    ENDM
    
RUSTLER_ANIM_TABLE:MACRO
rustler_anim_\1
    dc.l    rustler_\1_0,rustler_\1_0,rustler_\1_0,rustler_\1_0,rustler_\1_0,rustler_\1_0,rustler_\1_0,rustler_\1_0
    dc.l    rustler_\1_1,rustler_\1_1,rustler_\1_1,rustler_\1_1,rustler_\1_1,rustler_\1_1,rustler_\1_1,rustler_\1_1
rustler_anim_\1_end
    ENDM
    
    COPIER_ANIM_TABLE  right
    COPIER_ANIM_TABLE  left
    COPIER_ANIM_TABLE  up
    COPIER_ANIM_TABLE  down
    
    RUSTLER_ANIM_TABLE  right
    RUSTLER_ANIM_TABLE  left
    RUSTLER_ANIM_TABLE  up
    RUSTLER_ANIM_TABLE  down



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
heart
    incbin  "heart.bin"
copyright
    incbin  "copyright.bin"
space
    ds.b    8,0
    
high_score_string
    dc.b    " HIGH SCORE",0
p1_string
    dc.b    "     1UP",0
level_string
    dc.b    "   LEVEL",0
score_string
    dc.b    "       00",0
game_over_string
    dc.b    "GAME##OVER",0
player_one_string
    dc.b    "PLAYER ONE",0
player_one_string_clear
    dc.b    "          ",0



    even

    MUL_TABLE   40
    MUL_TABLE   26

square_table:
	rept	256
	dc.w	REPTN*REPTN
	endr
   
; truth table to avoid testing for several directions where there's only once choice
; (one bit set)
no_direction_choice_table:
    dc.b    $ff   ; 0=not possible
    dc.b    RIGHT   ; 1
    dc.b    DOWN   ; 2
    dc.b    $ff   ; 3=composite
    dc.b    LEFT   ; 4=UP
    dc.b    $ff   ; 5=composite
    dc.b    $ff   ; idem
    dc.b    $ff   ; idem
    dc.b    UP   ; 8
    ; all the rest is composite or invalid
    REPT    7
    dc.b    $ff
    ENDR
    even
    
    
score_value_table
    dc.l    20,40,80,160




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
play_fx
    tst.b   demo_mode
    bne.b   .no_sound
    lea _custom,a6
    bra _mt_playfx
.no_sound
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
    SOUND_ENTRY lose_bonus,1,SOUNDFREQ,64
    SOUND_ENTRY enemy_hit,1,SOUNDFREQ,64
    SOUND_ENTRY enemy_falling,2,SOUNDFREQ,48
    SOUND_ENTRY enemy_killed,2,SOUNDFREQ,56
    SOUND_ENTRY extra_life,2,SOUNDFREQ,56
    SOUND_ENTRY thief_attacks,2,SOUNDFREQ,48
    SOUND_ENTRY player_killed,2,SOUNDFREQ,40
    SOUND_ENTRY credit,1,SOUNDFREQ,64
    SOUND_ENTRY eat,3,SOUNDFREQ,16
    SOUND_ENTRY ping,3,SOUNDFREQ,32
    SOUND_ENTRY paint,3,SOUNDFREQ,12
    SOUND_ENTRY filled,0,SOUNDFREQ,24
    SOUND_ENTRY jump,1,SOUNDFREQ,24

; 0-49 divisibility table
divisible_by_5_table
    REPT    10
    dc.b    1
    dc.b    0,0,0,0
    ENDR
    
; ORed previous/current direction masks which allow
; a quick check to see if player just reversed direction
reverse_direction_table
	;		R,L,U,D
	dc.b	0,1,0,0	; R	
	dc.b	1,0,0,0	; L
	dc.b	0,0,0,1	; U
	dc.b	0,0,1,0	; D
	
jump_height_table
	dc.b	-2,-2,-2,-2,-2,-2,-1,-2,-1,-2,-1,-1,-1,0,-1,-1,0,0,0,-1
	dc.b	1,0,0,0,1,1,0,1,1,1,2,1,2,1,2,2,2,2,2,2
jump_height_table_end    

; attack timeouts

attack_timeout_table
    IFD THIEF_AI_TEST
    dc.w    ORIGINAL_TICKS_PER_SEC*10
    dc.w    ORIGINAL_TICKS_PER_SEC*2
    ENDC
    dc.w    ORIGINAL_TICKS_PER_SEC*100
    dc.w    ORIGINAL_TICKS_PER_SEC*80
    dc.w    ORIGINAL_TICKS_PER_SEC*65
    dc.w    ORIGINAL_TICKS_PER_SEC*55
    dc.w    ORIGINAL_TICKS_PER_SEC*53
    dc.w    ORIGINAL_TICKS_PER_SEC*25
    dc.w    ORIGINAL_TICKS_PER_SEC*12
    dc.w    ORIGINAL_TICKS_PER_SEC*10
    dc.w    ORIGINAL_TICKS_PER_SEC*8
    dc.w    ORIGINAL_TICKS_PER_SEC*5
    dc.w    ORIGINAL_TICKS_PER_SEC*4
    dc.w    ORIGINAL_TICKS_PER_SEC*3
    dc.w    ORIGINAL_TICKS_PER_SEC*2
    dc.w    ORIGINAL_TICKS_PER_SEC*1


; enemy speed increasing, level 1-2: 20/20 level 3-4: 20/19 levl 5-6: 20/18
;  level 8: 20/16 level 9-13: 20/15, at level 15 reaches 20/13 speed (max)

 ; speed table at 60 Hz
speed_table:
    dc.l    speed_level_12,speed_level_34,speed_level_56,speed_level_78
    dc.l    speed_level_913,speed_level_913,speed_level_15
    
speed_level_12:
    REPT    20
    dc.b   1
    ENDR
    
speed_level_34:
    REPT    10
    dc.b   1
    ENDR
    dc.b    2
    REPT    9
    dc.b   1
    ENDR
    
speed_level_56:
    REPT    6
    dc.b   1
    ENDR
    dc.b    2
    REPT    6
    dc.b   1
    ENDR
    dc.b    2
    REPT    6
    dc.b   1
    ENDR
    
speed_level_78:
    REPT    4
    dc.b   1
    ENDR
    dc.b    2
    REPT    4
    dc.b   1
    ENDR
    dc.b    2
    REPT    4
    dc.b   1
    ENDR
    dc.b    2
    REPT    4
    dc.b   1
    ENDR
    
speed_level_913:
    REPT    3
    dc.b   1
    ENDR
    dc.b    2
    REPT    4
    dc.b   1
    ENDR
    dc.b    2
    REPT    3
    dc.b   1
    ENDR
    dc.b    2
    REPT    4
    dc.b   1
    ENDR
    dc.b    2
    REPT    3
    dc.b   1
    ENDR

speed_level_15:     ; x1.5 speed!!!
    REPT    10
    dc.b    1
    dc.b    2
    ENDR

    
enemy_start_position_table
    dc.l    .level1
    dc.l    .level2
    dc.l    .level3
    dc.l    .level1

.level1:
    REPT    6
    dc.w    REPTN*40,0
    ENDR
.level2
    dc.w    0,0
    dc.w    40,36
    dc.w    80,36+24
    dc.w    120,36+48
    dc.w    160,36+24*3
    dc.w    200,36+24*4
.level3
    dc.w    120,0
    dc.w    120,36
    dc.w    120,36+24
    dc.w    120,106
    dc.w    120,176-24
    dc.w    120,176

game_palette
    include "palette.s"



    
player:
    ds.b    Player_SIZEOF
    even

enemies:
    ds.b    Enemy_SIZEOF*7
    even

leaving_paint_tile_x
	dc.w	0
leaving_paint_tile_y
	dc.w	0
	
rollback_paint_zone_pointer:
    dc.l    0
rollback_rectangle_pointer:
    dc.l    0
rollback_dot_table_pointer:
    dc.l    0
pending_paint_rectangle_pointer:
    dc.l    0
    
keyboard_table:
    ds.b    $100,0
    
floppy_file
    dc.b    "floppy",0
maze_dump_file
    dc.b    "maze.bin",0
    even

; table with 2 bytes: 60hz clock, 1 byte: move mask for the demo
demo_moves_1:

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
    
    IFD   RECORD_INPUT_TABLE_SIZE
record_input_table:
    ds.b    RECORD_INPUT_TABLE_SIZE
    ENDC
    
grid_backup_plane
    ds.b    SCREEN_PLANE_SIZE
rect_backup_plane
    ds.b    SCREEN_PLANE_SIZE
paint_backup_plane
    ds.b    SCREEN_PLANE_SIZE
maze_wall_table_copy
    ds.b    NB_TILE_LINES*NB_TILES_PER_LINE
    
rollback_paint_zone_buffer:
    ds.l    NB_ROLLBACK_SLOTS*2
rollback_paint_zone_buffer_end
rollback_rectangle_buffer:
    ds.l    NB_ROLLBACK_SLOTS
rollback_rectangle_buffer_end
rollback_dot_table_buffer:
    ds.l    NB_ROLLBACK_SLOTS
rollback_dot_table_buffer_end
pending_paint_rectangle_buffer:
    ds.l    6

player_move_buffer
    ds.l    NB_RECORDED_MOVES
    even
    
    
    SECTION  S4,CODE
    include ptplayer.s

    SECTION  S5,DATA,CHIP
; main copper list
coplist
   dc.l  $01080000
   dc.l  $010a0000
bitplanes:
   dc.l  $00e00000
   dc.l  $00e20000
   dc.l  $00e40000
   dc.l  $00e60000
   dc.l  $00e80000
   dc.l  $00ea0000
   dc.l  $00ec0000
   dc.l  $00ee0000
;   dc.l  $00f00000
;   dc.l  $00f20000

tunnel_color_reg = color+38

colors:
   dc.w color,0     ; fix black (so debug can flash color0)
sprites:
enemy_sprites:
intro_green_police:
bonus_banana:
    ; #0
    dc.w    sprpt+0,0
    dc.w    sprpt+2,0
    ; #1
    dc.w    sprpt+4,0
    dc.w    sprpt+6,0
intro_cattle_pink:
    ; #2
    dc.w    sprpt+8,0
    dc.w    sprpt+10,0
    ; #3
    dc.w    sprpt+12,0
    dc.w    sprpt+14,0
intro_cyan_cattle:    
    ; #4
    dc.w    sprpt+16,0
    dc.w    sprpt+18,0
    ; #5
    dc.w    sprpt+20,0
    dc.w    sprpt+22,0
    ; #6
thief_sprite:
    dc.w    sprpt+24,0
    dc.w    sprpt+26,0
    ; #7
    dc.w    sprpt+28,0
    dc.w    sprpt+30,0
end_color_copper:
   dc.w  diwstrt,$3081            ;  DIWSTRT
   dc.w  diwstop,$28c1            ;  DIWSTOP
   ; proper sprite priority: above bitplanes
   dc.w  $0102,$0000            ;  BPLCON1 := 0x0000
   dc.w  $0104,$0024            ;  BPLCON2 := 0x0024
   dc.w  $0092,$0038            ;  DDFSTRT := 0x0038
   dc.w  $0094,$00d0            ;  DDFSTOP := 0x00d0
   dc.w  $FFDF,$FFFE            ; PAL wait (256)
   dc.w  $2201,$FFFE            ; PAL extra wait (around 288)
   dc.w intreq,$8010            ; generate copper interrupt
    dc.l    -2

  
    
copier_left_0
    incbin  "copier_left_0.bin"
copier_left_1    
    incbin  "copier_left_1.bin"
copier_right_0
    incbin  "copier_right_0.bin"
copier_right_1    
    incbin  "copier_right_1.bin"
copier_up_0
copier_down_0
    incbin  "copier_updown_0.bin"
copier_up_1
copier_down_1
    incbin  "copier_updown_1.bin"
copier_dead_0
    incbin  "copier_dead_0.bin"
copier_dead_1
    incbin  "copier_dead_1.bin"
copier_dead_2
    incbin  "copier_dead_2.bin"
copier_dead_table
    dc.l    copier_dead_0,copier_dead_1,copier_dead_2


rustler_left_0
    incbin  "rustler_left_0.bin"
rustler_left_1    
    incbin  "rustler_left_1.bin"
rustler_right_0
    incbin  "rustler_right_0.bin"
rustler_right_1    
    incbin  "rustler_right_1.bin"
rustler_up_0
    incbin  "rustler_up_0.bin"
rustler_up_1
    incbin  "rustler_up_1.bin"
rustler_down_0
    incbin  "rustler_down_0.bin"
rustler_down_1
    incbin  "rustler_down_1.bin"
rustler_dead_0
    incbin  "rustler_dead_0.bin"
rustler_dead_1
    incbin  "rustler_dead_1.bin"
rustler_dead_2
    incbin  "rustler_dead_2.bin"
rustler_dead_table
    dc.l    rustler_dead_0,rustler_dead_1,rustler_dead_2

empty_16x16_bob
    ds.b    64*4,0

lives
    incbin  "life.bin"
star
    incbin  "star.bin"

    
DECL_POLICE:MACRO
police\1_frame_table:
    dc.l    police\1_0
    dc.l    police\1_1
    dc.l    police\1_2
    dc.l    police\1_3
police\1_end_frame_table:
police\1_jump_frame_table:
    dc.l    police\1_jump_0
    dc.l    police\1_jump_1
police\1_jump_end_frame_table:
police\1_hang_frame_table:
    dc.l    police\1_hang_0
    dc.l    police\1_hang_1
police\1_hang_end_frame_table:
police\1_kill_frame_table:
    dc.l    police\1_kill_0
    dc.l    police\1_kill_1
    dc.l    police\1_kill_0
    dc.l    police\1_kill_1
police\1_kill_end_frame_table:
police\1_fall_frame_table:
    dc.l    police\1_fall_0
    dc.l    police\1_fall_1
    dc.l    police\1_fall_2
    dc.l    police\1_fall_3
police\1_fall_end_frame_table:
police\1_score_frame_table:
    dc.l    police\1_score_200
    dc.l    police\1_score_400
    dc.l    police\1_score_800
    dc.l    police\1_score_1600
    dc.l    police\1_score_3200
    
    ; all enemies share the same graphics, only the colors are different
    ; but we need to replicate the graphics 8*4 times because of sprite control word
police\1_0
    dc.l    0
    incbin  "police_0.bin"
    dc.l    0
police\1_1
    dc.l    0
    incbin  "police_1.bin"
    dc.l    0
police\1_2
    dc.l    0
    incbin  "police_2.bin"
    dc.l    0
police\1_3
    dc.l    0
    incbin  "police_3.bin"
    dc.l    0
police\1_hang_0
    dc.l    0
    incbin  "police_hang_0.bin"
    dc.l    0
police\1_hang_1
    dc.l    0
    incbin  "police_hang_1.bin"
    dc.l    0
police\1_jump_0
    dc.l    0
    incbin  "police_jump_0.bin"
    dc.l    0
police\1_jump_1
    dc.l    0
    incbin  "police_jump_1.bin"
    dc.l    0
police\1_kill_0
police\1_fall_0
    dc.l    0
    incbin  "police_fall_0.bin"
    dc.l    0
police\1_fall_1
    dc.l    0
    incbin  "police_fall_1.bin"
    dc.l    0
police\1_fall_2
    dc.l    0
    incbin  "police_fall_2.bin"
    dc.l    0
police\1_fall_3
    dc.l    0
    incbin  "police_fall_3.bin"
    dc.l    0
police\1_kill_1
    dc.l    0
    incbin  "police_kill.bin"
    dc.l    0
police\1_score_200:
    dc.l    0
    incbin  "scores_200.bin"
    dc.l    0
police\1_score_400:
    dc.l    0
    incbin  "scores_400.bin"
    dc.l    0
police\1_score_800:
    dc.l    0
    incbin  "scores_800.bin"
    dc.l    0
police\1_score_1600:
    dc.l    0
    incbin  "scores_1600.bin"
    dc.l    0
police\1_score_3200:
    dc.l    0
    incbin  "scores_3200.bin"
    dc.l    0

    ENDM
        
    DECL_POLICE  1
    DECL_POLICE  2
    DECL_POLICE  3
    DECL_POLICE  4
    DECL_POLICE  5
    DECL_POLICE  6
    DECL_POLICE  7



    
DECL_CATTLE:MACRO
cattle\1_frame_table:
    dc.l    cattle\1_0
    dc.l    cattle\1_1
    dc.l    cattle\1_0
    dc.l    cattle\1_1
cattle\1_end_frame_table:
cattle\1_jump_frame_table:
    dc.l    cattle\1_jump_0
    dc.l    cattle\1_jump_1
cattle\1_jump_end_frame_table:
cattle\1_hang_frame_table:
    dc.l    cattle\1_hang_0
    dc.l    cattle\1_hang_1
cattle\1_hang_end_frame_table:
cattle\1_kill_frame_table:
    dc.l    cattle\1_kill_0
    dc.l    cattle\1_kill_1
    dc.l    cattle\1_kill_2
    dc.l    cattle\1_kill_3
cattle\1_kill_end_frame_table:
cattle\1_fall_frame_table:
    dc.l    cattle\1_fall_0
    dc.l    cattle\1_fall_1
    dc.l    cattle\1_fall_2
    dc.l    cattle\1_fall_3
cattle\1_fall_end_frame_table:
cattle\1_score_table:   ; no need to copy score sprites
    dc.l    police\1_score_200
    dc.l    police\1_score_400
    dc.l    police\1_score_800
    dc.l    police\1_score_1600
    dc.l    police\1_score_1600
    dc.l    police\1_score_3200

    
    ; all enemies share the same graphics, only the colors are different
    ; but we need to replicate the graphics 8*4 times because of sprite control word
cattle\1_0
    dc.l    0
    incbin  "cattle_0.bin"
    dc.l    0
cattle\1_1
    dc.l    0
    incbin  "cattle_1.bin"
    dc.l    0
cattle\1_hang_0
    dc.l    0
    incbin  "cattle_hang_0.bin"
    dc.l    0
cattle\1_hang_1
    dc.l    0
    incbin  "cattle_hang_1.bin"
    dc.l    0
cattle\1_kill_2
cattle\1_jump_0
    dc.l    0
    incbin  "cattle_jump_0.bin"
    dc.l    0
cattle\1_kill_3
cattle\1_jump_1
    dc.l    0
    incbin  "cattle_jump_1.bin"
    dc.l    0
cattle\1_fall_0
    dc.l    0
    incbin  "cattle_fall_0.bin"
    dc.l    0
cattle\1_kill_0
cattle\1_fall_1
    dc.l    0
    incbin  "cattle_fall_1.bin"
    dc.l    0
cattle\1_fall_2
    dc.l    0
    incbin  "cattle_fall_2.bin"
    dc.l    0
cattle\1_fall_3
    dc.l    0
    incbin  "cattle_fall_3.bin"
    dc.l    0
cattle\1_kill_1
    dc.l    0
    incbin  "cattle_kill.bin"
    dc.l    0

    ENDM
        
    DECL_CATTLE  1
    DECL_CATTLE  2
    DECL_CATTLE  3
    DECL_CATTLE  4
    DECL_CATTLE  5
    DECL_CATTLE  6
    DECL_CATTLE  7
    

score_5000:
    dc.l    0
    incbin  "scores_5000.bin"
    dc.l    0


thief_attacks_raw
    incbin  "thief_attacks.raw"
    even
thief_attacks_raw_end


credit_raw
    incbin  "credit.raw"
    even
credit_raw_end



lose_bonus_raw
    incbin  "lose_bonus.raw"
    even
lose_bonus_raw_end


ping_raw
    incbin  "ping.raw"
    even
ping_raw_end
enemy_hit_raw
    incbin  "enemy_hit.raw"
    even
enemy_hit_raw_end
enemy_killed_raw
    incbin  "enemy_killed.raw"
    even
enemy_killed_raw_end
extra_life_raw
    incbin  "extra_life.raw"
    even
extra_life_raw_end
enemy_falling_raw
    incbin  "enemy_falling.raw"
    even
enemy_falling_raw_end
player_killed_raw
    incbin  "player_killed.raw"
    even
player_killed_raw_end

eat_raw
    incbin  "eat.raw"
    even
eat_raw_end
filled_raw
    incbin  "filled.raw"
    even
filled_raw_end
paint_raw
    incbin  "paint.raw"
    even
paint_raw_end
jump_raw
    incbin  "jump.raw"
    even
jump_raw_end

    even

      
empty_sprite
    dc.l    0,0

    
    SECTION S_4,BSS,CHIP
    ; erase method erases one line above
    ; and character can be drawn at y=0 so add some memory
    ; to avoid corrupting memory
    ds.b    NB_BYTES_PER_LINE*NB_PLANES
screen_data:
    ds.b    SCREEN_PLANE_SIZE*NB_PLANES+NB_BYTES_PER_LINE,0

    
    	