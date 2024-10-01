; ---------------------------------------------------------------------------
; Subroutine to play music for LZ/SBZ3 after a countdown

; output:
;	d0.w = track number
; ---------------------------------------------------------------------------

ResumeMusic:
		cmpi.b	#air_alert,(v_air).w			; more than 12 seconds of air left?
		bhi.s	.over12					; if yes, branch
		move.b	(v_bgm).w,d0
		tst.w	(v_invincibility).w			; is Sonic invincible?
		beq.s	.notinvinc				; if not, branch
		move.w	#mus_Invincible,d0

	.notinvinc:
		tst.b	(f_boss_loaded).w			; is Sonic at a boss?
		beq.s	.playselected				; if not, branch
		move.w	#mus_Boss,d0

	.playselected:
		play_music d0

	.over12:
		move.w	#air_full<<8,(v_air).w			; reset air to 30 seconds
		rts
