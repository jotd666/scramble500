;
; Scramble (C) 1981 KONAMI.
;
; Reverse engineering work by Scott Tunstall, Paisley, Scotland. 
; Tools used: MAME debugger & Visual Studio Code text editor.
; Date: 28 May 2021. Keep checking for updates. 
; 
; Please send any questions, corrections and updates to scott.tunstall@ntlworld.com
;
; Thanks go to Phil Murray for misc help and Mark McDougall for his very thorough code review.
; Check out Mark's blog about transcoding this source to the Neo Geo here: http://retroports.blogspot.com/2021/04/scrambled-priorities.html
;
; Be sure to check out my reverse engineering work for Robotron 2084, Galaxian and Berzerk too, 
; at http://seanriddle.com/robomame.asm, http://seanriddle.com/galaxian.asm and http://seanriddle.com/berzerk.asm respectively.
;
; 
; Finally:
; If you'd like to show appreciation for this work by buying me a coffee, feel free: https://ko-fi.com/scotttunstall
; I'd be equally happy if you donated to Parkinsons UK or Chest Heart And Stroke (CHAS) Scotland.
; Thanks. 

/*
Conventions: 

NUMBERS
=======

The term "@ $" means "at memory address in hexadecimal". 
e.g. @ $1234 means "refer to memory address 1234" or "program code @ memory location 1234" 

The term "#$" means "immediate value in hexadecimal". It's a convention I have kept from 6502 days.
e.g. #$60 means "immediate value of 60 hex" (96 decimal)

If I don't prefix a number with $ or #$ in my comments, treat the value as a decimal number.


ARRAYS, LISTS, TABLES
=====================

The terms "entry", "slot", "item", "record" when used in an array, list or table context all mean the same thing.
I try to be consistent with my terminology but I might not always succeed.

"Length" when used in terms of an array refers to how many elements it contains. 

SizeOf refers to the size in bytes of a structure (as it does in C).

Unless I specify otherwise, I all indexes into arrays/lists/tables are zero-based, 
meaning element [0] is the first element, [1] the second, [2] the third and so on.


FLAGS
=====

The terms "Clear", "Reset", "Unset" in a flag context all mean the flag is set to zero.
A non-zero value in a flag means the flag is "set" - unless I specify otherwise.
                                                                               

COORDINATES
===========

X,Y refer to the X and Y axis in a Cartesian 2D coordinate system, where X is horizontal and Y is vertical.

Like Galaxian, the Scramble monitor is rotated 90 degrees. This means that:
a) updating the hardware Y position of a sprite presents itself to the player as changing the horizontal position.
   To make a sprite appear to move left, you would increment its Y position.
   To make a sprite appear to move right, you would decrement its Y position.

b) updating the hardware X position of a sprite presents itself to the player as changing the vertical position. 
   To make a sprite appear to move up, you would decrement its X position.
   To make a sprite appear to move down, you would increment its X position.

So, when you see code updating the Y coordinate when you would expect X to be updated, or vice versa, you now know why.


TODOs:
======
TODOs are for me to look at later, when a piece of code isn't immediately obvious.
Anyone who knows me, knows I like leaving TODOs in code :)

*/

/*
Copied from MAME4All documentation: https://github.com/squidrpi/mame4all-pi/blob/master/src/drivers/scramble.cpp
Port mappings copied from https://github.com/mamedev/mame/blob/master/src/mame/drivers/scramble.cpp

MAIN BOARD:
0000-3fff ROM
4000-47ff RAM
4800-4fff Character RAM  (Yes, $4fff, mame4all docs are incorrect)
5000-50ff Object RAM
    5000-503f  screen attributes
    5040-505f  sprites
    5060-507f  bullets
    5080-50ff  RAM

read:
7000      Watchdog Reset (Scramble)
8100      IN0
          PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_UP ) PORT_8WAY PORT_COCKTAIL
          PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_BUTTON2 )
          PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_SERVICE1 )
          PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_BUTTON1 )
          PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT ) PORT_8WAY
          PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT ) PORT_8WAY
          PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_COIN2 )
          PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_COIN1 )

8101      IN1
          PORT_DIPNAME( 0x03, 0x00, "Lives") PORT_DIPLOCATION("SW1:2,1")
          PORT_DIPSETTING(    0x00, "3" )
          PORT_DIPSETTING(    0x01, "4" )
          PORT_DIPSETTING(    0x02, "5" )
          PORT_DIPSETTING(    0x03, DEF_STR( Free_Play ) )
          PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_BUTTON2 ) PORT_COCKTAIL
          PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_BUTTON1 ) PORT_COCKTAIL
          PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT ) PORT_8WAY PORT_COCKTAIL
          PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT ) PORT_8WAY PORT_COCKTAIL
          PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_START2 )
          PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_START1 )

8102      IN2 
          PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN ) PORT_8WAY PORT_COCKTAIL

          ; Some examples of Coinage settings and explanation of purpose:
          ; "A 1/1 B 2/1 C 1/1" means "Slot A: ONE coin / ONE credit.  Slot B: TWO coins / ONE credit.  Slot C (SERVICE button) : ONE press / ONE credit."
          ; "A 1/2 B 1/1 C 1/2" means "Slot A: ONE coin / TWO credits.  Slot B: ONE coin / ONE credit.  Slot C (SERVICE button) : ONE press / TWO credits."
          PORT_DIPNAME( 0x06, 0x00, "Coinage" PORT_DIPLOCATION("SW1:5,4")
          PORT_DIPSETTING(    0x00, "Coinage A 1/1 B 2/1 C 1/1")
          PORT_DIPSETTING(    0x02, "Coinage A 1/2 B 1/1 C 1/2")
          PORT_DIPSETTING(    0x04, "Coinage A 1/3 B 3/1 C 1/3" )
          PORT_DIPSETTING(    0x06, "Coinage A 1/4 B 4/1 C 1/4" )
          
          PORT_DIPNAME( 0x08, 0x00, "Cabinet") PORT_DIPLOCATION("SW1:3")
          PORT_DIPSETTING(    0x00, "Upright")
          PORT_DIPSETTING(    0x08, "Cocktail")

          PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_JOYSTICK_UP ) PORT_8WAY
          PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_CUSTOM )    /* protection bit */
          PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN ) PORT_8WAY
          PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_CUSTOM )    /* protection bit */


write:
6801      interrupt enable
6802      coin counter
6803      POUT1 - affects screen background colour (0=black, 1 = blue) - thanks to Phil Murray for telling me about this
6804      stars on
6806      screen vertical flip
6807      screen horizontal flip
8200      To AY-3-8910 port A (commands for the audio CPU)
8201      bit 3 = interrupt trigger on audio CPU  bit 4 = disable sound (see scramble_state::scramble_sh_irqtrigger_w in MAME's scramble audio driver)
8202      protection check bits

SOUND BOARD:
0000-1fff ROM
8000-83ff RAM


I/O ports:
read:
20      8910 #2  read
80      8910 #1  read
write
10      8910 #2  control20      8910 #2  write
40      8910 #1  control
80      8910 #1  write

interrupts:
interrupt mode 1 triggered by the main CPU

*/


;
; Value in COINAGE_VALUE            What it represents                       
; ======================            =========================              
; 0                                 Coinage A 1/1 B 2/1 C 1/1                 
; 1                                 Coinage A 1/2 B 1/1 C 1/2              
; 2                                 Coinage A 1/3 B 3/1 C 1/3              
; 3                                 Coinage A 1/4 B 4/1 C 1/4              
;
; ** See hardware info above for explanation of coinage settings **

COINAGE_VALUE                       EQU $4000         
COIN_COUNTER                        EQU $4001         ; Used to coint up to number of coins required to gain a single credit. See $0A80. 
NUM_CREDITS                         EQU $4002         ; number of credits. See $0A68 and $0A80.
                                    EQU $4003         
                                    EQU $4004

;
; The game follows what I call "scripts". A SCRIPT is a predefined sequence of STAGES (ie: subroutines) that implement an overall goal.
; The whole game is script-driven, from attract mode to the game itself.
;
; The NMI interrupt handler uses SCRIPT_NUMBER ($4005) to identify what script to run and, depending on the script, SCRIPT_STAGE ($400A) to 
; determine what subroutine to call to do the work for that stage of the script.  When the subroutine has completed its work, 
; it increments SCRIPT_STAGE which is akin to, "OK, I'm done; proceed to next stage of script".
;
; For example, a script for HELLO WORLD might be implemented as three stages:
; 1. Display Hello World on screen. Set SCRIPT_STAGE to 2.
; 2. Wait for key. Set SCRIPT_STAGE to 3 after key pressed.
; 3. Terminate program.
;
; The main take-aways from the above are:
; 1. The whole game is driven by the NMI interrupt.
; 2. Script stage and number are really just indexes into jump tables. 
;
; see $21F5 for the NMI script handler. 

SCRIPT_NUMBER                       EQU $4005         ; 0-based index into pointer table beginning @ $21F9
IS_GAME_IN_PLAY                     EQU $4006         ; If set to 1, game is in play with a human in control.
DEFAULT_PLAYER_LIVES                EQU $4007         ; Number of lives you get when starting game. Controlled by dip switches.  See $0115
TEMP_COUNTER_4008                   EQU $4008         ; temporary counter used for delays, such as waiting before transitioning to next stage of a script
TEMP_COUNTER_4009                   EQU $4009         ; temporary counter used for delays
SCRIPT_STAGE                        EQU $400A         ; Identifies what stage of script [SCRIPT_NUMBER] we are at. See $0E87, $0FD2, $0FEA 
TEMP_CHAR_RAM_PTR                   EQU $400B         ; pointer to character RAM. Used by screen-related routines (e.g. power on colour test) to remember where to plot characters on next call.
CURRENT_PLAYER                      EQU $400D         ; 0 = PLAYER ONE, 1 = PLAYER TWO                
IS_TWO_PLAYER_GAME                  EQU $400E         ; 0 = One player game, 1 = 2 player game 
IS_COCKTAIL                         EQU $400F         ; 0 = upright, 1 = Cocktail 
PORT_STATE_8100                     EQU $4010         ; copy of state for memory address 8100 (IN0)          


; Value in PORT_STATE_8101          What it means
; =========================         ==========================
; 3                                 Players lives default to 3    
; 2                                 Players lives default to 4
; 1                                 Players lives default to 5
PORT_STATE_8101                     EQU $4011         ; copy of state for memory address 8101 (IN1)
               

;
PORT_STATE_8102                     EQU $4012         ; copy of state for memory address 8102 (IN2)
PREV_PORT_STATE_8100                EQU $4013         ; holds the previous state of memory address 8100 (IN0)  
PREV_PORT_STATE_8101                EQU $4014         ; holds the previous state of memory address 8101 (IN1)
PREV_PREV_PORT_STATE_8100           EQU $4015         ; holds the previous, previous (!) state of memory address 8100 (IN0) 
PREV_PREV_PREV_STATE_8100           EQU $4016         ; holds the previous, previous, previous state of memory address 8100 (IN0)
BONUS_JET_FOR                       EQU $4017         ; BCD value representing how many multiples of a thousand required to get a bonus jet, e.g. 10 = 10000        
UNPROCESSED_COINS                   EQU $4018         ; bumps up when coin inserted 
DRAW_LANDSCAPE_FLAG                 EQU $4019         ; when set to 1, landscape and ground objects will be drawn & updated. See $020D
LANDSCAPE_COLOUR_CHANGE_COUNTER     EQU $401B         ;  


; Object RAM back buffer. 
; Colour attributes, scroll offsets and sprite state are held in this buffer and updated by the game. 
; When all the updates are complete and ready to be presented on screen to the player, 
; the back buffer is copied to the hardware's OBJRAM by an LDIR operation - see $09D2.
; Effectively all colours, scroll and sprites are updated as part of a single operation.
; This back buffering technique is still used today in modern games.
;
; The back buffer is organised thus:
;
; From $4020 - 405f: column scroll and colour attributes. Labelled as OBJRAM_BACK_BUF_ATTRIBUTES in this document. Maps directly to $5000 - $503F. 
;    Note: Even numbered addresses hold scroll offsets, odd numbered addresses colour attributes. 
; From $4060 - 407F: 8 entries of type SPRITE. Labelled as OBJRAM_BACK_BUF_SPRITES in this document. Maps directly to $5040-$505f.
; From $4080 - 409F: 8 entries of type BULLET_SPRITE.  Labelled as OBJRAM_BACK_BUF_BULLETS in this document. Maps directly to $5060-$507f.

OBJRAM_BACK_BUF                     EQU $4020 
OBJRAM_BACK_BUF_ATTRIBUTES          EQU $4020           

; represents a hardware sprite
struct SPRITE
{
   BYTE Y;                          ; Y coordinate
   BYTE Code;                       ; Determines animation frame                
   BYTE Colour;                     ; Core (individual) colour of sprite - other colours shared between all sprites 
   BYTE X;                          ; X coordinate
} - sizeof(SPRITE) is 4 bytes

; 
OBJRAM_BACK_BUF_SPRITES             EQU $4060

; represents a hardware bullet sprite
struct BULLET_SPRITE
{
    BYTE ???                        ; Setting this byte in MAME debugger appears to do nothing. 
    BYTE Y;
    BYTE ???                        ; Does nothing.
    BYTE X;
}

OBJRAM_BACK_BUF_BULLETS             EQU $4080

; $40C0 to $40FF is reserved for a circular queue. The queue is comprised of byte pairs representing a command and parameter.
; NB: I term the byte pair a *Queue Entry* in the code @$0038 and $01C1.
;
; As 64 bytes are reserved for the queue, that means 32 commands and parameters can be stored. 
;
; The memory layout of the queue is quite simple.
; 
; $40C0: command A
; $40C1: parameter for command A 
; $40C2: command B
; $40C3: parameter for command B
; $40C4: command C
; $40C5: parameter for command C
; ..and so on.
;
; See docs @ $0038 for info about what commands are available, and how to add commands to the queue.
; See docs @ $01C1 for info about how commands are processed.
;

CIRC_CMD_QUEUE_PTR_LO               EQU $40A0         ; low byte of a pointer to a (hopefully) vacant entry in the circular queue. 
CIRC_CMD_QUEUE_PROC_LO              EQU $40A1         ; low byte of a pointer to the next entry in the circular queue to be processed.
CIRC_CMD_QUEUE_START                EQU $40C0
CIRC_CMD_QUEUE_END                  EQU $40FF

PLAYER_ONE_SCORE                    EQU $40A2         ; stored as 3 BCD bytes, 2 digits per byte: $40A2 = last 2 digits of score (tens), $40A3 = 3rd & 4th digits, $40A4 = 1st & 2nd
                                                      ; e.g. a score of 123456 would be stored like so:
                                                      ; $40A2: 56
                                                      ; $40A3: 34
                                                      ; $40A4: 12

PLAYER_TWO_SCORE                    EQU $40A5         ; stored as 3 BCD bytes, 2 digits per byte: same format & order as PLAYER_ONE_SCORE
HI_SCORE                            EQU $40A8         ; stored as 3 BCD bytes, 2 digits per byte: same format & order as PLAYER_ONE_SCORE
MYSTERY_SCORE                       EQU $40AB         ; stored as 3 BCD bytes, 2 digits per byte: same format & order as PLAYER_ONE_SCORE

IS_COLUMN_SCROLLING                 EQU $40B0         ; Unused
COLUMN_SCROLL_ATTR_BACKBUF_PTR      EQU $40B1         ; Unused

PROTECTION_1                        EQU $40B8
PROTECTION_PORT_PTR_1               EQU $40B9         ; contains a pointer to $8202, the protection check bits (see memory map at start of document)
    PROTECTION_PORT_PTR_1_LO        EQU $40B9
    PROTECTION_PORT_PTR_1_HI        EQU $40BA 
              
PROTECTION_PORT_PTR_2               EQU $40BB



CURRENT_PLAYER_STATE                EQU $4100
CURRENT_PLAYER_MISSIONS_COMPLETED   EQU $4100         ; Determines how many flags are displayed at the bottom right of the screen. See $0920
                                    EQU $4101         ; TODO: See $08C0
                                    EQU $4102         ; TODO: See $08DF
CURRENT_PLAYER_FUEL                 EQU $4105         ; 0 = Empty, 255 = full tank . See $0880
CURRENT_PLAYER_FUEL_DRAIN_COUNTER   EQU $4106         ; Counter affecting fuel consumption rate. Lower = faster. See $1725 and especially $29B5
CURRENT_PLAYER_HAD_EXTRA_LIFE       EQU $4107         ; Flag used to check if player can be awarded an extra life. 1 = No, Player already awarded extra life. See $13A7. 
CURRENT_PLAYER_LIVES                EQU $4108         ; Number of lives the current player has. See $08FB 
CAN_DRAW_LANDSCAPE_1                EQU $4110         ; Used in conjunction with CAN_DRAW_LANDSCAPE_2. Flag required for DRAW_LANDSCAPE to do its thing. See $0793.
DISABLE_STARS                       EQU $4111         ; Flag that determines whether blinking background starfield is disabled . Set to 1 if level has a ceiling. See $16A3 for when set, and $2821 for code that checks flag.    
IS_MISSION_COMPLETE                 EQU $4112         ; Flag. Set to $FF to complete the mission and run the MISSION_COMPLETED_SCRIPT (see $127E).  See also $22C9 and $232F

LANDSCAPE_SCROLL_CONTROL_LATCH      EQU $4114         ; This value is used to reload LANDSCAPE_SCROLL_CONTROL_COUNTER when it counts down to 0. See $15AF  
LANDSCAPE_SCROLL_CONTROL_COUNTER    EQU $4115         ; Controls when LANDSCAPE_SCROLL_COUNTER increments. See $15A9   
LANDSCAPE_SCROLL_COUNTER            EQU $4116         ; Used to determine when to scroll new landscape & objects on and the character RAM locations to plot them to. See $15B5 and $15D7           
LANDSCAPE_COLOUR                    EQU $4117         ; Primary colour of the landscape. See $2810
LANDSCAPE_LAYOUT_PTR                EQU $4118         ; Points to next piece of landscape to scroll on. See $15C5 for overview, $15CB and $1854
    LANDSCAPE_LAYOUT_PTR_LO         EQU $4118                       
    LANDSCAPE_LAYOUT_PTR_HI         EQU $4119 

;
; NEXT_GROUND_OBJECT_ID identifies - you guessed - the next ground object (fuel tank, stationary rocket, mystery, base) to scroll onto the screen. 
; 
; NEXT_GROUND_OBJECT_ID is set by @$163F within the DECODE_LANDSCAPE_FLOOR routine.
;
; Value         Ground Object type          
; ================================
; 1             Rocket
; 2             Fuel tank
; 4             Mystery
; 8             Base (I think it looks more like a drilling rig, personally!) 
;
NEXT_GROUND_OBJECT_ID               EQU $411A         

; NEXT_GROUND_OBJECT_CHAR_PTR is the character RAM address where the next ground object will be drawn. See GROUND_OBJECT_INIT @ $18E6 
NEXT_GROUND_OBJECT_CHAR_PTR         EQU $411B           

;
; LANDSCAPE_FLAGS are bit flags used to determine:
;     * How the landscape looks (see $07CE, $07F1, $081B); 
;     * What enemies appear (see table below)
;     * What ambient noises are played. (See $298E in AMBIENT_SOUND)
;
;
;  Flags Value      Applies to Level      INFLIGHT_ENEMY type
;  ===================================================================         
;  0                1                     Rockets (see $1CA7)
;  2                2                     UFOs (see $1D84)                   
;  1                3                     Fireballs (see $1EC6)             
;  8                4                     Rockets (see $1CAD)               
;  4                5                     None                 
;  10               BASE                  None
;

LANDSCAPE_FLAGS                     EQU $411D          
CURRENT_PLAYERS_LEVEL               EQU $411E         ; Determines how many cells in the progress bar are coloured. See @$93E 
NO_APPARENT_PURPOSE_4130            EQU $4130         ; referenced in code @ $1002, but doesn't do anything

PLAYER_ONE_STATE                    EQU $4140
PLAYER_ONE_LIVES                    EQU $4148
NO_APPARENT_PURPOSE_4170            EQU $4170         ; referenced in code @ $1002 via LDIR, but doesn't do anything

PLAYER_TWO_STATE                    EQU $4180 
PLAYER_TWO_LIVES                    EQU $4188
                                    EQU $41B0


; Scramble's game logic doesn't do anything like per-pixel testing to check if a player jet/bullet/bomb sprite has crashed into a hill or cave wall; 
; instead it uses an array of LANDSCAPE_EXTENT records (LANDSCAPE_EXTENTS) for collision detection purposes. 
; A LANDSCAPE_EXTENT defines pixel boundaries that a player/ player bullet/ player bomb must stay within to stay alive.
;    
; Generally speaking, as long as the X coordinate of the player/ bullet / bomb is between CeilingX .. GroundX then no collision is registered. 
;
: (in pseudocode: bool HitLandscape = (X < CeilingX || X > GroundX);  )
;

struct LANDSCAPE_EXTENT
{
    BYTE GroundX;                 ; ground pixel X limit.  
    BYTE CeilingX;                ; ceiling pixel X limit. Is always < GroundX 
} // sizeof(LANDSCAPE_EXTENT) == 4 bytes

; LANDSCAPE_EXTENTS is an array of 32 LANDSCAPE_EXTENT records: one record per character row of the playfield (including areas scrolled off screen). 
; Each LANDSCAPE_EXTENT record requires 2 bytes; the array is thus 64 bytes in size.
;
; See also: 
;     RESET_LANDSCAPE_EXTENTS ($0FC3) , DECODE_LANDSCAPE_FLOOR ($15CB),  DECODE_LANDSCAPE_CEILING ($1659),
;     PLAYER_TO_LANDSCAPE_COLLISION_DETECTION ($2113),  PLAYER_BULLET_TO_LANDSCAPE_COLLISION_DETECTION ($238F), PLAYER_BOMB_TO_LANDSCAPE_COLLISION_DETECTION ($251E)  


LANDSCAPE_EXTENTS                 EQU $41C0 
         

;
; Scores are stored as 3 BCD bytes, 2 digits per byte: 
; e.g. a score of 123456 would be stored like so:
; 56 34 12 
;
HI_SCORE_TABLE                      EQU $4200
HI_SCORE_TABLE_1ST                  EQU $4200         ; top ranking score
HI_SCORE_TABLE_2ND                  EQU $4203
HI_SCORE_TABLE_3RD                  EQU $4206
HI_SCORE_TABLE_4TH                  EQU $4209
HI_SCORE_TABLE_5TH                  EQU $420C
HI_SCORE_TABLE_6TH                  EQU $420F
HI_SCORE_TABLE_7TH                  EQU $4212
HI_SCORE_TABLE_8TH                  EQU $4215
HI_SCORE_TABLE_9TH                  EQU $4218
HI_SCORE_TABLE_10TH                 EQU $421B         ; lowest ranking score
HI_SCORE_TABLE_BUFFER               EQU $421E         ; buffer area used when moving high scores - see $137F  

CAN_DRAW_LANDSCAPE_2                EQU $4230         ; Used in conjunction with CAN_DRAW_LANDSCAPE_1. See $0793          


;
; In Scramble, a new part of the landscape is rendered offscreen every 2 characters (16 pixels) ready to be scrolled on "Just in time"
;
; LANDSCAPE_GROUND_FIRST_CHAR and LANDSCAPE_GROUND_SECOND_CHAR are the "edge characters" of the new ground to be scrolled on.
; If LANDSCAPE_HAS_CEILING_FLAG = 1 then LANDSCAPE_CEILING_FIRST_CHAR and LANDSCAPE_CEILING_SECOND_CHAR are the "edge characters" of the new ceiling 
; to be scrolled on. DRAW_LANDSCAPE @ $0793 will "fill in" any gaps, to make the landscape look solid.
; 
; See READ_LANDSCAPE_LAYOUT @$15C5 and DRAW_LANDSCAPE @ $0793 for more detail.
;
; 

LANDSCAPE_GROUND_FIRST_CHAR         EQU $4231        ; ordinal of the first ground character to scroll onto screen. 
LANDSCAPE_GROUND_FIRST_CHAR_PTR     EQU $4232        ; pointer to character RAM where to plot character

LANDSCAPE_GROUND_SECOND_CHAR        EQU $4234        ; ordinal of the second ground character to scroll onto screen
LANDSCAPE_GROUND_SECOND_CHAR_PTR    EQU $4235        ; pointer to character RAM where to plot character

LANDSCAPE_HAS_CEILING_FLAG          EQU $4238        ; Set to 1 if the landscape to be drawn has a ceiling, such as the cave and the maze.  

; These fields are only used if LANDSCAPE_HAS_CEILING_FLAG is set to 1
LANDSCAPE_CEILING_FIRST_CHAR        EQU $4239        ; ordinal of the first ceiling character to scroll onto screen    
LANDSCAPE_CEILING_FIRST_CHAR_PTR    EQU $423A        ; pointer to character RAM where to plot character
LANDSCAPE_CEILING_SECOND_CHAR       EQU $423C        ; ordinal of the first ceiling character to scroll onto screen
LANDSCAPE_CEILING_SECOND_CHAR_PTR   EQU $423D        ; pointer to character RAM where to plot character


;
; $4243 - $425D is reserved for a circular queue of bytes, labelled CIRC_SOUND_CMD_QUEUE below. 
; Each byte represents a sound, or a melody, to play.  
; 
; CIRC_SOUND_CMD_QUEUE_PTR_LO and CIRC_SOUND_CMD_QUEUE_PROC_LO work independently within this circular queue.   
;
; Think of CIRC_SOUND_CMD_QUEUE_PTR_LO as the LSB of a pointer to where the next sound command requested will be stored, and 
; CIRC_SOUND_CMD_QUEUE_PROC_LO as the LSB of a pointer to the sound command being processed.
;
; If you want to add a sound, call QUEUE_SOUND_COMMAND @ $2877.
;
; The code PROCESS_CIRC_SOUND_CMD_QUEUE @ $2855 will process the entries in the queue. Any entry with a value of $FF is treated as "played".


CIRC_SOUND_CMD_QUEUE_PTR_LO         EQU $4240         ; low byte of a pointer to a (hopefully) vacant entry in the circular queue. 
CIRC_SOUND_CMD_QUEUE_PROC_LO        EQU $4241         ; low byte of a pointer to the next entry in the circular queue to be processed.

IRQTRIGGER_CTRL                     EQU $4242         ; Used to control $8201 

CIRC_SOUND_CMD_QUEUE                EQU $4243
CIRC_SOUND_CMD_QUEUE_START          EQU $4243
CIRC_SOUND_CMD_QUEUE_END            EQU $425D

TIMING_VARIABLE                     EQU $425F         ; Perpetually decremented by the NMI handler. Routines use this variable to determine when to execute.


;
; CHAR_BASED_GROUND_OBJECT are "lightweight" (ie: don't require much memory) "projections" of the master GROUND_OBJECT record used for rendering character-based 
; objects (targets!!) sitting atop the landscape, i.e.: unlaunched rockets, fuel tanks, mystery, base. 
;
; $1F59 details how CHAR_BASED_GROUND_OBJECTs are created. 
; $084B details how CHAR_BASED_GROUND_OBJECTS are rendered as a batch to character RAM. 
;
;
; Notes:
;
; Value in Code field               What it represents                
; ===================               ===================================================================
; 10                                Fuel tank
; 11                                100 [points value]
; 12                                200 [points value]
; 13                                300 [points value]
; 1C                                Stationary rocket
; 1F                                Base (I think it looks more like a drilling rig!) animation frame #1 
; 26                                Base animation frame #2
; 2F                                Base animation frame #3
; 33                                Mystery 
; 38                                Explosion animation frame #1
; 39                                Explosion animation frame #2
; 3A                                Explosion animation frame #3
; 3B                                Explosion animation frame #4
;

struct CHAR_BASED_GROUND_OBJECT
{
    BYTE Undrawn;                   ; Flag. When set to 0 this tells the system to render this object. See $085E.
    BYTE Code;                      ; Type of ground object. See table above. Multiply by 4 to get ordinal of first character to plot to char RAM in 2x2. See $0867.
    BYTE CharRamPtrLo;              ; LSB of character RAM address to begin drawing this object. See $086C.
    BYTE CharRamPtrHi;              ; MSB of character RAM address to begin drawing this object. See $086F.
}  // sizeof(CHAR_BASED_GROUND_OBJECT) == 4 bytes


; CHAR_BASED_GROUND_OBJECTS is a fixed-size 8 element array of type CHAR_BASED_GROUND_OBJECT. It is used by DRAW_ALL_CHARACTER_BASED_GROUND_OBJECTS @ $084B
; to render all ground objects.
;  
; Each CHAR_BASED_GROUND_OBJECT requires 4 bytes to hold its state; the array is thus 32 bytes in size. 
CHAR_BASED_GROUND_OBJECTS            EQU $4260         ; 


;
; GROUND_OBJECT is important. It holds the main state for a single ground-based destructible target. i.e.: unlaunched rockets, fuel tanks, mystery, base
; (As compared to CHAR_BASED_GROUND_OBJECT which is only used for rendering.)
;
; A new GROUND_OBJECT is spawned by one of the following functions when NEXT_GROUND_OBJECT_ID (see $411A above) contains a nonzero value:  
;     SPAWN_FUEL_TANK (see $26FA) 
;     SPAWN_MYSTERY (see $275E)
;     SPAWN_ROCKET_ON_GROUND (see $272C) 
;     SPAWN_BASE (see $2790)
;
; See GROUND_OBJECT_STAGE_OF_LIFE ($18C6) 
;
; A GROUND_OBJECT has a 1:1 relationship with a CHAR_BASED_GROUND_OBJECT.  
;

struct GROUND_OBJECT                                    
{
0   BYTE IsActive;                 ; Active flag. 1 = Active
    BYTE IsExploding;              ; Flag. Set to 1 when object is exploding
    BYTE StageOfLife;              ; Stage of life. See GROUND_OBJECT_STAGE_OF_LIFE @ $18C6
    BYTE X;                        ; X coordinate
4   BYTE Y;                        ; Y coordinate
    BYTE ???
    BYTE ???
    BYTE ???
8   BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
12  BYTE AnimPtrLo                 ; Low byte of pointer to animation table. See GROUND_OBJECT_INIT@$18E6 and ANIMATE @$13E4.
    BYTE AnimPtrHi                 ; high byte of pointer
    BYTE AnimationCounter
    BYTE ExplosionCounter          ; Determines how long an explosion animation lasts. Higher = longer. See $19AA.
16  BYTE ???
    BYTE ???
    BYTE Code                      ; Drives animation of CHAR_BASED_GROUND_OBJECT. Updated by ANIMATE @$13E4, then mapped to CHAR_BASED_GROUND_OBJECT @$1F7A
    BYTE ???
20  BYTE ???
    BYTE ???
    BYTE Colour
    BYTE ObjectType                ; 0 = Rocket, 1 = Fuel, 2 = Mystery, 3 = Base . See $1904
24  BYTE CharRamPtrLo              ; LSB of character RAM pointer where this GROUND_OBJECT is drawn. See GROUND_OBJECT_INIT@18E6
    BYTE CharRamPtrHi              ; MSB of character RAM pointer where this GROUND_OBJECT is drawn
    BYTE MysteryPointsType         ; Only used for "Mystery" object type. Represents points value to display on screen when this object has been shot.  0 = 100pts, 1 = 200pts, 2= 300pts. See $2296 and $1976.
    BYTE ???
28  BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
} // sizeof (GROUND_OBJECT) = 32 bytes



; GROUND_OBJECTS is a fixed-size array of type GROUND_OBJECT. Each GROUND_OBJECT requires 32 bytes to model its state, thus the array is 256 bytes in size.
GROUND_OBJECTS                      EQU $4280


;
; The PLAYER struct maintains state for the player jet.
;

struct PLAYER
{
0   BYTE IsActive                   ; Active flag. 1 = Active
    BYTE IsExploding                ; Flag. Set to 1 when jet is exploding
    BYTE StageOfLife                ; Stage of player [jet's] life. See PLAYER_STAGE_OF_LIFE @ $16E6 for more info
    BYTE X                          ; X coordinate
4   BYTE Y                          ; Y coordinate
    BYTE ???
    BYTE ???
    BYTE ???
8   BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
12  BYTE AnimPtrLo                  ; Low byte of pointer to animation table. See ANIMATE @$13E4 for more info about animation tables. 
    BYTE AnimPtrHi                  ; high byte of pointer
    BYTE AnimationCounter           ; When this counts down to zero it's time for next animation frame. 
    BYTE ExplosionCounter           ; This is used to time how long the jet explosion animation should be shown for. See $1814 and $1847
16  BYTE ???
    BYTE ???
    BYTE SpriteCode;                ; Sprite code (animation frame) to display    
    BYTE ???
20  BYTE ???
    BYTE ???
    BYTE Colour;                    ; Main colour of jet sprite
    BYTE ???
24  BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
 28 BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
} // sizeof(PLAYER) = 32 bytes


; PLAYERS is a fixed-size two element array of type PLAYER. Each PLAYER requires 32 bytes to model its state, thus the array is 64 bytes in size.
PLAYERS EQU $4380
    PLAYER_ONE                      EQU $4380         ; alias of PLAYERS[0] 
    PLAYER_TWO                      EQU $43A0         ; alias of PLAYERS[1]


struct PLAYER_BOMB
{
0   BYTE IsActive;                 ; Active flag. 1 = Active
    BYTE IsExploding;              ; Flag. Set to 1 when bomb is exploding
    BYTE StageOfLife;              ; Stage of bomb's life. See $1A30 and $1A4B for more info 
    BYTE X;                        ; X coordinate
4   BYTE Y;                        ; Y coordinate
    BYTE ???
    BYTE ???
    BYTE ???  
8   BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
12  BYTE AnimPtrLo                  ; Low byte of pointer to animation table. See ANIMATE @$13E4 for more info about animation tables.
    BYTE AnimPtrHi                  ; high byte of pointer to animation table
    BYTE AnimationCounter           ; When this counts down to zero it's time for next animation frame. 
    BYTE ExplosionCounter           ; This is used to time how long the bomb explosion animation should be shown for. See $1AB9 and $1AC3 
16  BYTE ???
    BYTE ???
    BYTE SpriteCode;                ; Sprite code (animation frame) to display    
    BYTE PathPtrLo                  ; low byte of pointer to path table (see FOLLOW_PATH @$1578 for more information)
20  BYTE PathPtrHi                  ; high byte of pointer to path table
    BYTE ???
    BYTE Colour;                    ; Main colour of sprite
    BYTE ???
24  BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
 28 BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
} // sizeof(PLAYER_BOMB) = 32 bytes


; PLAYER_BOMBS is a 2 element array of type PLAYER_BOMB. Each PLAYER_BOMB requires 32 bytes to model its state, thus the array is 64 bytes in size. 
PLAYER_BOMBS                        EQU $43C0


;
; This struct holds the state for a flying enemy, specifically one of the following types: a launched rocket, UFO or fireball.
;
; All of the inflight enemies you see on screen at any one time (up to 4) will be of a single type, varying by level. 
; Mixing inflight enemy types is not possible. You can't have a mix of rockets and UFOs, for example (which would be fun, I think.) 
;
; The game knows what type of enemies are inflight by reading the value of LANDSCAPE_FLAGS ($411D) .
; 
; See: 
;     ROCKET_ANIMATION_AND_MOVEMENT ($1C98)
;     UFO_ANIMATION_AND_MOVEMENT ($1D75)
;     FIREBALL_ANIMATION_AND_MOVEMENT ($1EC6)

struct INFLIGHT_ENEMY
{
0   BYTE IsActive;                 ; Active flag. 1 = Active
    BYTE IsExploding;              ; Flag. Set to 1 when this enemy is exploding.
    BYTE StageOfLife;              ; Stage of enemy's life. See $1A30 for more info. 
    BYTE X;                        ; X coordinate
4   BYTE Y;                        ; Y coordinate
    BYTE ???
    BYTE ???
    BYTE ???
8   BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
12  BYTE AnimPtrLo                  ; Low byte of pointer to animation table. See ANIMATE @$13E4 for more info about animation tables.
    BYTE AnimPtrHi                  ; high byte of pointer to animation table
    BYTE AnimationCounter           ; When this counts down to zero it's time for next animation frame.
    BYTE ExplosionCounter           ; This is used to time how long the explosion animation should be shown for. See $1AB9 and $1AC3 
16  BYTE ???
    BYTE ???
    BYTE SpriteCode;                ; Sprite code (animation frame) to display    
    BYTE PathPtrLo                  ; low byte of pointer to path table. See FOLLOW_PATH @$1578 for more info on paths
20  BYTE PathPtrHi                  ; high byte of pointer to path table
    BYTE ???
    BYTE Colour;                    ; Sprite colour
    BYTE ???
24  BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
 28 BYTE ???
    BYTE ???
    BYTE ???
    BYTE ???
} // sizeof(INFLIGHT_ENEMY) = 32 bytes


; INFLIGHT_ENEMIES is a 4 element array of type INFLIGHT_ENEMY. Each INFLIGHT_ENEMY requires 32 bytes to model its state, thus the array is 128 bytes in size.  
INFLIGHT_ENEMIES                    EQU $4400

                                    EQU $4480  


struct PLAYER_BULLET
{
    BYTE IsActive;                  ; Active flag. 1 = Active
    BYTE X;                         ; X coordinate    
    BYTE Y;                         ; Y coordinate
} // sizeof(PLAYER_BULLET) = 3 bytes     

; PLAYER_BULLETS is a 4 element array of type PLAYER_BULLET. The array is 12 bytes in size.
PLAYER_BULLETS                      EQU $4500  

TEMP_COUNTER_4540                   EQU $4540         ; counter only used in attract mode script stages 
ATTRACT_MODE_SCRIPT_STAGE           EQU $4541         ; index into jump table @ $0BB1  

SCORE_TABLE_CHARS_COUNTER           EQU $4542         ; used by DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE to count down characters left to print on a row. See $0DC8
SCORE_TABLE_ROWS_COUNTER            EQU $4543         ; used by ADVANCE_TO_NEXT_ROW_OF_SCORE_TABLE to count rows of points values left to do. See $0DEA
SCORE_TABLE_TEXT_PTR                EQU $4544         ; pointer to character to read from SCORE_TABLE_TEXT @ $0D6C . See $0DB5
SCORE_TABLE_CHAR_PTR                EQU $4546         ; pointer to character RAM where read character will be stored. See $0DBD

; If you want to complete the mission at any time, set IS_MISSION_COMPLETE flag to $FF 
TEMP_COUNTER_4580                   EQU $4580         ; counter only used in stages of the MISSION_COMPLETED_SCRIPT
MISSION_COMPLETE_SCRIPT_STAGE       EQU $4581         ; Used by MISSION_COMPLETED_SCRIPT (see $127E). index into jump table @ $1282. 

TEMP_COUNTER_45C0                   EQU $45C0         ; counter only used in stages of the HIGH_SCORE_SCRIPT   
HIGH_SCORE_SCRIPT_STAGE             EQU $45C1         ; Used by HIGH_SCORE_SCRIPT (see $12F0). index into jump table @ $12F4  

// And now to the code... enjoy.
0000: AF          xor  a
0001: 32 01 68    ld   ($6801),a             ; disable interrupt
0004: C3 E1 02    jp   $02E1                 ; jump to CLEAR_RAM_THEN_JP_0069

0007: FF          rst  $38



; Write A to (HL) and A+1 to (HL+1)
; 
; Expects:
; A = seed value
; HL = memory address to begin writing values 
; DE = value to add to HL after writing done
;
; Returns:
; A is 2 more than it was on entry
; HL = HL + DE + 2
; 
0008: 77          ld   (hl),a
0009: 3C          inc  a
000A: 23          inc  hl
000B: 77          ld   (hl),a
000C: 3C          inc  a
000D: 19          add  hl,de
000E: C9          ret

000F: FF          rst  $38

;
; Fill memory from HL to HL+B with value A.
;
; expects:
; A = value to write
; B = count
; HL = pointer 
;

0010: 77          ld   (hl),a
0011: 23          inc  hl
0012: 10 FC       djnz $0010
0014: C9          ret

0015: FF          rst  $38
0016: FF          rst  $38
0017: FF          rst  $38

;
; Fill memory from HL to HL + B + (C*256) with value A
;

0018: 77          ld   (hl),a
0019: 23          inc  hl
001A: 10 FC       djnz $0018
001C: 0D          dec  c
001D: 20 F9       jr   nz,$0018
001F: C9          ret


;
; Return the byte at HL + A.
; i.e: in BASIC this would be akin to: result = PEEK (HL + A)
;
; expects:
; A = offset
; HL = pointer
;
; returns:
; A = the contents of (HL + A)
;

0020: 85            add  a,l                 ; a+=l
0021: 6F            ld   l,a                 
0022: 3E 00         ld   a,$00               
0024: 8C            adc  a,h                 
0025: 67            ld   h,a                 ; effectively: HL = HL + A. Now hl is set to point to byte to read
0026: 7E            ld   a,(hl)              ; load a with contents of (HL)
0027: C9            ret


;
; Jump to instruction in table. 
;
; Immediately after the RST 28 call, there must be a table of pointers to code.
; A is a zero-based index into the table.
; 
; Expects:
; A = index. Is multiplied by 2 to form an offset into the succeeding table.
; 

0028: 87            add  a,a                 ; multiply A by 2. 
0029: E1            pop  hl                  ; pop return address off stack into HL
002A: 5F            ld   e,a
002B: 16 00         ld   d,$00               ; extend A into DE. Now DE = offset into table
002D: 19            add  hl,de               ; Effectively, HL = HL + offset into table
002E: 5E            ld   e,(hl)              ; load E from table
002F: 23            inc  hl                
0030: 56            ld   d,(hl)              ; load D from table. Now DE = a pointer to code.
0031: EB            ex   de,hl               ; 
0032: E9            jp   (hl)                ; Jump to code specified by table entry.


0033: FF          rst  $38
0034: FF          rst  $38
0035: FF          rst  $38
0036: FF          rst  $38
0037: FF          rst  $38


;
; Try to insert into the circular command queue located @ $40C0. (CIRC_CMD_QUEUE_START)
; if insert is not possible, exit function immediately.
;
; Expects:
; D is a command number (0..??) 
; E is a parameter to pass to the command. 
;
; $40A0 (CIRC_CMD_QUEUE_PTR_LO) contains the low byte of a pointer to a (hopefully) free entry in the queue.  
;
; Value in D           Action it invokes 
; ========================================================
; 0                    Does nothing
; 1                    Does nothing
; 2:                   Invokes DISPLAY_HIGH_SCORES_COMMAND
; 3:                   Invokes UPDATE_PLAYER_SCORE_COMMAND
; 4:                   Invokes ZERO_SCORE_COMMAND
; 5:                   Invokes DISPLAY_SCORE_COMMAND
; 6:                   Invokes PRINT_TEXT 
; 7:                   Invokes HEAD_UP_DISPLAY_COMMAND 
; 
;
; See also: $01C1 (PROCESS_CIRCULAR_COMMAND_QUEUE) 
;
; ALGORITHM:
; 1. Form a pointer to an entry in the circular queue using #$40 as the high byte of the pointer
;    and the contents of $40A0 (CIRC_CMD_QUEUE_PTR_LO) as the low byte. 
; 2. Read a byte from the queue entry the pointer points to 
; 3. IF bit 7 of the byte is unset, then the queue entry is in use, we can't insert. Exit function.  
; 4. ELSE:
;    4a) store register DE at the pointer
;    4b) bump pointer to next queue entry 
; 5. Exit function

QUEUE_COMMAND:
0038: E5          push hl
0039: 26 40       ld   h,$40                 ; set high byte of address
003B: 3A A0 40    ld   a,($40A0)             ; read CIRC_CMD_QUEUE_PTR_LO          
003E: 6F          ld   l,a                   ; set low byte of address. Now HL = pointer to entry in circular queue.
003F: CB 7E       bit  7,(hl)                ; read byte from address and test bit 7
0041: 28 0E       jr   z,$0051               ; if bit 7 not set, this entry is already in use, goto $0051 and exit

0043: 72          ld   (hl),d                ; write DE...
0044: 2C          inc  l
0045: 73          ld   (hl),e
0046: 2C          inc  l                     ; ..to (HL)

; has L wrapped around to 0? If so, then we've hit the end of the circular queue
0047: 7D          ld   a,l                   ; 
0048: FE C0       cp   $C0                   ; compare low byte of address in HL to #$C0. 
004A: 30 02       jr   nc,$004E              ; if A > #$C0 (192 decimal) then we've not hit the end of the circular queue, goto $004E
004C: 3E C0       ld   a,$C0                 ; otherwise, A == 0 and we've passed the end of the queue, reset queue pointer high byte to #$C0 (192 decimal)
004E: 32 A0 40    ld   ($40A0),a             ; update CIRC_CMD_QUEUE_PTR_LO to point to next queue entry
0051: E1          pop  hl
0052: C9          ret


0053: FF          rst  $38
0054: FF          rst  $38
0055: FF          rst  $38
0056: FF          rst  $38
0057: FF          rst  $38
0058: FF          rst  $38
0059: FF          rst  $38
005A: FF          rst  $38
005B: FF          rst  $38
005C: FF          rst  $38
005D: FF          rst  $38
005E: FF          rst  $38
005F: FF          rst  $38
0060: FF          rst  $38
0061: FF          rst  $38
0062: FF          rst  $38
0063: FF          rst  $38
0064: FF          rst  $38
0065: FF          rst  $38


; NMI
0066: C3 C0 09    jp   $09C0                 ; jump to NMI_HANDLER


;
;  Invoked from CLEAR_RAM_THEN_JP_0069
;
;
;
0069: 3E 9B       ld   a,$9B
006B: 32 03 81    ld   ($8103),a             ; does nothing
006E: 3E 88       ld   a,$88
0070: 32 03 82    ld   ($8203),a             ; does nothing
0073: 3E 08       ld   a,$08
0075: 32 42 42    ld   ($4242),a             ; set IRQTRIGGER_CTRL
0078: 32 01 82    ld   ($8201),a             ; bit 3 = interrupt trigger on audio CPU


007B: 31 00 48    ld   sp,$4800

; Protection related code. 
; It appears the protection chip needs specific values in a specific sequence to be written to it,
; in order to return a specific value indicating that the protection check succeeded (see $00C0)
;
; I wonder if the protection chip would reset the system if it doesn't get the values written to it in the correct sequence?
; Or would it lock the system completely? 
007E: 3E 28       ld   a,$28
0080: 07          rlca
0081: C6 32       add  a,$32
0083: 67          ld   h,a
0084: E6 0F       and  $0F
0086: 6F          ld   l,a
0087: C6 0D       add  a,$0D
0089: 77          ld   (hl),a                ; write $0F to protection                

008A: 06 07       ld   b,$07
008C: 1E 09       ld   e,$09
008E: 4F          ld   c,a
008F: 57          ld   d,a
0090: 10 FC       djnz $008E
0092: 70          ld   (hl),b                ; write 0 to protection

; It appears the scramble hardware sets IX to $421E when the system boots up (ie: hits address 0). 
0093: 06 03       ld   b,$03
0095: DD 4E 03    ld   c,(ix+$03)            ; read from $4221  
0098: 10 FB       djnz $0095
009A: 77          ld   (hl),a                ; write $0F to protection  

009B: 59          ld   e,c
009C: 70          ld   (hl),b                ; write 0 to protection
009D: 06 FA       ld   b,$FA
009F: 80          add  a,b
00A0: 77          ld   (hl),a                ; write $09 to protection

00A1: 0E 10       ld   c,$10
00A3: 06 20       ld   b,$20
00A5: 81          add  a,c
00A6: 80          add  a,b
00A7: 5E          ld   e,(hl)                ; reads $F9 from protection...
00A8: 3E F0       ld   a,$F0
00AA: A3          and  e                     ; produces $F0..
00AB: 2F          cpl                        ; produces $0F..
00AC: E6 F0       and  $F0                   ; produces 0. Or should do - if it doesn't, protection kicks in.

00AE: C0          ret  nz                    ; return if protection is triggered. Someone's hacking.

00AF: 26 82       ld   h,$82
00B1: 7C          ld   a,h
00B2: E6 3F       and  $3F
00B4: 6F          ld   l,a                   ; set HL to $8202 (protection)
00B5: 36 0A       ld   (hl),$0A              ; write 10 to protection 
00B7: C6 02       add  a,$02
00B9: 77          ld   (hl),a                ; write 4 to protection
00BA: C6 05       add  a,$05
00BC: 77          ld   (hl),a                ; write 9 to protection
00BD: 7E          ld   a,(hl)                ; reads $B9 from protection check
00BE: E6 F0       and  $F0                   ; produces $B0 
00C0: FE B0       cp   $B0                   ; compare to $B0, which is value if protection check succeeds
00C2: C2 DC 05    jp   nz,$05DC              ; if protection check does not succeed, corrupt memory state by jumping to text strings, not code..

; When we get here, the preliminary protection checks have passed. 
00C5: 21 C0 40    ld   hl,$40C0              ; load HL with CIRC_CMD_QUEUE_START
00C8: 06 40       ld   b,$40                 ; sizeof(CIRC_CMD_QUEUE)
00CA: 3E FF       ld   a,$FF
00CC: D7          rst  $10                   ; fill memory with $FF

00CD: 21 43 42    ld   hl,$4243              ; address of CIRC_SOUND_CMD_QUEUE
00D0: 06 1C       ld   b,$1C                 ; sizeof(CIRC_SOUND_CMD_QUEUE)
00D2: D7          rst  $10                   ; fill memory

00D3: 21 43 43    ld   hl,$4343
00D6: 22 40 42    ld   ($4240),hl            ; write to CIRC_SOUND_CMD_QUEUE_PTR_LO and CIRC_SOUND_CMD_QUEUE_PROC_LO

00D9: 3A 00 70    ld   a,($7000)             ; kick watchdog
00DC: AF          xor  a
00DD: 32 01 68    ld   ($6801),a             ; disable interrupts 
00E0: 32 05 70    ld   ($7005),a             ; does nothing
00E3: 32 06 68    ld   ($6806),a             ; disable screen vertical flip
00E6: 32 07 68    ld   ($6807),a             ; disable screen horizontal flip
00E9: 21 C0 C0    ld   hl,$C0C0
00EC: 22 A0 40    ld   ($40A0),hl            ; reset CIRC_CMD_QUEUE_PTR_LO and CIRC_CMD_QUEUE_PROC_LO
00EF: 3C          inc  a
00F0: 32 04 68    ld   ($6804),a             ; enable stars

00F3: 21 00 48    ld   hl,$4800              ; start of character RAM
00F6: 22 0B 40    ld   ($400B),hl            ; set TEMP_CHAR_RAM_PTR

00F9: 3E 20       ld   a,$20
00FB: 32 08 40    ld   ($4008),a             ; set TEMP_COUNTER_4008
00FE: 3E 10       ld   a,$10
0100: 32 17 40    ld   ($4017),a             ; set BONUS_JET_FOR value to 10 BCD (meaning bonus jet at 10,000 points)

; Read IN2 to determine how many coins needed for credit, and if its a cocktail setup
0103: 3A 02 81    ld   a,($8102)             ; read IN2
0106: 0F          rrca
0107: 47          ld   b,a
0108: E6 03       and  $03
010A: 32 00 40    ld   ($4000),a            ; set COINAGE_VALUE
010D: 78          ld   a,b
010E: 0F          rrca                       
010F: 0F          rrca
0110: E6 01       and  $01                 
0112: 32 0F 40    ld   ($400F),a            ; set/reset IS_COCKTAIL flag

; Read IN1 so we can find out how many lives the player gets when starting a new game
0115: 3A 01 81    ld   a,($8101)             ; read IN1
0118: E6 03       and  $03
011A: FE 03       cp   $03                   ; free play?
011C: 28 07       jr   z,$0125

; If we get here, we are not in FREE PLAY mode
011E: C6 03       add  a,$03
0120: 32 07 40    ld   ($4007),a             ; set DEFAULT_PLAYER_LIVES                       
0123: 18 05       jr   $012A

; set FREE PLAY mode
0125: 3E FF       ld   a,$FF
0127: 32 07 40    ld   ($4007),a             ; set DEFAULT_PLAYER_LIVES to 255                                    

; Turn sound off
012A: CD 93 28    call $2893                 ; call DISABLE_SOUND


; More protection code - skip to $0165 if you're not interested in this stuff.
012D: AF          xor  a

012E: 3D          dec  a
012F: 20 FD       jr   nz,$012E

0131: CD A2 28    call $28A2                 ; call ENABLE_SOUND   
0134: 3A D7 07    ld   a,($07D7)             ; read $23 ("inc hl") from code in ROM
0137: C6 95       add  a,$95
0139: 6F          ld   l,a
013A: E6 0F       and  $0F
013C: 0F          rrca
013D: 0F          rrca
013E: 0F          rrca
013F: 47          ld   b,a                   ; set B to 1
0140: 0F          rrca
0141: 0F          rrca
0142: 67          ld   h,a                   ; set HL to $40B8 
0143: 70          ld   (hl),b                ; write calculated value 1 to $40B8

; Has someone been naughty and changed the KONAMI text to something else??
0144: 21 9E 05    ld   hl,$059E              ; point HL to the "K" in text string KONAMI
0147: 7E          ld   a,(hl)                ; get the ordinal for "K" into A
0148: C6 04       add  a,$04                 ; advance 4 letters in the alphabet, to "O"
014A: 23          inc  hl                    ; bump HL to point to "O" in string table
014B: BE          cp   (hl)                  ; compare A ("O") to what should be ("O") 
014C: 20 E0       jr   nz,$012E              ; if they don't match, someone's changed vendor text, put game into infinite loop 
                        
014E: 3E 10       ld   a,$10
0150: C6 30       add  a,$30
0152: 57          ld   d,a                   ; Load D with $40
0153: C6 78       add  a,$78
0155: 5F          ld   e,a                   ; load E with $B8. Now DE points to PROTECTION_1
0156: 1A          ld   a,(de)                ; read value from PROTECTION_1 (value should be 1 - see $013F)
0157: C6 81       add  a,$81
0159: 67          ld   h,a                   ; set H to $82
015A: E6 0F       and  $0F
015C: 6F          ld   l,a                   ; set HL to $8202 - protection
015D: EB          ex   de,hl
015E: 26 40       ld   h,$40
0160: 2E B9       ld   l,$B9                 ; load HL with address of PROTECTION_PORT_PTR_1
0162: 73          ld   (hl),e  
0163: 2C          inc  l
0164: 72          ld   (hl),d                ; write $8202 to PROTECTION_PORT_PTR_1
; End of protection code block              

; Clear OBJRAM
0165: 21 00 50    ld   hl,$5000              ; load HL with OBJRAM address
0168: 01 00 01    ld   bc,$0100              ; fill all of OBJRAM 
016B: 16 00       ld   d,$00
016D: 72          ld   (hl),d
016E: 23          inc  hl
016F: 0B          dec  bc
0170: 78          ld   a,b
0171: B1          or   c                     ; quick test to check if BC == 0
0172: 20 F9       jr   nz,$016D              ; if BC!=0, goto $016D

; Fill screen with 8x8 white rectangles
0174: 16 3F       ld   d,$3F                 ; ordinal of rectangle character
0176: 21 00 48    ld   hl,$4800              ; load HL with address of Character RAM
0179: 01 00 08    ld   bc,$0800              ; number of bytes to write to fill screen
017C: 72          ld   (hl),d
017D: 3A 00 70    ld   a,($7000)             ; kick watchdog
0180: 23          inc  hl
0181: 0B          dec  bc
0182: 78          ld   a,b
0183: B1          or   c                     ; quick test to check if BC == 0
0184: 20 F6       jr   nz,$017C              ; if BC!=0, goto $0174
                                                                   
; Check for 1PT_START1 being depressed. If you hold START down when the game's booting up,
; you'll put the system into an infinite loop.
0186: CD B2 01    call $01B2                 ; call CHECK_FOR_1PT_START1_HELD_DOWN
0189: 30 22       jr   nc,$01AD              ; if held down, goto INFINITE_LOOP
018B: CD B2 01    call $01B2                 ; call CHECK_FOR_1PT_START1_HELD_DOWN
018E: 30 1D       jr   nc,$01AD              ; if held down, goto INFINITE_LOOP

0190: 3E 01       ld   a,$01
0192: 32 01 68    ld   ($6801),a             ; enable interrupts

; Reset all scores in hi score table to 10000.
0195: 21 00 42    ld   hl,$4200              ; load HL with address of HI_SCORE_TABLE
0198: 06 0A       ld   b,$0A                 ; 10 entries in the table
019A: 36 00       ld   (hl),$00
019C: 2C          inc  l
019D: 36 00       ld   (hl),$00
019F: 2C          inc  l
01A0: 36 01       ld   (hl),$01              
01A2: 2C          inc  l
01A3: 10 F5       djnz $019A

; reset high score to 10000 as well.
01A5: 21 AA 40    ld   hl,$40AA              ; load HL with address of last byte of HI_SCORE 
01A8: 36 01       ld   (hl),$01              ; set high score to be 10000.
01AA: C3 C1 01    jp   $01C1                 ; jump to PROCESS_CIRCULAR_COMMAND_QUEUE 

INFINITE_LOOP:
01AD: 3A 00 70    ld   a,($7000)             ; kick watchdog 
01B0: 18 FB       jr   $01AD                  


; 
; Check if 1PT_START button is held down for a specified amount of time.
;
; Expects:
; BC = counter. The higher the number, the longer 1PT_START should be held down for.
;
; Returns:
; Carry flag set if 1PT_START was held down for BC cycles
;

CHECK_FOR_1PT_START1_HELD_DOWN:
01B2: 0B          dec  bc
01B3: 3A 00 70    ld   a,($7000)             ; kick watchdog
01B6: 3A 01 81    ld   a,($8101)             ; read IN1
01B9: 07          rlca                       ; move IPT_START1 bit into carry
01BA: D0          ret  nc                    ; return if 1PT_START1 is not pressed
01BB: 78          ld   a,b
01BC: B1          or   c                     ; Quick check to determine if BC==0
01BD: 20 F3       jr   nz,$01B2              ; repeat until BC==0
01BF: 37          scf                        ; set carry flag to signal that 1PT_START was held down as long as required
01C0: C9          ret

;
; Process the circular command queue starting @ $40C0 (CIRC_CMD_QUEUE_START)
;
; Notes:
; The value in $40A1 (I have named it CIRC_CMD_QUEUE_PROC_LO) is the low byte of a pointer to the first entry in 
; the queue to be processed. The MSB of the pointer is always #$40.
; 
; In a circular queue, the first entry to be processed is not necessarily the head of the queue. 
; The first entry to be processed could be anywhere in the queue. 
;

PROCESS_CIRCULAR_COMMAND_QUEUE:
01C1: 26 40       ld   h,$40                 ; high byte of pointer to queue entry be processed
01C3: 3A A1 40    ld   a,($40A1)             ; read CIRC_CMD_QUEUE_PROC_LO
01C6: C3 1A 04    jp   $041A                 ; $041A reads command number, multiplies it by 2, then jumps back to 01C9

01C9: 30 05       jr   nc,$01D0              ; if no carry, then we have a valid command number, goto $01D0
01CB: CD 04 02    call $0204                 
01CE: 18 F1       jr   $01C1                 ; process next entry in circular queue

01D0: E6 0F       and  $0F                   ; mask in lower nibble
01D2: 4F          ld   c,a
01D3: 06 00       ld   b,$00                 ; extend A into BC. BC is now the offset to add to $01F4 (see code @ $01E7)

; indicate that we've read this command, and mark it as free. 
; Update CIRC_CMD_QUEUE_PROC_LO to point to next command/parameter pair to process.
01D5: 36 FF       ld   (hl),$FF              ; write #$FF (255 decimal) to first byte of byte pair, to mark it as "free"
01D7: 23          inc  hl
01D8: 5E          ld   e,(hl)                ; read parameter value from queue entry into E. 
01D9: 36 FF       ld   (hl),$FF              ; write #$FF (255 decimal) to second byte of byte pair, to mark it as "free"
01DB: 2C          inc  l
01DC: 7D          ld   a,l
01DD: FE C0       cp   $C0                   ; is HL == $4100? If so, comparing L (which will be 0) to #$C0 (192 decimal) will set the carry flag. 
01DF: 30 02       jr   nc,$01E3              ; if carry is not set, then we have not reached the end of the queue ($4100), goto $01E3
01E1: 3E C0       ld   a,$C0                 ; otherwise, we have reached end of queue. 
01E3: 32 A1 40    ld   ($40A1),a             ; Set CIRC_CMD_QUEUE_PROC_LO to $C0 ($40C0 = start of circular queue)

; BC = offset into jump table @ $01F4
01E6: 7B          ld   a,e                   ; Now A = parameter to command
01E7: 21 F4 01    ld   hl,$01F4              ; pointer to COMMAND_JUMP_TABLE
01EA: 09          add  hl,bc                 ; now HL = pointer to entry in jump table
01EB: 5E          ld   e,(hl)
01EC: 23          inc  hl
01ED: 56          ld   d,(hl)                ; DE = pointer read from jump table
01EE: 21 C1 01    ld   hl,$01C1              ; return address to go to (entry point of PROCESS_CIRCULAR_COMMAND_QUEUE)
01F1: E5          push hl                    ; push it onto stack, so when we hit a RET it'll return to $01C1
01F2: EB          ex   de,hl                 ; Swap HL and DE round so that HL is pointer read from jump table

; HL = pointer to function, A = parameter to pass to function
01F3: E9          jp   (hl)                  ; jump to code pointed to by (HL)


COMMAND_JUMP_TABLE:
01F4: 
    6A 02         ; $026A (Just a RET instruction) 
    6B 02         ; $026B (Another RET) 
    6C 02         ; $026C (DISPLAY_HIGH_SCORES_COMMAND) 
    F1 02         ; $02F1 (UPDATE_PLAYER_SCORE_COMMAND) 
    CC 03         ; $03CC (ZERO_SCORE_COMMAND)
    E8 03         ; $03E8 (DISPLAY_SCORE_COMMAND) 
    35 04         ; $0435 (PRINT_TEXT)
    0B 07         ; $070B (HEAD_UP_DISPLAY_COMMAND) 


; Called from PROCESS_CIRCULAR_COMMAND_QUEUE
0204: 3A 5F 42    ld   a,($425F)             ; load A with value of TIMING_VARIABLE
0207: 47          ld   b,a
0208: E6 0F       and  $0F
020A: CA 23 02    jp   z,$0223               ; if A modulo 16 = 0, goto BLINK_1UP_OR_2UP_TEXT  

; If DRAW_LANDSCAPE_FLAG is set, we want to draw the landscape and the ground objects
020D: 21 19 40    ld   hl,$4019              ; load HL with address of DRAW_LANDSCAPE_FLAG
0210: CB 46       bit  0,(hl)                ; test flag            
0212: C8          ret  z                     ; return if flag is not set

0213: E6 03       and  $03
0215: CA 80 08    jp   z,$0880               ; goto DRAW_REMAINING_PLAYER_FUEL
0218: 3D          dec  a
0219: CA 4B 08    jp   z,$084B               ; goto DRAW_ALL_CHARACTER_BASED_GROUND_OBJECTS
021C: 3D          dec  a
021D: CA 93 07    jp   z,$0793               ; goto DRAW_LANDSCAPE
0220: C3 4B 08    jp   $084B                 ; goto DRAW_ALL_CHARACTER_BASED_GROUND_OBJECTS


;
; This code makes the 1UP or 2UP text blink on and off during the game.
;
; Expects: 
; B = any number (sourced from TIMING_VARIABLE @ $425F)
;

BLINK_1UP_OR_2UP_TEXT:
0223: 11 E0 FF    ld   de,$FFE0              ; load DE with -32 decimal
0226: 21 E0 48    ld   hl,$48E0              ; character RAM address to plot "2UP" at
0229: 3A 0E 40    ld   a,($400E)             ; read IS_TWO_PLAYER_GAME flag
022C: A7          and  a                     ; test if flag is set
022D: 28 22       jr   z,$0251               ; if not a 2 player game, goto DRAW_1UP_ERASE_2UP

; if its a 2 player game we draw "2UP" first, then "1UP".
022F: 36 02       ld   (hl),$02              ; plot "2" to character RAM
0231: CD 5B 02    call $025B                 ; plot "UP" to character RAM
0234: 21 40 4B    ld   hl,$4B40              
0237: CD 59 02    call $0259                 ; call DRAW_1UP

; the next thing we do is find out who's playing, so we know what score to blink. 
023A: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER
023D: A7          and  a                     ; test if A is zero 
023E: 21 40 4B    ld   hl,$4B40              ; address where "1UP" is plotted in character RAM
0241: 28 03       jr   z,$0246               ; if A is 0, its player 1, goto $0246

; player 2 in charge
0243: 21 E0 48    ld   hl,$48E0              ; load HL with character RAM address of "2UP"

; we can blink if bit 4 of the value read from TIMING_VARIABLE is set and the game is in play.
0246: CB 60       bit  4,b                   ; test bit 4 of the value 
0248: C8          ret  z                     ; if not set, do nothing

0249: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY
024C: 0F          rrca                       ; move flag into carry
024D: D0          ret  nc                    ; return if game is not in play

024E: C3 62 02    jp   $0262                 ; erase text

 
DRAW_1UP_ERASE_2UP:
0251: 21 E0 48    ld   hl,$48E0              ; load HL with character RAM address of "2UP"
0254: CD 62 02    call $0262                 ; call PLOT_THREE_EMPTY_SPACES to erase "2UP" from screen
0257: 18 DB       jr   $0234                 ; draw "1UP" on screen

; Plot 1UP to character RAM
;
; Expects:
; HL = pointer to character RAM to start plotting from
; DE = offset to add after erasing each character
DRAW_1UP:
0259: 36 01       ld   (hl),$01              ; "1" 
025B: 19          add  hl,de
025C: 36 25       ld   (hl),$25              ; "U"
025E: 19          add  hl,de
025F: 36 20       ld   (hl),$20              ; "P"
0261: C9          ret


; Expects:
; HL = pointer to character RAM to start plotting from
; DE = offset to add after erasing each character

PLOT_THREE_EMPTY_SPACES:
0262: 3E 10       ld   a,$10                 ; ordinal for empty space
0264: 77          ld   (hl),a                ; write to character RAM
0265: 19          add  hl,de
0266: 77          ld   (hl),a                ; write to character RAM
0267: 19          add  hl,de
0268: 77          ld   (hl),a                ; write to character RAM
0269: C9          ret

026A: C9          ret

026B: C9          ret


;
; Display high score table.
;
;
;

DISPLAY_HIGH_SCORES_COMMAND:
; Protection: if you're not interested in this, skip to $0283.
; First a sneaky ROM security check. If the ROM checksum doesn't match, memory state will be corrupted and the game will reboot.
026C: 11 B4 00    ld   de,$00B4
026F: 21 CC 00    ld   hl,$00CC
0272: AF          xor  a                     ; clear carry flag
0273: ED 52       sbc  hl,de                 ; HL = $18 
0275: 45          ld   b,l                   ; B = $18
0276: 21 B4 00    ld   hl,$00B4              ; start of code in ROM to checksum
0279: 86          add  a,(hl)                ; calculate ROM checksum 
027A: 23          inc  hl                    ; 
027B: 10 FC       djnz $0279                 ; repeat until B==0

; When we get here, if the ROM hasn't been tampered with, A will be $79
027D: 11 79 00    ld   de,$0079
0280: BB          cp   e                     ; compare A to $79 
0281: 20 05       jr   nz,$0288              ; if ROM has been tampered with, goto $0288 - corrupt memory

; Now display the - SCORE RANKING - and 1ST, 2ND, 3RD.. labels (but not the scores) for the high score table
0283: 3E 1A       ld   a,$1A                 ; ID of -SCORE RANKING- text string (see docs @$0435)
0285: 06 0B       ld   b,$0B                 ; there's 11 labels to display, 
0287: F5          push af

; Protection: if we come here from the jump @$0281, memory will be corrupted because the jump has skipped over the "push af" 
; and the "ld b,$0B" instructions above, meaning the loop will run too many times and the pop af @ $028D will pull things from the 
; stack it shouldn't. 
0288: C5          push bc
0289: CD 35 04    call $0435                 ; call PRINT_TEXT to print heading or high score
028C: C1          pop  bc
028D: F1          pop  af
028E: 3C          inc  a                     ; bump A to ID of next text string to print
028F: 10 F6       djnz $0287                 ; repeat until all labels are printed

; OK, when we get here we've displayed the heading & text labels. Now we need to print the scores as well.
0291: 21 87 49    ld   hl,$4987              ; load HL with address in character RAM to poke scores to
0294: 11 20 00    ld   de,$0020              ; number of characters per ROW
0297: 06 0A       ld   b,$0A                 ; 10 high scores to print

0299: DD 21 00 42 ld   ix,$4200              ; load IX with address of HI_SCORE_TABLE. IX points to last 2 digits (tens) of high score.

; POKE last 2 digits of this high score to character RAM
029D: DD 7E 00    ld   a,(ix+$00)            ; get 2 BCD digits of score into A
02A0: 4F          ld   c,a                   ; save BCD digits in C register 
02A1: E6 0F       and  $0F                   ; mask in lower nibble. Now A holds *sixth* (last) digit of high score. 
02A3: 77          ld   (hl),a                ; write digit to character RAM
02A4: 19          add  hl,de                 ; bump HL to character immediately below one just plotted

02A5: 79          ld   a,c                   ; restore BCD digits from C register
02A6: 0F          rrca                       ; move high nibble ..
02A7: 0F          rrca
02A8: 0F          rrca
02A9: 0F          rrca                       ; .. to lower nibble.
02AA: E6 0F       and  $0F                   ; mask in lower nibble. Now A holds *fifth* digit of high score.
02AC: 77          ld   (hl),a                ; write digit to character RAM
02AD: 19          add  hl,de                 ; bump HL to character immediately below one just plotted

; POKE 3rd and 4th digits of high score to character RAM
02AE: DD 23       inc  ix                    ; bump IX to point to 3rd & 4th digits of current high score
02B0: DD 7E 00    ld   a,(ix+$00)            ; get 3rd & 4th BCD digits of score into A
02B3: 4F          ld   c,a                   ; save BCD digits in C register 
02B4: E6 0F       and  $0F                   ; mask in lower nibble. Now A holds *fourth* digit of high score.
02B6: 77          ld   (hl),a                ; write digit to character RAM
02B7: 19          add  hl,de                 ; bump HL to character immediately below one just plotted

02B8: 79          ld   a,c                   ; restore BCD digits from C register
02B9: 0F          rrca                       ; move high nibble ..
02BA: 0F          rrca
02BB: 0F          rrca
02BC: 0F          rrca                       ; .. to lower nibble.
02BD: E6 0F       and  $0F                   ; mask in lower nibble. Now A holds *third* digit of high score.
02BF: 77          ld   (hl),a                ; write digit to character RAM
02C0: 19          add  hl,de                 ; bump HL to character immediately below one just plotted

; POKE 1st and 2nd digits of high score to character RAM
; I wonder why they didn't make this code a subroutine? It's pretty much a clone of the code above.
02C1: DD 23       inc  ix                    ; bump IX to point to 1st & 2nd digits of current high score
02C3: DD 7E 00    ld   a,(ix+$00)            ; get 1st & 2nd BCD digits of score into A
02C6: 4F          ld   c,a                   ; save BCD digits in C register 
02C7: E6 0F       and  $0F                   ; mask in lower nibble. Now A holds *second* digit of high score.
02C9: 77          ld   (hl),a                ; write digit to character RAM
02CA: 19          add  hl,de                 ; bump HL to character immediately below one just plotted

02CB: 79          ld   a,c                   ; restore BCD digits from C register 
02CC: 0F          rrca                       ; move high nibble ..
02CD: 0F          rrca
02CE: 0F          rrca
02CF: 0F          rrca                       ; .. to lower nibble.
02D0: E6 0F       and  $0F                   ; mask in lower nibble. Now A holds *first* digit of high score.
02D2: 28 01       jr   z,$02D5               ; if first digit of high score is zero, don't bother drawing a zero. Skip to $02D5
02D4: 77          ld   (hl),a                ; write digit to character RAM

; Adjust HL to point to character two columns down, for next high score. Remember the monitor is rotated 90 degrees.
02D5: 11 62 FF    ld   de,$FF62              ; load DE with -158
02D8: 19          add  hl,de                 ; bump HL
02D9: 11 20 00    ld   de,$0020
02DC: DD 23       inc  ix
02DE: 10 BD       djnz $029D                 ; repeat until all entries of high score have been drawn
02E0: C9          ret



;
; Clears RAM from $4000 - $47FF then jumps to $0069
;
;

CLEAR_RAM_THEN_JP_0069:
02E1: 21 00 40    ld   hl,$4000
02E4: 11 01 40    ld   de,$4001
02E7: 01 00 08    ld   bc,$0800
02EA: 36 00       ld   (hl),$00
02EC: ED B0       ldir
02EE: C3 69 00    jp   $0069


; Adds points to a player's score.
;
; Expects:
; A = identifies points to be added to current player score 
; 
; Value in A (decimal)      Action
; ====================      =================
; 0                         Add MYSTERY_SCORE
; 1                         50 points 
; 2                         100 points
; 3                         150 points
; 4                         80 points
; 5                         100 points
; 6                         200 points
; 7                         300 points
; 8                         100 points
; 9                         200 points
; 10                        80 points
; 11                        200 points
; 12                        10 points
; 13                        800 points

UPDATE_PLAYER_SCORE_COMMAND:
02F1: A7          and  a                     ; test if A is zero
02F2: 28 48       jr   z,$033C               ; yes, goto ADD_MYSTERY_SCORE_TO_PLAYER_SCORE

; First update current player's score..
02F4: 4F          ld   c,a                  
02F5: CD 47 03    call $0347                 ; call LEA_DE_OF_CURRENT_PLAYER_SCORE
02F8: 87          add  a,a                   ; Multiply A..
02F9: 81          add  a,c                   ; .. by 3.
02FA: 4F          ld   c,a                   
02FB: 06 00       ld   b,$00                 ; Extend A into BC. Now BC is an offset into POINTS_TABLE 
02FD: 21 9B 03    ld   hl,$039B              ; pointer to POINTS_TABLE
0300: 09          add  hl,bc                 ; now HL points to an entry in the score table. 
0301: A7          and  a                     ; clear carry flag
0302: 06 03       ld   b,$03                 ; Players score is 3 bytes in size
0304: 1A          ld   a,(de)                ; read byte from players score
0305: 8E          adc  a,(hl)                ; add byte from the score table
0306: 27          daa                        ; ensure that the result is valid BCD
0307: 12          ld   (de),a                ; update player score
0308: 13          inc  de                    ; bump to next BCD digits in players score
0309: 23          inc  hl                    ; bump to next BCD digits in points table 
030A: 10 F8       djnz $0304                 ; repeat until all digits in player score have been updated.
030C: D5          push de                    ; DE points to last address of score + 1

; Now compare current player's score to high score, and update high score if necessary
030D: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER                      
0310: 0F          rrca                       ; 
0311: 30 02       jr   nc,$0315              ; if carry flag is not set, its player one in charge
0313: 3E 01       ld   a,$01                 ; Parameter: 1 = Display player two's score
0315: CD E8 03    call $03E8                 ; call DISPLAY_SCORE_COMMAND
0318: D1          pop  de
0319: 1B          dec  de                    
031A: 21 AA 40    ld   hl,$40AA              ; point to last byte (first 2 digits) of HI_SCORE
031D: 06 03       ld   b,$03                 ; Players score is 3 bytes in size
031F: 1A          ld   a,(de)                ; read byte from player score
0320: BE          cp   (hl)                  ; compare to byte from high score
0321: D8          ret  c                     ; if byte read is lower than the byte from high score, its not a new high score, so return
0322: 20 05       jr   nz,$0329              ; if byte is not the same, then we have a new high score, goto UPDATE_HIGH_SCORE
0324: 1B          dec  de                    ; otherwise, bump de 
0325: 2B          dec  hl                    ; and bump hl
0326: 10 F7       djnz $031F                 ; repeat until b==0
0328: C9          ret

; Called when the current player's score exceeds the high score.
UPDATE_HIGH_SCORE:
0329: CD 47 03    call $0347                 ; Call LEA_DE_OF_CURRENT_PLAYER_SCORE. Now DE = pointer to current player score
032C: 21 A8 40    ld   hl,$40A8              ; address of HI_SCORE
032F: 06 03       ld   b,$03                 ; high score occupies 3 bytes
0331: 1A          ld   a,(de)                ; read byte from player score
0332: 77          ld   (hl),a                ; update byte in high score              
0333: 13          inc  de                    ; bump DE to point to next byte in player score
0334: 23          inc  hl                    ; bump HL to point to next byte in high score
0335: 10 FA       djnz $0331
0337: 3E 02       ld   a,$02
0339: C3 E8 03    jp   $03E8                 ; call DISPLAY_SCORE_COMMAND


; TODO: This looks like it's adding an arbitrary score to current.
; I suspect this will be the MYSTERY score.
ADD_MYSTERY_SCORE_TO_PLAYER_SCORE:
033C: CD 47 03    call $0347                 ; call LEA_DE_OF_CURRENT_PLAYER_SCORE
033F: 21 AB 40    ld   hl,$40AB              ; load HL with address of MYSTERY_SCORE
0342: A7          and  a                     ; clear carry flag so that BCD additions aren't affected 
0343: 06 03       ld   b,$03                 ; player score is 3 bytes in size 
0345: 18 BD       jr   $0304                 ; update current player's score with mystery value


;
; Load DE with the [effective] address of the current player's score.
; 

LEA_DE_OF_CURRENT_PLAYER_SCORE:
0347: F5          push af
0348: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER 
034B: 11 A2 40    ld   de,$40A2              ; address of PLAYER_ONE_SCORE
034E: 0F          rrca                       ; move current player into carry. If its player 2's turn, carry will be set
034F: 30 03       jr   nc,$0354              ; if its not player 2's turn, exit
0351: 11 A5 40    ld   de,$40A5              ; return address of PLAYER_TWO_SCORE
0354: F1          pop  af
0355: C9          ret



; 
; Shows head up display, and PLAYER ONE message in middle of screen, indicating its player one's turn.
;

DISPLAY_HUD_FOR_PLAYER_ONE:
0356: AF          xor  a
0357: 32 5F 42    ld   ($425F),a             ; reset TIMING_VARIABLE 
035A: 32 06 68    ld   ($6806),a             ; disable screen vertical flip
035D: 32 07 68    ld   ($6807),a             ; disable screen horizontal flip
0360: 32 0D 40    ld   ($400D),a
0363: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
0366: 34          inc  (hl)                  ; advance to next stage in script (REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE @ $107E)
0367: 2D          dec  l                     ; bump HL to address of TEMP_COUNTER_4009
0368: 36 96       ld   (hl),$96              ; set counter value
036A: 3A 0E 40    ld   a,($400E)             ; read IS_TWO_PLAYER_GAME flag
036D: 0F          rrca                       ; move flag into carry
036E: 38 25       jr   c,$0395               ; if carry is set, its a two player game, need to show player 2's score as well, so goto DISPLAY_PLAYER_TWO_SCORE
0370: 11 00 05    ld   de,$0500              ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param: 0 = Display Player 1 score           
0373: FF          rst  $38                   ; call QUEUE_COMMAND
0374: 1E 02       ld   e,$02                 ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param: 2 = Display high score    
0376: FF          rst  $38                   ; call QUEUE_COMMAND
0377: 14          inc  d                     ; Command ID: 6 = PRINT_TEXT, Param:2 = PLAYER ONE
0378: FF          rst  $38                   ; call QUEUE_COMMAND
0379: 1E 04       ld   e,$04                 ; Command ID: 6 = PRINT_TEXT, Param:4 = HIGH SCORE
037B: FF          rst  $38                   ; call QUEUE_COMMAND
037C: 11 03 07    ld   de,$0703              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:3 = DISPLAY_CURRENT_PLAYER_LIVES
037F: FF          rst  $38                   ; call QUEUE_COMMAND
0380: 1E 00       ld   e,$00                 ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:0 = DISPLAY_MISSIONS_COMPLETED_FLAGS 
0382: FF          rst  $38                   ; call QUEUE_COMMAND

0383: 21 40 41    ld   hl,$4140              ; copy all of PLAYER_ONE_STATE to CURRENT_PLAYER_STATE
0386: 11 00 41    ld   de,$4100             
0389: 01 40 00    ld   bc,$0040              
038C: ED B0       ldir
038E: 2A 1D 41    ld   hl,($411D)
0391: 22 18 41    ld   ($4118),hl
0394: C9          ret

DISPLAY_PLAYER_TWO_SCORE:
0395: 11 01 05    ld   de,$0501              ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param: 1 = Display Player 2 score  
0398: FF          rst  $38                   ; call QUEUE_COMMAND
0399: 18 D5       jr   $0370                 ; now go print player 1's score too



;
; Used by UPDATE_PLAYER_SCORE_COMMAND.  
;

POINTS_TABLE:
039B: 
00 00 00          ; 0 points (unused)
50 00 00          ; 50 points  
00 01 00          ; 100 points
50 01 00          ; 150 points
80 00 00          ; 80 points
00 01 00          ; 100 points     
00 02 00          ; 200 points
00 03 00          ; 300 points
00 01 00          ; 100 points 
00 02 00          ; 200 points
80 00 00          ; 80 points
00 02 00          ; 200 points
10 00 00          ; 10 points
00 08 00          ; 800 points



03C5: 3A 02 40    ld   a,($4002)             ; read NUM_CREDITS
03C8: A7          and  a                     ; test if zero
03C9: C3 09 26    jp   $2609                 ; invoke ADVANCE_TO_NEXT_SCRIPT_IF_ZERO_FLAG_UNSET


;
; Zero a given score.  Will update score on screen also.
;
; Value in A      Action taken
; ===========================================
; 0               Reset player 1's score to 0                    
; 1               Reset player 2's score to 0                    
; Any other       Reset high score to 0                    
;

ZERO_SCORE_COMMAND:
03CC: F5          push af
03CD: 21 A2 40    ld   hl,$40A2              ; load HL with address of PLAYER_ONE_SCORE
03D0: A7          and  a
03D1: 28 09       jr   z,$03DC
03D3: 21 A5 40    ld   hl,$40A5              ; load HL with address of PLAYER_TWO_SCORE
03D6: 3D          dec  a
03D7: 28 03       jr   z,$03DC
03D9: 21 A8 40    ld   hl,$40A8              ; load HL with address of HI_SCORE
03DC: 36 00       ld   (hl),$00              ; zero...
03DE: 23          inc  hl
03DF: 36 00       ld   (hl),$00
03E1: 23          inc  hl
03E2: 36 00       ld   (hl),$00              ; ..high score 
03E4: F1          pop  af
03E5: C3 E8 03    jp   $03E8                 ; jump to DISPLAY_SCORE_COMMAND


; Display a score
; 
; Value in A      Action taken                     
; ==========================================
; 0               Display player one's score       
; 1               Display player two's score
; 2               Display high score 

DISPLAY_SCORE_COMMAND:
03E8: 21 A4 40    ld   hl,$40A4              ; load HL with address of last byte of PLAYER_ONE_SCORE
03EB: DD 21 81 4B ld   ix,$4B81              ; pointer to character RAM location for player one's score
03EF: A7          and  a                     ; test if A is zero 
03F0: 28 11       jr   z,$0403               ; if zero, display player one's score

03F2: 21 A7 40    ld   hl,$40A7              ; load HL with address of last byte of PLAYER_TWO_SCORE
03F5: DD 21 21 49 ld   ix,$4921              ; pointer to character RAM location for player two's score
03F9: 3D          dec  a
03FA: 28 07       jr   z,$0403               ; if A is now 0 then it was 1 on entry, meaning display player two score, goto $0403

; Display high score
03FC: 21 AA 40    ld   hl,$40AA              ; load HL with address of last byte of HI_SCORE              
03FF: DD 21 41 4A ld   ix,$4A41              ; pointer to character RAM location for high score

; OK, now render score pointed to by HL
0403: 11 E0 FF    ld   de,$FFE0              ; load DE with $FFE0 (-32 decimal) 
0406: 06 03       ld   b,$03                 ; a score is 3 bytes in size..
0408: 0E 04       ld   c,$04                 ; max number of leading zeros that can be skipped. For example,
                                             ; when you start the game you have a score of zero. It renders as "00" instead of "000000". 
                                             ; So this specifies "skip the first 4 zeros in the score, but display the rest"
040A: 7E          ld   a,(hl)                ; read BCD digits from score byte
040B: 0F          rrca                       ; move high nibble (first digit of BCD number)...
040C: 0F          rrca
040D: 0F          rrca
040E: 0F          rrca                       ; ...into lower nibble (second digit). 
040F: CD 20 04    call $0420                 ; call PLOT_LOWER_NIB_AS_DIGIT to plot the first digit 
0412: 7E          ld   a,(hl)
0413: CD 20 04    call $0420                 ; call PLOT_LOWER_NIB_AS_DIGIT to plot the second digit
0416: 2B          dec  hl                    ; bump to *previous* BCD byte
0417: 10 F1       djnz $040A                 ; do until all BCD digits in score have been drawn
0419: C9          ret

041A: 6F          ld   l,a                   ; now HL = pointer to a queue entry 
041B: 7E          ld   a,(hl)                ; read command number from queue entry into A. 
041C: 87          add  a,a                   ; multiply A by 2 to form an offset into jump table
041D: C3 C9 01    jp   $01C9                 ; go to PROCESS_CIRCULAR_COMMAND_QUEUE


; Pokes a digit of the score to character RAM.
;
; Expects:
; Lower nibble of A: BCD digit to be plotted as a character on screen 
; C = max number of leading zero digits in the score that can be skipped. 
;     If C is 0, leading zero digits will always be drawn
; IX = pointer to character RAM where digit will be plotted.

PLOT_LOWER_NIB_AS_DIGIT:
0420: E6 0F       and  $0F                   ; mask in lower nibble
0422: 28 08       jr   z,$042C               ; if the lower nibble is zero, goto $042C

; OK, we have a nonzero digit. 
0424: 0E 00       ld   c,$00                 ; tell the plot routine to draw all digits, even if they are zero, from now on
0426: DD 77 00    ld   (ix+$00),a            ; go plot the character
0429: DD 19       add  ix,de                 ; now IX points to character directly above one just plotted
042B: C9          ret                        

; we have a zero digit. Do we print it, or print a space instead?
042C: 79          ld   a,c                   ; how many zero digits can we skip over? 
042D: A7          and  a                     ; test if A is zero
042E: 28 F6       jr   z,$0426               ; if we can't skip over any more leading zero digits, then goto $0426 to draw "0". 

; Otherwise, we are skipping a leading "0" digit and will print an empty space in its stead..
0430: 3E 10       ld   a,$10                 ; ordinal for empty space character 
0432: 0D          dec  c                     ; decrement count of leading zeros we are allowed to ignore
0433: 18 F1       jr   $0426                 ; plot empty space to screen


;
; A = index of string to print
;
; Bit 6 set: scroll this text onto screen (unused functionality)
; Bit 7 set: erase this text
;
; Value in A (ANDed with $7F)       Text printed
; =============================================================
; 0                                 GAME OVER                
; 1                                 PUSH START BUTTON 
; 2                                 PLAYER ONE 
; 3                                 PLAYER TWO 
; 4                                 HIGH SCORE
; 5                                 CREDIT 
; 6                                 HOW FAR CAN YOU INVADE 
; 7                                 FUEL
; 8                                 CONGRATULATIONS 
; 9                                 YOU COMPLETED YOUR DUTIES
; A                                 GOOD LUCK NEXT TIME
; B                                 PLAY
; C                                 - SCRAMBLE -
; D                                 - SCORE TABLE -  
; E                                 (C) KONAMI  1981 
; F                                 (C) KONAMI  1981 
; 10                                (C) KONAMI  1981 
; 11                                (C) KONAMI  1981 
; 12                                OUR SCRAMBLE SYSTEM 
; 13                                2 COINS 1 PLAY
; 14                                3 COINS 1 PLAY
; 15                                1 COIN  2 PLAY 
; 16                                BONUS JET   FOR
; 17                                XI000 PTS
; 18                                ONE PLAYER ONLY
; 19                                ONE OR TWO PLAYERS
; 1A                                - SCORE RANKING -
; 1B                                1ST
; 1C                                2ND
; 1D                                3RD
; 1E                                4TH
; 1F                                5TH
; 20                                6TH
; 21                                7TH
; 22                                8TH
; 23                                9TH
; 24                                10TH

PRINT_TEXT:
0435: 87          add  a,a                   ; A = A * 2.   This may affect C and PO flags.
0436: F5          push af
0437: 21 A2 04    ld   hl,$04A2              ; HL = address of TEXTPTRS        
043A: E6 7F       and  $7F                   ; mask in bits 0..6. Now A = a value in range of 0..127
043C: 5F          ld   e,a
043D: 16 00       ld   d,$00                 ; Extend A into DE 
043F: 19          add  hl,de                 ; HL now points to an entry in the TEXTPTRS lookup table.
0440: 5E          ld   e,(hl)
0441: 23          inc  hl
0442: 56          ld   d,(hl)                ; DE now holds a pointer to a character string to print.  
0443: EB          ex   de,hl                 ; HL = pointer to character string. DE we don't care about, it will be overwritten.
0444: 5E          ld   e,(hl)
0445: 23          inc  hl
0446: 56          ld   d,(hl)                ; DE = *HL. Now DE holds character RAM address to print text at
0447: 23          inc  hl
0448: EB          ex   de,hl                 ; Now HL = pointer to character RAM, DE = pointer to text to print
0449: 01 E0 FF    ld   bc,$FFE0              ; offset to add to HL after every character write. (-32 in decimal)
044C: F1          pop  af
044D: 38 0E       jr   c,$045D               ; if bit 7 of A was set on entry to this function, goto ERASE_TEXT
044F: FA 67 04    jp   m,$0467               ; if bit 7 is NOW set, then goto BEGIN_SCROLL_TEXT  *unused functionality*
0452: 1A          ld   a,(de)                ; read character to be drawn  
0453: FE 3F       cp   $3F                   ; is this the string terminator, #$3F?
0455: C8          ret  z                     ; yes, so exit routine
0456: D6 30       sub  $30
0458: 77          ld   (hl),a                ; write character to character RAM
0459: 13          inc  de                    ; bump DE to point to next character
045A: 09          add  hl,bc                 ; Add offset to screen address so that next character is drawn in row above
045B: 18 F5       jr   $0452                 ; and continue



; DE = pointer to text string to erase from screen
ERASE_TEXT:
045D: 1A          ld   a,(de)
045E: FE 3F       cp   $3F
0460: C8          ret  z
0461: 36 10       ld   (hl),$10              ; plot space character
0463: 13          inc  de
0464: 09          add  hl,bc
0465: 18 F6       jr   $045D



;
; ** THIS FUNCTIONALITY IS UNUSED **
;
; The only reason I'm documenting it is because I've covered near-identical code in Galaxian.
; I wouldn't waste time on it otherwise. 
;
; Set text up for scrolling. 
;
; HL = pointer to character RAM
; DE = pointer to text string to render
;

BEGIN_SCROLL_TEXT:
0467: 22 B5 40    ld   ($40B5),hl            ; store pointer to character RAM in COLUMN_SCROLL_CHAR_RAM_PTR    
046A: ED 53 B3 40 ld   ($40B3),de            ; now HL = pointer to text string, DE = pointer to character RAM 
046E: EB          ex   de,hl                 ; store pointer to next char to scroll on in COLUMN_SCROLL_NEXT_CHAR_PTR
046F: 7B          ld   a,e                   ; get low byte of character RAM address into A
0470: E6 1F       and  $1F                   ; mask in bits 0..4. Effectively A = A mod #$20 (32 decimal). A now represents a column index from 0-31
0472: 47          ld   b,a                   ; save column index in B.
0473: 87          add  a,a                   ; A=A*2. This is because attribute RAM requires 2 bytes per column.
0474: C6 20       add  a,$20                 ; add $20 (32 decimal) as OBJRAM_BACK_BUF starts at $4020 
0476: 6F          ld   l,a                    
0477: 26 40       ld   h,$40                 ; now HL = a pointer to scroll attribute value in OBJRAM_BACK_BUF 
0479: 22 B1 40    ld   ($40B1),hl            ; set COLUMN_SCROLL_ATTR_BACKBUF_PTR
047C: CB 3B       srl  e                     
047E: CB 3B       srl  e                     
0480: 7A          ld   a,d
0481: E6 03       and  $03
0483: 0F          rrca
0484: 0F          rrca
0485: B3          or   e
0486: E6 F8       and  $F8
0488: 4F          ld   c,a                   ; C = scroll offset to write to OBJRAM_BACK_BUF 
0489: 21 00 48    ld   hl,$4800              ; HL = start of character RAM
048C: 78          ld   a,b                   ; restore column index from B (see @$0472)
048D: 85          add  a,l                     
048E: 6F          ld   l,a                   ; Add column index to L. Now HL = pointer to column to clear
048F: 11 20 00    ld   de,$0020              ; offset to add to HL. $20 (32 decimal) characters per row
0492: 43          ld   b,e                   ; B = count of how many characters need to be cleared by DJNZ loop
0493: 36 10       ld   (hl),$10              ; write empty space character
0495: 19          add  hl,de                 ; add offset to HL. Now HL points to same column next row down
0496: 10 FB       djnz $0493
0498: 2A B1 40    ld   hl,($40B1)            ; restore attribute pointer from the stack
049B: 71          ld   (hl),c                ; write initial scroll offset to OBJRAM_BACK_BUF
049C: 3E 01       ld   a,$01
049E: 32 B0 40    ld   ($40B0),a             ; set IS_COLUMN_SCROLLING flag
04A1: C9          ret




;
; The TEXTPTRS table is a lookup table comprised of pointers to text strings.
;
; The text strings are always organised thus:
;   First 2 bytes: pointer to address in character RAM to begin printing text at.
;   Subsequent bytes: characters to print, terminated by #$3F (63 decimal)
;
; For example, lets take the first entry in the table, 3E 07.
;
; 3E 07 forms memory address $073E. 

; (Note: I suggest you open a memory window in the MAME debugger and view $073E, it'll make this a lot easier to follow.)
;
; The first 2 bytes stored at $073E are $96 and $4A. This forms a character RAM address of $4A96, where the first character will be drawn.
; The subsequent bytes, 47 41 4D 45 40 40 4F 56 45 32 represent the string "GAME  OVER" in (mostly) ASCII. $40 is a space character. 
; The next byte, $3F, "terminates" the string. (ie: it tells the print routine that nothing more is to be printed.)
;

TEXTPTRS:
04A2: 
    3E 07         ; GAME OVER                            
    4B 07         ; PUSH START BUTTON 
    5F 07         ; PLAYER ONE 
    6C 07         ; PLAYER TWO 
    EC 04         ; HIGH SCORE
    F9 04         ; CREDIT 
    08 05         ; HOW FAR CAN YOU INVADE 
    21 05         ; FUEL
    28 05         ; CONGRATULATIONS 
    3A 05         ; YOU COMPLETED YOUR DUTIES
    56 05         ; GOOD LUCK NEXT TIME
    72 05         ; PLAY
    79 05         ; - SCRAMBLE -
    88 05         ; - SCORE TABLE -  
    9A 05         ; (C) KONAMI  1981 
    9A 05         ; (C) KONAMI  1981 
    9A 05         ; (C) KONAMI  1981 
    9A 05         ; (C) KONAMI  1981 
    AB 05         ; OUR SCRAMBLE SYSTEM 
    C4 05         ; 2 COINS 1 PLAY
    D5 05         ; 3 COINS 1 PLAY
    E6 05         ; 1 COIN  2 PLAY 
    F7 05         ; BONUS JET   FOR
    08 06         ; 000 PTS
    12 06         ; ONE PLAYER ONLY
    24 06         ; ONE OR TWO PLAYERS
    39 06         ; - SCORE RANKING -
    4D 06         ; 1ST
    60 06         ; 2ND
    73 06         ; 3RD
    86 06         ; 4TH
    99 06         ; 5TH
    AC 06         ; 6TH
    BF 06         ; 7TH
    D2 06         ; 8TH
    E5 06         ; 9TH
    F8 06         ; 10TH

04EC:  80 4A 48 49 47 48 40 53 43 4F 52 45 3F 9F 4B 40  .JHIGH@SCORE?.K@
04FC:  43 52 45 44 49 54 40 40 40 40 40 3F 51 4B 48 4F  CREDIT@@@@@?QKHO
050C:  57 40 46 41 52 40 43 41 4E 40 59 4F 55 40 49 4E  W@FAR@CAN@YOU@IN
051C:  56 41 44 45 3F 5E 4B 46 55 45 4C 3F CC 4A 43 4F  VADE?^KFUEL?.JCO
052C:  4E 47 52 41 54 55 4C 41 54 49 4F 4E 53 3F 6E 4B  NGRATULATIONS?nK
053C:  59 4F 55 40 43 4F 4D 50 4C 45 54 45 44 40 59 4F  YOU@COMPLETED@YO
054C:  55 52 40 44 55 54 49 45 53 3F 70 4B 47 4F 4F 44  UR@DUTIES?pKGOOD
055C:  40 4C 55 43 4B 40 4E 45 58 54 40 54 49 4D 45 40  @LUCK@NEXT@TIME@
056C:  41 47 41 49 4E 3F 26 4A 50 4C 41 59 3F A9 4A 5B  AGAIN?&JPLAY?.J[
057C:  40 53 43 52 41 4D 42 4C 45 40 5B 3F C7 4A 5B 40  @SCRAMBLE@[?.J[@
058C:  53 43 4F 52 45 40 54 41 42 4C 45 40 5B 3F BC 4A  SCORE@TABLE@[?.J
059C:  6E 40 4B 4F 4E 41 4D 49 40 40 31 39 38 31 3F 54  n@KONAMI@@1981?T
05AC:  4B 40 4F 55 52 40 53 43 52 41 4D 42 4C 45 40 53  K@OUR@SCRAMBLE@S
05BC:  59 53 54 45 4D 40 02 3F D5 4A 32 40 43 4F 49 4E  YSTEM@.?.J2@COIN
05CC:  53 40 31 40 50 4C 41 59 3F D5 4A 33 40 43 4F 49  S@1@PLAY?.J3@COI
05DC:  4E 53 40 31 40 50 4C 41 59 3F D5 4A 31 40 43 4F  NS@1@PLAY?.J1@CO
05EC:  49 4E 40 40 32 40 50 4C 41 59 3F 78 4B 42 4F 4E  IN@@2@PLAY?xKBON
05FC:  55 53 40 4A 45 54 40 40 46 4F 52 3F 58 49 30 30  US@JET@@FOR?XI00
060C:  30 40 50 54 53 3F D4 4A 4F 4E 45 40 50 4C 41 59  0@PTS?.JONE@PLAY
061C:  45 52 40 4F 4E 4C 59 3F F4 4A 4F 4E 45 40 4F 52  ER@ONLY?.JONE@OR
062C:  40 54 57 4F 40 50 4C 41 59 45 52 53 3F 04 4B 5B  @TWO@PLAYERS?.K[
063C:  40 53 43 4F 52 45 40 52 41 4E 4B 49 4E 47 40 5B  @SCORE@RANKING@[
064C:  3F E7 4A 31 53 54 40 40 40 40 40 40 40 40 40 40  ?.J1ST@@@@@@@@@@
065C:  50 54 53 3F E9 4A 32 4E 44 40 40 40 40 40 40 40  PTS?.J2ND@@@@@@@
066C:  40 40 40 50 54 53 3F EB 4A 33 52 44 40 40 40 40  @@@PTS?.J3RD@@@@
067C:  40 40 40 40 40 40 50 54 53 3F ED 4A 34 54 48 40  @@@@@@PTS?.J4TH@
068C:  40 40 40 40 40 40 40 40 40 50 54 53 3F EF 4A 35  @@@@@@@@@PTS?.J5
069C:  54 48 40 40 40 40 40 40 40 40 40 40 50 54 53 3F  TH@@@@@@@@@@PTS?
06AC:  F1 4A 36 54 48 40 40 40 40 40 40 40 40 40 40 50  .J6TH@@@@@@@@@@P
06BC:  54 53 3F F3 4A 37 54 48 40 40 40 40 40 40 40 40  TS?.J7TH@@@@@@@@
06CC:  40 40 50 54 53 3F F5 4A 38 54 48 40 40 40 40 40  @@PTS?.J8TH@@@@@
06DC:  40 40 40 40 40 50 54 53 3F F7 4A 39 54 48 40 40  @@@@@PTS?.J9TH@@
06EC:  40 40 40 40 40 40 40 40 50 54 53 3F F9 4A 31 30  @@@@@@@@PTS?.J10
06FC:  54 48 40 40 40 40 40 40 40 40 40 50 54 53 3F     TH@@@@@@@@@PTS?


;
; Value in A      What it does 
; ==========      ========================================                  
; 0               Invokes DISPLAY_MISSIONS_COMPLETED_FLAGS
; 1               Invokes DISPLAY_CREDITS
; 2               Invokes DISPLAY_CURRENT_PLAYER_PROGRESS_BAR  
; 3               Invokes DISPLAY_CURRENT_PLAYER_LIVES

HEAD_UP_DISPLAY_COMMAND:
070B: A7          and  a                     ; test if zero
070C: CA 20 09    jp   z,$0920               ; if zero, goto DISPLAY_MISSIONS_COMPLETED_FLAGS
070F: 3D          dec  a
0710: CA 1A 07    jp   z,$071A               ; if zero, goto DISPLAY_CREDITS
0713: 3D          dec  a
0714: CA 3E 09    jp   z,$093E               ; if zero, goto DISPLAY_CURRENT_PLAYER_PROGRESS_BAR
0717: C3 FB 08    jp   $08FB                 ; default: goto DISPLAY_CURRENT_PLAYER_LIVES


DISPLAY_CREDITS:
071A: 3E 05       ld   a,$05                 ; index of text string "CREDIT"
071C: CD 35 04    call $0435                 ; call PRINT_TEXT                 
071F: 3A 02 40    ld   a,($4002)             ; read NUM_CREDITS
0722: FE 63       cp   $63                   ; compare to 99 
0724: 38 02       jr   c,$0728               ; if A < 99 , skip to $0728
0726: 3E 63       ld   a,$63                 ; clamp (limit) number of credits to 99 
0728: CD 79 07    call $0779                 ; call CONVERT_A_TO_BCD
072B: 47          ld   b,a                   ; save credits as BCD in B
072C: E6 F0       and  $F0                   ; mask in high nibble, which is first digit of BCD
072E: 28 07       jr   z,$0737               ; if the first digit is 0, goto $0737. We don't display it.
0730: 0F          rrca                       ; shift high nibble...
0731: 0F          rrca
0732: 0F          rrca
0733: 0F          rrca                       ; to low nibble.. converting first BCD digit to decimal.
0734: 32 9F 4A    ld   ($4A9F),a             ; Write first digit of credits to character RAM
0737: 78          ld   a,b                   ; get credits as BCD into A again. We preserved it in B @$072B
0738: E6 0F       and  $0F                   ; mask in low nibble, which is second digit of BCD. Converts second BCD digit to decimal.
073A: 32 7F 4A    ld   ($4A7F),a             ; Write second digit of credits to character RAM 
073D: C9          ret


073E:  96 4A 47 41 4D 45 40 40 4F 56 45 52 3F F1 4A 50  .JGAME@@OVER?.JP
074E:  55 53 48 40 53 54 41 52 54 40 42 55 54 54 4F 4E  USH@START@BUTTON
075E:  3F 94 4A 50 4C 41 59 45 52 40 4F 4E 45 3F 94 4A  ?.JPLAYER@ONE?.J
076E:  50 4C 41 59 45 52 40 54 57 4F 3F 47 E6 0F C6 00  PLAYER@TWO


;
; Convert value in register A to BCD equivalent 
; 
; For example, if you pass in $63 (99 decimal) in A, this function will return 99 BCD
; 
; Expects:
; A = non BCD value, from 0..99
;
; Returns:
; A = BCD equivalent
; 

CONVERT_A_TO_BCD:
0779: 47          ld   b,a                     ; preserve A in B register
077A: E6 0F       and  $0F                     ; mask in low nibble
077C: C6 00       add  a,$00                   ; clears the half carry flag which might affect DAA
077E: 27          daa
077F: 4F          ld   c,a                     ; store result in C
0780: 78          ld   a,b                     ; restore A to its original value
0781: E6 F0       and  $F0                     ; mask in high nibble
0783: 28 0B       jr   z,$0790                 ; if high nibble is zero we don't care, goto $0790
0785: 0F          rrca                         ; shift high nibble...
0786: 0F          rrca
0787: 0F          rrca
0788: 0F          rrca                         ; ... into lower nibble
0789: 47          ld   b,a                     ; and store in B.
078A: AF          xor  a                       ; clear A
078B: C6 16       add  a,$16                   ; Add 16 hex (which in BCD terms is 16 decimal) to A  (so A will progress in BCD from 0->16->32->48... )
078D: 27          daa                          
078E: 10 FB       djnz $078B                   ; and repeat until B is 0.
0790: 81          add  a,c                     ; add in value of lower nibble preserved @$256f  
0791: 27          daa                          ; ensure A is a valid BCD number
0792: C9          ret                          ; and we're out




;
; This routine renders a new part of the landscape offscreen every 16 pixels (or, each time the playfield scrolls 2 character rows' worth) 
; ready to be scrolled on "Just in time" .  
;
; This routine does not render the enemies on top of the landscape; that is handled by DRAW_ALL_CHARACTER_BASED_GROUND_OBJECTS @ $084B.  
;
; NOTES:
;
; Algorithm is roughly:
; IF CAN_DRAW_LANDSCAPE_1 = FALSE OR CAN_DRAW_LANDSCAPE_2 = FALSE THEN EXIT 
; Clear 2 rows of characters offscreen ready to be filled with new landscape
; Plot first character for ground
; Fill from beneath this character to bottom of playfield with repeating solid character appropriate for level (brick for maze or solid colour for cave)
; Plot second character for ground 
; Fill from beneath this character to bottom of playfield with repeating solid character appropriate for level (brick for maze or solid colour for cave)
; IF landscape doesn't have a ceiling, THEN EXIT 
; ELSE
;   Plot first character for ceiling
;   Fill from "above" this character to "top" of playfield with repeating solid character appropriate for level (brick for maze or solid colour for cave)
;   Plot second character for ceiling 
;   Fill from "above" this character to "top" of playfield with repeating solid character appropriate for level (brick for maze or solid colour for cave)
; END IF
;
; 

DRAW_LANDSCAPE:                                              
; First check both our flags CAN_DRAW_LANDSCAPE_1 and CAN_DRAW_LANDSCAPE_2. If either flag is unset we can't draw our landscape. 
0793: 3A 10 41    ld   a,($4110)             ; read CAN_DRAW_LANDSCAPE_1
0796: 0F          rrca                       ; move flag into carry
0797: D0          ret  nc                    ; exit if flag not set
0798: 3A 30 42    ld   a,($4230)             ; read CAN_DRAW_LANDSCAPE_2
079B: 0F          rrca                       ; move flag into carry
079C: D0          ret  nc                    ; exit if flag not set

; OK, both CAN_DRAW_LANDSCAPE_1 and CAN_DRAW_LANDSCAPE_2 flags are set, so we have green light to draw new part of landscape.
079D: 2A 35 42    ld   hl,($4235)            ; load HL with contents of LANDSCAPE_GROUND_SECOND_CHAR_PTR
07A0: 7D          ld   a,l                   ; ensure that HL points to.. 
07A1: E6 E0       and  $E0
07A3: 6F          ld   l,a                   ; ..the very start of a character row
07A4: 11 05 00    ld   de,$0005              ; the height of the scores + progress bar is 5 characters
07A7: 19          add  hl,de                 ; now HL points to first character column of landscape to draw

; Preparation work: clear 2 rows of characters to make way for the landscape we're going to draw  
07A8: 3E 10       ld   a,$10                 ; ordinal for empty space
07AA: 06 19       ld   b,$19                 ; 25 decimal
07AC: D7          rst  $10                   ; draw 25 empty space characters 
07AD: 11 07 00    ld   de,$0007              ; offset to add to HL (25 + 7 = 32, which is number of chars per row)
07B0: 19          add  hl,de                 ; bump HL to point to start of next row down
07B1: 06 19       ld   b,$19
07B3: D7          rst  $10                   ; draw 25 empty space characters.

; Plot the first ground character.      
07B4: DD 21 30 42 ld   ix,$4230
07B8: DD 7E 01    ld   a,(ix+$01)            ; read LANDSCAPE_GROUND_FIRST_CHAR           
07BB: DD 6E 02    ld   l,(ix+$02)            ; read LSB of LANDSCAPE_GROUND_FIRST_CHAR_PTR 
07BE: DD 66 03    ld   h,(ix+$03)            ; read MSB of LANDSCAPE_GROUND_FIRST_CHAR_PTR. Now HL = character RAM address.
07C1: 77          ld   (hl),a                ; plot first character 

; OK we've plotted the first character. 
; We now must fill down to the bottom (in reality, the right hand column) of the scrolling area with a repeating solid character. 
; Calculate how many solid characters we need to plot. 
07C2: 7D          ld   a,l                   ; get LSB of LANDSCAPE_GROUND_FIRST_CHAR_PTR into A
07C3: E6 1F       and  $1F                   ; As each row is 32 characters wide, ANDing LSB with 31 will return index of character on row
07C5: 47          ld   b,a                   ; save index in B 
07C6: 3E 1D       ld   a,$1D                 ; Remaining number of characters to draw = (29 decimal - B)
07C8: 90          sub  b
07C9: 28 10       jr   z,$07DB               ; if result is zero then we don't need to fill in a gap with solid characters, goto $07DB

; A now holds number of solid characters to draw
07CB: 47          ld   b,a                   ; b = number of characters to plot

; what type of solid character to use?
07CC: 0E 39       ld   c,$39                 ; ordinal of solid "rock" character 
07CE: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
07D1: E6 1C       and  $1C                   ; Are we on Level 4, 5 or BASE?
07D3: 28 02       jr   z,$07D7               ; if not, goto $07D7

07D5: 0E 3D       ld   c,$3D                 ; ordinal of solid "brick" character

; Working from left to right, fill in the empty gap between the "edge" character and bottom of scroll area with character ordinal <C> 
07D7: 23          inc  hl
07D8: 71          ld   (hl),c                ; plot to character RAM
07D9: 10 FC       djnz $07D7                 ; repeat until all solid characters plotted
  
; This code is a repeat of the above ($07B8-07D9) so I won't document it.
07DB: DD 7E 04    ld   a,(ix+$04)            ; read LANDSCAPE_GROUND_SECOND_CHAR
07DE: DD 6E 05    ld   l,(ix+$05)            ; read LSB of LANDSCAPE_GROUND_SECOND_CHAR_PTR  
07E1: DD 66 06    ld   h,(ix+$06)            ; read MSB of LANDSCAPE_GROUND_SECOND_CHAR_PTR. Now HL = character RAM address.
07E4: 77          ld   (hl),a                ; plot first character 
07E5: 7D          ld   a,l
07E6: E6 1F       and  $1F                   
07E8: 47          ld   b,a
07E9: 3E 1D       ld   a,$1D                 
07EB: 90          sub  b
07EC: 28 10       jr   z,$07FE               ; If we have nothing to draw, goto $07FE
07EE: 47          ld   b,a
07EF: 0E 39       ld   c,$39                 ; ordinal of solid "rock" character
07F1: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
07F4: E6 1C       and  $1C
07F6: 28 02       jr   z,$07FA
07F8: 0E D0       ld   c,$D0                 ; ordinal of solid "brick" character
07FA: 23          inc  hl
07FB: 71          ld   (hl),c                ; plot to character RAM
07FC: 10 FC       djnz $07FA                 ; repeat until all solid characters plotted

07FE: DD 36 00 00 ld   (ix+$00),$00          ; clear flag 

; Does the landscape have a ceiling that needs to be drawn?
0802: DD CB 08 46 bit  0,(ix+$08)            ; test LANDSCAPE_HAS_CEILING_FLAG
0806: C8          ret  z                     ; exit if we don't have a ceiling to draw

; Render the ceiling part of the landscape.
; This code is pretty near identical to the ground rendering code, except this code fills from right to left.
0807: DD 7E 09    ld   a,(ix+$09)            ; read LANDSCAPE_CEILING_FIRST_CHAR
080A: DD 6E 0A    ld   l,(ix+$0a)            ; read LSB of LANDSCAPE_CEILING_FIRST_CHAR_PTR 
080D: DD 66 0B    ld   h,(ix+$0b)            ; read MSB of LANDSCAPE_CEILING_FIRST_CHAR_PTR
0810: 77          ld   (hl),a                ; plot character to character RAM

; calculate how many solid characters we need to plot to fill in the roof.
0811: 7D          ld   a,l                   ; get LSB of LANDSCAPE_CEILING_FIRST_CHAR_PTR into A
0812: E6 1F       and  $1F                   ; As each row is 32 characters wide, ANDing LSB with 31 will return index of character on row
0814: D6 05       sub  $05                   
0816: 28 10       jr   z,$0828

; A now holds number of characters to draw
0818: 47          ld   b,a

; what type of solid character to use?
0819: 0E 39       ld   c,$39                 ; ordinal of solid "rock" character
081B: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
081E: E6 1C       and  $1C                   ; Are we on Level 4, 5 or BASE?
0820: 28 02       jr   z,$0824               ; if not, goto $0824
0822: 0E D0       ld   c,$D0                 ; ordinal of solid "brick" character

; Working from *right to left*, fill in the empty gap between the "edge" character and top of scroll area with character ordinal <C> 
0824: 2B          dec  hl
0825: 71          ld   (hl),c                ; plot to character RAM
0826: 10 FC       djnz $0824                 ; repeat until all solid characters plotted

0828: DD 7E 0C    ld   a,(ix+$0c)            ; read LANDSCAPE_CEILING_SECOND_CHAR
082B: DD 6E 0D    ld   l,(ix+$0d)            ; read LSB of LANDSCAPE_CEILING_SECOND_CHAR_PTR
082E: DD 66 0E    ld   h,(ix+$0e)            ; read MSB of LANDSCAPE_CEILING_SECOND_CHAR_PTR
0831: C3 97 09    jp   $0997                 ; jump to PLOT_LANDSCAPE_CHAR

; jumped to from $099D..
0834: 28 10       jr   z,$0846
0836: 47          ld   b,a
0837: 0E 39       ld   c,$39                 ; ordinal of solid "rock" character
0839: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS  
083C: E6 1C       and  $1C
083E: 28 02       jr   z,$0842
0840: 0E 3D       ld   c,$3D                 ; ordinal of solid "brick" character
0842: 2B          dec  hl
0843: 71          ld   (hl),c
0844: 10 FC       djnz $0842

0846: DD 36 08 00 ld   (ix+$08),$00
084A: C9          ret




;
; Renders all stationary rockets, fuel tanks, mystery and bases.
;
;

DRAW_ALL_CHARACTER_BASED_GROUND_OBJECTS:
084B: 11 04 00    ld   de,$0004              ; sizeof(CHAR_BASED_GROUND_OBJECT)
084E: 06 08       ld   b,$08                 ; 
0850: DD 21 60 42 ld   ix,$4260              ; load IX with address of CHAR_BASED_GROUND_OBJECTS array
0854: D9          exx
0855: CD 5E 08    call $085E                 ; call DRAW_CHARACTER_BASED_GROUND_OBJECT
0858: D9          exx
0859: DD 19       add  ix,de                 ; bump IX to point to next CHAR_BASED_GROUND_OBJECT in array 
085B: 10 F7       djnz $0854                 ; repeat until B==0 
085D: C9          ret


; A ground object is 2x2 characters. This routine plots the characters to character RAM.
;
; IX = pointer to CHAR_BASED_GROUND_OBJECT structure
;

DRAW_CHARACTER_BASED_GROUND_OBJECT:
085E: DD CB 00 46 bit  0,(ix+$00)            ; read CHAR_BASED_GROUND_OBJECT.Undrawn flag           
0862: C8          ret  z                     ; return if ground object has been drawn.
0863: DD 36 00 00 ld   (ix+$00),$00          ; clear CHAR_BASED_GROUND_OBJECT.Undrawn flag            
0867: DD 7E 01    ld   a,(ix+$01)            ; read CHAR_BASED_GROUND_OBJECT.Code flag            
086A: 87          add  a,a                   
086B: 87          add  a,a                   ; multiply A by 4, to give us ordinal of first character to POKE to character RAM
086C: DD 6E 02    ld   l,(ix+$02)            ; read CHAR_BASED_GROUND_OBJECT.CharRamPtrLo
086F: DD 66 03    ld   h,(ix+$03)            ; read CHAR_BASED_GROUND_OBJECT.CharRamPtrHi

; HL is a character RAM address where we start drawing our object. Each object is 2x2 characters in size.
; A is the ordinal of the first character to plot.
0872: 77          ld   (hl),a                ; plot character
0873: 3C          inc  a
0874: 23          inc  hl
0875: 77          ld   (hl),a                ; plot character
0876: 3C          inc  a
0877: 11 1F 00    ld   de,$001F              ; offset to add to get to next character row
087A: 19          add  hl,de
087B: 77          ld   (hl),a                ; plot character
087C: 3C          inc  a
087D: 23          inc  hl
087E: 77          ld   (hl),a                ; plot character
087F: C9          ret




DRAW_REMAINING_PLAYER_FUEL:
0880: 3A 05 41    ld   a,($4105)             ; read CURRENT_PLAYER_FUEL         
0883: 0F          rrca                       ; divide by 2 
0884: 4F          ld   c,a
0885: E6 78       and  $78                   ; preserve bits 3-6; 
0887: 0F          rrca                                                 
0888: 0F          rrca
0889: 0F          rrca
088A: 47          ld   b,a                   ; B = A on entry / 16

; calculate how many full fuel cells to draw
088B: 3E 0F       ld   a,$0F
088D: 90          sub  b
088E: 21 BE 4A    ld   hl,$4ABE              ; character RAM address to draw at
0891: 11 E0 FF    ld   de,$FFE0              ; load DE with -32
0894: 04          inc  b
0895: 05          dec  b
0896: 28 05       jr   z,$089D

; draw full fuel cells. B = number of full cells to draw
0898: 36 CB       ld   (hl),$CB              ; draw solid block of fuel
089A: 19          add  hl,de                 ; bump HL to point to character beneath 
089B: 10 FB       djnz $0898                 ; repeat until B==0

; now calculate remainder of fuel cells to draw 
089D: 47          ld   b,a
089E: 79          ld   a,c
089F: E6 07       and  $07
08A1: D9          exx
08A2: 21 B5 08    ld   hl,$08B5              ; pointer to FUEL_CELL_CHARS array  
08A5: 5F          ld   e,a
08A6: 16 00       ld   d,$00
08A8: 19          add  hl,de
08A9: 7E          ld   a,(hl)                ; get ordinal of fuel character to plot 
08AA: D9          exx
08AB: 77          ld   (hl),a                ; plot to character RAM
08AC: 04          inc  b
08AD: 05          dec  b
08AE: C8          ret  z
08AF: 19          add  hl,de
08B0: 36 3C       ld   (hl),$3C              ; plot a blue empty square
08B2: 10 FB       djnz $08AF
08B4: C9          ret

; These are the ordinals for the characters representing fuel cells
; 3C = blue empty square
; $C4 = fuel cell nearly empty, all the way to...
; $CA = ..fuel cell nearly full
FUEL_CELL_CHARS:
08B5: 3C C4 C5 C6 C7 C8 C9 CA         



;
; TODO: this code here appears to be uncalled - or it may be for P2 cocktail?
;
;

08BD: CD 80 08    call $0880                 ; call DRAW_REMAINING_PLAYER_FUEL
08C0: 3A 01 41    ld   a,($4101)
08C3: 21 64 4B    ld   hl,$4B64
08C6: 11 E0 FF    ld   de,$FFE0              ; load DE with -32 decimal 
08C9: 47          ld   b,a
08CA: 3E 18       ld   a,$18
08CC: 90          sub  b
08CD: 04          inc  b
08CE: 05          dec  b
08CF: 28 05       jr   z,$08D6
08D1: 36 0C       ld   (hl),$0C
08D3: 19          add  hl,de
08D4: 10 FB       djnz $08D1
08D6: 47          ld   b,a
08D7: A7          and  a
08D8: 28 05       jr   z,$08DF
08DA: 36 10       ld   (hl),$10
08DC: 19          add  hl,de
08DD: 10 FB       djnz $08DA
08DF: 3A 02 41    ld   a,($4102)
08E2: 21 63 4B    ld   hl,$4B63
08E5: 47          ld   b,a
08E6: 3E 18       ld   a,$18
08E8: 90          sub  b
08E9: 04          inc  b
08EA: 05          dec  b
08EB: 28 05       jr   z,$08F2
08ED: 36 0D       ld   (hl),$0D
08EF: 19          add  hl,de
08F0: 10 FB       djnz $08ED
08F2: 47          ld   b,a
08F3: A7          and  a
08F4: C8          ret  z
08F5: 36 10       ld   (hl),$10
08F7: 19          add  hl,de
08F8: 10 FB       djnz $08F5
08FA: C9          ret



DISPLAY_CURRENT_PLAYER_LIVES:
; First clear all of the existing spaceships representing lives left at bottom left (as player sees it) of screen
08FB: 21 BF 4B    ld   hl,$4BBF              ; character RAM address of leftmost "life"
08FE: 11 E0 FF    ld   de,$FFE0              ; load de with -32 
0901: 06 0C       ld   b,$0C                 ; 12 characters to erase
0903: 36 10       ld   (hl),$10              ; ordinal of empty character
0905: 19          add  hl,de                 ; bump HL to point to row above
0906: 10 FB       djnz $0903                 ; repeat until all ships (if any) are erased

; And now redraw spaceships representing lives left
0908: 21 BF 4B    ld   hl,$4BBF
090B: 3A 08 41    ld   a,($4108)             ; read CURRENT_PLAYER_LIVES
090E: A7          and  a                     ; test if current player has zero lives
090F: C8          ret  z                     ; return if true
0910: FE 07       cp   $07                   ; does player have 7 or more lives?
0912: 38 02       jr   c,$0916               ; if player has <7 lives, goto $0916
0914: 3E 06       ld   a,$06                 ; otherwise, we can draw a max of 6 lives
0916: 47          ld   b,a                   ; B now holds number of spaceships to draw  
0917: 36 0A       ld   (hl),$0A              ; plot character for rocket of spaceship 
0919: 19          add  hl,de                 ; bump HL to point to character directly above one just plotted
091A: 36 0B       ld   (hl),$0B              ; plot character for cockpit of spaceship 
091C: 19          add  hl,de                 ; bump HL to point to character directly above one just plotted
091D: 10 F8       djnz $0917                 ; repeat until all spaceships drawn           
091F: C9          ret



;
; Draw flags representing the number of missions completed.
;

DISPLAY_MISSIONS_COMPLETED_FLAGS:
0920: 3A 00 41    ld   a,($4100)             ; read CURRENT_PLAYER_MISSIONS_COMPLETED
0923: E6 0F       and  $0F                   ; ensure value is from 0..15
0925: 3C          inc  a                     ; then add 1
0926: 47          ld   b,a                   ; B is now number of flags to draw (1..16)

; Draw B number of flags
0927: 3E 10       ld   a,$10                 ; compute how many empty characters need to be drawn
0929: 90          sub  b                     ; empty characters = 16-B
092A: 21 5F 48    ld   hl,$485F              ; character RAM address to start drawing flags
092D: 11 20 00    ld   de,$0020              ; offset to add to HL after plot: there's 32 characters per row
0930: 36 0E       ld   (hl),$0E              ; plot flag character
0932: 19          add  hl,de                 ; bump HL to point to character directly beneath one just plotted
0933: 10 FB       djnz $0930                 ; repeat until B==0

; We've drawn the flags. Do we need to pad out the remaining space with empty characters?
; A = count of empty characters that need to be drawn 
0935: A7          and  a                     ; set zero flag if A == 0
0936: C8          ret  z                     ; return if A is zero

; draw [A] number of empty space characters in a column starting at HL
0937: 36 10       ld   (hl),$10              ; plot an empty space character
0939: 19          add  hl,de                 ; bump HL to point to character directly beneath one just plotted
093A: 3D          dec  a                     ; decrement count of empty spaces to be drawn
093B: 20 FA       jr   nz,$0937              ; repeat until A==0
093D: C9          ret


;
; This routine is responsible for drawing the progress bar directly beneath the player scores and high score. 
;
; The progress bar is depicted as a table with 2 rows and 6 columns:
;
;    1ST | 2ND | 3RD | 4TH | 5TH | BASE 
;    ----------------------------------
;        |     |     |     |     |     
;
; The first row is the table headings listing the "sections" in the game - think of the <TH> element in HTML if that makes more sense.
; The second row are coloured cells that represent the players progress. I suppose these would be like <TD> elements.
; Red cells indicate that a section is completed; purple cells indicate that a section is uncompleted.
;

DISPLAY_CURRENT_PLAYER_PROGRESS_BAR:
; First draw the table headers (1ST, 2ND , .. BASE ) 
093E: DD 21 63 4B ld   ix,$4B63              ; address in character RAM of first character to plot
0942: 11 E0 FF    ld   de,$FFE0              ; offset to add to HL (-32 decimal) after plotting each cell 
0945: 21 7F 09    ld   hl,$097F              ; load HL with address of PROGRESS_BAR_HEADER_TEXT
0948: 06 18       ld   b,$18                 ; the bar is 24 characters long in total
094A: 7E          ld   a,(hl)                ; read character ordinal 
094B: DD 77 00    ld   (ix+$00),a            ; plot character into character RAM
094E: 23          inc  hl                    ; bump HL to point to next character to draw
094F: DD 19       add  ix,de                 ; bump IX to point to character directly above one just plotted
0951: 10 F7       djnz $094A                 ; repeat until B==0

; then draw purple table cells beneath the headers 
0953: 21 64 4B    ld   hl,$4B64              ; character RAM address
0956: 11 E0 FF    ld   de,$FFE0              ; offset to add to HL (-32 decimal) after plotting each cell 
0959: DD 21 A0 09 ld   ix,$09A0              ; load IX with address of PROGRESS_BAR_PURPLE_CELLS
095D: 06 18       ld   b,$18                 ; the cells are 24 characters long in total
095F: DD 7E 00    ld   a,(ix+$00)
0962: 77          ld   (hl),a
0963: DD 23       inc  ix
0965: 19          add  hl,de                 ; bump HL to point to character directly above one just plotted
0966: 10 F7       djnz $095F                 ; repeat until all cells are purple

; overwrite purple table cells with red to show what section the player is in
0968: 3A 1E 41    ld   a,($411E)             ; read CURRENT_PLAYERS_LEVEL
096B: 3C          inc  a                     ; ensure value is nonzero 

096C: 47          ld   b,a                   ; now B indicates how many cells to turn red
096D: 21 64 4B    ld   hl,$4B64              ; character RAM address
0970: 36 81       ld   (hl),$81              ; overwrite purple cell...
0972: 19          add  hl,de
0973: 36 82       ld   (hl),$82
0975: 19          add  hl,de
0976: 36 82       ld   (hl),$82
0978: 19          add  hl,de
0979: 36 83       ld   (hl),$83              ; .. with red.
097B: 19          add  hl,de
097C: 10 F2       djnz $0970                 ; repeat until B==0
097E: C9          ret

; Ordinals of the characters comprising the header text of the "progress bar". See $093E.

PROGRESS_BAR_HEADER_TEXT:
       1  S  T  |  2  N  D  |  3  R  D  |  4  T  H  |
097F:  50 51 52 6D 53 54 55 6D 56 57 55 6D 58 59 5A 6D  

       5  T  H  |  B  A  S  E
098F:  5B 59 5A 6D 64 65 51 66                          


;
; invoked from DRAW_LANDSCAPE. I think the reason this code is separated from the main routine is to make tracing
; logic that bit more difficult for hackers back in the day. I don't see any other reason for doing it.
;

PLOT_LANDSCAPE_CHAR:
0997: 77          ld   (hl),a
0998: 7D          ld   a,l
0999: E6 1F       and  $1F
099B: D6 05       sub  $05
099D: C3 34 08    jp   $0834


; Ordinals of the characters comprising the purple part of the progress bar. See $0953

PROGRESS_BAR_PURPLE_CELLS:
09A0:  6E 6F 6F 80 6E 6F 6F 80 6E 6F 6F 80 6E 6F 6F 80  
09B0:  6E 6F 6F 80 6E 6F 6F 80                          

09B8: 6E          ld   l,(hl)
09B9: 6F          ld   l,a
09BA: 6F          ld   l,a
09BB: 80          add  a,b
09BC: 6E          ld   l,(hl)
09BD: 6F          ld   l,a
09BE: 6F          ld   l,a
09BF: 80          add  a,b


; Non maskable interrupt (NMI) handler
            
NMI_HANDLER:
09C0: F5          push af
09C1: C5          push bc
09C2: D5          push de
09C3: E5          push hl
09C4: 08          ex   af,af'
09C5: D9          exx
09C6: F5          push af
09C7: C5          push bc
09C8: D5          push de
09C9: E5          push hl
09CA: DD E5       push ix
09CC: FD E5       push iy
09CE: AF          xor  a
09CF: 32 01 68    ld   ($6801),a             ; disable NMI

; update attributes, sprites 
09D2: 21 20 40    ld   hl,$4020              ; pointer to OBJRAM_BACK_BUF buffer held in RAM
09D5: 11 00 50    ld   de,$5000              ; start of screen attribute RAM
09D8: 01 80 00    ld   bc,$0080              ; number of bytes to copy from OBJRAM_BACK_BUF 
09DB: ED B0       ldir                       ; update screen & sprites in one go

09DD: 3A 00 70    ld   a,($7000)             ; kick watchdog
09E0: 3A 15 40    ld   a,($4015)             ; read PREV_PREV_PORT_STATE_8100
09E3: 32 16 40    ld   ($4016),a             ; and write to PREV_PREV_PREV_STATE_8100 
09E6: 3A 13 40    ld   a,($4013)             ; read PREV_PORT_STATE_8100
09E9: C3 CA 21    jp   $21CA                 ; jump to rest of NMI handler


UNPROCESSED_COINS:
09EC: 21 18 40    ld   hl,$4018              ; read UNPROCESSED_COINS
09EF: 7E          ld   a,(hl)                ; Read value
09F0: A7          and  a                     ; test if zero. 
09F1: 28 03       jr   z,$09F6               ; if zero, goto $09F6 
09F3: 35          dec  (hl)                  ; Otherwise, decrement UNPROCESSED_COINS
09F4: 3E 01       ld   a,$01
09F6: 32 02 68    ld   ($6802),a             ; write to coin counter
                             
09F9: 21 10 40    ld   hl,$4010              ; pointer to PORT_STATE_8100 value
09FC: 7E          ld   a,(hl)                ; read value
09FD: 2C          inc  l
09FE: 2C          inc  l
09FF: 2C          inc  l                     ; bump HL to $4013, which is PREV_PORT_STATE_8100 value
0A00: B6          or   (hl)                  ; combine bits set for current state of port 8100 with bits set from previous state
0A01: 2C          inc  l
0A02: 2C          inc  l                     ; bump HL to $4015, which is PREV_PREV_PORT_STATE_8100 value
0A03: 2F          cpl                        ; flip bits
0A04: A6          and  (hl)
0A05: 2C          inc  l                     ; bump HL to $4016, which is PREV_PREV_PREV_STATE_8100 value 
0A06: A6          and  (hl)
0A07: E6 C4       and  $C4                   ; mask in IPT_COIN1, IPT_COIN2 and IPT_SERVICE1 bits
0A09: 28 21       jr   z,$0A2C               ; if none of them are pressed, goto $0A2C

; if we get here, IPT_COIN1 or IPT_COIN2 or IPT_SERVICE1 bits are set
; If we've inserted a coin, we need to acknowledge it. If we've pressed SERVICE on the other hand, we get free credits
0A0B: 47          ld   b,a
0A0C: E6 C0       and  $C0                   ; mask in IPT_COIN1 or IPT_COIN2 bits  
0A0E: 28 05       jr   z,$0A15               ; if no coins inserted, must be SERVICE switch that's pressed, goto $0A15

; Coin has been inserted
0A10: 3E 06       ld   a,$06
0A12: 32 18 40    ld   ($4018),a             ; set UNPROCESSED_COINS

; Update credits and ensure a maximum of 99.
0A15: CD 68 0A    call $0A68                 ; call UPDATE_CREDITS
0A18: 21 02 40    ld   hl,$4002              ; address of NUM_CREDITS 
0A1B: 7E          ld   a,(hl)                ; read number of credits
0A1C: FE 63       cp   $63                   ; compare to 99 (decimal)
0A1E: 38 02       jr   c,$0A22               ; if A < 99 decimal, goto $0A22
0A20: 36 63       ld   (hl),$63              ; otherwise, clamp number of credits to 99 decimal

; if game is *not* in play, show credit available
0A22: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY flag
0A25: 0F          rrca                       ; move flag into carry
0A26: 38 04       jr   c,$0A2C               ; if game is not in play, goto $0A2C
0A28: 11 01 07    ld   de,$0701              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param: 1 = DISPLAY_CREDITS
0A2B: FF          rst  $38                   ; call QUEUE_COMMAND

; This code here doesn't do anything in the game. 
0A2C: 21 03 40    ld   hl,$4003
0A2F: 5E          ld   e,(hl)
0A30: 16 06       ld   d,$06                 ; load DE with #$0600
0A32: 1A          ld   a,(de)                ; A = $45
0A33: 1C          inc  e
0A34: 73          ld   (hl),e
0A35: 23          inc  hl                    ; bump HL to point to $4004 
0A36: 86          add  a,(hl)
0A37: 3D          dec  a
0A38: 77          ld   (hl),a

0A39: 3A B0 40    ld   a,($40B0)              ; read IS_COLUMN_SCROLLING flag
0A3C: 0F          rrca                        ; move flag into carry
0A3D: D0          ret  nc                     ; return if flag not set

; $40B0 is always set to zero so this code is never called.
-- BEGIN UNCALLED CODE BLOCK
0A3E: 2A B1 40    ld   hl,($40B1)
0A41: 7E          ld   a,(hl)
0A42: E6 07       and  $07
0A44: 20 1B       jr   nz,$0A61

0A46: EB          ex   de,hl
0A47: 2A B3 40    ld   hl,($40B3)
0A4A: 7E          ld   a,(hl)
0A4B: FE 3F       cp   $3F
0A4D: 28 11       jr   z,$0A60

0A4F: 23          inc  hl
0A50: 22 B3 40    ld   ($40B3),hl
0A53: D6 30       sub  $30
0A55: 2A B5 40    ld   hl,($40B5)
0A58: 77          ld   (hl),a
0A59: 01 E0 FF    ld   bc,$FFE0
0A5C: 09          add  hl,bc
0A5D: 22 B5 40    ld   ($40B5),hl
0A60: EB          ex   de,hl
0A61: 35          dec  (hl)
0A62: C0          ret  nz

0A63: AF          xor  a
0A64: 32 B0 40    ld   ($40B0),a
0A67: C9          ret
-- END UNCALLED CODE BLOCK


;
;
;
;
;

; B = bits representing status of IPT_COIN1, IPT_COIN2, IPT_SERVICE1

UPDATE_CREDITS:
0A68: 21 02 40    ld   hl,$4002              ; load HL with address of NUM_CREDITS
0A6B: 78          ld   a,b
0A6C: E6 84       and  $84                   ; test if IPT_COIN1 or IPT_SERVICE1 is pressed
0A6E: 28 10       jr   z,$0A80               ; if both not pressed, then it must be IPT_COIN2. Goto IPT_COIN2

; Either IPT_COIN1 or IPT_SERVICE1 is pressed. Award a credit. 
0A70: 34          inc  (hl)                  ; increment NUM_CREDITS

0A71: 3A 00 40    ld   a,($4000)             ; read COINAGE_VALUE
0A74: A7          and  a                     ; test if value is Coinage A 1/1 B 2/1 C 1/1
0A75: C8          ret  z                     ; return if zero  

0A76: 34          inc  (hl)                  ; increment NUM_CREDITS
0A77: 3D          dec  a
0A78: C3 08 1A    jp   $1A08                 ; jumps to a RET Z and a JP $0A7B...                 

0A7B: 34          inc  (hl)                  ; increment NUM_CREDITS
0A7C: 3D          dec  a
0A7D: C8          ret  z

; if we get here, we get FOUR credits for one coin inserted into IPT_COIN1
0A7E: 34          inc  (hl)                  ; increment credits
0A7F: C9          ret



;
; Called when coin(s) are inserted into the IPT_COIN2 slot.  
;

IPT_COIN2:
0A80: 3A 00 40    ld   a,($4000)             ; read COINAGE_VALUE
0A83: 2D          dec  l                     ; bump HL to point to COIN_COUNTER                        
0A84: 34          inc  (hl)                  
0A85: A7          and  a                     ; Test if value is Coinage A 1/1 B 2/1 C 1/1 
0A86: 28 08       jr   z,$0A90               ; if true, goto IPT_COIN2_TWO_COINS_FOR_ONE_CREDIT

0A88: 3D          dec  a                     ; Test if value is Coinage A 1/2 B 1/1 C 1/2 
0A89: 28 0A       jr   z,$0A95               ; if true, goto IPT_COIN2_ONE_COIN_FOR_ONE_CREDIT

0A8B: 3D          dec  a                     ; Test if value is Coinage A 1/3 B 3/1 C 1/3
0A8C: 28 0C       jr   z,$0A9A               ; if true, goto IPT_COIN2_THREE_COINS_FOR_ONE_CREDIT
0A8E: 18 0F       jr   $0A9F                 ; default: goto IPT_COIN2_FOUR_COINS_FOR_ONE_CREDIT


IPT_COIN2_TWO_COINS_FOR_ONE_CREDIT:
0A90: 7E          ld   a,(hl)                ; read COIN_COUNTER
0A91: FE 02       cp   $02                   ; 2 coins inserted?
0A93: 18 0D       jr   $0AA2


IPT_COIN2_ONE_COIN_FOR_ONE_CREDIT:
0A95: 7E          ld   a,(hl)                ; read COIN_COUNTER
0A96: FE 01       cp   $01                   ; 1 coin inserted?
0A98: 18 08       jr   $0AA2

IPT_COIN2_THREE_COINS_FOR_ONE_CREDIT:
0A9A: 7E          ld   a,(hl)                ; read COIN_COUNTER 
0A9B: FE 03       cp   $03                   ; 3 coins inserted?
0A9D: 18 03       jr   $0AA2

IPT_COIN2_FOUR_COINS_FOR_ONE_CREDIT:
0A9F: 7E          ld   a,(hl)                ; read COIN_COUNTER
0AA0: FE 04       cp   $04

; Carry flag set by one of the CP instructions above  
0AA2: D8          ret  c                     ; return if COIN_COUNTER does not match number of coins required for a credit

0AA3: 36 00       ld   (hl),$00              ; reset COIN_COUNTER
0AA5: 2C          inc  l
0AA6: 34          inc  (hl)                  ; increment NUM_CREDITS
0AA7: C9          ret


;
; This is the first script run. It clears the screen, displays scores + high score before switching to ATTRACT_MODE_SCRIPT.   
;

SCRIPT_ONE:
; clear the screen
0AA8: 2A 0B 40    ld   hl,($400B)            ; read TEMP_CHAR_RAM_PTR
0AAB: 06 20       ld   b,$20                 ; number of characters per row
0AAD: 3E 10       ld   a,$10                 ; ordinal of character (space)
0AAF: D7          rst  $10                   ; fill memory
0AB0: 22 0B 40    ld   ($400B),hl            ; update TEMP_CHAR_RAM_PTR
0AB3: 21 08 40    ld   hl,$4008              ; load HL with address of TEMP_COUNTER_4008
0AB6: 35          dec  (hl)                  ; decrement value
0AB7: C0          ret  nz                    ; if counter hasn't hit zero, return
0AB8: 2D          dec  l
0AB9: 2D          dec  l                     ; bump HL to point to IS_GAME_IN_PLAY
0ABA: 36 00       ld   (hl),$00              ; reset flag

; move onto attract mode
0ABC: 2D          dec  l                     ; bump HL to point to SCRIPT_NUMBER
0ABD: 36 01       ld   (hl),$01              ; set script number to ATTRACT_MODE_SCRIPT (zero-based index, remember)
0ABF: AF          xor  a
0AC0: 32 0A 40    ld   ($400A),a             ; set SCRIPT_STAGE

; display scores
0AC3: 21 E9 0A    ld   hl,$0AE9              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0AE9
0AC6: CD D9 0A    call $0AD9                 ; call SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN
0AC9: 11 04 06    ld   de,$0604              ; Command ID: 06 = PRINT_TEXT, Param: 4 = HIGH SCORE
0ACC: FF          rst  $38                   ; call QUEUE_COMMAND
0ACD: 11 00 05    ld   de,$0500              ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param: 0 = Display player one's score
0AD0: FF          rst  $38                   ; call QUEUE_COMMAND
0AD1: 1E 02       ld   e,$02                 ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param: 2 = Display high score
0AD3: FF          rst  $38                   ; call QUEUE_COMMAND
0AD4: AF          xor  a
0AD5: 32 14 45    ld   ($4514),a
0AD8: C9          ret




;
; Set the colour attributes in OBJRAM_BACK_BUF_ATTRIBUTES.
;
; Expects:
; HL = pointer to 32 bytes which define the colour attributes for each character column.
;
SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN:
0AD9: 11 20 40    ld   de,$4020              ; pointer to OBJRAM_BACK_BUF_ATTRIBUTES
0ADC: 06 20       ld   b,$20                 ; we're setting attributes for all 32 columns in the row
0ADE: EB          ex   de,hl                 ; DE now points to 32 byte attribute list, HL = entry in OBJRAM_BACK_BUF_ATTRIBUTES
0ADF: 36 00       ld   (hl),$00              ; reset scroll offset for column in OBJRAM_BACK_BUF_ATTRIBUTES 
0AE1: 2C          inc  l
0AE2: 1A          ld   a,(de)                ; read attribute value from source
0AE3: 77          ld   (hl),a                ; write attribute value to OBJRAM_BACK_BUF_ATTRIBUTES
0AE4: 2C          inc  l                     ; bump HL  
0AE5: 13          inc  de
0AE6: 10 F7       djnz $0ADF                 ; repeat until B==0
0AE8: C9          ret


COLOUR_ATTRIBUTE_TABLE_0AE9:
0AE9:  00 05 00 07 07 01 06 00 00 00 00 00 00 00 00 00  
0AF9:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 06  

COLOUR_ATTRIBUTE_TABLE_0B09:
0B09:  00 05 00 00 01 01 06 03 03 04 04 04 04 00 00 00  
0B19:  02 02 02 00 00 00 04 04 04 04 04 06 06 06 06 06  

COLOUR_ATTRIBUTE_TABLE_0B29:
0B29:  00 05 02 02 02 02 02 06 06 06 06 06 06 06 06 06  
0B39:  04 04 04 04 04 04 04 04 04 04 06 06 00 06 06 06  

COLOUR_ATTRIBUTE_TABLE_0B49:
0B49:  00 05 06 06 06 06 06 02 00 00 00 00 00 00 00 00  
0B59:  00 00 00 00 00 00 00 00 00 00 00 00 00 06 06 06  

COLOUR_ATTRIBUTE_TABLE_0B69:
0B69:  00 05 04 04 04 04 04 02 02 02 02 02 02 06 06 06  
0B79:  06 06 06 07 07 07 07 07 07 07 07 06 06 06 06 06  

COLOUR_ATTRIBUTE_TABLE_0B89:
0B89:  00 05 01 01 01 01 01 01 02 02 03 03 04 04 05 05  
0B99:  06 06 07 07 01 01 02 02 01 01 01 01 01 01 01 06  


;
;
; ATTRACT_MODE_SCRIPT handles the attract mode for the game
;
;

ATTRACT_MODE_SCRIPT:
0BA9: 21 C5 03    ld   hl,$03C5              ; push return address on stack
0BAC: E5          push hl
0BAD: 3A 41 45    ld   a,($4541)             ; read ATTRACT_MODE_SCRIPT_STAGE 
0BB0: EF          rst  $28                   ; call function 

C5 0B             ; $0BC5 (ATTRACT_MODE_INIT)
32 0C             ; $0C32 (DISPLAY_CHALLENGE_MESSAGE)
A5 0C             ; $0CA5 (CLEAR_CHALLENGE_MESSAGE_THEN_DISPLAY_HIGH_SCORES)           
C7 0C             ; $0CC7 (some protection code)
F3 0C             ; $0CF3 (DISPLAY_SPRITES_FOR_SCORE_TABLE)
AE 0D             ; $0DAE (DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE)
D7 0D             ; $0DD7 (ADVANCE_TO_NEXT_ROW_OF_SCORE_TABLE)
F8 0D             ; $0DF8 (CLEAR_SCREEN_AND_HIDE_SPRITES_0DF8)
13 0E             ; $0E13 (INIT_DEMO)
5C 0E             ; $0E5C (DEMO)


; Initialise the attract mode
ATTRACT_MODE_INIT:
0BC5: 3E 01       ld   a,$01
0BC7: 32 04 68    ld   ($6804),a             ; Enable stars
0BCA: 3D          dec  a
0BCB: 32 03 68    ld   ($6803),a             ; set background to black
0BCE: AF          xor  a
0BCF: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG

0BD2: 21 20 40    ld   hl,$4020              ; address of OBJRAM_BACK_BUF
0BD5: 11 21 40    ld   de,$4021
0BD8: 01 7F 00    ld   bc,$007F
0BDB: 36 00       ld   (hl),$00
0BDD: ED B0       ldir                       ; clear OBJRAM_BACK_BUF

0BDF: 21 02 48    ld   hl,$4802              ; address of 3rd character on top row
0BE2: 22 0B 40    ld   ($400B),hl            ; set TEMP_CHAR_RAM_PTR
0BE5: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
0BE8: 36 20       ld   (hl),$20              ; set TEMP_COUNTER_4009
0BEA: 21 41 45    ld   hl,$4541              ; load HL with address of ATTRACT_MODE_SCRIPT_STAGE
0BED: 34          inc  (hl)                  ; advance to next stage of script (DISPLAY_CHALLENGE_MESSAGE @ $0C32)
0BEE: AF          xor  a
0BEF: 32 06 40    ld   ($4006),a             ; reset IS_GAME_IN_PLAY flag

; protection code - if you're not interested in this, skip to $0C25
0BF2: ED 5B B9 40 ld   de,($40B9)            ; load DE with PROTECTION_PORT_PTR_1
0BF6: 2A 9E 40    ld   hl,($409E)
0BF9: 22 BE 40    ld   ($40BE),hl
0BFC: 2C          inc  l
0BFD: ED 53 BB 40 ld   ($40BB),de            ; copy PROTECTION_PORT_PTR_1 to PROTECTION_PORT_PTR_2         

0C01: 3A 8B 0F    ld   a,($0F8B)             ; load A with #$3E (opcode for LD A,)
0C04: 47          ld   b,a
0C05: 47          ld   b,a
0C06: 00          nop
0C07: 47          ld   b,a
0C08: E6 0F       and  $0F
0C0A: 3C          inc  a                     ; A= #$0F
0C0B: 12          ld   (de),a                ; write to protection
0C0C: 67          ld   h,a
0C0D: AF          xor  a                     ; A = 0
0C0E: 12          ld   (de),a                ; write to protection
0C0F: 44          ld   b,h                   ; B = $#0F
0C10: EB          ex   de,hl                 ; HL now is pointer to protection, DE = #$0F01 
0C11: 70          ld   (hl),b                ; write to protection
0C12: 47          ld   b,a                   ; B = 0
0C13: 70          ld   (hl),b                ; write to protection
0C14: 3A 89 0B    ld   a,($0B89)             ; read first entry of COLOUR_ATTRIBUTE_TABLE_0B89 
0C17: C6 04       add  a,$04
0C19: 07          rlca
0C1A: 3C          inc  a                     ; A = 9
0C1B: 77          ld   (hl),a                ; write to protection
0C1C: 7E          ld   a,(hl)                ; read from protection
0C1D: E6 F0       and  $F0                   ; mask in upper nibble
0C1F: 2F          cpl
0C20: E6 F0       and  $F0                   ; if protection is OK, this should set A to 0, and zero flag should be set
0C22: C2 F3 0C    jp   nz,$0CF3              ; if protection check failed, goto DISPLAY_SPRITES_FOR_SCORE_TABLE 
; end protection code

0C25: 06 80       ld   b,$80
0C27: 19          add  hl,de                 ; bump HL to point to $9103 
0C28: 7E          ld   a,(hl)                ; A = $9B

; IX = $4981
0C29: DD CB 01 5E bit  3,(ix+$01)
0C2D: C8          ret  z                     ; happy path - return if protection check succeeded

0C2E: 21 00 01    ld   hl,$0100
0C31: C9          ret


;
;
; Display HOW FAR CAN YOU INVADE OUR SCRAMBLE SYSTEM
;
;

DISPLAY_CHALLENGE_MESSAGE:
; first clear everything on screen except scores
0C32: 2A 0B 40    ld   hl,($400B)            ; load character RAM address from TEMP_CHAR_RAM_PTR
0C35: 06 1E       ld   b,$1E                 ; number of characters to erase
0C37: 3E 10       ld   a,$10                 ; ordinal for empty char
0C39: D7          rst  $10                   ; fill memory
0C3A: 11 02 00    ld   de,$0002              ; offset to add to HL 
0C3D: 19          add  hl,de
0C3E: 22 0B 40    ld   ($400B),hl            ; update TEMP_CHAR_RAM_PTR
0C41: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
0C44: 35          dec  (hl)
0C45: C0          ret  nz

; strange piece of code here. TODO: investigate
0C46: 21 00 41    ld   hl,$4100              ; load HL with address of CURRENT_PLAYER_MISSIONS_COMPLETED 
0C49: 7E          ld   a,(hl)
0C4A: 2C          inc  l
0C4B: 46          ld   b,(hl)
0C4C: 2C          inc  l
0C4D: 4E          ld   c,(hl)
0C4E: 11 40 41    ld   de,$4140              
0C51: 78          ld   a,b
0C52: 12          ld   (de),a
0C53: B1          or   c
0C54: 12          ld   (de),a

; protection code - if you're not interested in this, skip to $0C74
0C55: 3A B9 40    ld   a,($40B9)             ; read PROTECTION_PORT_PTR_1_LO
0C58: 6F          ld   l,a
0C59: ED 5B BA 40 ld   de,($40BA)            
0C5D: 63          ld   h,e                   ; loads HL with address of protection ($8202)  
0C5E: 36 0A       ld   (hl),$0A              ; write to protection 
0C60: 3E 0A       ld   a,$0A
0C62: E6 07       and  $07
0C64: 07          rlca                       ; now A is 4     
0C65: 77          ld   (hl),a                ; write to protection again
0C66: C6 05       add  a,$05                 ; now A is 9.. 
0C68: 77          ld   (hl),a                ; write to protection again  
0C69: 4E          ld   c,(hl)                ; read from protection
0C6A: 79          ld   a,c
0C6B: E6 F0       and  $F0                   ; mask in upper nibble
0C6D: 4F          ld   c,a
0C6E: 3E B0       ld   a,$B0
0C70: B9          cp   c                     ; compare upper nibble to $B0 
0C71: C2 F4 22    jp   nz,$22F4              ; if they don't match, reset system by going to PLAY_GAME
; end protection code

0C74: 11 10 10    ld   de,$1010
0C77: 19          add  hl,de                 ; now HL = $9212
0C78: 7E          ld   a,(hl)                ; ??? no reason why - is $9212 a mirror for a protection port? 
0C79: 21 29 0B    ld   hl,$0B29              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0B29
0C7C: CD D9 0A    call $0AD9                 ; call SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN
0C7F: AF          xor  a
0C80: 32 06 68    ld   ($6806),a             ; disable screen vertical flip
0C83: 32 07 68    ld   ($6807),a             ; disable screen horizontal flip
0C86: 21 41 45    ld   hl,$4541              ; load HL with address of ATTRACT_MODE_SCRIPT_STAGE
0C89: 34          inc  (hl)                  ; advance to next stage of script (CLEAR_CHALLENGE_MESSAGE_THEN_DISPLAY_HIGH_SCORES @ $0CA5)
0C8A: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4540
0C8B: 36 00       ld   (hl),$00              ; set delay before clearing the screen @$0CAC

; Display HOW FAR CAN YOU INVADE OUR SCRAMBLE SYSTEM message
0C8D: 11 01 07    ld   de,$0701              ; command ID:7 = HEAD_UP_DISPLAY_COMMAND, Param: 1 = Display credits
0C90: FF          rst  $38                   ; call QUEUE_COMMAND
0C91: 11 06 06    ld   de,$0606              ; Command ID:6 = PRINT_TEXT, Param: 6   = HOW FAR CAN YOU INVADE
0C94: FF          rst  $38                   ; call QUEUE_COMMAND
0C95: 11 12 06    ld   de,$0612              ; Command ID:6 = PRINT_TEXT, Param: $12 = OUR SCRAMBLE SYSTEM 
0C98: FF          rst  $38                   ; call QUEUE_COMMAND
0C99: 11 11 06    ld   de,$0611              ; Command ID:6 = PRINT_TEXT, Param: $11 = (C) KONAMI  1981 
0C9C: FF          rst  $38                   ; call QUEUE_COMMAND
0C9D: 11 0B 06    ld   de,$060B              ; Command ID:6 = PRINT_TEXT, Param: $0B = PLAY
0CA0: FF          rst  $38                   ; call QUEUE_COMMAND
0CA1: 1E 0C       ld   e,$0C                 ; Command ID:6 = PRINT_TEXT, Param: $0C = - SCRAMBLE - 
0CA3: FF          rst  $38                   ; call QUEUE_COMMAND
0CA4: C9          ret



CLEAR_CHALLENGE_MESSAGE_THEN_DISPLAY_HIGH_SCORES:
0CA5: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0CA8: 35          dec  (hl)
0CA9: C0          ret  nz                    ; wait until counter reaches zero
0CAA: 2C          inc  l                     ; bump HL to point to ATTRACT_MODE_SCRIPT_STAGE
0CAB: 34          inc  (hl)                  ; advance to next stage of script (which is some protection code - skip to DISPLAY_SPRITES_FOR_SCORE_TABLE @$0CF3)

; Remove "HOW FAR CAN YOU INVADE OUR SCRAMBLE SYSTEM" from the screen
0CAC: 21 69 0B    ld   hl,$0B69              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0B69 
0CAF: CD D9 0A    call $0AD9                 ; call SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN
0CB2: 11 86 06    ld   de,$0686              ; Command ID: PRINT_TEXT, Param: $86 = clears HOW FAR CAN YOU INVADE
0CB5: FF          rst  $38                   ; call QUEUE_COMMAND 
0CB6: 11 92 06    ld   de,$0692              ; Command ID: PRINT_TEXT, Param: $92 = clears OUR SCRAMBLE SYSTEM 
0CB9: FF          rst  $38                   ; call QUEUE_COMMAND
0CBA: 11 8B 06    ld   de,$068B              ; Command ID: PRINT_TEXT, Param: $8B = clears PLAY
0CBD: FF          rst  $38                   ; call QUEUE_COMMAND
0CBE: 11 8C 06    ld   de,$068C              ; Command ID: PRINT_TEXT, Param: $8C = clears SCRAMBLE
0CC1: FF          rst  $38                   ; call QUEUE_COMMAND

; now display high scores
0CC2: 11 00 02    ld   de,$0200              ; Command ID: DISPLAY_HIGH_SCORES_COMMAND
0CC5: FF          rst  $38                   ; call QUEUE_COMMAND
0CC6: C9          ret



;
; Some protection code I can't put a label to 
;

0CC7: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0CCA: 35          dec  (hl)      
0CCB: C0          ret  nz                    ; wait until counter reaches zero 
0CCC: 21 02 48    ld   hl,$4802              ; load HL with address of 3rd character, top row, in character RAM
0CCF: 22 0B 40    ld   ($400B),hl            ; save to TEMP_CHAR_RAM_PTR   
0CD2: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
0CD5: 36 20       ld   (hl),$20              ; set counter 
0CD7: 21 41 45    ld   hl,$4541              ; load HL with address of ATTRACT_MODE_SCRIPT_STAGE
0CDA: 34          inc  (hl)                  ; advance to next stage of script (DISPLAY_SPRITES_FOR_SCORE_TABLE @ $0CF3)

;protection code - if not interested, skip rest of this function
0CDB: 3E 80       ld   a,$80
0CDD: C6 02       add  a,$02
0CDF: 2E 02       ld   l,$02
0CE1: 67          ld   h,a                   ; set HL to point to $8202, protection 
0CE2: 36 03       ld   (hl),$03              ; write to protection 
0CE4: 7D          ld   a,l
0CE5: 3D          dec  a                     ; set A to 1
0CE6: 77          ld   (hl),a                ; write to protection
0CE7: C6 08       add  a,$08                 ; set A to 9
0CE9: 77          ld   (hl),a                ; write to protection
0CEA: 46          ld   b,(hl)                ; read from protection
0CEB: 78          ld   a,b
0CEC: E6 F0       and  $F0                   ; mask in upper nibble
0CEE: FE 40       cp   $40                   
0CF0: 20 D5       jr   nz,$0CC7              ; if protection check failed, goto $0CC7
0CF2: C9          ret



; 
; Displays all enemy types (as sprites) on the - SCORE TABLE - attract mode screen. 
; The associated points values are drawn by DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE @ $0DAE
;

DISPLAY_SPRITES_FOR_SCORE_TABLE:
; clear character RAM so sprites can be shown clearly on black background 
0CF3: 2A 0B 40    ld   hl,($400B)            ; load HL from TEMP_CHAR_RAM_PTR
0CF6: 06 1A       ld   b,$1A                 ; count #$1A (26)
0CF8: 3E 10       ld   a,$10                 ; ordinal for empty space character
0CFA: D7          rst  $10                   ; plot 26 empty space characters
0CFB: 11 06 00    ld   de,$0006              ; each row is 32 characters wide and we've done 26. So we add 6 .. 
0CFE: 19          add  hl,de                 ; .. to get HL to point to starting character on next row down
0CFF: 22 0B 40    ld   ($400B),hl            ; update TEMP_CHAR_RAM_PTR
0D02: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
0D05: 35          dec  (hl)
0D06: C0          ret  nz

; set the colour palette
0D07: 21 49 0B    ld   hl,$0B49              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0B49
0D0A: CD D9 0A    call $0AD9                 ; call SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN

; display the - SCORE TABLE - heading
0D0D: 11 0D 06    ld   de,$060D              ; Command ID: 6 = PRINT_TEXT, Param:$0D = -SCORE TABLE-
0D10: FF          rst  $38                   ; call QUEUE_COMMAND

; position the sprites for the enemy types
0D11: 21 54 0D    ld   hl,$0D54              ; load HL with address of SCORE_TABLE_SPRITES
0D14: 11 60 40    ld   de,$4060              ; load DE with address of OBJRAM_BACK_BUF_SPRITES
0D17: 01 18 00    ld   bc,$0018               
0D1A: ED B0       ldir                       ; set up all sprites in one go
0D1C: 21 6C 0D    ld   hl,$0D6C              ; load HL with address of SCORE_TABLE_TEXT
0D1F: 22 44 45    ld   ($4544),hl
0D22: 21 4A 4A    ld   hl,$4A4A              ; address in character RAM
0D25: 22 46 45    ld   ($4546),hl

; protection code - if you're not interested in this, skip to $0D46
0D28: ED 5B B9 40 ld   de,($40B9)            ; read PROTECTION_PORT_PTR_1         
0D2C: 3E 0A       ld   a,$0A
0D2E: 47          ld   b,a
0D2F: 0F          rrca
0D30: 12          ld   (de),a                ; write to protection 
0D31: EB          ex   de,hl
0D32: 36 0C       ld   (hl),$0C              ; write to protection 
0D34: 36 09       ld   (hl),$09              ; write to protection 
0D36: 7E          ld   a,(hl)                ; read from protection
0D37: E6 F0       and  $F0                   ; mask in upper nibble
0D39: 0F          rrca
0D3A: FE 30       cp   $30
0D3C: C2 14 41    jp   nz,$4114              ; jump to somewhere in RAM where there's no code!

; This code doesn't appear to do anything. My guess is that this code exists to slow down "people" (pirates) looking through the code,
; by making them waste time to see if the registers/ flags (carry & zero) were needed elsewhere in any logic.
0D3F: 47          ld   b,a
0D40: 48          ld   c,b
0D41: 6F          ld   l,a
0D42: 59          ld   e,c
0D43: 07          rlca
0D44: 07          rlca
0D45: 57          ld   d,a
; end protection code

0D46: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0D49: 36 32       ld   (hl),$32
0D4B: 2C          inc  l                     ; bump HL to point to ATTRACT_MODE_SCRIPT_STAGE
0D4C: 34          inc  (hl)                  ; advance to next stage of script (DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE)

; set fields required for DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE routine
0D4D: 2C          inc  l                     ; bump HL to point to SCORE_TABLE_CHARS_COUNTER
0D4E: 36 0B       ld   (hl),$0B              ; 11 characters per line
0D50: 2C          inc  l                     ; bump HL to point to SCORE_TABLE_ROWS_COUNTER
0D51: 36 06       ld   (hl),$06              ; 6 lines
0D53: C9          ret


SCORE_TABLE_SPRITES:
0D54:  50 1C 00 4A 50 1E 00 62 50 1A 06 7B 50 10 04 92  
0D64:  50 26 05 A9 50 33 01 C2                  

SCORE_TABLE_TEXT:
; ...  50 PTS               
0D6C:  0C 0C 0C 10 10 05 00 10 20 24 23 
; ...  80 PTS          
0D77:  0C 0C 0C 10 10 08 00 10 20 24 23 
; ... 100 PTS
0D82:  0C 0C 0C 10 01 00 00 10 20 24 23 
; ... 150 PTS
0D8D:  0C 0C 0C 10 01 05 00 10 20 24 23 
; ... 800 PTS
0D98:  0C 0C 0C 10 08 00 00 10 20 24 23 
; ... MYSTERY
0DA3:  0C 0C 0C 10 1D 29 23 24 15 22 29 





;
; Displays the points value for an enemy on - SCORE TABLE - screen. 
;
; This code basically draws a hard-coded text string sourced from SCORE_TABLE_TEXT above,
; with a delay between each character drawn.
;

DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE:
; Has 
0DAE: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0DB1: 35          dec  (hl)                  ; decrement counter 
0DB2: C0          ret  nz                    ; return if its not 
0DB3: 36 05       ld   (hl),$05

; get character from SCORE_TABLE_TEXT 
0DB5: 2A 44 45    ld   hl,($4544)            ; load HL with contents of SCORE_TABLE_TEXT_PTR
0DB8: 7E          ld   a,(hl)                ; read character to plot
0DB9: 23          inc  hl
0DBA: 22 44 45    ld   ($4544),hl            ; update SCORE_TABLE_TEXT_PTR

; plot ordinal in A to character RAM
0DBD: 2A 46 45    ld   hl,($4546)            ; load HL with contents of SCORE_TABLE_CHAR_PTR to get pointer to character RAM
0DC0: 77          ld   (hl),a                ; plot character
0DC1: 11 E0 FF    ld   de,$FFE0              ; load DE with -32 decimal
0DC4: 19          add  hl,de                 ; bump HL to point to character above
0DC5: 22 46 45    ld   ($4546),hl            ; set SCORE_TABLE_CHAR_PTR pointer

; count how many characters left to print 
0DC8: 21 42 45    ld   hl,$4542              ; load HL with address of SCORE_TABLE_CHARS_COUNTER
0DCB: 35          dec  (hl)                  ; decrement number of characters left to print
0DCC: C0          ret  nz                    ; return if we've not done them all yet

; we've printed all 11 characters
0DCD: 36 0B       ld   (hl),$0B              ; reset value of SCORE_TABLE_CHARS_COUNTER to 11.
0DCF: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0DD2: 36 14       ld   (hl),$14              ; delay before plotting next row
0DD4: 2C          inc  l                     ; bump HL to point to to ATTRACT_MODE_SCRIPT_STAGE 
0DD5: 34          inc  (hl)                  ; advance to next stage of script (ADVANCE_TO_NEXT_ROW_OF_SCORE_TABLE @ $0DD7)
0DD6: C9          ret



; bump SCORE_TABLE_CHAR_PTR to point to the next row on the - SCORE TABLE - screen  in preparation for printing enemy points values.

ADVANCE_TO_NEXT_ROW_OF_SCORE_TABLE:
0DD7: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0DDA: 35          dec  (hl)                  ; decrement countdown
0DDB: C0          ret  nz                    ; wait until counter reaches zero
0DDC: 36 01       ld   (hl),$01              ; reset countdown value    
0DDE: 2C          inc  l                     ; bump HL to point to ATTRACT_MODE_SCRIPT_STAGE
0DDF: 35          dec  (hl)                  ; set script stage to DISPLAY_ROW_OF_POINTS_VALUES_FOR_SCORE_TABLE

; calculate character RAM address where next line of score table should be drawn
0DE0: 2A 46 45    ld   hl,($4546)            ; get character RAM address from SCORE_TABLE_CHAR_PTR
0DE3: 11 63 01    ld   de,$0163
0DE6: 19          add  hl,de
0DE7: 22 46 45    ld   ($4546),hl            ; update SCORE_TABLE_CHAR_PTR with new address

; how many rows of the score table do we have left to do? 
0DEA: 21 43 45    ld   hl,$4543              ; load HL with address of SCORE_TABLE_ROWS_COUNTER
0DED: 35          dec  (hl)                  ; decrement counter
0DEE: C0          ret  nz                    ; exit if counter hasn't hit zero

; we've done all of the rows of the score table
0DEF: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0DF2: 36 96       ld   (hl),$96              ; set delay before 
0DF4: 2C          inc  l                     ; bump HL to point to ATTRACT_MODE_SCRIPT_STAGE
0DF5: 34          inc  (hl)
0DF6: 34          inc  (hl)                  ; set script stage to be CLEAR_SCREEN_AND_HIDE_SPRITES_0DF8
0DF7: C9          ret


;
;
;
;
;

CLEAR_SCREEN_AND_HIDE_SPRITES_0DF8:
0DF8: 21 40 45    ld   hl,$4540              ; load HL with address of TEMP_COUNTER_4540
0DFB: 35          dec  (hl)              
0DFC: C0          ret  nz                    ; wait until counter reaches zero
0DFD: 2C          inc  l                     ; bump HL to point to ATTRACT_MODE_SCRIPT_STAGE
0DFE: 34          inc  (hl)                  ; increment ATTRACT_MODE_SCRIPT_STAGE

0DFF: 21 60 40    ld   hl,$4060              ; load HL with address of OBJRAM_BACK_BUF_SPRITES
0E02: 3E 10       ld   a,$10
0E04: 06 18       ld   b,$18
0E06: D7          rst  $10                   ; remove all sprites from screen
0E07: CD 62 11    call $1162                 ; call CLEAR_SCREEN_EXCEPT_SCORES_AND_CREDIT 
0E0A: CD 83 11    call $1183                 ; call CLEAR_ARRAYS_AND_SPRITES
0E0D: 21 E9 0A    ld   hl,$0AE9              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0AE9
0E10: C3 D9 0A    jp   $0AD9                 ; jump to SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN


;
; Prepare for the demo of the player jet flying over the landscape.
;
;
;

INIT_DEMO:
0E13: 21 41 45    ld   hl,$4541              ; load HL with address of ATTRACT_MODE_SCRIPT_STAGE 
0E16: 34          inc  (hl)                  ; advance to next stage of script (DEMO @ $0E5C)

; reset landscape
0E17: CD C3 0F    call $0FC3                 ; call RESET_LANDSCAPE_EXTENTS
0E1A: CD A1 10    call $10A1                 ; call DRAW_FLAT_STRIP_OF_LAND 
0E1D: 3E 01       ld   a,$01
0E1F: 32 19 40    ld   ($4019),a             ; set DRAW_LANDSCAPE_FLAG

; activate player jet for demo
0E22: 21 01 00    ld   hl,$0001
0E25: 22 80 43    ld   ($4380),hl            ; set PLAYERS[0].IsActive to 1, and PLAYERS[0].IsExploding to 0
0E28: 22 A0 43    ld   ($43A0),hl            ; set PLAYERS[1].IsActive to 1, and PLAYERS[1].IsExploding to 0
0E2B: AF          xor  a
0E2C: 32 82 43    ld   ($4382),a             ; set PLAYERS[0].StageOfLife to 0 (see PLAYER_INIT @ $16FE)

; clear player related game state
0E2F: 21 00 41    ld   hl,$4100
0E32: 06 40       ld   b,$40
0E34: D7          rst  $10                   ; clear player related game state

; set level 1 to be the landscape for the demo mode
0E35: 21 D0 29    ld   hl,$29D0              ; load HL with address of LANDSCAPE_LAYOUT_METADATA_TABLE table
0E38: 11 18 41    ld   de,$4118              ; load DE with address of LANDSCAPE_LAYOUT_PTR
0E3B: 7E          ld   a,(hl)                ; read LSB of landscape pointer
0E3C: 12          ld   (de),a                ; set LSB of LANDSCAPE_LAYOUT_PTR
0E3D: 23          inc  hl
0E3E: 13          inc  de
0E3F: 7E          ld   a,(hl)                ; read MSB of landscape pointer
0E40: 12          ld   (de),a                ; set MSB of LANDSCAPE_LAYOUT_PTR
0E41: 23          inc  hl
0E42: 7E          ld   a,(hl)                
0E43: 32 1D 41    ld   ($411D),a             ; set LANDSCAPE_FLAGS

; display fuel remaining bar
0E46: 11 02 07    ld   de,$0702              ; Command ID: 07 = HEAD_UP_DISPLAY_COMMAND, Param: 2 = DISPLAY_CURRENT_PLAYER_PROGRESS_BAR
0E49: FF          rst  $38                   ; call QUEUE_COMMAND
0E4A: 3E 20       ld   a,$20
0E4C: 32 15 41    ld   ($4115),a             ; set LANDSCAPE_SCROLL_CONTROL_COUNTER
0E4F: 21 05 41    ld   hl,$4105              ; load HL with address of CURRENT_PLAYER_FUEL
0E52: 36 FF       ld   (hl),$FF              ; give player a full tank
0E54: 2C          inc  l                     ; bump HL to point to CURRENT_PLAYER_FUEL_DRAIN_COUNTER
0E55: 36 05       ld   (hl),$05              ; set fuel drain counter.
0E57: 11 07 06    ld   de,$0607              ; Command ID: 06 = PRINT_TEXT, Param: 7 = FUEL
0E5A: FF          rst  $38                   ; call QUEUE_COMMAND
0E5B: C9          ret


;
; Handle the rocket flying over the landscape in demo mode.
;
;

DEMO:
0E5C: CD CC 13    call $13CC                 ; call ANIMATION_AND_MOVEMENT
0E5F: CD 35 1F    call $1F35                 ; call SCROLL_AND_SPRITES
0E62: CD 36 20    call $2036                 ; call COLLISION_DETECTION
0E65: CD 63 25    call $2563                 ; call SPAWN_ENEMIES
0E68: CD C2 27    call $27C2                 ; call LANDSCAPE_CHANGE

; wait until the player jet's destroyed in the demo
0E6B: 21 80 43    ld   hl,$4380              ; load HL with address of PLAYERS[0].IsActive flag
0E6E: 7E          ld   a,(hl)                ; read flag
0E6F: 2C          inc  l                     ; bump HL to point to PLAYERS[0].IsExploding flag
0E70: B6          or   (hl)                  ; OR with that flag
0E71: 0F          rrca                       ; move result into carry
0E72: D8          ret  c                     ; return if player is active or is dying

; when jet is destroyed, go back to title page  
0E73: 21 41 45    ld   hl,$4541              ; load HL with address of ATTRACT_MODE_SCRIPT_STAGE
0E76: 36 00       ld   (hl),$00              ; set stage to 0
0E78: C9          ret



ADVANCE_TO_NEXT_SCRIPT_IF_ZERO_FLAG_UNSET:
0E79: C8          ret  z
0E7A: 21 05 40    ld   hl,$4005              ; load HL with address of SCRIPT_NUMBER
0E7D: 34          inc  (hl)                  ; advance to next script  
0E7E: AF          xor  a
0E7F: 32 0A 40    ld   ($400A),a             ; reset SCRIPT_STAGE to start of script
0E82: C9          ret



;
;
; This script handles the case where credit is inserted and the player must press 1P START or 2P START
;
;

CREDIT_INSERTED_SCRIPT:
0E83: 21 3B 0F    ld   hl,$0F3B              ; address of CHECK_IF_1P_START_OR_2P_START_PRESSED
0E86: E5          push hl                    ; push address on the stack. This method will be called after each script below.
0E87: 3A 0A 40    ld   a,($400A)             ; read SCRIPT_STAGE
0E8A: EF          rst  $28

0E8B:
    91 0E             ; $0E91 (PUSH_START_INIT)
    E7 0E             ; $0EE7 (DISPLAY_PUSH_START_BUTTON)
    2D 0F             ; $0F2D (DISPLAY_NUMBER_OF_PLAYERS_ALLOWED)


PUSH_START_INIT:
; Protection code. If you're not interested in this, skip to $0EB9.
0E91: 53          ld   d,e
0E92: 53          ld   d,e
0E93: 4A          ld   c,d
0E94: 53          ld   d,e
0E95: AF          xor  a
0E96: 53          ld   d,e
0E97: 53          ld   d,e
0E98: 26 02       ld   h,$02
0E9A: 5A          ld   e,d
0E9B: 59          ld   e,c                  ; referenced by $24D1 as part of protection algorithm   
0E9C: 2E 79       ld   l,$79
0E9E: 59          ld   e,c
0E9F: 06 0A       ld   b,$0A
0EA1: 86          add  a,(hl)
0EA2: 59          ld   e,c
0EA3: 1E 05       ld   e,$05
0EA5: 1E 05       ld   e,$05
0EA7: 5A          ld   e,d
0EA8: 23          inc  hl
0EA9: 5A          ld   e,d
0EAA: 5A          ld   e,d
0EAB: 10 F4       djnz $0EA1

0EAD: 1E 09       ld   e,$09
0EAF: 5A          ld   e,d
0EB0: FE 1F       cp   $1F
0EB2: 4B          ld   c,e
0EB3: 4B          ld   c,e

; HL should be $0283 when we get here, and zero flag should be set.
; If the zero flag is not set, the game will reset.
0EB4: 4E          ld   c,(hl)
0EB5: C2 2D F1    jp   nz,$F12D              ; reset the game.
0EB8: 53          ld   d,e
; End of protection code

0EB9: AF          xor  a
0EBA: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG
0EBD: 3E 01       ld   a,$01
0EBF: 32 04 68    ld   ($6804),a             ; enable stars
0EC2: 3D          dec  a                     ; set A to 0
0EC3: 32 03 68    ld   ($6803),a             ; set background to black
0EC6: 21 09 0B    ld   hl,$0B09              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0B09 
0EC9: CD D9 0A    call $0AD9                 ; call SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN
0ECC: 21 60 40    ld   hl,$4060              ; load HL with address of OBJRAM_BACK_BUF_SPRITES
0ECF: 06 40       ld   b,$40
0ED1: AF          xor  a
0ED2: D7          rst  $10                   ; hides all sprites     
0ED3: 32 B0 40    ld   ($40B0),a             ; reset unused IS_COLUMN_SCROLLING flag
0ED6: 32 06 40    ld   ($4006),a             ; reset IS_GAME_IN_PLAY flag
d0ED9: 21 02 48    ld   hl,$4802             ; character RAM address
0EDC: 22 0B 40    ld   ($400B),hl            ; set TEMP_CHAR_RAM_PTR
0EDF: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
0EE2: 36 10       ld   (hl),$10
0EE4: 2C          inc  l                     ; bump HL to point to SCRIPT_STAGE
0EE5: 34          inc  (hl)                  ; advance to next stage of script (DISPLAY_PUSH_START_BUTTON below)
0EE6: C9          ret


;
; Displays PUSH START BUTTON and BONUS JET FOR messages on screen.
;
;
;

DISPLAY_PUSH_START_BUTTON:
; First lets clear the screen two rows of characters at a time. 
; As the screen is rotated it looks like 2 columns are being cleared.
0EE7: 2A 0B 40    ld   hl,($400B)            ; read TEMP_CHAR_RAM_PTR
0EEA: 06 1D       ld   b,$1D
0EEC: 3E 10       ld   a,$10
0EEE: D7          rst  $10                   ; plot 29 empty characters
0EEF: 11 03 00    ld   de,$0003              ; 
0EF2: 19          add  hl,de                 ; bump HL to next row of characters
0EF3: 06 1D       ld   b,$1D
0EF5: D7          rst  $10                   ; plot another 29 empty characters
0EF6: 19          add  hl,de                
0EF7: 22 0B 40    ld   ($400B),hl            ; update TEMP_CHAR_RAM_PTR
0EFA: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
0EFD: 35          dec  (hl)
0EFE: C0          ret  nz

; now display PUSH START BUTTON and BONUS JET FOR _____ PTS
0EFF: 2C          inc  l                     ; bump HL to point to SCRIPT_STAGE
0F00: 34          inc  (hl)                  ; advance to next stage of script (DISPLAY_NUMBER_OF_PLAYERS_ALLOWED @ $0F2D)
0F01: AF          xor  a
0F02: 32 06 68    ld   ($6806),a             ; disable screen vertical flip
0F05: 32 07 68    ld   ($6807),a             ; disable screen horizontal flip
0F08: 32 0D 40    ld   ($400D),a             ; set CURRENT_PLAYER
0F0B: 11 01 07    ld   de,$0701              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:1 = DISPLAY_CREDITS
0F0E: FF          rst  $38                   ; call QUEUE_COMMAND
0F0F: 11 01 06    ld   de,$0601              ; Command ID: 6 = PRINT_TEXT, Param:1 = PUSH START BUTTON
0F12: FF          rst  $38                   ; call QUEUE_COMMAND
0F13: 1E 16       ld   e,$16                 ; Command ID: 6 = PRINT_TEXT, Param:$16 = BONUS JET   FOR
0F15: FF          rst  $38                   ; call QUEUE_COMMAND
0F16: 1C          inc  e                     ; Command ID: 6 = PRINT_TEXT, Param:$17 = 000 PTS
0F17: FF          rst  $38                   ; call QUEUE_COMMAND

; Poke 2 digit BCD value into BONUS JET FOR nn000 PTS message on screen
0F18: 3A 17 40    ld   a,($4017)             ; read BONUS_JET_FOR BCD value
0F1B: 47          ld   b,a                   ; preserve A in B
0F1C: E6 0F       and  $0F                   ; mask in lower nibble (2nd digit)
0F1E: 32 78 49    ld   ($4978),a             ; write digit to character RAM
0F21: 78          ld   a,b                   ; restore A from B
0F22: E6 F0       and  $F0                   ; mask in upper nibble (1st digit)
0F24: C8          ret  z                     ; if it's zero, don't draw it
0F25: 0F          rrca                       ; move upper nibble...
0F26: 0F          rrca
0F27: 0F          rrca
0F28: 0F          rrca                       ; ... to lower nibble. 
0F29: 32 98 49    ld   ($4998),a             ; write digit to character RAM
0F2C: C9          ret


;
; Read number of credits. 
; If credits available is zero, exit. 
; If only 1 credit, display ONE PLAYER ONLY 
; Else display ONE OR TWO PLAYERS
; 

DISPLAY_NUMBER_OF_PLAYERS_ALLOWED:
0F2D: 3A 02 40    ld   a,($4002)             ; read NUM_CREDITS
0F30: A7          and  a                     ; test if we have any credits
0F31: C8          ret  z                     ; return if no credits
0F32: 3D          dec  a                     ; decrement credit count. If we only have 1 credit, zero flag will now be set.
0F33: 11 18 06    ld   de,$0618              ; Command ID: 6 = PRINT_TEXT, Param:$18 = ONE PLAYER ONLY
0F36: 28 01       jr   z,$0F39               ; if zero flag set, we only have 1 credit, so can only have one player game, goto $0F39
0F38: 1C          inc  e                     ; bump param to display ONE OR TWO PLAYERS
0F39: FF          rst  $38                   ; call QUEUE_COMMAND
0F3A: C9          ret



;
; Check if the player has pushed the 1 Player or 2 Player start buttons.  
;
;

CHECK_IF_1P_START_OR_2P_START_PRESSED:
0F3B: 3A 11 40    ld   a,($4011)             ; read PORT_STATE_8101
0F3E: CB 7F       bit  7,a                   ; test if 1P START button is pressed
0F40: C2 7B 0F    jp   nz,$0F7B              ; if button pressed, goto $0F7B
0F43: CB 77       bit  6,a                   ; test if 2P START button is pressed
0F45: C8          ret  z                     ; return if 2P START button is not pressed

; Called when 2P START button is pressed
0F46: 3A 02 40    ld   a,($4002)             ; read NUM_CREDITS
0F49: FE 02       cp   $02                   ; have we at least 2 credits for a 2 player game?
0F4B: D8          ret  c                     ; return if <2 
0F4C: D6 02       sub  $02                   ; deduct 2 credits from available credit
0F4E: 32 02 40    ld   ($4002),a             ; update NUM_CREDITS
0F51: 21 00 01    ld   hl,$0100              ; will set CURRENT_PLAYER to 0 and IS_TWO_PLAYER_GAME flag to 1

START_GAME:
0F54: 22 0D 40    ld   ($400D),hl            ; write to CURRENT_PLAYER and IS_TWO_PLAYER_GAME flag 
0F57: AF          xor  a
0F58: 32 0A 40    ld   ($400A),a             ; set SCRIPT_STAGE to 0
0F5B: 3E 03       ld   a,$03
0F5D: 32 05 40    ld   ($4005),a             ; set SCRIPT_NUMBER to 3 
0F60: 3E 01       ld   a,$01
0F62: 32 06 40    ld   ($4006),a             ; set IS_GAME_IN_PLAY flag
0F65: 11 04 06    ld   de,$0604              ; Command ID: 6 = PRINT_TEXT, Param:4 = HIGH SCORE
0F68: FF          rst  $38                   ; call QUEUE_COMMAND
0F69: CD 91 0F    call $0F91
0F6C: CD 13 29    call $2913                 ; call QUEUE_GAME_START_MUSIC
0F6F: 11 00 04    ld   de,$0400              ; Command ID: 4 = ZERO_SCORE_COMMAND, Param:0 = Zero player 1's score
0F72: FF          rst  $38                   ; call QUEUE_COMMAND
0F73: 3A 0E 40    ld   a,($400E)             ; read IS_TWO_PLAYER_GAME flag
0F76: 0F          rrca                       ; move flag into carry
0F77: D0          ret  nc                    ; return if its not a 2 player game 
0F78: 1C          inc  e                     ; Command ID: 4 = ZERO_SCORE_COMMAND, Param:1 = Zero player 2's score
0F79: FF          rst  $38                   ; call QUEUE_COMMAND
0F7A: C9          ret

; Called when 1P START button is pressed
0F7B: 3A 02 40    ld   a,($4002)             ; read NUM_CREDITS
0F7E: A7          and  a                     ; test if any credits have been inserted
0F7F: 28 0A       jr   z,$0F8B               ; if no 
0F81: 3D          dec  a
0F82: 32 02 40    ld   ($4002),a             ; update NUM_CREDITS  
0F85: 21 00 00    ld   hl,$0000              ; will set CURRENT_PLAYER to 0 and IS_TWO_PLAYER_GAME flag to 0
0F88: C3 54 0F    jp   $0F54                 ; jump to START_GAME 

0F8B: 3E 01       ld   a,$01
0F8D: 32 05 40    ld   ($4005),a             ; set SCRIPT_NUMBER to 1
0F90: C9          ret



;
;
;
;
;

0F91: AF          xor  a
; clear player state and landscape state from 4100-41ff
0F92: 21 00 41    ld   hl,$4100               
0F95: 47          ld   b,a
0F96: D7          rst  $10                   ; 

; clear landscape related flags
0F97: 21 30 42    ld   hl,$4230              
0F9A: 06 10       ld   b,$10
0F9C: D7          rst  $10                   ; clear landscape related flags 

; hide all sprites
0F9D: 21 60 40    ld   hl,$4060              ; load HL with address of OBJRAM_BACK_BUF_SPRITES
0FA0: 06 40       ld   b,$40
0FA2: D7          rst  $10                   ; hide all sprites

0FA3: 21 60 42    ld   hl,$4260              ; load HL with address of CHAR_BASED_GROUND_OBJECTS array
0FA6: 01 02 B0    ld   bc,$B002
0FA9: DF          rst  $18                   ; fill memory   

0FAA: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG

; zero any state held for both players  
0FAD: 21 00 41    ld   hl,$4100              ; load HL with address of CURRENT_PLAYER_STATE
0FB0: 11 01 41    ld   de,$4101               
0FB3: 01 C0 00    ld   bc,$00C0
0FB6: 36 00       ld   (hl),$00
0FB8: ED B0       ldir                       ; clear all player state

0FBA: 3A 07 40    ld   a,($4007)             ; read DEFAULT_PLAYER_LIVES
0FBD: 32 48 41    ld   ($4148),a             ; set PLAYER_ONE_LIVES
0FC0: 32 88 41    ld   ($4188),a             ; set PLAYER_TWO_LIVES



;
; Reset the LANDSCAPE_EXTENTS to default values.  
;

RESET_LANDSCAPE_EXTENTS:
0FC3: 21 C0 41    ld   hl,$41C0              ; load HL with address of LANDSCAPE_EXTENTS              
0FC6: 11 28 C9    ld   de,$C928              ; D = #$C9 (ground), E = $28 (ceiling)
0FC9: 06 20       ld   b,$20                 ; 32 rows to do
0FCB: 72          ld   (hl),d                ; set LANDSCAPE_EXTENT.GroundX
0FCC: 2C          inc  l
0FCD: 73          ld   (hl),e                ; set LANDSCAPE_EXTENT.CeilingX    
0FCE: 2C          inc  l
0FCF: 10 FA       djnz $0FCB                 ; repeat until all rows done
0FD1: C9          ret


;
;
; This script handles PLAYER ONE's game.
;
;

PLAYER_ONE_GAME_SCRIPT:
0FD2: 3A 0A 40    ld   a,($400A)             ; read SCRIPT_STAGE
0FD5: EF          rst  $28

0FD6:   
    02 10 
    18 1A         ; $1A18: CLEAR_SCREEN_1A18        
    56 03         ; $0356: DISPLAY_HUD_FOR_PLAYER_ONE 
    7E 10         ; $107E: REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE
    BA 10         ; $10BA: GAME_INIT
    F4 22         ; $22F4: PLAY_GAME
    1D 11         ; $111D: PLAYER_ONE_KILLED      
    AB 11         ; $11AB: CHECK_IF_SHOULD_SWITCH_TO_PLAYER_TWO 
    7E 12         ; $127E: MISSION_COMPLETED_SCRIPT
    F0 12         ; $12F0: HIGH_SCORE_SCRIPT             


;
;
; This script handles PLAYER TWO's game.
;
;

PLAYER_TWO_GAME_SCRIPT:
0FEA: 3A 0A 40    ld   a,($400A)
0FED: EF          rst  $28

0FEE: 
    02 10 
    18 1A        ; $1A18: CLEAR_SCREEN_1A18
    39 10        ; $1039: DISPLAY_HUD_FOR_PLAYER_TWO
    7E 10        ; $107E: REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE
    BA 10        ; $10BA: GAME_INIT
    F4 22        ; $22F4: PLAY_GAME
    09 12        ; $1209: PLAYER_TWO_KILLED
    3F 12        ; $123F: CHECK_IF_SHOULD_SWITCH_TO_PLAYER_ONE  
    7E 12        ; $127E: MISSION_COMPLETED_SCRIPT  
    F0 12        ; $12F0: HIGH_SCORE_SCRIPT    



;
;
;
;

; I don't know what this code is for but I'm sure its redundant. I suspect it was a part of some
; protection scheme that was removed before production. Skip to $1017.

; Begin redundant code
1002: 21 30 41    ld   hl,$4130              ; load HL with address of NO_APPARENT_PURPOSE_4130
1005: 11 70 41    ld   de,$4170              ; load DE with address of NO_APPARENT_PURPOSE_4170 
1008: 01 08 00    ld   bc,$0008
100B: ED B0       ldir                       ; copy 8 bytes

100D: 7E          ld   a,(hl)                ; HL = $4138   
100E: B1          or   c
100F: 12          ld   (de),a
1010: 2C          inc  l
1011: 14          inc  d
1012: 7E          ld   a,(hl)
1013: 4F          ld   c,a
1014: 1A          ld   a,(de)
1015: B0          or   b
1016: 12          ld   (de),a                ; write 0 to $4278 - for no reason whatsoever.
; End redundant code

1017: AF          xor  a
1018: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG
101B: 21 60 40    ld   hl,$4060              ; load HL with address of OBJRAM_BACK_BUF_SPRITES
101E: 06 40       ld   b,$40                 ; sizeof(OBJRAM_BACK_BUF_SPRITES) + sizeof(OBJRAM_BACK_BUF_BULLETS)
1020: D7          rst  $10                   ; fill memory
1021: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
1024: 34          inc  (hl)                  ; advance to next stage of script (CLEAR_SCREEN_1A18 @ $1A18)
1025: 2D          dec  l
1026: 36 20       ld   (hl),$20
1028: 21 00 48    ld   hl,$4800              ; load HL with start of character RAM
102B: 22 0B 40    ld   ($400B),hl            ; write to TEMP_CHAR_RAM_PTR 
102E: CD 83 11    call $1183                 ; call CLEAR_ARRAYS_AND_SPRITES
1031: 3E 01       ld   a,$01
1033: 32 06 40    ld   ($4006),a             ; set IS_GAME_IN_PLAY flag.
1036: C3 C3 0F    jp   $0FC3                 ; jump to RESET_LANDSCAPE_EXTENTS


; 
; Shows head up display, and PLAYER TWO message in middle of screen, indicating its player two's turn.
;

DISPLAY_HUD_FOR_PLAYER_TWO:
1039: AF          xor  a
103A: 32 5F 42    ld   ($425F),a             ; reset TIMING_VARIABLE
103D: 3A 0F 40    ld   a,($400F)             ; read IS_COCKTAIL flag
1040: 0F          rrca                       ; move flag into carry
1041: 30 08       jr   nc,$104B              ; if not cocktail, goto $104B

; flip the screen for player 2 if its a cocktail cabinet
1043: 3E 01       ld   a,$01
1045: 32 06 68    ld   ($6806),a             ; set screen vertical flip
1048: 32 07 68    ld   ($6807),a             ; set screen horizontal flip

; 
104B: 3E 01       ld   a,$01
104D: 32 0D 40    ld   ($400D),a             ; set CURRENT_PLAYER to be 1 (PLAYER TWO)
1050: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
1053: 34          inc  (hl)                  ; advance to next stage of script (REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE @ $107E)
1054: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
1055: 36 96       ld   (hl),$96              ; set counter value

; Display head up display 
1057: 11 00 05    ld   de,$0500              ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param:0 = Display player 1's score
105A: FF          rst  $38                   ; call QUEUE_COMMAND
105B: 1C          inc  e                     ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param:1 = Display player 2's score
105C: FF          rst  $38                   ; call QUEUE_COMMAND
105D: 1C          inc  e                     ; Command ID: 5 = DISPLAY_SCORE_COMMAND, Param:2 = Display high score
105E: FF          rst  $38                   ; call QUEUE_COMMAND
105F: 11 03 06    ld   de,$0603              ; Command ID: 6 = PRINT_TEXT, Param:3 = PLAYER TWO 
1062: FF          rst  $38                   ; call QUEUE_COMMAND
1063: 1C          inc  e                     ; Command ID: 6 = PRINT_TEXT, Param:4 = HIGH SCORE
1064: FF          rst  $38                   ; call QUEUE_COMMAND
1065: 11 03 07    ld   de,$0703              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:3 = DISPLAY_CURRENT_PLAYER_LIVES
1068: FF          rst  $38                   ; call QUEUE_COMMAND
1069: 1E 00       ld   e,$00                 ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:0 = DISPLAY_MISSIONS_COMPLETED_FLAGS
106B: FF          rst  $38                   ; call QUEUE_COMMAND

; Copy player two state to current player state. Now current player = player two.
106C: 21 80 41    ld   hl,$4180              ; address of PLAYER_TWO_STATE
106F: 11 00 41    ld   de,$4100              ; address of CURRENT_PLAYER_STATE
1072: 01 40 00    ld   bc,$0040              
1075: ED B0       ldir                       ; copy state 
1077: 2A 1D 41    ld   hl,($411D)            ; read LANDSCAPE_FLAGS
107A: 22 18 41    ld   ($4118),hl            ; set LANDSCAPE_LAYOUT_PTR  
107D: C9          ret


;
; The player's turn is almost ready to begin. 
;
; We need to remove any existing sprites from the screen as they are from the previous turn, and then draw the flat landscape that you 
; see at the start of every level.
;

REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE:
107E: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
1081: 35          dec  (hl)
1082: C0          ret  nz
1083: 36 20       ld   (hl),$20              ; set TEMP_COUNTER_4009 
1085: 2C          inc  l                     ; bump HL to point to SCRIPT_STAGE
1086: 34          inc  (hl)                  ; advance to next stage of script (GAME_INIT @ $10BA)
1087: 11 82 06    ld   de,$0682              ; Command ID: 6 = PRINT_TEXT, Param:$82 = erase text PLAYER ONE  
108A: FF          rst  $38                   ; call QUEUE_COMMAND
108B: 1E 07       ld   e,$07                 ; Command ID: 6 = PRINT_TEXT, Param:$7 = FUEL
108D: FF          rst  $38                   ; call QUEUE_COMMAND
108E: CD 62 11    call $1162                 ; call CLEAR_SCREEN_EXCEPT_SCORES_AND_CREDIT
1091: CD 83 11    call $1183                 ; call CLEAR_ARRAYS_AND_SPRITES
1094: CD C3 0F    call $0FC3                 ; call RESET_LANDSCAPE_EXTENTS

1097: AF          xor  a
1098: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG
109B: 21 60 40    ld   hl,$4060              ; load HL with address of OBJRAM_BACK_BUF_SPRITES
109E: 06 40       ld   b,$40
10A0: D7          rst  $10                   ; fill memory  

; Draw flat strip of land you see when starting a level.
DRAW_FLAT_STRIP_OF_LAND:
10A1: 21 19 48    ld   hl,$4819              ; character RAM address to start drawing from
10A4: 11 1C 00    ld   de,$001C              ; offset to add to HL to get to next character row after plotting characters
10A7: 06 1E       ld   b,$1E                 ; number of rows to fill
10A9: 3E 36       ld   a,$36                 ; ordinal for rugged ground character
10AB: 0E 39       ld   c,$39                 ; ordinal for solid block character
10AD: 77          ld   (hl),a                ; plot rugged part of ground 
10AE: 2C          inc  l
10AF: 71          ld   (hl),c                ; plot solid block
10B0: 2C          inc  l
10B1: 71          ld   (hl),c                ; plot solid block
10B2: 2C          inc  l
10B3: 71          ld   (hl),c                ; plot solid block
10B4: 2C          inc  l
10B5: 71          ld   (hl),c                ; plot solid block
10B6: 19          add  hl,de
10B7: 10 F4       djnz $10AD
10B9: C9          ret


;
; Initialise player jet, select landscape, draw HUD ready for player to start turn 
;
;
;

GAME_INIT:
10BA: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009  
10BD: 35          dec  (hl)
10BE: C0          ret  nz                    ; wait until counter reaches zero
10BF: 36 0A       ld   (hl),$0A              ; set TEMP_COUNTER_4009 to 10

10C1: 2C          inc  l                     ; bump HL to point to SCRIPT_STAGE
10C2: 34          inc  (hl)                  ; advance to next stage of script (PLAY_GAME @ $22F4)

10C3: 3E 01       ld   a,$01
10C5: 32 19 40    ld   ($4019),a             ; set DRAW_LANDSCAPE_FLAG

10C8: 21 01 00    ld   hl,$0001
10CB: 22 80 43    ld   ($4380),hl            ; set PLAYERS[0].IsActive and reset PLAYERS[0].IsExploding flags
10CE: 22 A0 43    ld   ($43A0),hl            ; set PLAYERS[1].IsActive and reset PLAYERS[1].IsExploding flags

10D1: AF          xor  a
10D2: 32 82 43    ld   ($4382),a             ; reset PLAYERS[0].StageOfLife (see PLAYER_INIT @ $16FE)

; player starting level, update lives remaining 
10D5: 21 08 41    ld   hl,$4108              ; load HL with address of CURRENT_PLAYER_LIVES
10D8: 35          dec  (hl)                  ; reduce number of lives
10D9: 11 03 07    ld   de,$0703              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:3 = DISPLAY_CURRENT_PLAYER_LIVES
10DC: FF          rst  $38                   ; call QUEUE_COMMAND

10DD: 21 10 41    ld   hl,$4110
10E0: 11 11 41    ld   de,$4111
10E3: 01 0D 00    ld   bc,$000D
10E6: 36 00       ld   (hl),$00
10E8: ED B0       ldir

; select landscape depending on current player's level. 
10EA: 21 D0 29    ld   hl,$29D0              ; load HL with address of LANDSCAPE_LAYOUT_METADATA_TABLE table 
10ED: 3A 1E 41    ld   a,($411E)             ; read CURRENT_PLAYERS_LEVEL
10F0: 47          ld   b,a                   ; 
10F1: 87          add  a,a                   ; Multiply CURRENT_PLAYERS_LEVEL..
10F2: 80          add  a,b                   ; .. by 3 and store result in A.  
10F3: 5F          ld   e,a                   
10F4: 16 00       ld   d,$00                 ; Extend A into DE. Now DE is an offset into the LANDSCAPE_LAYOUT_METADATA_TABLE
10F6: 19          add  hl,de                 ; bump HL to point to layout metadata.
10F7: 7E          ld   a,(hl)                
10F8: 32 18 41    ld   ($4118),a             ; set LANDSCAPE_LAYOUT_PTR_LO
10FB: 23          inc  hl
10FC: 7E          ld   a,(hl)
10FD: 32 19 41    ld   ($4119),a             ; set LANDSCAPE_LAYOUT_PTR_HI
1100: 23          inc  hl
1101: 7E          ld   a,(hl)
1102: 32 1D 41    ld   ($411D),a             ; set LANDSCAPE_FLAGS

; Update progress bar 
1105: 11 02 07    ld   de,$0702              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:2 = DISPLAY_CURRENT_PLAYER_PROGRESS_BAR
1108: FF          rst  $38                   ; call QUEUE_COMMAND
1109: 3E 08       ld   a,$08
110B: 32 15 41    ld   ($4115),a             ; set LANDSCAPE_SCROLL_CONTROL_COUNTER
110E: 3E FF       ld   a,$FF
1110: 32 05 41    ld   ($4105),a             ; set CURRENT_PLAYER_FUEL to max (full tank)
1113: 3E 05       ld   a,$05
1115: 32 06 41    ld   ($4106),a             ; set CURRENT_PLAYER_FUEL_DRAIN_COUNTER rate
1118: 11 00 07    ld   de,$0700              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:0 = DISPLAY_MISSIONS_COMPLETED_FLAGS
111B: FF          rst  $38                   ; call QUEUE_COMMAND
111C: C9          ret



; See also $1209 (PLAYER_TWO_KILLED) 
PLAYER_ONE_KILLED:
; how many lives does player one have left?
111D: 3A 08 41    ld   a,($4108)             ; read CURRENT_PLAYER_LIVES
1120: A7          and  a                     ; test if zero (game over)
1121: 20 28       jr   nz,$114B              ; if not game over, goto PLAYER_ONE_NOT_GAME_OVER

; Player one's out of lives, so display GAME OVER PLAYER ONE
1123: CD 62 11    call $1162                 ; call CLEAR_SCREEN_EXCEPT_SCORES_AND_CREDIT
1126: CD 83 11    call $1183                 ; call CLEAR_ARRAYS_AND_SPRITES
1129: 11 00 06    ld   de,$0600              ; Command ID: 6 = PRINT_TEXT, Param:0 = GAME OVER
112C: FF          rst  $38                   ; call QUEUE_COMMAND 
112D: 1E 02       ld   e,$02                 ; Command ID: 6 = PRINT_TEXT, Param:2 = PLAYER ONE
112F: FF          rst  $38                   ; call QUEUE_COMMAND
1130: 3E 01       ld   a,$01
1132: 32 04 68    ld   ($6804),a             ; enable stars
1135: 3D          dec  a
1136: 32 03 68    ld   ($6803),a             ; set background to black

; Now let player one see if they have a high score
1139: 21 C0 45    ld   hl,$45C0              ; load HL with address of TEMP_COUNTER_45C0
113C: 36 96       ld   (hl),$96
113E: 2C          inc  l                     ; bump HL to point to HIGH_SCORE_SCRIPT_STAGE          
113F: 36 00       ld   (hl),$00              ; set HIGH_SCORE_SCRIPT_STAGE to 0 (start) 
1141: 3E 09       ld   a,$09
1143: 32 0A 40    ld   ($400A),a             ; set SCRIPT_STAGE to 9 (see HIGH_SCORE_SCRIPT @ $12F0)
1146: AF          xor  a
1147: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG 
114A: C9          ret


; Player one has some lives left. Is it a two player game? If not, return player one to start of level they died in.
; If it is a two player game, jump to a routine that checks if its player two's turn (they might be out of lives so can't continue.) 
PLAYER_ONE_NOT_GAME_OVER:
; First check if this is a two player game
114B: 3A 0E 40    ld   a,($400E)             ; read IS_TWO_PLAYER_GAME flag
114E: 0F          rrca                       ; move flag into carry
114F: 38 09       jr   c,$115A               ; if a two player game goto $115A

; its a one player game. 
1151: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
1154: 36 03       ld   (hl),$03              ; set SCRIPT_STAGE to 3 (see REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE @ $107E)
1156: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
1157: 36 32       ld   (hl),$32              ; set TEMP_COUNTER_4009
1159: C9          ret

; its a two player game.
115A: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
115D: 34          inc  (hl)                  ; advance to next stage of script (CHECK_IF_SHOULD_SWITCH_TO_PLAYER_TWO @ $11BA)
115E: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009 
115F: 36 32       ld   (hl),$32              ; set TEMP_COUNTER_4009
1161: C9          ret


;
;
; Clear all text, except scores and available credits, from the screen.
;
; 

CLEAR_SCREEN_EXCEPT_SCORES_AND_CREDIT:
1162: 21 03 48    ld   hl,$4803              ; load HL with address of 4th character on top row
1165: 11 05 00    ld   de,$0005

; first clear screen
1168: 0E 20       ld   c,$20                 ; 32 rows to do 
116A: 3E 10       ld   a,$10                 ; ordinal of empty space character    
116C: 06 1B       ld   b,$1B                 ; 27 characters to erase per row
116E: 77          ld   (hl),a                ; plot empty space character    
116F: 23          inc  hl                    ; bump HL to point to next character on same row 
1170: 10 FC       djnz $116E                 ; repeat until all characters erased 
1172: 19          add  hl,de                 ; bump HL to point to first character on *next* row to erase
1173: 0D          dec  c                     ; decrement counter of rows left to do
1174: 20 F6       jr   nz,$116C              ; if nonzero, there's more rows to be erased, goto $116C

; now set attributes and scroll offsets
1176: 21 2A 40    ld   hl,$402A              ; point to scroll offset for 4th character in OBJRAM_BACK_BUF
1179: 06 19       ld   b,$19                 ; do 25 columns
117B: AF          xor  a
117C: 77          ld   (hl),a                ; reset scroll offset 
117D: 2C          inc  l
117E: 77          ld   (hl),a                ; reset colour attribute to black
117F: 2C          inc  l
1180: 10 FA       djnz $117C
1182: C9          ret


; Clears (fills with 0) the following arrays: 
; GROUND_OBJECTS
; PLAYERS
; PLAYER_BOMBS
; INFLIGHT_ENEMIES
; PLAYER_BULLETS
; OBJRAM_BACK_BUF_SPRITES (will hide all sprites)
; OBJRAM_BACK_BUF_BULLETS (will hide all bullets)

CLEAR_ARRAYS_AND_SPRITES:
1183: 21 80 42    ld   hl,$4280              ; load HL with address of GROUND_OBJECTS
1186: 11 81 42    ld   de,$4281
1189: 01 A0 02    ld   bc,$02A0              
118C: 36 00       ld   (hl),$00              ; clear GROUND_OBJECTS array
118E: ED B0       ldir
1190: 21 60 42    ld   hl,$4260              ; load HL with address of CHAR_BASED_GROUND_OBJECTS array
1193: 11 61 42    ld   de,$4261
1196: 01 1F 00    ld   bc,$001F              ; sizeof(CHAR_BASED_GROUND_OBJECTS) -1
1199: 36 00       ld   (hl),$00
119B: ED B0       ldir                       ; clear CHAR_BASED_GROUND_OBJECTS array
119D: 21 60 40    ld   hl,$4060              ; load HL with address of OBJRAM_BACK_BUF_SPRITES
11A0: 11 61 40    ld   de,$4061
11A3: 01 3F 00    ld   bc,$003F              ; sizeof(OBJRAM_BACK_BUF_SPRITES) + sizeof(OBJRAM_BACK_BUF_BULLETS) -1
11A6: 36 00       ld   (hl),$00
11A8: ED B0       ldir                       ; clear OBJRAM_BACK_BUF_SPRITES & OBJRAM_BACK_BUF_BULLETS
11AA: C9          ret




CHECK_IF_SHOULD_SWITCH_TO_PLAYER_TWO:
; Skip to $11BA. I think this is dead code.
; I've put a breakpoint on reads from $41B0, $41B1 and $41B2 and have found this is the only code that references these addresses.
; I've NOPed out 11AB - 11B9 and no adverse effects occurred during the game.  
; My conclusion is that this is dead protection code. At best its wasting CPU cycles for some timing reason I can't fathom.   
11AB: 21 B0 41    ld   hl,$41B0
11AE: 7E          ld   a,(hl)
11AF: F6 03       or   $03
11B1: 77          ld   (hl),a
11B2: 2C          inc  l
11B3: F6 09       or   $09
11B5: 77          ld   (hl),a
11B6: 2C          inc  l
11B7: F6 0C       or   $0C
11B9: 77          ld   (hl),a

; 
11BA: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
11BD: 35          dec  (hl)                  
11BE: C0          ret  nz                    ; wait until the counter times out


; read number of lives player one has left.
11BF: 3A 08 41    ld   a,($4108)             ; read CURRENT_PLAYER_LIVES
11C2: A7          and  a                     ; test if zero
11C3: 20 10       jr   nz,$11D5              ; if player one has some lives left, goto $11D5

; player one has no lives left. Check if its a two player game.
11C5: 3A 0E 40    ld   a,($400E)             ; read IS_TWO_PLAYER_GAME flag.
11C8: 0F          rrca                       ; move flag into carry
11C9: 38 19       jr   c,$11E4               ; if its a two player game, goto $11E4

; Its a one player game and the player has no lives left: go back to the HOW FAR CAN YOU INVADE OUR SCRAMBLE SYSTEM intro. 
11CB: 3E 01       ld   a,$01
11CD: 32 05 40    ld   ($4005),a             ; set SCRIPT_NUMBER to 1 
11D0: AF          xor  a
11D1: 32 41 45    ld   ($4541),a             ; set ATTRACT_MODE_SCRIPT_STAGE to 0 ($0BC5)
11D4: C9          ret                        

; player one has some lives left, how about player two?
11D5: 3A 88 41    ld   a,($4188)             ; read PLAYER_TWO_LIVES
11D8: A7          and  a                     ; test if zero
11D9: 20 19       jr   nz,$11F4              ; if player two has some lives left, goto $11F4

; player one has some lives left, but player two doesn't (or its not a two player game) so let player one continue.
11DB: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE           
11DE: 36 03       ld   (hl),$03              ; set SCRIPT_STAGE to be REMOVE_SPRITES_AND_DRAW_FLAT_LANDSCAPE ($107E)
11E0: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
11E1: 36 01       ld   (hl),$01
11E3: C9          ret

; player one has no lives left and its a two player game. So do we switch to PLAYER TWO's game?
11E4: 3A 88 41    ld   a,($4188)             ; read PLAYER_TWO_LIVES
11E7: A7          and  a                     ; test if zero
11E8: 20 0A       jr   nz,$11F4              ; player two has some lives left, switch to his game 

; player one has no lives left and neither does player two. Go back to the HOW FAR CAN YOU INVADE OUR SCRAMBLE SYSTEM intro. 
11EA: 3E 01       ld   a,$01
11EC: 32 05 40    ld   ($4005),a             ; set SCRIPT_NUMBER to 1  
11EF: AF          xor  a
11F0: 32 41 45    ld   ($4541),a             ; set ATTRACT_MODE_SCRIPT_STAGE to 0 ($0BC5) 
11F3: C9          ret

; We're about to switch over to player two, but we need to preserve player one's progress. 
; Copy current game state over to player one's state 
11F4: 21 00 41    ld   hl,$4100              ; CURRENT_PLAYER_STATE
11F7: 11 40 41    ld   de,$4140              ; PLAYER_ONE_STATE 
11FA: 01 40 00    ld   bc,$0040               
11FD: ED B0       ldir

; switch to player TWO.
11FF: AF          xor  a
1200: 32 0A 40    ld   ($400A),a             ; set SCRIPT_STAGE to 0
1203: 3E 04       ld   a,$04
1205: 32 05 40    ld   ($4005),a             ; switch over to PLAYER_TWO_GAME_SCRIPT which handles player two 
1208: C9          ret



PLAYER_TWO_KILLED:
; how many lives does player two have remaining?
1209: 3A 08 41    ld   a,($4108)             ; read CURRENT_PLAYER_LIVES
120C: A7          and  a                     ; test if zero (game over)      
120D: 20 28       jr   nz,$1237              ; if not game over goto PLAYER_TWO_NOT_GAME_OVER

; Player two's out of lives, so display GAME OVER PLAYER TWO
120F: CD 62 11    call $1162                 ; call CLEAR_SCREEN_EXCEPT_SCORES_AND_CREDIT
1212: CD 83 11    call $1183                 ; call CLEAR_ARRAYS_AND_SPRITES
1215: 11 00 06    ld   de,$0600              ; Command ID: 6 = PRINT_TEXT, Param:0 = GAME OVER
1218: FF          rst  $38                   ; call QUEUE_COMMAND
1219: 1E 03       ld   e,$03                 ; Command ID: 6 = PRINT_TEXT, Param:3 = PLAYER TWO
121B: FF          rst  $38                   ; call QUEUE_COMMAND
121C: 3E 01       ld   a,$01
121E: 32 04 68    ld   ($6804),a             ; enable stars
1221: 3D          dec  a
1222: 32 03 68    ld   ($6803),a             ; set background to black

; Now let player two see if they have a high score
1225: 21 C0 45    ld   hl,$45C0              ; load HL with address of TEMP_COUNTER_45C0
1228: 36 96       ld   (hl),$96
122A: 2C          inc  l                     ; bump HL to point to HIGH_SCORE_SCRIPT_STAGE
122B: 36 00       ld   (hl),$00              ; set stage to 0
122D: 3E 09       ld   a,$09
122F: 32 0A 40    ld   ($400A),a             ; set SCRIPT_STAGE to 9 (HIGH_SCORE_SCRIPT @ $12F0)
1232: AF          xor  a
1233: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG
1236: C9          ret

; Player two has some lives left
; Switch to player one if possible 
PLAYER_TWO_NOT_GAME_OVER:
1237: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE              
123A: 34          inc  (hl)                  ; advance to next stage of script (CHECK_IF_SHOULD_SWITCH_TO_PLAYER_ONE @ $123F)
123B: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
123C: 36 64       ld   (hl),$64              ; set counter value
123E: C9          ret


;
; This code is almost identical to that in CHECK_IF_SHOULD_SWITCH_TO_PLAYER_TWO (see $11BA)
;
;

CHECK_IF_SHOULD_SWITCH_TO_PLAYER_ONE: 
123F: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009
1242: 35          dec  (hl)
1243: C0          ret  nz                    ; wait until the counter times out

; read number of lives player two has left.
1244: 3A 08 41    ld   a,($4108)             ; read CURRENT_PLAYER_LIVES
1247: A7          and  a                     ; test if zero               
1248: 20 10       jr   nz,$125A              ; if not zero, goto $125A

; player two has no lives left. Check if player one has any lives left.
124A: 3A 48 41    ld   a,($4148)             ; read PLAYER_ONE_LIVES
124D: A7          and  a                     ; test if zero
124E: 20 0A       jr   nz,$125A              ; if player one has lives left, goto $125A

; Its a two player game and neither player has any lives left: go back to the HOW FAR CAN YOU INVADE OUR SCRAMBLE SYSTEM intro. 
1250: 3E 01       ld   a,$01
1252: 32 05 40    ld   ($4005),a             ; set SCRIPT_NUMBER to 1
1255: AF          xor  a
1256: 32 41 45    ld   ($4541),a             ; clear ATTRACT_MODE_SCRIPT_STAGE
1259: C9          ret

; player two  has some lives left, how about player one?
125A: 3A 48 41    ld   a,($4148)             ; read PLAYER_ONE_LIVES
125D: A7          and  a                     ; test if zero
125E: 20 09       jr   nz,$1269              ; player one has some lives left, switch to his game

; player two has some lives left, but player one doesn't so let player two continue.
1260: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE  
1263: 36 03       ld   (hl),$03              ; set SCRIPT_STAGE to be GAME_INIT ($10BA)
1265: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
1266: 36 01       ld   (hl),$01
1268: C9          ret

; We're about to switch over to player one, but we need to preserve player two's progress. 
; Copy current game state over to player two's state 
1269: 21 00 41    ld   hl,$4100              ; CURRENT_PLAYER_STATE
126C: 11 80 41    ld   de,$4180              ; PLAYER_TWO_STATE
126F: 01 40 00    ld   bc,$0040
1272: ED B0       ldir

; switch to player ONE.
1274: AF          xor  a
1275: 32 0A 40    ld   ($400A),a             ; set SCRIPT_STAGE to 0
1278: 3E 03       ld   a,$03
127A: 32 05 40    ld   ($4005),a             ; switch over to PLAYER_ONE_GAME_SCRIPT which handles player one
127D: C9          ret




;
; This script executes when the player completes their mission
;

MISSION_COMPLETED_SCRIPT:
127E: 3A 81 45    ld   a,($4581)             ; read MISSION_COMPLETE_SCRIPT_STAGE
1281: EF          rst  $28                   ; invoke function mapping to script stage
1282: 
    88 12        ; $1288 (COOL_OFF)   
    AB 12        ; $12AB (DISPLAY_CONGRATULATIONS) 
    C6 12        ; $12C6 (AWARD_EXTRA_LIFE_AND_MISSION_FLAG)


;
; The mission is complete, but let the game continue for a second or so.
; I'll call this the "cool off period"
;

COOL_OFF:
1288: CD CC 13    call $13CC                 ; call ANIMATION_AND_MOVEMENT
128B: CD 35 1F    call $1F35                 ; call SCROLL_AND_SPRITES
128E: CD 36 20    call $2036                 ; call COLLISION_DETECTION
1291: CD C2 27    call $27C2                 ; call LANDSCAPE_CHANGE

; count down until cool off period is over
1294: 21 80 45    ld   hl,$4580              ; load HL with address of TEMP_COUNTER_4580
1297: 35          dec  (hl)                  ; decrement counter
1298: C0          ret  nz                    ; exit if cool off period isn't over yet
1299: 36 05       ld   (hl),$05              ; set value of TEMP_COUNTER_4580
129B: 2C          inc  l                     ; bump HL to point to MISSION_COMPLETE_SCRIPT_STAGE
129C: 34          inc  (hl)                  ; advance to next stage of script (DISPLAY_CONGRATULATIONS @ $12AB)
129D: 3E 01       ld   a,$01
129F: 32 04 68    ld   ($6804),a             ; enable stars
12A2: 3E 00       ld   a,$00
12A4: 32 03 68    ld   ($6803),a             ; set background to black
12A7: 32 19 40    ld   ($4019),a             ; clear DRAW_LANDSCAPE_FLAG 
12AA: C9          ret


;
; Displays "CONGRATULATIONS YOU COMPLETED YOUR DUTIES GOOD LUCK NEXT TIME"
;

DISPLAY_CONGRATULATIONS:
12AB: 21 80 45    ld   hl,$4580              ; load HL with address of TEMP_COUNTER_4580 
12AE: 35          dec  (hl)                   
12AF: C0          ret  nz
12B0: 2C          inc  l                     ; bump HL to point to MISSION_COMPLETE_SCRIPT_STAGE
12B1: 34          inc  (hl)                  ; advance to next stage of script (which is AWARD_EXTRA_LIFE_AND_MISSION_FLAG @ $12C6)
12B2: CD 62 11    call $1162                 ; call CLEAR_SCREEN_EXCEPT_SCORES_AND_CREDIT
12B5: 11 08 06    ld   de,$0608              ; command: PRINT_TEXT, parameter: 8 = CONGRATULATIONS
12B8: FF          rst  $38                   ; call QUEUE_COMMAND
12B9: 1C          inc  e                     ; command: PRINT_TEXT, parameter: 9 = YOU COMPLETED YOUR DUTIES 
12BA: FF          rst  $38                   ; call QUEUE_COMMAND
12BB: 1C          inc  e                     ; command: PRINT_TEXT, parameter: $0A = GOOD LUCK NEXT TIME
12BC: FF          rst  $38                   ; call QUEUE_COMMAND
12BD: 21 89 0B    ld   hl,$0B89              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0B89
12C0: CD D9 0A    call $0AD9                 ; call SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN
12C3: C3 83 11    jp   $1183                 ; jump to CLEAR_ARRAYS_AND_SPRITES


;
; Award extra life, add a "mission complete" flag and return to 1ST level
;

AWARD_EXTRA_LIFE_AND_MISSION_FLAG:
; Wait a short while until player has read the congratulations message
12C6: 21 80 45    ld   hl,$4580              ; load HL with address of TEMP_COUNTER_4580 
12C9: 35          dec  (hl)                  ; decrement counter value
12CA: C0          ret  nz                    ; wait until value reaches zero

; award extra life
12CB: 21 08 41    ld   hl,$4108              ; load HL with address of CURRENT_PLAYER_LIVES
12CE: 34          inc  (hl)                  ; give player an extra life
12CF: 21 00 41    ld   hl,$4100              ; load HL with address of CURRENT_PLAYER_MISSIONS_COMPLETED

; update missions completed flags on HUD
12D2: 34          inc  (hl)                  ; increment number of missions completed 
12D3: 11 00 07    ld   de,$0700              ; command: HEAD_UP_DISPLAY_COMMAND, parameter: 0 = DISPLAY_MISSIONS_COMPLETED_FLAGS
12D6: FF          rst  $38                   ; call QUEUE_COMMAND
12D7: AF          xor  a
12D8: 32 5F 42    ld   ($425F),a             ; reset TIMING_VARIABLE

; and restart game from level one
12DB: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
12DE: 36 03       ld   (hl),$03              ; set SCRIPT_STAGE to 3 (see GAME_INIT @ $10BA)
12E0: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
12E1: 36 0A       ld   (hl),$0A              ; set counter
12E3: CD C3 0F    call $0FC3                 ; call RESET_LANDSCAPE_EXTENTS
12E6: AF          xor  a
12E7: 32 1E 41    ld   ($411E),a             ; set CURRENT_PLAYERS_LEVEL back to start level
12EA: 21 E9 0A    ld   hl,$0AE9              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0AE9
12ED: C3 D9 0A    jp   $0AD9                 ; jump to SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN



HIGH_SCORE_SCRIPT:
12F0: 3A C1 45    ld   a,($45C1)             ; read HIGH_SCORE_SCRIPT_STAGE
12F3: EF          rst  $28                   ; call appropriate stage of script
12F4: 
    FA 12         ; $12FA (REMOVE_GAME_OVER_MESSAGE)
    0E 13         ; $130E (HIGHLIGHT_HIGH_SCORE) 
    2D 13         ; $132D (SWITCH_TO_OTHER_PLAYER)


REMOVE_GAME_OVER_MESSAGE:
12FA: 21 C0 45    ld   hl,$45C0              ; load HL with address of TEMP_COUNTER_45C0
12FD: 35          dec  (hl)                  ; decrement counter
12FE: C0          ret  nz                    ; return if counter hasn't reached zero.
12FF: 2C          inc  l                     ; bump HL to point to HIGH_SCORE_SCRIPT_STAGE
1300: 34          inc  (hl)                  ; advance to next stage of the GAME OVER script (which is HIGHLIGHT_HIGH_SCORE @ $130E)
1301: 11 80 06    ld   de,$0680              ; Command ID: 6 = PRINT_TEXT, Parameter: 80 = Clear GAME OVER text
1304: FF          rst  $38                   ; call QUEUE_COMMAND
1305: 1E 82       ld   e,$82                 ; Parameter 82 = Clear PLAYER ONE text
1307: FF          rst  $38                   ; call QUEUE_COMMAND
1308: 21 69 0B    ld   hl,$0B69              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0B69
130B: C3 D9 0A    jp   $0AD9                 ; jump to SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN



;
; If the user's score makes it into the high score table, highlight it in white.
;

HIGHLIGHT_HIGH_SCORE:
130E: CD 46 13    call $1346                 ; call GET_HIGH_SCORE_INDEX
1311: 7D          ld   a,l                   ; get index of high score into A. 
1312: FE 0A       cp   $0A                   ; compare to 10.
1314: 28 0B       jr   z,$1321               ; if 10, then that means the player didn't get a high score, goto $1321  

; Player has a high score. Calculate the address of the colour attribute for the player's high score, then set attribute to white to highlight score. 
1316: 87          add  a,a                   ; multiply index of high score..
1317: 87          add  a,a                   ; .. by 4.
1318: 5F          ld   e,a
1319: 16 00       ld   d,$00                 ; save result in DE
131B: 21 2F 40    ld   hl,$402F              
131E: 19          add  hl,de                 ; add result to $402F (OBJRAM_BACK_BUF_ATTRIBUTES)
131F: 36 00       ld   (hl),$00              ; set row containing new high score to WHITE

; Now display high scores
1321: 11 00 02    ld   de,$0200              ; command ID: 2 = DISPLAY_HIGH_SCORES_COMMAND
1324: FF          rst  $38                   ; call QUEUE_COMMAND

; Establish a short delay.
1325: 21 C0 45    ld   hl,$45C0              ; load HL with address of TEMP_COUNTER_45C0
1328: 36 80       ld   (hl),$80
132A: 2C          inc  l                     ; bump HL to point to HIGH_SCORE_SCRIPT_STAGE
132B: 34          inc  (hl)                  ; advance to next stage of the GAME OVER script    
132C: C9          ret


;
; After showing the player's high score, switch to the other player if possible.
;
;

SWITCH_TO_OTHER_PLAYER:
132D: 21 C0 45    ld   hl,$45C0              ; load HL with address of TEMP_COUNTER_45C0
1330: 35          dec  (hl)                  ; decrement counter
1331: C0          ret  nz                    ; return if counter hasn't reached zero.

1332: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
1335: 36 07       ld   (hl),$07              ; set SCRIPT_STAGE to 7 (either CHECK_IF_SHOULD_SWITCH_TO_PLAYER_ONE@$123F or CHECK_IF_SHOULD_SWITCH_TO_PLAYER_TWO @$11AB).
1337: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009
1338: 36 64       ld   (hl),$64              ; set TEMP_COUNTER_4009 to 100.
133A: C9          ret


;
; Called when rocket has been shot. This code  was possibly split from CHECK_IF_PLAYER_BOMB_HIT_ROCKET
; to make it harder to follow for hackers. 
;
; IY = pointer to PLAYER_BOMB struct
;

CHECK_IF_PLAYER_BOMB_HIT_ROCKET_CONTINUED_1:
133B: FD 36 02 06 ld   (iy+$02),$06          ; set PLAYER_BOMB.StageOfLife to 6 (see PLAYER_BOMB_EXPLOSION_INIT @ $1A4B)
133F: 11 0A 03    ld   de,$030A              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param: $0A = 80 points
1342: FF          rst  $38                   ; call QUEUE_COMMAND
1343: C3 17 25    jp   $2517



; Check if the player has a high score. If they do, then overwrite the relevant high score in the high score table,
; and return the index to the calling function.
;
; Returns: 
; L = zero-based index of high score that was overwritten with player's score. 
; if L = 10 that means player did not get a high score.

GET_HIGH_SCORE_INDEX:
1346: 01 1E 00    ld   bc,$001E              ; $1E = 30 decimal. Divide by 3 to give 10 - number of entries in high score table
1349: 11 03 00    ld   de,$0003              ; sizeof(bytes required for score)
134C: 6A          ld   l,d                   ; set l to 0
134D: DD 21 A2 40 ld   ix,$40A2              ; load IX with address of PLAYER_ONE_SCORE
1351: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER
1354: 0F          rrca                       ; if carry is set, player two is our current player
1355: 30 02       jr   nc,$1359              ; if carry is not set, player one is current, goto $1359
1357: DD 19       add  ix,de                 ; bump IX to point to PLAYER_TWO_SCORE

; IX = pointer to current player's score
1359: FD 21 00 42 ld   iy,$4200              ; load IY with address of HI_SCORE_TABLE_1ST

; Compare first two digits of score to first two digits of high score  
135D: DD 7E 02    ld   a,(ix+$02)            ; read first two digits of player's score 
1360: FD BE 02    cp   (iy+$02)              ; compare against first two digits of high score entry
1363: 20 0F       jr   nz,$1374              ; if they don't match,   

; Compare third & fourth digits
1365: DD 7E 01    ld   a,(ix+$01)            ; read third and fourth digits of players score  
1368: FD BE 01    cp   (iy+$01)
136B: 20 07       jr   nz,$1374

136D: DD 7E 00    ld   a,(ix+$00)
1370: FD BE 00    cp   (iy+$00)
1373: C8          ret  z

1374: 30 09       jr   nc,$137F              ; if digits of player's score >= digits of high score, goto REPLACE_HIGH_SCORE_WITH_PLAYERS_SCORE 

1376: FD 19       add  iy,de                 ; bump IY to point to next score in table (going from top score, to 2nd top, 3rd top etc)  
1378: 2C          inc  l                     ; increment index of high score 
1379: 0D          dec  c
137A: 0D          dec  c
137B: 0D          dec  c
137C: C8          ret  z
137D: 18 DE       jr   $135D

;
; IX = pointer to players score (3 BCD digits)
; IY = pointer to high score entry to overwrite with players score
; BC = number of bytes to move in high score table
; L = zero-based index of high score that will be overwritten (0=1ST, 1=2ND, 2=3RD and so on) 
REPLACE_HIGH_SCORE_WITH_PLAYERS_SCORE:
137F: 7D          ld   a,l
1380: 21 1D 42    ld   hl,$421D              ; pointer to tens digits of HI_SCORE_TABLE_10TH  
1383: 11 20 42    ld   de,$4220              ; pointer to HI_SCORE_TABLE_BUFFER 
1386: ED B8       lddr                       ; shift scores down 
1388: 6F          ld   l,a

; now overwrite high score entry with player score
1389: DD 7E 00    ld   a,(ix+$00)
138C: FD 77 00    ld   (iy+$00),a
138F: DD 7E 01    ld   a,(ix+$01)
1392: FD 77 01    ld   (iy+$01),a
1395: DD 7E 02    ld   a,(ix+$02)
1398: FD 77 02    ld   (iy+$02),a
139B: C9          ret



; Add 10 points to players score every 64 ticks of the TIMING_VARIABLE.
GAIN_POINTS_JUST_FOR_STAYING_ALIVE:
139C: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
139F: E6 3F       and  $3F                   ; if the modulus of TIMING_VARIABLE divided by 64 != 0.. 
13A1: C0          ret  nz                    ; ..then return.

13A2: 11 0C 03    ld   de,$030C              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param: $0C = 10 points
13A5: FF          rst  $38                   ; call QUEUE_COMMAND
13A6: C9          ret


CHECK_IF_EXTRA_LIFE_SHOULD_BE_AWARDED:
13A7: 3A 07 41    ld   a,($4107)             ; read CURRENT_PLAYER_HAD_EXTRA_LIFE
13AA: A7          and  a                     ; test flag
13AB: C0          ret  nz                    ; exit if player has already been awarded an extra life

; Find out what player is playing 
13AC: 21 A4 40    ld   hl,$40A4              ; load HL with address of first 2 digits of PLAYER ONE's score
13AF: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER                       
13B2: 0F          rrca
13B3: 30 03       jr   nc,$13B8              ; if no carry, PLAYER ONE is playing, goto $13B8

; player two is playing
13B5: 21 A7 40    ld   hl,$40A7              ; load HL with address of first 2 digits of PLAYER TWO's score

; If the first two digits of the player's score aren't zero, then the player has hit 10000 points and a new life can be awarded.
13B8: 7E          ld   a,(hl)                ; read first two digits
13B9: A7          and  a                     ; test if zero
13BA: C8          ret  z                     ; exit if first two digits are zero. No extra life for you! 
13BB: CD C4 24    call $24C4                 ; do a protection check and then play a "life awarded!" sound.
13BE: 21 08 41    ld   hl,$4108              ; load HL with address of CURRENT_PLAYER_LIVES
13C1: 34          inc  (hl)                  ; award player an extra life!
13C2: 11 03 07    ld   de,$0703              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:3 = DISPLAY_CURRENT_PLAYER_LIVES
13C5: FF          rst  $38                   ; call QUEUE_COMMAND
13C6: 3E 01       ld   a,$01
13C8: 32 07 41    ld   ($4107),a             ; set CURRENT_PLAYER_HAD_EXTRA_LIFE flag. Player will not get another extra life. 
13CB: C9          ret


ANIMATION_AND_MOVEMENT:
13CC: CD A5 15    call $15A5                 ; call SCROLL
13CF: CD AE 18    call $18AE                 ; call GROUND_OBJECT_ANIMATION_AND_MOVEMENT
13D2: CD D0 16    call $16D0                 ; call PLAYER_ANIMATION_AND_MOVEMENT
13D5: CD 30 1A    call $1A30                 ; call PLAYER_BOMB_ANIMATION_AND_MOVEMENT 
13D8: CD 98 1C    call $1C98                 ; call ROCKET_ANIMATION_AND_MOVEMENT
13DB: CD 75 1D    call $1D75                 ; call UFO_ANIMATION_AND_MOVEMENT
13DE: CD C6 1E    call $1EC6                 ; call FIREBALL_ANIMATION_AND_MOVEMENT
13E1: C3 AA 16    jp   $16AA                 ; call MOVE_PLAYER_BULLETS




;
; This function animates an entity.
;
; IX = pointer to a PLAYER/ PLAYER_BOMB/ GROUND_OBJECT/ INFLIGHT_ENEMY struct.
;
; Before this method is called, the AnimPtrLo (IX + $0C) and AnimPtrHi (IX + $0D) fields must form a pointer to a record within an "animation table". 
; An animation table describes the colours and sprite codes required for an animation. It does *not* define how the entity moves (see FOLLOW_PATH @$1578 for more info.) 
;
; Each entry in the animation table requires 3 bytes:
;   * Byte 0: the core colour for the animation frame;
;   * Byte 1: the "sprite code" (number) for the animation frame to display;
;   * Byte 2: the delay before showing the next frame.
;
; A colour byte of $FF is special: it marks the end of the animation sequence (the "end of animation marker"); 
; The subsequent two bytes are a pointer to the next animation table to use. 
;
; All animation tables have the suffix _ANIMATION_TABLE. e.g. PLAYER_ONE_JET_ANIMATION_TABLE.
 

ANIMATE:
13E4: DD 7E 0E    ld   a,(ix+$0e)            ; read AnimationCounter value
13E7: A7          and  a                       
13E8: 28 05       jr   z,$13EF               ; if AnimationCounter has counted down to zero goto CHANGE_COLOUR_AND_SPRITE_CODE 
13EA: 3D          dec  a                     ; 
13EB: DD 77 0E    ld   (ix+$0e),a            ; otherwise decrement delay value
13EE: C9          ret                   

; change colour and sprite code (animation frame) of entity  
CHANGE_COLOUR_AND_SPRITE_CODE:
13EF: DD 6E 0C    ld   l,(ix+$0c)            ; read AnimPtrLo 
13F2: DD 66 0D    ld   h,(ix+$0d)            ; read AnimPtrHi. Now HL contains a pointer to animation information
13F5: 7E          ld   a,(hl)                ; read colour byte 
13F6: FE FF       cp   $FF                   ; is this the end of animation marker byte? (see docs @ $1860)
13F8: 28 15       jr   z,$140F               ; yes, goto END_OF_ANIMATION_SEQUENCE
13FA: DD 77 16    ld   (ix+$16),a            ; set Colour
13FD: 23          inc  hl                    ;
13FE: 7E          ld   a,(hl)                ;  
13FF: DD 77 12    ld   (ix+$12),a            ; write to SpriteCode / CharCode
1402: 23          inc  hl
1403: 7E          ld   a,(hl)
1404: DD 77 0E    ld   (ix+$0e),a            ; write to AnimationCounter
1407: 23          inc  hl
1408: DD 75 0C    ld   (ix+$0c),l            
140B: DD 74 0D    ld   (ix+$0d),h            ; update pointer to animation information
140E: C9          ret

; We have encountered the "end of animation marker" byte ($FF). The next two bytes we read from (HL) form a pointer to the next animation table we must use. 
END_OF_ANIMATION_SEQUENCE: 
140F: 23          inc  hl                    ; bump HL. Now HL is a pointer to a pointer [to an animation table] 
1410: 7E          ld   a,(hl)                ; read low byte of animation table address
1411: DD 77 0C    ld   (ix+$0c),a            ; set AnimPtrLo
1414: 23          inc  hl
1415: 7E          ld   a,(hl)                ; read high byte of animation table address 
1416: DD 77 0D    ld   (ix+$0d),a            ; set AnimPtrHi  
1419: 18 C9       jr   $13E4                 ; jump to ANIMATE to read animation info.




;
; The code from $141B-1577 is unused. I've put breakpoints on some of the entry points and played through the game, they are never called.
; 

/*** START UNUSED CODE ***/
141B: DD E5       push ix
141D: E1          pop  hl
141E: 3E 07       ld   a,$07
1420: 85          add  a,l
1421: 6F          ld   l,a
1422: DD 36 0A 00 ld   (ix+$0a),$00
1426: DD 7E 05    ld   a,(ix+$05)
1429: DD BE 03    cp   (ix+$03)
142C: 28 04       jr   z,$1432
142E: 38 1E       jr   c,$144E
1430: 18 56       jr   $1488

1432: DD 7E 06    ld   a,(ix+$06)
1435: DD BE 04    cp   (ix+$04)
1438: 28 0E       jr   z,$1448
143A: 38 06       jr   c,$1442
143C: 36 00       ld   (hl),$00
143E: 2C          inc  l
143F: 36 01       ld   (hl),$01
1441: C9          ret

1442: 36 00       ld   (hl),$00
1444: 2C          inc  l
1445: 36 FF       ld   (hl),$FF
1447: C9          ret

1448: 36 00       ld   (hl),$00
144A: 2C          inc  l
144B: 36 00       ld   (hl),$00
144D: C9          ret

144E: DD 7E 06    ld   a,(ix+$06)
1451: DD BE 04    cp   (ix+$04)
1454: 28 2C       jr   z,$1482
1456: 38 15       jr   c,$146D
1458: 36 FF       ld   (hl),$FF
145A: 2C          inc  l
145B: 36 01       ld   (hl),$01
145D: DD 7E 03    ld   a,(ix+$03)
1460: DD 96 05    sub  (ix+$05)
1463: 47          ld   b,a
1464: DD 7E 06    ld   a,(ix+$06)
1467: DD 96 04    sub  (ix+$04)
146A: 4F          ld   c,a
146B: 18 55       jr   $14C2

146D: 36 FF       ld   (hl),$FF
146F: 2C          inc  l
1470: 36 FF       ld   (hl),$FF
1472: DD 7E 03    ld   a,(ix+$03)
1475: DD 96 05    sub  (ix+$05)
1478: 47          ld   b,a
1479: DD 7E 04    ld   a,(ix+$04)
147C: DD 96 06    sub  (ix+$06)
147F: 4F          ld   c,a
1480: 18 40       jr   $14C2
1482: 36 FF       ld   (hl),$FF
1484: 2C          inc  l
1485: 36 00       ld   (hl),$00
1487: C9          ret

1488: DD 7E 06    ld   a,(ix+$06)
148B: DD BE 04    cp   (ix+$04)
148E: 28 2C       jr   z,$14BC
1490: 38 15       jr   c,$14A7
1492: 36 01       ld   (hl),$01
1494: 2C          inc  l
1495: 36 01       ld   (hl),$01
1497: DD 7E 05    ld   a,(ix+$05)
149A: DD 96 03    sub  (ix+$03)
149D: 47          ld   b,a
149E: DD 7E 06    ld   a,(ix+$06)
14A1: DD 96 04    sub  (ix+$04)
14A4: 4F          ld   c,a
14A5: 18 1B       jr   $14C2

14A7: 36 01       ld   (hl),$01
14A9: 2C          inc  l
14AA: 36 FF       ld   (hl),$FF
14AC: DD 7E 05    ld   a,(ix+$05)
14AF: DD 96 03    sub  (ix+$03)
14B2: 47          ld   b,a
14B3: DD 7E 04    ld   a,(ix+$04)
14B6: DD 96 06    sub  (ix+$06)
14B9: 4F          ld   c,a
14BA: 18 06       jr   $14C2

14BC: 36 01       ld   (hl),$01
14BE: 2C          inc  l
14BF: 36 00       ld   (hl),$00
14C1: C9          ret

14C2: 79          ld   a,c
14C3: B8          cp   b
14C4: 28 16       jr   z,$14DC
14C6: 38 0B       jr   c,$14D3
14C8: DD 36 09 00 ld   (ix+$09),$00
14CC: CD E5 14    call $14E5
14CF: DD 77 0B    ld   (ix+$0b),a
14D2: C9          ret

14D3: DD 36 09 01 ld   (ix+$09),$01
14D7: 78          ld   a,b
14D8: 41          ld   b,c
14D9: 4F          ld   c,a
14DA: 18 F0       jr   $14CC

14DC: DD 36 09 01 ld   (ix+$09),$01
14E0: DD 36 0B FF ld   (ix+$0b),$FF
14E4: C9          ret

14E5: AF          xor  a
14E6: 67          ld   h,a
14E7: 68          ld   l,b
14E8: 57          ld   d,a
14E9: 59          ld   e,c
14EA: 06 08       ld   b,$08
14EC: CB FF       set  7,a
14EE: 07          rlca
14EF: 29          add  hl,hl
14F0: A7          and  a
14F1: ED 52       sbc  hl,de
14F3: 38 03       jr   c,$14F8
14F5: 10 F5       djnz $14EC
14F7: C9          ret

14F8: 19          add  hl,de
14F9: CB 87       res  0,a
14FB: 10 EF       djnz $14EC
14FD: C9          ret

14FE: DD 7E 04    ld   a,(ix+$04)
1501: DD BE 06    cp   (ix+$06)
1504: 28 4A       jr   z,$1550
1506: DD 7E 03    ld   a,(ix+$03)
1509: DD BE 05    cp   (ix+$05)
150C: 28 58       jr   z,$1566
150E: DD CB 09 46 bit  0,(ix+$09)
1512: 28 1E       jr   z,$1532
1514: DD 7E 07    ld   a,(ix+$07)
1517: DD 86 03    add  a,(ix+$03)
151A: DD 77 03    ld   (ix+$03),a
151D: DD 7E 0B    ld   a,(ix+$0b)
1520: DD 86 0A    add  a,(ix+$0a)
1523: DD 77 0A    ld   (ix+$0a),a
1526: D0          ret  nc
1527: DD 7E 08    ld   a,(ix+$08)
152A: DD 86 04    add  a,(ix+$04)
152D: DD 77 04    ld   (ix+$04),a
1530: A7          and  a
1531: C9          ret

1532: DD 7E 08    ld   a,(ix+$08)
1535: DD 86 04    add  a,(ix+$04)
1538: DD 77 04    ld   (ix+$04),a
153B: DD 7E 0B    ld   a,(ix+$0b)
153E: DD 86 0A    add  a,(ix+$0a)
1541: DD 77 0A    ld   (ix+$0a),a
1544: D0          ret  nc
1545: DD 7E 07    ld   a,(ix+$07)
1548: DD 86 03    add  a,(ix+$03)
154B: DD 77 03    ld   (ix+$03),a
154E: A7          and  a
154F: C9          ret

1550: DD 7E 03    ld   a,(ix+$03)
1553: DD BE 05    cp   (ix+$05)
1556: 28 0C       jr   z,$1564
1558: 30 05       jr   nc,$155F
155A: DD 34 03    inc  (ix+$03)
155D: A7          and  a
155E: C9          ret

155F: DD 35 03    dec  (ix+$03)
1562: A7          and  a
1563: C9          ret

1564: 37          scf
1565: C9          ret

1566: DD 7E 04    ld   a,(ix+$04)
1569: DD BE 06    cp   (ix+$06)
156C: 30 05       jr   nc,$1573
156E: DD 34 04    inc  (ix+$04)
1571: A7          and  a
1572: C9          ret

1573: DD 35 04    dec  (ix+$04)
1576: A7          and  a
1577: C9          ret

/*** END UNUSED CODE ***/


;
; Makes the entity move along a table-driven path. 
;
; Expects:
; IX = pointer to PLAYER_BOMB or INFLIGHT_ENEMY structure 
;
; PathPtrLo (IX + $13) and PathPtrHi (IX+$14) form a pointer to an entry in a path table which is basically a table of 2D vectors. 
;
; Each entry in the table comprises of 2 bytes:
;   Byte 0: a signed delta (which I will call XDelta in the code below) to be added to the X coordinate 
;   Byte 1: a signed delta (which I will call YDelta)to be added to the Y coordinate
;
; An XDelta of #$80 is a special case. This means that the end of the path has been reached, and that the 2 following bytes 
; in the table should be treated as a pointer to the next path to follow. This allows paths to be "chained" but I haven't
; seen any paths that reference anything except themselves.
;

FOLLOW_PATH:
1578: DD 6E 13    ld   l,(ix+$13)            ; read PathPtrLo          
157B: DD 66 14    ld   h,(ix+$14)            ; read PathPtrHi. Now HL = pointer to a path
157E: 7E          ld   a,(hl)                ; read byte from path
157F: FE 80       cp   $80                   ; is this a marker byte?
1581: 20 0C       jr   nz,$158F              ; if not, goto UPDATE_XY_FROM_PATH

; we've got a marker byte. Next 2 bytes are a pointer to our next path.
1583: 23          inc  hl
1584: 7E          ld   a,(hl)
1585: DD 77 13    ld   (ix+$13),a            ; set PathPtrLo
1588: 23          inc  hl
1589: 7E          ld   a,(hl)
158A: DD 77 14    ld   (ix+$14),a            ; set PathPtrHi
158D: 18 E9       jr   $1578                 ; goto FOLLOW_PATH

; Update X and Y coordinates of the object using our deltas
UPDATE_XY_FROM_PATH:
158F: DD 86 03    add  a,(ix+$03)            ; X = X + XDelta 
1592: DD 77 03    ld   (ix+$03),a            ; update X 
1595: 23          inc  hl                   
1596: 7E          ld   a,(hl)
1597: DD 86 04    add  a,(ix+$04)            ; Y = Y + YDelta
159A: DD 77 04    ld   (ix+$04),a            ; update Y 
159D: 23          inc  hl
159E: DD 75 13    ld   (ix+$13),l            ; update PathPtrLo         
15A1: DD 74 14    ld   (ix+$14),h            ; update PathPtrHi
15A4: C9          ret



;
;
; ! IMPORTANT !
;
; Scrolls on a new part of the landscape every 16 pixels (2 character rows)
;
;

LANDSCAPE_SCROLLING:
15A5: DD 21 10 41 ld   ix,$4110
15A9: DD 7E 05    ld   a,(ix+$05)            ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
15AC: A7          and  a                     ; test if zero
15AD: 20 12       jr   nz,$15C1              ; if not zero, goto UPDATE_SCROLL_CONTROL_COUNTER which decrements it

; LANDSCAPE_SCROLL_CONTROL_COUNTER is zero.
15AF: DD 7E 04    ld   a,(ix+$04)            ; read LANDSCAPE_SCROLL_CONTROL_LATCH value
15B2: DD 77 05    ld   (ix+$05),a            ; set LANDSCAPE_SCROLL_CONTROL_COUNTER to the latch value

; Every 16th pixel we need to scroll a new part of the landscape on.
15B5: DD 7E 06    ld   a,(ix+$06)            ; read LANDSCAPE_SCROLL_COUNTER
15B8: E6 0F       and  $0F                   ; 
15BA: CC C5 15    call z,$15C5               ; if LANDSCAPE_SCROLL_COUNTER modulo 16 == 0, call READ_LANDSCAPE_LAYOUT
15BD: DD 34 06    inc  (ix+$06)              ; increment LANDSCAPE_SCROLL_COUNTER 
15C0: C9          ret

UPDATE_SCROLL_CONTROL_COUNTER:
15C1: DD 35 05    dec  (ix+$05)              ; decrement LANDSCAPE_SCROLL_CONTROL_COUNTER
15C4: C9          ret


;
; A LANDSCAPE_LAYOUT defines the landscape and ground objects (targets!) for a level.  
;
; A landscape layout is comprised of multiple records. Each record defines 2 character columns (16 pixels) of a level, specifically:
;     * the ordinals of the characters to be scrolled on (the "sharp edges" of the landscape, so to speak); 
;     * the "height(s)" to draw the characters at;
;     * any ground objects (targets) to be rendered.
;  
; Each record can be either 6 bytes or 9 bytes in size; 9 bytes if a ceiling needs to be rendered. 
; IMPORTANT: A level layout may comprise a mix of both 6 and 9 byte records. 
; 
; The record structure is as follows: 
;   Byte 0: used to compute LANDSCAPE_GROUND_FIRST_CHAR_PTR (see $15FD)
;   Byte 1: sets LANDSCAPE_GROUND_FIRST_CHAR (see $160A)
;   Byte 2: used to compute LANDSCAPE_GROUND_SECOND_CHAR_PTR (see $15E4)
;   Byte 3: sets LANDSCAPE_GROUND_SECOND_CHAR (see $15F3)
;
;   This is where things become a little more complex. Byte 4 determines if this record is going to be 6 or 9 bytes in size.
;   If Byte 4 is zero:
;       * this record is 6 bytes in size and no ceiling needs to be rendered: 
;       * Byte 5 sets NEXT_GROUND_OBJECT_ID (see $164A);
;   
;   Else If Byte 4 is nonzero:
;       This record is 9 bytes in size because a ceiling needs to be rendered, and:
;       * Byte 4 is used to compute LANDSCAPE_CEILING_FIRST_CHAR_PTR (see $167B)
;       * Byte 5 is stored in LANDSCAPE_CEILING_FIRST_CHAR (see $1688)
;       * Byte 6 is used to compute LANDSCAPE_CEILING_SECOND_CHAR_PTR (see $1664)
;       * Byte 7 sets LANDSCAPE_CEILING_SECOND_CHAR (see $1671)
;       * Byte 8 sets NEXT_GROUND_OBJECT_ID (see $1645)
;  
;
; See also:
; Landscape layout definitions @ $29E2, $2DD3, $31C4, $3465, $3856, $3C47.

READ_LANDSCAPE_LAYOUT:
15C5: CD CB 15    call $15CB                 ; call DECODE_LANDSCAPE_FLOOR
15C8: C3 59 16    jp   $1659                 ; jump to DECODE_LANDSCAPE_CEILING


DECODE_LANDSCAPE_FLOOR:
15CB: FD 2A 18 41 ld   iy,($4118)            ; load IY with contents of LANDSCAPE_LAYOUT_PTR
15CF: 3E 01       ld   a,$01
15D1: 32 10 41    ld   ($4110),a             ; set CAN_DRAW_LANDSCAPE_1 
15D4: 32 30 42    ld   ($4230),a             ; set CAN_DRAW_LANDSCAPE_2

; Calculate where in screen RAM to plot two characters of ground
15D7: DD 7E 06    ld   a,(ix+$06)            ; read LANDSCAPE_SCROLL_COUNTER
15DA: 2F          cpl                        ; flip bits                          
15DB: E6 F0       and  $F0
15DD: 47          ld   b,a                   ; save result in B for use later - see $1610 
15DE: 6F          ld   l,a
15DF: 26 12       ld   h,$12
15E1: 29          add  hl,hl
15E2: 29          add  hl,hl
15E3: E5          push hl                    ; save character RAM address on stack

; compute LANDSCAPE_GROUND_SECOND_CHAR_PTR and LANDSCAPE_GROUND_SECOND_CHAR
15E4: FD 7E 02    ld   a,(iy+$02)
15E7: E6 F8       and  $F8
15E9: 0F          rrca
15EA: 0F          rrca
15EB: 0F          rrca
15EC: 5F          ld   e,a
15ED: 16 00       ld   d,$00
15EF: 19          add  hl,de                 ; HL is now an address in character RAM
15F0: 22 35 42    ld   ($4235),hl            ; set LANDSCAPE_GROUND_SECOND_CHAR_PTR 
15F3: FD 7E 03    ld   a,(iy+$03)
15F6: 32 34 42    ld   ($4234),a             ; set LANDSCAPE_GROUND_SECOND_CHAR

15F9: E1          pop  hl

; Bump HL to point to next character row
15FA: 1E 20       ld   e,$20                 ; 32 bytes per character row
15FC: 19          add  hl,de

; compute LANDSCAPE_GROUND_FIRST_CHAR_PTR and LANDSCAPE_GROUND_FIRST_CHAR 
15FD: FD 7E 00    ld   a,(iy+$00)
1600: E6 F8       and  $F8
1602: 0F          rrca
1603: 0F          rrca
1604: 0F          rrca
1605: 5F          ld   e,a                   ; E = character offset on row
1606: 19          add  hl,de
1607: 22 32 42    ld   ($4232),hl            ; set LANDSCAPE_GROUND_FIRST_CHAR_PTR
160A: FD 7E 01    ld   a,(iy+$01)
160D: 32 31 42    ld   ($4231),a             ; set LANDSCAPE_GROUND_FIRST_CHAR

; Now record the ground height in the relevant LANDSCAPE_EXTENT record. 
1610: 78          ld   a,b
1611: 0F          rrca
1612: 0F          rrca
1613: 5F          ld   e,a
1614: 21 C0 41    ld   hl,$41C0               ; load HL with address of LANDSCAPE_EXTENTS
1617: 19          add  hl,de
1618: FD 7E 02    ld   a,(iy+$02)
161B: 77          ld   (hl),a                 ; set LANDSCAPE_EXTENT.GroundX
161C: 2C          inc  l

; $28 is the default for when the landscape has no ceiling (ie: not cave or maze)
161D: 36 28       ld   (hl),$28               ; set LANDSCAPE_EXTENT.CeilingX
161F: 2C          inc  l                      ; bump HL to point to next LANDSCAPE_EXTENT record

1620: FD 7E 00    ld   a,(iy+$00)
1623: 77          ld   (hl),a                 ; set LANDSCAPE_EXTENT.GroundX
1624: 2C          inc  l
1625: 36 28       ld   (hl),$28               ; set LANDSCAPE_EXTENT.CeilingX 


1627: AF          xor  a
1628: 32 38 42    ld   ($4238),a             ; reset LANDSCAPE_HAS_CEILING_FLAG
162B: 32 11 41    ld   ($4111),a             ; reset DISABLE_STARS flag

; do we have a ceiling to render?
162E: 2A 18 41    ld   hl,($4118)            ; load HL with contents of LANDSCAPE_LAYOUT_PTR
1631: 1E 09       ld   e,$09                 ; sizeof(record) that contains ceiling data                  
1633: FD 7E 04    ld   a,(iy+$04)            
1636: A7          and  a                     ; test if byte 4 is nonzero
1637: 20 02       jr   nz,$163B              ; if nonzero, we have a ceiling, goto $163B  

1639: 1E 06       ld   e,$06                 ; sizeof(record) that does not contain ceiling data

163B: 19          add  hl,de
163C: 22 18 41    ld   ($4118),hl            ; update LANDSCAPE_LAYOUT_PTR

; identify what type of ground object we are going to scroll onto screen
163F: FD 7E 04    ld   a,(iy+$04)
1642: A7          and  a
1643: 28 05       jr   z,$164A
1645: FD 7E 08    ld   a,(iy+$08)
1648: 18 03       jr   $164D                 

164A: FD 7E 05    ld   a,(iy+$05)
164D: 32 1A 41    ld   ($411A),a             ; set NEXT_GROUND_OBJECT_ID

; Establish where next CHAR_BASED_GROUND_OBJECT will be plotted
1650: 2A 35 42    ld   hl,($4235)            ; load HL with contents of LANDSCAPE_GROUND_SECOND_CHAR_PTR
1653: 2B          dec  hl
1654: 2B          dec  hl               
1655: 22 1B 41    ld   ($411B),hl            ; set NEXT_GROUND_OBJECT_CHAR_PTR
1658: C9          ret


;
;
;
;
;

DECODE_LANDSCAPE_CEILING:
1659: FD 7E 04    ld   a,(iy+$04)
165C: A7          and  a
165D: C8          ret  z

; Calculate where in screen RAM to plot two characters for ceiling
165E: 68          ld   l,b
165F: 26 12       ld   h,$12
1661: 29          add  hl,hl
1662: 29          add  hl,hl
1663: E5          push hl


; compute LANDSCAPE_GROUND_SECOND_CHAR_PTR and LANDSCAPE_GROUND_SECOND_CHAR
1664: FD 7E 06    ld   a,(iy+$06)
1667: E6 F8       and  $F8
1669: 0F          rrca
166A: 0F          rrca
166B: 0F          rrca
166C: 5F          ld   e,a
166D: 19          add  hl,de
166E: 22 3D 42    ld   ($423D),hl            ; set LANDSCAPE_CEILING_SECOND_CHAR_PTR
1671: FD 7E 07    ld   a,(iy+$07)
1674: 32 3C 42    ld   ($423C),a             ; set LANDSCAPE_CEILING_SECOND_CHAR
1677: E1          pop  hl

; bump HL to point to next row
1678: 1E 20       ld   e,$20
167A: 19          add  hl,de

; compute LANDSCAPE_CEILING_FIRST_CHAR_PTR and LANDSCAPE_CEILING_FIRST_CHAR 
167B: FD 7E 04    ld   a,(iy+$04)
167E: E6 F8       and  $F8
1680: 0F          rrca
1681: 0F          rrca
1682: 0F          rrca
1683: 5F          ld   e,a
1684: 19          add  hl,de
1685: 22 3A 42    ld   ($423A),hl            ; set LANDSCAPE_CEILING_FIRST_CHAR_PTR
1688: FD 7E 05    ld   a,(iy+$05)
168B: 32 39 42    ld   ($4239),a             ; set LANDSCAPE_CEILING_FIRST_CHAR

; Now record the ceiling depth in the relevant LANDSCAPE_EXTENT record.  
; The ground height for the same record will be set at $1610 
168E: 78          ld   a,b
168F: 0F          rrca
1690: 0F          rrca
1691: 5F          ld   e,a
1692: 21 C0 41    ld   hl,$41C0              ; load HL with address of LANDSCAPE_EXTENTS
1695: 19          add  hl,de
1696: 2C          inc  l
1697: FD 7E 06    ld   a,(iy+$06)
169A: 77          ld   (hl),a                ; set LANDSCAPE_EXTENT.CeilingX
169B: 2C          inc  l
169C: 2C          inc  l
169D: FD 7E 04    ld   a,(iy+$04)
16A0: 77          ld   (hl),a                ; set LANDSCAPE_EXTENT.CeilingX

; If the maze has a ceiling then we don't show starfield
16A1: 3E 01       ld   a,$01
16A3: 32 11 41    ld   ($4111),a             ; set DISABLE_STARS flag
16A6: 32 38 42    ld   ($4238),a             ; set LANDSCAPE_HAS_CEILING_FLAG
16A9: C9          ret


;
; Update any active player bullets.
; When bullet goes off screen, deactivate it.
;

MOVE_PLAYER_BULLETS:
16AA: DD 21 00 45 ld   ix,$4500              ; load IX with address of PLAYER_BULLETS 
16AE: 11 03 00    ld   de,$0003              ; sizeof(PLAYER_BULLET)
16B1: 06 04       ld   b,$04                 ; player can have a maximum of 4 bullets at once
16B3: CD BB 16    call $16BB
16B6: DD 19       add  ix,de
16B8: 10 F9       djnz $16B3
16BA: C9          ret

16BB: DD CB 00 46 bit  0,(ix+$00)            ; read PLAYER_BULLET.IsActive flag   
16BF: C8          ret  z
16C0: DD 7E 02    ld   a,(ix+$02)            ; read PLAYER_BULLET.Y            
16C3: D6 03       sub  $03                   ; subtract 3 pixels - to player, bullet will appear to move right
16C5: DD 77 02    ld   (ix+$02),a            ; update PLAYER_BULLET.Y
16C8: FE 1F       cp   $1F                   ; has bullet gone offscreen?
16CA: D0          ret  nc                    ; return if not 

16CB: DD CB 00 86 res  0,(ix+$00)            ; otherwise clear PLAYER_BULLET.IsActive flag
16CF: C9          ret


;
; Read the joystick state and animate and move the player jet accordingly
;
; This code does not read the state of the SHOOT or BOMB buttons - see SPAWN_PLAYER_BULLET @$257F and SPAWN_PLAYER_BOMB @ $26B1 for that.  
;

PLAYER_ANIMATION_AND_MOVEMENT:
; Protection code - if not interested, skip to $16DA
16D0: 00          nop
16D1: 00          nop
16D2: 78          ld   a,b
16D3: 4F          ld   c,a
16D4: 2A B9 40    ld   hl,($40B9)            ; read PROTECTION_PORT_PTR_1
16D7: 36 00       ld   (hl),$00              ; write to protection
16D9: 00          nop
; End protection code

16DA: DD 21 80 43 ld   ix,$4380              ; load IX with address of PLAYERS[0].IsActive flag
16DE: DD 7E 00    ld   a,(ix+$00)            ; read flag
16E1: DD B6 01    or   (ix+$01)              ; OR with PLAYERS[0].IsExploding flag
16E4: 0F          rrca                       ; if either flag is set, carry will be set after rrca 
16E5: D0          ret  nc                    ; return if player is not active and not dying 

PLAYER_STAGE_OF_LIFE:
16E6: DD 7E 02    ld   a,(ix+$02)            ; read PLAYER.StageOfLife
16E9: EF          rst  $28
16EA: 
     FE 16        ; PLAYER_INIT
     25 17        ; PLAYER_ANIMATE  
     D4 17        ; PLAYER_OUT_OF_FUEL 
     07 18        ; $1807: just a RET 
     08 18        ; $1808: just a RET
     09 18        ; $1809: just a RET
     0A 18        ; PLAYER_EXPLOSION_INIT
     25 18        ; PLAYER_EXPLOSION_ANIMATE 
     5E 18        ; $185E: just a RET
     5F 18        ; $185F: just a RET
     

;
;
; Initialise important player state such as screen position and animation table  
;
;

PLAYER_INIT:
16FE: DD 36 03 58 ld   (ix+$03),$58          ; set PLAYERS[0].X
1702: DD 36 23 58 ld   (ix+$23),$58          ; set PLAYERS[1].X
1706: DD 36 04 D0 ld   (ix+$04),$D0          ; set PLAYERS[0].Y
170A: DD 36 24 E0 ld   (ix+$24),$E0          ; set PLAYERS[1].Y
170E: 21 60 18    ld   hl,$1860              ; load HL with address of PLAYER_ONE_JET_ANIMATION_TABLE
1711: 22 8C 43    ld   ($438C),hl            ; set PLAYERS[0].AnimPtr to point to PLAYER_ONE_JET_ANIMATION_TABLE 
1714: 21 6F 18    ld   hl,$186F              ; load HL with address of PLAYER_TWO_JET_ANIMATION_TABLE
1717: 22 AC 43    ld   ($43AC),hl            ; set PLAYERS[1].AnimPtr to point to PLAYER_TWO_JET_ANIMATION_TABLE 
171A: DD 36 0E 00 ld   (ix+$0e),$00          ; set PLAYERS[0].AnimationCounter to 0  
171E: DD 36 2E 00 ld   (ix+$2e),$00          ; set PLAYERS[1].AnimationCounter to 0
1722: DD 34 02    inc  (ix+$02)              ; advance to next stage of life


; Drain player's fuel, and if not out of fuel animate the jet and read joystick controls to move
PLAYER_ANIMATE:
1725: 21 06 41    ld   hl,$4106              ; load HL with address of CURRENT_PLAYER_FUEL_DRAIN_COUNTER            
1728: 35          dec  (hl)                  ; decrement counter 
1729: 20 0A       jr   nz,$1735              ; if counter hasn't hit zero, goto ANIMATE_AND_MOVE_PLAYER
172B: C3 B5 29    jp   $29B5                 ; jump to SET_CURRENT_PLAYER_FUEL_DRAIN_COUNTER to reset counter depending on level. Eventually jumps to $172E...

; HL = address of CURRENT_PLAYER_FUEL ($4105)
172E: 35          dec  (hl)                  ; reduce amount of fuel left
172F: 20 04       jr   nz,$1735              ; if not run out of fuel, goto $1735 
1731: DD 34 02    inc  (ix+$02)              ; player has run out of fuel. increment PLAYER[].StageOfLife 
1734: C9          ret

1735: DD 21 A0 43 ld   ix,$43A0              ; address of PLAYER_TWO
1739: CD E4 13    call $13E4                 ; call ANIMATE
173C: DD 21 80 43 ld   ix,$4380              ; address of PLAYER_ONE
1740: CD E4 13    call $13E4                 ; call ANIMATE 
1743: CD 49 17    call $1749                 ; call PLAYER_MOVE_VERTICAL
1746: C3 9E 17    jp   $179E                 ; call PLAYER_MOVE_HORIZONTAL


;
; Read joystick state and move the player jet up or down the screen accordingly, if required. 
;
; Expects:
; IX = pointer to PLAYER structure
;

PLAYER_MOVE_VERTICAL:
1749: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY 
174C: 0F          rrca                       ; move flag into carry
174D: D0          ret  nc                    ; return if game is not in play
174E: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER                      
1751: 0F          rrca                       ; set carry if its player 2
1752: 38 33       jr   c,$1787               ; if player 2, goto $1787

; Player 1 is in charge. Read vertical joystick state. 
CHECK_IF_PLAYER_ONE_JOYSTICK_PUSHED_UP_OR_DOWN:
1754: 3A 12 40    ld   a,($4012)             ; read PORT_STATE_8102 
1757: 06 00       ld   b,$00
1759: CB 67       bit  4,a                   ; read IPT_JOYSTICK_UP
175B: 28 02       jr   z,$175F               ; if joystick not pushed up, goto $175F
175D: CB C0       set  0,b
175F: CB 77       bit  6,a                   ; read IPT_JOYSTICK_DOWN
1761: 28 02       jr   z,$1765               ; if joystick not pushed down, goto $1765
1763: CB C8       set  1,b

; Bit 0 of B set: joystick pushed UP.  Bit 1 set: joystick pushed DOWN.
1765: 78          ld   a,b

CHECK_IF_JOYSTICK_PUSHED_UP:
1766: 0F          rrca                       ; move joystick UP flag into carry
1767: 30 0E       jr   nc,$1777              ; if joystick not pushed up, goto CHECK_IF_JOYSTICK_PUSHED_DOWN

; joystick has been pushed up. Can we move the player jet up?
1769: DD 7E 03    ld   a,(ix+$03)            ; read PLAYER.X
176C: 3D          dec  a                     ; tentatively decrement X coordinate  
176D: FE 38       cp   $38                   ; has the jet flown as far up as it can go?
176F: D8          ret  c                     ; yes, so return 

; move the player jet up
1770: DD 77 03    ld   (ix+$03),a            ; otherwise update PLAYER.X
1773: DD 35 23    dec  (ix+$23)
1776: C9          ret

CHECK_IF_JOYSTICK_PUSHED_DOWN:
1777: 0F          rrca                       ; move joystick DOWN flag into carry
1778: D0          ret  nc                    ; if joystick not pushed down, return

; Joystick has been pushed down. Can we move the player jet down? 
1779: DD 7E 03    ld   a,(ix+$03)            ; read PLAYER.X
177C: 3C          inc  a                     ; tentatively increment X coordinate  
177D: FE D8       cp   $D8                   ; has the jet flown as far down as it can go?
177F: D0          ret  nc                    ; yes, so return

; Move the player jet down
1780: DD 77 03    ld   (ix+$03),a            ; otherwise update PLAYER.X
1783: DD 34 23    inc  (ix+$23)
1786: C9          ret


;
; Player 2 is in charge. Read joystick state.
;

CHECK_IF_PLAYER_TWO_JOYSTICK_PUSHED_UP_OR_DOWN:
1787: 3A 12 40    ld   a,($4012)             ; read PORT_STATE_8102
178A: 06 00       ld   b,$00
178C: CB 47       bit  0,a                   ; test IPT_JOYSTICK_DOWN bit
178E: 28 02       jr   z,$1792               ; if player is not pushing stick down, goto $1792
1790: CB C8       set  1,b
1792: 3A 10 40    ld   a,($4010)             ; read PORT_STATE_8100
1795: CB 47       bit  0,a                   ; test IPT_JOYSTICK_UP bit
1797: 28 02       jr   z,$179B               ; if player is not pushing stick up, goto $179B
1799: CB C0       set  0,b

; Bit 0 of B set: joystick pushed UP.  Bit 1 set: joystick pushed DOWN.
179B: 78          ld   a,b
179C: 18 C8       jr   $1766                 ; jump to CHECK_IF_JOYSTICK_PUSHED_UP


;
; Read joystick state and move the player jet left or right accordingly, if required. 
;
; Expects:
; IX = pointer to PLAYER structure
;
PLAYER_MOVE_HORIZONTAL:
179E: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY
17A1: 0F          rrca                       ; move flag into carry
17A2: D0          ret  nc                    ; return if game is not in play
17A3: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER                         
17A6: 0F          rrca                       ; set carry if its player 2
17A7: 38 26       jr   c,$17CF               ; if player 2, goto CHECK_IF_PLAYER_TWO_JOYSTICK_PUSHED_LEFT_OR_RIGHT

; Player 1's in charge, so read controller 1 bits 
17A9: 3A 10 40    ld   a,($4010)             ; read PORT_STATE_8100

CHECK_IF_JOYSTICK_PUSHED_LEFT:
17AC: 07          rlca
17AD: 07          rlca
17AE: 07          rlca                       ; move IPT_JOYSTICK_LEFT bit into carry
17AF: 30 0E       jr   nc,$17BF              ; if joystick is not being pushed left, goto CHECK_IF_JOYSTICK_PUSHED_RIGHT

; joystick is being pushed left. Can we move the player left?
17B1: DD 7E 04    ld   a,(ix+$04)            ; read PLAYER.Y
17B4: 3C          inc  a                     ; tentatively increment Y coordinate 
17B5: FE D0       cp   $D0                   ; has the jet flown as far left as it can go?
17B7: D0          ret  nc                    ; yes, so return 

17B8: DD 77 04    ld   (ix+$04),a            ; otherwise update PLAYER.Y 
17BB: DD 34 24    inc  (ix+$24)
17BE: C9          ret

CHECK_IF_JOYSTICK_PUSHED_RIGHT:
17BF: 07          rlca                       ; move 1PT_JOYSTICK_RIGHT bit into carry
17C0: D0          ret  nc                    ; exit if joystick is not being pushed right 

; joystick is being pushed right. Can we move the player right?
17C1: DD 7E 04    ld   a,(ix+$04)            ; read PLAYER.Y
17C4: 3D          dec  a                     ; tentatively decrement Y coordinate 
17C5: FE 80       cp   $80                   ; has the jet flown as far right as it can go?
17C7: D8          ret  c                     ; yes, so return

17C8: DD 77 04    ld   (ix+$04),a            ; otherwise update PLAYER.Y 
17CB: DD 35 24    dec  (ix+$24)
17CE: C9          ret


; Player 2's in charge, so read controller 2 bits 
CHECK_IF_PLAYER_TWO_JOYSTICK_PUSHED_LEFT_OR_RIGHT:
17CF: 3A 11 40    ld   a,($4011)             ; read PORT_STATE_8101
17D2: 18 D8       jr   $17AC                 ; goto CHECK_IF_JOYSTICK_PUSHED_LEFT


;
; The player's run out of fuel. 
; Make the player's jet lose altitude and crash into the ground.
;
; Expects:
; IX = pointer to PLAYER structure
;

PLAYER_OUT_OF_FUEL:
17D4: DD 21 A0 43 ld   ix,$43A0              ; load IX with address of PLAYERS[1]
17D8: CD E4 13    call $13E4                 ; call ANIMATE
17DB: DD 21 80 43 ld   ix,$4380              ; load IX with address of PLAYERS[0]
17DF: CD E4 13    call $13E4                 ; call ANIMATE
17E2: DD 34 03    inc  (ix+$03)              ; increment PLAYER.X
17E5: DD 34 23    inc  (ix+$23)
17E8: DD 7E 03    ld   a,(ix+$03)            ; read PLAYER.X
17EB: FE F0       cp   $F0                   ; has plane hit the ground yet?
17ED: D8          ret  c                     ; return if not

; Plane's hit the ground and going to explode
17EE: DD 36 00 00 ld   (ix+$00),$00          ; clear PLAYERS[0].IsActive 
17F2: DD 36 01 01 ld   (ix+$01),$01          ; set PLAYERS[0].IsExploding
17F6: DD 36 02 06 ld   (ix+$02),$06          ; set PLAYERS[0].StageOfLife to 6 (see PLAYER_EXPLOSION_INIT @ $180A)      
17FA: DD 36 20 00 ld   (ix+$20),$00          ; clear PLAYERS[1].IsActive   
17FE: DD 36 21 01 ld   (ix+$21),$01          ; set PLAYERS[1].IsExploding  
1802: DD 36 22 06 ld   (ix+$22),$06          ; set PLAYERS[1].StageOfLife to 6 (see PLAYER_EXPLOSION_INIT @ $180A)
1806: C9          ret

1807: C9          ret

1808: C9          ret

1809: C9          ret



PLAYER_EXPLOSION_INIT:
180A: 21 7E 18    ld   hl,$187E              ; load HL with address of PLAYER_ONE_EXPLOSION_ANIMATION_TABLE
180D: 22 8C 43    ld   ($438C),hl
1810: DD 36 0E 00 ld   (ix+$0e),$00
1814: DD 36 0F 6F ld   (ix+$0f),$6F          ; set PLAYER.ExplosionCounter
1818: 21 96 18    ld   hl,$1896              ; load HL with address of PLAYER_TWO_EXPLOSION_ANIMATION_TABLE
181B: 22 AC 43    ld   ($43AC),hl
181E: DD 36 2E 00 ld   (ix+$2e),$00
1822: DD 34 02    inc  (ix+$02)              ; bump StageOfLife  



PLAYER_EXPLOSION_ANIMATE:
1825: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
1828: E6 03       and  $03
182A: CC 54 18    call z,$1854               ; if timing variable is a multiple of 4, call CYCLE_LANDSCAPE_COLOUR
182D: DD 21 A0 43 ld   ix,$43A0
1831: CD E4 13    call $13E4                 ; call ANIMATE
1834: DD 21 80 43 ld   ix,$4380
1838: CD E4 13    call $13E4                 ; call ANIMATE

183B: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
183E: A7          and  a                     ; test if zero
183F: 20 06       jr   nz,$1847              ; if not zero, goto CHECK_IF_PLAYER_EXPLOSION_FINISHED

; These 2 lines of code are never called. From tinkering I've found they are meant to scroll the jet explosion animation off screen. 
1841: DD 34 04    inc  (ix+$04)
1844: DD 34 24    inc  (ix+$24)

; Have we finished exploding yet?
CHECK_IF_PLAYER_EXPLOSION_FINISHED:
1847: DD 35 0F    dec  (ix+$0f)              ; decrement PLAYER.ExplosionCounter
184A: C0          ret  nz                    ; if the explosion counter hasn't reached zero, the explosion animation hasn't finished, so exit

; explosion animation is complete
184B: DD 36 01 00 ld   (ix+$01),$00          ; reset PLAYER.IsExploding flag
184F: DD 36 21 00 ld   (ix+$21),$00
1853: C9          ret



;
; The player has been killed. Cycle the landscape colours.
;

CYCLE_LANDSCAPE_COLOUR:
1854: 3A 17 41    ld   a,($4117)             ; read LANDSCAPE_COLOUR
1857: 3C          inc  a                     ; increment it to next colour
1858: E6 07       and  $07                   ; clamp colour to value between 0 and 7
185A: 32 17 41    ld   ($4117),a             ; set LANDSCAPE_COLOUR

185D: C9          ret

185E: C9          ret

185F: C9          ret


PLAYER_ONE_JET_ANIMATION_TABLE:
1860: 
    06 28 05  ; colour = 06, code = $28, delay = $05                 
    06 2A 05  ; colour = 06, code = $2A, delay = $05        
    06 2C 05  ; colour = 06, code = $2C, delay = $05        
    06 2E 05  ; colour = 06, code = $2E, delay = $05     
    FF        ; end of animation marker        
    60 18     ; pointer to PLAYER_ONE_JET_ANIMATION_TABLE ($1860) - this animation is cyclic 


PLAYER_TWO_JET_ANIMATION_TABLE:
186F: 
    00 27 05  ; colour = 0, code = $27, delay = $05        
    00 29 05  ; colour = 0, code = $29, delay = $05         
    00 2B 05  ; colour = 0, code = $2B, delay = $05        
    00 2D 05  ; colour = 0, code = $2D, delay = $05  
    FF        ; end of animation marker  
    6F 18     ; pointer to PLAYER_TWO_JET_ANIMATION_TABLE ($186F) - this animation is cyclic
    
PLAYER_ONE_EXPLOSION_ANIMATION_TABLE:
187E: 
    04 3C 10 
    04 3D 10 
    04 3C 10 
    04 3D 10 
    04 3C 10
    04 3D 10 
    04 3E 10       
    FF        ; end of animation marker 
    7E 18     ; pointer to PLAYER_ONE_EXPLOSION_ANIMATION_TABLE ($187E) - this animation is cyclic


PLAYER_TWO_EXPLOSION_ANIMATION_TABLE:
1896:  
    04 BC 10 
    04 BD 10 
    04 BC 10 
    04 BD 10 
    04 BC 10 
    04 BD 10 
    04 BE 10 
    FF        ; end of animation marker
    96 18     ; pointer to PLAYER_TWO_EXPLOSION_ANIMATION_TABLE ($1896) - this animation is cyclic



;
; Handles all GROUND_OBJECTS from cradle to grave, ie:  initialisation/ animation/ explosion / death /deletion from screen.
;
;

GROUND_OBJECT_ANIMATION_AND_MOVEMENT:
; Protection check    
18AE: 2A B9 40    ld   hl,($40B9)
18B1: 36 0F       ld   (hl),$0F
; end protection check

18B3: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS
18B7: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
18BA: 06 08       ld   b,$08
18BC: D9          exx
18BD: CD C6 18    call $18C6                 ; call GROUND_OBJECT_STAGE_OF_LIFE
18C0: D9          exx
18C1: DD 19       add  ix,de
18C3: 10 F7       djnz $18BC
18C5: C9          ret


GROUND_OBJECT_STAGE_OF_LIFE:
18C6: DD 7E 00    ld   a,(ix+$00)            ; read GROUND_OBJECT.IsActive flag 
18C9: DD B6 01    or   (ix+$01)              ; combine with GROUND_OBJECT.IsExploding flag
18CC: 0F          rrca                       ; move result into carry
18CD: D0          ret  nc                    ; return if neither flag is set
18CE: DD 7E 02    ld   a,(ix+$02)            ; read GROUND_OBJECT.StageOfLife
18D1: EF          rst  $28

18D2: 
      E6 18       ; GROUND_OBJECT_INIT        
      2F 19       ; GROUND_OBJECT_ANIMATE    
      47 19       ; $1947: RET   
      48 19       ; GROUND_OBJECT_DELETE   
      62 19       ; $1962: RET         
      63 19       ; $1963: RET   
      64 19       ; GROUND_OBJECT_EXPLOSION_INIT   
      A7 19       ; GROUND_OBJECT_EXPLOSION_ANIMATE   
      C4 19       ; $19C4: RET 
      C5 19       ; $19C5: RET   



;
; Initialise a GROUND_OBJECT. 
;
;

; IX = pointer to vacant GROUND_OBJECT structure
GROUND_OBJECT_INIT:
; get pointer to character RAM address where the ground object should be drawn
18E6: 2A 1B 41    ld   hl,($411B)            ; read NEXT_GROUND_OBJECT_CHAR_PTR
18E9: DD 75 18    ld   (ix+$18),l            ; set GROUND_OBJECT.CharRamPtrLo
18EC: DD 74 19    ld   (ix+$19),h            ; set GROUND_OBJECT.CharRamPtrHi

; calculate screen coordinates for GROUND_OBJECT to use in collision detection
18EF: 3A 16 41    ld   a,($4116)             ; read LANDSCAPE_SCROLL_COUNTER
18F2: E6 0F       and  $0F
18F4: C6 F8       add  a,$F8
18F6: DD 77 04    ld   (ix+$04),a            ; set GROUND_OBJECT.Y
18F9: 7D          ld   a,l
18FA: E6 1F       and  $1F
18FC: 07          rlca
18FD: 07          rlca
18FE: 07          rlca
18FF: C6 08       add  a,$08
1901: DD 77 03    ld   (ix+$03),a            ; set GROUND_OBJECT.X

; Identify the animation table the GROUND_OBJECT needs
1904: DD 7E 17    ld   a,(ix+$17)            ; read GROUND_OBJECT.ObjectType
1907: A7          and  a
1908: 28 15       jr   z,$191F               ; if GROUND_OBJECT.ObjectType==0, goto GROUND_OBJECT_ROCKET_INIT 
190A: 3D          dec  a
190B: 28 08       jr   z,$1915               ; if GROUND_OBJECT.ObjectType==1, goto GROUND_OBJECT_FUEL_TANK_INIT
190D: 3D          dec  a
190E: 28 0A       jr   z,$191A               ; if GROUND_OBJECT.ObjectType==2, goto GROUND_OBJECT_MYSTERY_INIT
1910: 21 D8 19    ld   hl,$19D8              ; otherwise, the object type is "Base" (the only animated ground object)
1913: 18 0D       jr   $1922

GROUND_OBJECT_FUEL_TANK_INIT:
1915: 21 CC 19    ld   hl,$19CC              ; load HL with address of GROUND_OBJECT_FUEL_TANK_ANIMATION_TABLE
1918: 18 08       jr   $1922

GROUND_OBJECT_MYSTERY_INIT:
191A: 21 D2 19    ld   hl,$19D2              ; load HL with address of GROUND_OBJECT_MYSTERY_ANIMATION_TABLE
191D: 18 03       jr   $1922

GROUND_OBJECT_ROCKET_INIT:
191F: 21 C6 19    ld   hl,$19C6              ; load HL with address of GROUND_OBJECT_ROCKET_ANIMATION_TABLE

; Main part of GROUND_OBJECT_INIT - invoked for all ground object types
; HL = pointer to animation table for the ground object
1922: DD 75 0C    ld   (ix+$0c),l            ; set GROUND_OBJECT.AnimPtrLo
1925: DD 74 0D    ld   (ix+$0d),h            ; set GROUND_OBJECT.AnimPtrHi
1928: DD 36 0E 00 ld   (ix+$0e),$00          ; set GROUND_OBJECT.AnimationCounter
192C: DD 34 02    inc  (ix+$02)              ; set GROUND_OBJECT.StageOfLife to 2 (GROUND_OBJECT_ANIMATE)


; IX = pointer to GROUND_OBJECT
GROUND_OBJECT_ANIMATE:
192F: CD E4 13    call $13E4                 ; call ANIMATE

; keep the ground object's Y coordinate in sync with landscape.
1932: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
1935: A7          and  a
1936: C0          ret  nz
1937: DD 34 04    inc  (ix+$04)              ; increment GROUND_OBJECT.Y

; has the ground object scrolled off the screen?
193A: DD 7E 04    ld   a,(ix+$04)
193D: C6 14       add  a,$14
193F: FE 08       cp   $08
1941: D0          ret  nc

; ground object has scrolled off the screen. Set stage of life to be 3 (GROUND_OBJECT_DELETE)
1942: DD 36 02 03 ld   (ix+$02),$03
1946: C9          ret

1947: C9          ret


; IX = pointer to GROUND_OBJECT to be deleted from screen.  
GROUND_OBJECT_DELETE:
1948: DD 6E 18    ld   l,(ix+$18)            ; read GROUND_OBJECT.CharRamPtrLo
194B: DD 66 19    ld   h,(ix+$19)            ; read GROUND_OBJECT.CharRamPtrHi
; now HL = address in character RAM
194E: 3E 10       ld   a,$10                 ; ordinal of empty character
1950: 77          ld   (hl),a                ; erase 1st character 
1951: 23          inc  hl
1952: 77          ld   (hl),a                ; erase 2nd character
1953: 11 1F 00    ld   de,$001F              ; Add 31 to bump HL to character RAM line below 
1956: 19          add  hl,de
1957: 77          ld   (hl),a                ; erase 3rd character
1958: 23          inc  hl
1959: 77          ld   (hl),a                ; erase 4th character
195A: AF          xor  a
195B: DD 77 00    ld   (ix+$00),a            ; clear GROUND_OBJECT.IsActive
195E: DD 77 01    ld   (ix+$01),a            ; clear GROUND_OBJECT.IsExploding
1961: C9          ret

1962: C9          ret
1963: C9          ret



GROUND_OBJECT_EXPLOSION_INIT:
; First find out what type of object is exploding, then pick the correct animation table.
1964: DD 7E 17    ld   a,(ix+$17)            ; read GROUND_OBJECT.ObjectType
1967: 3D          dec  a
1968: 28 05       jr   z,$196F               ; if GROUND_OBJECT.ObjectType==1, goto GROUND_OBJECT_EXPLOSION_INIT_FUEL_TANK
196A: 3D          dec  a
196B: 28 09       jr   z,$1976               ; if GROUND_OBJECT.ObjectType==2, goto GROUND_OBJECT_EXPLOSION_INIT_MYSTERY
196D: 18 23       jr   $1992                 ; otherwise, use the default explosion animation.

GROUND_OBJECT_EXPLOSION_INIT_FUEL_TANK:
196F: 21 F3 19    ld   hl,$19F3              ; address of FUEL_TANK_EXPLOSION_ANIMATION_TABLE
1972: 3E 3F       ld   a,$3F                 ; counter for how long explosion should last. Higher = longer 
1974: 18 21       jr   $1997


;
; The "Mystery" has been hit. Instead of an explosion animation, we display a points value. 
; 

GROUND_OBJECT_EXPLOSION_INIT_MYSTERY:
1976: DD 46 1A    ld   b,(ix+$1a)            ; read GROUND_OBJECT.MysteryPointsType (see also: MYSTERY_SHOT_AWARD_RANDOM_PTS @$2296)
1979: 3E 4F       ld   a,$4F                 ; counter for how long points value should be displayed. Higher = longer 
197B: 05          dec  b                    
197C: 28 05       jr   z,$1983               ; if GROUND_OBJECT.MysteryPointsType == 1, goto GROUND_OBJECT_EXPLOSION_INIT_MYSTERY_DISPLAY_200PTS
197E: 05          dec  b
197F: 28 07       jr   z,$1988               ; if GROUND_OBJECT.MysteryPointsType == 2, goto GROUND_OBJECT_EXPLOSION_INIT_MYSTERY_DISPLAY_300PTS
1981: 18 0A       jr   $198D                 ; goto GROUND_OBJECT_EXPLOSION_INIT_MYSTERY_DISPLAY_100PTS

; Display "200PTS"
GROUND_OBJECT_EXPLOSION_INIT_MYSTERY_DISPLAY_200PTS:
1983: 21 0C 1A    ld   hl,$1A0C              ; load HL with address of MYSTERY_200PTS_ANIMATION_TABLE
1986: 18 0F       jr   $1997

; Display "300PTS"
GROUND_OBJECT_EXPLOSION_INIT_MYSTERY_DISPLAY_300PTS:
1988: 21 12 1A    ld   hl,$1A12              ; load HL with address of MYSTERY_300PTS_ANIMATION_TABLE
198B: 18 0A       jr   $1997

; Display "100PTS"
GROUND_OBJECT_EXPLOSION_INIT_MYSTERY_DISPLAY_100PTS:
198D: 21 02 1A    ld   hl,$1A02              ; load HL with address of MYSTERY_100PTS_ANIMATION_TABLE
1990: 18 05       jr   $1997


1992: 21 E4 19    ld   hl,$19E4              ; load HL with address of DEFAULT_EXPLOSION_ANIMATION_TABLE 
1995: 3E 3F       ld   a,$3F

; Main part of GROUND_OBJECT_EXPLOSION_INIT - invoked for all ground object types
; HL = pointer to animation table for the exploding ground object
1997: DD 75 0C    ld   (ix+$0c),l            ; set GROUND_OBJECT.AnimPtrLo
199A: DD 74 0D    ld   (ix+$0d),h            ; set GROUND_OBJECT.AnimPtrHi
199D: DD 36 0E 00 ld   (ix+$0e),$00          ; set GROUND_OBJECT.AnimationCounter
19A1: DD 77 0F    ld   (ix+$0f),a            ; set GROUND_OBJECT.ExplosionCounter
19A4: DD 34 02    inc  (ix+$02)              ; set GROUND_OBJECT.StageOfLife to 2 (GROUND_OBJECT_ANIMATE)


;
; Animate the exploding GROUND_OBJECT. 
;
; IX = pointer to GROUND_OBJECT
GROUND_OBJECT_EXPLOSION_ANIMATE:
19A7: CD E4 13    call $13E4                 ; call ANIMATE

; has the explosion counter counted down to zero? If so, the explosion animation is done, remove this ground object from screen.
19AA: DD 35 0F    dec  (ix+$0f)              ; decrement GROUND_OBJECT.ExplosionCounter
19AD: 28 10       jr   z,$19BF               ; if counter has reached zero, explosion has burnt itself out, goto GROUND_OBJECT_EXPLOSION_DONE

; keep explosion's Y coordinate in sync with landscape scroll.
19AF: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
19B2: A7          and  a
19B3: C0          ret  nz
19B4: DD 34 04    inc  (ix+$04)              ; increment GROUND_OBJECT.Y

; has the explosion scrolled off the screen?
19B7: DD 7E 04    ld   a,(ix+$04)
19BA: C6 14       add  a,$14
19BC: FE 08       cp   $08
19BE: D0          ret  nc

; Explosion's either burnt out or gone off screen. 
GROUND_OBJECT_EXPLOSION_DONE:
19BF: DD 36 02 03 ld   (ix+$02),$03          ; set GROUND_OBJECT.StageOfLife to 3 (GROUND_OBJECT_DELETE) to delete this object
19C3: C9          ret

19C4: C9          ret
19C5: C9          ret

; The rocket, fuel tank and MYSTERY are all cyclic animations with one frame of animation. 
GROUND_OBJECT_ROCKET_ANIMATION_TABLE:
19C6: 
    02 1C 10    ; colour = 02, code = $1C, delay = $10       
    FF          ; end of animation marker 
    C6 19       ; pointer to $19C6, GROUND_OBJECT_ROCKET_ANIMATION_TABLE 


GROUND_OBJECT_FUEL_TANK_ANIMATION_TABLE:
19CC: 
    02 10 10    ; colour = 02, code = $10, delay = $10    
    FF          ; end of animation marker  
    CC 19       ; pointer to $19CC, GROUND_OBJECT_FUEL_TANK_ANIMATION_TABLE  

GROUND_OBJECT_MYSTERY_ANIMATION_TABLE:
19D2: 
    02 33 10    ; colour = 02, code = $33, delay = $10 
    FF          ; end of animation marker  
    D2 19       ; pointer to $19D2, GROUND_OBJECT_MYSTERY_ANIMATION_TABLE 
    
GROUND_OBJECT_BASE_ANIMATION_TABLE:    
19D8:      
    00 2F 06    ; colour = 0, code = $2F, delay = $06
    00 26 06    ; colour = 0, code = $26, delay = $06   
    00 1F 06    ; colour = 0, code = $1F, delay = $06
    FF          ; end of animation marker 
    D8 19       ; pointer to $19D8, GROUND_OBJECT_BASE_ANIMATION_TABLE  




DEFAULT_EXPLOSION_ANIMATION_TABLE:
19E4: 
    02 38 10
    02 39 10 
    02 3A 10 
    02 3B 10 
    FF          ; end of animation marker   
    E4 19     
                

; Note how the fuel tank explosion animation (for when you hit unlaunched rockets) is identical to the default explosion animation above.
FUEL_TANK_EXPLOSION_ANIMATION_TABLE:
19F3:
    02 38 10    ; colour = 02, code = $38, delay = $10    
    02 39 10     
    02 3A 10 
    02 3B 10 
    FF          ; end of animation marker
    F3 19       ; pointer to $19F3, FUEL_TANK_EXPLOSION_ANIMATION_TABLE  


MYSTERY_100PTS_ANIMATION_TABLE:
1A02:
    02 11 50    ; colour = 02, code = $11, delay = $50 
    FF          ; end of animation marker 
    02 1A       ; pointer to $1A02, MYSTERY_100PTS_ANIMATION_TABLE 

; called by $0A78
1A08: C8          ret  z
1A09: C3 7B 0A    jp   $0A7B


; Animation table for "200PTS" displayed when Mystery shot
MYSTERY_200PTS_ANIMATION_TABLE:
1A0C:
    02 12 50    ; colour = 02, code = 12, delay = 50       
    FF          ; end of animation marker 
    0C 1A       ; pointer to $1A0C, MYSTERY_200PTS_ANIMATION_TABLE 

; Animation table for "300PTS" displayed when Mystery shot
MYSTERY_300PTS_ANIMATION_TABLE:
1A12:
    02 13 50    ; colour = 02, code = 13, delay = 50 
    FF          ; end of animation marker  
    12 1A       ; pointer to $1A12, MYSTERY_300PTS_ANIMATION_TABLE 


;
; Clear specified number of character rows and then increment SCRIPT_STAGE
; As the screen is rotated 90 degrees, it will appear as if a single column of characters is being cleared
; from right to left, one by one.
;
; value in TEMP_COUNTER_4009 = number of character rows left to clear 
; 

CLEAR_SCREEN_1A18:
1A18: 2A 0B 40    ld   hl,($400B)            ; read TEMP_CHAR_RAM_PTR
1A1B: 06 20       ld   b,$20                 ; number of characters per row
1A1D: 3E 10       ld   a,$10                 ; ordinal of character (space)
1A1F: D7          rst  $10                   ; fill memory
1A20: 22 0B 40    ld   ($400B),hl            ; update TEMP_CHAR_RAM_PTR
1A23: 21 09 40    ld   hl,$4009              ; load HL with address of TEMP_COUNTER_4009 
1A26: 35          dec  (hl)
1A27: C0          ret  nz
1A28: 2C          inc  l                     ; bump HL to point to SCRIPT_STAGE
1A29: 34          inc  (hl)                  ; increment SCRIPT_STAGE
1A2A: 21 E9 0A    ld   hl,$0AE9              ; load HL with address of COLOUR_ATTRIBUTE_TABLE_0AE9 
1A2D: C3 D9 0A    jp   $0AD9                 ; jump to SET_COLOUR_ATTRIBUTES_FOR_ENTIRE_SCREEN



PLAYER_BOMB_ANIMATION_AND_MOVEMENT:
; first, some protection code.. jump to $1A38 if not interested
1A30: 3E 41       ld   a,$41
1A32: 07          rlca
1A33: 67          ld   h,a
1A34: 2E 02       ld   l,$02                 ; make HL = $8202, IO port for protection chip  
1A36: 36 0F       ld   (hl),$0F              ; write to protection chip 
; end of protection code

1A38: DD 21 C0 43 ld   ix,$43C0              ; load IX with address of PLAYER_BOMBS array
1A3C: 11 20 00    ld   de,$0020              ; sizeof (PLAYER_BOMB)
1A3F: 06 02       ld   b,$02                 ; max number of player bombs on screen you can have
1A41: D9          exx
1A42: CD 4B 1A    call $1A4B                 ; call PLAYER_BOMB_STAGE_OF_LIFE
1A45: D9          exx
1A46: DD 19       add  ix,de
1A48: 10 F7       djnz $1A41
1A4A: C9          ret


;
; Expects:
; IX = pointer to PLAYER_BOMB struct
;
PLAYER_BOMB_STAGE_OF_LIFE:
1A4B: DD 7E 00    ld   a,(ix+$00)            ; read PLAYER_BOMB.IsActive flag 
1A4E: DD B6 01    or   (ix+$01)              ; combine with PLAYER_BOMB.IsExploding flag
1A51: 0F          rrca                       ; if either flags were set, carry flag will now be set
1A52: D0          ret  nc                    ; exit if bomb is neither active nor exploding.

; OK, we have a bomb that's either active or exploding. What stage of its "life" is it at?
; Jump to routine most appropriate for its stage of life.
1A53: DD 7E 02    ld   a,(ix+$02)      
1A56: EF          rst  $28
1A57: 
    6B 1A             ; $1A6B                ; PLAYER_BOMB_INIT
    94 1A             ; $1A94                ; PLAYER_BOMB_ANIMATE
    A8 1A             ; $1AA8                ; RET instruction
    A9 1A             ; $1AA9                ; RET instruction
    AA 1A             ; $1AAA                ; RET instruction 
    AB 1A             ; $1AAB                ; RET instruction
    AC 1A             ; $1AAC                ; PLAYER_BOMB_EXPLOSION_INIT
    C0 1A             ; $1AC0                ; PLAYER_BOMB_EXPLOSION_ANIMATE
    D6 1A             ; $1AD6                ; RET instruction
    D7 1A             ; $1AD7                ; RET instruction

PLAYER_BOMB_INIT:
; first position the bomb below the player jet
1A6B: 3A 83 43    ld   a,($4383)             ; read PLAYERS[0].X
1A6E: C6 04       add  a,$04
1A70: DD 77 03    ld   (ix+$03),a            ; set PLAYER_BOMB.X
1A73: 3A 84 43    ld   a,($4384)             ; read PLAYERS[0].Y
1A76: C6 08       add  a,$08
1A78: DD 77 04    ld   (ix+$04),a            ; set PLAYER_BOMB.Y

; define animation frames for bomb
1A7B: 21 D8 1A    ld   hl,$1AD8              ; load HL with address of PLAYER_BOMB_ANIMATION_TABLE
1A7E: DD 75 0C    ld   (ix+$0c),l            ; set PLAYER_BOMB.AnimPtrLo
1A81: DD 74 0D    ld   (ix+$0d),h            ; set PLAYER_BOMB.AnimPtrHi
1A84: DD 36 0E 00 ld   (ix+$0e),$00          ; set PLAYER_BOMB.AnimationCounter

; define flightpath of bomb
1A88: 21 FF 1A    ld   hl,$1AFF              ; load HL with address of PLAYER_BOMB_PATH
1A8B: DD 75 13    ld   (ix+$13),l            ; set PLAYER_BOMB.PathPtrLo
1A8E: DD 74 14    ld   (ix+$14),h            ; set PLAYER_BOMB.PathPtrHi
1A91: DD 34 02    inc  (ix+$02)              ; advance PLAYER_BOMB.StageOfLife


;
; Expects:
; IX = pointer to PLAYER_BOMB structure
;

PLAYER_BOMB_ANIMATE:
1A94: CD E4 13    call $13E4                 ; call ANIMATE
1A97: CD 78 15    call $1578                 ; call FOLLOW_PATH  

; has the bomb gone down the screen as far as it can?
1A9A: DD 7E 03    ld   a,(ix+$03)            ; read PLAYER_BOMB.X
1A9D: FE F0       cp   $F0                   
1A9F: D8          ret  c                     ; return if <#$F0   

; bomb's hit the ground. Make it explode!
1AA0: AF          xor  a
1AA1: DD 77 00    ld   (ix+$00),a            ; clear PLAYER_BOMB.IsActive 
1AA4: DD 77 01    ld   (ix+$01),a            ; clear PLAYER_BOMB.IsExploding
1AA7: C9          ret

1AA8: C9          ret
1AA9: C9          ret
1AAA: C9          ret
1AAB: C9          ret


;
; 
;
;

PLAYER_BOMB_EXPLOSION_INIT:
1AAC: 21 F0 1A    ld   hl,$1AF0             ; load HL with address of PLAYER_BOMB_EXPLOSION_ANIMATION_TABLE
1AAF: DD 75 0C    ld   (ix+$0c),l           ; write LSB to PLAYER_BOMB.AnimPtrLo 
1AB2: DD 74 0D    ld   (ix+$0d),h           ; write MSB to PLAYER_BOMB.AnimPtrLo 
1AB5: DD 36 0E 00 ld   (ix+$0e),$00         ; set PLAYER_BOMB.AnimationCounter
1AB9: DD 36 0F 23 ld   (ix+$0f),$23         ; set PLAYER_BOMB.ExplosionCounter
1ABD: DD 34 02    inc  (ix+$02)             ; advance to next stage of life


PLAYER_BOMB_EXPLOSION_ANIMATE:
1AC0: CD E4 13    call $13E4                 ; call ANIMATE
1AC3: DD 35 0F    dec  (ix+$0f)              ; decrement PLAYER_BOMB.ExplosionCounter
1AC6: 20 05       jr   nz,$1ACD              ; if counter hasn't reached zero goto CHECK_IF_PLAYER_BOMB_EXPLOSION_SHOULD_SCROLL_TOO       

; explosion animation has completed. 
1AC8: AF          xor  a
1AC9: DD 77 01    ld   (ix+$01),a            ; reset PLAYER_BOMB.IsExploding flag             
1ACC: C9          ret

; The only time a bomb explosion won't scroll off the screen is when the player jet is hit.
CHECK_IF_PLAYER_BOMB_EXPLOSION_SHOULD_SCROLL_TOO:
1ACD: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
1AD0: A7          and  a                     ; test if zero
1AD1: C0          ret  nz                    ; return if not

; Scroll the explosion off screen
1AD2: DD 34 04    inc  (ix+$04)              ; increment PLAYER_BOMB.Y
1AD5: C9          ret

1AD6: C9          ret

1AD7: C9          ret


PLAYER_BOMB_ANIMATION_TABLE:
1AD8: 
    06 21 04      ; colour = 06, code = 21, delay = 04     
    06 22 04          
    06 21 04          
    06 22 04          
    06 23 08          
    06 24 08          
    06 25 FE 
    FF            ; end of animation marker
    D8 1A         ; pointer to $1AD8, PLAYER_BOMB_ANIMATION_TABLE          

PLAYER_BOMB_EXPLOSION_ANIMATION_TABLE:
1AF0: 
    06 38 09      ; colour = 06, code = 38, delay = 09 
    06 39 09          
    06 3A 09          
    06 3B 09          
    FF            ; end of animation marker
    F0  1A        ; pointer to $1AF0, PLAYER_BOMB_EXPLOSION_ANIMATION_TABLE   


;
; This defines the path that a player bomb takes.
;
; See FOLLOW_PATH ($1578) for description of the table.
;

PLAYER_BOMB_PATH:
1AFF:  
    00 00         ; X delta = 0, Y delta = 0 
    01 00         ; X delta = 1, Y delta = 0  
    00 FF         ; X delta = 0, Y delta = -1 (remember, bytes are signed)
    ; .. you get the idea.. Now here's the rest of the deltas, from $1B05:
    00 FF 00 FF 00 FF 00 FF 00 FF
    00 FF 00 FF 00 FF 00 FF 00 FF 00 FF 00 FF 00 FF
    00 FF 01 FF 00 FF 00 FF 00 FF 01 FF 00 FF 00 FF
    01 FF 00 FF 01 FF 01 FF 00 FF 01 FF 01 FF 01 FF
    01 00 01 00 01 FF 01 FF 01 00 01 FF 01 00 01 FF
    01 00 01 00 01 FF 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00
    01 00 01 00 01 00
    80      ; marker byte specifying "end of path"
    FF 1A   ; pointer to $1AFF, PLAYER_BOMB_PATH - path repeats itself      


;
;
;
;
;

ROCKET_ANIMATION_AND_MOVEMENT:
; protection code: if not interested skip to $1CA7
1C98: 2A B9 40    ld   hl,($40B9)            ; read PROTECTION_PORT_PTR_1 
1C9B: 36 00       ld   (hl),$00              ; write to protection 
1C9D: 3E 12       ld   a,$12
1C9F: 0F          rrca
1CA0: 77          ld   (hl),a                ; write to protection
1CA1: 4E          ld   c,(hl)                ; read from protection
1CA2: 36 0A       ld   (hl),$0A              ; write to protection
1CA4: C6 FB       add  a,$FB
1CA6: 77          ld   (hl),a                ; write to protection
; end protection code

; Are we on a landscape with flying rockets?
1CA7: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
1CAA: A7          and  a                     ; are we on level 1?
1CAB: 28 03       jr   z,$1CB0               ; yes, goto $1CAB  
1CAD: FE 08       cp   $08                   ; are we on level 4?
1CAF: C0          ret  nz

; Call ROCKET_STAGE_OF_LIFE for each INFLIGHT_ENEMY
1CB0: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
1CB4: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
1CB7: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time 
1CB9: D9          exx
1CBA: CD C3 1C    call $1CC3                 ; call ROCKET_STAGE_OF_LIFE 
1CBD: D9          exx
1CBE: DD 19       add  ix,de                 ; bump IX to point to next INFLIGHT_ENEMY
1CC0: 10 F7       djnz $1CB9                 ; repeat until all rockets are done
1CC2: C9          ret




ROCKET_STAGE_OF_LIFE:
1CC3: DD 7E 00    ld   a,(ix+$00)            ; read INFLIGHT_ENEMY.IsActive flag
1CC6: DD B6 01    or   (ix+$01)              ; combine with INFLIGHT_ENEMY.IsExploding flag
1CC9: 0F          rrca                       ; move result into carry
1CCA: D0          ret  nc                    ; exit if neither active nor exploding

1CCB: DD 7E 02    ld   a,(ix+$02)
1CCE: EF          rst  $28
1CCF: 
    E3 1C         ; $1CE3  - ROCKET_INIT
    FC 1C         ; $1CFC  - ROCKET_ANIMATE
    28 1D         ; $1D28  - RET instruction
    29 1D         ; $1D29  - RET instruction
    2A 1D         ; $1D2A  - RET instruction
    2B 1D         ; $1D2B  - RET instruction
    2C 1D         ; $1D2C  - ROCKET_EXPLOSION_INIT
    40 1D         ; $1D40  - ROCKET_EXPLOSION_ANIMATE
    56 1D         ; $1D56  - RET instruction 
    57 1D         ; $1D57  - RET instruction

; Prepare to launch a rocket
ROCKET_INIT:
1CE3: 21 58 1D    ld   hl,$1D58              ; load HL with address of ROCKET_ANIMATION_TABLE
1CE6: DD 75 0C    ld   (ix+$0c),l            ; set INFLIGHT_ENEMY.AnimPtrLo
1CE9: DD 74 0D    ld   (ix+$0d),h            ; set INFLIGHT_ENEMY.AnimPtrHi
1CEC: DD 36 0E 00 ld   (ix+$0e),$00          ; set INFLIGHT_ENEMY.AnimationCounter
1CF0: 21 70 1D    ld   hl,$1D70              ; load HL with address of ROCKET_PATH
1CF3: DD 75 13    ld   (ix+$13),l            ; set INFLIGHT_ENEMY.PathPtrLo
1CF6: DD 74 14    ld   (ix+$14),h            ; set INFLIGHT_ENEMY.PathPtrHi
1CF9: DD 34 02    inc  (ix+$02)              ; advance to next stage of life.


ROCKET_ANIMATE:
1CFC: CD E4 13    call $13E4                 ; call ANIMATE
1CFF: CD 78 15    call $1578                 ; call FOLLOW_PATH
1D02: 3A 17 41    ld   a,($4117)             ; read LANDSCAPE_COLOUR
1D05: DD 77 16    ld   (ix+$16),a            ; ensure colour is in sync with player
1D08: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
1D0B: A7          and  a
1D0C: 20 03       jr   nz,$1D11
1D0E: DD 34 04    inc  (ix+$04)              ; increment INFLIGHT_ENEMY.Y - this will make the rocket scroll with the scenery 

; has the rocket gone off the left hand of screen (as player sees it)? 
1D11: DD 7E 04    ld   a,(ix+$04)            ; read INFLIGHT_ENEMY.Y 
1D14: FE F0       cp   $F0                   
1D16: 38 08       jr   c,$1D20               ; if Y < 240, rockets not gone off side of screen, goto $1D20

; rocket's gone off screen. Free up its slot in INFLIGHT_ENEMIES
1D18: AF          xor  a                     
1D19: DD 77 00    ld   (ix+$00),a            ; reset INFLIGHT_ENEMY.IsActive
1D1C: DD 77 01    ld   (ix+$01),a            ; reset INFLIGHT_ENEMY.IsExploding
1D1F: C9          ret

; has this rocket flown up screen as far as it can go?
1D20: DD 7E 03    ld   a,(ix+$03)            ; read INFLIGHT_ENEMY.X 
1D23: FE 28       cp   $28                   ; if X>=$28 (40 decimal) ..
1D25: D0          ret  nc                    ; .. don't do anything 

; rocket gone up screen as far as it can go, deactivate it
1D26: 18 F0       jr   $1D18            

1D28: C9          ret
1D29: C9          ret
1D2A: C9          ret
1D2B: C9          ret


ROCKET_EXPLOSION_INIT:
1D2C: 21 61 1D    ld   hl,$1D61              ; load HL with address of ROCKET_EXPLOSION_ANIMATION_TABLE
1D2F: DD 75 0C    ld   (ix+$0c),l            ; set INFLIGHT_ENEMY.AnimPtrLo
1D32: DD 74 0D    ld   (ix+$0d),h            ; set INFLIGHT_ENEMY.AnimPtrHi
1D35: DD 36 0E 00 ld   (ix+$0e),$00          ; set INFLIGHT_ENEMY.AnimationCounter  
1D39: DD 36 0F 3F ld   (ix+$0f),$3F          ; set INFLIGHT_ENEMY.ExplosionCounter  
1D3D: DD 34 02    inc  (ix+$02)              ; advance to next stage of life (ROCKET_EXPLOSION_ANIMATE)


ROCKET_EXPLOSION_ANIMATE:
1D40: CD E4 13    call $13E4                 ; call ANIMATE
1D43: DD 35 0F    dec  (ix+$0f)              ; decrement INFLIGHT_ENEMY.ExplosionCounter
1D46: 20 05       jr   nz,$1D4D              ; if explosion hasn't finished, goto $1D4D
1D48: AF          xor  a
1D49: DD 77 01    ld   (ix+$01),a            ; reset INFLIGHT_ENEMY.IsExploding to terminate the explosion
1D4C: C9          ret

; Check if we need to scroll the explosion in time with the landscape
1D4D: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
1D50: A7          and  a                     ; test if zero  
1D51: C0          ret  nz                    ; if not zero, then not time to scroll the rocket

; scroll exploding rocket off screen
1D52: DD 34 04    inc  (ix+$04)              ; increment INFLIGHT_ENEMY.Y 
1D55: C9          ret

1D56: C9          ret

1D57: C9          ret

ROCKET_ANIMATION_TABLE:
1D58: 
    00 1D 10    ; colour = 0, sprite code = $1D, delay before next frame = $10
    00 1E 10    ; colour = 0, sprite code = $1E, delay before next frame = $10
    FF          ; end of animation marker          
    58 1D       ; pointer to first animation ($1D58) - this animation is cyclic


ROCKET_EXPLOSION_ANIMATION_TABLE:
1D61: 
    06 38 05    ; colour = 6, sprite code = $38, delay before next frame = $05
    06 39 05          
    06 3A 05
    06 3B 05
    FF          ; end of animation marker   
    61 1D       ; pointer to first animation ($1D61) - this animation is cyclic  


; Rocket only flies straight up.
ROCKET_PATH:
1D70: 
    FF 00       ; XDelta = -1, YDelta = 0        
    80          ; end of path marker     
    70 1D       ; pointer to start ($1D70)      



UFO_ANIMATION_AND_MOVEMENT:
; Protection related code. If not interested, skip to $1D84
1D75: 3E 41       ld   a,$41
1D77: 07          rlca
1D78: 67          ld   h,a
1D79: 2E 02       ld   l,$02                 ; HL = $8202 (protection)
1D7B: 36 09       ld   (hl),$09              ; write to protection 
1D7D: 7E          ld   a,(hl)                ; read from protection
1D7E: E6 F0       and  $F0
1D80: FE B0       cp   $B0
1D82: 20 F1       jr   nz,$1D75
; end of protection code

; Are we on a landscape with UFOs?
1D84: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
1D87: FE 02       cp   $02                   ; are flags set for level 2 (UFOs) ?
1D89: C0          ret  nz                    ; exit if not 

; call UFO_STAGE_OF_LIFE for each INFLIGHT_ENEMY
1D8A: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
1D8E: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
1D91: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
1D93: D9          exx
1D94: CD 9D 1D    call $1D9D                 ; call UFO_STAGE_OF_LIFE
1D97: D9          exx
1D98: DD 19       add  ix,de                 ; bump IX to point to next INFLIGHT_ENEMY
1D9A: 10 F7       djnz $1D93
1D9C: C9          ret


; Expects:
; IX = pointer to INFLIGHT_ENEMY structure
; 

UFO_STAGE_OF_LIFE:
1D9D: DD 7E 00    ld   a,(ix+$00)            ; read INFLIGHT_ENEMY.IsActive flag
1DA0: DD B6 01    or   (ix+$01)              ; OR with INFLIGHT_ENEMY.IsExploding flag
1DA3: 0F          rrca                       ; move result into carry
1DA4: D0          ret  nc                    ; exit if ufo is neither active nor exploding

1DA5: DD 7E 02    ld   a,(ix+$02)            ; read INFLIGHT_ENEMY.StageOfLife
1DA8: EF          rst  $28

1DA9: 
    BD 1D         ; $1DBD - UFO_INIT          
    D6 1D         ; $1DD6 - UFO_AND_FIREBALL_ANIMATE
    EA 1D         ; $1DEA - RET instruction
    EB 1D         ; $1DEB - RET instruction
    EC 1D         ; $1DEC - RET instruction
    ED 1D         ; $1DED - RET instruction
    EE 1D         ; $1DEE - UFO_AND_FIREBALL_EXPLOSION_INIT
    02 1E         ; $1E02 - UFO_AND_FIREBALL_EXPLOSION_ANIMATE
    18 1E         ; $1E18 - RET instruction
    19 1E         ; $1E19 - RET instruction

UFO_INIT:    
1DBD: 21 1A 1E    ld   hl,$1E1A              ; load HL with address of UFO_ANIMATION_TABLE
1DC0: DD 75 0C    ld   (ix+$0c),l            ; set INFLIGHT_ENEMY.AnimPtrLo 
1DC3: DD 74 0D    ld   (ix+$0d),h            ; set INFLIGHT_ENEMY.AnimPtrHi
1DC6: DD 36 0E 00 ld   (ix+$0e),$00          ; set INFLIGHT_ENEMY.AnimationCounter
1DCA: 21 2F 1E    ld   hl,$1E2F              ; load HL with address of UFO_PATH
1DCD: DD 75 13    ld   (ix+$13),l            ; set INFLIGHT_ENEMY.PathPtrLo
1DD0: DD 74 14    ld   (ix+$14),h            ; set INFLIGHT_ENEMY.PathPtrHi
1DD3: DD 34 02    inc  (ix+$02)              ; advance to next stage of life

UFO_AND_FIREBALL_ANIMATE:
1DD6: CD E4 13    call $13E4                 ; call ANIMATE
1DD9: CD 78 15    call $1578                 ; call FOLLOW_PATH

; has this entity gone offscreen?
1DDC: DD 7E 04    ld   a,(ix+$04)            ; read INFLIGHT_ENEMY.Y          
1DDF: FE F0       cp   $F0                   
1DE1: D8          ret  c                     ; if Y < 240, UFO/fireball has not gone off side of screen

; entity has gone off screen, deactivate it.
1DE2: AF          xor  a
1DE3: DD 77 00    ld   (ix+$00),a            ; reset INFLIGHT_ENEMY.IsActive            
1DE6: DD 77 01    ld   (ix+$01),a            ; reset INFLIGHT_ENEMY.IsExploding
1DE9: C9          ret

1DEA: C9          ret

1DEB: C9          ret

1DEC: C9          ret

1DED: C9          ret

;
;
;
;
;

UFO_AND_FIREBALL_EXPLOSION_INIT:
1DEE: 21 20 1E    ld   hl,$1E20              ; load HL with address of UFO_EXPLOSION_ANIMATION_TABLE
1DF1: DD 75 0C    ld   (ix+$0c),l            ; set INFLIGHT_ENEMY.AnimPtrLo
1DF4: DD 74 0D    ld   (ix+$0d),h            ; set INFLIGHT_ENEMY.AnimPtrHi
1DF7: DD 36 0E 00 ld   (ix+$0e),$00          ; set INFLIGHT_ENEMY.AnimationCounter
1DFB: DD 36 0F 2B ld   (ix+$0f),$2B          ; set INFLIGHT_ENEMY.ExplosionCounter
1DFF: DD 34 02    inc  (ix+$02)              ; increment INFLIGHT_ENEMY.StageOfLife to UFO_AND_FIREBALL_EXPLOSION_ANIMATE


UFO_AND_FIREBALL_EXPLOSION_ANIMATE:
1E02: CD E4 13    call $13E4                 ; call ANIMATE 
1E05: DD 35 0F    dec  (ix+$0f)              ; decrement INFLIGHT_ENEMY.ExplosionCounter
1E08: 20 05       jr   nz,$1E0F              ; if counter hasn't reached zero goto CHECK_IF_PLAYER_BOMB_EXPLOSION_SHOULD_SCROLL_TOO 

; explosion animation has completed.
1E0A: AF          xor  a
1E0B: DD 77 01    ld   (ix+$01),a            ; reset INFLIGHT_ENEMY.IsExploding flag  
1E0E: C9          ret

; If the player's hit, don't scroll the UFO explosion off screen.
CHECK_IF_UFO_EXPLOSION_SHOULD_SCROLL_TOO:
1E0F: 3A 15 41    ld   a,($4115)             ; read LANDSCAPE_SCROLL_CONTROL_COUNTER
1E12: A7          and  a                     ; test if zero
1E13: C0          ret  nz                    ; return if not

; Scroll the explosion off screen
1E14: DD 34 04    inc  (ix+$04)              ; increment INFLIGHT_ENEMY.Y
1E17: C9          ret

1E18: C9          ret

1E19: C9          ret


; The poor UFO only has one animation frame!
UFO_ANIMATION_TABLE:
1E1A: 
    05 1A 10      ; colour 5, sprite code = $1A, delay before frame change = $10 
    FF            ; end of animation marker     
    1A 1E         ; pointer to first animation ($1E1A) - this animation is cyclic   


UFO_EXPLOSION_ANIMATION_TABLE:
1E20:
    04 38 0B      ; colour 4, sprite code = $38, delay before frame change = $0B      
    04 39 0B          
    04 3A 0B 
    04 3B 0B          
    FF            ; end of animation marker           
    20 1E         ; pointer to first animation of this table ($1E20) - this animation is cyclic   


UFO_PATH:
1E2F: 
    FF 00         ; XDelta = -1, YDelta = 0          
    FE 00         ; XDelta = -2, YDelta = 0
    FE 00       
    FE 00 FE 00 FE 00 FE 00 FE 00 FE 00 FE 02 FE 00
    FE 02 FE 00 FE 02 FE 02 FE 02 FE 02 00 02 00 02
    02 02 02 02 02 02 02 02 02 02 02 02 02 00 02 02
    02 00 02 02 02 00 02 02 02 00 02 00 02 00 02 00
    02 00 02 02 02 00 02 00 02 00 02 02 02 00 02 00
    02 00 02 00 02 02 02 00 02 02 02 00 02 00 02 02
    02 02 02 02 00 02 00 02 00 02 FE 02 FE 02 FE 02
    FE 02 FE 00 FE 02 FE 00 FE 02 FE 00 FE 02 FE 00
    FE 02 FE 00 FE 00 FE 00 FE 00 FE 00 FE 00 
1EC3:
    80       ; marker byte specifying "end of path"    
    2F 1E    ; pointer to $1E2F, UFO_PATH     


; Are we on a landscape with fireballs?
FIREBALL_ANIMATION_AND_MOVEMENT:
1EC6:             ld   a,($411D)             ; read LANDSCAPE_FLAGS
1EC9: FE 01       cp   $01
1ECB: C0          ret  nz

; call FIREBALL_STAGE_OF_LIFE for each INFLIGHT_ENEMY
1ECC: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
1ED0: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
1ED3: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
1ED5: D9          exx
1ED6: CD DF 1E    call $1EDF                 ; call FIREBALL_STAGE_OF_LIFE
1ED9: D9          exx
1EDA: DD 19       add  ix,de                 ; bump IX to point to next INFLIGHT_ENEMY structure
1EDC: 10 F7       djnz $1ED5                 ; repeat until b==0
1EDE: C9          ret


;
; Expects: 
; IX = pointer to INFLIGHT_ENEMY structure
;

FIREBALL_STAGE_OF_LIFE:
1EDF: DD 7E 00    ld   a,(ix+$00)            ; read INFLIGHT_ENEMY.IsActive flag
1EE2: DD B6 01    or   (ix+$01)              ; combine with INFLIGHT_ENEMY.IsExploding flag
1EE5: 0F          rrca                       ; move result into carry
1EE6: D0          ret  nc                    ; exit if neither active nor exploding

1EE7: DD 7E 02    ld   a,(ix+$02)
1EEA: EF          rst  $28
1EEB: 
    FF 1E         ; $1EFF - FIREBALL_INIT
    D6 1D         ; $1DD6 - UFO_AND_FIREBALL_ANIMATE 
    EA 1D         ; $1DEA - RET instruction
    EB 1D         ; $1DEB - RET instruction
    EC 1D         ; $1DEC - RET instruction
    ED 1D         ; $1DED - RET instruction       
    EE 1D         ; $1DEE - UFO_AND_FIREBALL_EXPLOSION_INIT
    02 1E         ; $1E02 - UFO_AND_FIREBALL_EXPLOSION_ANIMATE 
    18 1E         ; $1E18 - RET instruction
    19 1E         ; $1E19 - RET instruction
    
FIREBALL_INIT:    
1EFF: 21 1B 1F    ld   hl,$1F1B              ; load HL with address of FIREBALL_ANIMATION_TABLE
1F02: DD 75 0C    ld   (ix+$0c),l            ; set INFLIGHT_ENEMY.AnimPtrLo 
1F05: DD 74 0D    ld   (ix+$0d),h            ; set INFLIGHT_ENEMY.AnimPtrHi
1F08: DD 36 0E 00 ld   (ix+$0e),$00          ; set INFLIGHT_ENEMY.AnimationCounter
1F0C: 21 30 1F    ld   hl,$1F30              ; load HL with address of FIREBALL_PATH
1F0F: DD 75 13    ld   (ix+$13),l            ; set INFLIGHT_ENEMY.PathPtrLo  
1F12: DD 74 14    ld   (ix+$14),h            ; set INFLIGHT_ENEMY.PathPtrHi
1F15: DD 34 02    inc  (ix+$02)              ; advance to next stage of life (which is UFO_AND_FIREBALL_ANIMATE)
1F18: C3 D6 1D    jp   $1DD6                 ; jump to UFO_AND_FIREBALL_ANIMATE


FIREBALL_ANIMATION_TABLE:
1F1B: 
    00 35 05       ; colour 9, sprite code = $35, delay before frame change = $05   
    00 36 05       
    00 37 05
    00 30 05       
    00 37 05       
    00 36 05       
    FF             ; end of animation marker     
    1B 1F          ; pointer to first animation of this table ($1F1B) - this animation is cyclic


FIREBALL_PATH:
1F30: 
    00 04     ; XDelta = 0, YDelta = 4
    80        ; end of path marker  
    30 1F     ; pointer to start of path ($1F30)  


;
; Handle the scrolling and positioning/colour of sprites. 
;
;

SCROLL_AND_SPRITES:
1F35: CD 44 1F    call $1F44                 ; call SET_PLAYFIELD_SCROLL_OFFSET_AND_COLOUR_ATTRIBUTES
1F38: CD 59 1F    call $1F59                 ; call MAP_GROUND_OBJECTS_TO_CHAR_BASED_GROUND_OBJECTS
1F3B: CD 8A 1F    call $1F8A                 ; call SET_PLAYER_JET_SPRITE_POS_CODE_COLOUR
1F3E: CD 94 1F    call $1F94                 ; call SET_INFLIGHT_ENEMIES_SPRITE_POS_CODE_COLOUR
1F41: C3 E3 1F    jp   $1FE3                 ; jump to SET_BULLETS_SPRITE_POSITIONS


;
; Sets the scroll offsets and colour attributes for the playfield only. 
;

SET_PLAYFIELD_SCROLL_OFFSET_AND_COLOUR_ATTRIBUTES:
1F44: 21 2A 40    ld   hl,$402A              ; pointer to scroll offset in OBJRAM_BACK_BUF
1F47: 06 19       ld   b,$19
1F49: 3A 16 41    ld   a,($4116)             ; read LANDSCAPE_SCROLL_COUNTER
1F4C: ED 44       neg
1F4E: 4F          ld   c,a
1F4F: 3A 17 41    ld   a,($4117)             ; read LANDSCAPE_COLOUR
1F52: 71          ld   (hl),c                ; set scroll offset 
1F53: 2C          inc  l
1F54: 77          ld   (hl),a                ; set colour attribute
1F55: 2C          inc  l
1F56: 10 FA       djnz $1F52
1F58: C9          ret


;
;
; The GROUND_OBJECT is the main structure but CHAR_BASED_GROUND_OBJECT is its representation on screen.
; We need to "project" data from GROUND_OBJECT into a CHAR_BASED_GROUND_OBJECT so that the game can 
; render the ground objects properly.
;
; Tech note: A projection is taking a structure and mapping it to a different structure.
; See: https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/projection-operations
;
;

MAP_GROUND_OBJECTS_TO_CHAR_BASED_GROUND_OBJECTS:
1F59: 21 60 42    ld   hl,$4260              ; address of CHAR_BASED_GROUND_OBJECTS array
1F5C: DD 21 80 42 ld   ix,$4280              ; address of GROUND_OBJECTS array
1F60: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
1F63: 06 08       ld   b,$08                 ; max number of ground objects on screen at one time
1F65: CD 6D 1F    call $1F6D                 ; call MAP_GROUND_OBJECT_TO_CHAR_BASED_GROUND_OBJECT
1F68: DD 19       add  ix,de                 ; bump IX to point to next GROUND_OBJECT
1F6A: 10 F9       djnz $1F65                 ; repeat until all GROUND_OBJECTS are done
1F6C: C9          ret



; HL = pointer to target CHAR_BASED_GROUND_OBJECT structure
; IX = pointer to source GROUND_OBJECT structure
MAP_GROUND_OBJECT_TO_CHAR_BASED_GROUND_OBJECT:
1F6D: DD 7E 00    ld   a,(ix+$00)            ; read GROUND_OBJECT.IsActive
1F70: DD B6 01    or   (ix+$01)              ; combine with GROUND_OBJECT.IsExploding
1F73: 0F          rrca                       
1F74: 36 00       ld   (hl),$00              ; reset CHAR_BASED_GROUND_OBJECT.Undrawn flag
1F76: D0          ret  nc                    ; exit if ground object is not active or exploding

1F77: 36 01       ld   (hl),$01              ; set CHAR_BASED_GROUND_OBJECT.Undrawn flag                    
1F79: 2C          inc  l
1F7A: DD 7E 12    ld   a,(ix+$12)            ; read GROUND_OBJECT.Code  
1F7D: 77          ld   (hl),a                ; set CHAR_BASED_GROUND_OBJECT.Code
1F7E: 2C          inc  l
1F7F: DD 7E 18    ld   a,(ix+$18)            ; read GROUND_OBJECT.CharRamPtrLo
1F82: 77          ld   (hl),a                ; set CHAR_BASED_GROUND_OBJECT.CharRamPtrLo
1F83: 2C          inc  l
1F84: DD 7E 19    ld   a,(ix+$19)            ; read GROUND_OBJECT.CharRamPtrHi
1F87: 77          ld   (hl),a                ; set CHAR_BASED_GROUND_OBJECT.CharRamPtrHi
1F88: 2C          inc  l
1F89: C9          ret


;
; Set the position and colour of the player jet and player bomb sprites.
;
SET_PLAYER_JET_AND_BOMBS_SPRITE_POS_CODE_COLOUR:
1F8A: DD 21 80 43 ld   ix,$4380              ; load IX with address of PLAYER 
1F8E: FD 21 60 40 ld   iy,$4060              ; load IY with address of OBJRAM_BACK_BUF_SPRITES
1F92: 18 12       jr   $1FA6                 ; jump to SET_SPRITE_POS_CODE_COLOUR 


SET_INFLIGHT_ENEMIES_SPRITE_POS_CODE_COLOUR:
1F94: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
1F98: FD 21 70 40 ld   iy,$4070              ; pointer to sprite in OBJRAM_BACK_BUF_SPRITES
1F9C: 18 08       jr   $1FA6                 ; jump to SET_SPRITE_POS_CODE_COLOUR

; Unsure if this code is called.
1F9E: DD 21 80 44 ld   ix,$4480
1FA2: FD 21 70 40 ld   iy,$4070              ; pointer inside OBJRAM_BACK_BUF_SPRITES


;
; Set the position, code (animation frame) and colour of a sprite.
;
; IX = pointer to PLAYER or INFLIGHT_ENEMY structure.
; IY = pointer to a SPRITE structure in OBJRAM_BACK_BUF_SPRITES
;

SET_SPRITE_POS_CODE_COLOUR:
1FA6: 01 08 04    ld   bc,$0408              ; B = 4 (number of sprites to set position and colour), C =8 
1FA9: DD 7E 00    ld   a,(ix+$00)            ; read Active flag
1FAC: DD B6 01    or   (ix+$01)              ; OR with Dying/Exploding flag
1FAF: 0F          rrca                       ; move result into carry
1FB0: 30 27       jr   nc,$1FD9              ; if entity is neither active or dying/exploding, goto $1FD9

; entity is active or exploding, so sprite needs to be setup with correct position, colour and animation frame (code).
1FB2: DD 7E 16    ld   a,(ix+$16)            ; read sprite colour value
1FB5: FD 77 02    ld   (iy+$02),a            ; write to SPRITE.Colour
1FB8: DD 7E 03    ld   a,(ix+$03)            ; read X coordinate
1FBB: 91          sub  c                     ; subtract 8 
1FBC: FD 77 03    ld   (iy+$03),a            ; write to SPRITE.X
1FBF: DD 7E 04    ld   a,(ix+$04)            ; read Y coordinate   
1FC2: 2F          cpl                        ; flip bits
1FC3: 91          sub  c                     ; subtract 8
1FC4: FD 77 00    ld   (iy+$00),a            ; write to SPRITE.Y
1FC7: DD 7E 12    ld   a,(ix+$12)            ; read sprite code
1FCA: FD 77 01    ld   (iy+$01),a            ; write to SPRITE.Code
1FCD: 11 20 00    ld   de,$0020                  
1FD0: DD 19       add  ix,de
1FD2: 1E 04       ld   e,$04                 ; sizeof(SPRITE)
1FD4: FD 19       add  iy,de                 ; bump to next SPRITE record
1FD6: 10 D1       djnz $1FA9                 ; repeat until 4 sprites done
1FD8: C9          ret

; if the entity is not active then place its sprite offscreen.
1FD9: FD 36 00 F8 ld   (iy+$00),$F8
1FDD: FD 36 03 F8 ld   (iy+$03),$F8
1FE1: 18 EA       jr   $1FCD



;
;
; Position sprites for all player bullets.
;
;

SET_BULLETS_SPRITE_POSITIONS:
1FE3: DD 21 80 40 ld   ix,$4080              ; load IX with address of OBJRAM_BACK_BUF_BULLETS
1FE7: FD 21 00 45 ld   iy,$4500              ; load IY with address of PLAYER_BULLETS
1FEB: 06 07       ld   b,$07
1FED: CD FB 1F    call $1FFB
1FF0: 11 04 00    ld   de,$0004              ; sizeof(BULLET_SPRITE)
1FF3: DD 19       add  ix,de
1FF5: 1D          dec  e                     ; set DE to be 3, which is sizeof(PLAYER_BULLET)
1FF6: FD 19       add  iy,de                 ; bump IY to point to next PLAYER_BULLET
1FF8: 10 F3       djnz $1FED
1FFA: C9          ret


; IX = pointer to BULLET_SPRITE structure
; IY = pointer to PLAYER_BULLET structure
1FFB: FD CB 00 46 bit  0,(iy+$00)            ; test PLAYER_BULLET.IsActive flag
1FFF: 28 23       jr   z,$2024               ; if bullet is not active
2001: FD 7E 02    ld   a,(iy+$02)            ; read PLAYER_BULLET.Y
2004: 2F          cpl
2005: DD 77 01    ld   (ix+$01),a            ; set BULLET_SPRITE.Y
2008: FD 7E 01    ld   a,(iy+$01)            ; read PLAYER_BULLET.X
200B: C6 05       add  a,$05                 ; add 5 to value to get real X coordinate
200D: DD 77 03    ld   (ix+$03),a            ; set BULLET_SPRITE.X
2010: 3A 0F 40    ld   a,($400F)             ; read IS_COCKTAIL flag
2013: 0F          rrca                       ; move flag into carry
2014: 30 06       jr   nc,$201C              ; if not a cocktail cabinet goto $201C

; cocktail cabinet
2016: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER                          
2019: 0F          rrca                       ; carry will be set if PLAYER TWO is playing
201A: 38 11       jr   c,$202D               ; if player two is playing, 

; must be a hardware quirk that requires bullet X coordinate to be flipped?
201C: DD 7E 03    ld   a,(ix+$03)            ; read BULLET_SPRITE.X 
201F: 2F          cpl                        ; X = 255 - X
2020: DD 77 03    ld   (ix+$03),a            ; update BULLET_SPRITE.X
2023: C9          ret

; Player bullet is not active, so position bullet sprite offscreen.
2024: DD 36 01 00 ld   (ix+$01),$00          ; set BULLET_SPRITE.Y 
2028: DD 36 03 00 ld   (ix+$03),$00          ; set BULLET_SPRITE.X
202C: C9          ret

; Called when IS_COCKTAIL is true and PLAYER TWO playing.
202D: DD 7E 03    ld   a,(ix+$03)
2030: D6 0D       sub  $0D
2032: DD 77 03    ld   (ix+$03),a
2035: C9          ret


; !IMPORTANT ROUTINE!
; Handles all collision detection in the game.
;

COLLISION_DETECTION:
2036: CD 5E 20    call $205E                 ; call PLAYER_TO_UFO_COLLISION_DETECTION
2039: CD C2 20    call $20C2                 ; call PLAYER_TO_FIREBALL_COLLISION_DETECTION
203C: CD DE 20    call $20DE                 ; call PLAYER_TO_GROUND_OBJECT_COLLISION_DETECTION
203F: CD F4 20    call $20F4                 ; call PLAYER_TO_ROCKET_COLLISION_DETECTION
2042: CD 13 21    call $2113                 ; call PLAYER_TO_LANDSCAPE_COLLISION_DETECTION
2045: CD 66 21    call $2166                 ; call PLAYER_BULLET_TO_UFO_COLLISION_DETECTION
2048: CD 17 22    call $2217                 ; call PLAYER_BULLET_TO_GROUND_OBJECT_COLLISION_DETECTION
204B: CD D6 22    call $22D6                 ; call PLAYER_BULLET_TO_ROCKET_COLLISION_DETECTION
204E: CD 8F 23    call $238F                 ; call PLAYER_BULLET_TO_LANDSCAPE_COLLISION_DETECTION
2051: CD C9 23    call $23C9                 ; call PLAYER_BOMB_TO_UFO_COLLISION_DETECTION
2054: CD 34 24    call $2434                 ; call PLAYER_BOMB_TO_GROUND_OBJECT_COLLISION_DETECTION
2057: CD 94 24    call $2494                 ; call PLAYER_BOMB_TO_ROCKET_COLLISION_DETECTION
205A: CD 1E 25    call $251E                 ; call PLAYER_BOMB_TO_LANDSCAPE_COLLISION_DETECTION
205D: C9          ret


PLAYER_TO_UFO_COLLISION_DETECTION:
205E: 3A 80 43    ld   a,($4380)             ; read PLAYERS[0].IsActive flag
2061: 0F          rrca                       ; move flag into carry
2062: D0          ret  nc                    ; return if player is not active
2063: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
2066: FE 02       cp   $02                   ; are UFOs on this level?
2068: C0          ret  nz                    ; exit if not

2069: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
206D: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
2070: 06 04       ld   b,$04                 ; max number of UFOs on screen at one time
2072: CD 7A 20    call $207A                 ; call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT
2075: DD 19       add  ix,de
2077: 10 F9       djnz $2072
2079: C9          ret


; Check if the player jet has collided with an inflight enemy or a ground object.
;
; Expects:
; IX = pointer to INFLIGHT_ENEMY or GROUND_OBJECT structure
; 

CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT:
207A: DD CB 00 46 bit  0,(ix+$00)
207E: C8          ret  z
207F: 21 83 43    ld   hl,$4383              ; load HL with address of PLAYERS[0].X
2082: 7E          ld   a,(hl)                ; read PLAYERS[0].X 
2083: DD 96 03    sub  (ix+$03)              
2086: C6 06       add  a,$06
2088: FE 0D       cp   $0D
208A: D0          ret  nc
208B: 2C          inc  l                     ; bump HL to point to PLAYERS[0].Y
208C: 7E          ld   a,(hl)                ; read PLAYERS[0].Y
208D: C6 04       add  a,$04
208F: DD 96 04    sub  (ix+$04)
2092: C6 0D       add  a,$0D
2094: FE 19       cp   $19
2096: D0          ret  nc

; Player jet has hit an inflight enemy or ground object
2097: DD CB 00 86 res  0,(ix+$00)            ; clear IsActive flag
209B: DD CB 01 C6 set  0,(ix+$01)            ; set IsExploding flag  
209F: DD 36 02 06 ld   (ix+$02),$06
20A3: 2D          dec  l
20A4: 2D          dec  l                     ; bump HL to point to PLAYER_ONE.StageOfLife
20A5: 36 06       ld   (hl),$06              ; set stage of life to 6 (PLAYER_EXPLOSION_INIT)
20A7: 2D          dec  l
20A8: 36 01       ld   (hl),$01              ; set PLAYER_ONE.IsExploding 
20AA: 2D          dec  l
20AB: 36 00       ld   (hl),$00              ; reset PLAYER_ONE.IsActive
20AD: 21 A0 43    ld   hl,$43A0              ; load HL with address of PLAYER_TWO  
20B0: 36 00       ld   (hl),$00              ; reset PLAYER_TWO.IsActive
20B2: 2C          inc  l
20B3: 36 01       ld   (hl),$01              ; set PLAYER_TWO.IsExploding flag
20B5: DD 36 17 00 ld   (ix+$17),$00			 ; set GROUND_OBJECT.ObjectType to 0, so that player doesn't get points for crashing into object (thanks Mark)
20B9: 3E FF       ld   a,$FF
20BB: 32 15 41    ld   ($4115),a             ; set LANDSCAPE_SCROLL_CONTROL_COUNTER
20BE: CD F3 28    call $28F3                 ; call QUEUE_PLAYER_HIT_OBJECT_SOUND
20C1: C9          ret



PLAYER_TO_FIREBALL_COLLISION_DETECTION:
20C2: 3A 80 43    ld   a,($4380)             ; read PLAYERS[0].IsActive flag
20C5: 0F          rrca                       ; move flag into carry
20C6: D0          ret  nc                    ; return if player is not active   
20C7: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
20CA: FE 01       cp   $01                   ; are fireballs on this level?
20CC: C0          ret  nz                    ; exit if not

; Call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT for each INFLIGHT_ENEMY
20CD: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
20D1: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
20D4: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
20D6: CD 7A 20    call $207A                 ; call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT
20D9: DD 19       add  ix,de
20DB: 10 F9       djnz $20D6
20DD: C9          ret



PLAYER_TO_GROUND_OBJECT_COLLISION_DETECTION:
20DE: 3A 80 43    ld   a,($4380)             ; read PLAYERS[0].IsActive flag 
20E1: 0F          rrca                       ; move flag into carry
20E2: D0          ret  nc                    ; return if player is not active

; Call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT for each GROUND_OBJECT
20E3: DD 21 80 42 ld   ix,$4280              ; load HL with address of GROUND_OBJECTS
20E7: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
20EA: 06 08       ld   b,$08                 ; maximum of 8 ground objects on screen
20EC: CD 7A 20    call $207A                 ; call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT
20EF: DD 19       add  ix,de
20F1: 10 F9       djnz $20EC
20F3: C9          ret



PLAYER_TO_ROCKET_COLLISION_DETECTION:
20F4: 3A 80 43    ld   a,($4380)             ; read PLAYERS[0].IsActive flag
20F7: 0F          rrca                       ; move flag into carry
20F8: D0          ret  nc                    ; return if player is not active 

; are we on a rocket level?
20F9: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
20FC: A7          and  a                     ; is this level 1, can rockets attack the player? 
20FD: 28 03       jr   z,$2102
20FF: FE 08       cp   $08                   ; is this level 4, can rockets attack the player?
2101: C0          ret  nz

; Call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT for each INFLIGHT_ENEMY
2102: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
2106: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
2109: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
210B: CD 7A 20    call $207A                 ; call CHECK_IF_PLAYER_COLLIDED_WITH_OBJECT
210E: DD 19       add  ix,de
2110: 10 F9       djnz $210B
2112: C9          ret




PLAYER_TO_LANDSCAPE_COLLISION_DETECTION:
2113: 3A 80 43    ld   a,($4380)             ; read PLAYERS[0].IsActive flag
2116: 0F          rrca                       ; move flag into carry
2117: D0          ret  nc                    ; return if player is not active

2118: 3A 16 41    ld   a,($4116)             ; read LANDSCAPE_SCROLL_COUNTER
211B: 47          ld   b,a

; get Y coordinate of jet (horizontal as player sees it) and use it to compute the first LANDSCAPE_EXTENT record to check player's X position against. 
211C: 3A 84 43    ld   a,($4384)             ; read PLAYERS[0].Y
211F: D6 04       sub  $04
2121: 90          sub  b
2122: E6 F8       and  $F8
2124: 0F          rrca
2125: 0F          rrca
2126: C6 C0       add  a,$C0                 
2128: 6F          ld   l,a
2129: 26 41       ld   h,$41                 ; HL is now a pointer into LANDSCAPE_EXTENTS array

; get X coordinate of jet (vertical as player sees it)
212B: 06 03       ld   b,$03                 ; jet body is 3 characters wide. 
212D: 3A 83 43    ld   a,($4383)             ; read PLAYERS[0].X

2130: C6 03       add  a,$03                 
2132: 5F          ld   e,a                   ; E = PLAYERS[0].X+3
2133: D6 06       sub  $06    
2135: 57          ld   d,a                   ; D = PLAYERS[0].X-3

; Check if jet is within height parameters.   
2136: 7E          ld   a,(hl)                ; read LANDSCAPE_EXTENT.GroundX
2137: BB          cp   e                     ;  
2138: 38 10       jr   c,$214A               ; if E > ground pixel height then player jet has hit the ground. Goto KILL_PLAYER
213A: 2C          inc  l
213B: 7E          ld   a,(hl)                ; read LANDSCAPE_EXTENT.CeilingX 
213C: BA          cp   d                      
213D: 30 0B       jr   nc,$214A              ; if D <= ceiling pixel height then player jet has hit the ceiling. Goto KILL_PLAYER
213F: 2C          inc  l
2140: 28 03       jr   z,$2145               ; if HL = $4200 then the end of the LANDSCAPE_EXTENTS array has been reached.
2142: 10 F2       djnz $2136                 ; Working from nose of jet backwards to the tail, repeat until 3 characters worth of space has been checked for collision. 
2144: C9          ret

; Reset HL to point to start of LANDSCAPE_EXTENTS array
2145: 2E C0       ld   l,$C0                 ; LSB of LANDSCAPE_EXTENTS array address
2147: 10 ED       djnz $2136
2149: C9          ret


KILL_PLAYER:
214A: 21 80 43    ld   hl,$4380              ; load HL with address of PLAYER_ONE             
214D: 36 00       ld   (hl),$00              ; reset PLAYERS[0].IsActive
214F: 2C          inc  l
2150: 36 01       ld   (hl),$01              ; set PLAYERS[0].IsExploding
2152: 2C          inc  l
2153: 36 06       ld   (hl),$06              ; set PLAYERS[0].StageOfLife
2155: 21 A0 43    ld   hl,$43A0              ; load HL with address of PLAYER_TWO
2158: 36 00       ld   (hl),$00              ; reset PLAYERS[1].IsActive
215A: 2C          inc  l
215B: 36 01       ld   (hl),$01              ; set PLAYERS[1].IsExploding
215D: 3E FF       ld   a,$FF
215F: 32 15 41    ld   ($4115),a             ; set LANDSCAPE_SCROLL_CONTROL_COUNTER
2162: CD F3 28    call $28F3                 ; call QUEUE_PLAYER_HIT_OBJECT_SOUND
2165: C9          ret



PLAYER_BULLET_TO_UFO_COLLISION_DETECTION:
2166: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
2169: FE 02       cp   $02                   ; are UFOs enabled?
216B: C0          ret  nz                    ; exit if not.
216C: FD 21 00 45 ld   iy,$4500              ; load IY with address of PLAYER_BULLETS array
2170: 06 04       ld   b,$04                 ; max number of bullets on screen.
2172: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY) 
2175: CD 81 21    call $2181                 ; call CHECK_IF_PLAYER_BULLET_HIT_UFOS
2178: FD 23       inc  iy
217A: FD 23       inc  iy
217C: FD 23       inc  iy                    ; bump IY to point to next PLAYER_BULLET structure
217E: 10 F5       djnz $2175
2180: C9          ret


; IY = pointer to PLAYER_BULLET structure
CHECK_IF_PLAYER_BULLET_HIT_UFOS:
2181: FD CB 00 46 bit  0,(iy+$00)            ; test PLAYER_BULLET.IsActive flag
2185: C8          ret  z                     ; return if player bullet is not active
2186: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
218A: 0E 04       ld   c,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
218C: D9          exx
218D: CD 97 21    call $2197
2190: D9          exx
2191: DD 19       add  ix,de
2193: 0D          dec  c
2194: 20 F6       jr   nz,$218C
2196: C9          ret


; IX = pointer to INFLIGHT_ENEMY structure
; IY = pointer to PLAYER_BULLET structure
CHECK_IF_PLAYER_BULLET_HIT_UFO:
2197: DD CB 00 46 bit  0,(ix+$00)            ; test INFLIGHT_ENEMY.IsActive flag
219B: C8          ret  z                     ; if enemy is not active, return
219C: FD 7E 01    ld   a,(iy+$01)            ; read PLAYER_BULLET.X
219F: DD 96 03    sub  (ix+$03)              ; subtract INFLIGHT_ENEMY.X
21A2: C6 03       add  a,$03
21A4: FE 07       cp   $07
21A6: D0          ret  nc
21A7: FD 7E 02    ld   a,(iy+$02)            ; read PLAYER_BULLET.Y
21AA: DD 96 04    sub  (ix+$04)              ; subtract INFLIGHT_ENEMY.Y
21AD: C6 04       add  a,$04
21AF: FE 09       cp   $09
21B1: D0          ret  nc

; Player bullet has hit a UFO.
21B2: DD 36 00 00 ld   (ix+$00),$00          ; reset INFLIGHT_ENEMY.IsActive flag 
21B6: DD 36 01 01 ld   (ix+$01),$01          ; set INFLIGHT_ENEMY.IsExploding flag 
21BA: DD 36 02 06 ld   (ix+$02),$06          ; set INFLIGHT_ENEMY.StageOfLife to 6 (see UFO_AND_FIREBALL_EXPLOSION_INIT @ $1DEE)
21BE: FD 36 00 00 ld   (iy+$00),$00          ; reset PLAYER_BULLET.IsActive flag  
21C2: 11 08 03    ld   de,$0308              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:8 = 100 pts
21C5: FF          rst  $38                   ; call QUEUE_COMMAND
21C6: CD EB 28    call $28EB                 ; call QUEUE_UFO_DEATH_SOUND
21C9: C9          ret


;
; Rest of the NMI handler - called from $09E9.
;

21CA: 32 15 40    ld   ($4015),a             ; write to PREV_PREV_PORT_STATE_8100
21CD: 2A 10 40    ld   hl,($4010)            ; read PORT_STATE_8100 and PORT_STATE_8101
21D0: 22 13 40    ld   ($4013),hl            ; and write to PREV_PORT_STATE_8100 and PREV_PORT_STATE_8101
21D3: 21 12 40    ld   hl,$4012              ; load HL with address of PORT_STATE_8102
21D6: 3A 02 81    ld   a,($8102)             ; read IN2
21D9: 2F          cpl
21DA: 77          ld   (hl),a                ; write to PORT_STATE_8102
21DB: 2B          dec  hl
21DC: 3A 01 81    ld   a,($8101)             ; read IN1
21DF: 2F          cpl
21E0: 77          ld   (hl),a                ; write to PORT_STATE_8101
21E1: 2B          dec  hl
21E2: 3A 00 81    ld   a,($8100)             ; read IN0 
21E5: 2F          cpl
21E6: 77          ld   (hl),a                ; write to PORT_STATE_8100
21E7: 21 5F 42    ld   hl,$425F              ; pointer to TIMING_VARIABLE 
21EA: 35          dec  (hl)                  ; decrement value
21EB: CD EC 09    call $09EC                 ; call UNPROCESSED_COINS
21EE: CD 55 28    call $2855                 ; call PROCESS_CIRC_SOUND_CMD_QUEUE

21F1: 21 03 22    ld   hl,$2203              ; address of NMI_CLEANUP
21F4: E5          push hl                    ; 

; invoke script #SCRIPT NUMBER (where SCRIPT_NUMBER is zero-based)
21F5: 3A 05 40    ld   a,($4005)             ; read SCRIPT_NUMBER 
21F8: EF          rst  $28

21F9: 
    A8 0A         ; $0AA8 (SCRIPT_ONE) 
    A9 0B         ; $0BA9 (ATTRACT_MODE_SCRIPT) 
    83 0E         ; $0E83 (CREDIT_INSERTED_SCRIPT)
    D2 0F         ; $0FD2 (PLAYER_ONE_GAME_SCRIPT) 
    EA 0F         ; $0FEA (PLAYER_TWO_GAME_SCRIPT)

NMI_CLEANUP:
2203: FD E1       pop  iy
2205: DD E1       pop  ix
2207: E1          pop  hl
2208: D1          pop  de
2209: C1          pop  bc
220A: F1          pop  af
220B: D9          exx
220C: 08          ex   af,af'
220D: E1          pop  hl
220E: D1          pop  de
220F: C1          pop  bc
2210: 3E 01       ld   a,$01
2212: 32 01 68    ld   ($6801),a             ; re-enable interrupts    
2215: F1          pop  af
2216: C9          ret


;
; Checks if player bullet has hit any ground based targets
;

PLAYER_BULLET_TO_GROUND_OBJECT_COLLISION_DETECTION:
2217: FD 21 00 45 ld   iy,$4500              ; load IY with address of PLAYER_BULLETS array
221B: 06 04       ld   b,$04                 ; max number of player bullets on screen at one time
221D: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
2220: CD 2C 22    call $222C
2223: FD 23       inc  iy
2225: FD 23       inc  iy
2227: FD 23       inc  iy                    ; bump IY to point to next PLAYER_BULLET 
2229: 10 F5       djnz $2220
222B: C9          ret

; IY = pointer to PLAYER_BULLET 
222C: FD CB 00 46 bit  0,(iy+$00)            ; test PLAYER_BULLET.IsActive flag
2230: C8          ret  z                     ; return if bullet is not active
2231: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array
2235: 0E 08       ld   c,$08                 ; length of GROUND_OBJECTS array
2237: D9          exx
2238: CD 42 22    call $2242                 ; call CHECK_IF_PLAYER_BULLET_HIT_GROUND_OBJECT
223B: D9          exx
223C: DD 19       add  ix,de                 ; bump IX to point to next GROUND_OBJECT
223E: 0D          dec  c                     ; C holds count of how many ground objects left to check 
223F: 20 F6       jr   nz,$2237              ; repeat until bullet checked for collision against all ground objects  
2241: C9          ret


; IX = pointer to GROUND_OBJECT
; IY = pointer to PLAYER_BULLET
CHECK_IF_PLAYER_BULLET_HIT_GROUND_OBJECT:
2242: DD CB 00 46 bit  0,(ix+$00)            ; test GROUND_OBJECT.IsActive  
2246: C8          ret  z                     ; exit if object is not active 
2247: FD 7E 01    ld   a,(iy+$01)            ; read PLAYER_BULLET.X
224A: DD 96 03    sub  (ix+$03)              ; subtract GROUND_OBJECT.X           
224D: C6 07       add  a,$07
224F: FE 0F       cp   $0F
2251: D0          ret  nc
2252: FD 7E 02    ld   a,(iy+$02)            ; read PLAYER_BULLET.Y
2255: DD 96 04    sub  (ix+$04)              ; subtract GROUND_OBJECT.Y
2258: C6 04       add  a,$04
225A: FE 09       cp   $09
225C: D0          ret  nc

; Ground object has been shot. Deactivate the bullet and make the ground object explode.
225D: DD 36 00 00 ld   (ix+$00),$00          ; clear GROUND_OBJECT.IsActive
2261: DD 36 01 01 ld   (ix+$01),$01          ; set GROUND_OBJECT.IsExploding 
2265: DD 36 02 06 ld   (ix+$02),$06          ; set GROUND_OBJECT.StageOfLife to 6 (see GROUND_OBJECT_EXPLOSION_INIT @ $1964)
2269: FD 36 00 00 ld   (iy+$00),$00          ; clear PLAYER_BULLET.IsActive

; read the type of ground object then award required amount of points to player 
AWARD_POINTS_FOR_DESTROYING_GROUND_OBJECT:
226D: DD 7E 17    ld   a,(ix+$17)            ; read GROUND_OBJECT.ObjectType
2270: A7          and  a                     ; test if zero (rocket)
2271: 28 08       jr   z,$227B               ; it's a rocket, goto ROCKET_DESTROYED_AWARD_50_PTS             
2273: 3D          dec  a                     
2274: 28 0D       jr   z,$2283               ; fuel tank, goto FUEL_DESTROYED_ADD_FUEL_AND_AWARD_50_PTS
2276: 3D          dec  a
2277: 28 1D       jr   z,$2296               ; mystery, goto MYSTERY_SHOT_AWARD_RANDOM_PTS
2279: 18 4E       jr   $22C9                 ; Base, goto BASE_SHOT_AWARD_800_PTS_AND_COMPLETE_GAME

; We've shot a rocket. Award player 50 points.
ROCKET_DESTROYED_AWARD_50_PTS:
227B: 11 01 03    ld   de,$0301              ;  Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:1 = 50 pts
227E: FF          rst  $38                   ; call QUEUE_COMMAND
227F: CD FB 28    call $28FB                 ; call QUEUE_ROCKET_EXPLOSION_SOUND
2282: C9          ret

; We've shot a fuel tank, add fuel to jet and award 150 pts
FUEL_DESTROYED_ADD_FUEL_AND_AWARD_50_PTS:
2283: 21 05 41    ld   hl,$4105              ; address of CURRENT_PLAYER_FUEL
2286: 7E          ld   a,(hl)                ; read fuel left
2287: C6 30       add  a,$30                 ; add 48 decimal (3 full blocks) to it      
2289: 30 02       jr   nc,$228D              ; if there's no overflow after this addition, goto $228D  
228B: 3E FF       ld   a,$FF                 ; otherwise, clamp to maximum amount of fuel you can have
228D: 77          ld   (hl),a                ; update CURRENT_PLAYER_FUEL 
228E: 11 03 03    ld   de,$0303              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:3 = 150 pts
2291: FF          rst  $38                   ; call QUEUE_COMMAND
2292: CD CE 28    call $28CE                 ; call QUEUE_EXPLOSION_SOUND_1
2295: C9          ret


; We've shot a MYSTERY object. The number of points we are awarded is based on a pseudo-random number from 0..3.
MYSTERY_SHOT_AWARD_RANDOM_PTS: 
2296: ED 5F       ld   a,r                   ; read the refresh register
2298: E6 03       and  $03                   ; convert value read into number from 0-3. 
229A: A7          and  a                     ; is the number zero?
229B: 28 08       jr   z,$22A5               ; if so, goto MYSTERY_SHOT_AWARD_100_PTS
229D: 3D          dec  a                     ; was the original number 1?
229E: 28 05       jr   z,$22A5               ; if so, goto MYSTERY_SHOT_AWARD_100_PTS
22A0: 3D          dec  a                     ; was the original number 2?
22A1: 28 0E       jr   z,$22B1               ; if so, goto MYSTERY_SHOT_AWARD_200_PTS
22A3: 18 18       jr   $22BD                 ; the original number must have been 3 - goto MYSTERY_SHOT_AWARD_300_PTS


MYSTERY_SHOT_AWARD_100_PTS:
22A5: DD 36 1A 00 ld   (ix+$1a),$00          ; set GROUND_OBJECT.MysteryPointsType to 0
22A9: 11 05 03    ld   de,$0305              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:5 = 100 pts
22AC: FF          rst  $38                   ; call QUEUE_COMMAND
22AD: CD D6 28    call $28D6                 ; call QUEUE_EXPLOSION_SOUND_DUPLICATE
22B0: C9          ret

MYSTERY_SHOT_AWARD_200_PTS:
22B1: DD 36 1A 01 ld   (ix+$1a),$01          ; set GROUND_OBJECT.MysteryPointsType to 1
22B5: 11 06 03    ld   de,$0306              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:6 = 200 pts
22B8: FF          rst  $38                   ; call QUEUE_COMMAND
22B9: CD D6 28    call $28D6                 ; call QUEUE_EXPLOSION_SOUND_DUPLICATE
22BC: C9          ret

MYSTERY_SHOT_AWARD_300_PTS:
22BD: DD 36 1A 02 ld   (ix+$1a),$02          ; set GROUND_OBJECT.MysteryPointsType to 2
22C1: 11 07 03    ld   de,$0307              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:7 = 300 points
22C4: FF          rst  $38                   ; call QUEUE_COMMAND
22C5: CD D6 28    call $28D6                 ; call QUEUE_EXPLOSION_SOUND_DUPLICATE
22C8: C9          ret

; Shot a "Base" - not only do you get 800 points, you also complete the mission.
BASE_SHOT_AWARD_800_PTS_AND_COMPLETE_GAME:
22C9: 11 0D 03    ld   de,$030D              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:$0D = 800 points!!!
22CC: FF          rst  $38                   ; call QUEUE_COMMAND
22CD: CD D6 28    call $28D6                 ; call QUEUE_EXPLOSION_SOUND_DUPLICATE
22D0: 3E FF       ld   a,$FF
22D2: 32 12 41    ld   ($4112),a             ; set the IS_MISSION_COMPLETE flag.
22D5: C9          ret


PLAYER_BULLET_TO_ROCKET_COLLISION_DETECTION:
22D6: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
22D9: A7          and  a                     ; test if rockets allowed
22DA: 28 03       jr   z,$22DF
22DC: FE 08       cp   $08                   ; test if rockets allowed
22DE: C0          ret  nz

22DF: FD 21 00 45 ld   iy,$4500              ; load IY with address of PLAYER_BULLETS
22E3: 06 04       ld   b,$04                 ; max number of rockets inflight at one time
22E5: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
22E8: CD 46 23    call $2346                 ; call CHECK_ONE_PLAYER_BULLET_MANY_ROCKETS
22EB: FD 23       inc  iy
22ED: FD 23       inc  iy
22EF: FD 23       inc  iy                    ; bump IY to next PLAYER_BULLET
22F1: 10 F5       djnz $22E8                 ; repeat until all player bullets done
22F3: C9          ret



; ! IMPORTANT !
; This is the routine that effectively runs the game. 
;

PLAY_GAME:
22F4: CD CC 13    call $13CC                 ; call ANIMATION_AND_MOVEMENT
22F7: CD 35 1F    call $1F35                 ; call SCROLL_AND_SPRITES
22FA: CD 36 20    call $2036                 ; call COLLISION_DETECTION
22FD: CD 63 25    call $2563                 ; call SPAWN_ENEMIES
2300: C3 52 28    jp   $2852                 ; jump to a JP $2303... I expect this would have been to confuse hackers. 

2303: CD C2 27    call $27C2                 ; call LANDSCAPE_CHANGE
2306: CD 9C 13    call $139C                 ; call GAIN_POINTS_JUST_FOR_STAYING_ALIVE    
2309: CD 80 29    call $2980                 ; call AMBIENT_SOUND  
230C: CD A7 13    call $13A7                 ; call CHECK_IF_EXTRA_LIFE_SHOULD_BE_AWARDED

230F: 21 80 43    ld   hl,$4380              ; load HL with address of PLAYER_ONE
2312: 7E          ld   a,(hl)                ; read PLAYER_ONE.IsActive flag
2313: 0F          rrca                       ; move flag into carry
2314: 38 19       jr   c,$232F               ; if player is active, jump to CHECK_IF_MISSION_IS_COMPLETE

2316: 2C          inc  l
2317: 7E          ld   a,(hl)                ; read PLAYER_ONE.IsExploding flag
2318: 0F          rrca                       ; move flag into carry
2319: D8          ret  c                     ; exit if player is exploding

; Player's finished exploding! Clear player state
231A: 21 80 43    ld   hl,$4380              ; load HL with address of PLAYERS array 
231D: 11 81 43    ld   de,$4381
2320: 36 00       ld   (hl),$00
2322: 01 A0 01    ld   bc,$01A0
2325: ED B0       ldir                       ; clear PLAYERS, PLAYER_BOMBS, INFLIGHT_ENEMIES, PLAYER_BULLETS arrays

; advance to next stage of script
2327: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
232A: 34          inc  (hl)                  ; advance to next stage of script (either PLAYER_ONE_KILLED @ $111D or PLAYER_TWO_KILLED @ $1209)
232B: 2D          dec  l                     ; bump HL to point to TEMP_COUNTER_4009 
232C: 36 64       ld   (hl),$64              ; set temp counter value
232E: C9          ret



CHECK_IF_MISSION_IS_COMPLETE:
232F: 3A 12 41    ld   a,($4112)             ; read IS_MISSION_COMPLETE flag.
2332: FE FF       cp   $FF                   ; have we completed our mission?
2334: C0          ret  nz                    ; exit if not

; We've completed our mission. We now need to kick off the MISSION_COMPLETED_SCRIPT at $127E
2335: 21 80 45    ld   hl,$4580              ; load HL with address of TEMP_COUNTER_4580
2338: 36 96       ld   (hl),$96              ; set value of counter
233A: 2C          inc  l                     ; bump HL to point to MISSION_COMPLETE_SCRIPT_STAGE
233B: 36 00       ld   (hl),$00              ; 
233D: 21 0A 40    ld   hl,$400A              ; load HL with address of SCRIPT_STAGE
2340: 36 08       ld   (hl),$08              ; set SCRIPT_STAGE to 8
2342: 2D          dec  l
2343: 36 64       ld   (hl),$64
2345: C9          ret



; Check if a given player bullet has hit any active rockets.
;
; IY = pointer to PLAYER_BULLET structure

CHECK_ONE_PLAYER_BULLET_MANY_ROCKETS:
2346: FD CB 00 46 bit  0,(iy+$00)            ; test PLAYER_BULLET.IsActive flag
234A: C8          ret  z                     ; return if flag is not set
234B: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
234F: 0E 04       ld   c,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
2351: D9          exx
2352: CD 5C 23    call $235C                 ; call CHECK_IF_PLAYER_BULLET_HIT_ROCKET
2355: D9          exx
2356: DD 19       add  ix,de                 ; bump IX to next INFLIGHT_ENEMY
2358: 0D          dec  c                     ; reduce count of INFLIGHT_ENEMY slots to process
2359: 20 F6       jr   nz,$2351              ; repeat until all slots done
235B: C9          ret


; IX = pointer to INFLIGHT_ENEMY structure
; IY = pointer to PLAYER_BULLET structure
CHECK_IF_PLAYER_BULLET_HIT_ROCKET:
235C: DD CB 00 46 bit  0,(ix+$00)            ; test INFLIGHT_ENEMY.IsActive flag
2360: C8          ret  z                     ; exit if this slot isn't being used

2361: FD 7E 01    ld   a,(iy+$01)            ; Read PLAYER_BULLET.X
2364: DD 96 03    sub  (ix+$03)              ; subtract INFLIGHT_ENEMY.X
2367: C6 05       add  a,$05                 
2369: FE 0B       cp   $0B
236B: D0          ret  nc
236C: FD 7E 02    ld   a,(iy+$02)            ; read PLAYER_BULLET.Y
236F: DD 96 04    sub  (ix+$04)              ; subtract INFLIGHT_ENEMY.Y
2372: C6 03       add  a,$03
2374: FE 07       cp   $07
2376: D0          ret  nc

; Rocket has been hit by a bullet. 
2377: DD 36 00 00 ld   (ix+$00),$00          ; clear INFLIGHT_ENEMY.IsActive flag
237B: DD 36 01 01 ld   (ix+$01),$01          ; set INFLIGHT_ENEMY.IsExploding flag
237F: DD 36 02 06 ld   (ix+$02),$06          ; set INFLIGHT_ENEMY.StageOfLife to 6 (see ROCKET_EXPLOSION_INIT @ $1D2C)
2383: FD 36 00 00 ld   (iy+$00),$00          ; clear PLAYER_BULLET.IsActive flag
2387: 11 0A 03    ld   de,$030A              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:$0A = 80 pts
238A: FF          rst  $38                   ; call QUEUE_COMMAND 
238B: CD FB 28    call $28FB                 ; call QUEUE_ROCKET_EXPLOSION_SOUND
238E: C9          ret


;
; Deactivate any player bullets that have hit the landscape.
;

PLAYER_BULLET_TO_LANDSCAPE_COLLISION_DETECTION:
238F: DD 21 00 45 ld   ix,$4500              ; load IX with address of PLAYER_BULLETS
2393: 11 03 00    ld   de,$0003              ; sizeof(PLAYER_BULLET)
2396: 06 04       ld   b,$04                 ; maximum number of player bullets on screen at one time
2398: D9          exx
2399: CD A2 23    call $23A2                 ; call CHECK_IF_PLAYER_BULLET_HIT_LANDSCAPE
239C: D9          exx
239D: DD 19       add  ix,de
239F: 10 F7       djnz $2398
23A1: C9          ret

; IX = pointer to PLAYER_BULLET
CHECK_IF_PLAYER_BULLET_HIT_LANDSCAPE:
23A2: DD CB 00 46 bit  0,(ix+$00)            ; test PLAYER_BULLET.IsActive flag
23A6: C8          ret  z                     ; return if bullet is not active

; find the LANDSCAPE_EXTENT record that defines the safe X coordinate range for our bullet.
23A7: 3A 16 41    ld   a,($4116)             ; read LANDSCAPE_SCROLL_COUNTER
23AA: 47          ld   b,a
23AB: DD 7E 02    ld   a,(ix+$02)            ; read PLAYER_BULLET.Y
23AE: 90          sub  b                     ; A = PLAYER_BULLET.Y - LANDSCAPE_SCROLL_COUNTER 
23AF: E6 F8       and  $F8
23B1: 0F          rrca
23B2: 0F          rrca
23B3: C6 C0       add  a,$C0                 ; LSB of address of LANDSCAPE_EXTENTS array 
23B5: 6F          ld   l,a
23B6: 26 41       ld   h,$41                 ; now HL is a pointer to an entry in LANDSCAPE_EXTENTS array

; if (PLAYER.BULLET.X > LANDSCAPE_EXTENT.GroundX) OR (PLAYER.BULLET.X < LANDSCAPE_EXTENT.CeilingX) THEN Deactivate bullet  
23B8: 7E          ld   a,(hl)                ; read LANDSCAPE_EXTENT.GroundX
23B9: DD BE 01    cp   (ix+$01)              ; compare to PLAYER_BULLET.X
23BC: 38 06       jr   c,$23C4               ; if PLAYER_BULLET.X > LANDSCAPE_EXTENT.GroundX, deactivate 
23BE: 2C          inc  l               
23BF: 7E          ld   a,(hl)                ; read LANDSCAPE_EXTENT.CeilingX
23C0: DD BE 01    cp   (ix+$01)              ; compare to PLAYER_BULLET.X 
23C3: D8          ret  c                     ; if PLAYER_BULLET.X > LANDSCAPE_EXTENT.CeilingX, exit function

; Bullet has hit the landscape
23C4: DD 36 00 00 ld   (ix+$00),$00          ; Deactivate bullet
23C8: C9          ret




;
;
; Check if any active player bombs have hit any active UFOs.
;
;

PLAYER_BOMB_TO_UFO_COLLISION_DETECTION:
23C9: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
23CC: FE 02       cp   $02                   ; UFO level?
23CE: C0          ret  nz                    ; exit if not

23CF: FD 21 C0 43 ld   iy,$43C0              ; load IY with address of PLAYER_BOMBS array
23D3: 06 02       ld   b,$02                 ; number of bombs on screen player can have at one time
23D5: 11 20 00    ld   de,$0020              ; sizeof(PLAYER_BOMB) and sizeof(INFLIGHT_ENEMY)
23D8: CD E0 23    call $23E0                 ; call CHECK_IF_PLAYER_BOMB_HIT_ANY_UFO
23DB: FD 19       add  iy,de                 ; bump IY to point to next PLAYER_BOMB 
23DD: 10 F9       djnz $23D8                 ; repeat until all bombs checked
23DF: C9          ret

; IY = pointer to PLAYER_BOMB 
; DE = sizeof(INFLIGHT_ENEMY)
CHECK_IF_PLAYER_BOMB_HIT_ANY_UFO:
23E0: FD CB 00 46 bit  0,(iy+$00)            ; read PLAYER_BOMB.IsActive
23E4: C8          ret  z                     ; return if bomb is not active
23E5: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES 
23E9: 0E 04       ld   c,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
23EB: D9          exx
23EC: CD F6 23    call $23F6                 ; call CHECK_IF_PLAYER_BOMB_HIT_UFO
23EF: D9          exx
23F0: DD 19       add  ix,de                 ; bump IX to next INFLIGHT_ENEMY
23F2: 0D          dec  c                     ; repeat until bomb checked against all INFLIGHT_ENEMIES
23F3: 20 F6       jr   nz,$23EB
23F5: C9          ret

; IX = pointer to INFLIGHT_ENEMY (which, if active, will be a UFO)
; IY = pointer to PLAYER_BOMB
CHECK_IF_PLAYER_BOMB_HIT_UFO:
23F6: DD CB 00 46 bit  0,(ix+$00)            ; test INFLIGHT_ENEMY.IsActive flag 
23FA: C8          ret  z                     ; exit if enemy is not active
23FB: FD 7E 03    ld   a,(iy+$03)            ; read INFLIGHT_ENEMY.X
23FE: DD 96 03    sub  (ix+$03)              ; subtract PLAYER_BOMB.X
2401: C6 05       add  a,$05
2403: FE 0B       cp   $0B
2405: D0          ret  nc
2406: FD 7E 04    ld   a,(iy+$04)            ; read INFLIGHT_ENEMY.Y
2409: DD 96 04    sub  (ix+$04)              ; subtract PLAYER_BOMB.Y
240C: C6 06       add  a,$06
240E: FE 0D       cp   $0D
2410: D0          ret  nc

; The player's bomb has hit an inflight enemy. 
DETONATE_PLAYER_BOMB_AND_KILL_INFLIGHT_ENEMY:
2411: DD 36 00 00 ld   (ix+$00),$00          ; clear INFLIGHT_ENEMY.IsActive flag
2415: DD 36 01 01 ld   (ix+$01),$01          ; set INFLIGHT_ENEMY.IsExploding flag
2419: DD 36 02 06 ld   (ix+$02),$06          ; set INFLIGHT_ENEMY.StageOfLife (for rocket, this stage is ROCKET_EXPLOSION_INIT, see $1D2C. For UFOs, this stage is UFO_AND_FIREBALL_EXPLOSION_INIT - see $1DEE)
241D: FD 36 00 00 ld   (iy+$00),$00          ; clear PLAYER_BOMB.IsActive flag
2421: FD 36 01 01 ld   (iy+$01),$01          ; set PLAYER_BOMB.IsExploding flag
2425: FD 36 02 06 ld   (iy+$02),$06          ; set PLAYER_BOMB.StageOfLife to 6 (see PLAYER_BOMB_EXPLOSION_INIT @ $1A6B)
2429: 11 08 03    ld   de,$0308              ; Command ID: 3 = UPDATE_PLAYER_SCORE_COMMAND, Param:8 = 100 pts
242C: FF          rst  $38                   ; call QUEUE_COMMAND 
242D: CD DE 28    call $28DE                 ; call QUEUE_PLAYER_BOMB_EXPLOSION_SOUND
2430: CD EB 28    call $28EB                 ; call QUEUE_UFO_DEATH_SOUND
2433: C9          ret



;
;
; Check if any active player bombs have hit any active ground objects.
;
;

PLAYER_BOMB_TO_GROUND_OBJECT_COLLISION_DETECTION:
2434: FD 21 C0 43 ld   iy,$43C0              ; load IY with address of PLAYER_BOMBS array
2438: 06 02       ld   b,$02                 ; Player has 2 bombs max
243A: 11 20 00    ld   de,$0020              ; sizeof(PLAYER_BOMB) 
243D: CD 45 24    call $2445
2440: FD 19       add  iy,de
2442: 10 F9       djnz $243D
2444: C9          ret

; IY = pointer to PLAYER_BOMB structure
2445: FD CB 00 46 bit  0,(iy+$00)            ; test PLAYER_BOMB.IsActive flag
2449: C8          ret  z                     ; return if bomb is not active
244A: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array
244E: 0E 08       ld   c,$08                 ; length of GROUND_OBJECTS array 
2450: D9          exx
2451: CD 5B 24    call $245B                 ; call CHECK_IF_PLAYER_BOMB_HIT_GROUND_OBJECT
2454: D9          exx
2455: DD 19       add  ix,de
2457: 0D          dec  c
2458: 20 F6       jr   nz,$2450
245A: C9          ret

; IX = pointer to GROUND_OBJECT structure
; IY = pointer to PLAYER_BOMB structure
CHECK_IF_PLAYER_BOMB_HIT_GROUND_OBJECT:
245B: DD CB 00 46 bit  0,(ix+$00)            ; test GROUND_OBJECT.IsActive flag
245F: C8          ret  z                     ; exit if this slot isn't used
2460: FD 7E 03    ld   a,(iy+$03)            ; read PLAYER_BOMB.X 
2463: DD 96 03    sub  (ix+$03)
2466: C6 07       add  a,$07
2468: FE 0E       cp   $0E
246A: D0          ret  nc
246B: FD 7E 04    ld   a,(iy+$04)            ; read PLAYER_BOMB.Y
246E: DD 96 04    sub  (ix+$04)
2471: C6 07       add  a,$07
2473: FE 0E       cp   $0E
2475: D0          ret  nc

; Player bomb has hit ground object. Make both bomb and ground object explode.
2476: DD 36 00 00 ld   (ix+$00),$00           ; clear GROUND_OBJECT.IsActive flag         
247A: DD 36 01 01 ld   (ix+$01),$01           ; set GROUND_OBJECT.IsExploding flag
247E: DD 36 02 06 ld   (ix+$02),$06           ; set GROUND_OBJECT.StageOfLife to 6 (see GROUND_OBJECT_EXPLOSION_INIT @ $1964)
2482: FD 36 00 00 ld   (iy+$00),$00           ; clear PLAYER_BOMB.IsActive
2486: FD 36 01 01 ld   (iy+$01),$01           ; set PLAYER_BOMB.IsExploding 
248A: FD 36 02 06 ld   (iy+$02),$06           ; set PLAYER_BOMB.StageOfLife to 6 (see PLAYER_BOMB_EXPLOSION_INIT @ $1AAC)
248E: CD DE 28    call $28DE                  ; call QUEUE_PLAYER_BOMB_EXPLOSION_SOUND
2491: C3 6D 22    jp   $226D                  ; jump to AWARD_POINTS_FOR_DESTROYING_GROUND_OBJECT



;
;
; Check if any active player bombs have hit any active ground objects.
;
;
PLAYER_BOMB_TO_ROCKET_COLLISION_DETECTION:
2494: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS 
2497: A7          and  a                     ; check if this is the first level with rockets
2498: 28 03       jr   z,$249D
249A: FE 08       cp   $08                   ; check if this is the second level with rockets
249C: C0          ret  nz
; OK, we're on a level that has rockets that can fly.  
249D: FD 21 C0 43 ld   iy,$43C0              ; load IY with address of PLAYER_BOMBS array
24A1: 06 02       ld   b,$02                 ; Player has 2 bombs max
24A3: 11 20 00    ld   de,$0020              ; sizeof(PLAYER_BOMB)
24A6: CD AE 24    call $24AE                 ; call CHECK_IF_PLAYER_BOMB_HIT_ANY_ROCKET 
24A9: FD 19       add  iy,de                 ; bump IY to point to next PLAYER_BOMB 
24AB: 10 F9       djnz $24A6                 ; repeat until all player bombs have been checked
24AD: C9          ret

; IY = pointer to PLAYER_BOMB 
CHECK_IF_PLAYER_BOMB_HIT_ANY_ROCKET:
24AE: FD CB 00 46 bit  0,(iy+$00)            ; test PLAYER_BOMB.IsActive flag 
24B2: C8          ret  z                     ; return if bomb is not active
24B3: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
24B7: 0E 04       ld   c,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
24B9: D9          exx
24BA: CD E5 24    call $24E5                 ; call CHECK_IF_PLAYER_BOMB_HIT_ROCKET
24BD: D9          exx
24BE: DD 19       add  ix,de                 ; bump IX to next INFLIGHT_ENEMY
24C0: 0D          dec  c                     ; repeat until all INFLIGHT_ENEMIES checked  
24C1: 20 F6       jr   nz,$24B9
24C3: C9          ret


;
;
;
;

; protection related code... if not interested skip to $24E0.
24C4: 3A B8 40    ld   a,($40B8)             ; read from PROTECTION_1
24C7: 07          rlca
24C8: 07          rlca
24C9: 07          rlca
24CA: C6 30       add  a,$30
24CC: 0F          rrca
24CD: 0F          rrca
24CE: 67          ld   h,a
24CF: C6 8D       add  a,$8D
24D1: 6F          ld   l,a                   ; set HL to $0E9B
24D2: 06 1E       ld   b,$1E
24D4: 86          add  a,(hl)                ; calculate checksum to see if code has been tampered with
24D5: 23          inc  hl
24D6: 10 FC       djnz $24D4 
24D8: FE 13       cp   $13
24DA: 28 04       jr   z,$24E0

; reset the game
24DC: AF          xor  a
24DD: 32 05 40    ld   ($4005),a             ; set SCRIPT_NUMBER

; play EXTRA LIFE AWARDED sound
24E0: 3E 08       ld   a,$08
24E2: C3 77 28    jp   $2877                 ; jump to QUEUE_SOUND_COMMAND


;
; Check if a given player bomb has hit a specific rocket.
;
; IX = pointer to INFLIGHT_ENEMY (which, if active, will be a rocket)
; IY = pointer to active PLAYER_BOMB
;

CHECK_IF_PLAYER_BOMB_HIT_ROCKET:
24E5: DD CB 00 46 bit  0,(ix+$00)            ; test INFLIGHT_ENEMY.IsActive flag
24E9: C8          ret  z                     ; exit if this rocket is not active

24EA: FD 7E 03    ld   a,(iy+$03)            ; read PLAYER_BOMB.X
24ED: DD 96 03    sub  (ix+$03)              ; subtract INFLIGHT_ENEMY.X
24F0: C6 06       add  a,$06
24F2: FE 0D       cp   $0D
24F4: D0          ret  nc
24F5: FD 7E 04    ld   a,(iy+$04)            ; read PLAYER_BOMB.Y 
24F8: DD 96 04    sub  (ix+$04)              ; subtract INFLIGHT_ENEMY.Y
24FB: C6 04       add  a,$04
24FD: FE 09       cp   $09
24FF: D0          ret  nc

; Player bomb has hit rocket. Make both bomb and rocket explode.
2500: DD 36 00 00 ld   (ix+$00),$00          ; clear INFLIGHT_ENEMY.IsActive flag 
2504: DD 36 01 01 ld   (ix+$01),$01          ; set INFLIGHT_ENEMY.IsExploding flag
2508: DD 36 02 06 ld   (ix+$02),$06          ; set INFLIGHT_ENEMY.StageOfLife to 6 (see ROCKET_EXPLOSION_INIT @ $1D2C)
250C: FD 36 00 00 ld   (iy+$00),$00          ; clear PLAYER_BOMB.IsActive flag
2510: FD 36 01 01 ld   (iy+$01),$01          ; set PLAYER_BOMB.IsExploding flag
2514: C3 3B 13    jp   $133B                 ; jump to CHECK_IF_PLAYER_BOMB_HIT_ROCKET_CONTINUED_1

; Jumped to from $133B
CHECK_IF_PLAYER_BOMB_HIT_ROCKET_CONTINUED_2:
2517: CD DE 28    call $28DE                 ; call QUEUE_PLAYER_BOMB_EXPLOSION_SOUND
251A: CD FB 28    call $28FB                 ; call QUEUE_ROCKET_EXPLOSION_SOUND
251D: C9          ret



;
;
; Check if any active player bombs have hit the landscape.
;
;

PLAYER_BOMB_TO_LANDSCAPE_COLLISION_DETECTION:
251E: DD 21 C0 43 ld   ix,$43C0              ; load IX with address of PLAYER_BOMBS array
2522: 06 02       ld   b,$02
2524: 11 20 00    ld   de,$0020              ; sizeof(PLAYER_BOMB)
2527: D9          exx
2528: CD 31 25    call $2531                 ; call CHECK_IF_PLAYER_BOMB_HIT_LANDSCAPE
252B: D9          exx
252C: DD 19       add  ix,de                 ; bump IX to next PLAYER_BOMB
252E: 10 F7       djnz $2527                 ; repeat until all PLAYER_BOMBS processed.
2530: C9          ret


; IX = pointer to PLAYER_BOMB struct
CHECK_IF_PLAYER_BOMB_HIT_LANDSCAPE:
2531: DD CB 00 46 bit  0,(ix+$00)            ; test PLAYER_BOMB.IsActive flag
2535: C8          ret  z                     ; return if bomb is not active
2536: 3A 16 41    ld   a,($4116)             ; read LANDSCAPE_SCROLL_COUNTER
2539: 47          ld   b,a
253A: DD 7E 04    ld   a,(ix+$04)            ; read PLAYER_BOMB.Y
253D: 90          sub  b                     ; subtract LANDSCAPE_SCROLL_COUNTER
253E: E6 F8       and  $F8
2540: 0F          rrca
2541: 0F          rrca
2542: C6 C0       add  a,$C0                 ; add LSB of LANDSCAPE_EXTENTS address
2544: 6F          ld   l,a
2545: 26 41       ld   h,$41                 ; now HL is a pointer into LANDSCAPE_EXTENTS
2547: 7E          ld   a,(hl)                ; read LANDSCAPE_EXTENT.GroundX
2548: DD BE 03    cp   (ix+$03)              ; compare to PLAYER_BOMB.X
254B: 38 06       jr   c,$2553               ; if LANDSCAPE_EXTENT.GroundX < PLAYER_BOMB.X then bomb has hit landscape  
254D: 2C          inc  l
254E: 7E          ld   a,(hl)                ; read LANDSCAPE_EXTENT.CeilingX  
254F: DD BE 03    cp   (ix+$03)              ; compare to PLAYER_BOMB.X  
2552: D8          ret  c                     ; if LANDSCAPE_EXTENT.CeilingX < PLAYER_BOMB.X then no collision, exit

; Bomb has hit the landscape. Make it explode.
2553: DD 36 00 00 ld   (ix+$00),$00          ; reset PLAYER_BOMB.IsActive flag 
2557: DD 36 01 01 ld   (ix+$01),$01          ; set PLAYER_BOMB.IsExploding flag
255B: DD 36 02 06 ld   (ix+$02),$06          ; set PLAYER_BOMB.StageOfLife to 6 (see PLAYER_BOMB_EXPLOSION_INIT @ $1AAC)
255F: CD DE 28    call $28DE                 ; call QUEUE_PLAYER_BOMB_EXPLOSION_SOUND
2562: C9          ret


; ! IMPORTANT !
; Main routine for spawning ground based and flying enemies 
;

SPAWN_ENEMIES:
2563: CD 7F 25    call $257F                 ; call SPAWN_PLAYER_BULLET
2566: CD CC 25    call $25CC                 ; call TRY_SPAWN_UFO
2569: CD 0C 26    call $260C                 ; call TRY_SPAWN_INFLIGHT_ROCKET
256C: CD 74 26    call $2674                 ; call SPAWN_FIREBALLS
256F: CD B1 26    call $26B1                 ; call SPAWN_PLAYER_BOMB
2572: CD FA 26    call $26FA                 ; call SPAWN_FUEL_TANK
2575: CD 5E 27    call $275E                 ; call SPAWN_MYSTERY
2578: CD 2C 27    call $272C                 ; call SPAWN_ROCKET_ON_GROUND
257B: CD 90 27    call $2790                 ; call SPAWN_BASE
257E: C9          ret


;
; Test for SHOOT button being pressed. 
; If shoot button has been pressed, spawn a player bullet if possible.
;
;

SPAWN_PLAYER_BULLET:
257F: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY
2582: 0F          rrca                       ; move flag into carry
2583: D0          ret  nc                    ; return if game is not in play
2584: 3A 80 43    ld   a,($4380)             ; read PLAYERS[0].IsActive flag
2587: 0F          rrca                       ; move flag into carry
2588: D0          ret  nc                    ; return if player is not active
2589: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER                      
258C: 0F          rrca                       ;  
258D: 38 0E       jr   c,$259D               ; if carry is set then its player 2 in control, goto $259D

; Player 1 
258F: 3A 10 40    ld   a,($4010)             ; read PORT_STATE_8100
2592: CB 5F       bit  3,a                   ; test if IPT_BUTTON1 is pressed
2594: C8          ret  z                     ; return if IPT_BUTTON1 not pressed
2595: 3A 13 40    ld   a,($4013)             ; read PREV_PORT_STATE_8100
2598: CB 5F       bit  3,a                   ; test if IPT_BUTTON1 was pressed before
259A: C0          ret  nz                    ; return if it was.
259B: 18 0C       jr   $25A9

; Player 2
259D: 3A 11 40    ld   a,($4011)             ; read PORT_STATE_8101
25A0: CB 5F       bit  3,a                   ; test if IPT_BUTTON1 (cocktail) was pressed
25A2: C8          ret  z                     ; return if IPT_BUTTON1 (cocktail) was not pressed
25A3: 3A 14 40    ld   a,($4014)             ; read PREV_PORT_STATE_8101
25A6: CB 5F       bit  3,a                   ; test if IPT_BUTTON1 (cocktail) was pressed before
25A8: C0          ret  nz                    ; return if it was

; The shoot button has been pressed.
; Look for a vacant PLAYER_BULLET record and re-use it for a new bullet.
TRY_SPAWN_PLAYER_BULLET:
25A9: 21 00 45    ld   hl,$4500              ; load HL with address of PLAYER_BULLETS array
25AC: 06 04       ld   b,$04                 ; maximum of 4 bullets on screen at once
25AE: CB 46       bit  0,(hl)                ; read  PLAYER_BULLET.IsActive flag
25B0: 20 14       jr   nz,$25C6              ; if this PLAYER_BULLET record is in use, try next PLAYER_BULLET record.  

; we've found a vacant record. Repurpose it for a "new" bullet.
; HL = pointer to PLAYER_BULLET structure.
25B2: CB C6       set  0,(hl)                ; set PLAYER_BULLET.IsActive flag
25B4: 2C          inc  l
25B5: 3A 83 43    ld   a,($4383)             ; read PLAYERS[0].X
25B8: C6 02       add  a,$02
25BA: 77          ld   (hl),a                ; set PLAYER_BULLET.X
25BB: 2C          inc  l
25BC: 3A 84 43    ld   a,($4384)             ; read PLAYERS[0].Y 
25BF: D6 07       sub  $07
25C1: 77          ld   (hl),a                ; set PLAYER_BULLET.Y
25C2: CD 03 29    call $2903                 ; call QUEUE_PLAYER_BULLET_FIRED_SOUND
25C5: C9          ret

25C6: 2C          inc  l
25C7: 2C          inc  l
25C8: 2C          inc  l                     ; bump HL to next PLAYER_BULLET record
25C9: 10 E3       djnz $25AE                 ; repeat until all records in PLAYER_BULLETS scanned
25CB: C9          ret



;
;
; Check if the level contains UFOs. If so, try to spawn one at regular intervals.
;
;

TRY_SPAWN_UFO:
25CC: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
25CF: FE 02       cp   $02                   ; UFOs on this level?
25D1: C0          ret  nz                    ; exit if not

; We only want to spawn a new UFO every 64 cycles of the game, to keep the UFOs spaced apart.
25D2: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
25D5: E6 3F       and  $3F
25D7: C0          ret  nz

; Look for a vacant INFLIGHT_ENEMY record and re-use it for a new UFO.
; If no vacant INFLIGHT_ENEMY records, just exit
25D8: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
25DC: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
25DF: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
25E1: DD 7E 00    ld   a,(ix+$00)            ; read INFLIGHT_ENEMY.IsActive flag
25E4: DD B6 01    or   (ix+$01)              ; combined with INFLIGHT_ENEMY.IsExploding flag
25E7: 0F          rrca                       ; move result into carry
25E8: 30 05       jr   nc,$25EF              ; if INFLIGHT_ENEMY is not active and not exploding, this record is free for use. Goto SPAWN_UFO 
25EA: DD 19       add  ix,de
25EC: 10 F3       djnz $25E1
25EE: C9          ret


; IX = pointer to vacant INFLIGHT_ENEMY record to use for UFO.
SPAWN_UFO:
25EF: DD 36 00 01 ld   (ix+$00),$01          ; set INFLIGHT_ENEMY.IsActive flag
25F3: DD 36 01 00 ld   (ix+$01),$00          ; clear INFLIGHT_ENEMY.IsExploding flag
25F7: DD 36 02 00 ld   (ix+$02),$00          ; set INFLIGHT_ENEMY.StageOfLife to 0.
25FB: DD 36 03 88 ld   (ix+$03),$88          ; set INFLIGHT_ENEMY.X

; calculate a pseudo-random Y coordinate for the UFO
25FF: ED 5F       ld   a,r
2601: E6 0F       and  $0F
2603: C6 09       add  a,$09
2605: DD 77 04    ld   (ix+$04),a            ; set INFLIGHT_ENEMY.Y
2608: C9          ret

2609: C3 79 0E    jp   $0E79



;
; Check if the level contains rockets. If so, find a rocket on the ground and launch it.
;
;

TRY_SPAWN_INFLIGHT_ROCKET:
260C: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
260F: A7          and  a                     ; test if zero
2610: 28 03       jr   z,$2615               ; if zero, then rocket launches are enabled for this level
2612: FE 08       cp   $08                   ; check if eight 
2614: C0          ret  nz                    ; if 8, then rocket launches are enabled for this level


; We only want to spawn a new rocket every 64 cycles of the game, to keep the sky from being too saturated with rockets.
2615: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
2618: E6 3F       and  $3F                   ; effectively do A = A modulus 64 
261A: C0          ret  nz                    ; if A wasn't a multiple of 64, return

; Scan through GROUND_OBJECTS array for an active object that has an ObjectType == 0 (type "Rocket").  
261B: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array
261F: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
2622: 06 08       ld   b,$08                 ; length of GROUND_OBJECTS array
2624: DD CB 00 46 bit  0,(ix+$00)            ; test GROUND_OBJECT.IsActive flag
2628: 20 05       jr   nz,$262F              ; if ground object is active goto $262F
262A: DD 19       add  ix,de
262C: 10 F6       djnz $2624
262E: C9          ret

; Expects: IX = pointer to GROUND_OBJECT 
262F: DD 7E 17    ld   a,(ix+$17)            ; read GROUND_OBJECT.ObjectType
2632: A7          and  a                     ; test if its zero (Rocket)
2633: 20 F5       jr   nz,$262A              ; if its not a rocket, resume scanning GROUND_OBJECTS array for one. 

; We've got an active rocket on the ground. Is this rocket within an area where if it launched, there's a chance
; it might hit the player? (ie: its not going off screen, and its not too far in front of the player)
2635: DD 7E 04    ld   a,(ix+$04)            ; read GROUND_OBJECT.Y
2638: FE 60       cp   $60
263A: 38 EE       jr   c,$262A               
263C: FE E8       cp   $E8
263E: 30 EA       jr   nc,$262A

; We've got a GROUND_OBJECT that's a rocket. We now need to find a free INFLIGHT_ENEMY record to use for our rocket.
TRY_LAUNCH_ROCKET:
2640: FD 21 00 44 ld   iy,$4400              ; load IY with address of INFLIGHT_ENEMIES
2644: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
2646: FD 7E 00    ld   a,(iy+$00)            ; read INFLIGHT_ENEMY.IsActive flag
2649: FD B6 01    or   (iy+$01)              ; combine with INFLIGHT_ENEMY.IsExploding 
264C: 0F          rrca
264D: 30 05       jr   nc,$2654              ; if not active and not exploding, we can use this slot. goto LAUNCH_ROCKET
264F: FD 19       add  iy,de                 ; bump IY to next INFLIGHT_ENEMY record
2651: 10 F3       djnz $2646                 ; repeat until all INFLIGHT_ENEMIES scanned.
2653: C9          ret


;
; Delete the GROUND_OBJECT and launch the INFLIGHT_ENEMY rocket.
; 
; Expects: 
; IX = pointer to GROUND_OBJECT to delete (a stationary rocket)
; IY = pointer to inactive INFLIGHT_ENEMY record (which now becomes an active flying rocket)

LAUNCH_ROCKET:
; First, we need to delete the rocket characters from screen.. 
2654: DD 36 02 03 ld   (ix+$02),$03          ; set GROUND_OBJECT.StageOfLife to 3 (GROUND_OBJECT_DELETE)
; .. then swap in a rocket sprite at the correct coordinates.
2658: DD 7E 03    ld   a,(ix+$03)            ; read GROUND_OBJECT.X 
265B: FD 77 03    ld   (iy+$03),a            ; set INFLIGHT_ENEMY.X
265E: DD 7E 04    ld   a,(ix+$04)            ; read GROUND_OBJECT.Y
2661: FD 77 04    ld   (iy+$04),a            ; set INFLIGHT_ENEMY.Y
2664: FD 36 00 01 ld   (iy+$00),$01          ; set INFLIGHT_ENEMY.IsActive
2668: FD 36 01 00 ld   (iy+$01),$00          ; clear INFLIGHT_ENEMY.IsExploding
266C: FD 36 02 00 ld   (iy+$02),$00          ; set INFLIGHT_ENEMY.StageOfLife
2670: CD 0D 29    call $290D                 ; just a RET
2673: C9          ret



;
;
;
;

SPAWN_FIREBALLS:
2674: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
2677: FE 01       cp   $01                   ; are we on the fireball level?
2679: C0          ret  nz                    ; exit if not

; We only want to spawn a fireball every 16 ticks of the timing variable
267A: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
267D: E6 0F       and  $0F
267F: C0          ret  nz

; Look for a vacant INFLIGHT_ENEMY record and re-use it for a new fireball.
; If no vacant INFLIGHT_ENEMY records, just exit
TRY_SPAWN_FIREBALL:
2680: DD 21 00 44 ld   ix,$4400              ; load IX with address of INFLIGHT_ENEMIES
2684: 11 20 00    ld   de,$0020              ; sizeof(INFLIGHT_ENEMY)
2687: 06 04       ld   b,$04                 ; max number of INFLIGHT_ENEMIES on screen at one time
2689: DD 7E 00    ld   a,(ix+$00)            ; read INFLIGHT_ENEMY.IsActive
268C: DD B6 01    or   (ix+$01)              ; or with INFLIGHT_ENEMY.IsExploding
268F: 0F          rrca                       ; move combined flags into carry
2690: 30 05       jr   nc,$2697              ; if enemy is not active or exploding, goto $2697  
2692: DD 19       add  ix,de
2694: 10 F3       djnz $2689
2696: C9          ret

; IX = pointer to vacant INFLIGHT_ENEMY record to use for fireball.
SPAWN_FIREBALL:
2697: DD 36 00 01 ld   (ix+$00),$01          ; set INFLIGHT_ENEMY.IsActive flag
269B: DD 36 01 00 ld   (ix+$01),$00          ; clear INFLIGHT_ENEMY.IsExploding flag
269F: DD 36 02 00 ld   (ix+$02),$00          ; set INFLIGHT_ENEMY.StageOfLife to 0 (see FIREBALL_INIT @ $1EFF)
26A3: ED 5F       ld   a,r                   ; get a pseudo-random number
26A5: E6 7F       and  $7F                   ; ensure it's between 0-127
26A7: C6 30       add  a,$30                 ; add 48
26A9: DD 77 03    ld   (ix+$03),a            ; set INFLIGHT_ENEMY.X
26AC: DD 36 04 08 ld   (ix+$04),$08          ; set INFLIGHT_ENEMY.Y to 8
26B0: C9          ret



;
; Check if player has pushed the BOMB button.
; If bomb button has been pressed, spawn a bomb if possible.
;

SPAWN_PLAYER_BOMB:
; can't drop a bomb if in demo mode!
26B1: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY
26B4: 0F          rrca                       ; move flag into carry 
26B5: D0          ret  nc                    ; return if game is not in play
26B6: 3A 80 43    ld   a,($4380)
26B9: 0F          rrca
26BA: D0          ret  nc
26BB: 3A 0D 40    ld   a,($400D)             ; read CURRENT_PLAYER
26BE: 0F          rrca                       ; if carry flag is set, PLAYER 2 is current player
26BF: 38 0E       jr   c,$26CF               ; jumpt to $26CF if player 2 playing

; Read player 1 bomb button
26C1: 3A 10 40    ld   a,($4010)             ; read PORT_STATE_8100
26C4: CB 4F       bit  1,a                   ; test if IPT_BUTTON2 is pressed
26C6: C8          ret  z                     ; return if not

26C7: 3A 13 40    ld   a,($4013)             ; read PREV_PORT_STATE_8100
26CA: CB 4F       bit  1,a                   ; test if IPT_BUTTON2 was already pressed
26CC: C0          ret  nz                    ; return if true
26CD: 18 0C       jr   $26DB                 ; try to spawn a player bomb

; Read Player 2 bomb button
26CF: 3A 11 40    ld   a,($4011)             ; read PORT_STATE_8101
26D2: CB 57       bit  2,a                   ; test if IPT_BUTTON2 (cocktail) is pressed
26D4: C8          ret  z                     ; return if not
26D5: 3A 14 40    ld   a,($4014)             ; read PREV_PORT_STATE_8101
26D8: CB 57       bit  2,a                   ; test if IPT_BUTTON2 (cocktail) was already pressed
26DA: C0          ret  nz                    ; return if true   
                                                             
; Player's pressed the bomb button. Can we spawn a bomb?
TRY_SPAWN_PLAYER_BOMB:
26DB: 21 C0 43    ld   hl,$43C0              ; load HL with address of PLAYER_BOMBS
26DE: 11 1F 00    ld   de,$001F              ; sizeof(PLAYER_BOMB)-1
26E1: 06 02       ld   b,$02                 ; player gets a max of 2 bombs
26E3: 7E          ld   a,(hl)                ; read PLAYER_BOMB.IsActive
26E4: 2C          inc  l
26E5: B6          or   (hl)                  ; combine with PLAYER_BOMB.IsExploding flag
26E6: 0F          rrca                       ; move result into carry
26E7: 30 04       jr   nc,$26ED              ; if bomb slot is not active, and not exploding, we can re-use it, goto SPAWN_PLAYER_BOMB
26E9: 19          add  hl,de                 ; bump HL to point to next PLAYER_BOMB record in array
26EA: 10 F7       djnz $26E3                 ; repeat until we find a vacant bomb slot or we find all bombs are in use.
26EC: C9          ret

; HL+1  = pointer to PLAYER_BOMB struct
SPAWN_PLAYER_BOMB:
26ED: 2D          dec  l                     ; align HL to point to start of PLAYER_BOMB struct.
26EE: 36 01       ld   (hl),$01              ; set PLAYER_BOMB.IsActive to true
26F0: 2C          inc  l
26F1: 36 00       ld   (hl),$00              ; set PLAYER_BOMB.IsExploding to false  
26F3: 2C          inc  l
26F4: 36 00       ld   (hl),$00              ; set PLAYER_BOMB.StageOfLife to 0 
26F6: CD 08 29    call $2908                 ; call QUEUE_PLAYER_BOMB_DROP_SOUND
26F9: C9          ret



;
; Should we scroll a Fuel Tank onto the screen?
;

SPAWN_FUEL_TANK:
26FA: 3A 1A 41    ld   a,($411A)             ; read NEXT_GROUND_OBJECT_ID
26FD: E6 02       and  $02                   ; is it a FUEL TANK?
26FF: C8          ret  z                     ; exit if not
2700: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array 
2704: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
2707: 06 08       ld   b,$08                 ; length of GROUND_OBJECTS array
2709: DD 7E 00    ld   a,(ix+$00)            ; read GROUND_OBJECT.IsActive flag
270C: DD B6 01    or   (ix+$01)              ; combine with GROUND_OBJECT.IsExploding flag
270F: 0F          rrca                       ; move into carry. 
2710: 30 05       jr   nc,$2717              ; if object is not active nor exploding, its free to re-use, goto FUEL_TANK_INIT
2712: DD 19       add  ix,de
2714: 10 F3       djnz $2709
2716: C9          ret

FUEL_TANK_INIT:
2717: DD 36 00 01 ld   (ix+$00),$01          ; set GROUND_OBJECT.IsActive flag 
271B: DD 36 01 00 ld   (ix+$01),$00          ; clear GROUND_OBJECT.IsExploding flag
271F: DD 36 02 00 ld   (ix+$02),$00          ; set GROUND_OBJECT.StageOfLife to 0 (see GROUND_OBJECT_INIT @ $18E6)
2723: DD 36 17 01 ld   (ix+$17),$01          ; set GROUND_OBJECT.ObjectType
2727: AF          xor  a
2728: 32 1A 41    ld   ($411A),a             ; clear NEXT_GROUND_OBJECT_ID
272B: C9          ret


;
; Should we scroll a Rocket onto the screen?
;

SPAWN_ROCKET_ON_GROUND:
272C: 3A 1A 41    ld   a,($411A)             ; read NEXT_GROUND_OBJECT_ID
272F: E6 01       and  $01                   ; is it a ROCKET?
2731: C8          ret  z                     ; exit if not
2732: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array 
2736: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
2739: 06 08       ld   b,$08                 ; length of GROUND_OBJECTS array
273B: DD 7E 00    ld   a,(ix+$00)            ; read GROUND_OBJECT.IsActive flag
273E: DD B6 01    or   (ix+$01)              ; combine with GROUND_OBJECT.IsExploding flag
2741: 0F          rrca                       ; move into carry. 
2742: 30 05       jr   nc,$2749              ; if object is not active nor exploding, its free to re-use, goto ROCKET_ON_GROUND_INIT  
2744: DD 19       add  ix,de                 ; bump IX to point to next GROUND_OBJECT in array
2746: 10 F3       djnz $273B                 ; repeat until all records in GROUND_OBJECTS have been scanned. 
2748: C9          ret

ROCKET_ON_GROUND_INIT:
2749: DD 36 00 01 ld   (ix+$00),$01          ; set GROUND_OBJECT.IsActive flag
274D: DD 36 01 00 ld   (ix+$01),$00          ; clear GROUND_OBJECT.IsExploding flag  
2751: DD 36 02 00 ld   (ix+$02),$00          ; ; set GROUND_OBJECT.StageOfLife to 0 (see GROUND_OBJECT_INIT @ $18E6)
2755: DD 36 17 00 ld   (ix+$17),$00          ; set GROUND_OBJECT.ObjectType to 0 (Rocket)
2759: AF          xor  a
275A: 32 1A 41    ld   ($411A),a             ; clear NEXT_GROUND_OBJECT_ID  
275D: C9          ret

;
; Should we scroll a Mystery onto the screen?
;
;

SPAWN_MYSTERY:
275E: 3A 1A 41    ld   a,($411A)             ; read NEXT_GROUND_OBJECT_ID
2761: E6 04       and  $04                   ; is it a MYSTERY?
2763: C8          ret  z                     ; exit if not

; Find a vacant GROUND_OBJECT record to use to hold our MYSTERY.
2764: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array
2768: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
276B: 06 08       ld   b,$08                 ; length of GROUND_OBJECTS array
276D: DD 7E 00    ld   a,(ix+$00)            ; read GROUND_OBJECT.IsActive flag
2770: DD B6 01    or   (ix+$01)              ; combine with GROUND_OBJECT.IsExploding flag
2773: 0F          rrca                       ; move combined flags into carry. 
2774: 30 05       jr   nc,$277B              ; if object is not active nor exploding, its free to re-use, goto MYSTERY_INIT 
2776: DD 19       add  ix,de                 ; bump IX to point to next GROUND_OBJECT in array
2778: 10 F3       djnz $276D                 ; repeat until all records in GROUND_OBJECTS have been scanned.
277A: C9          ret

; IX = pointer to vacant GROUND_OBJECT record to use for a MYSTERY.
MYSTERY_INIT:
277B: DD 36 00 01 ld   (ix+$00),$01          ; set GROUND_OBJECT.IsActive flag
277F: DD 36 01 00 ld   (ix+$01),$00          ; clear GROUND_OBJECT.IsExploding flag
2783: DD 36 02 00 ld   (ix+$02),$00          ; ; set GROUND_OBJECT.StageOfLife to 0 (see GROUND_OBJECT_INIT @ $18E6)
2787: DD 36 17 02 ld   (ix+$17),$02          ; set GROUND_OBJECT.ObjectType to 2 (Mystery)
278B: AF          xor  a          
278C: 32 1A 41    ld   ($411A),a             ; clear NEXT_GROUND_OBJECT_ID
278F: C9          ret


;
; Should we scroll a Base (I think it looks more like a drilling rig, personally) onto the screen?
;
SPAWN_BASE:
2790: 3A 1A 41    ld   a,($411A)             ; read NEXT_GROUND_OBJECT_ID 
2793: E6 08       and  $08                   ; is it a BASE?
2795: C8          ret  z                     ; exit of not

; Find a vacant GROUND_OBJECT record to use to hold our BASE.
2796: DD 21 80 42 ld   ix,$4280              ; load IX with address of GROUND_OBJECTS array
279A: 11 20 00    ld   de,$0020              ; sizeof(GROUND_OBJECT)
279D: 06 08       ld   b,$08                 ; length of GROUND_OBJECTS array
279F: DD 7E 00    ld   a,(ix+$00)            ; read GROUND_OBJECT.IsActive flag
27A2: DD B6 01    or   (ix+$01)              ; combine with GROUND_OBJECT.IsExploding flag  
27A5: 0F          rrca                       ; move into carry. 
27A6: 30 05       jr   nc,$27AD              ; if object is not active nor exploding, its free to re-use, goto BASE_INIT 
27A8: DD 19       add  ix,de                 ; bump IX to point to next GROUND_OBJECT in array
27AA: 10 F3       djnz $279F                 ; repeat until all records in GROUND_OBJECTS have been scanned.
27AC: C9          ret

; IX = pointer to vacant GROUND_OBJECT to use for a BASE.
BASE_INIT:
27AD: DD 36 00 01 ld   (ix+$00),$01          ; set GROUND_OBJECT.IsActive flag
27B1: DD 36 01 00 ld   (ix+$01),$00          ; clear GROUND_OBJECT.IsExploding flag
27B5: DD 36 02 00 ld   (ix+$02),$00          ; ; set GROUND_OBJECT.StageOfLife to 0 (see GROUND_OBJECT_INIT @ $18E6)
27B9: DD 36 17 03 ld   (ix+$17),$03          ; set GROUND_OBJECT.ObjectType to 3 (Base)
27BD: AF          xor  a
27BE: 32 1A 41    ld   ($411A),a             ; clear NEXT_GROUND_OBJECT_ID
27C1: C9          ret



;
; !IMPORTANT!
; Used to ensure correct landscape and colour scheme is chosen
;

LANDSCAPE_CHANGE:
27C2: CD C9 27    call $27C9                 ; call SELECT_NEXT_LANDSCAPE
27C5: CD 04 28    call $2804                 ; call SET_LANDSCAPE_AND_BACKGROUND_COLOUR
27C8: C9          ret


;
; Check if player has reached end of current landscape.
; 
; If so: 
; * Select next landscape that player will fly over. 
; * Update progress bar (1ST, 2ND, 3RD.. BASE).
;

SELECT_NEXT_LANDSCAPE:
27C9: 2A 18 41    ld   hl,($4118)            ; load HL with contents of LANDSCAPE_LAYOUT_PTR 
27CC: 7E          ld   a,(hl)                ; read byte from landscape
27CD: FE FF       cp   $FF                   ; end of level marker?
27CF: C0          ret  nz                    ; return if not end of level

; we've reached the end of the level. Advance to next level if we can
27D0: 21 00 44    ld   hl,$4400              ; load HL with address of INFLIGHT_ENEMIES
27D3: 11 01 44    ld   de,$4401
27D6: 01 80 00    ld   bc,$0080              ; sizeof(INFLIGHT_ENEMIES)
27D9: 36 00       ld   (hl),$00
27DB: ED B0       ldir                       ; clear INFLIGHT_ENEMIES array
27DD: 21 1E 41    ld   hl,$411E              ; load HL with address of CURRENT_PLAYERS_LEVEL
27E0: 7E          ld   a,(hl)                ; read level
27E1: FE 05       cp   $05                   ; are we on the (final) "BASE" level?
27E3: 28 01       jr   z,$27E6               ; if so, goto $27E6 
27E5: 34          inc  (hl)                  ; otherwise, increment level 

; get landscape for next level
27E6: 7E          ld   a,(hl)                ; read level
27E7: 47          ld   b,a                   ; effectively multiply level..
27E8: 87          add  a,a
27E9: 80          add  a,b                   ; .. by 3.
27EA: 5F          ld   e,a
27EB: 16 00       ld   d,$00                 ; extend A into DE
27ED: 21 D0 29    ld   hl,$29D0              ; load HL with address of LANDSCAPE_LAYOUT_METADATA_TABLE table
27F0: 19          add  hl,de
27F1: 7E          ld   a,(hl)
27F2: 32 18 41    ld   ($4118),a             ; set LANDSCAPE_LAYOUT_PTR_LO
27F5: 23          inc  hl
27F6: 7E          ld   a,(hl)
27F7: 32 19 41    ld   ($4119),a             ; set LANDSCAPE_LAYOUT_PTR_LO
27FA: 23          inc  hl
27FB: 7E          ld   a,(hl)
27FC: 32 1D 41    ld   ($411D),a             ; set LANDSCAPE_FLAGS

; update progress bar
27FF: 11 02 07    ld   de,$0702              ; Command ID: 7 = HEAD_UP_DISPLAY_COMMAND, Param:2 = DISPLAY_CURRENT_PLAYER_PROGRESS_BAR
2802: FF          rst  $38                   ; call QUEUE_COMMAND  
2803: C9          ret



;
;
; Change the landscape and background colours, enable starfield . 
;
;

SET_LANDSCAPE_AND_BACKGROUND_COLOUR:
2804: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
2807: A7          and  a                     ; test if zero           
2808: C0          ret  nz                    ; return if not zero

2809: 21 1B 40    ld   hl,$401B              ; load HL with address of LANDSCAPE_COLOUR_CHANGE_COUNTER
280C: 34          inc  (hl)                  ; increment counter
280D: 7E          ld   a,(hl)                ; read value of counter
280E: 0F          rrca                       ; move bit zero into carry
280F: D8          ret  c                     ; if counter is not an even number, exit

; change colour of landscape
2810: 21 17 41    ld   hl,$4117              ; load HL with address of LANDSCAPE_COLOUR
2813: 7E          ld   a,(hl)                ; read colour value
2814: 3C          inc  a                     ; increment it
2815: E6 07       and  $07                   ; ensure its a value between 0..7
2817: FE 01       cp   $01                   ; compare to 1
2819: 28 03       jr   z,$281E               ; if it's 1 then we can't use that colour, goto $281E
281B: 77          ld   (hl),a                ; update LANDSCAPE_COLOUR
281C: 18 02       jr   $2820         

281E: 3C          inc  a                     ; Adjust invalid colour 1 to 2 
281F: 77          ld   (hl),a                ; update LANDSCAPE_COLOUR         

2820: 47          ld   b,a                   ; load B with value of LANDSCAPE_COLOUR

; If DISABLE_STARS = 1 then disable starfield & set background colour to black.  
; Else set the background colour and starfield from the STARS_AND_BACKGROUND_TABLE
2821: 3A 11 41    ld   a,($4111)             ; read DISABLE_STARS flag
2824: 0F          rrca                       ; move flag into carry
2825: 38 13       jr   c,$283A               ; if flag is set, goto HIDE_STARS_AND_SET_BACKGROUND_TO_BLACK

2827: 78          ld   a,b                   ; load A with LANDSCAPE_COLOUR
2828: 21 42 28    ld   hl,$2842              ; load HL with address of STARS_AND_BACKGROUND_TABLE
282B: 16 00       ld   d,$00
282D: 87          add  a,a                   ; multiply A by 2
282E: 5F          ld   e,a                   ; extend A into DE (or alternatively: DE = A)
282F: 19          add  hl,de                 ; now HL points to an entry in STARS_AND_BACKGROUND_TABLE
2830: 7E          ld   a,(hl)                ; read enable stars flag
2831: 32 04 68    ld   ($6804),a             ; enable/disable stars 
2834: 23          inc  hl                    ; 
2835: 7E          ld   a,(hl)                ; read background colour 
2836: 32 03 68    ld   ($6803),a             ; set background colour 
2839: C9          ret

HIDE_STARS_AND_SET_BACKGROUND_TO_BLACK:
283A: AF          xor  a
283B: 32 04 68    ld   ($6804),a             ; disable stars
283E: 32 03 68    ld   ($6803),a             ; set background to black
2841: C9          ret


STARS_AND_BACKGROUND_TABLE:
2842: 
    01 00         ; enable stars, black background 
    01 00         ; enable stars, black background
    01 00         ; enable stars, black background
    01 00         ; enable stars, black background
    01 01         ; enable stars, blue background 
    01 01         ; enable stars, blue background
    01 00         ; enable stars, black background
    01 00         ; enable stars, black background


; called by $2300. Jumps to succeeding instruction. Was this to make the code harder to trace or waste CPU cycles? 
; (I think the former is more likely.) 
2852: C3 03 23    jp   $2303          



;
; ! IMPORTANT !
; Process the circular sound command queue @ starting $4243 (CIRC_SOUND_CMD_QUEUE_START)
;

PROCESS_CIRC_SOUND_CMD_QUEUE:
2855: 11 41 42    ld   de,$4241              ; load de with address of CIRC_SOUND_CMD_QUEUE_PROC_LO
2858: 1A          ld   a,(de)                ; read CIRC_SOUND_CMD_QUEUE_PROC_LO
2859: 6F          ld   l,a
285A: 26 42       ld   h,$42                 ; Now HL = pointer to a command or a "done" marker ($FF)

; read command ID from sound command queue. If it's $FF then exit
285C: 7E          ld   a,(hl)                ; read command ID
285D: FE FF       cp   $FF                   ; if its a "done" marker we do nothing with it  
285F: C8          ret  z                     ; return if done marker 

; we don't play any sounds when the game's not in play
2860: 47          ld   b,a                   ; preserve command ID in B 
2861: 3A 06 40    ld   a,($4006)             ; read IS_GAME_IN_PLAY flag
2864: A7          and  a                     ; test flag
2865: 78          ld   a,b                   ; restore command ID from B register
2866: C4 B2 28    call nz,$28B2              ; if game is in play, call EXEC_AUDIO_COMMAND
2869: 36 FF       ld   (hl),$FF              ; overwrite sound command with "done" flag 

; have we hit the end of the sound queue? If so, we need to go back to start of queue and resume processing from there.
286B: 7D          ld   a,l
286C: FE 5E       cp   $5E                    
286E: 28 03       jr   z,$2873               ; yes, we've reached end - so go to RESET_CIRC_SOUND_CMD_QUEUE_PROC_LO

; bump 
2870: 3C          inc  a
2871: 12          ld   (de),a                ; update CIRC_SOUND_CMD_QUEUE_PROC_LO
2872: C9          ret

; Reset CIRC_SOUND_CMD_QUEUE_PROC_LO to point to start of queue in memory 
RESET_CIRC_SOUND_CMD_QUEUE_PROC_LO:
2873: 3E 43       ld   a,$43
2875: 12          ld   (de),a                ; update CIRC_SOUND_CMD_QUEUE_PROC_LO
2876: C9          ret



; Queue a sound command in the CIRC_SOUND_CMD_QUEUE queue.
;
; A = Command to perform 
;
;
; Value in A      What it does
; ==========      ============
; 1               Halts current sound (I think!)
; 3               Queue rocket exploding sound
; 4               Queue UFO exploding sound  
; 5               Queue Player jet exploding sound  
; 6               Queue Player bullet fired sound
; 7               Queue low fuel alert sound
; 8               Queue new life awarded sound
; 9               Queue game start music voice 1 (doo doo doo de doo doo doo doo ;-)  )
; $0A             Queue game start music voice 2 
; $0E             Queue nice little jingle that I don't think is used in game
; $0F             Queue another nice little unused jingle
; $12             Queue default ambient sound (reminds me of Paradroid C64)
; $13             Queue player bomb exploding sound
; $20             Queue bomb drop sound
; $21             Queue UFO ambient sound
; $22             Prep before queuing fireball sound (you need to queue $23 as well)
; $23             Queue Fireball sizzling ambient sound 
; $24             Queue maze ambient sound
;
; There probably are other sounds/melodies available, but these are the sounds used in game. 
; Tinker with the value of A and see what you can find :) 
;

QUEUE_SOUND_COMMAND:
2877: C5          push bc
2878: D5          push de
2879: E5          push hl
287A: 47          ld   b,a                   ; preserve A in B, as A will be used to read from (DE)
287B: 11 40 42    ld   de,$4240              ; load DE with address of CIRC_SOUND_CMD_QUEUE_PTR
287E: 1A          ld   a,(de)                ; get LSB of address into A
287F: 6F          ld   l,a               
2880: 26 42       ld   h,$42                 ; now HL = $42xx, where xx = value read from CIRC_SOUND_CMD_QUEUE_PTR_LO

; add command ID to sound queue
2882: 70          ld   (hl),b                ; write command to CIRC_SOUND_CMD_QUEUE
2883: 7D          ld   a,l                   ; get LSB of HL into A

; test if we've hit the end of the queue - if so, reset CIRC_SOUND_CMD_QUEUE_PTR_LO
2884: FE 5E       cp   $5E                   ; have we hit the end of the circular buffer?
2886: 28 04       jr   z,$288C               ; yes, we need to go back to start 
2888: 3C          inc  a                     ; otherwise, bump A to point to next entry in buffer
2889: 12          ld   (de),a                ; and update CIRC_SOUND_CMD_QUEUE_PTR_LO
288A: 18 03       jr   $288F                 ; and we're out.

; reset CIRC_SOUND_CMD_QUEUE_PTR_LO
288C: 3E 43       ld   a,$43                 ; LSB of CIRC_SOUND_CMD_QUEUE_START
288E: 12          ld   (de),a                ; set CIRC_SOUND_CMD_QUEUE_PTR_LO to point to start of buffer

; restore registers
288F: E1          pop  hl
2890: D1          pop  de
2891: C1          pop  bc
2892: C9          ret




DISABLE_SOUND:
2893: 3A 42 42    ld   a,($4242)             ; read IRQTRIGGER_CTRL
2896: F6 10       or   $10                   ; set bit 4 to disable sound  
2898: 32 42 42    ld   ($4242),a             ; set IRQTRIGGER_CTRL
289B: 32 01 82    ld   ($8201),a             ; write to i8255 chip
289E: AF          xor  a
289F: C3 B2 28    jp   $28B2                 ; jump to EXEC_SOUND_COMMAND



ENABLE_SOUND:
28A2: AF          xor  a
28A3: CD B2 28    call $28B2                 ; jump to EXEC_SOUND_COMMAND
28A6: 3A 42 42    ld   a,($4242)             ; read IRQTRIGGER_CTRL   
28A9: E6 EF       and  $EF                   ; clear bit 4 to enable sound
28AB: 32 42 42    ld   ($4242),a             ; IRQTRIGGER_CTRL
28AE: 32 01 82    ld   ($8201),a             ; write to interrupt trigger port
28B1: C9          ret


;
; Execute a command on the audio CPU. 
;
; Expects:
; A = command to execute. See QUEUE_SOUND_COMMAND for list of commands.
;

EXEC_AUDIO_COMMAND:
28B2: 32 00 82    ld   ($8200),a             ; write to AY-3-8910 
28B5: 3A 42 42    ld   a,($4242)             ; read IRQTRIGGER_CTRL  
28B8: E6 F7       and  $F7                   ; clear bit 3 (audio CPU)
28BA: 32 01 82    ld   ($8201),a             ; write to i8255 chip 
; use NOPs to create a delay before writing to i8255 chip again              
28BD: 00          nop
28BE: 00          nop
28BF: 00          nop
28C0: 00          nop
28C1: 3A 42 42    ld   a,($4242)             ; read IRQTRIGGER_CTRL
28C4: F6 08       or   $08                   ; set bit 3 (audio CPU)
28C6: 32 01 82    ld   ($8201),a             ; write to i8255 chip
28C9: C9          ret

28CA: 3E 08       ld   a,$08
28CC: 18 E4       jr   $28B2

QUEUE_EXPLOSION_SOUND_1:
28CE: 3E 01       ld   a,$01
28D0: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
28D3: C3 36 29    jp   $2936                 ; jump to QUEUE_EXPLOSION_SOUND

; Named duplicate because its the exact same code as QUEUE_EXPLOSION_SOUND_1, above.
QUEUE_EXPLOSION_SOUND_DUPLICATE:
28D6: 3E 01       ld   a,$01
28D8: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND 
28DB: C3 36 29    jp   $2936                 ; jump to QUEUE_EXPLOSION_SOUND

QUEUE_PLAYER_BOMB_EXPLOSION_SOUND:
28DE: 3E 30       ld   a,$30
28E0: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
28E3: 3E 02       ld   a,$02
28E5: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
28E8: C3 36 29    jp   $2936                 ; jump to QUEUE_EXPLOSION_SOUND


QUEUE_UFO_DEATH_SOUND:
28EB: 3E 04       ld   a,$04
28ED: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND 
28F0: C3 36 29    jp   $2936                 ; jump to QUEUE_EXPLOSION_SOUND

QUEUE_PLAYER_HIT_OBJECT_SOUND:
28F3: 3E 05       ld   a,$05
28F5: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
28F8: C3 36 29    jp   $2936                 ; jump to QUEUE_EXPLOSION_SOUND


QUEUE_ROCKET_EXPLOSION_SOUND:
28FB: 3E 03       ld   a,$03
28FD: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2900: C3 36 29    jp   $2936                 ; jump to QUEUE_EXPLOSION_SOUND

QUEUE_PLAYER_BULLET_FIRED_SOUND:
2903: 3E 06       ld   a,$06
2905: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND 


QUEUE_PLAYER_BOMB_DROP_SOUND:
2908: 3E 20       ld   a,$20
290A: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

290D: C9          ret

; Unused
290E: 3E 0A       ld   a,$0A
2910: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND


;
; You can change the start music for the game by inputting the following into the MAME debugger:
;
; maincpu.mb@2913 = C3
; maincpu.mb@2914 = 1D   (or 2C if you want another tune)
; maincpu.mb@2915 = 29
;

QUEUE_GAME_START_MUSIC:
2913: 3E 09       ld   a,$09
2915: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2918: 3E 0A       ld   a,$0A
291A: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND


;
; This is a nice little jingle that I think was *meant* to be played when you gain an extra life OR you complete all the levels. 
; Its a shame its not played - as far as I know. No code references it and I've never heard it without hacking. 
;

QUEUE_UNUSED_MUSIC_1:
291D: 3E 0B       ld   a,$0B
291F: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2922: 3E 0C       ld   a,$0C
2924: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2927: 3E 0D       ld   a,$0D
2929: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

; Another nice tune that is not used.  
QUEUE_UNUSED_MUSIC_2:
292C: 3E 0E       ld   a,$0E
292E: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2931: 3E 0F       ld   a,$0F
2933: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

QUEUE_EXPLOSION_SOUND:
2936: 3E 13       ld   a,$13
2938: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
293B: 3E 14       ld   a,$14
293D: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2940: 3E 15       ld   a,$15
2942: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

; Unused
2945: 3A 42 42    ld   a,($4242)             ; read IRQTRIGGER_CTRL
2948: F6 40       or   $40
294A: B0          or   b
294B: 32 42 42    ld   ($4242),a             ; set IRQTRIGGER_CTRL
294E: 32 01 82    ld   ($8201),a
2951: C9          ret

; Unused
2952: 3A 42 42    ld   a,($4242)             ; read IRQTRIGGER_CTRL
2955: E6 BF       and  $BF
2957: 32 42 42    ld   ($4242),a             ; set IRQTRIGGER_CTRL
295A: 32 01 82    ld   ($8201),a
295D: AF          xor  a
295E: 32 1C 40    ld   ($401C),a
2961: C9          ret

QUEUE_DEFAULT_AMBIENT_SOUND:
2962: 3E 12       ld   a,$12
2964: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

QUEUE_UFO_AMBIENT_SOUND:
2967: 3E 21       ld   a,$21
2969: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

QUEUE_LOW_FUEL_SOUND:
296C: 3E 07       ld   a,$07
296E: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

QUEUE_FIREBALL_SIZZLING_AMBIENT_SOUND:
2971: 3E 22       ld   a,$22
2973: CD 77 28    call $2877                 ; call QUEUE_SOUND_COMMAND
2976: 3E 23       ld   a,$23
2978: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND

QUEUE_MAZE_AMBIENT_SOUND:
297B: 3E 24       ld   a,$24
297D: C3 77 28    jp   $2877                 ; call QUEUE_SOUND_COMMAND



;
; Play ambient "background" sounds appropriate for the current level 
;

AMBIENT_SOUND:
2980: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
2983: E6 3F       and  $3F                   ;
2985: C0          ret  nz                    ; return if TIMING_VARIABLE modulus 64 !=0 
2986: 3A 05 41    ld   a,($4105)             ; read CURRENT_PLAYER_FUEL
2989: FE 50       cp   $50
298B: DC 6C 29    call c,$296C               ; make "low fuel" sound 

; determine what level player is on 
298E: 3A 1D 41    ld   a,($411D)             ; read LANDSCAPE_FLAGS
2991: FE 00       cp   $00                   ; level 1?
2993: CC 62 29    call z,$2962               ; call QUEUE_DEFAULT_AMBIENT_SOUND
2996: FE 01       cp   $01                   ; level 3? (Yes, 3! Bit flags are not in step with the levels they are used on)
2998: CC 71 29    call z,$2971               ; call QUEUE_FIREBALL_SIZZLING_AMBIENT_SOUND
299B: FE 02       cp   $02                   ; level 2?
299D: 28 0D       jr   z,$29AC               ; call TRY_PLAY_UFO_SOUND
299F: FE 04       cp   $04                   ; level 5?
29A1: CC 7B 29    call z,$297B               ; call QUEUE_MAZE_AMBIENT_SOUND
29A4: FE 08       cp   $08
29A6: CC 62 29    call z,$2962               ; call QUEUE_DEFAULT_AMBIENT_SOUND
29A9: C3 62 29    jp   $2962                 ; jump to QUEUE_DEFAULT_AMBIENT_SOUND

TRY_PLAY_UFO_SOUND:
29AC: 3A 5F 42    ld   a,($425F)             ; read TIMING_VARIABLE
29AF: E6 7F       and  $7F                   ; Only play when TIMING_VARIABLE == 128
29B1: CA 67 29    jp   z,$2967
29B4: C9          ret


;
; Sets CURRENT_PLAYER_FUEL_DRAIN_COUNTER depending on the current level.
;
; The fuel counter effectively determines the fuel drain rate of the current player's jet.
; The lower the fuel counter is set to, the faster the fuel drains from the jet.
;
; Expects:
; HL = $4106 (address of CURRENT_PLAYER_FUEL_DRAIN_COUNTER) 

SET_CURRENT_PLAYER_FUEL_DRAIN_COUNTER:
29B5: 3A 00 41    ld   a,($4100)             ; read CURRENT_PLAYER_MISSIONS_COMPLETED
29B8: A7          and  a                     ; test if on "1ST" level
29B9: 28 09       jr   z,$29C4               ; if on "1ST" level, goto $29C4
29BB: 3D          dec  a                     
29BC: 28 0C       jr   z,$29CA               ; if on "2ND" level, goto $29CA

; player on 3RD level or higher, fastest fuel drain
29BE: 36 06       ld   (hl),$06              ; set CURRENT_PLAYER_FUEL_DRAIN_COUNTER to 6 (fastest drain rate in game) 
29C0: 2D          dec  l                     ; bump HL to point to CURRENT_PLAYER_FUEL
29C1: C3 2E 17    jp   $172E

; player on 1ST level - slowest fuel drain
29C4: 36 0A       ld   (hl),$0A              ; set CURRENT_PLAYER_FUEL_DRAIN_COUNTER to 10 (slowest drain rate in game)
29C6: 2D          dec  l                     ; bump HL to point to CURRENT_PLAYER_FUEL
29C7: C3 2E 17    jp   $172E

; player on 2ND level - faster fuel drain
29CA: 36 08       ld   (hl),$08              ; set CURRENT_PLAYER_FUEL_DRAIN_COUNTER to 8 (median between slowest and fastest)
29CC: 2D          dec  l                     ; bump HL to point to CURRENT_PLAYER_FUEL
29CD: C3 2E 17    jp   $172E



;
; Byte 0: LSB of pointer to a landscape layout. Sets LANDSCAPE_LAYOUT_PTR_LO
;      1: MSB of pointer to a landscape layout. Sets LANDSCAPE_LAYOUT_PTR_HI
;      2: Flags used to determine how the landscape looks, what enemies appear, what ambient sounds play 
;

LANDSCAPE_LAYOUT_METADATA_TABLE:
29D0: 
    E2 29 00     ; pointer to $29E2 (LEVEL_1_LANDSCAPE_LAYOUT), flags = 0
    D3 2D 02     ; pointer to $2DD3 (LEVEL_2_LANDSCAPE_LAYOUT). flags = 2
    C4 31 01     ; pointer to $31C4 (LEVEL_3_LANDSCAPE_LAYOUT). flags = 1
    65 34 08     ; pointer to $3465 (LEVEL_4_LANDSCAPE_LAYOUT). flags = 8     
    56 38 04     ; pointer to $3856 (LEVEL_5_LANDSCAPE_LAYOUT). flags = 4
    47 3C 10     ; pointer to $3C47 (BASE_LANDSCAPE_LAYOUT), flags = 16
    
        
; See docs @ $15C5 (READ_LANDSCAPE_LAYOUT) to understand how layout is structured.
LEVEL_1_LANDSCAPE_LAYOUT:
29E2:  C0 33 BC 31 00 00 B0 32 AB 31 00 00 A0 33 9B 30
29F2:  00 00 93 30 8B 33 00 00 83 30 7B 31 00 00 70 32
2A02:  68 32 00 00 60 34 6B 2D 00 00 73 2D 7B 2E 00 00
2A12:  80 36 80 36 00 01 83 2C 83 30 00 00 80 36 80 36
2A22:  00 01 80 36 80 36 00 00 80 36 80 36 00 01 80 36
2A32:  80 36 00 00 80 36 80 36 00 01 80 36 80 36 00 01
2A42:  80 36 80 36 00 01 80 35 80 35 00 00 80 36 80 36
2A52:  00 04 83 35 7B 30 00 00 73 30 6B 31 00 00 60 32
2A62:  60 2C 00 00 6B 2C 73 2C 00 00 7B 2F 83 2F 00 00
2A72:  8B 2E 93 2D 00 00 98 2E A0 2E 00 00 AB 2D B0 2F
2A82:  00 00 BB 2C C3 2C 00 00 C8 36 C8 2E 00 00 D3 2D
2A92:  DB 2E 00 00 E0 36 E0 36 00 01 E0 36 E0 36 00 01
2AA2:  D8 32 D8 35 00 00 DB 2C E0 36 00 00 E0 36 E0 36
2AB2:  00 02 E0 36 E0 36 00 02 E0 36 D8 34 00 00 E0 36
2AC2:  E0 36 00 01 E0 36 E0 36 00 01 E0 36 E0 36 00 04
2AD2:  D8 32 D8 35 00 00 D0 30 D0 2D 00 00 DB 2F E0 36
2AE2:  00 00 E0 36 E0 36 00 00 E0 36 E0 36 00 01 E0 36
2AF2:  E0 36 00 00 E0 36 E0 36 00 01 E0 36 E0 36 00 00
2B02:  E0 36 E0 36 00 01 E0 36 E0 36 00 04 E0 36 E0 36
2B12:  00 02 D8 30 D3 30 00 00 D0 2C D8 2E 00 00 E0 36
2B22:  E0 36 00 01 E0 36 DB 33 00 00 D0 33 CB 33 00 00
2B32:  C8 36 C8 36 00 01 C0 31 C0 36 00 00 C0 36 C0 36
2B42:  00 01 B9 34 C0 35 00 00 C0 36 C0 36 00 01 B8 34
2B52:  B8 33 00 00 B8 36 B8 36 00 01 B8 36 B8 36 00 01
2B62:  B0 33 A8 34 00 00 B0 36 B0 36 00 04 B0 36 B0 36
2B72:  00 02 A8 33 A0 32 00 00 A0 36 A0 36 00 01 A0 36
2B82:  A0 36 00 01 98 34 98 30 00 00 98 2C 98 33 00 00
2B92:  98 36 98 36 00 01 98 36 98 36 00 01 90 34 90 33
2BA2:  00 00 90 36 90 36 00 01 90 36 90 36 00 01 8B 32
2BB2:  83 31 00 00 7B 33 73 34 00 00 7B 2D 83 2E 00 00
2BC2:  8B 2D 93 2F 00 00 9B 2C A3 2E 00 00 AB 2C B3 2D
2BD2:  00 00 B8 36 B8 36 00 01 B8 36 B8 36 00 01 B3 32
2BE2:  AB 33 00 00 A0 34 A0 34 00 00 A8 36 A8 36 00 01
2BF2:  A3 32 9B 32 00 00 90 34 98 35 00 00 98 36 98 36
2C02:  00 01 93 30 8B 33 00 00 83 32 7B 30 00 00 73 33
2C12:  6B 31 00 00 60 34 6B 2E 00 00 70 35 70 2E 00 00
2C22:  78 36 78 36 00 01 7B 2D 83 2D 00 00 88 36 88 36
2C32:  00 02 8B 2F 93 2D 00 00 9B 2E A0 35 00 00 A0 36
2C42:  A0 36 00 01 A3 2C A3 30 00 00 9B 33 90 33 00 00
2C52:  90 36 90 36 00 01 90 36 90 36 00 04 88 30 88 2C
2C62:  00 00 90 36 90 36 00 01 88 34 93 2E 00 00 9B 2D
2C72:  A3 2F 00 00 AB 2C B3 2E 00 00 BB 2F C3 2C 00 00
2C82:  C8 36 CB 2E 00 00 D0 36 D0 36 00 01 D0 35 C8 34
2C92:  00 00 D0 36 D0 36 00 02 D0 36 D0 36 00 02 CB 31
2CA2:  C3 33 00 00 C0 36 C0 36 00 01 C0 36 BB 32 00 00
2CB2:  B0 30 B0 2E 00 00 B8 36 B3 33 00 00 AB 32 AB 2C
2CC2:  00 00 B3 2C BB 2C 00 00 C3 2C C8 36 00 00 C8 36
2CD2:  C8 36 00 01 C8 36 C8 35 00 00 C8 36 C0 34 00 00
2CE2:  CB 2C D3 2C 00 00 DB 2C DB 30 00 00 D8 36 D8 36
2CF2:  00 02 DB 2D E0 36 00 00 E0 36 E0 36 00 04 D8 34
2D02:  D8 30 00 00 D8 36 D8 36 00 01 D3 30 CB 32 00 00
2D12:  C8 36 C8 36 00 01 C8 36 C8 36 00 04 CB 2C D0 35
2D22:  00 00 CB 30 C8 36 00 00 C0 33 BB 33 00 00 B3 31
2D32:  AB 33 00 00 A0 34 A8 35 00 00 A8 36 A8 36 00 01
2D42:  A8 36 A8 36 00 01 A8 36 A8 36 00 04 A8 36 A8 36
2D52:  00 02 A8 35 A8 2C 00 00 B0 36 B0 36 00 01 B0 36
2D62:  B0 36 00 01 B0 36 B0 36 00 01 B0 36 B0 36 00 00
2D72:  A8 34 A8 31 00 00 A8 36 A8 36 00 02 A8 36 A8 36
2D82:  00 01 A8 36 A8 36 00 04 AB 2F B3 2E 00 00 BB 2D
2D92:  C0 35 00 00 C0 36 C0 36 00 02 BB 31 B3 32 00 00
2DA2:  AB 31 A0 34 00 00 A3 31 9B 32 00 00 93 33 90 35
2DB2:  00 00 8B 32 80 34 00 00 8B 2C 93 2E 00 00 9B 2F
2DC2:  A3 2C 00 00 AB 2D B3 2E 00 00 BB 2D C3 2F 00 00
2DD2:  FF   

LEVEL_2_LANDSCAPE_LAYOUT:
2DD3:  C8 2E D0 36 28 63 28 5E 00 D0 36 D0 2D 28 5E 30
2DE3:  63 00 D8 36 D8 36 30 5E 30 5E 02 D8 2F E0 36 38
2DF3:  63 38 5E 00 E0 36 D8 31 38 5E 40 63 00 D0 30 C8
2E03:  30 48 62 48 62 00 C0 30 B8 31 48 5D 50 62 00 B8
2E13:  36 B8 35 50 5E 5F 62 00 B0 34 B8 2C 5F 5D 5F 60
2E23:  00 C0 35 B8 34 50 60 48 60 00 C0 2D C8 2C 48 62
2E33:  50 62 00 D0 36 D0 2C 50 60 50 62 00 D8 2D D8 31
2E43:  5F 62 5F 60 00 D0 32 C8 31 5F 62 5F 60 00 C0 32
2E53:  C0 2F 50 60 48 60 00 C8 2F C8 33 48 62 48 60 00
2E63:  C8 2C D0 2C 40 60 38 60 00 D0 30 D0 2D 38 62 40
2E73:  62 00 D0 31 C8 34 48 62 48 60 00 C8 30 C0 30 40
2E83:  60 38 61 00 B8 30 B0 30 38 62 40 63 00 B0 2C B0
2E93:  30 40 60 38 61 00 B0 36 B0 2C 30 60 30 62 00 B8
2EA3:  2C B8 30 38 62 38 60 00 B8 2C C0 2C 30 60 30 62
2EB3:  00 C8 36 C0 30 38 62 40 5C 00 C0 2C C8 35 38 60
2EC3:  30 61 00 C0 30 C0 2C 28 5E 28 60 00 C0 31 B8 30
2ED3:  28 62 30 62 00 B0 32 B0 36 38 62 40 62 00 B0 2E
2EE3:  B8 2D 48 62 50 62 00 C0 2E C8 2D 5F 62 5F 3A 00
2EF3:  D0 36 D0 36 5F 3A 5F 60 01 D0 36 D0 36 50 3A 50
2F03:  3A 02 D0 36 D0 36 5F 62 5F 3A 01 D0 36 D0 36 5F
2F13:  3A 5F 3A 02 D0 36 D0 2E 5F 3A 5F 3A 00 D8 36 D8
2F23:  36 5F 3A 5F 60 04 D8 36 D8 36 50 60 48 60 04 D0
2F33:  32 D0 36 40 60 38 60 00 D0 36 D0 36 30 3A 30 3A
2F43:  01 C8 31 C0 32 30 3A 30 3A 00 C0 36 C0 36 30 3A
2F53:  30 3A 01 B8 31 B0 32 30 3A 30 60 00 B0 36 B0 36
2F63:  28 3A 28 3A 00 B0 36 B0 36 28 3A 28 3A 00 B0 2E
2F73:  B8 2D 30 62 30 3A 00 C0 36 C0 2E 30 3A 30 3A 00
2F83:  C8 36 C8 36 38 62 40 62 04 C8 36 C8 36 48 62 48
2F93:  3A 01 C8 2E D0 36 48 3A 50 62 00 D0 36 D0 36 5F
2FA3:  62 5F 3A 04 D0 36 D0 2D 5F 3A 5F 60 00 D8 36 D8
2FB3:  36 50 60 48 60 01 D8 36 D8 36 40 60 38 60 02 D0
2FC3:  31 C8 32 30 60 28 60 00 C0 31 B8 30 28 62 30 62
2FD3:  00 B0 32 B0 36 38 62 40 62 00 B0 2E B8 2D 48 62
2FE3:  50 62 00 C0 2E C8 2D 5F 62 5F 3A 00 D0 36 D0 36
2FF3:  5F 3A 5F 60 01 D0 36 D0 36 50 3A 50 3A 01 D0 36
3003:  D0 36 5F 62 5F 3A 02 D0 36 D0 36 5F 3A 5F 3A 02
3013:  D0 36 D0 2E 5F 3A 5F 3A 00 D8 36 D8 36 5F 3A 5F
3023:  60 01 D8 36 D8 36 50 60 48 60 01 D0 32 D0 36 40
3033:  60 38 60 00 D0 36 D0 36 30 3A 30 3A 04 C8 31 C0
3043:  32 30 3A 30 3A 00 C0 36 C0 36 30 3A 30 3A 01 B8
3053:  31 B0 32 30 3A 30 60 00 B0 36 B0 36 28 3A 28 3A
3063:  00 B0 36 B0 36 28 3A 28 3A 00 B0 2E B8 2D 30 62
3073:  30 3A 00 C0 36 C0 2E 30 3A 30 3A 00 C8 36 C8 36
3083:  38 62 40 62 04 C8 36 C8 36 48 62 48 3A 04 C8 2E
3093:  D0 36 48 3A 50 62 00 D0 36 D0 36 5F 62 5F 3A 01
30A3:  D0 36 D0 2D 5F 3A 5F 60 00 D8 36 D8 36 50 60 48
30B3:  60 04 D8 36 D8 36 40 60 38 60 04 D0 31 C8 32 30
30C3:  60 28 60 00 C8 2C D0 2C 28 62 30 62 00 D8 2C E0
30D3:  36 38 62 40 62 00 E0 36 E0 36 48 62 50 62 01 E0
30E3:  36 D8 34 5F 5C 50 60 00 E0 36 E0 36 48 60 40 60
30F3:  02 E0 36 E0 36 38 60 30 60 01 E0 36 E0 36 28 5E
3103:  30 62 01 D8 34 E0 36 36 5C 30 60 00 E0 36 E0 36
3113:  28 5E 30 5C 04 E0 36 E0 36 28 5E 30 62 01 E0 36
3123:  E0 36 38 62 40 62 04 D8 30 D0 30 48 62 57 5C 00
3133:  C8 30 C0 30 48 60 40 60 00 B8 30 B0 34 38 60 30
3143:  60 00 B8 2C C0 2C 28 3A 28 3A 00 C8 2C D0 2C 28
3153:  3A 28 3A 00 D8 2C D8 34 28 3A 28 3A 00 E0 36 E0
3163:  36 28 3A 30 5C 01 E0 36 E0 36 28 3A 28 3A 02 D8
3173:  30 D0 34 28 3A 28 3A 00 D8 2C E0 36 28 3A 28 3A
3183:  00 E0 36 E0 36 28 3A 28 3A 01 E0 36 E0 36 28 3A
3193:  28 3A 01 E0 36 E0 36 28 3A 28 3A 01 E0 36 D8 34
31A3:  28 3A 28 3A 00 E0 36 E0 36 28 3A 28 3A 04 E0 36
31B3:  D8 30 28 3A 28 3A 00 D0 30 C8 30 28 3A 28 60 00
31C3:  FF  


LEVEL_3_LANDSCAPE_LAYOUT:
31C4:  C8 36 CB 2E 00 00 D3 2C DB 2E 00 00 E0 36 E0 36
31D4:  00 01 DB 30 D3 33 00 00 D0 35 CB 32 00 00 C3 33
31E4:  B8 30 00 00 BB 2F C3 2D 00 00 CB 2E D3 2C 00 00
31F4:  DB 2E E0 36 00 00 E0 36 E0 36 00 01 E0 36 E0 36
3204:  00 02 E0 36 E0 36 00 01 DB 30 D0 32 00 00 D3 2E
3214:  DB 2C 00 00 DB 30 D3 32 00 00 C8 34 D3 2F 00 00
3224:  D8 36 D8 36 00 02 D3 30 CB 33 00 00 C3 30 BB 33
3234:  00 00 B8 2F B8 30 00 00 B8 2E C3 2D 00 00 CB 2C
3244:  D3 2F 00 00 D8 36 D8 36 00 01 D8 36 DB 2E 00 00
3254:  E0 36 E0 36 00 04 E0 36 E0 36 00 02 E0 36 DB 33
3264:  00 00 D3 30 C8 30 00 00 C0 33 B8 34 00 00 C3 2F
3274:  CB 2D 00 00 D3 2C DB 2F 00 00 E0 36 E0 36 00 02
3284:  D8 32 D8 35 00 00 DB 2C E0 36 00 00 E0 36 E0 36
3294:  00 04 E0 36 E0 36 00 04 E0 36 D8 34 00 00 E0 36
32A4:  E0 36 00 02 E0 36 E0 36 00 01 E0 36 E0 36 00 01
32B4:  D8 32 D8 35 00 00 D0 30 D0 2D 00 00 DB 2F E0 36
32C4:  00 00 E0 36 E0 36 00 04 E0 36 E0 36 00 04 E0 36
32D4:  E0 36 00 01 E0 36 E0 36 00 02 E0 36 E0 36 00 01
32E4:  DB 30 D3 31 00 00 CB 32 C3 33 00 00 BB 31 BB 2C
32F4:  00 00 C3 2D CB 2E 00 00 D0 2C D8 2E 00 00 E0 36
3304:  E0 36 00 02 E0 36 DB 33 00 00 D0 33 CB 33 00 00
3314:  C8 36 CB 2E 00 00 D3 2C DB 2E 00 00 E0 36 E0 36
3324:  00 04 DB 30 D3 33 00 00 D0 35 CB 32 00 00 C3 33
3334:  B8 30 00 00 BB 2F C3 2D 00 00 CB 2E D3 2C 00 00
3344:  DB 2E E0 36 00 00 E0 36 E0 36 00 02 E0 36 E0 36
3354:  00 01 E0 36 E0 36 00 01 DB 30 D0 32 00 00 D3 2E
3364:  DB 2C 00 00 DB 30 D3 32 00 00 C8 34 D3 2F 00 00
3374:  D8 36 D8 36 00 02 D3 30 CB 33 00 00 C3 30 BB 33
3384:  00 00 B8 2F B8 30 00 00 B8 2E C3 2D 00 00 CB 2C
3394:  D3 2F 00 00 D8 36 D8 36 00 00 D8 36 DB 2E 00 00
33A4:  E0 36 E0 36 00 04 E0 36 E0 36 00 02 E0 36 DB 33
33B4:  00 00 D3 30 C8 30 00 00 C8 36 CB 2E 00 00 D3 2C
33C4:  DB 2E 00 00 E0 36 E0 36 00 01 DB 30 D3 33 00 00
33D4:  D0 35 CB 32 00 00 C3 33 B8 30 00 00 BB 2F C3 2D
33E4:  00 00 CB 2E D3 2C 00 00 DB 2E E0 36 00 00 E0 36
33F4:  E0 36 00 01 E0 36 E0 36 00 01 E0 36 E0 36 00 02
3404:  DB 30 D0 32 00 00 D3 2E DB 2C 00 00 DB 30 D3 32
3414:  00 00 C8 34 D3 2F 00 00 D8 36 D8 36 00 02 D3 30
3424:  CB 33 00 00 C3 30 BB 33 00 00 B8 2F B8 30 00 00
3434:  B8 2E C3 2D 00 00 CB 2C D3 2F 00 00 D8 36 D8 36
3444:  00 00 D8 36 DB 2E 00 00 E0 36 E0 36 00 02 E0 36
3454:  E0 36 00 04 E0 36 DB 33 00 00 D3 30 C8 30 00 00
3464:  FF   


LEVEL_4_LANDSCAPE_LAYOUT:
3465:  60 D1 60 D1 00 00 60 D1 60 D1 00 00 60 D1 60 D1
3475:  00 00 60 D1 60 D1 00 00 70 D1 70 D1 00 01 60 D1
3485:  60 D1 00 01 60 D1 60 D1 00 00 78 D1 78 D1 00 01
3495:  60 D1 60 D1 00 01 48 D1 48 D1 00 00 58 D1 58 D1
34A5:  00 01 48 D1 48 D1 00 00 58 D1 58 D1 00 01 58 D1
34B5:  58 D1 00 01 68 D1 68 D1 00 01 68 D1 68 D1 00 02
34C5:  78 D1 78 D1 00 01 78 D1 78 D1 00 01 88 D1 88 D1
34D5:  00 01 88 D1 88 D1 00 02 98 D1 98 D1 00 01 98 D1
34E5:  98 D1 00 01 90 D1 90 D1 00 04 90 D1 90 D1 00 04
34F5:  90 D1 90 D1 00 01 90 D1 90 D1 00 00 A0 D1 A0 D1
3505:  00 01 80 D1 80 D1 00 00 90 D1 90 D1 00 01 70 D1
3515:  70 D1 00 00 80 D1 80 D1 00 01 60 D1 60 D1 00 00
3525:  70 D1 70 D1 00 01 50 D1 50 D1 00 00 60 D1 60 D1
3535:  00 01 50 D1 50 D1 00 00 48 D1 48 D1 00 00 58 D1
3545:  58 D1 00 01 50 D1 50 D1 00 00 50 D1 50 D1 00 00
3555:  60 D1 60 D1 00 01 58 D1 58 D1 00 00 68 D1 68 D1
3565:  00 01 60 D1 60 D1 00 00 70 D1 70 D1 00 01 68 D1
3575:  68 D1 00 00 78 D1 78 D1 00 01 70 D1 70 D1 00 00
3585:  80 D1 80 D1 00 01 80 D1 80 D1 00 00 80 D1 80 D1
3595:  00 00 80 D1 80 D1 00 04 80 D1 80 D1 00 02 80 D1
35A5:  80 D1 00 04 80 D1 80 D1 00 01 80 D1 80 D1 00 01
35B5:  78 D1 78 D1 00 01 70 D1 70 D1 00 02 68 D1 68 D1
35C5:  00 04 60 D1 60 D1 00 01 60 D1 60 D1 00 01 58 D1
35D5:  58 D1 00 00 58 D1 58 D1 00 00 60 D1 60 D1 00 01
35E5:  48 D1 48 D1 00 00 48 D1 48 D1 00 00 50 D1 50 D1
35F5:  00 01 48 D1 48 D1 00 01 58 D1 58 D1 00 01 48 D1
3605:  48 D1 00 00 50 D1 50 D1 00 01 48 D1 48 D1 00 00
3615:  60 D1 60 D1 00 01 50 D1 50 D1 00 02 40 D1 40 D1
3625:  00 00 60 D1 60 D1 00 01 40 D1 40 D1 00 00 60 D1
3635:  60 D1 00 01 40 D1 40 D1 00 00 50 D1 50 D1 00 01
3645:  40 D1 40 D1 00 00 50 D1 50 D1 00 01 60 D1 60 D1
3655:  00 00 60 D1 60 D1 00 02 60 D1 60 D1 00 00 60 D1
3665:  60 D1 00 02 60 D1 60 D1 00 00 60 D1 60 D1 00 02
3675:  70 D1 70 D1 00 01 60 D1 60 D1 00 01 60 D1 60 D1
3685:  00 00 78 D1 78 D1 00 01 60 D1 60 D1 00 01 48 D1
3695:  48 D1 00 00 58 D1 58 D1 00 01 48 D1 48 D1 00 00
36A5:  58 D1 58 D1 00 01 58 D1 58 D1 00 01 68 D1 68 D1
36B5:  00 01 68 D1 68 D1 00 02 78 D1 78 D1 00 01 78 D1
36C5:  78 D1 00 01 88 D1 88 D1 00 01 88 D1 88 D1 00 02
36D5:  98 D1 98 D1 00 01 98 D1 98 D1 00 01 90 D1 90 D1
36E5:  00 04 90 D1 90 D1 00 04 90 D1 90 D1 00 01 90 D1
36F5:  90 D1 00 00 A0 D1 A0 D1 00 01 80 D1 80 D1 00 00
3705:  90 D1 90 D1 00 01 70 D1 70 D1 00 00 80 D1 80 D1
3715:  00 01 60 D1 60 D1 00 00 70 D1 70 D1 00 01 50 D1
3725:  50 D1 00 00 60 D1 60 D1 00 01 50 D1 50 D1 00 00
3735:  48 D1 48 D1 00 00 58 D1 58 D1 00 01 50 D1 50 D1
3745:  00 00 50 D1 50 D1 00 00 60 D1 60 D1 00 01 58 D1
3755:  58 D1 00 00 68 D1 68 D1 00 01 60 D1 60 D1 00 00
3765:  70 D1 70 D1 00 01 68 D1 68 D1 00 00 78 D1 78 D1
3775:  00 01 70 D1 70 D1 00 00 80 D1 80 D1 00 01 80 D1
3785:  80 D1 00 00 80 D1 80 D1 00 00 80 D1 80 D1 00 04
3795:  80 D1 80 D1 00 02 80 D1 80 D1 00 04 80 D1 80 D1
37A5:  00 01 80 D1 80 D1 00 01 78 D1 78 D1 00 01 70 D1
37B5:  70 D1 00 02 68 D1 68 D1 00 04 60 D1 60 D1 00 01
37C5:  60 D1 60 D1 00 01 58 D1 58 D1 00 00 58 D1 58 D1
37D5:  00 00 60 D1 60 D1 00 01 48 D1 48 D1 00 00 48 D1
37E5:  48 D1 00 00 50 D1 50 D1 00 01 48 D1 48 D1 00 01
37F5:  58 D1 58 D1 00 01 48 D1 48 D1 00 00 50 D1 50 D1
3805:  00 01 48 D1 48 D1 00 00 60 D1 60 D1 00 01 50 D1
3815:  50 D1 00 02 40 D1 40 D1 00 00 60 D1 60 D1 00 01
3825:  40 D1 40 D1 00 00 60 D1 60 D1 00 01 40 D1 40 D1
3835:  00 00 50 D1 50 D1 00 01 60 D1 60 D1 00 00 60 D1
3845:  60 D1 00 00 60 D1 60 D1 00 00 60 D1 60 D1 00 00
3855:  FF  


LEVEL_5_LANDSCAPE_LAYOUT:
3856:  60 D1 60 D1 47 D1 47 D1 02 60 D1 60 D1 47 D1 47
3866:  D1 02 60 D1 60 D1 37 D1 37 D1 00 60 D1 60 D1 37
3876:  D1 37 D1 00 60 D1 60 D1 37 D1 37 D1 00 50 D1 50
3886:  D1 37 D1 37 D1 02 50 D1 50 D1 37 D1 37 D1 00 60
3896:  D1 60 D1 37 D1 37 D1 00 60 D1 60 D1 37 D1 37 D1
38A6:  00 60 D1 60 D1 37 D1 37 D1 00 60 D1 60 D1 47 D1
38B6:  47 D1 00 60 D1 60 D1 47 D1 47 D1 00 60 D1 60 D1
38C6:  47 D1 47 D1 02 60 D1 60 D1 47 D1 47 D1 02 60 D1
38D6:  60 D1 47 D1 47 D1 02 60 D1 60 D1 2F D1 2F D1 02
38E6:  60 D1 60 D1 2F D1 2F D1 00 60 D1 60 D1 2F D1 2F
38F6:  D1 00 40 D1 40 D1 2F D1 2F D1 00 40 D1 40 D1 2F
3906:  D1 2F D1 00 40 D1 40 D1 2F D1 2F D1 00 40 D1 40
3916:  D1 2F D1 2F D1 00 40 D1 40 D1 2F D1 2F D1 00 A0
3926:  D1 A0 D1 2F D1 2F D1 00 A0 D1 A0 D1 2F D1 2F D1
3936:  00 A0 D1 A0 D1 2F D1 2F D1 00 A0 D1 A0 D1 2F D1
3946:  2F D1 00 A0 D1 A0 D1 2F D1 2F D1 02 A0 D1 A0 D1
3956:  2F D1 2F D1 02 A0 D1 A0 D1 37 D1 37 D1 02 A0 D1
3966:  A0 D1 8F D1 8F D1 02 A0 D1 A0 D1 8F D1 8F D1 02
3976:  A0 D1 A0 D1 8F D1 8F D1 02 A0 D1 A0 D1 8F D1 8F
3986:  D1 00 A0 D1 A0 D1 8F D1 8F D1 00 A0 D1 A0 D1 8F
3996:  D1 8F D1 00 D8 D1 D8 D1 8F D1 8F D1 00 D8 D1 D8
39A6:  D1 8F D1 8F D1 00 D8 D1 D8 D1 8F D1 8F D1 00 D8
39B6:  D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8 D1 C7 D1 C7 D1
39C6:  02 D8 D1 D8 D1 C7 D1 C7 D1 02 D8 D1 D8 D1 C7 D1
39D6:  C7 D1 02 D8 D1 D8 D1 C7 D1 C7 D1 02 D8 D1 D8 D1
39E6:  C7 D1 C7 D1 00 D8 D1 D8 D1 3F D1 3F D1 00 D8 D1
39F6:  D8 D1 3F D1 3F D1 00 D8 D1 D8 D1 3F D1 3F D1 00
3A06:  D8 D1 D8 D1 3F D1 3F D1 00 D8 D1 D8 D1 3F D1 3F
3A16:  D1 00 D8 D1 D8 D1 3F D1 3F D1 00 50 D1 50 D1 3F
3A26:  D1 3F D1 00 50 D1 50 D1 3F D1 3F D1 00 50 D1 50
3A36:  D1 3F D1 3F D1 00 50 D1 50 D1 3F D1 3F D1 00 50
3A46:  D1 50 D1 3F D1 3F D1 00 D8 D1 D8 D1 3F D1 3F D1
3A56:  00 D8 D1 D8 D1 3F D1 3F D1 00 D8 D1 D8 D1 3F D1
3A66:  3F D1 00 D8 D1 D8 D1 3F D1 3F D1 00 D8 D1 D8 D1
3A76:  3F D1 3F D1 00 D8 D1 D8 D1 3F D1 3F D1 00 D8 D1
3A86:  D8 D1 3F D1 3F D1 00 D8 D1 D8 D1 C7 D1 C7 D1 00
3A96:  D8 D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8 D1 C7 D1 C7
3AA6:  D1 00 D8 D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8 D1 C7
3AB6:  D1 C7 D1 00 D8 D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8
3AC6:  D1 C7 D1 C7 D1 00 D8 D1 D8 D1 4F D1 4F D1 00 D8
3AD6:  D1 D8 D1 4F D1 4F D1 00 D8 D1 D8 D1 4F D1 4F D1
3AE6:  00 D8 D1 D8 D1 4F D1 4F D1 00 D8 D1 D8 D1 4F D1
3AF6:  4F D1 00 60 D1 60 D1 4F D1 4F D1 00 60 D1 60 D1
3B06:  4F D1 4F D1 00 60 D1 60 D1 4F D1 4F D1 00 60 D1
3B16:  60 D1 37 D1 37 D1 00 60 D1 60 D1 37 D1 37 D1 00
3B26:  48 D1 48 D1 37 D1 37 D1 00 48 D1 48 D1 37 D1 37
3B36:  D1 00 48 D1 48 D1 37 D1 37 D1 00 58 D1 58 D1 37
3B46:  D1 37 D1 00 58 D1 58 D1 37 D1 37 D1 00 58 D1 58
3B56:  D1 47 D1 47 D1 00 58 D1 58 D1 47 D1 47 D1 00 58
3B66:  D1 58 D1 47 D1 47 D1 00 58 D1 58 D1 47 D1 47 D1
3B76:  00 D8 D1 D8 D1 47 D1 47 D1 00 D8 D1 D8 D1 47 D1
3B86:  47 D1 00 D8 D1 D8 D1 47 D1 47 D1 00 D8 D1 D8 D1
3B96:  47 D1 47 D1 00 D8 D1 D8 D1 47 D1 47 D1 00 D8 D1
3BA6:  D8 D1 C7 D1 C7 D1 00 D8 D1 D8 D1 C7 D1 C7 D1 00
3BB6:  D8 D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8 D1 C7 D1 C7
3BC6:  D1 00 D8 D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8 D1 C7
3BD6:  D1 C7 D1 00 D8 D1 D8 D1 C7 D1 C7 D1 00 D8 D1 D8
3BE6:  D1 C7 D1 C7 D1 00 D8 D1 D8 D1 3F D1 3F D1 00 D8
3BF6:  D1 D8 D1 3F D1 3F D1 00 D8 D1 D8 D1 3F D1 3F D1
3C06:  00 D8 D1 D8 D1 3F D1 3F D1 00 D8 D1 D8 D1 3F D1
3C16:  3F D1 00 D8 D1 D8 D1 3F D1 3F D1 00 50 D1 50 D1
3C26:  3F D1 3F D1 00 60 D1 60 D1 3F D1 3F D1 00 60 D1
3C36:  60 D1 3F D1 3F D1 00 60 D1 60 D1 3F D1 3F D1 00
3C46:  FF  


; Final level
BASE_LANDSCAPE_LAYOUT:
3C47:  C8 D1 C8 D1 00 00 C8 D1 C8 D1 00 00 90 D1 90 D1
3C57:  00 00 50 D1 50 D1 00 00 90 D1 90 D1 00 00 C8 D1
3C67:  C8 D1 00 00 C8 D1 C8 D1 00 00 98 D1 98 D1 00 00
3C77:  98 D1 98 D1 00 00 98 D1 98 D1 00 00 C8 D1 C8 D1
3C87:  00 00 48 1B 48 1F 00 00 48 1E 48 11 00 00 48 1D
3C97:  48 19 00 00 C8 D1 C8 D1 00 00 98 D1 98 D1 00 00
3CA7:  98 D1 98 D1 00 00 98 D1 98 D1 00 00 C8 D1 C8 D1
3CB7:  00 00 C8 D1 C8 D1 00 00 C8 D1 C8 D1 00 08 C8 D1
3CC7:  C8 D1 00 00 C8 D1 C8 D1 00 00 C8 D1 C8 D1 00 00
3CD7:  70 D1 70 D1 00 00 70 D1 70 D1 00 00 C8 D1 C8 D1
3CE7:  00 00 C8 D1 C8 D1 00 00 FF 