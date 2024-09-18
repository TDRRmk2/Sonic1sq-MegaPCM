; ---------------------------------------------------------------------------
; Object 7F - chaos emeralds from the special stage results screen

; spawned by:
;	SSResult, SSRChaos
; ---------------------------------------------------------------------------

SSRChaos:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	SSRC_Index(pc,d0.w),d1
		jmp	SSRC_Index(pc,d1.w)
; ===========================================================================
SSRC_Index:	index *,,2
		ptr SSRC_Main
		ptr SSRC_Flash

SSRC_PosData:	; x positions for chaos emeralds
		dc.w screen_left+144				; blue
		dc.w screen_left+168				; yellow
		dc.w screen_left+120				; pink
		dc.w screen_left+192				; green
		dc.w screen_left+96				; red
		dc.w screen_left+216				; grey
; ===========================================================================

SSRC_Main:	; Routine 0
		movea.l	a0,a1					; replace current object with 1st emerald
		lea	SSRC_PosData(pc),a2
		moveq	#0,d2
		moveq	#emerald_count-1,d1
		move.l	(v_emeralds).w,d4			; get emerald bitfield
		bra.s	.skip_findost

	.loop:
		jsr	FindFreeInert

	.skip_findost:
		move.l	#0,ost_id(a1)				; set object to none by default
		btst	d2,d4					; check if emerald was collected
		beq.s	.emerald_not_got			; branch if not

		move.l	#SSRChaos,ost_id(a1)
		move.w	d2,d3
		add.w	d3,d3
		move.w	(a2,d3.w),ost_x_pos(a1)			; set x position from list
		move.w	#screen_top+112,ost_y_screen(a1)	; set y position
		move.b	d2,ost_frame(a1)			; set frame number
		move.b	d2,ost_anim(a1)				; copy frame number (not an animation number)
		addq.b	#2,ost_routine(a1)			; goto SSRC_Flash next
		move.l	#Map_SSRC,ost_mappings(a1)
		move.w	#tile_Art_ResultEm+tile_hi,ost_tile(a1)
		move.w	#priority_0,ost_priority(a1)
		move.b	#render_abs,ost_render(a1)

	.emerald_not_got:
		addq.b	#1,d2					; next emerald value
		dbf	d1,.loop				; repeat for rest of emeralds
; ===========================================================================

SSRC_Flash:	; Routine 2
		move.b	ost_frame(a0),d0			; get previous frame
		move.b	#id_frame_ssrc_blank,ost_frame(a0)	; use blank frame (6)
		cmpi.b	#id_frame_ssrc_blank,d0			; was previous frame blank?
		bne.s	.keep_frame				; if not, branch
		move.b	ost_anim(a0),ost_frame(a0)		; use original frame stored in ost_anim

	.keep_frame:
		jmp	DisplaySprite
