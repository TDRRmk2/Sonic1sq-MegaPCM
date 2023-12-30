; ---------------------------------------------------------------------------
; Bosses

; spawned by:
;	
; ---------------------------------------------------------------------------

Boss:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Boss_Index(pc,d0.w),d1
		jmp	Boss_Index(pc,d1.w)
; ===========================================================================
Boss_Index:	index *,,2
		ptr Boss_Main
		ptr Boss_Wait
		ptr Boss_Move

		rsobj Boss2
ost_boss2_y_normal:	rs.l 1					; y position without wobble
ost_boss2_time:		rs.w 1					; time until next action
ost_boss2_cam_start:	equ ost_boss2_time			; camera x pos where boss activates
ost_boss2_wobble:	rs.b 1					; wobble counter
ost_boss2_laugh:	rs.b 1					; flag set when Eggman laughs
		rsobjend
		
Boss_CamXPos:	dc.w 0,$2960					; camera x pos where the boss becomes active
Boss_InitMode:	dc.b (Boss_MoveGHZ-Boss_MoveList)/sizeof_bmove	; initial mode for each boss
		even
		
bmove:		macro xvel,yvel,time,xflip,next
		dc.w xvel, yvel, time
		dc.b xflip, next
		endm
		
bmove_xflip_bit:	equ 0
bmove_laugh_bit:	equ 1
bmove_xflip:		equ 1<<bmove_xflip_bit
bmove_laugh:		equ 1<<bmove_laugh_bit
sizeof_bmove:		equ 8

Boss_MoveList:	; x speed, y speed, duration, flags, value to add to mode
Boss_MoveGHZ:	bmove 0, $100, $B8, 0, 1
		bmove -$100, -$40, $60, 0, 1
		bmove 0, 0, 119, bmove_laugh, 1
		bmove -$40, 0, 127, 0, 1
		bmove 0, 0, 63, bmove_xflip, 1
		bmove $100, 0, 63, bmove_xflip, 1
		bmove 0, 0, 63, 0, 1
		bmove -$100, 0, 63, 0, -3
; ===========================================================================

Boss_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Boss_Wait next
		move.l	#Map_Bosses,ost_mappings(a0)
		move.w	#tile_Art_Eggman,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.b	#$20,ost_displaywidth(a0)
		move.b	#priority_3,ost_priority(a0)
		move.b	#id_React_Boss,ost_col_type(a0)
		move.b	#24,ost_col_width(a0)
		move.b	#24,ost_col_height(a0)
		move.b	#hitcount_ghz,ost_col_property(a0)	; set number of hits to 8
		move.w	ost_y_pos(a0),ost_boss2_y_normal(a0)
		moveq	#0,d0
		move.b	ost_subtype(a0),d0
		lea	Boss_InitMode,a2
		move.b	(a2,d0.w),ost_mode(a0)
		add.w	d0,d0
		lea	Boss_CamXPos,a2
		move.w	(a2,d0.w),ost_boss2_cam_start(a0)
		
		moveq	#id_UPLC_Boss,d0
		jsr	UncPLC

Boss_Wait:	; Routine 2
		move.w	ost_boss2_cam_start(a0),d0
		cmp.w	(v_camera_x_pos).w,d0
		bls.s	.activate				; branch if camera reaches position
		jmp	DisplaySprite
		
	.activate:
		addq.b	#2,ost_routine(a0)			; goto Boss_Move next
		bsr.s	Boss_SetMode
		jmp	DisplaySprite
		
; ===========================================================================

Boss_Move:	; Routine 4
		subq.w	#1,ost_boss2_time(a0)			; decrement timer
		bpl.s	.continue				; branch if time remains
		bsr.s	Boss_SetMode
		
	.continue:
		update_x_pos
		move.w	ost_y_vel(a0),d0			; load vertical speed
		ext.l	d0
		asl.l	#8,d0					; multiply speed by $100
		add.l	d0,ost_boss2_y_normal(a0)		; update y position
		
		move.b	ost_boss2_wobble(a0),d0			; get wobble byte
		jsr	(CalcSine).l				; convert to sine
		asr.w	#6,d0					; divide by 64
		add.w	ost_boss2_y_normal(a0),d0		; add y pos
		move.w	d0,ost_y_pos(a0)			; update actual y pos
		addq.b	#2,ost_boss2_wobble(a0)			; increment wobble (wraps to 0 after $FE)
		
		tst.b	ost_col_type(a0)
		bne.s	.no_flash				; branch if not flashing
		eori.w	#cWhite,(v_pal_dry_line2+2).w		; toggle black/white on palette line 2 colour 2
		subq.b	#1,(v_boss_flash).w			; decrement flash counter
		bne.s	.no_flash				; branch if not 0
		move.b	#id_React_Boss,ost_col_type(a0)		; enable boss collision again
		
	.no_flash:
		jmp	DisplaySprite

; ---------------------------------------------------------------------------
; Subroutine to load info for and update the boss mode
; ---------------------------------------------------------------------------

Boss_SetMode:
		moveq	#0,d0
		move.b	ost_mode(a0),d0
		lsl.w	#3,d0
		lea	Boss_MoveList,a2
		adda.l	d0,a2
		move.w	(a2)+,ost_x_vel(a0)
		move.w	(a2)+,ost_y_vel(a0)
		move.w	(a2)+,ost_boss2_time(a0)
		move.b	(a2)+,d0				; get flags
		bclr	#render_xflip_bit,ost_render(a0)	; assume facing left
		bclr	#status_xflip_bit,ost_status(a0)
		move.b	#0,ost_boss2_laugh(a0)			; assume not laughing
		
		btst	#bmove_xflip_bit,d0
		beq.s	.noflip					; branch if xflip bit isn't set
		bset	#render_xflip_bit,ost_render(a0)	; face right
		bset	#status_xflip_bit,ost_status(a0)
		
	.noflip:
		btst	#bmove_laugh_bit,d0
		beq.s	.nolaugh				; branch if laughing bit isn't set
		move.b	#1,ost_boss2_laugh(a0)			; Eggman laughs
		
	.nolaugh:
		move.b	(a2)+,d0
		add.b	d0,ost_mode(a0)				; next mode
		rts
		