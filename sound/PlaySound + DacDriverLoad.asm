; ---------------------------------------------------------------------------
; Subroutines to play sounds in various queue slots
;
; input:
;	d0 = sound to play
; ---------------------------------------------------------------------------

PlaySound0:
		move.b	d0,(v_snddriver_ram+v_soundqueue+0).w	; play in slot 0
		rts

PlaySound1:
		move.b	d0,(v_snddriver_ram+v_soundqueue+1).w	; play in slot 1
		rts

PlaySound2:
		move.b	d0,(v_snddriver_ram+v_soundqueue+2).w	; play in slot 2 (broken!)
		rts
