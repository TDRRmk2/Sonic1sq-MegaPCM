; ---------------------------------------------------------------------------
; Object 0C - flapping door (LZ)

; spawned by:
;	ObjPos_LZ2, ObjPos_LZ3, ObjPos_SBZ3 - subtype 2
; ---------------------------------------------------------------------------

FlapDoor:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Flap_Index(pc,d0.w),d1
		jmp	Flap_Index(pc,d1.w)
; ===========================================================================
Flap_Index:	index *,,2
		ptr Flap_Main
		ptr Flap_OpenClose

		rsobj FlapDoor
ost_flap_wait:	rs.w 1 ; $30					; time until change (2 bytes)
ost_flap_time:	rs.w 1 ; $32					; time between opening/closing (2 bytes)
		rsobjend
; ===========================================================================

Flap_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Flap_OpenClose next
		move.l	#Map_Flap,ost_mappings(a0)
		move.w	#tile_Kos_FlapDoor+tile_pal3,ost_tile(a0)
		ori.b	#render_rel,ost_render(a0)
		move.b	#$28,ost_displaywidth(a0)
		move.b	#8,ost_width(a0)
		move.b	#32,ost_height(a0)
		moveq	#0,d0
		move.b	ost_subtype(a0),d0			; get object type
		mulu.w	#60,d0					; multiply by 60 (1 second)
		move.w	d0,ost_flap_time(a0)			; set flap delay time

Flap_OpenClose:	; Routine 2
		subq.w	#1,ost_flap_wait(a0)			; decrement time delay
		bpl.s	.wait					; if time remains, branch
		move.w	ost_flap_time(a0),ost_flap_wait(a0)	; reset time delay
		bchg	#0,ost_anim(a0)				; open/close door
		bclr	#7,ost_anim(a0)
		tst.b	ost_render(a0)
		bpl.s	.nosound
		play.w	1, jsr, sfx_Door			; play door sound

	.wait:
	.nosound:
		lea	(Ani_Flap).l,a1
		jsr	AnimateSprite
		clr.b	(f_water_tunnel_disable).w		; enable wind tunnel
		tst.b	ost_frame(a0)				; is the door open?
		bne.s	.display				; if yes, branch
		move.w	(v_ost_player+ost_x_pos).w,d0
		cmp.w	ost_x_pos(a0),d0			; has Sonic passed through the door?
		bcc.s	.display				; if yes, branch
		move.b	#1,(f_water_tunnel_disable).w		; disable wind tunnel
		bsr.w	SolidNew				; make the door	solid

	.display:
		bra.w	DespawnObject

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Flap:	index *
		ptr ani_flap_opening
		ptr ani_flap_closing
		
ani_flap_opening:
		dc.w 3
		dc.w id_frame_flap_closed
		dc.w id_frame_flap_halfway
		dc.w id_frame_flap_open
		dc.w id_Anim_Flag_Back, 1

ani_flap_closing:
		dc.w 3
		dc.w id_frame_flap_open
		dc.w id_frame_flap_halfway
		dc.w id_frame_flap_closed
		dc.w id_Anim_Flag_Back, 1
		even
