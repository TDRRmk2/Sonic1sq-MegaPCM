; ---------------------------------------------------------------------------
; Object 3B - purple rock (GHZ)

; spawned by:
;	ObjPos_GHZ1, ObjPos_GHZ2, ObjPos_GHZ3
; ---------------------------------------------------------------------------

PurpleRock:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Rock_Index(pc,d0.w),d1
		jmp	Rock_Index(pc,d1.w)
; ===========================================================================
Rock_Index:	index *,,2
		ptr Rock_Main
		ptr Rock_Solid
; ===========================================================================

Rock_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Rock_Solid next
		move.l	#Map_PRock,ost_mappings(a0)
		move.w	#tile_Kos_PurpleRock+tile_pal4,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.b	#$13,ost_displaywidth(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	#16,ost_height(a0)
		move.b	#16,ost_width(a0)

Rock_Solid:	; Routine 2
		shortcut
		bsr.w	SolidObject
		bra.w	DespawnQuick
