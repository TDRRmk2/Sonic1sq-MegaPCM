; ---------------------------------------------------------------------------
; Object 2C - Jaws enemy (LZ)

; spawned by:
;	ObjPos_LZ1, ObjPos_LZ2, ObjPos_LZ3, ObjPos_SBZ3 - subtypes 6/8/9/$A/$C
; ---------------------------------------------------------------------------

Jaws:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Jaws_Index(pc,d0.w),d1
		jmp	Jaws_Index(pc,d1.w)
; ===========================================================================
Jaws_Index:	index *,,2
		ptr Jaws_Main
		ptr Jaws_Turn

		rsobj Jaws
ost_jaws_turn_time:	rs.w 1					; time until jaws turns (2 bytes)
ost_jaws_turn_master:	rs.w 1					; time between turns, copied to ost_jaws_turn_time every turn (2 bytes)
		rsobjend
; ===========================================================================

Jaws_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Jaws_Turn next
		move.l	#Map_Jaws,ost_mappings(a0)
		move.w	(v_tile_jaws).w,ost_tile(a0)
		addi.w	#tile_pal2,ost_tile(a0)
		ori.b	#render_rel,ost_render(a0)
		move.b	#id_React_Enemy,ost_col_type(a0)
		move.b	#16,ost_col_width(a0)
		move.b	#12,ost_col_height(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	#$10,ost_displaywidth(a0)
		moveq	#0,d0
		move.b	ost_subtype(a0),d0			; load object subtype number
		lsl.w	#6,d0					; multiply d0 by 64
		subq.w	#1,d0
		move.w	d0,ost_jaws_turn_time(a0)		; set turn delay time
		move.w	d0,ost_jaws_turn_master(a0)
		move.w	#-$40,ost_x_vel(a0)			; move Jaws to the left
		btst	#status_xflip_bit,ost_status(a0)	; is Jaws facing left?
		beq.s	Jaws_Turn				; if yes, branch
		neg.w	ost_x_vel(a0)				; move Jaws to the right

Jaws_Turn:	; Routine 2
		shortcut
		subq.w	#1,ost_jaws_turn_time(a0)		; subtract 1 from turn delay time
		bpl.s	.animate				; if time remains, branch

		move.w	ost_jaws_turn_master(a0),ost_jaws_turn_time(a0) ; reset turn delay time
		neg.w	ost_x_vel(a0)				; change speed direction
		bchg	#status_xflip_bit,ost_status(a0)	; change Jaws facing direction
		move.b	#0,ost_anim_frame(a0)			; reset animation
		move.b	#0,ost_anim_time(a0)

	.animate:
		lea	Ani_Jaws(pc),a1
		bsr.w	AnimateSprite
		update_x_pos
		bra.w	DespawnObject

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Jaws:	index *
		ptr ani_jaws_swim
		
ani_jaws_swim:	dc.w 7
		dc.w id_frame_jaws_open1
		dc.w id_frame_jaws_shut1
		dc.w id_frame_jaws_open2
		dc.w id_frame_jaws_shut2
		dc.w id_Anim_Flag_Restart
