
; ==============================================================================
; ------------------------------------------------------------------------------
; Mega PCM 2.0 - DAC Sound Driver
;
; Documentation, examples and source code are available at:
; - https://github.com/vladikcomper/MegaPCM/tree/2.x
;
; (c) 2012-2024, Vladikcomper
; ------------------------------------------------------------------------------

; ==============================================================================
; ------------------------------------------------------------------------------
; Constants
; ------------------------------------------------------------------------------


; ------------------------------------------------------------------------------
; Definitions for sample table
; ------------------------------------------------------------------------------

FLAGS_SFX:		equ	$01		; sample is SFX, normal drums cannot interrupt it
FLAGS_LOOP:		equ	$02		; loop sample indefinitely

TYPE_NONE:		equ	$00
TYPE_PCM:		equ	'P'
TYPE_PCM_TURBO:	equ	'T'
TYPE_DPCM:		equ	'D'

; ------------------------------------------------------------------------------
; Maximum playback rates:
TYPE_PCM_TURBO_MAX_RATE:	equ	32000 ; Hz
TYPE_PCM_MAX_RATE:			equ	25100 ; Hz
TYPE_DPCM_MAX_RATE:			equ	20600 ; Hz

; Internal driver's base rates for pitched playback.
; NOTICE: Actual max rates are slightly lower,
; because the highest pitch is 255/256, not 256/256.
TYPE_PCM_BASE_RATE:			equ	25208 ; Hz
TYPE_DPCM_BASE_RATE:		equ	20691 ; Hz


; ------------------------------------------------------------------------------
; Return error codes for `MegaPCM_LoadSampleTable`
; ------------------------------------------------------------------------------

MPCM_ST_TOO_MANY_SAMPLES:			equ	$01
MPCM_ST_UNKNOWN_SAMPLE_TYPE:		equ	$02

MPCM_ST_PITCH_NOT_SET:				equ	$10

MPCM_ST_WAVE_INVALID_HEADER:		equ	$20
MPCM_ST_WAVE_BAD_AUDIO_FORMAT:		equ	$21
MPCM_ST_WAVE_NOT_MONO:				equ	$22
MPCM_ST_WAVE_NOT_8BIT:				equ	$23
MPCM_ST_WAVE_BAD_SAMPLE_RATE:		equ	$24
MPCM_ST_WAVE_MISSING_DATA_CHUNK:	equ	$25


; ------------------------------------------------------------------------------
; System Ports used by Mega PCM
; ------------------------------------------------------------------------------

MPCM_Z80_RAM:		equ		$A00000
MPCM_Z80_BUSREQ:	equ		$A11100
MPCM_Z80_RESET:		equ		$A11200

MPCM_YM2612_A0:		equ		$A04000
MPCM_YM2612_D0:		equ		$A04001
MPCM_YM2612_A1:		equ		$A04002
MPCM_YM2612_D1:		equ		$A04003

; ------------------------------------------------------------------------------
; Z80 equates
; ------------------------------------------------------------------------------

Z_MPCM_DriverReady:	equ $1fc3
Z_MPCM_CommandInput:	equ $1fc2
Z_MPCM_VolumeInput:	equ $1fc4
Z_MPCM_SFXVolumeInput:	equ $1fc5
Z_MPCM_PanInput:	equ $1fc6
Z_MPCM_SFXPanInput:	equ $1fc7
Z_MPCM_LoopId:	equ $1fdd
Z_MPCM_ActiveSamplePitch:	equ $1fdc
Z_MPCM_VBlankActive:	equ $1fe2
Z_MPCM_CalibrationApplied:	equ $1fe3
Z_MPCM_CalibrationScore_ROM:	equ $1fe4
Z_MPCM_CalibrationScore_RAM:	equ $1fe6
Z_MPCM_LastErrorCode:	equ $1fe8
Z_MPCM_SampleTable:	equ $1976
Z_MPCM_COMMAND_STOP:	equ $1
Z_MPCM_COMMAND_PAUSE:	equ $2
Z_MPCM_LOOP_IDLE:	equ $1
Z_MPCM_LOOP_PAUSE:	equ $2
Z_MPCM_LOOP_PCM:	equ $10
Z_MPCM_LOOP_PCM_TURBO:	equ $18
Z_MPCM_LOOP_DPCM:	equ $20
Z_MPCM_LOOP_CALIBRATION:	equ $80
Z_MPCM_ERROR__BAD_INTERRUPT:	equ $2
Z_MPCM_ERROR__BAD_SAMPLE_TYPE:	equ $1
Z_MPCM_ERROR__UNKNOWN_COMMAND:	equ $80

; ==============================================================================
; ------------------------------------------------------------------------------
; Macros
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Macro to generate sample record in a sample table
; ------------------------------------------------------------------------------
; ARGUMENTS:
;	type - Sample type (TYPE_PCM, TYPE_DPCM, TYPE_PCM_TURBO or TYPE_NONE)
;	samplePtr - Sample pointer/name (assigned via `incdac` macro)
;	sampleRateHz? - (Optional) Playback rate in Hz, auto-detected for .WAV
;	flags? - (Optional) Additional flags (e.g. FLAGS_SFX or FLAGS_LOOP)
; ------------------------------------------------------------------------------

dcSample: macro	type, samplePtr, sampleRateHz, flags
	if narg>4
		inform 2, "Too many arguments. USAGE: dcSample type, samplePtr, sampleRateHz, flags"
	endif

	dc.b	\type					; $00	- type

	if \type=TYPE_PCM
		if \sampleRateHz+0>TYPE_PCM_MAX_RATE
			inform 2, "Invalid sample rate: \sampleRateHz\. TYPE_PCM only supports sample rates <= \#TYPE_PCM_MAX_RATE Hz"
		endif
		dc.b	\flags+0								; $01	- flags (optional)
		dc.b	(\sampleRateHz+0)*256/TYPE_PCM_BASE_RATE; $02	- pitch (optional for .WAV files)
		dc.b	0										; $03	- <RESERVED>
		dc.l	\samplePtr								; $04	- start offset
		dc.l	\samplePtr\_End							; $08	- end offset

	elseif \type=TYPE_PCM_TURBO
		if (\sampleRateHz+0<>TYPE_PCM_TURBO_MAX_RATE)&(\sampleRateHz+0<>0)
			inform 2, "Invalid sample rate: \sampleRateHz\. TYPE_PCM_TURBO only supports sample rate of \#TYPE_PCM_TURBO_MAX_RATE Hz"
		endif
		dc.b	\flags+0								; $01	- flags (optional)
		dc.b	$FF										; $02	- pitch (optional for .WAV files)
		dc.b	0										; $03	- <RESERVED>
		dc.l	\samplePtr								; $04	- start offset
		dc.l	\samplePtr\_End							; $08	- end offset

	elseif \type=TYPE_DPCM
		if \sampleRateHz>TYPE_DPCM_MAX_RATE
			inform 2, "Invalid sample rate: \sampleRateHz\. TYPE_DPCM only supports sample rates <= \#TYPE_DPCM_MAX_RATE Hz"
		endif
		dc.b	\flags+0								; $01	- flags (optional)
		dc.b	(\sampleRateHz)*256/TYPE_DPCM_BASE_RATE	; $02	- pitch
		dc.b	0										; $03	- <RESERVED>
		dc.l	\samplePtr								; $04	- start offset
		dc.l	\samplePtr\_End							; $08	- end offset

	elseif \type=TYPE_NONE
		dc.b	0, 0, 0
		dc.l	0, 0

	else
		inform 2, "Unknown sample type. Please use one of: TYPE_PCM, TYPE_DPCM, TYPE_PCM_TURBO, TYPE_NONE"
	endif
	endm

; ------------------------------------------------------------------------------
; Macro to include a sample file
; ------------------------------------------------------------------------------
; ARGUMENTS:
;	name - Name assigned to the sample (label)
;	path - Sample's include path (string)
; ------------------------------------------------------------------------------

incdac:	macro name, path
		even
	\name:
		incbin	\path
	\name\_End:
	endm

; ------------------------------------------------------------------------------
; Macro to stop Z80 and take over its bus
; ------------------------------------------------------------------------------
; ARGUMENTS:
;	opBusReq? - (Optional) Custom operand for Z80_BUSREQ
; ------------------------------------------------------------------------------

MPCM_stopZ80:	macro opBusReq
	pusho
	opt		l-		; make sure "@" marks local labels

	if narg=1
		move.w	#$100, \opBusReq
		@wait\@:
			btst	#0, \opBusReq
			bne.s	@wait\@
	else
		move.w	#$100, MPCM_Z80_BUSREQ
		@wait\@:
			btst	#0, MPCM_Z80_BUSREQ
			bne.s	@wait\@
	endif

	popo
	endm

; ------------------------------------------------------------------------------
; Macro to start Z80 and release its bus
; ------------------------------------------------------------------------------
; ARGUMENTS:
;	opBusReq? - (Optional) Custom operand for Z80_BUSREQ
; ------------------------------------------------------------------------------

MPCM_startZ80:	macro opBusReq
	if narg=1
		move.w	#0, \opBusReq
	else
		move.w	#0, MPCM_Z80_BUSREQ
	endif
	endm

; ------------------------------------------------------------------------------
; Ensures Mega PCM 2 isn't busy writing to YM (other than DAC output obviously)
; ------------------------------------------------------------------------------
; ARGUMENTS:
;	opBusReq? - (Optional) Custom operand for Z80_BUSREQ
; ------------------------------------------------------------------------------

MPCM_ensureYMWriteReady:	macro opBusReq
	pusho
	opt		l-		; make sure "@" marks local labels

	@chk_ready\@:
		tst.b	(MPCM_Z80_RAM+Z_MPCM_DriverReady).l
		bne.s	@ready\@
		MPCM_startZ80 \opBusReq
		move.w	d0, -(sp)
		moveq	#10, d0
		dbf		d0, *						; waste 100+ cycles
		move.w	(sp)+, d0
		MPCM_stopZ80 \opBusReq
		bra.s	@chk_ready\@
	@ready\@:

	popo
	endm

; ==============================================================================
; ------------------------------------------------------------------------------
; Mega PCM library blob
; ------------------------------------------------------------------------------

MegaPCMLibraryBlob:

	dc.l	$40E746FC, $27002F0B, $47F900A1, $1100303C, $01003680, $37400100, $41FA0346, $43F900A0
	dc.l	$0000323C, $197512D8, $51C9FFFC, $72003741, $010041F9, $00A01FC3, $4E714E71, $37400100
	dc.l	$36816016, $36BC0100, $08130000, $66FA1210, $36BC0000, $0C010052, $670A303C, $0FFF51C8
	dc.l	$FFFE60E0, $265F46DF, $4E7548E7, $3C3847F9, $00A11100, $43F900A0, $1976594F, $747E1A18
	dc.l	$67000174, $6B000160, $18181618, $52482458, $28580C05, $00446700, $00F80C05, $00506708
	dc.l	$0C050054, $66000184, $20120C80, $52494646, $67180C80, $41494646, $67000174, $0C804E49
	dc.l	$53546600, $00C46000, $01660CAA, $57415645, $00086600, $015A45EA, $000C0C92, $666D7420
	dc.l	$6600014C, $0C6A0100, $00086700, $000C0C6A, $FEFF0008, $6600013C, $0C6A0100, $000A6600
	dc.l	$01360C6A, $08000016, $66000130, $4A036630, $1EAA000D, $1F6A000C, $00013017, $0C050054
	dc.l	$660C0C40, $7D006600, $011676FF, $60120C40, $620C6200, $010A48C0, $E18880FC, $62781600
	dc.l	$B5CC6400, $00FE1EAA, $00071F6A, $00060001, $1F6A0005, $00021F6A, $00040003, $201745F2
	dc.l	$08080C92, $64617461, $66D61EAA, $00071F6A, $00060001, $1F6A0005, $00021F6A, $00040003
	dc.l	$201749F2, $0808504A, $300C0240, $000198C0, $4A036700, $00B2200A, $D0805240, $E2583E80
	dc.l	$4840220C, $D2815241, $E2593F41, $00024841, $40E746FC, $270036BC, $01000813, $000066FA
	dc.l	$12C512C4, $12C312C0, $12C112EF, $000312EF, $000212EF, $000512EF, $000436BC, $000046DF
	dc.l	$51CAFE9C, $60405348, $700041E8, $FFF4584F, $4CDF1C3C, $4E7540E7, $46FC2700, $36BC0100
	dc.l	$08130000, $66FA12C5, $12C512C5, $12C512C5, $12C512C5, $12C512C5, $36BC0000, $46DF41E8
	dc.l	$000B51CA, $FE5A7001, $60C07002, $60BC7020, $60B87021, $60B47022, $60B07023, $60AC7024
	dc.l	$60A87025, $60A47010, $60A033FC, $010000A1, $11000839, $000000A1, $110066F6, $13C000A0
	dc.l	$1FC233FC, $000000A1, $11004E75, $33FC0100, $00A11100, $08390000, $00A11100, $66F613FC
	dc.l	$000200A0, $1FC233FC, $000000A1, $11004E75, $33FC0100, $00A11100, $08390000, $00A11100
	dc.l	$66F613FC, $000000A0, $1FC233FC, $000000A1, $11004E75, $33FC0100, $00A11100, $08390000
	dc.l	$00A11100, $66F613FC, $000100A0, $1FC233FC, $000000A1, $11004E75, $33FC0100, $00A11100
	dc.l	$08390000, $00A11100, $66F613C0, $00A01FC4, $33FC0000, $00A11100, $4E7533FC, $010000A1
	dc.l	$11000839, $000000A1, $110066F6, $13C000A0, $1FC533FC, $000000A1, $11004E75, $33FC0100
	dc.l	$00A11100, $08390000, $00A11100, $66F613C0, $00A01FC6, $33FC0000, $00A11100, $4E7533FC
	dc.l	$010000A1, $11000839, $000000A1, $110066F6, $13C000A0, $1FC733FC, $000000A1, $11004E75
	dc.l	$F3ED56C3, $D1180000, $FEFFC210, $00C90000, $320900E5, $21006077, $0F770F77, $0F770F77
	dc.l	$0F770F77, $0F7775E1, $C94D6567, $6150434D, $20762E32, $2E300000, $C33B00F5, $3E0232E8
	dc.l	$1FF1C9F3, $3E1032DD, $1F214301, $223900ED, $73DE1FDD, $F933F1C1, $E1D131DD, $1FF508CB
	dc.l	$FCCB85E5, $7AE67F57, $CB83B320, $03051680, $D578B920, $0BDA6919, $CBBCEBED, $52C38700
	dc.l	$AF955F9C, $8557EBE5, $C521C41F, $0830012C, $E5ED7BDE, $1FDD21D1, $1F3AD31F, $CFF32AD9
	dc.l	$1FED4BD5, $1F110003, $D908AF08, $ED4BD11F, $0AE60FC6, $04473ADC, $1FFD6F21, $00031101
	dc.l	$40D9FB00, $3E00F3ED, $A0EDA016, $03E2EE00, $D94E0A12, $08FD8530, $012C087D, $D9FB9392
	dc.l	$D2C600F5, $3E000000, $0000F1F3, $18E2FB3A, $0900DDBE, $032025F3, $7BD9BD28, $154E0A12
	dc.l	$08FD8530, $012C08D9, $FBC50303, $030303C1, $18E5D9FB, $DDCB0A4E, $C29900C9, $3A09003C
	dc.l	$21008044, $DDBE0320, $04ED4BD7, $1FD7C3C6, $0021E100, $36C42336, $00C9D900, $030B030B
	dc.l	$001814F5, $C5068E7B, $D9BD28EE, $4E0A1208, $FD853001, $2C08D93E, $FF32E21F, $E52329E1
	dc.l	$10E57BD9, $BD280A4E, $0A1208FD, $8530012C, $08D9D9ED, $4BD11F0A, $E60FC604, $47D9007B
	dc.l	$D9BD280A, $4E0A1208, $FD853001, $2C08D93A, $DC1FFD6F, $3AC21FB7, $280EF2BF, $01DDCB0A
	dc.l	$46CAF118, $AF32C21F, $32E21F7B, $D9BD280A, $4E0A1208, $FD853001, $2C08D9C1, $F1FBC93D
	dc.l	$CA69193D, $2005FD2E, $0018DD3E, $8032E81F, $18D2F33E, $1832DD1F, $21A00222, $3900ED73
	dc.l	$DE1FDDF9, $33F1C1E1, $D131DD1F, $F5CBFCCB, $85E57AE6, $7F57CB83, $B3200305, $1680D578
	dc.l	$B9200BDA, $6919CBBC, $EBED52C3, $1502AF95, $5F9C8557, $EBE5C5ED, $7BDE1FDD, $21D11F3A
	dc.l	$D31FCFF3, $1100032A, $D91FED4B, $D51FD921, $00031101, $40D93E00, $F3EDA0ED, $A01603E2
	dc.l	$5602D97E, $122C7DD9, $FB9392D2, $3802E523, $2309E1F3, $18ECFB3A, $0900DDBE, $03201DF3
	dc.l	$7BD9BD28, $0D7E122C, $D9FBE5C5, $09C1E1C3, $5F02D9FB, $DDCB0A4E, $C21F02C9, $3A09003C
	dc.l	$21008044, $DDBE0320, $04ED4BD7, $1FD7C338, $02214C02, $36362336, $02C9D93E, $00C3AD02
	dc.l	$F5C506BF, $7BD9BD28, $F17E122C, $D93EFF32, $E21F3E00, $C5010000, $C110E900, $7BD9BD28
	dc.l	$037E122C, $D93AC21F, $B7280EF2, $E002DDCB, $0A46CAF1, $18AF32C2, $1F32E21F, $C1F1FBC9
	dc.l	$3DCA6919, $3D2006CD, $5C18AF18, $EC3E8032, $E81F18E1, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000, $00000000
	dc.l	$00010203, $04050607, $08090A0B, $0C0D0E0F, $10111213, $14151617, $18191A1B, $1C1D1E1F
	dc.l	$20212223, $24252627, $28292A2B, $2C2D2E2F, $30313233, $34353637, $38393A3B, $3C3D3E3F
	dc.l	$40414243, $44454647, $48494A4B, $4C4D4E4F, $50515253, $54555657, $58595A5B, $5C5D5E5F
	dc.l	$60616263, $64656667, $68696A6B, $6C6D6E6F, $70717273, $74757677, $78797A7B, $7C7D7E7F
	dc.l	$80818283, $84858687, $88898A8B, $8C8D8E8F, $90919293, $94959697, $98999A9B, $9C9D9E9F
	dc.l	$A0A1A2A3, $A4A5A6A7, $A8A9AAAB, $ACADAEAF, $B0B1B2B3, $B4B5B6B7, $B8B9BABB, $BCBDBEBF
	dc.l	$C0C1C2C3, $C4C5C6C7, $C8C9CACB, $CCCDCECF, $D0D1D2D3, $D4D5D6D7, $D8D9DADB, $DCDDDEDF
	dc.l	$E0E1E2E3, $E4E5E6E7, $E8E9EAEB, $ECEDEEEF, $F0F1F2F3, $F4F5F6F7, $F8F9FAFB, $FCFDFEFF
	dc.l	$08090A0B, $0C0D0E0F, $10101112, $13141516, $1718191A, $1B1C1D1E, $1E1F2021, $22232425
	dc.l	$26272829, $2A2B2C2C, $2D2E2F30, $31323334, $35363738, $393A3A3B, $3C3D3E3F, $40414243
	dc.l	$44454647, $4848494A, $4B4C4D4E, $4F505152, $53545556, $56575859, $5A5B5C5D, $5E5F6061
	dc.l	$62636464, $65666768, $696A6B6C, $6D6E6F70, $71727273, $74757677, $78797A7B, $7C7D7E7F
	dc.l	$80808182, $83848586, $8788898A, $8B8C8D8E, $8E8F9091, $92939495, $96979899, $9A9B9C9C
	dc.l	$9D9E9FA0, $A1A2A3A4, $A5A6A7A8, $A9AAAAAB, $ACADAEAF, $B0B1B2B3, $B4B5B6B7, $B8B8B9BA
	dc.l	$BBBCBDBE, $BFC0C1C2, $C3C4C5C6, $C6C7C8C9, $CACBCCCD, $CECFD0D1, $D2D3D4D4, $D5D6D7D8
	dc.l	$D9DADBDC, $DDDEDFE0, $E1E2E2E3, $E4E5E6E7, $E8E9EAEB, $ECEDEEEF, $F0F0F1F2, $F3F4F5F6
	dc.l	$11111213, $14151617, $1818191A, $1B1C1D1E, $1E1F2021, $22232425, $25262728, $292A2B2B
	dc.l	$2C2D2E2F, $30313232, $33343536, $37383839, $3A3B3C3D, $3E3F3F40, $41424344, $45454647
	dc.l	$48494A4B, $4C4C4D4E, $4F505152, $52535455, $56575859, $595A5B5C, $5D5E5F5F, $60616263
	dc.l	$64656666, $6768696A, $6B6C6C6D, $6E6F7071, $72737374, $75767778, $79797A7B, $7C7D7E7F
	dc.l	$80808182, $83848586, $86878889, $8A8B8C8D, $8D8E8F90, $91929393, $94959697, $98999A9A
	dc.l	$9B9C9D9E, $9FA0A0A1, $A2A3A4A5, $A6A7A7A8, $A9AAABAC, $ADADAEAF, $B0B1B2B3, $B4B4B5B6
	dc.l	$B7B8B9BA, $BABBBCBD, $BEBFC0C1, $C1C2C3C4, $C5C6C7C7, $C8C9CACB, $CCCDCECE, $CFD0D1D2
	dc.l	$D3D4D4D5, $D6D7D8D9, $DADBDBDC, $DDDEDFE0, $E1E1E2E3, $E4E5E6E7, $E8E8E9EA, $EBECEDEE
	dc.l	$191A1B1C, $1C1D1E1F, $20202122, $23242425, $26272828, $292A2B2C, $2C2D2E2F, $30303132
	dc.l	$33343435, $36373838, $393A3B3C, $3C3D3E3F, $40404142, $43444445, $46474848, $494A4B4C
	dc.l	$4C4D4E4F, $50505152, $53545455, $56575858, $595A5B5C, $5C5D5E5F, $60606162, $63646465
	dc.l	$66676868, $696A6B6C, $6C6D6E6F, $70707172, $73747475, $76777878, $797A7B7C, $7C7D7E7F
	dc.l	$80808182, $83848485, $86878888, $898A8B8C, $8C8D8E8F, $90909192, $93949495, $96979898
	dc.l	$999A9B9C, $9C9D9E9F, $A0A0A1A2, $A3A4A4A5, $A6A7A8A8, $A9AAABAC, $ACADAEAF, $B0B0B1B2
	dc.l	$B3B4B4B5, $B6B7B8B8, $B9BABBBC, $BCBDBEBF, $C0C0C1C2, $C3C4C4C5, $C6C7C8C8, $C9CACBCC
	dc.l	$CCCDCECF, $D0D0D1D2, $D3D4D4D5, $D6D7D8D8, $D9DADBDC, $DCDDDEDF, $E0E0E1E2, $E3E4E4E5
	dc.l	$22222324, $25252627, $2828292A, $2A2B2C2D, $2D2E2F30, $30313233, $33343535, $36373838
	dc.l	$393A3B3B, $3C3D3E3E, $3F404041, $42434344, $45464647, $4849494A, $4B4B4C4D, $4E4E4F50
	dc.l	$51515253, $54545556, $56575859, $595A5B5C, $5C5D5E5F, $5F606161, $62636464, $65666767
	dc.l	$68696A6A, $6B6C6C6D, $6E6F6F70, $71727273, $74757576, $77777879, $7A7A7B7C, $7D7D7E7F
	dc.l	$80808182, $82838485, $85868788, $88898A8B, $8B8C8D8D, $8E8F9090, $91929393, $94959696
	dc.l	$97989899, $9A9B9B9C, $9D9E9E9F, $A0A1A1A2, $A3A3A4A5, $A6A6A7A8, $A9A9AAAB, $ACACADAE
	dc.l	$AEAFB0B1, $B1B2B3B4, $B4B5B6B7, $B7B8B9B9, $BABBBCBC, $BDBEBFBF, $C0C1C2C2, $C3C4C4C5
	dc.l	$C6C7C7C8, $C9CACACB, $CCCDCDCE, $CFCFD0D1, $D2D2D3D4, $D5D5D6D7, $D8D8D9DA, $DADBDCDD
	dc.l	$2A2B2C2C, $2D2E2E2F, $30303132, $32333434, $35363637, $3838393A, $3A3B3C3C, $3D3E3E3F
	dc.l	$40404142, $42434444, $45464647, $4848494A, $4A4B4C4C, $4D4E4E4F, $50505152, $52535454
	dc.l	$55565657, $5858595A, $5A5B5C5C, $5D5E5E5F, $60606162, $62636464, $65666667, $6868696A
	dc.l	$6A6B6C6C, $6D6E6E6F, $70707172, $72737474, $75767677, $7878797A, $7A7B7C7C, $7D7E7E7F
	dc.l	$80808182, $82838484, $85868687, $8888898A, $8A8B8C8C, $8D8E8E8F, $90909192, $92939494
	dc.l	$95969697, $9898999A, $9A9B9C9C, $9D9E9E9F, $A0A0A1A2, $A2A3A4A4, $A5A6A6A7, $A8A8A9AA
	dc.l	$AAABACAC, $ADAEAEAF, $B0B0B1B2, $B2B3B4B4, $B5B6B6B7, $B8B8B9BA, $BABBBCBC, $BDBEBEBF
	dc.l	$C0C0C1C2, $C2C3C4C4, $C5C6C6C7, $C8C8C9CA, $CACBCCCC, $CDCECECF, $D0D0D1D2, $D2D3D4D4
	dc.l	$33333435, $35363637, $38383939, $3A3B3B3C, $3C3D3E3E, $3F3F4041, $41424243, $44444545
	dc.l	$46474748, $48494A4A, $4B4B4C4D, $4D4E4E4F, $50505151, $52535354, $54555656, $57575859
	dc.l	$595A5A5B, $5C5C5D5D, $5E5F5F60, $60616262, $63636465, $65666667, $68686969, $6A6B6B6C
	dc.l	$6C6D6E6E, $6F6F7071, $71727273, $74747575, $76777778, $78797A7A, $7B7B7C7D, $7D7E7E7F
	dc.l	$80808181, $82838384, $84858686, $87878889, $898A8A8B, $8C8C8D8D, $8E8F8F90, $90919292
	dc.l	$93939495, $95969697, $98989999, $9A9B9B9C, $9C9D9E9E, $9F9FA0A1, $A1A2A2A3, $A4A4A5A5
	dc.l	$A6A7A7A8, $A8A9AAAA, $ABABACAD, $ADAEAEAF, $B0B0B1B1, $B2B3B3B4, $B4B5B6B6, $B7B7B8B9
	dc.l	$B9BABABB, $BCBCBDBD, $BEBFBFC0, $C0C1C2C2, $C3C3C4C5, $C5C6C6C7, $C8C8C9C9, $CACBCBCC
	dc.l	$3B3C3C3D, $3D3E3E3F, $40404141, $42424343, $44444545, $46464748, $4849494A, $4A4B4B4C
	dc.l	$4C4D4D4E, $4E4F5050, $51515252, $53535454, $55555656, $57585859, $595A5A5B, $5B5C5C5D
	dc.l	$5D5E5E5F, $60606161, $62626363, $64646565, $66666768, $6869696A, $6A6B6B6C, $6C6D6D6E
	dc.l	$6E6F7070, $71717272, $73737474, $75757676, $77787879, $797A7A7B, $7B7C7C7D, $7D7E7E7F
	dc.l	$80808181, $82828383, $84848585, $86868788, $8889898A, $8A8B8B8C, $8C8D8D8E, $8E8F9090
	dc.l	$91919292, $93939494, $95959696, $97989899, $999A9A9B, $9B9C9C9D, $9D9E9E9F, $A0A0A1A1
	dc.l	$A2A2A3A3, $A4A4A5A5, $A6A6A7A8, $A8A9A9AA, $AAABABAC, $ACADADAE, $AEAFB0B0, $B1B1B2B2
	dc.l	$B3B3B4B4, $B5B5B6B6, $B7B8B8B9, $B9BABABB, $BBBCBCBD, $BDBEBEBF, $C0C0C1C1, $C2C2C3C3
	dc.l	$44444545, $46464747, $48484849, $494A4A4B, $4B4C4C4D, $4D4E4E4F, $4F4F5050, $51515252
	dc.l	$53535454, $55555656, $56575758, $5859595A, $5A5B5B5C, $5C5D5D5D, $5E5E5F5F, $60606161
	dc.l	$62626363, $64646465, $65666667, $67686869, $696A6A6B, $6B6B6C6C, $6D6D6E6E, $6F6F7070
	dc.l	$71717272, $72737374, $74757576, $76777778, $78797979, $7A7A7B7B, $7C7C7D7D, $7E7E7F7F
	dc.l	$80808081, $81828283, $83848485, $85868687, $87878888, $89898A8A, $8B8B8C8C, $8D8D8E8E
	dc.l	$8E8F8F90, $90919192, $92939394, $94959595, $96969797, $98989999, $9A9A9B9B, $9C9C9C9D
	dc.l	$9D9E9E9F, $9FA0A0A1, $A1A2A2A3, $A3A3A4A4, $A5A5A6A6, $A7A7A8A8, $A9A9AAAA, $AAABABAC
	dc.l	$ACADADAE, $AEAFAFB0, $B0B1B1B1, $B2B2B3B3, $B4B4B5B5, $B6B6B7B7, $B8B8B8B9, $B9BABABB
	dc.l	$4C4D4D4E, $4E4E4F4F, $50505051, $51525252, $53535454, $54555556, $56565757, $58585859
	dc.l	$595A5A5A, $5B5B5C5C, $5C5D5D5E, $5E5E5F5F, $60606061, $61626262, $63636464, $64656566
	dc.l	$66666767, $68686869, $696A6A6A, $6B6B6C6C, $6C6D6D6E, $6E6E6F6F, $70707071, $71727272
	dc.l	$73737474, $74757576, $76767777, $78787879, $797A7A7A, $7B7B7C7C, $7C7D7D7E, $7E7E7F7F
	dc.l	$80808081, $81828282, $83838484, $84858586, $86868787, $88888889, $898A8A8A, $8B8B8C8C
	dc.l	$8C8D8D8E, $8E8E8F8F, $90909091, $91929292, $93939494, $94959596, $96969797, $98989899
	dc.l	$999A9A9A, $9B9B9C9C, $9C9D9D9E, $9E9E9F9F, $A0A0A0A1, $A1A2A2A2, $A3A3A4A4, $A4A5A5A6
	dc.l	$A6A6A7A7, $A8A8A8A9, $A9AAAAAA, $ABABACAC, $ACADADAE, $AEAEAFAF, $B0B0B0B1, $B1B2B2B2
	dc.l	$55555656, $56575757, $58585859, $59595A5A, $5A5B5B5B, $5C5C5C5D, $5D5D5E5E, $5E5F5F5F
	dc.l	$60606061, $61616262, $62636363, $64646465, $65656666, $66676767, $68686869, $69696A6A
	dc.l	$6A6B6B6B, $6C6C6C6D, $6D6D6E6E, $6E6F6F6F, $70707071, $71717272, $72737373, $74747475
	dc.l	$75757676, $76777777, $78787879, $79797A7A, $7A7B7B7B, $7C7C7C7D, $7D7D7E7E, $7E7F7F7F
	dc.l	$80808081, $81818282, $82838383, $84848485, $85858686, $86878787, $88888889, $89898A8A
	dc.l	$8A8B8B8B, $8C8C8C8D, $8D8D8E8E, $8E8F8F8F, $90909091, $91919292, $92939393, $94949495
	dc.l	$95959696, $96979797, $98989899, $99999A9A, $9A9B9B9B, $9C9C9C9D, $9D9D9E9E, $9E9F9F9F
	dc.l	$A0A0A0A1, $A1A1A2A2, $A2A3A3A3, $A4A4A4A5, $A5A5A6A6, $A6A7A7A7, $A8A8A8A9, $A9A9AAAA
	dc.l	$5D5E5E5E, $5E5F5F5F, $60606060, $61616161, $62626262, $63636364, $64646465, $65656566
	dc.l	$66666667, $67676868, $68686969, $69696A6A, $6A6A6B6B, $6B6C6C6C, $6C6D6D6D, $6D6E6E6E
	dc.l	$6E6F6F6F, $70707070, $71717171, $72727272, $73737374, $74747475, $75757576, $76767677
	dc.l	$77777878, $78787979, $79797A7A, $7A7A7B7B, $7B7C7C7C, $7C7D7D7D, $7D7E7E7E, $7E7F7F7F
	dc.l	$80808080, $81818181, $82828282, $83838384, $84848485, $85858586, $86868687, $87878888
	dc.l	$88888989, $89898A8A, $8A8A8B8B, $8B8C8C8C, $8C8D8D8D, $8D8E8E8E, $8E8F8F8F, $90909090
	dc.l	$91919191, $92929292, $93939394, $94949495, $95959596, $96969697, $97979898, $98989999
	dc.l	$99999A9A, $9A9A9B9B, $9B9C9C9C, $9C9D9D9D, $9D9E9E9E, $9E9F9F9F, $A0A0A0A0, $A1A1A1A1
	dc.l	$66666667, $67676767, $68686868, $68696969, $69696A6A, $6A6A6A6B, $6B6B6B6B, $6C6C6C6C
	dc.l	$6C6D6D6D, $6D6D6E6E, $6E6E6E6F, $6F6F6F6F, $70707070, $70717171, $71717272, $72727273
	dc.l	$73737373, $74747474, $74757575, $75757676, $76767677, $77777777, $78787878, $78797979
	dc.l	$79797A7A, $7A7A7A7B, $7B7B7B7B, $7C7C7C7C, $7C7D7D7D, $7D7D7E7E, $7E7E7E7F, $7F7F7F7F
	dc.l	$80808080, $80818181, $81818282, $82828283, $83838383, $84848484, $84858585, $85858686
	dc.l	$86868687, $87878787, $88888888, $88898989, $89898A8A, $8A8A8A8B, $8B8B8B8B, $8C8C8C8C
	dc.l	$8C8D8D8D, $8D8D8E8E, $8E8E8E8F, $8F8F8F8F, $90909090, $90919191, $91919292, $92929293
	dc.l	$93939393, $94949494, $94959595, $95959696, $96969697, $97979797, $98989898, $98999999
	dc.l	$6E6F6F6F, $6F6F6F6F, $70707070, $70707070, $71717171, $71717172, $72727272, $72727273
	dc.l	$73737373, $73737474, $74747474, $74747575, $75757575, $75767676, $76767676, $76777777
	dc.l	$77777777, $78787878, $78787878, $79797979, $7979797A, $7A7A7A7A, $7A7A7A7B, $7B7B7B7B
	dc.l	$7B7B7C7C, $7C7C7C7C, $7C7C7D7D, $7D7D7D7D, $7D7E7E7E, $7E7E7E7E, $7E7F7F7F, $7F7F7F7F
	dc.l	$80808080, $80808080, $81818181, $81818182, $82828282, $82828283, $83838383, $83838484
	dc.l	$84848484, $84848585, $85858585, $85868686, $86868686, $86878787, $87878787, $88888888
	dc.l	$88888888, $89898989, $8989898A, $8A8A8A8A, $8A8A8A8B, $8B8B8B8B, $8B8B8C8C, $8C8C8C8C
	dc.l	$8C8C8D8D, $8D8D8D8D, $8D8E8E8E, $8E8E8E8E, $8E8F8F8F, $8F8F8F8F, $90909090, $90909090
	dc.l	$77777777, $77777777, $78787878, $78787878, $78787878, $78787879, $79797979, $79797979
	dc.l	$79797979, $79797A7A, $7A7A7A7A, $7A7A7A7A, $7A7A7A7A, $7A7B7B7B, $7B7B7B7B, $7B7B7B7B
	dc.l	$7B7B7B7B, $7C7C7C7C, $7C7C7C7C, $7C7C7C7C, $7C7C7C7D, $7D7D7D7D, $7D7D7D7D, $7D7D7D7D
	dc.l	$7D7D7E7E, $7E7E7E7E, $7E7E7E7E, $7E7E7E7E, $7E7F7F7F, $7F7F7F7F, $7F7F7F7F, $7F7F7F7F
	dc.l	$80808080, $80808080, $80808080, $80808081, $81818181, $81818181, $81818181, $81818282
	dc.l	$82828282, $82828282, $82828282, $82838383, $83838383, $83838383, $83838383, $84848484
	dc.l	$84848484, $84848484, $84848485, $85858585, $85858585, $85858585, $85858686, $86868686
	dc.l	$86868686, $86868686, $86878787, $87878787, $87878787, $87878787, $88888888, $88888888
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080, $80808080
	dc.l	$00000000, $00000000, $00000000, $00000000, $01010101, $01010101, $01010101, $01010101
	dc.l	$02020202, $02020202, $02020202, $02020202, $04040404, $04040404, $04040404, $04040404
	dc.l	$08080808, $08080808, $08080808, $08080808, $10101010, $10101010, $10101010, $10101010
	dc.l	$20202020, $20202020, $20202020, $20202020, $40404040, $40404040, $40404040, $40404040
	dc.l	$80808080, $80808080, $80808080, $80808080, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF
	dc.l	$FEFEFEFE, $FEFEFEFE, $FEFEFEFE, $FEFEFEFE, $FCFCFCFC, $FCFCFCFC, $FCFCFCFC, $FCFCFCFC
	dc.l	$F8F8F8F8, $F8F8F8F8, $F8F8F8F8, $F8F8F8F8, $F0F0F0F0, $F0F0F0F0, $F0F0F0F0, $F0F0F0F0
	dc.l	$E0E0E0E0, $E0E0E0E0, $E0E0E0E0, $E0E0E0E0, $C0C0C0C0, $C0C0C0C0, $C0C0C0C0, $C0C0C0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00010204, $08102040, $80FFFEFC, $F8F0E0C0, $00010204, $08102040, $80FFFEFC, $F8F0E0C0
	dc.l	$00000000, $000000D1, $C9D511A0, $00B7ED52, $112000ED, $52280FD2, $13167DED, $440F0FE6
	dc.l	$07210016, $6FE9D1D5, $132918D4, $F33E2032, $DD1F2140, $17223900, $ED73DE1F, $DDF933F1
	dc.l	$C1E1D131, $DD1FF508, $CBFCE5CB, $BA1B7AA3, $3C200305, $167F141C, $D5151D78, $B9200BDA
	dc.l	$6919CBBC, $EBED52C3, $7216AF95, $5F9C8557, $EB2B242C, $E5C521C4, $1F083001, $2CE5ED7B
	dc.l	$DE1F3AD3, $1FCFF301, $00032614, $ED5BD91F, $DD2AD51F, $D908AF08, $ED4BD11F, $0AE60FC6
	dc.l	$04473ADC, $1FFD6F21, $00031101, $40D9FB0D, $3E800200, $1A136F0A, $0C8624F3, $020C8625
	dc.l	$02DD2D28, $1DD94E0A, $1208FD85, $30012C08, $7DD9FB91, $90D2B416, $F5F1F5F1, $E509E1F3
	dc.l	$18E3DD25, $C2C516FB, $3A090021, $D41FBE20, $28F379D9, $BD28174E, $0A1208FD, $8530012C
	dc.l	$08D9FBF5, $F1F5F1E5, $232323E1, $18E3D9FB, $3ADB1FE6, $02C28216, $C93C1100, $80DD2100
	dc.l	$80BE2004, $DD2AD71F, $2614D7C3, $B41621D6, $1636B323, $3616C9D9, $00030B03, $0B001814
	dc.l	$F5C50672, $79D9BD28, $EE4E0A12, $08FD8530, $012C08D9, $3EFF32E2, $1FC5C1E5, $2929E100
	dc.l	$10E279D9, $BD280A4E, $0A1208FD, $8530012C, $08D9D9ED, $4BD11F0A, $E60FC604, $47D93ADC
	dc.l	$1FFD6F3A, $C21FB728, $0DF2AE17, $3ADB1F0F, $3028AF32, $C21F79D9, $BD280A4E, $0A1208FD
	dc.l	$8530012C, $08D9AF32, $E21FC1F1, $FBC93DCA, $69193D20, $0BFD2E00, $18DC3AC2, $1FC3F118
	dc.l	$3E8032E8, $1F18CBF3, $3E8032DD, $1F21DC17, $223900D9, $0E00D9FB, $000018FC, $D921834D
	dc.l	$CD091621, $F517790C, $D1E60387, $16005F19, $5E2356EB, $E9FB170B, $181B18D9, $010000ED
	dc.l	$43E41F11, $0080214B, $18FBE9D9, $ED43E41F, $01000011, $0000214B, $18FBE9D9, $ED43E61F
	dc.l	$6069ED5B, $E41FAFED, $52FA3C18, $7BCB2A1F, $CB2A1FCB, $2A1F5FAF, $ED52300E, $CD3101CD
	dc.l	$9102CD2E, $173E0132, $E31FC91A, $031A031A, $031A031A, $031A031A, $031A03E9, $F33E0232
	dc.l	$DD1FE52A, $390022E0, $1F217518, $223900E1, $FB000018, $FCE52172, $4DCD0916, $E13AC21F
	dc.l	$B72823F2, $98183ADB, $1F0F3006, $AF32C21F, $FBC93AC2, $1FC3F118, $3DCA6919, $3D28F13E
	dc.l	$8032E81F, $18E6E52A, $E01F2239, $00E13333, $C9F33E01, $32DD1F21, $C2182239, $00FB0000
	dc.l	$18FC2187, $4DCD0916, $3AC21FB7, $FAF118FB, $C931EA1F, $21000006, $15E510FD, $31C01FCD
	dc.l	$C71721C6, $1F3EC077, $2C773E52, $32C31F18, $C031C01F, $21C21F36, $00CDFF18, $C3B118D6
	dc.l	$8028134F, $06008760, $6F292909, $DD216D19, $EBDD19C3, $1A19DD21, $C81F21C6, $1FDDCB01
	dc.l	$4628012C, $4E21C31F, $11004043, $3E5270EB, $362B2C36, $802C36B6, $2C716836, $2A12CD52
	dc.l	$1921C31F, $1100403E, $5273EB36, $2B2C3600, $12C9DD7E, $00FE50CA, $4300FE54, $CAD201FE
	dc.l	$44CA2C16, $3E0132E8, $1FAF32C2, $1F31C01F, $CD4119C3
	dc.w	$B118

; ------------------------------------------------------------------------------
; Exported symbols
; ------------------------------------------------------------------------------

MegaPCM_LoadDriver:	equ	MegaPCMLibraryBlob+$0
MegaPCM_LoadSampleTable:	equ	MegaPCMLibraryBlob+$6A
MegaPCM_PlaySample:	equ	MegaPCMLibraryBlob+$24A
MegaPCM_PausePlayback:	equ	MegaPCMLibraryBlob+$26C
MegaPCM_UnpausePlayback:	equ	MegaPCMLibraryBlob+$290
MegaPCM_StopPlayback:	equ	MegaPCMLibraryBlob+$2B4
MegaPCM_SetVolume:	equ	MegaPCMLibraryBlob+$2D8
MegaPCM_SetSFXVolume:	equ	MegaPCMLibraryBlob+$2FA
MegaPCM_SetPan:	equ	MegaPCMLibraryBlob+$31C
MegaPCM_SetSFXPan:	equ	MegaPCMLibraryBlob+$33E
MegaPCM:	equ	MegaPCMLibraryBlob+$360
MegaPCM_End:	equ	MegaPCMLibraryBlob+$1CD6

	if def(__DEBUG__)
; ------------------------------------------------------------------------------
; Additional debuggers
; ------------------------------------------------------------------------------


	pusho
	opt		l-

; ------------------------------------------------------------------------------
; DEBUGGER: Displays details for `MegaPCM_LoadSampleTable` error code
; ------------------------------------------------------------------------------
; INPUT:
;		d0	.w	Error code returned by `MegaPCM_LoadSampleTable`
;		a0		Pointer to faulty sample
; ------------------------------------------------------------------------------

MPCM_Debugger_LoadSampleTableException:

	; Print raw error code
	Console.Write "%<pal1>Error code: %<pal0>%<.b d0>%<endl>"

	; Print error description
	lea		@ErrorCodeToDescription-4(pc), a1
	lea		@Str_UnknownError(pc), a2			; fallback in case error description isn't found

	@findErrorDescriptionLoop:
		addq.w	#4, a1							; skip string pointer
		cmp.b	(a1), d0
		bhi.s	@findErrorDescriptionLoop
		blo.s	@errorDescriptionLoopDone		; search failure
		move.l	(a1), a2						; a2 = error description string
	@errorDescriptionLoopDone:

	Console.Write "%<pal1>Error description:%<endl>%<pal0>%<.l a2 str>%<endl>%<endl>"

	; Print sample data
	Console.WriteLine "%<pal1>RAW SAMPLE RECORD:"
	Console.WriteLine "%<pal2>Type: %<pal0>%<.b (a0)>"
	Console.WriteLine "%<pal2>Flags: %<pal0>%<.b 1(a0)>"
	Console.WriteLine "%<pal2>Pitch: %<pal0>%<.b 2(a0)>"
	Console.WriteLine "%<pal2>Start: %<pal0>%<.l 4(a0) sym>"
	Console.WriteLine "%<pal2>End: %<pal0>%<.l 8(a0) sym>"

	rts

; ------------------------------------------------------------------------------
@ErrorCodeToDescription:
	;		Raw error code							  String pointer
	dc.l	(MPCM_ST_TOO_MANY_SAMPLES<<24) 			| @Str_TooManySamples
	dc.l	(MPCM_ST_UNKNOWN_SAMPLE_TYPE<<24)		| @Str_UnknownSampleType
	dc.l	(MPCM_ST_PITCH_NOT_SET<<24)				| @Str_PitchNotSet
	dc.l	(MPCM_ST_WAVE_INVALID_HEADER<<24)		| @Str_WaveInvalidHeader
	dc.l	(MPCM_ST_WAVE_BAD_AUDIO_FORMAT<<24)		| @Str_WaveBadAudioFormat
	dc.l	(MPCM_ST_WAVE_NOT_MONO<<24)				| @Str_WaveNotMono
	dc.l	(MPCM_ST_WAVE_NOT_8BIT<<24)				| @Str_WaveNot8bit
	dc.l	(MPCM_ST_WAVE_BAD_SAMPLE_RATE<<24)		| @Str_BadSampleRate
	dc.l	(MPCM_ST_WAVE_MISSING_DATA_CHUNK<<24)	| @Str_MissingDataChunk
	dc.b	$FF, 0		; end marker

; ------------------------------------------------------------------------------
@Str_TooManySamples:
	dc.b	"Too many samples in table", 0
@Str_UnknownSampleType:
	dc.b	"Unknown sample type or missing end marker. Please use one of: TYPE_PCM, TYPE_DPCM, TYPE_PCM_TURBO, TYPE_NONE", 0
@Str_PitchNotSet:
	dc.b	"Sample rate can't be auto-detected (only works for .WAV files). Please set it manually", 0
@Str_WaveInvalidHeader:
	dc.b	"WAVE error: Invalid WAVE header", 0
@Str_WaveBadAudioFormat:
	dc.b	"WAVE error: Unsupported audio format. Only PCM is supported", 0
@Str_WaveNotMono:
	dc.b	"WAVE error: Audio must be mono", 0
@Str_WaveNot8bit:
	dc.b	"WAVE error: Audio must be 8-bit PCM", 0
@Str_BadSampleRate:
	dc.b	"WAVE error: Unsupported sample rate. Use <=\#TYPE_PCM_MAX_RATE\ Hz for TYPE_PCM or \#TYPE_PCM_TURBO_MAX_RATE\ Hz for TYPE_PCM_TURBO.", 0
@Str_MissingDataChunk:
	dc.b	"WAVE error: Failed to locate 'data' chunk", 0
@Str_UnknownError:
	dc.b	"Uknown error code", 0
	even
	popo

	endif

; ------------------------------------------------------------------------------
; MIT License
;
; Copyright (c) 2012-2024 Vladikcomper
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; ------------------------------------------------------------------------------
