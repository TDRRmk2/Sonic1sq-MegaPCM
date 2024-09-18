; ---------------------------------------------------------------------------
; Object 41 - springs

; spawned by:
;	ObjPos_GHZ1, ObjPos_GHZ2, ObjPos_GHZ3 - subtypes 0/2/$10
;	ObjPos_MZ2, ObjPos_MZ3 - subtype $10
;	ObjPos_SYZ1, ObjPos_SYZ2, ObjPos_SYZ3 - subtypes 0/2/$10/$12/$20
;	ObjPos_LZ1, ObjPos_LZ2, ObjPos_LZ3 - subtypes 0/$10
;	ObjPos_SLZ1, ObjPos_SLZ2, ObjPos_SLZ3 - subtypes 0/2/$10
;	ObjPos_SBZ1, ObjPos_SBZ2, ObjPos_SBZ3 - subtypes 0/$10

; subtypes:
;	%TTTTSSSC
;	TTTT - type (see Spring_Settings)
;	SSS - strength (see Spring_Powers)
;	C - 1 to use palette line 2

type_spring_pal2_bit:	equ 0
type_spring_pal2:	equ 1<<type_spring_pal2_bit		; x1 - use palette line 2 (yellow)
type_spring_strong:	equ 0
type_spring_weak:	equ 2
type_spring_red:	equ type_spring_strong			; x0 - red strong
type_spring_yellow:	equ type_spring_weak+type_spring_pal2	; x2 - yellow weak
type_spring_up:		equ 0					; $0x - facing up
type_spring_right:	equ $10					; $1x - facing right (or left if xflipped)
type_spring_down:	equ $20					; $2x - facing down (must also be yflipped)
; ---------------------------------------------------------------------------

Springs:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Spring_Index(pc,d0.w),d1
		jmp	Spring_Index(pc,d1.w)
; ===========================================================================
Spring_Index:	index *,,2
		ptr Spring_Main
		ptr Spring_Up
		ptr Spring_Animate
		ptr Spring_Reset
		ptr Spring_LR
		ptr Spring_Down

Spring_Powers:	dc.w -spring_power_red				; power	of red spring
		dc.w -spring_power_yellow			; power	of yellow spring

Spring_Settings:
		; up ($0x)
		dc.l v_tile_hspring				; location of tile setting
		dc.b 14, 8					; width, height
		dc.b id_ani_spring_up				; animation
		dc.b id_frame_spring_up				; frame
		dc.b id_Spring_Up				; routine number
		even
	Spring_Settings_end:
		
		; left/right ($1x)
		dc.l v_tile_vspring
		dc.b 8, 14
		dc.b id_ani_spring_left
		dc.b id_frame_spring_left
		dc.b id_Spring_LR
		even
		
		; down ($2x)
		dc.l v_tile_hspring
		dc.b 14, 8
		dc.b id_ani_spring_up
		dc.b id_frame_spring_up
		dc.b id_Spring_Down
		even

		rsobj Springs
ost_spring_power:	rs.w 1					; power of current spring
ost_spring_routine:	rs.b 1					; buffered routine number while spring animates
		rsobjend
; ===========================================================================

Spring_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Spring_Up next
		move.l	#Map_Spring,ost_mappings(a0)
		ori.b	#render_rel,ost_render(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	ost_subtype(a0),d0			; get subtype
		move.l	d0,d1
		andi.w	#$E,d1					; read only low nybble of subtype (0 or 2)
		move.w	Spring_Powers(pc,d1.w),ost_spring_power(a0) ; get power level
		
		btst	#type_spring_pal2_bit,d0
		beq.s	.not_yellow				; branch if bit 0 isn't set
		bset	#tile_pal12_bit,ost_tile(a0)		; use 2nd palette (yellow spring)

	.not_yellow:
		btst	#status_yflip_bit,ost_status(a0)
		beq.s	.not_yflipped				; branch if not yflipped
		neg.w	ost_spring_power(a0)			; reverse direction

	.not_yflipped:
		andi.w	#$F0,d0					; read only high nybble
		lsr.b	#4,d0					; move to low nybble
		mulu.w	#Spring_Settings_end-Spring_Settings,d0
		lea	Spring_Settings(pc,d0.w),a2
		movea.l	(a2)+,a3
		move.w	(a3),d0
		or.w	d0,ost_tile(a0)
		move.b	(a2),ost_displaywidth(a0)
		move.b	(a2)+,ost_width(a0)
		move.b	(a2)+,ost_height(a0)
		move.b	(a2)+,ost_anim(a0)
		move.b	(a2)+,ost_frame(a0)
		move.b	(a2),ost_routine(a0)
		move.b	(a2)+,ost_spring_routine(a0)
		bra.w	DespawnQuick
; ===========================================================================

Spring_Up:	; Routine 2
		bsr.w	SolidObject				; detect collision
		andi.b	#solid_top,d1
		beq.w	DespawnQuick				; branch if no collision on top
		
		addq.w	#8,ost_y_pos(a1)
		
Spring_Bounce:
		move.b	#id_Spring_Animate,ost_routine(a0)	; goto Spring_Animate next
		move.w	ost_spring_power(a0),ost_y_vel(a1)	; move Sonic upwards
		bset	#status_air_bit,ost_status(a1)
		bclr	#status_platform_bit,ost_status(a1)
		move.b	#id_Spring,ost_anim(a1)			; use "bouncing" animation
		move.b	#id_Sonic_Control,ost_routine(a1)
		bclr	#status_platform_bit,ost_status(a0)
		clr.b	ost_mode(a0)
		play.w	1, jsr, sfx_Spring			; play spring sound

Spring_Animate:	; Routine 4
		lea	Ani_Spring(pc),a1
		bsr.w	AnimateSprite				; animate and goto Spring_Reset next
		bra.w	DespawnQuick
; ===========================================================================

Spring_Reset:	; Routine 6
		move.b	#0,ost_anim_frame(a0)			; reset animation
		move.b	#0,ost_anim_time(a0)
		move.b	ost_spring_routine(a0),ost_routine(a0)	; goto previous routine
		bra.w	DespawnQuick
; ===========================================================================

Spring_LR:	; Routine 8
		bsr.w	SolidObject				; detect collision
		andi.b	#solid_left+solid_right,d1
		beq.w	DespawnQuick				; branch if no collision on left/right
		
		move.b	#id_Spring_Animate,ost_routine(a0)	; goto Spring_Animate next
		move.w	ost_spring_power(a0),ost_x_vel(a1)	; move Sonic to the left
		addq.w	#8,ost_x_pos(a1)
		btst	#status_xflip_bit,ost_status(a0)	; is object flipped?
		bne.s	.xflipped				; if yes, branch
		subi.w	#$10,ost_x_pos(a1)
		neg.w	ost_x_vel(a1)				; move Sonic to	the right

	.xflipped:
		move.w	#15,ost_sonic_lock_time(a1)		; lock controls for 0.25 seconds
		move.w	ost_x_vel(a1),ost_inertia(a1)
		bchg	#status_xflip_bit,ost_status(a1)
		btst	#status_jump_bit,ost_status(a1)		; is Sonic jumping/rolling?
		bne.s	.is_rolling				; if yes, branch
		move.b	#id_Walk,ost_anim(a1)			; use walking animation

	.is_rolling:
		bclr	#status_pushing_bit,ost_status(a0)
		bclr	#status_pushing_bit,ost_status(a1)
		play.w	1, jsr, sfx_Spring			; play spring sound
		bra.w	Spring_Animate
; ===========================================================================

Spring_Down:	; Routine $A
		bsr.w	SolidObject				; detect collision
		andi.b	#solid_bottom,d1
		beq.w	DespawnQuick				; branch if no collision on bottom
		
		subq.w	#8,ost_y_pos(a1)
		bra.w	Spring_Bounce

; ---------------------------------------------------------------------------
; Animation script
; ---------------------------------------------------------------------------

Ani_Spring:	index *
		ptr ani_spring_up
		ptr ani_spring_left
		
ani_spring_up:
		dc.w 0
		dc.w id_frame_spring_upflat
		dc.w id_frame_spring_up
		dc.w id_frame_spring_up
		dc.w id_frame_spring_upext
		dc.w id_frame_spring_upext
		dc.w id_frame_spring_upext
		dc.w id_frame_spring_upext
		dc.w id_frame_spring_upext
		dc.w id_frame_spring_upext
		dc.w id_frame_spring_up
		dc.w id_Anim_Flag_Routine

ani_spring_left:
		dc.w 0
		dc.w id_frame_spring_leftflat
		dc.w id_frame_spring_left
		dc.w id_frame_spring_left
		dc.w id_frame_spring_leftext
		dc.w id_frame_spring_leftext
		dc.w id_frame_spring_leftext
		dc.w id_frame_spring_leftext
		dc.w id_frame_spring_leftext
		dc.w id_frame_spring_leftext
		dc.w id_frame_spring_left
		dc.w id_Anim_Flag_Routine
