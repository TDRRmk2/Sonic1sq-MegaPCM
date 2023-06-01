; ---------------------------------------------------------------------------
; MZ3 object placement
; ---------------------------------------------------------------------------
ObjPos_MZ3:
		objpos $0010,$0410,MarbleBrick,type_brick_still
		objpos $0010,$0430,MarbleBrick,type_brick_still
		objpos $0010,$0450,MarbleBrick,type_brick_still
		objpos $0010,$04D0,MarbleBrick,type_brick_still
		objpos $0010,$04F0,MarbleBrick,type_brick_still
		objpos $0020,$03B0,FireMaker,type_fire_rate120+type_fire_horizontal+2,xflip
		objpos $0030,$0470,SmashBlock,$00
		objpos $0030,$0490,SmashBlock,$00
		objpos $0030,$04B0,SmashBlock,$00
		objpos $0050,$0470,SmashBlock,$00
		objpos $0050,$0490,SmashBlock,$00
		objpos $0050,$04B0,SmashBlock,$00
		objpos $0080,$0370,FireMaker,type_fire_rate120+type_fire_horizontal+2,xflip
		objpos $00A0,$05F4,Spikes,type_spike_3up+type_spike_updown
		objpos $00D0,$0320,FireMaker,type_fire_rate90+2,yflip
		objpos $0110,$04F0,Monitor,type_monitor_shield,rem
		objpos $0110,$06D0,Monitor,type_monitor_rings,rem
		objpos $0120,$01CC,LargeGrass,type_grass_narrow+type_grass_1
		objpos $0150,$0610,SmashBlock,$00
		objpos $0150,$0630,SmashBlock,$00
		objpos $0150,$0650,SmashBlock,$00
		objpos $0154,$0130,Rings,$11,rem
		objpos $0160,$0310,Invisibarrier,$31
		objpos $0160,$03A7,GlassBlock,type_glass_updown
		objpos $0160,$0499,GlassBlock,type_glass_updown
		objpos $0190,$0548,Button,1+type_button_pal3
		objpos $0190,$0560,MarbleBrick,type_brick_still
		objpos $01A0,$01CC,LargeGrass,type_grass_narrow+type_grass_1+type_grass_rev
		objpos $01A0,$05D7,GlassBlock,type_glass_drop_button+type_glass_button_1
		objpos $01E0,$0499,GlassBlock,type_glass_updown_rev
		objpos $0220,$03A8,CollapseFloor,$01
		objpos $0240,$0420,LavaTag,$01
		objpos $0240,$04E8,CollapseFloor,$01
		objpos $0240,$06D0,Splats,$00,xflip,rem
		objpos $0260,$03A8,CollapseFloor,$01
		objpos $0280,$04E8,CollapseFloor,$01
		objpos $0290,$031C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $02D0,$031C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $02D0,$046C,Batbrain,$00,rem
		objpos $02D0,$04F0,MarbleBrick,type_brick_still
		objpos $02F0,$0150,BuzzBomber,$00,rem
		objpos $02F0,$0690,PushBlock,type_pblock_single,rem
		objpos $0310,$054C,Splats,$00,rem
		objpos $0320,$048C,Batbrain,$00,rem
		objpos $0338,$06A8,Rings,$13,rem
		objpos $0380,$06E8,LavaTag,$02
		objpos $03B0,$06A0,MarbleBrick,type_brick_still
		objpos $03E0,$01A8,Splats,$00,rem
		objpos $03F0,$06A8,Rings,$14,rem
		objpos $0420,$04A8,CollapseFloor,$01
		objpos $0430,$0150,BuzzBomber,$00,rem
		objpos $0430,$029C,ChainStomp,type_cstomp_wide+type_cstomp_2
		objpos $0470,$041C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $0480,$04E8,LavaTag,$02
		objpos $0480,$06E8,LavaTag,$02
		objpos $0490,$0680,MarbleBrick,type_brick_still
		objpos $0490,$06A0,MarbleBrick,type_brick_still
		objpos $04B0,$0410,MarbleBrick,type_brick_falls
		objpos $04C0,$0160,BuzzBomber,$00,rem
		objpos $04C8,$06A8,Rings,$14,rem
		objpos $04F0,$041C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $04F0,$05A0,Invisibarrier,$00
		objpos $0510,$05B8,MovingBlock,type_mblock_1+type_mblock_leftright
		objpos $0510,$0610,MarbleBrick,type_brick_still
		objpos $0530,$01B8,Rings,$10,rem
		objpos $0530,$0410,MarbleBrick,type_brick_falls
		objpos $0530,$0610,MarbleBrick,type_brick_still
		objpos $0540,$02C8,Splats,$00,rem
		objpos $0554,$01CE,Rings,$10,rem
		objpos $0570,$01EC,Rings,$10,rem
		objpos $0570,$041C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $0580,$04E8,LavaTag,$02
		objpos $0580,$06E8,LavaTag,$02
		objpos $058C,$0208,Rings,$10,rem
		objpos $0590,$0580,MarbleBrick,type_brick_still
		objpos $05AB,$0225,Rings,$10,rem
		objpos $05B0,$0580,MarbleBrick,type_brick_still
		objpos $05C0,$0410,MarbleBrick,type_brick_falls
		objpos $05CA,$0243,Rings,$10,rem
		objpos $05F4,$0253,Rings,$10,rem
		objpos $0618,$0454,Rings,$12,rem
		objpos $0620,$02E8,LargeGrass,type_grass_narrow+type_grass_3
		objpos $0620,$03B0,FireMaker,type_fire_rate150+type_fire_horizontal+2,xflip
		objpos $0640,$06E8,LavaTag,$01
		objpos $0670,$0414,Rings,$10,rem
		objpos $0680,$0370,FireMaker,type_fire_rate150+type_fire_horizontal+2,xflip
		objpos $0690,$03D4,Rings,$10,rem
		objpos $0698,$06C0,Spikes,type_spike_3left+type_spike_still
		objpos $06A0,$02CC,LargeGrass,type_grass_narrow+type_grass_1
		objpos $06B0,$03B4,Rings,$10,rem
		objpos $06C0,$05A8,Splats,$00,rem
		objpos $06D0,$0320,FireMaker,type_fire_rate150+2,yflip
		objpos $06D4,$0394,Rings,$11,rem
		objpos $0710,$0360,MarbleBrick,type_brick_still
		objpos $0720,$05F4,Spikes,type_spike_3up+type_spike_updown
		objpos $0750,$0550,MarbleBrick,type_brick_still
		objpos $0754,$05D4,Rings,$11,rem
		objpos $0770,$0550,MarbleBrick,type_brick_still
		objpos $07A0,$05F4,Spikes,type_spike_3up+type_spike_updown
		objpos $07D0,$0550,MarbleBrick,type_brick_still
		objpos $07E8,$05D4,Rings,$12,rem
		objpos $07F0,$02B0,Monitor,type_monitor_rings,rem
		objpos $07F0,$0550,MarbleBrick,type_brick_still
		objpos $0820,$06B0,FireMaker,type_fire_rate120+type_fire_horizontal+2,xflip
		objpos $0848,$0750,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $0850,$05E0,MarbleBrick,type_brick_still
		objpos $0880,$0670,FireMaker,type_fire_rate120+type_fire_horizontal+2,xflip
		objpos $0888,$0790,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $08A0,$05D4,Spikes,type_spike_3up+type_spike_updown
		objpos $08D0,$0620,FireMaker,type_fire_rate120+2,yflip
		objpos $0930,$053C,ChainStomp,type_cstomp_medium+type_cstomp_1
		objpos $0940,$07C0,Splats,$00,xflip,rem
		objpos $09B8,$07D0,Springs,type_spring_red+type_spring_right,xflip
		objpos $09D0,$053C,ChainStomp,type_cstomp_medium+type_cstomp_1
		objpos $0AC0,$07E8,LavaTag,$01
		objpos $0B20,$0768,SwingingPlatform,$04
		objpos $0B80,$07D0,FireMaker,type_fire_rate180+type_fire_vertical+type_fire_gravity+4
		objpos $0B80,$07E8,LavaTag,$02
		objpos $0B90,$05B0,Monitor,type_monitor_1up,rem
		objpos $0BE0,$0768,SwingingPlatform,$04,xflip
		objpos $0C40,$07D0,FireMaker,type_fire_rate180+type_fire_vertical+type_fire_gravity+4
		objpos $0C80,$07E8,LavaTag,$02
		objpos $0CA0,$0768,SwingingPlatform,$04
		objpos $0D10,$06F1,Monitor,type_monitor_shield,rem
		objpos $0DA0,$06EC,Lamppost,$01,rem
		objpos $0DEC,$0710,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $0E00,$0748,Splats,$10,rem
		objpos $0E28,$03B0,FireMaker,type_fire_rate150+type_fire_horizontal+2,xflip
		objpos $0E30,$0431,Monitor,type_monitor_rings
		objpos $0E48,$0450,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $0E88,$0370,FireMaker,type_fire_rate150+type_fire_horizontal+2,xflip
		objpos $0E88,$0490,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $0EC8,$04D0,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $0ED0,$0328,FireMaker,type_fire_rate150+2,yflip
		objpos $0EE0,$06F4,Spikes,type_spike_3up+type_spike_updown
		objpos $0F30,$049C,ChainStomp,type_cstomp_medium+type_cstomp_1
		objpos $0F60,$0698,GlassBlock,type_glass_updown
		objpos $0F90,$048C,Batbrain,$00,rem
		objpos $0F94,$06F2,Rings,$11,rem
		objpos $0FA0,$0354,Spikes,type_spike_3up+type_spike_updown
		objpos $0FD0,$0650,MarbleBrick,type_brick_still
		objpos $0FD4,$06A0,Rings,$11,rem
		objpos $0FE0,$048C,Batbrain,$00,rem
		objpos $0FE0,$06D4,Spikes,type_spike_3up+type_spike_updown
		objpos $0FE8,$0578,Spikes,type_spike_3left+type_spike_still,xflip
		objpos $0FF0,$0650,MarbleBrick,type_brick_still
		objpos $1008,$0514,Rings,$12,rem
		objpos $1014,$06F2,Rings,$11,rem
		objpos $1030,$0540,Invisibarrier,$11
		objpos $1040,$033C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $1060,$069A,GlassBlock,type_glass_updown_rev
		objpos $1080,$0598,LavaTag,$02
		objpos $1094,$06F2,Rings,$11,rem
		objpos $1098,$030C,Batbrain,$00,rem
		objpos $1098,$040C,Batbrain,$00,rem
		objpos $10C0,$0394,Spikes,type_spike_3up+type_spike_updown
		objpos $10C0,$040C,Batbrain,$00,rem
		objpos $10D0,$0650,MarbleBrick,type_brick_still
		objpos $10D4,$06A0,Rings,$11,rem
		objpos $10E0,$030C,Batbrain,$00,rem
		objpos $10E0,$06D4,Spikes,type_spike_3up+type_spike_updown
		objpos $10E8,$040C,Batbrain,$00,rem
		objpos $10F0,$0650,MarbleBrick,type_brick_still
		objpos $1108,$0514,Rings,$12,rem
		objpos $1110,$06F0,SmashBlock,$00
		objpos $1110,$0710,SmashBlock,$00
		objpos $1130,$0540,Invisibarrier,$11
		objpos $1130,$06F0,SmashBlock,$00
		objpos $1130,$0710,SmashBlock,$00
		objpos $1140,$033C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $1160,$0710,Invisibarrier,$31
		objpos $1160,$07A7,GlassBlock,type_glass_updown
		objpos $1180,$0598,LavaTag,$02
		objpos $1198,$040C,Batbrain,$00,rem
		objpos $11A0,$030C,Batbrain,$00,rem
		objpos $11C0,$0394,Spikes,type_spike_3up+type_spike_updown
		objpos $11C0,$040C,Batbrain,$00,rem
		objpos $11E8,$040C,Batbrain,$00,rem
		objpos $11F0,$030C,Batbrain,$00,rem
		objpos $1200,$0598,LavaTag,$00
		objpos $1208,$0514,Rings,$12,rem
		objpos $1210,$07B8,MovingBlock,type_mblock_1+type_mblock_right
		objpos $1230,$0540,Invisibarrier,$11
		objpos $1230,$0790,MarbleBrick,type_brick_still
		objpos $1250,$031C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $1280,$0598,LavaTag,$02
		objpos $1280,$0620,LavaTag,$02
		objpos $1280,$07D0,LavaFall,$01
		objpos $1280,$07E8,LavaTag,$02
		objpos $12B0,$031C,ChainStomp,type_cstomp_small+type_cstomp_proximity+type_cstomp_3
		objpos $12D0,$0768,MovingBlock,type_mblock_1+type_mblock_right
		objpos $12F0,$06F0,Monitor,type_monitor_shield,rem
		objpos $1310,$02F0,MarbleBrick,type_brick_still
		objpos $1310,$0550,PushBlock,type_pblock_single,rem
		objpos $1310,$0710,MarbleBrick,type_brick_still
		objpos $1330,$0790,MarbleBrick,type_brick_still
		objpos $1354,$0340,Spikes,type_spike_3left+type_spike_leftright
		objpos $1380,$07E8,LavaTag,$02
		objpos $13A0,$04EC,Splats,$00,xflip,rem
		objpos $13E8,$02A8,Rings,$12,rem
		objpos $1418,$07C0,Spikes,type_spike_3left+type_spike_still
		objpos $1438,$063C,Batbrain,$00,rem
		objpos $1448,$0550,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $1450,$048C,Batbrain,$00,rem
		objpos $1450,$0710,Rings,$14,rem
		objpos $1458,$063C,Batbrain,$00,rem
		objpos $1468,$0670,Rings,$12,rem
		objpos $1478,$063C,Batbrain,$00,rem
		objpos $1488,$0590,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $1498,$063C,Batbrain,$00,rem
		objpos $14A0,$048C,Batbrain,$00,rem
		objpos $14A8,$02D8,FireMaker,type_fire_rate150+type_fire_vertical+type_fire_gravity+4
		objpos $14B8,$04F4,Rings,$12,rem
		objpos $14B8,$063C,Batbrain,$00,rem
		objpos $14C0,$02FC,LavaTag,$01
		objpos $14C8,$05D0,Spikes,type_spike_1left+type_spike_leftright,xflip
		objpos $14D8,$02D8,FireMaker,type_fire_rate180+type_fire_vertical+type_fire_gravity+5
		objpos $1518,$0752,Rings,$12,rem
		objpos $1530,$063C,ChainStomp,type_cstomp_medium+type_cstomp_1
		objpos $1550,$02A0,FireMaker,type_fire_rate150+type_fire_vertical+type_fire_gravity+5
		objpos $1580,$02A8,LargeGrass,type_grass_narrow+type_grass_2+type_grass_rev
		objpos $1580,$02B8,LavaTag,$01
		objpos $1590,$0590,MarbleBrick,type_brick_still
		objpos $15B0,$02A0,FireMaker,type_fire_rate150+type_fire_vertical+type_fire_gravity+5
		objpos $15B0,$0590,MarbleBrick,type_brick_still
		objpos $15B0,$05BC,ChainStomp,type_cstomp_medium+type_cstomp_1
		objpos $15D0,$0590,MarbleBrick,type_brick_still
		objpos $1640,$0268,Lamppost,$02,rem
		
		objpos $17C0,$02F8,LavaTag,$01
		objpos $18A0,$02F8,LavaTag,$01
		objpos $1A00,$027C,Prison,$01
		objpos $1A00,$02A1,Prison,$00
		endobj
