; ---------------------------------------------------------------------------
; Object 6E - electrocution orbs (SBZ)

; spawned by:
;	ObjPos_SBZ1, ObjPos_SBZ2 - subtypes 2/4/8
; ---------------------------------------------------------------------------

Electro:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Elec_Index(pc,d0.w),d1
		jmp	Elec_Index(pc,d1.w)
; ===========================================================================
Elec_Index:	index *,,2
		ptr Elec_Main
		ptr Elec_Wait
		ptr Elec_Zap
		ptr Elec_Reset

		rsobj Electro
ost_electro_mask:	rs.w 1					; zap rate - applies bitmask to frame counter
		rsobjend
; ===========================================================================

Elec_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Elec_Wait next
		move.l	#Map_Elec,ost_mappings(a0)
		move.w	#tile_Kos_Electric,ost_tile(a0)
		ori.b	#render_rel,ost_render(a0)
		move.w	#priority_0,ost_priority(a0)
		move.b	#$28,ost_displaywidth(a0)
		move.b	#StrId_Electro,ost_name(a0)
		move.b	#72,ost_col_width(a0)
		move.b	#8,ost_col_height(a0)
		moveq	#0,d0
		move.b	ost_subtype(a0),d0			; read object type (2/4/8)
		lsl.w	#4,d0					; multiply by $10
		subq.w	#1,d0					; d0 = $1F or $3F or $7F
		move.w	d0,ost_electro_mask(a0)

Elec_Wait:	; Routine 2
		move.w	(v_frame_counter).w,d0			; get byte that increments every frame
		and.w	ost_electro_mask(a0),d0			; and with rate bitmask
		bne.w	DespawnQuick				; branch if any bits are set

		tst.b	ost_render(a0)
		bpl.w	DespawnQuick				; branch if off screen
		play.w	1, jsr, sfx_Electricity			; play electricity sound
		addq.b	#2,ost_routine(a0)			; goto Elec_Zap next
		move.b	#id_ani_electro_zap,ost_anim(a0)

Elec_Zap:	; Routine 4
		lea	Ani_Elec(pc),a1
		jsr	(AnimateSprite).l
		move.w	ost_frame_hi(a0),d0
		move.b	Elec_Hurt(pc,d0.w),ost_col_type(a0)	; convert frame id to collision type
		bra.w	DespawnQuick
		
Elec_Hurt:	dc.b 0, 0, 0, 0, id_React_Hurt, 0
		even
; ===========================================================================

Elec_Reset:	; Routine 6
		move.b	#id_Elec_Wait,ost_routine(a0)		; goto Elec_Wait next
		move.b	#0,ost_col_type(a0)
		bra.s	Elec_Wait

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Elec:	index *
		ptr ani_electro_zap

ani_electro_zap:
		dc.w 0
		dc.w id_frame_electro_zap1
		dc.w id_frame_electro_zap1
		dc.w id_frame_electro_zap1
		dc.w id_frame_electro_zap2
		dc.w id_frame_electro_zap3
		dc.w id_frame_electro_zap3
		dc.w id_frame_electro_zap4
		dc.w id_frame_electro_zap4
		dc.w id_frame_electro_zap4
		dc.w id_frame_electro_zap5
		dc.w id_frame_electro_zap5
		dc.w id_frame_electro_zap5
		dc.w id_frame_electro_normal
		dc.w id_Anim_Flag_Routine
