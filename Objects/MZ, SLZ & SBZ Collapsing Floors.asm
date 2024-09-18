; ---------------------------------------------------------------------------
; Object 53 - collapsing floors	(MZ, SLZ, SBZ)

; spawned by:
;	ObjPos_MZ3 - subtype 1
;	ObjPos_SLZ1, ObjPos_SLZ2, ObjPos_SLZ3 - subtypes $21/$A1
;	ObjPos_SBZ1, ObjPos_SBZ2 - subtype 1

; subtypes:
;	%SFFFKDDD
;	S - 1 to xflip platform (and fragment pattern) if Sonic is on right side
;	FFF - frame id
;	K - 1 to keep frame id when collapsing
;	DDD - delay fragment pattern id

type_cfloor_slz:		equ id_frame_cfloor_slz<<4	; +$20 - SLZ mappings
type_cfloor_sided:		equ $80				; +$80 - collapse pattern depends on which side was touched
type_cfloor_keepframe_bit:	equ 3
type_cfloor_keepframe:		equ 1<<type_cfloor_keepframe_bit ; +8 - keep frame id when collapsing
; ---------------------------------------------------------------------------

CollapseFloor:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	CFlo_Index(pc,d0.w),d1
		jmp	CFlo_Index(pc,d1.w)
; ===========================================================================
CFlo_Index:	index *,,2
		ptr CFlo_Main
		ptr CFlo_Solid
		ptr CFlo_Wait

		rsobj CollapseFloor
ost_cfloor_wait_time:	rs.b 1					; time delay for collapsing floor
		rsobjend
; ===========================================================================

CFlo_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto CFlo_Solid next
		move.l	#Map_CFlo,ost_mappings(a0)
		move.w	(v_tile_floor).w,ost_tile(a0)
		addi.w	#tile_pal3,ost_tile(a0)
		move.b	ost_subtype(a0),d0
		andi.b	#%01110000,d0				; read bits 4-6 of subtype
		lsr.b	#4,d0
		move.b	d0,ost_frame(a0)			; set as frame
		ori.b	#render_rel,ost_render(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	#14,ost_cfloor_wait_time(a0)
		move.b	#$44,ost_displaywidth(a0)
		move.b	#32,ost_width(a0)
		move.b	#8,ost_height(a0)

CFlo_Solid:	; Routine 2
		bsr.w	SolidObject_TopOnly
		tst.b	d1
		beq.w	DespawnObject				; branch if no collision
		addq.b	#2,ost_routine(a0)			; goto CFlo_Wait next
		move.b	ost_subtype(a0),d1
		btst	#type_cfloor_keepframe_bit,d1
		bne.s	.keep_frame				; branch if bit 3 is set
		addq.b	#1,ost_frame(a0)			; use frame consisting of smaller pieces
		
	.keep_frame:
		bpl.s	.no_sidedness				; branch if high bit of subtype is 0
		bclr	#render_xflip_bit,ost_render(a0)
		move.w	ost_x_pos(a1),d0
		sub.w	ost_x_pos(a0),d0
		bcc.s	.no_sidedness				; branch if Sonic is left of the platform
		bset	#render_xflip_bit,ost_render(a0)
		
	.no_sidedness:
		andi.w	#%00000111,d1				; read bits 0-2 of subtype
		add.b	d1,d1
		move.w	CFlo_FragTiming_Index(pc,d1.w),d1
		lea	CFlo_FragTiming_Index(pc,d1.w),a4
		bsr.w	Crumble					; spawn fragments
		bra.w	DespawnObject

CFlo_FragTiming_Index:	index *,,2
		ptr CFlo_FragTiming_0
		ptr CFlo_FragTiming_1

CFlo_FragTiming_0:
		dc.b $1E, $16, $E, 6, $1A, $12,	$A, 2		; unused
CFlo_FragTiming_1:
		dc.b $16, $1E, $1A, $12, 6, $E,	$A, 2
		even
; ===========================================================================

CFlo_Wait:	; Routine 4
		subq.b	#1,ost_cfloor_wait_time(a0)		; decrement timer
		bmi.s	.delete					; branch if time hits -1
		bsr.w	SolidObject_TopOnly
		bra.w	DespawnQuick_NoDisplay
		
	.delete:
		bsr.w	UnSolid_TopOnly
		bra.w	DeleteObject
