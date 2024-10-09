; ---------------------------------------------------------------------------
; Title	screen
; ---------------------------------------------------------------------------

GM_Title:
		play_stop					; stop music
		bsr.w	PaletteFadeOut				; fade from previous gamemode to black
		disable_ints
		bsr.w	DacDriverLoad
		lea	(vdp_control_port).l,a6
		move.w	#vdp_md_color,(a6)			; normal colour mode
		move.w	#vdp_fg_nametable+(vram_fg>>10),(a6)	; set foreground nametable address
		move.w	#vdp_bg_nametable+(vram_bg>>13),(a6)	; set background nametable address
		move.w	#vdp_plane_width_64|vdp_plane_height_32,(a6) ; 64x32 cell plane size
		move.w	#vdp_full_vscroll|vdp_1px_hscroll,(a6)	; single pixel line horizontal scrolling
		move.w	#vdp_bg_color+$20,(a6)			; set background colour (palette line 2, entry 0)
		clr.b	(f_water_pal_full).w
		bsr.w	ClearScreen

		lea	(v_ost_all).w,a1			; RAM address to start clearing
		move.w	#loops_to_clear_ost,d1			; size of RAM block to clear
		bsr.w	ClearRAM				; fill OST with 0

		lea	(v_pal_dry).w,a1
		moveq	#loops_to_clear_pal,d1
		bsr.w	ClearRAM

		moveq	#id_Pal_Sonic,d0			; load Sonic's palette
		bsr.w	PalLoad					; palette will be shown after fading in
		jsr	FindFreeInert
		move.l	#CreditsText,ost_id(a1)			; load "SONIC TEAM PRESENTS" object
		bsr.w	ExecuteObjects
		bsr.w	BuildSprites
		bsr.w	PaletteFadeIn				; fade in to "SONIC TEAM PRESENTS" screen from black
		moveq	#id_VBlank_Title,d1
		moveq	#60,d0
		bsr.w	WaitLoop				; freeze for 1 second
		disable_ints

		moveq	#0,d0
		move.b	d0,(v_last_lamppost).w			; clear lamppost counter
		move.w	d0,(v_debug_active).w			; disable debug item placement mode
		move.w	d0,(v_demo_mode).w			; disable debug mode
		move.w	#id_GHZ_act1,(v_zone).w			; set level to GHZ act 1 (0000)
		move.w	d0,(v_palcycle_time).w			; disable palette cycling
		bsr.w	PaletteFadeOut				; fade out "SONIC TEAM PRESENTS" screen to black
		moveq	#id_SPLC_Title,d0
		jsr	SlowPLC_Now				; load title screen gfx
		bsr.w	LoadPerZone
		bsr.w	LevelParameterLoad			; set level boundaries and Sonic's start position
		bsr.w	DeformLayers
		lea	Level_GHZ_bg,a1
		lea	(v_bg_layout).w,a2
		bsr.w	HiveDec					; load GHZ background
		disable_ints
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a6
		lea	(v_bg1_x_pos).w,a3
		lea	(v_bg_layout).w,a4			; background layout start address
		move.w	#draw_bg,d2
		jsr	DrawChunks				; draw background

		lea	($FF0000).l,a1				; RAM buffer
		lea	(KosMap_Title).l,a0			; title screen mappings
		locVRAM	vram_fg+(sizeof_vram_row*4)+(3*2),d0	; foreground, x=3, y=4
		moveq	#$22,d1					; width
		moveq	#$16,d2					; height
		move.w	#tile_Kos_TitleFg,d3			; tile setting
		bsr.w	LoadTilemap

		moveq	#id_Pal_Title,d0			; load title screen palette
		bsr.w	PalLoad
		play_music mus_TitleScreen			; play title screen music
		clr.b	(f_debug_enable).w			; disable debug mode
		move.w	#406,(v_countdown).w			; run title screen for 406 frames

		jsr	FindFreeInert
		bne.s	.no_slots
		move.l	#TitleSonic,ost_id(a1)			; load big Sonic object
		move.b	#104,(v_spritemask_pos).w
		move.b	#80,(v_spritemask_height).w

		jsr	FindFreeInert
		bne.s	.no_slots
		move.l	#PSBTM,ost_id(a1)			; load "PRESS START BUTTON" object
		move.b	#0,ost_subtype(a1)

		jsr	FindFreeInert
		bne.s	.no_slots
		move.l	#PSBTM,ost_id(a1)			; load "TM" object
		move.b	#1,ost_subtype(a1)

	.no_slots:
		bsr.w	ExecuteObjects
		bsr.w	DeformLayers
		bsr.w	BuildSprites
		clr.w	(v_title_d_count).w			; reset d-pad counter
		enable_display
		bsr.w	PaletteFadeIn				; fade in to title screen from black

; ---------------------------------------------------------------------------
; Title	screen main loop
; ---------------------------------------------------------------------------

Title_MainLoop:
		move.b	#id_VBlank_Title,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		bsr.w	ExecuteObjects				; run all objects
		bsr.w	DeformLayers				; scroll background
		bsr.w	BuildSprites				; create sprite table
		bsr.w	PCycle_Title				; animate water palette
		addq.w	#2,(v_ost_player+ost_x_pos).w		; move dummy object 2px to the right (there is no actual object loaded)
		bsr.s	Title_Dpad
		tst.w	(v_countdown).w				; has counter hit 0? (started at 406)
		beq.w	PlayDemo				; if yes, branch
		andi.b	#btnStart,(v_joypad_press_actual).w	; check if Start is pressed
		beq.s	Title_MainLoop				; if not, branch

		tst.b	(f_levelselect_cheat).w			; check if level select code is on
		beq.w	PlayLevel				; if not, play level
		btst	#bitA,(v_joypad_hold_actual).w		; check if A is pressed
		beq.w	PlayLevel				; if not, play level
		bra.w	SuperSelect				; goto level select
; ===========================================================================

Title_Dpad:
		tst.b	(f_levelselect_cheat).w
		bne.s	.exit					; branch if code has been entered
		move.w	(v_title_d_count).w,d0			; get number of times d-pad has been pressed in correct order
		lea	LevSelCode(pc,d0.w),a0			; jump to relevant position in cheat code
		move.b	(v_joypad_press_actual).w,d1		; get button press
		andi.b	#btnDir,d1				; read only UDLR buttons
		beq.s	.exit					; branch if not pressed
		cmp.b	(a0),d1					; does button press match the cheat code?
		bne.s	.reset_cheat				; if not, branch
		addq.w	#1,(v_title_d_count).w			; next input
		tst.b	1(a0)
		bmi.s	.complete				; branch if next input is $FF

	.exit:
		rts

	.reset_cheat:
		move.w	#0,(v_title_d_count).w			; reset cheat counter
		rts

	.complete:
		move.b	#1,(f_levelselect_cheat).w		; set level select flag
		move.b	#1,(f_debug_cheat).w			; set debug mode flag
		play_sound sfx_Ring				; play ring sound
		rts

LevSelCode:	dc.b btnUp,btnDn,btnL,btnR,$FF
		even
; ===========================================================================

LevSel_Init:
		moveq	#id_Pal_LevelSel,d0
		bsr.w	PalLoad					; load level select palette
		lea	(v_hscroll_buffer).w,a1
		move.w	#loops_to_clear_hscroll,d1
		bsr.w	ClearRAM				; clear hscroll buffer (in RAM)

		clr.l	(v_fg_y_pos_vsram).w
		disable_ints

		locVRAM	vram_bg,d0
		set_dma_fill_size	sizeof_vram_bg,d1
		bsr.w	ClearVRAM				; clear bg nametable (in VRAM)

		bsr.w	LevSel_Display

; ---------------------------------------------------------------------------
; Level	Select loop
; ---------------------------------------------------------------------------

LevelSelect:
		move.b	#id_VBlank_Title,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		bsr.s	LevSel_Control
		bsr.s	LevSel_Hold
		bsr.w	LevSel_Select
		beq.s	LevelSelect				; branch if d0 is 0
		rts						; exit level select if d0 is 1

linesize:	equ LevSel_Strings_end1-LevSel_Strings-6	; characters per line
linecount:	equ (LevSel_Strings_end2-LevSel_Strings)/(linesize+6) ; number of lines
lineleft:	equ 1						; where on screen to start drawing
linetop:	equ 4
linestart:	equ (sizeof_vram_row*linetop)+(lineleft*2)	; address in nametable
linecolumn:	equ 19						; lines per column (set as linecount for 1 column)
columnwidth:	equ linesize+2					; spacing between columns
linesound:	equ (LevSel_Strings_sound-LevSel_Strings)/(linesize+6) ; line number with sound test
linecharsel:	equ (LevSel_Strings_charsel-LevSel_Strings)/(linesize+6) ; line number with character select
charselsize:	equ LevSel_CharStrings_end-LevSel_CharStrings	; characters per character name

LevSel_Control:
		move.w	(v_levelselect_item).w,d0
		move.b	(v_joypad_press_actual).w,d1
		beq.s	.exit					; branch if nothing is pressed
		move.w	#8,(v_levelselect_hold_delay).w		; reset timer for autoscroll

		btst	#bitDn,d1
		beq.s	.not_down				; branch if down isn't pressed
		bsr.s	LevSel_Down

	.not_down:
		btst	#bitUp,d1
		beq.s	.not_up					; branch if up isn't pressed
		bsr.s	LevSel_Up

	.not_up:
		btst	#bitR,d1
		beq.s	.not_right				; branch if right isn't pressed
		bsr.s	LevSel_Right

	.not_right:
		btst	#bitL,d1
		beq.s	.not_left				; branch if right isn't pressed
		bsr.w	LevSel_Left

	.not_left:
		move.w	d0,(v_levelselect_item).w		; set new selection
		bra.w	LevSel_Display

	.exit:
		rts

LevSel_Hold:
		move.w	(v_levelselect_item).w,d0
		move.b	(v_joypad_hold_actual).w,d1
		andi.b	#btnUp+btnDn,d1				; is up/down currently held?
		beq.s	.exit					; branch if not
		subq.w	#1,(v_levelselect_hold_delay).w		; decrement timer
		bpl.s	.exit					; branch if time remains
		move.w	#8,(v_levelselect_hold_delay).w		; reset timer

		btst	#bitDn,d1
		beq.s	.not_down				; branch if down isn't held
		bsr.s	LevSel_Down

	.not_down:
		btst	#bitUp,d1
		beq.s	.not_up					; branch if up isn't held
		bsr.s	LevSel_Up

	.not_up:
		move.w	d0,(v_levelselect_item).w		; set new selection
		bra.w	LevSel_Display

	.exit:
		rts

LevSel_Down:
		addq.w	#1,d0					; goto next item
		cmpi.w	#linecount,d0
		bne.s	.exit					; branch if item is valid
		moveq	#0,d0					; jump to start after last item
	.exit:
		rts

LevSel_Up:
		subq.w	#1,d0					; goto previous item
		bpl.s	.exit					; branch if item is valid
		moveq	#linecount-1,d0				; jump to end before first item
	.exit:
		rts

LevSel_Right:
		cmpi.w	#linesound,d0
		bne.s	.not_soundtest				; branch if not on sound test
		addq.w	#1,(v_levelselect_sound).w		; increment sound test
		cmpi.w	#$50,(v_levelselect_sound).w
		bne.s	.exit					; branch if valid
		clr.w	(v_levelselect_sound).w		; reset to 0 if above max
		bra.s	.exit
	.not_soundtest:
		cmpi.w	#linecharsel,d0
		bne.s	.not_charsel				; branch if not on character select
		addq.w	#1,(v_character1).w			; increment character select
		cmpi.w	#3,(v_character1).w
		bne.s	.exit					; branch if valid
		clr.w	(v_character1).w			; reset to 0 if above max
		bra.s	.exit
	.not_charsel:
		addi.w	#linecolumn,d0				; goto next column
		cmpi.w	#linecount,d0
		blt.s	.exit					; branch if item is valid
		subi.w	#linecolumn,d0				; undo
	.exit:
		rts

LevSel_Left:
		cmpi.w	#linesound,d0
		bne.s	.not_soundtest				; branch if not on sound test
		subq.w	#1,(v_levelselect_sound).w		; increment sound test
		bpl.s	.exit					; branch if valid
		move.w	#$4F,(v_levelselect_sound).w		; jump to $4F if below 0
		bra.s	.exit
	.not_soundtest:
		cmpi.w	#linecharsel,d0
		bne.s	.not_charsel				; branch if not on character select
		subq.w	#1,(v_character1).w			; increment character select
		bpl.s	.exit					; branch if valid
		move.w	#2,(v_character1).w			; jump to 2 if below 0
		bra.s	.exit
	.not_charsel:
		subi.w	#linecolumn,d0				; goto previous column
		bpl.s	.exit					; branch if item is valid
		addi.w	#linecolumn,d0				; undo
	.exit:
		rts

LevSel_Display:
		lea	LevSel_Strings(pc),a1
		lea	LevSel_CharStrings(pc),a2
		lea	(vdp_control_port).l,a6
		locVRAM	vram_bg+linestart,d3
		move.l	d3,d4
		moveq	#linecount-1,d0
		moveq	#0,d5
		moveq	#0,d6

	.loop:
		move.l	d3,(a6)
		bsr.w	LevSel_Line				; draw line of text
		addq.w	#6,a1				; next string
		addi.l	#sizeof_vram_row<<16,d3			; jump to next line in nametable
		addq.w	#1,d5					; count line number in current column
		addq.w	#1,d6					; count line number overall
		cmpi.w	#linecolumn,d5
		bne.s	.not_last				; branch if not last line in column
		addi.l	#(columnwidth*2)<<16,d4			; jump to next column
		move.l	d4,d3					; update drawing position
		moveq	#0,d5

	.not_last:
		dbf	d0,.loop				; repeat for all lines
		rts

LevSel_Line:
		moveq	#linesize-1,d1

	.loop:
		moveq	#0,d2
		move.b	(a1)+,d2				; get character
		cmpi.w	#linesound,d6				; d6 = current line being drawn
		bne.s	.not_soundtest				; branch if not the sound test
		cmpi.w	#1,d1
		bgt.s	.not_soundtest				; branch if not the last 2 characters on the line
		move.w	(v_levelselect_sound).w,d2		; get current sound test
		addi.b	#$80,d2
		lsl.w	#2,d1					; multiply character number by 4 (so it's either 4 or 0)
		lsr.b	d1,d2					; move high nybble to low if d1 is 4
		andi.b	#$F,d2					; read single nybble
		addi.b	#$30,d2					; convert to character
		lsr.w	#2,d1					; restore d1

	.not_soundtest:
		cmpi.w	#linecharsel,d6				; d6 = current line being drawn
		bne.s	.not_charsel				; branch if not the character select
		cmpi.w	#charselsize-1,d1
		bgt.s	.not_charsel				; branch if not the last 8 characters on the line
		move.w	(v_character1).w,d2			; get character id
		lsl.w	#3,d2					; multiply by 8
		subi.w	#charselsize-1,d1
		neg.w	d1					; invert value d1
		add.w	d1,d2					; add d1
		neg.w	d1
		addi.w	#charselsize-1,d1			; restore d1
		move.b	(a2,d2.w),d2				; get character

	.not_charsel:
		addi.w	#tile_Kos_Text+tile_pal4+tile_hi-$20,d2	; convert to tile
		cmp.w	(v_levelselect_item).w,d6		; d6 = current line being drawn
		bne.s	.unselected				; branch if line is not selected
		subi.w	#$2000,d2				; use yellow text

	.unselected:
		move.w	d2,-4(a6)				; write to nametable in VRAM
		dbf	d1,.loop				; repeat for all characters in line
		rts

LevSel_Select:
		move.b	(v_joypad_press_actual).w,d0
		andi.b	#btnABC+btnStart,d0			; is A, B, C, or Start pressed?
		beq.s	.nothing				; branch if not
		lea	LevSel_Strings(pc),a1
		move.w	(v_levelselect_item).w,d1
		mulu.w	#linesize+6,d1
		addi.w	#linesize,d1
		lea	(a1,d1.w),a1				; jump to data after string for current line
		move.w	(a1)+,d2				; get item type
		add.w	d2,d2
		move.w	LevSel_Index(pc,d2.w),d2
		jsr	LevSel_Index(pc,d2.w)
		cmpi.w	#linesound,(v_levelselect_item).w
		beq.s	.nothing				; don't exit if on the sound test
		moveq	#1,d0					; set flag to exit level select
		rts

	.nothing:
		moveq	#0,d0
		rts

LevSel_Index:	index *
		ptr LevSel_Level
		ptr LevSel_Special
		ptr LevSel_Ending
		ptr LevSel_Credits
		ptr LevSel_Gamemode
		ptr LevSel_Sound

LevSel_Level:
		move.w	(a1)+,d0
		move.b	d0,(v_zone).w				; set zone
		move.w	(a1)+,d0
		move.b	d0,(v_act).w				; set act

PlayLevel:
		move.b	#id_Level,(v_gamemode).w		; set gamemode to $0C (level)
		move.b	#3,(v_lives).w				; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w				; clear rings
		move.l	d0,(v_time).w				; clear time
		move.l	d0,(v_score).w				; clear score
		move.b	d0,(v_last_ss_levelid).w		; clear special stage number
		move.l	d0,(v_emeralds).w			; clear emeralds
		move.b	d0,(v_continues).w			; clear continues
		move.l	#5000,(v_score_next_life).w		; extra life is awarded at 50000 points
		play_fadeout					; fade out music
		rts

LevSel_Special:
		move.w	(a1)+,d0
		move.b	d0,(v_last_ss_levelid).w		; set Special Stage number
		move.b	#id_Special,(v_gamemode).w		; set gamemode to $10 (Special Stage)
		clr.w	(v_zone).w				; clear	level
		move.b	#3,(v_lives).w				; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w				; clear rings
		move.l	d0,(v_time).w				; clear time
		move.l	d0,(v_score).w				; clear score
		move.l	#5000,(v_score_next_life).w		; extra life is awarded at 50000 points
		rts

LevSel_Ending:
		move.w	(a1)+,d0
		move.b	d0,(v_zone).w				; set zone
		move.w	(a1)+,d0
		move.b	d0,(v_act).w				; set act
		move.b	#id_Ending,(v_gamemode).w		; set gamemode to $18 (Ending)
		rts

LevSel_Gamemode:
		move.w	(a1)+,d0
		move.b	d0,(v_gamemode).w			; set gamemode
		move.w	(a1)+,d0
		move.w	d0,(v_emeralds+2).w			; set emeralds
		move.b	#3,(v_continues).w			; give Sonic 3 continues
		rts

LevSel_Credits:
		move.w	(a1)+,d0
		move.w	d0,(v_credits_num).w			; set credits number
		move.b	#id_Credits,(v_gamemode).w		; set gamemode to credits
		rts

LevSel_Sound:
		btst.b	#bitA,(v_joypad_press_actual).w		; is button A pressed?
		beq.s	.play					; branch if not
		addi.w	#$10,(v_levelselect_sound).w		; skip $10
		cmpi.w	#$4F,(v_levelselect_sound).w
		ble.s	.exit					; branch if valid
		clr.w	(v_levelselect_sound).w			; reset to 0
	.exit:
		bra.w	LevSel_Display				; update number

	.play:
		move.w	(v_levelselect_sound).w,d0
		addi.w	#$80,d0
		play_sound d0
		rts

; ---------------------------------------------------------------------------
; Demo mode
; ---------------------------------------------------------------------------

PlayDemo:
		play_fadeout					; fade out music
		bsr.w	LoadPerDemo
		addq.w	#1,(v_demo_num).w			; add 1 to demo number
		cmpi.w	#countof_demo,(v_demo_num).w		; is demo number less than 4?
		blo.s	.demo_0_to_3				; if yes, branch
		clr.w	(v_demo_num).w				; reset demo number to 0

	.demo_0_to_3:
		move.w	#1,(v_demo_mode).w			; turn demo mode on
		move.b	#id_Demo,(v_gamemode).w			; set screen mode to 08 (demo)
		tst.b	(v_zone).w				; is level a special stage?
		bpl.s	.demo_level				; if not, branch
		move.b	#id_Special,(v_gamemode).w		; set screen mode to $10 (Special Stage)
		clr.w	(v_zone).w				; clear	level number
		clr.b	(v_last_ss_levelid).w			; clear special stage number

	.demo_level:
		move.b	#3,(v_lives).w				; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w				; clear rings
		move.l	d0,(v_time).w				; clear time
		move.l	d0,(v_score).w				; clear score
		move.l	#5000,(v_score_next_life).w		; extra life is awarded at 50000 points
		rts

; ---------------------------------------------------------------------------
; Level	select menu text strings
; ---------------------------------------------------------------------------

lsline:		macro string,type,zone,act
		if strlen(\string)&1=1
		inform	3,"Level select strings must be of even length."
		endc
		dc.b \string
		even
		dc.w type,zone,act
		endm

LevSel_Strings:	lsline "GREEN HILL ZONE  1",id_LevSel_Level,id_GHZ,0
	LevSel_Strings_end1:
		lsline "                 2",id_LevSel_Level,id_GHZ,1
		lsline "                 3",id_LevSel_Level,id_GHZ,2
		lsline "MARBLE ZONE      1",id_LevSel_Level,id_MZ,0
		lsline "                 2",id_LevSel_Level,id_MZ,1
		lsline "                 3",id_LevSel_Level,id_MZ,2
		lsline "SPRING YARD ZONE 1",id_LevSel_Level,id_SYZ,0
		lsline "                 2",id_LevSel_Level,id_SYZ,1
		lsline "                 3",id_LevSel_Level,id_SYZ,2
		lsline "LABYRINTH ZONE   1",id_LevSel_Level,id_LZ,0
		lsline "                 2",id_LevSel_Level,id_LZ,1
		lsline "                 3",id_LevSel_Level,id_LZ,2
		lsline "STAR LIGHT ZONE  1",id_LevSel_Level,id_SLZ,0
		lsline "                 2",id_LevSel_Level,id_SLZ,1
		lsline "                 3",id_LevSel_Level,id_SLZ,2
		lsline "SCRAP BRAIN ZONE 1",id_LevSel_Level,id_SBZ,0
		lsline "                 2",id_LevSel_Level,id_SBZ,1
		lsline "                 3",id_LevSel_Level,id_LZ,3
		lsline "FINAL ZONE        ",id_LevSel_Level,id_SBZ,2
		lsline "SPECIAL STAGE    1",id_LevSel_Special,0,0
		lsline "                 2",id_LevSel_Special,1,0
		lsline "                 3",id_LevSel_Special,2,0
		lsline "                 4",id_LevSel_Special,3,0
		lsline "                 5",id_LevSel_Special,4,0
		lsline "                 6",id_LevSel_Special,5,0
		lsline "GOOD ENDING       ",id_LevSel_Ending,id_EndZ,0
		lsline "BAD ENDING        ",id_LevSel_Ending,id_EndZ,1
		lsline "CREDITS           ",id_LevSel_Credits,0,0
		lsline "HIDDEN CREDITS    ",id_LevSel_Gamemode,id_HiddenCredits,0
		lsline "END SCREEN        ",id_LevSel_Gamemode,id_TryAgain,emerald_all
		lsline "TRY AGAIN SCREEN  ",id_LevSel_Gamemode,id_TryAgain,0
		lsline "CONTINUE SCREEN   ",id_LevSel_Gamemode,id_Continue,0
	LevSel_Strings_sound:
		lsline "SOUND SELECT   $XX",id_LevSel_Sound,0,0
	LevSel_Strings_charsel:
		lsline "CHARACTER XXXXXXXX",id_LevSel_Level,id_GHZ,0
	LevSel_Strings_end2:

LevSel_CharStrings:
		dc.b "   SONIC"
	LevSel_CharStrings_end:
		dc.b " KETCHUP"
		dc.b " MUSTARD"
		dc.b "   TAILS"
		dc.b "KNUCKLES"
		even

