; ---------------------------------------------------------------------------
; Object 1A - GHZ collapsing ledge

; spawned by:
;	ObjPos_GHZ1, ObjPos_GHZ2, ObjPos_GHZ3 - subtypes 0/1

type_ledge_left:	equ id_frame_ledge_left			; 0 - facing left
type_ledge_right:	equ id_frame_ledge_right		; 1 - also facing left, but always xflipped to face right
; ---------------------------------------------------------------------------

CollapseLedge:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Ledge_Index(pc,d0.w),d1
		jmp	Ledge_Index(pc,d1.w)
; ===========================================================================
Ledge_Index:	index *,,2
		ptr Ledge_Main
		ptr Ledge_Solid
		ptr Ledge_Wait

		rsobj CollapseLedge
ost_ledge_heightmap:	rs.l 1					; pointer to heightmap
ost_ledge_wait_time:	rs.b 1					; time between touching the ledge and it collapsing
		rsobjend
; ===========================================================================

Ledge_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Ledge_Solid next
		move.l	#Map_Ledge,ost_mappings(a0)
		move.w	#0+tile_pal3,ost_tile(a0)
		ori.b	#render_rel+render_useheight,ost_render(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	#14,ost_ledge_wait_time(a0)		; set time delay for collapse
		move.b	#$30,ost_displaywidth(a0)
		move.b	#StrId_Ledge,ost_name(a0)
		move.b	#$30,ost_width(a0)
		move.b	ost_subtype(a0),ost_frame(a0)
		move.b	#$38,ost_height(a0)
		move.l	#Ledge_SlopeData,ost_ledge_heightmap(a0) ; heightmap
		tst.b	ost_subtype(a0)
		beq.s	Ledge_Solid
		move.l	#Ledge_SlopeData_Flip,ost_ledge_heightmap(a0) ; heightmap xflipped

Ledge_Solid:	; Routine 2
		moveq	#1,d6					; 1 byte in heightmap = 2px
		movea.l	ost_ledge_heightmap(a0),a2		; heightmap
		bsr.w	SolidObjectTopHeightmap
		beq.w	DespawnObject				; branch if no collision
		addq.b	#2,ost_routine(a0)			; goto Ledge_Wait next
		addq.b	#2,ost_frame(a0)			; use frame consisting of smaller pieces
		lea	Ledge_FragTiming(pc),a4
		bsr.w	Crumble					; create crumbling fragments
		bra.w	DespawnObject

Ledge_FragTiming:
		dc.b $1C, $18, $14, $10, $1A, $16, $12,	$E, $A,	6, $18,	$14, $10, $C, 8, 4
		dc.b $16, $12, $E, $A, 6, 2, $14, $10, $C
		even
; ===========================================================================

Ledge_Wait:	; Routine 4
		subq.b	#1,ost_ledge_wait_time(a0)		; decrement timer
		bmi.s	.delete					; branch if time hits -1
		moveq	#1,d6					; 1 byte in heightmap = 2px
		movea.l	ost_ledge_heightmap(a0),a2		; heightmap
		bsr.w	SolidObjectTopHeightmap
		bra.w	DespawnQuick_NoDisplay
		
	.delete:
		bsr.w	UnSolid
		bra.w	DeleteObject
