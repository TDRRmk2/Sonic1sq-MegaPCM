; ---------------------------------------------------------------------------
; Always return to this address, bypassing ost_routine (recommended for
;  objects which don't change ost_routine)
; ---------------------------------------------------------------------------

shortcut:	macro
		ifarg \1
		move.l	#\1,ost_id(a0)
		else
		move.l	#.shortcut_here\@,ost_id(a0)
	.shortcut_here\@:
		endc
		endm

; ---------------------------------------------------------------------------
; Save the parent OST address to ost_parent in a child object

; usage:
;		bsr.w	FindFreeObj
;		bne.s	.fail
;		move.l	#Crabmeat,ost_id(a0)
;		saveparent					; use after creating a new object
; ---------------------------------------------------------------------------

saveparent:	macros
		move.w	a0,ost_parent(a1)

; ---------------------------------------------------------------------------
; Set a1 as the parent object
; ---------------------------------------------------------------------------

getparent:	macro
		ifarg \1
		rg: equs "\1"
		else
		rg: equs "a1"					; set a1 as target
		endc
		movea.w	ost_parent(a0),\rg
		endm

; ---------------------------------------------------------------------------
; Set a1 as linked object
; ---------------------------------------------------------------------------

getlinked:	macro
		ifarg \1
		rg: equs "\1"
		else
		rg: equs "a1"					; set a1 as target
		endc
		movea.w	ost_linked(a0),\rg
		endm

; ---------------------------------------------------------------------------
; Set a1 as Sonic
; ---------------------------------------------------------------------------

getsonic:	macro
		ifarg \1
		lea	(v_ost_player).w,\1
		else
		lea	(v_ost_player).w,a1			; set a1 as Sonic
		endc
		endm

; ---------------------------------------------------------------------------
; Set a2 as subsprite table
; ---------------------------------------------------------------------------

getsubsprite:	macro
		ifarg \1
		rg: equs "\1"
		else
		rg: equs "a2"					; set a1 as subsprite table
		endc
		movea.w	ost_subsprite(a0),\rg
		endm

; ---------------------------------------------------------------------------
; Convert speed to position (speed of $100 will move an object 1px per frame)

;	uses d0.l, d1.l
; ---------------------------------------------------------------------------

update_x_pos:	macro
		move.w	ost_x_vel(a0),d0			; load horizontal speed
		ext.l	d0
		asl.l	#8,d0					; multiply speed by $100
		add.l	d0,ost_x_pos(a0)			; update x position
		endm

update_y_pos:	macro
		move.w	ost_y_vel(a0),d0			; load vertical speed
		ext.l	d0
		asl.l	#8,d0					; multiply speed by $100
		add.l	d0,ost_y_pos(a0)			; update y position
		endm

update_xy_pos:	macro
		movem.w	ost_x_vel(a0),d0/d1			; load horizontal & vertical speed
		lsl.l	#8,d0					; multiply x speed by $100
		add.l	d0,ost_x_pos(a0)			; update x position
		lsl.l	#8,d1					; multiply y speed by $100
		add.l	d1,ost_y_pos(a0)			; update y position
		endm

; ---------------------------------------------------------------------------
; Convert speed to position and apply gravity

; input:
;	\1 = gravity (default $38)

;	uses d0.l, d1.l
; ---------------------------------------------------------------------------

update_y_fall:	macro
		update_y_pos
		ifarg \1
		addi.w	#\1,ost_y_vel(a0)			; increase falling speed
		else
		addi.w	#$38,ost_y_vel(a0)			; increase falling speed
		endc
		endm

update_xy_fall:	macro
		update_xy_pos
		ifarg \1
		addi.w	#\1,ost_y_vel(a0)			; increase falling speed
		else
		addi.w	#$38,ost_y_vel(a0)			; increase falling speed
		endc
		endm

; ---------------------------------------------------------------------------
; Get distance between two objects (a0 and a1)

; output:
;	d0.w = x distance (-ve if Sonic is to the left)
;	d1.w = x distance (always +ve)
;	d2.w = y distance (-ve if Sonic is above)
;	d3.w = y distance (always +ve)
; ---------------------------------------------------------------------------

range_x_quick:	macro
		move.w	ost_x_pos(a1),d0
		sub.w	ost_x_pos(a0),d0			; d0 = x dist (-ve if Sonic is to the left)
		endm

range_y_quick:	macro
		move.w	ost_y_pos(a1),d2
		sub.w	ost_y_pos(a0),d2			; d2 = y dist (-ve if Sonic is above)
		endm

range_x:	macro
		range_x_quick					; d0 = x dist (-ve if Sonic is to the left)
		mvabs.w	d0,d1					; make d1 +ve
		endm

range_y:	macro
		range_y_quick					; d2 = y dist (-ve if Sonic is above)
		mvabs.w	d2,d3					; make d3 +ve
		endm

; ---------------------------------------------------------------------------
; Test if two objects (a0 and a1) are within range of each other

; input:
;	\dist = distance to test

;	uses d0.w, d2.w

; usage:
;		range_x_test	16				; test for 16px range
;		bcs.w	.inrange				; branch if within 16px
;		bcc.w	.outrange				; branch if outside 16px
; ---------------------------------------------------------------------------

range_x_test:	macro dist
		range_x_quick					; d0 = x dist (-ve if Sonic is to the left)
		if dist<=8
		addq.w	#dist,d0
		else
		addi.w	#dist,d0
		endc
		cmpi.w	#dist*2,d0
		endm

range_y_test:	macro dist
		range_y_quick					; d2 = y dist (-ve if Sonic is above)
		if dist<=8
		addq.w	#dist,d2
		else
		addi.w	#dist,d2
		endc
		cmpi.w	#dist*2,d2
		endm

; ---------------------------------------------------------------------------
; Get distance between the hitboxes of two objects (a0 and a1)

; output:
;	d0.w = x distance (-ve if Sonic is to the left)
;	d1.w = x distance between hitbox edges (-ve if overlapping)
;	d2.w = y distance (-ve if Sonic is above)
;	d3.w = y distance between hitbox edges (-ve if overlapping)
;	d4.w = x position of Sonic on object, starting at 0 on left edge

;	uses d4.l, d5.l
; ---------------------------------------------------------------------------

range_x_exact:	macro
		range_x
		moveq	#0,d4
		move.b	ost_width(a1),d4
		sub.w	d4,d1
		move.b	ost_width(a0),d4
		sub.w	d4,d1					; d1 = x dist between hitbox edges (-ve if overlapping)
		endm

range_x_sonic:	macro
		range_x
		moveq	#0,d4
		move.b	(v_player1_width).w,d4			; use fixed player width value
		sub.w	d4,d1
		move.b	ost_width(a0),d4
		addq.b	#1,d4
		sub.w	d4,d1					; d1 = x dist between hitbox edges (-ve if overlapping)
		add.w	d0,d4					; d4 = Sonic's x pos relative to left edge
		bpl.s	.keep_pos\@				; branch if +ve
		moveq	#0,d4
	.keep_pos\@:
		endm

range_x_sonic0:	macro						; as above, but ignoring Sonic's width
		range_x
		moveq	#0,d4
		move.b	ost_width(a0),d4
		sub.w	d4,d1					; d1 = x dist between Sonic's x pos and object hitbox edge (-ve if overlapping)
		add.w	d0,d4					; d4 = Sonic's x pos relative to left edge
		endm

range_y_exact:	macro
		range_y
		moveq	#0,d5
		move.b	ost_height(a1),d5
		sub.w	d5,d3
		move.b	ost_height(a0),d5
		addq.b	#1,d5
		sub.w	d5,d3					; d3 = y dist between hitbox edges (-ve if overlapping)
		endm

; ---------------------------------------------------------------------------
; Set the animation id of an object to d0 (do nothing if it's the same as d0)

; input:
;	d0.b = new animation id

; output:
;	d1.b = previous animation id

; usage:
;		moveq	#id_ani_roll_roll,d0
;		set_anim
; ---------------------------------------------------------------------------

set_anim:	macro
		move.b	ost_anim(a0),d1				; get previous animation id
		andi.b	#$7F,d1					; ignore high bit (the no-restart flag)
		cmp.b	d0,d1					; compare with new id
		beq.s	.keepanim\@				; branch if same
		move.b	d0,ost_anim(a0)				; update animation id (and clear high bit)
	.keepanim\@:
		endm

; ---------------------------------------------------------------------------
; Halt object execution if it's above or below the screen

; input:
;	d0.w = y position

; usage:
;		move.w	ost_y_pos(a0),d0
;		waitvisible	120,240				; halt if object is 120px above or 240px below screen
; ---------------------------------------------------------------------------

waitvisible:	macro
		sub.w	(v_camera_y_pos).w,d0			; d0 = dist between object and top of screen (-ve if object is above)
		addi.w	#\1,d0					; d0 = dist between object and upper limit (-ve if object is above)
		cmpi.w	#\1+screen_height+\2,d0
		bcs.s	.inside_range\@				; branch if within upper and lower limit
		rts						; object is outside
	.inside_range\@:
		endm

; ---------------------------------------------------------------------------
; Alternate between two frames of animation

; input:
;	\1 = delay in frames
; ---------------------------------------------------------------------------

toggleframe:	macro
		ifarg \1
		subq.b	#1,ost_anim_time(a0)			; decrement time
		bpl.s	.wait\@					; branch if time remains
		chr1:	substr ,1,"\1"				; get first character
		if strcmp("d","\chr1")				; check if it's a register
		move.b	\1,ost_anim_time(a0)			; reset time (dx)
		else
		move.b	#\1,ost_anim_time(a0)			; reset time (#n)
		endc
		bchg	#0,ost_frame(a0)			; toggle between frame 0 and 1
	.wait\@:
		else
		bchg	#0,ost_frame(a0)			; toggle between frame 0 and 1
		endc
		endm

; ---------------------------------------------------------------------------
; Multiply a number by 60

; input:
;	\1.w = dx register to multiply by 60

;	uses \2.w
; ---------------------------------------------------------------------------

mul60:		macro
		move.w	\1,\2
		lsl.w	#6,\1
		add.w	\2,\2
		add.w	\2,\2
		sub.w	\2,\1
		endm

; ---------------------------------------------------------------------------
; Copy x/y position of object to d0/d1
; ---------------------------------------------------------------------------

getpos:		macro
		move.w	ost_x_pos(a0),d0
		move.w	ost_y_pos(a0),d1
		endm

getpos_y:	macro
		ifarg \1
		moveq	#\1,d1
		add.w	ost_y_pos(a0),d1
		else
		moveq	#0,d1
		move.b	ost_height(a0),d1
		add.w	ost_y_pos(a0),d1
		endc
		endm

getpos_y_neg:	macro
		ifarg \1
		moveq	#-\1,d1
		add.w	ost_y_pos(a0),d1
		else
		moveq	#0,d1
		move.b	ost_height(a0),d1
		neg.w	d1
		add.w	ost_y_pos(a0),d1
		endc
		endm

getpos_bottom:	macro
		move.w	ost_x_pos(a0),d0
		getpos_y \1
		endm

getpos_top:	macro
		move.w	ost_x_pos(a0),d0
		getpos_y_neg \1
		endm

getpos_x:	macro
		ifarg \1
		moveq	#\1,d0
		add.w	ost_x_pos(a0),d0
		else
		moveq	#0,d0
		move.b	ost_width(a0),d0
		add.w	ost_x_pos(a0),d0
		endc
		endm

getpos_x_neg:	macro
		ifarg \1
		moveq	#-\1,d0
		add.w	ost_x_pos(a0),d0
		else
		moveq	#0,d0
		move.b	ost_width(a0),d0
		neg.w	d0
		add.w	ost_x_pos(a0),d0
		endc
		endm

getpos_right:	macro
		getpos_x \1
		move.w	ost_y_pos(a0),d1
		endm

getpos_left:	macro
		getpos_x_neg \1
		move.w	ost_y_pos(a0),d1
		endm

getpos_bottomright:	macro
		getpos_x \1
		getpos_y \2
		endm

getpos_bottomleft:	macro
		getpos_x_neg \1
		getpos_y \2
		endm

getpos_bottomforward:	macro
		ifarg \1
		moveq	#\1,d0
		tst.w	ost_x_vel(a0)
		bpl.s	.right\@				; branch if moving right
		moveq	#-\1,d0
	.right\@:
		add.w	ost_x_pos(a0),d0
		else
		moveq	#0,d0
		move.b	ost_width(a0),d0
		tst.w	ost_x_vel(a0)
		bpl.s	.right\@				; branch if moving right
		neg.w	d0
	.right\@:
		add.w	ost_x_pos(a0),d0
		endc
		getpos_y \2
		endm

getpos_topright:	macro
		getpos_x \1
		getpos_y_neg \2
		endm

getpos_topleft:	macro
		getpos_x_neg \1
		getpos_y_neg \2
		endm
		