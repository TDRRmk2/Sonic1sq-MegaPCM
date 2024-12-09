; ---------------------------------------------------------------------------
; Object 20 - cannonball that Ball Hog throws (SBZ)

; spawned by:
;	BallHog - subtype inherited from parent
; ---------------------------------------------------------------------------

Cannonball:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Cbal_Index(pc,d0.w),d1
		jmp	Cbal_Index(pc,d1.w)
; ===========================================================================
Cbal_Index:	index *,,2
		ptr Cbal_Main
		ptr Cbal_Bounce

		rsobj Cannonball
ost_ball_time:		rs.w 1					; time until the cannonball explodes
ost_ball_bounce:	rs.w 1					; bounce y speed
		rsobjend
		
cannonball_height:	equ 6
; ===========================================================================

Cbal_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Cbal_Bounce next
		move.b	#7,ost_height(a0)
		move.l	#Map_Hog,ost_mappings(a0)
		move.w	(v_tile_ballhog).w,ost_tile(a0)
		addi.w	#tile_pal2,ost_tile(a0)
		move.b	#render_rel,ost_render(a0)
		move.w	#priority_3,ost_priority(a0)
		move.b	#id_React_Hurt,ost_col_type(a0)
		move.b	#6,ost_col_width(a0)
		move.b	#cannonball_height,ost_col_height(a0)
		move.b	#8,ost_displaywidth(a0)
		move.b	#StrId_Ball,ost_name(a0)
		move.b	ost_subtype(a0),d0			; move subtype to d0
		move.w	d0,d1
		andi.w	#$F,d0					; read low nybble only
		mulu.w	#60,d0					; multiply by 60 frames	(1 second)
		move.w	d0,ost_ball_time(a0)			; set explosion time
		andi.w	#$F0,d1					; read high nybble only
		lsl.w	#4,d1					; multiply by $10
		neg.w	d1					; invert because it bounces up
		move.w	d1,ost_ball_bounce(a0)			; set bounce speed
		move.b	#id_frame_hog_ball1,ost_frame(a0)

Cbal_Bounce:	; Routine 2
		shortcut
		update_xy_fall					; update position & apply gravity
		bmi.s	Cbal_ChkExplode				; branch if moving up
		getpos_bottom cannonball_height			; d0 = x pos; d1 = y pos of bottom
		moveq	#1,d6
		jsr	FloorDist
		tst.w	d5					; has ball hit the floor?
		bpl.s	Cbal_ChkExplode				; if not, branch

		add.w	d5,ost_y_pos(a0)			; align to floor
		move.w	ost_ball_bounce(a0),ost_y_vel(a0)	; bounce
		jsr	FloorAngle				; d2 = floor angle
		tst.b	d2
		beq.s	Cbal_ChkExplode				; branch if perfectly flat
		bmi.s	.down_left				; branch if sloping up-right or down-left

		tst.w	ost_x_vel(a0)
		bpl.s	Cbal_ChkExplode				; branch if ball is moving right
		neg.w	ost_x_vel(a0)				; reverse direction (ball hits down-right slope while moving left)
		bra.s	Cbal_ChkExplode
; ===========================================================================

.down_left:
		tst.w	ost_x_vel(a0)
		bmi.s	Cbal_ChkExplode				; branch if ball is moving left
		neg.w	ost_x_vel(a0)				; reverse direction (ball hits down-left slope while moving right)

Cbal_ChkExplode:
		subq.w	#1,ost_ball_time(a0)			; subtract 1 from explosion time
		bpl.s	Cbal_Animate				; if time is > 0, branch
		jsr	Explode					; replace cannonball with explosion
		bra.w	ExplosionBomb				; jump to explosion code
; ===========================================================================

Cbal_Animate:
		subq.b	#1,ost_anim_time(a0)			; subtract 1 from frame duration
		bpl.s	Cbal_Display
		move.b	#5,ost_anim_time(a0)			; set frame duration to 5 frames
		bchg	#0,ost_frame(a0)			; change frame

Cbal_Display:
		move.w	(v_boundary_bottom).w,d0
		addi.w	#screen_height,d0
		cmp.w	ost_y_pos(a0),d0			; has object fallen off the level?
		bcs.w	DeleteObject				; if yes, branch
		bra.w	DespawnQuick
