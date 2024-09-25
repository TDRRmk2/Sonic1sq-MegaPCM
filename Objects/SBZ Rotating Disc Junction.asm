; ---------------------------------------------------------------------------
; Object 66 - rotating disc junction that grabs Sonic (SBZ)

; spawned by:
;	ObjPos_SBZ1 - subtypes 0/2
; ---------------------------------------------------------------------------

Junction:
		moveq	#0,d0
		move.b	ost_routine(a0),d0
		move.w	Jun_Index(pc,d0.w),d1
		jmp	Jun_Index(pc,d1.w)
; ===========================================================================
Jun_Index:	index *,,2
		ptr Jun_Main
		ptr Jun_Action
		ptr Jun_Grabbed
		ptr Jun_Cooldown

		rsobj Junction
ost_junc_grab_frame:	rs.b 1					; which frame the junction grabbed Sonic on
ost_junc_direction:	rs.b 1					; direction of rotation: 1 or -1 (added to the frame number)
ost_junc_button_flag:	rs.b 1					; flag set when button is pressed
ost_junc_cooldown:	rs.b 1					; time until junction becomes solid after Sonic leaves it
		rsobjend
; ===========================================================================

Jun_Main:	; Routine 0
		addq.b	#2,ost_routine(a0)			; goto Jun_Action next
		move.l	#Map_Jun,ost_mappings(a0)
		move.w	#tile_Kos_SbzJunction+tile_pal3,ost_tile(a0)
		ori.b	#render_rel,ost_render(a0)
		move.b	#$30,ost_width(a0)
		move.b	#$30,ost_height(a0)
		move.b	#$30,ost_displaywidth(a0)
		move.b	#StrId_Junction,ost_name(a0)
		move.w	#priority_4,ost_priority(a0)
		move.b	#1,ost_junc_direction(a0)		; set default direction (anticlockwise)
		
		bsr.w	FindFreeObj				; find free OST slot
		bne.s	Jun_Action				; branch if not found
		move.l	#JunctionBG,ost_id(a1)			; load 2nd junction object
		move.w	ost_x_pos(a0),ost_x_pos(a1)
		move.w	ost_y_pos(a0),ost_y_pos(a1)
		move.w	#priority_3,ost_priority(a1)
		move.b	#id_frame_junc_circle,ost_frame(a1)	; use large circular sprite
		move.l	ost_mappings(a0),ost_mappings(a1)
		move.w	ost_tile(a0),ost_tile(a1)
		ori.b	#render_rel,ost_render(a1)
		move.b	#$38,ost_displaywidth(a1)
		move.b	#StrId_Junction,ost_name(a1)

Jun_Action:	; Routine 2
		bsr.w	Jun_Update				; check if button is pressed and animate the junction
		bsr.w	SolidObject
		btst	#status_pushing_bit,ost_status(a0)	; is Sonic pushing the disc?
		beq.w	DespawnQuick				; if not, branch

		getsonic					; a1 = OST of Sonic
		moveq	#id_frame_junc_nw,d1
		move.w	ost_x_pos(a1),d0
		cmp.w	ost_x_pos(a0),d0			; is Sonic to the left of the disc?
		bcs.s	.isleft					; if yes, branch
		moveq	#id_frame_junc_ese,d1		

	.isleft:
		cmp.b	ost_frame(a0),d1			; is the gap next to Sonic?
		bne.w	DespawnQuick				; if not, branch

		move.b	d1,ost_junc_grab_frame(a0)
		addq.b	#2,ost_routine(a0)			; goto Jun_Grabbed next
		move.b	#1,(v_lock_multi).w			; lock controls
		move.b	#id_Roll,ost_anim(a1)			; make Sonic use "rolling" animation
		move.w	#$800,ost_inertia(a1)
		move.w	#0,ost_x_vel(a1)
		move.w	#0,ost_y_vel(a1)
		bclr	#status_pushing_bit,ost_status(a0)
		bclr	#status_pushing_bit,ost_status(a1)
		bset	#status_air_bit,ost_status(a1)
		move.w	ost_x_pos(a1),d2
		move.w	ost_y_pos(a1),d3
		bsr.w	Jun_MoveSonic				; update Sonic's position within the junction
		add.w	d2,ost_x_pos(a1)
		add.w	d3,ost_y_pos(a1)
		asr	ost_x_pos(a1)
		asr	ost_y_pos(a1)
		bra.w	DespawnQuick
; ===========================================================================

Jun_Grabbed:	; Routine 4
		getsonic					; a1 = OST of Sonic
		bsr.s	Jun_Update				; check if button is pressed and animate the junction
		cmpi.b	#7,ost_anim_time(a0)
		bne.w	DespawnQuick				; branch if frame hasn't changed
		bsr.w	Jun_MoveSonic				; update Sonic's position within the junction
		
		move.b	ost_frame(a0),d0
		cmpi.b	#id_frame_junc_s,d0			; is gap pointing down?
		beq.s	.release				; if yes, branch
		cmpi.b	#id_frame_junc_ese,d0			; is gap pointing right?
		bne.w	DespawnQuick				; if not, branch

	.release:
		cmp.b	ost_junc_grab_frame(a0),d0		; is gap on the frame Sonic was grabbed on?
		beq.w	DespawnQuick				; if yes, branch
		move.w	#0,ost_x_vel(a1)
		move.w	#$800,ost_y_vel(a1)			; drop Sonic straight down
		cmpi.b	#id_frame_junc_s,d0			; is gap pointing down?
		beq.s	.isdown					; if yes, branch
		move.w	#$800,ost_x_vel(a1)
		move.w	#$800,ost_y_vel(a1)			; launch Sonic diagonally down-right

	.isdown:
		clr.b	(v_lock_multi).w			; unlock controls
		addq.b	#2,ost_routine(a0)			; goto Jun_Cooldown next
		move.b	#7,ost_junc_cooldown(a0)
		bra.w	DespawnQuick
; ===========================================================================

Jun_Cooldown:	; Routine 6
		bsr.s	Jun_Update
		subq.b	#1,ost_junc_cooldown(a0)		; decrement cooldown
		bpl.w	DespawnQuick				; branch if time remains
		move.b	#id_Jun_Action,ost_routine(a0)		; goto Jun_Action next
		bra.w	DespawnQuick

; ---------------------------------------------------------------------------
; Subroutine to update direction when button is pressed and animate
; ---------------------------------------------------------------------------

Jun_Update:
		lea	(v_button_state).w,a2
		moveq	#0,d0
		move.b	ost_subtype(a0),d0
		btst	#0,(a2,d0.w)				; is relevant button pressed?
		beq.s	.unpressed				; if not, branch

		tst.b	ost_junc_button_flag(a0)		; has button previously been pressed?
		bne.s	.animate				; if yes, branch
		neg.b	ost_junc_direction(a0)			; reverse direction (set to -1)
		move.b	#1,ost_junc_button_flag(a0)		; set to "previously pressed"
		bra.s	.animate
; ===========================================================================

.unpressed:
		clr.b	ost_junc_button_flag(a0)		; set to "not yet pressed"

.animate:
		subq.b	#1,ost_anim_time(a0)			; decrement frame timer
		bpl.s	.nochange				; if time remains, branch
		move.b	#7,ost_anim_time(a0)			; 7 frames until next update
		move.b	ost_frame(a0),d0
		add.b	ost_junc_direction(a0),d0		; add direction (1 or -1) to frame
		andi.b	#$F,d0
		move.b	d0,ost_frame(a0)			; update frame

	.nochange:
		rts

; ---------------------------------------------------------------------------
; Subroutine to move Sonic while he's in the junction
; ---------------------------------------------------------------------------

Jun_MoveSonic:
		moveq	#0,d0
		move.b	ost_frame(a0),d0
		add.w	d0,d0					; d0 = current frame * 2
		lea	.data(pc,d0.w),a2			; jump to relevant position data
		move.b	(a2)+,d0
		ext.w	d0
		add.w	ost_x_pos(a0),d0			; get x pos relative to junction
		move.w	d0,ost_x_pos(a1)			; update Sonic's x pos
		move.b	(a2)+,d0
		ext.w	d0
		add.w	ost_y_pos(a0),d0			; get y pos relative to junction
		move.w	d0,ost_y_pos(a1)			; update Sonic's y pos
		rts

.data:		; x pos, y pos
		dc.b -$20,    0					; w
		dc.b -$1E,   $E					; wsw
		dc.b -$18,  $18					; sw
		dc.b  -$E,  $1E					; ssw
		dc.b    0,  $20					; s
		dc.b   $E,  $1E					; sse
		dc.b  $18,  $18					; se
		dc.b  $1E,   $E					; ese
		dc.b  $20,    0					; e
		dc.b  $1E,  -$E					; ene
		dc.b  $18, -$18					; ne
		dc.b   $E, -$1E					; nne
		dc.b    0, -$20					; n
		dc.b  -$E, -$1E					; nnw
		dc.b -$18, -$18					; nw
		dc.b -$1E,  -$E					; wnw

; ---------------------------------------------------------------------------
; Junction background circle object
; ---------------------------------------------------------------------------

JunctionBG:
		bra.w	DespawnQuick
		
