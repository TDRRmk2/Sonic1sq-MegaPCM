; ---------------------------------------------------------------------------
; Object 29 - points that appear when you destroy something

; spawned by:
;	Animals, SmashBlock, Bumper
; ---------------------------------------------------------------------------

Points:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Poi_Index(pc,d0.w),d1
		jmp	Poi_Index(pc,d1.w)
; ===========================================================================
Poi_Index:	index *,,2
		ptr Poi_Main
		ptr Poi_Slower
; ===========================================================================

Poi_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Poi_Slower next
		move.l	#Map_Points,ost_mappings(a0)
		move.w	(v_tile_points).w,ost_tile(a0)
		addi.w	#tile_pal2,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.w	#priority_1,ost_priority(a0)
		move.b	#8,ost_displaywidth(a0)
		move.w	#-$300,ost_y_vel(a0)			; move object upwards

Poi_Slower:	; Routine 2
		shortcut
		tst.w	ost_y_vel(a0)
		bpl.w	DeleteObject				; branch if stopped
		update_y_fall	$18				; update position & slow ascent
		bra.w	DisplaySprite	
