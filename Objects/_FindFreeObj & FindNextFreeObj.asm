; ---------------------------------------------------------------------------
; Subroutine to find a free OST

; output:
;	a1 = address of free OST slot

;	uses d0.w

; usage:
;		bsr.w	FindFreeObj
;		bne.s	.fail					; branch if empty slot isn't found
;		move.l	#Crabmeat,ost_id(a1)			; load Crabmeat object
; ---------------------------------------------------------------------------

FindFreeObj:
		lea	(v_ost_level_obj).w,a1			; start address for OSTs
		move.w	#countof_ost_ert-1,d0

FindFreeObj2:
	.loop:
		tst.l	ost_id(a1)				; is OST slot empty?
		beq.s	.found					; if yes, branch
		lea	sizeof_ost(a1),a1			; goto next OST
		dbf	d0,.loop				; repeat $5F times

	.found:
		rts

; ---------------------------------------------------------------------------
; Subroutine to find a free OST, including inert object slots

; output:
;	a1 = address of free OST slot

;	uses d0.w
; ---------------------------------------------------------------------------

FindFreeInert:
		lea	(v_ost_all+sizeof_ost).w,a1		; start at OST after Sonic
		move.w	#countof_ost-2,d0
		bra.s	FindFreeObj2
		
; ---------------------------------------------------------------------------
; Subroutine to find the last free OST slot

; output:
;	a1 = address of free OST slot

;	uses d0.w
; ---------------------------------------------------------------------------

FindFreeFinal:
		lea	(v_ost_final).w,a1			; last possible OST slot
		move.w	#countof_ost_ert-1,d0

	.loop:
		tst.l	ost_id(a1)				; is OST slot empty?
		beq.s	.found					; if yes, branch
		lea	-sizeof_ost(a1),a1			; goto previous OST
		dbf	d0,.loop				; repeat $5F times

	.found:
		rts
		
; ---------------------------------------------------------------------------
; Subroutine to find a free OST AFTER the current one

; input:
;	a0 = address of current OST slot

; output:
;	a1 = address of free OST slot

;	uses d0.w

; usage:
;		bsr.w	FindNextFreeObj
;		bne.s	.fail					; branch if empty slot isn't found
;		move.b	#id_Bomb,ost_id(a1)			; load Bomb object
; ---------------------------------------------------------------------------

FindNextFreeObj:
		movea.l	a0,a1					; address of OST of current object
		move.w	#v_ost_end&$FFFF,d0			; end of OSTs
		sub.w	a0,d0					; d0 = space between current OST and end
		lsr.w	#6,d0					; divide by $40
		subq.w	#1,d0
		bcs.s	.use_current				; branch if current OST is final

	.loop:
		tst.l	ost_id(a1)				; is OST slot empty?
		beq.s	.found					; if yes, branch
		lea	sizeof_ost(a1),a1			; goto next OST
		dbf	d0,.loop				; repeat until end of OSTs

	.use_current:
	.found:
		rts

; ---------------------------------------------------------------------------
; Subroutine to move the current object to the last available OST slot

;	uses d0.l, a1, a2
; ---------------------------------------------------------------------------

RunLast:
		bsr.s	FindFreeFinal				; a1 = new OST slot
		movea.l	a0,a2
		rept sizeof_ost/4
		move.l	(a2)+,(a1)+				; copy contents of OST to new slot
		endr
		bra.w	DeleteObject				; delete original

; ---------------------------------------------------------------------------
; Subroutine to find a free subsprite slot

; output:
;	a1 = address of free subsprite slot

;	uses d0.l

; usage:
;		bsr.w	FindFreeSub
;		bne.s	.fail					; branch if empty slot isn't found
;		addq.w	#1,(a1)					; create first subsprite
; ---------------------------------------------------------------------------

FindFreeSub:
		lea	(v_subsprite_queue).w,a1		; start address for subsprites
		move.w	#countof_subsprite-1,d0

	.loop:
		tst.w	(a1)					; is OST slot empty?
		beq.s	.found					; if yes, branch
		lea	sizeof_subsprite(a1),a1			; goto next slot
		dbf	d0,.loop				; repeat
		rts

	.found:
		move.w	a1,ost_subsprite(a0)			; save subsprite table address
		moveq	#0,d0					; flag that subsprite slot was found
		rts
