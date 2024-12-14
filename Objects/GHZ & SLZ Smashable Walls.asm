; ---------------------------------------------------------------------------
; Object 3C - smashable	wall (GHZ, SLZ)

; spawned by:
;	ObjPos_GHZ2, ObjPos_GHZ3 - subtypes 0/1/2
;	ObjPos_SLZ1, ObjPos_SLZ3 - subtype 1
; ---------------------------------------------------------------------------

SmashWall:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Smash_Index(pc,d0.w),d1
		jmp	Smash_Index(pc,d1.w)
; ===========================================================================
Smash_Index:	index *,,2
		ptr Smash_Main
		ptr Smash_Solid
; ===========================================================================

Smash_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Smash_Solid next
		move.l	#Map_Smash,ost_mappings(a0)
		move.w	(v_tile_wall).w,ost_tile(a0)
		addi.w	#tile_pal3,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.b	#$10,ost_displaywidth(a0)
		move.b	#StrId_SmashWall,ost_name(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	ost_subtype(a0),ost_frame(a0)
		move.b	#16,ost_width(a0)
		move.b	#32,ost_height(a0)
		bset	#status_breakable_bit,ost_status(a0)

Smash_Solid:	; Routine 2
		shortcut
		bsr.w	SolidObject
		beq.w	DespawnObject				; branch if no collision with left/right
		btst	#solid_broken_bit,d1
		beq.w	DespawnObject				; branch if not broken
		lea	Smash_FragRight(pc),a4			; use fragments that move right
		andi.b	#solid_right,d1
		bne.s	.right					; branch if collision with right side
		lea	Smash_FragLeft(pc),a4			; use fragments that move left
		
	.right:
		move.w	#$70,d2					; gravity
		bra.s	Shatter
		
Smash_FragRight:
		dc.w $400, -$500				; x speed, y speed
		dc.w $600, -$100
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, -$600
		dc.w $800, -$200
		dc.w $800, $200
		dc.w $600, $600

Smash_FragLeft:	dc.w -$600, -$600
		dc.w -$800, -$200
		dc.w -$800, $200
		dc.w -$600, $600
		dc.w -$400, -$500
		dc.w -$600, -$100
		dc.w -$600, $100
		dc.w -$400, $500
