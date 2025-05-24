	opt	c-
	
	SECTION	"Amiga Down Under Intro",CODE_C

;--------------------------------------;

WaitBlt	MACRO
	tst.b	2(a5)
WB\@	btst	#6,2(a5)
	bne.b	WB\@
	ENDM

;--------------------------------------;

	lea	$dff000,a5
	WaitBlt

	move.l	4.w,a6
	jsr	-132(a6)
	moveq	#0,d0
	lea	GfxBase(pc),a1
	jsr	-552(a6)
	move.l	d0,GfxBase
	move.l	d0,a6
	move.l	34(a6),OldView
	sub.l	a1,a1
	jsr	-222(a6)
	jsr	-270(a6)
	jsr	-270(a6)

	move.w	$1c(a5),d0
	or.w	#$c000,d0
	move.w	d0,IntEna

	move.w	2(a5),d0
	or.w	#$8000,d0
	move.w	d0,DMACon

	bsr.w	MT_Init
	move.l	#Picture,d0
	lea	BPL1(pc),a0
	moveq	#2,d7
Pic2Cop	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#87*(320/8),d0
	addq.l	#8,a0
	dbf	d7,Pic2Cop

	move.l	#MskArea,d0
	lea	BPL2(pc),a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

	move.l	#Sprite,d0
	lea	SPR1(pc),a0
	moveq	#1,d7
SPR2Cop	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	addq.l	#8,a0
	add.l	#44,d0
	dbf	d7,SPR2Cop

	move.l	#SPRBlnk,d0
	lea	SPR3(pc),a0
	moveq	#4,d7
Blk2Cop	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	addq.l	#8,a0
	dbf	d7,Blk2Cop

	bsr.w	GetVBR
	lea	$dff000,a5
	move.w	#$7fff,$9a(a5)
	move.w	#$7fff,$9c(a5)
	move.l	$6c(a4),OldIRQ
	move.l	#NewIRQ,$6c(a4)
	move.w	#$c020,$9a(a5)

	move.w	#$7fff,$96(a5)
	move.l  #CList,$80(a5)
	move.w	#$0000,$88(a5)
	move.w	#$83e0,$96(a5)
	move.l	#0,$144(a5)

MousChk	btst	#6,$bfe001
	bne.b	MousChk

	lea	$dff000,a5
	WaitBlt

	move.w	#$7fff,$9a(a5)
	move.w	#$7fff,$9c(a5)
	move.l	OldIRQ(pc),$6c(a4)
	move.w	IntEna(pc),$9a(a5)

	bsr.w	MT_End
	move.l	GfxBase(pc),a6
	move.l	OldView(pc),a1
	jsr	-222(a6)
	move.w	#$7fff,$96(a5)
	move.l	38(a6),$80(a5)
	move.w	#$0000,$88(a5)
	move.w	DMACon(pc),$96(a5)

	move.l	4.w,a6
	jsr	-138(a6)
End	moveq	#0,d0
	rts

GetVBR	sub.l	a4,a4
	move.l	4.w,a6
	btst	#0,297(a6)
	beq.b	NoProcc
	lea	VBRExcp(pc),a5
	jsr	-30(a6)
NoProcc	rts

VBRExcp	dc.w	$4e7a,$c801
	rte

;--------------------------------------;

NewIRQ	movem.l	d0-a6,-(a7)
	bsr.b	ComChck
	bsr	Stars
	bsr.w	MT_Music
	movem.l	(a7)+,d0-a6
;	move.w	#$00f0,$dff180
	move.w	#$0020,$dff09c
	rte

;--------------------------------------;

ComChck	move.l	ComdPnt(pc),a0
	move.l	(a0),a0
	jmp	(a0)

;--------------------------------------;

SptLght	subq.w	#1,SptSwch
	bne.b	SpotClr
	addq.l	#4,ComdPnt
SpotClr	WaitBlt
	move.l	#$01000000,$40(a5)
	move.w	#$0000,$66(a5)
	move.l	#MskArea,$54(a5)
	move.w	#82<<6+20,$58(a5)

	moveq	#0,d0
	move.l	d0,d1
	move.l	d0,d2
	move.l	SnePntX(pc),a0
	move.l	SnePntY(pc),a1
	lea	OutSide(pc),a2
	move.b	(a0),d0
	move.b	(a1),d1

	addq.b	#1,d0
	move.w	d0,d2
	and.w	#$f,d0
	ror.w	#4,d0
	or.w	#$09f0,d0
	WaitBlt
	move.w	d0,$40(a5)
	lsr.w	#3,d2
	lea	(a2,d2),a2

	move.w	d1,d2
	lsl.w	#3,d1
	lsl.w	#5,d2
	add.w	d2,d1
	lea	(a2,d1),a2

	move.l	#$ffff0000,$44(a5)	;Mask
	move.l	#30,$64(a5)		;Modulo A
	move.l	#Circle,$50(a5)		;Blitter A
	move.l	a2,$54(a5)		;Blitter D
	move.w	#64<<6+5,$58(a5)	;Blitter Size

	addq.l	#1,SnePntX
	cmp.l	#SneHorzEnd,SnePntX
	blt.b	NoSineX
	sub.l	#100,SnePntX
NoSineX	addq.l	#1,SnePntY
	cmp.l	#SneVertEnd,SnePntY
	blt.b	NoSineY
	sub.l	#100,SnePntY
NoSineY	rts

;--------------------------------------;

InitFde	addq.l	#4,ComdPnt
	move.w	#15,SptSwch

FadeLgo	moveq	#0,d0
	move.l	d0,d1
	move.b	ColSwch(pc),d0
	lea	ColOffs(pc),a0
	lea	Colours+2(pc),a1
	move.l	#7,d3
WRed	move.w	(a0)+,d1
	move.l	d1,d2
	and.w	#$0f00,d2
	lsr.w	#8,d2
	cmp.b	d0,d2
	blt.b	WGreen
	add.w	#$0100,(a1)
WGreen	move.l	d1,d2
	and.w	#$00f0,d2
	lsr.w	#4,d2
	cmp.b	d0,d2
	blt.b	WBlue
	add.w	#$0010,(a1)
WBlue	and.w	#$000f,d1
	cmp.b	d0,d1
	blt.b	WLoop
	add.w	#$0001,(a1)
WLoop	add.w	#4,a1
	dbf	d3,WRed
	sub.b	#1,ColSwch

	cmp.w	#4,MskCols+2
	beq.w	SptLght
	subq.w	#1,MskCols+2
	bra.w	SptLght

;--------------------------------------;

MveCols	addq.l	#4,ComdPnt
	WaitBlt
	move.l	#$01000000,$40(a5)
	move.w	#$0000,$66(a5)
	move.l	#MskArea,$54(a5)
	move.w	#82<<6+20,$58(a5)

	lea	ColChrt(pc),a0
	lea	MskCols+2(pc),a1
	moveq	#7,d0
MvColLp	move.w	(a0)+,(a1)
	addq.l	#4,a1
	dbf	d0,MvColLp
	rts

;--------------------------------------;

SinWait	subq.w	#1,SinSwch
	bne	End
	addq.l	#4,ComdPnt

	move.b	#1,StrSwch
	move.w	#0,CList+22
	move.l	#Spr0,d0
	lea	SPR2(pc),a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

SinScrl	WaitBlt
	move.l	#$01000000,$40(a5)
	move.w	#$0000,$66(a5)
	move.l	WorkScn(pc),$54(a5)
	move.w	#82<<6+20,$58(a5)

	WaitBlt
	move.w	#38,$62(a5)
	move.l	#40<<16+38,$64(a5)
	move.l	#$0dfc0000,$40(a5)
	move.w	#$ffff,$46(a5)
	move.l	SinePnt(pc),a1
	lea	SclArea(pc),a2

	moveq	#0,d0
	move.l	d0,d1
	move.w	#%1000000000000000,d0
	moveq	#19,d6
SnLoop1	moveq	#15,d7
SnLoop2	move.l	WorkScn(pc),a0
	lea	(a0,d1),a0
	moveq	#0,d2
	move.b	(a1),d2

	move.l	d2,d3
	lsl.l	#3,d3
	lsl.l	#5,d2
	add.l	d3,d2
	add.l	d2,a0

	lea	(a2,d1),a3

	WaitBlt
	move.l	a0,$4c(a5)
	move.l	a3,$50(a5)
	move.l	a0,$54(a5)
	move.w	d0,$44(a5)
	move.w	#17<<6+1,$58(a5)

	ror.w	#1,d0
	addq.l	#1,a1
	cmp.l	#SineTbleEnd,a1
	blt.b	NoNewSn
	sub.l	#320,a1
NoNewSn	dbf	d7,SnLoop2
	addq.l	#2,d1
	dbf	d6,SnLoop1
	subq.l	#1,a1
	move.l	a1,SinePnt

;--------------------------------------;

SinEnd	tst.w	Counter
	bne.b	ScrllIt
	move.w	#8,Counter

GetTxCh	move.l	CharPnt(pc),a0
	moveq	#0,d0
	move.b	(a0)+,d0
	bne.s	GrabChr
	move.l	#ScrMess,CharPnt
	bra.s	GetTxCh

GrabChr	move.l	a0,CharPnt
	sub.b	#32,d0
	lsl.w	#5,d0
	add.l	#FntData,d0

NewChar	WaitBlt
	move.l	#$09f00000,$40(a5)
	move.l	#$ffffffff,$44(a5)
	move.l	d0,$50(a5)
	move.l	#SclArea+40,$54(a5)
	move.l	#40,$64(a5)
	move.w	#16<<6+1,$58(a5)

ScrllIt	WaitBlt
	move.l	#$e9f00000,$40(a5)
	move.l	#$ffffffff,$44(a5)
	move.l	#SclArea,$50(a5)
	move.l	#SclArea-(16/8),$54(a5)
	move.l	#0,$64(a5)
	move.w	#17<<6+20,$58(a5)
	sub.w	#1,Counter

;--------------------------------------;

NextScn	movem.l	CurrScn(pc),d0/d1
	exg.l	d0,d1
	movem.l	d0/d1,CurrScn

	lea	BPL2(pc),a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
SineEnd	rts

;--------------------------------------;

Stars	tst.b	StrSwch
	beq	StarEnd
	cmp.w	#$088c,StarCol+6
	beq	DoStars
	add.w	#$0111,StarCol+6

DoStars	lea	Spr0+1(pc),a0
	moveq	#9,d0
StrLoop	addq.b	#1,(a0)
	addq.b	#2,8(a0)
	addq.b	#3,16(a0)
	addq.b	#4,24(a0)
	lea	32(a0),a0
	dbf	d0,StrLoop
	addq.b	#1,(a0)
StarEnd	rts

;--------------------------------------;

;**************************************************
;*    ----- Protracker V2.3A Playroutine -----    *
;**************************************************

; VBlank Version 2:
; Call mt_init to initialize the routine, then call mt_music on
; each vertical blank (50 Hz). To end the song and turn off all
; voices, call mt_end.

; This playroutine is not very fast, optimized or well commented,
; but all the new commands in PT2.3A should work.
; If it's not good enough, you'll have to change it yourself.
; We'll try to write a faster routine soon...

; Changes from V1.0C playroutine:
; - Vibrato depth changed to be compatible with Noisetracker 2.0.
;   You'll have to double all vib. depths on old PT modules.
; - Funk Repeat changed to Invert Loop.
; - Period set back earlier when stopping an effect.

n_note		EQU	0  ; W
n_cmd		EQU	2  ; W
n_cmdlo		EQU	3  ; B
n_start		EQU	4  ; L
n_length	EQU	8  ; W
n_loopstart	EQU	10 ; L
n_replen	EQU	14 ; W
n_period	EQU	16 ; W
n_finetune	EQU	18 ; B
n_volume	EQU	19 ; B
n_dmabit	EQU	20 ; W
n_toneportdirec	EQU	22 ; B
n_toneportspeed	EQU	23 ; B
n_wantedperiod	EQU	24 ; W
n_vibratocmd	EQU	26 ; B
n_vibratopos	EQU	27 ; B
n_tremolocmd	EQU	28 ; B
n_tremolopos	EQU	29 ; B
n_wavecontrol	EQU	30 ; B
n_glissfunk	EQU	31 ; B
n_sampleoffset	EQU	32 ; B
n_pattpos	EQU	33 ; B
n_loopcount	EQU	34 ; B
n_funkoffset	EQU	35 ; B
n_wavestart	EQU	36 ; L
n_reallength	EQU	40 ; W

mt_init	LEA	mt_data,A0
	MOVE.L	A0,mt_SongDataPtr
	MOVE.L	A0,A1
	LEA	952(A1),A1
	MOVEQ	#127,D0
	MOVEQ	#0,D1
mtloop	MOVE.L	D1,D2
	SUBQ.W	#1,D0
mtloop2	MOVE.B	(A1)+,D1
	CMP.B	D2,D1
	BGT.S	mtloop
	DBRA	D0,mtloop2
	ADDQ.B	#1,D2
			
	LEA	mt_SampleStarts(PC),A1
	ASL.L	#8,D2
	ASL.L	#2,D2
	ADD.L	#1084,D2
	ADD.L	A0,D2
	MOVE.L	D2,A2
	MOVEQ	#30,D0
mtloop3	CLR.L	(A2)
	MOVE.L	A2,(A1)+
	MOVEQ	#0,D1
	MOVE.W	42(A0),D1
	ASL.L	#1,D1
	ADD.L	D1,A2
	ADD.L	#30,A0
	DBRA	D0,mtloop3

	OR.B	#2,$BFE001
	MOVE.B	#6,mt_speed
	CLR.B	mt_counter
	CLR.B	mt_SongPos
	CLR.W	mt_PatternPos
mt_end	CLR.W	$DFF0A8
	CLR.W	$DFF0B8
	CLR.W	$DFF0C8
	CLR.W	$DFF0D8
	MOVE.W	#$F,$DFF096
	RTS

mt_music
	MOVEM.L	D0-D4/A0-A6,-(SP)
	ADDQ.B	#1,mt_counter
	MOVE.B	mt_counter(PC),D0
	CMP.B	mt_speed(PC),D0
	BLO.S	mt_NoNewNote
	CLR.B	mt_counter
	TST.B	mt_PattDelTime2
	BEQ.S	mt_GetNewNote
	BSR.S	mt_NoNewAllChannels
	BRA.W	mt_dskip

mt_NoNewNote
	BSR.S	mt_NoNewAllChannels
	BRA.W	mt_NoNewPosYet

mt_NoNewAllChannels
	LEA	$DFF0A0,A5
	LEA	mt_chan1temp(PC),A6
	BSR.W	mt_CheckEfx
	LEA	$DFF0B0,A5
	LEA	mt_chan2temp(PC),A6
	BSR.W	mt_CheckEfx
	LEA	$DFF0C0,A5
	LEA	mt_chan3temp(PC),A6
	BSR.W	mt_CheckEfx
	LEA	$DFF0D0,A5
	LEA	mt_chan4temp(PC),A6
	BRA.W	mt_CheckEfx

mt_GetNewNote
	MOVE.L	mt_SongDataPtr(PC),A0
	LEA	12(A0),A3
	LEA	952(A0),A2	;pattpo
	LEA	1084(A0),A0	;patterndata
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	mt_SongPos(PC),D0
	MOVE.B	(A2,D0.W),D1
	ASL.L	#8,D1
	ASL.L	#2,D1
	ADD.W	mt_PatternPos(PC),D1
	CLR.W	mt_DMACONtemp

	LEA	$DFF0A0,A5
	LEA	mt_chan1temp(PC),A6
	BSR.S	mt_PlayVoice
	LEA	$DFF0B0,A5
	LEA	mt_chan2temp(PC),A6
	BSR.S	mt_PlayVoice
	LEA	$DFF0C0,A5
	LEA	mt_chan3temp(PC),A6
	BSR.S	mt_PlayVoice
	LEA	$DFF0D0,A5
	LEA	mt_chan4temp(PC),A6
	BSR.S	mt_PlayVoice
	BRA.W	mt_SetDMA

mt_PlayVoice
	TST.L	(A6)
	BNE.S	mt_plvskip
	BSR.W	mt_PerNop
mt_plvskip
	MOVE.L	(A0,D1.L),(A6)
	ADDQ.L	#4,D1
	MOVEQ	#0,D2
	MOVE.B	n_cmd(A6),D2
	AND.B	#$F0,D2
	LSR.B	#4,D2
	MOVE.B	(A6),D0
	AND.B	#$F0,D0
	OR.B	D0,D2
	TST.B	D2
	BEQ.W	mt_SetRegs
	MOVEQ	#0,D3
	LEA	mt_SampleStarts(PC),A1
	MOVE	D2,D4
	SUBQ.L	#1,D2
	ASL.L	#2,D2
	MULU	#30,D4
	MOVE.L	(A1,D2.L),n_start(A6)
	MOVE.W	(A3,D4.L),n_length(A6)
	MOVE.W	(A3,D4.L),n_reallength(A6)
	MOVE.B	2(A3,D4.L),n_finetune(A6)
	MOVE.B	3(A3,D4.L),n_volume(A6)
	MOVE.W	4(A3,D4.L),D3 ; Get repeat
	TST.W	D3
	BEQ.S	mt_NoLoop
	MOVE.L	n_start(A6),D2	; Get start
	ASL.W	#1,D3
	ADD.L	D3,D2		; Add repeat
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	4(A3,D4.L),D0	; Get repeat
	ADD.W	6(A3,D4.L),D0	; Add replen
	MOVE.W	D0,n_length(A6)
	MOVE.W	6(A3,D4.L),n_replen(A6)	; Save replen
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)	; Set volume
	BRA.S	mt_SetRegs

mt_NoLoop
	MOVE.L	n_start(A6),D2
	ADD.L	D3,D2
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	6(A3,D4.L),n_replen(A6)	; Save replen
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)	; Set volume
mt_SetRegs
	MOVE.W	(A6),D0
	AND.W	#$0FFF,D0
	BEQ.W	mt_CheckMoreEfx	; If no note
	MOVE.W	2(A6),D0
	AND.W	#$0FF0,D0
	CMP.W	#$0E50,D0
	BEQ.S	mt_DoSetFineTune
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#3,D0	; TonePortamento
	BEQ.S	mt_ChkTonePorta
	CMP.B	#5,D0
	BEQ.S	mt_ChkTonePorta
	CMP.B	#9,D0	; Sample Offset
	BNE.S	mt_SetPeriod
	BSR.W	mt_CheckMoreEfx
	BRA.S	mt_SetPeriod

mt_DoSetFineTune
	BSR.W	mt_SetFineTune
	BRA.S	mt_SetPeriod

mt_ChkTonePorta
	BSR.W	mt_SetTonePorta
	BRA.W	mt_CheckMoreEfx

mt_SetPeriod
	MOVEM.L	D0-D1/A0-A1,-(SP)
	MOVE.W	(A6),D1
	AND.W	#$0FFF,D1
	LEA	mt_PeriodTable(PC),A1
	MOVEQ	#0,D0
	MOVEQ	#36,D7
mt_ftuloop
	CMP.W	(A1,D0.W),D1
	BHS.S	mt_ftufound
	ADDQ.L	#2,D0
	DBRA	D7,mt_ftuloop
mt_ftufound
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	MULU	#36*2,D1
	ADD.L	D1,A1
	MOVE.W	(A1,D0.W),n_period(A6)
	MOVEM.L	(SP)+,D0-D1/A0-A1

	MOVE.W	2(A6),D0
	AND.W	#$0FF0,D0
	CMP.W	#$0ED0,D0 ; Notedelay
	BEQ.W	mt_CheckMoreEfx

	MOVE.W	n_dmabit(A6),$DFF096
	BTST	#2,n_wavecontrol(A6)
	BNE.S	mt_vibnoc
	CLR.B	n_vibratopos(A6)
mt_vibnoc
	BTST	#6,n_wavecontrol(A6)
	BNE.S	mt_trenoc
	CLR.B	n_tremolopos(A6)
mt_trenoc
	MOVE.L	n_start(A6),(A5)	; Set start
	MOVE.W	n_length(A6),4(A5)	; Set length
	MOVE.W	n_period(A6),D0
	MOVE.W	D0,6(A5)		; Set period
	MOVE.W	n_dmabit(A6),D0
	OR.W	D0,mt_DMACONtemp
	BRA.W	mt_CheckMoreEfx
 
mt_SetDMA
	MOVE.W	#300,D0
mt_WaitDMA
	DBRA	D0,mt_WaitDMA
	MOVE.W	mt_DMACONtemp(PC),D0
	OR.W	#$8000,D0
	MOVE.W	D0,$DFF096
	MOVE.W	#300,D0
mt_WaitDMA2
	DBRA	D0,mt_WaitDMA2

	LEA	$DFF000,A5
	LEA	mt_chan4temp(PC),A6
	MOVE.L	n_loopstart(A6),$D0(A5)
	MOVE.W	n_replen(A6),$D4(A5)
	LEA	mt_chan3temp(PC),A6
	MOVE.L	n_loopstart(A6),$C0(A5)
	MOVE.W	n_replen(A6),$C4(A5)
	LEA	mt_chan2temp(PC),A6
	MOVE.L	n_loopstart(A6),$B0(A5)
	MOVE.W	n_replen(A6),$B4(A5)
	LEA	mt_chan1temp(PC),A6
	MOVE.L	n_loopstart(A6),$A0(A5)
	MOVE.W	n_replen(A6),$A4(A5)

mt_dskip
	ADD.W	#16,mt_PatternPos
	MOVE.B	mt_PattDelTime,D0
	BEQ.S	mt_dskc
	MOVE.B	D0,mt_PattDelTime2
	CLR.B	mt_PattDelTime
mt_dskc	TST.B	mt_PattDelTime2
	BEQ.S	mt_dska
	SUBQ.B	#1,mt_PattDelTime2
	BEQ.S	mt_dska
	SUB.W	#16,mt_PatternPos
mt_dska	TST.B	mt_PBreakFlag
	BEQ.S	mt_nnpysk
	SF	mt_PBreakFlag
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos(PC),D0
	CLR.B	mt_PBreakPos
	LSL.W	#4,D0
	MOVE.W	D0,mt_PatternPos
mt_nnpysk
	CMP.W	#1024,mt_PatternPos
	BLO.S	mt_NoNewPosYet
mt_NextPosition	
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos(PC),D0
	LSL.W	#4,D0
	MOVE.W	D0,mt_PatternPos
	CLR.B	mt_PBreakPos
	CLR.B	mt_PosJumpFlag
	ADDQ.B	#1,mt_SongPos
	AND.B	#$7F,mt_SongPos
	MOVE.B	mt_SongPos(PC),D1
	MOVE.L	mt_SongDataPtr(PC),A0
	CMP.B	950(A0),D1
	BLO.S	mt_NoNewPosYet
	CLR.B	mt_SongPos
mt_NoNewPosYet	
	TST.B	mt_PosJumpFlag
	BNE.S	mt_NextPosition
	MOVEM.L	(SP)+,D0-D4/A0-A6
	RTS

mt_CheckEfx
	BSR.W	mt_UpdateFunk
	MOVE.W	n_cmd(A6),D0
	AND.W	#$0FFF,D0
	BEQ.S	mt_PerNop
	MOVE.B	n_cmd(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_Arpeggio
	CMP.B	#1,D0
	BEQ.W	mt_PortaUp
	CMP.B	#2,D0
	BEQ.W	mt_PortaDown
	CMP.B	#3,D0
	BEQ.W	mt_TonePortamento
	CMP.B	#4,D0
	BEQ.W	mt_Vibrato
	CMP.B	#5,D0
	BEQ.W	mt_TonePlusVolSlide
	CMP.B	#6,D0
	BEQ.W	mt_VibratoPlusVolSlide
	CMP.B	#$E,D0
	BEQ.W	mt_E_Commands
SetBack	MOVE.W	n_period(A6),6(A5)
	CMP.B	#7,D0
	BEQ.W	mt_Tremolo
	CMP.B	#$A,D0
	BEQ.W	mt_VolumeSlide
mt_Return2
	RTS

mt_PerNop
	MOVE.W	n_period(A6),6(A5)
	RTS

mt_Arpeggio
	MOVEQ	#0,D0
	MOVE.B	mt_counter(PC),D0
	DIVS	#3,D0
	SWAP	D0
	CMP.W	#0,D0
	BEQ.S	mt_Arpeggio2
	CMP.W	#2,D0
	BEQ.S	mt_Arpeggio1
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	BRA.S	mt_Arpeggio3

mt_Arpeggio1
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#15,D0
	BRA.S	mt_Arpeggio3

mt_Arpeggio2
	MOVE.W	n_period(A6),D2
	BRA.S	mt_Arpeggio4

mt_Arpeggio3
	ASL.W	#1,D0
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	MULU	#36*2,D1
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D1,A0
	MOVEQ	#0,D1
	MOVE.W	n_period(A6),D1
	MOVEQ	#36,D7
mt_arploop
	MOVE.W	(A0,D0.W),D2
	CMP.W	(A0),D1
	BHS.S	mt_Arpeggio4
	ADDQ.L	#2,A0
	DBRA	D7,mt_arploop
	RTS

mt_Arpeggio4
	MOVE.W	D2,6(A5)
	RTS

mt_FinePortaUp
	TST.B	mt_counter
	BNE.S	mt_Return2
	MOVE.B	#$0F,mt_LowMask
mt_PortaUp
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	mt_LowMask(PC),D0
	MOVE.B	#$FF,mt_LowMask
	SUB.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#113,D0
	BPL.S	mt_PortaUskip
	AND.W	#$F000,n_period(A6)
	OR.W	#113,n_period(A6)
mt_PortaUskip
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	MOVE.W	D0,6(A5)
	RTS	
 
mt_FinePortaDown
	TST.B	mt_counter
	BNE.W	mt_Return2
	MOVE.B	#$0F,mt_LowMask
mt_PortaDown
	CLR.W	D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	mt_LowMask(PC),D0
	MOVE.B	#$FF,mt_LowMask
	ADD.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#856,D0
	BMI.S	mt_PortaDskip
	AND.W	#$F000,n_period(A6)
	OR.W	#856,n_period(A6)
mt_PortaDskip
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	MOVE.W	D0,6(A5)
	RTS

mt_SetTonePorta
	MOVE.L	A0,-(SP)
	MOVE.W	(A6),D2
	AND.W	#$0FFF,D2
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	MULU	#36*2,D0 ;37?
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D0,A0
	MOVEQ	#0,D0
mt_StpLoop
	CMP.W	(A0,D0.W),D2
	BHS.S	mt_StpFound
	ADDQ.W	#2,D0
	CMP.W	#36*2,D0 ;37?
	BLO.S	mt_StpLoop
	MOVEQ	#35*2,D0
mt_StpFound
	MOVE.B	n_finetune(A6),D2
	AND.B	#8,D2
	BEQ.S	mt_StpGoss
	TST.W	D0
	BEQ.S	mt_StpGoss
	SUBQ.W	#2,D0
mt_StpGoss
	MOVE.W	(A0,D0.W),D2
	MOVE.L	(SP)+,A0
	MOVE.W	D2,n_wantedperiod(A6)
	MOVE.W	n_period(A6),D0
	CLR.B	n_toneportdirec(A6)
	CMP.W	D0,D2
	BEQ.S	mt_ClearTonePorta
	BGE.W	mt_Return2
	MOVE.B	#1,n_toneportdirec(A6)
	RTS

mt_ClearTonePorta
	CLR.W	n_wantedperiod(A6)
	RTS

mt_TonePortamento
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_TonePortNoChange
	MOVE.B	D0,n_toneportspeed(A6)
	CLR.B	n_cmdlo(A6)
mt_TonePortNoChange
	TST.W	n_wantedperiod(A6)
	BEQ.W	mt_Return2
	MOVEQ	#0,D0
	MOVE.B	n_toneportspeed(A6),D0
	TST.B	n_toneportdirec(A6)
	BNE.S	mt_TonePortaUp
mt_TonePortaDown
	ADD.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BGT.S	mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)
	BRA.S	mt_TonePortaSetPer

mt_TonePortaUp
	SUB.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BLT.S	mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)

mt_TonePortaSetPer
	MOVE.W	n_period(A6),D2
	MOVE.B	n_glissfunk(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_GlissSkip
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	MULU	#36*2,D0
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D0,A0
	MOVEQ	#0,D0
mt_GlissLoop
	CMP.W	(A0,D0.W),D2
	BHS.S	mt_GlissFound
	ADDQ.W	#2,D0
	CMP.W	#36*2,D0
	BLO.S	mt_GlissLoop
	MOVEQ	#35*2,D0
mt_GlissFound
	MOVE.W	(A0,D0.W),D2
mt_GlissSkip
	MOVE.W	D2,6(A5) ; Set period
	RTS

mt_Vibrato
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Vibrato2
	MOVE.B	n_vibratocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	mt_vibskip
	AND.B	#$F0,D2
	OR.B	D0,D2
mt_vibskip
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	mt_vibskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
mt_vibskip2
	MOVE.B	D2,n_vibratocmd(A6)
mt_Vibrato2
	MOVE.B	n_vibratopos(A6),D0
	LEA	mt_VibratoTable(PC),A4
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	AND.B	#$03,D2
	BEQ.S	mt_vib_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	mt_vib_rampdown
	MOVE.B	#255,D2
	BRA.S	mt_vib_set
mt_vib_rampdown
	TST.B	n_vibratopos(A6)
	BPL.S	mt_vib_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	mt_vib_set
mt_vib_rampdown2
	MOVE.B	D0,D2
	BRA.S	mt_vib_set
mt_vib_sine
	MOVE.B	0(A4,D0.W),D2
mt_vib_set
	MOVE.B	n_vibratocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#7,D2
	MOVE.W	n_period(A6),D0
	TST.B	n_vibratopos(A6)
	BMI.S	mt_VibratoNeg
	ADD.W	D2,D0
	BRA.S	mt_Vibrato3
mt_VibratoNeg
	SUB.W	D2,D0
mt_Vibrato3
	MOVE.W	D0,6(A5)
	MOVE.B	n_vibratocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_vibratopos(A6)
	RTS

mt_TonePlusVolSlide
	BSR.W	mt_TonePortNoChange
	BRA.W	mt_VolumeSlide

mt_VibratoPlusVolSlide
	BSR.S	mt_Vibrato2
	BRA.W	mt_VolumeSlide

mt_Tremolo
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Tremolo2
	MOVE.B	n_tremolocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	mt_treskip
	AND.B	#$F0,D2
	OR.B	D0,D2
mt_treskip
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	mt_treskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
mt_treskip2
	MOVE.B	D2,n_tremolocmd(A6)
mt_Tremolo2
	MOVE.B	n_tremolopos(A6),D0
	LEA	mt_VibratoTable(PC),A4
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	LSR.B	#4,D2
	AND.B	#$03,D2
	BEQ.S	mt_tre_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	mt_tre_rampdown
	MOVE.B	#255,D2
	BRA.S	mt_tre_set
mt_tre_rampdown
	TST.B	n_vibratopos(A6)
	BPL.S	mt_tre_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	mt_tre_set
mt_tre_rampdown2
	MOVE.B	D0,D2
	BRA.S	mt_tre_set
mt_tre_sine
	MOVE.B	0(A4,D0.W),D2
mt_tre_set
	MOVE.B	n_tremolocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#6,D2
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	TST.B	n_tremolopos(A6)
	BMI.S	mt_TremoloNeg
	ADD.W	D2,D0
	BRA.S	mt_Tremolo3
mt_TremoloNeg
	SUB.W	D2,D0
mt_Tremolo3
	BPL.S	mt_TremoloSkip
	CLR.W	D0
mt_TremoloSkip
	CMP.W	#$40,D0
	BLS.S	mt_TremoloOk
	MOVE.W	#$40,D0
mt_TremoloOk
	MOVE.W	D0,8(A5)
	MOVE.B	n_tremolocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_tremolopos(A6)
	RTS

mt_SampleOffset
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_sononew
	MOVE.B	D0,n_sampleoffset(A6)
mt_sononew
	MOVE.B	n_sampleoffset(A6),D0
	LSL.W	#7,D0
	CMP.W	n_length(A6),D0
	BGE.S	mt_sofskip
	SUB.W	D0,n_length(A6)
	LSL.W	#1,D0
	ADD.L	D0,n_start(A6)
	RTS
mt_sofskip
	MOVE.W	#$0001,n_length(A6)
	RTS

mt_VolumeSlide
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	TST.B	D0
	BEQ.S	mt_VolSlideDown
mt_VolSlideUp
	ADD.B	D0,n_volume(A6)
	CMP.B	#$40,n_volume(A6)
	BMI.S	mt_vsuskip
	MOVE.B	#$40,n_volume(A6)
mt_vsuskip
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	RTS

mt_VolSlideDown
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
mt_VolSlideDown2
	SUB.B	D0,n_volume(A6)
	BPL.S	mt_vsdskip
	CLR.B	n_volume(A6)
mt_vsdskip
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	RTS

mt_PositionJump
	MOVE.B	n_cmdlo(A6),D0
	SUBQ.B	#1,D0
	MOVE.B	D0,mt_SongPos
mt_pj2	CLR.B	mt_PBreakPos
	ST 	mt_PosJumpFlag
	RTS

mt_VolumeChange
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	CMP.B	#$40,D0
	BLS.S	mt_VolumeOk
	MOVEQ	#$40,D0
mt_VolumeOk
	MOVE.B	D0,n_volume(A6)
	MOVE.W	D0,8(A5)
	RTS

mt_PatternBreak
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	MOVE.L	D0,D2
	LSR.B	#4,D0
	MULU	#10,D0
	AND.B	#$0F,D2
	ADD.B	D2,D0
	CMP.B	#63,D0
	BHI.S	mt_pj2
	MOVE.B	D0,mt_PBreakPos
	ST	mt_PosJumpFlag
	RTS

mt_SetSpeed
	MOVE.B	3(A6),D0
	BEQ.W	mt_Return2
	CLR.B	mt_counter
	MOVE.B	D0,mt_speed
	RTS

mt_CheckMoreEfx
	BSR.W	mt_UpdateFunk
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#$9,D0
	BEQ.W	mt_SampleOffset
	CMP.B	#$B,D0
	BEQ.W	mt_PositionJump
	CMP.B	#$D,D0
	BEQ.S	mt_PatternBreak
	CMP.B	#$E,D0
	BEQ.S	mt_E_Commands
	CMP.B	#$F,D0
	BEQ.S	mt_SetSpeed
	CMP.B	#$C,D0
	BEQ.W	mt_VolumeChange
	BRA.W	mt_PerNop

mt_E_Commands
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	LSR.B	#4,D0
	BEQ.S	mt_FilterOnOff
	CMP.B	#1,D0
	BEQ.W	mt_FinePortaUp
	CMP.B	#2,D0
	BEQ.W	mt_FinePortaDown
	CMP.B	#3,D0
	BEQ.S	mt_SetGlissControl
	CMP.B	#4,D0
	BEQ.W	mt_SetVibratoControl
	CMP.B	#5,D0
	BEQ.W	mt_SetFineTune
	CMP.B	#6,D0
	BEQ.W	mt_JumpLoop
	CMP.B	#7,D0
	BEQ.W	mt_SetTremoloControl
	CMP.B	#9,D0
	BEQ.W	mt_RetrigNote
	CMP.B	#$A,D0
	BEQ.W	mt_VolumeFineUp
	CMP.B	#$B,D0
	BEQ.W	mt_VolumeFineDown
	CMP.B	#$C,D0
	BEQ.W	mt_NoteCut
	CMP.B	#$D,D0
	BEQ.W	mt_NoteDelay
	CMP.B	#$E,D0
	BEQ.W	mt_PatternDelay
	CMP.B	#$F,D0
	BEQ.W	mt_FunkIt
	RTS

mt_FilterOnOff
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#1,D0
	ASL.B	#1,D0
	AND.B	#$FD,$BFE001
	OR.B	D0,$BFE001
	RTS	

mt_SetGlissControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	RTS

mt_SetVibratoControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS

mt_SetFineTune
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	MOVE.B	D0,n_finetune(A6)
	RTS

mt_JumpLoop
	TST.B	mt_counter
	BNE.W	mt_Return2
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_SetLoop
	TST.B	n_loopcount(A6)
	BEQ.S	mt_jumpcnt
	SUBQ.B	#1,n_loopcount(A6)
	BEQ.W	mt_Return2
mt_jmploop	MOVE.B	n_pattpos(A6),mt_PBreakPos
	ST	mt_PBreakFlag
	RTS

mt_jumpcnt
	MOVE.B	D0,n_loopcount(A6)
	BRA.S	mt_jmploop

mt_SetLoop
	MOVE.W	mt_PatternPos(PC),D0
	LSR.W	#4,D0
	MOVE.B	D0,n_pattpos(A6)
	RTS

mt_SetTremoloControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS

mt_RetrigNote
	MOVE.L	D1,-(SP)
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter(PC),D1
	BNE.S	mt_rtnskp
	MOVE.W	(A6),D1
	AND.W	#$0FFF,D1
	BNE.S	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter(PC),D1
mt_rtnskp
	DIVU	D0,D1
	SWAP	D1
	TST.W	D1
	BNE.S	mt_rtnend
mt_DoRetrig
	MOVE.W	n_dmabit(A6),$DFF096	; Channel DMA off
	MOVE.L	n_start(A6),(A5)	; Set sampledata pointer
	MOVE.W	n_length(A6),4(A5)	; Set length
	MOVE.W	#300,D0
mt_rtnloop1
	DBRA	D0,mt_rtnloop1
	MOVE.W	n_dmabit(A6),D0
	BSET	#15,D0
	MOVE.W	D0,$DFF096
	MOVE.W	#300,D0
mt_rtnloop2
	DBRA	D0,mt_rtnloop2
	MOVE.L	n_loopstart(A6),(A5)
	MOVE.L	n_replen(A6),4(A5)
mt_rtnend
	MOVE.L	(SP)+,D1
	RTS

mt_VolumeFineUp
	TST.B	mt_counter
	BNE.W	mt_Return2
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F,D0
	BRA.W	mt_VolSlideUp

mt_VolumeFineDown
	TST.B	mt_counter
	BNE.W	mt_Return2
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BRA.W	mt_VolSlideDown2

mt_NoteCut
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter(PC),D0
	BNE.W	mt_Return2
	CLR.B	n_volume(A6)
	MOVE.W	#0,8(A5)
	RTS

mt_NoteDelay
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter,D0
	BNE.W	mt_Return2
	MOVE.W	(A6),D0
	BEQ.W	mt_Return2
	MOVE.L	D1,-(SP)
	BRA.W	mt_DoRetrig

mt_PatternDelay
	TST.B	mt_counter
	BNE.W	mt_Return2
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	TST.B	mt_PattDelTime2
	BNE.W	mt_Return2
	ADDQ.B	#1,D0
	MOVE.B	D0,mt_PattDelTime
	RTS

mt_FunkIt
	TST.B	mt_counter
	BNE.W	mt_Return2
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	TST.B	D0
	BEQ.W	mt_Return2
mt_UpdateFunk
	MOVEM.L	A0/D1,-(SP)
	MOVEQ	#0,D0
	MOVE.B	n_glissfunk(A6),D0
	LSR.B	#4,D0
	BEQ.S	mt_funkend
	LEA	mt_FunkTable(PC),A0
	MOVE.B	(A0,D0.W),D0
	ADD.B	D0,n_funkoffset(A6)
	BTST	#7,n_funkoffset(A6)
	BEQ.S	mt_funkend
	CLR.B	n_funkoffset(A6)

	MOVE.L	n_loopstart(A6),D0
	MOVEQ	#0,D1
	MOVE.W	n_replen(A6),D1
	ADD.L	D1,D0
	ADD.L	D1,D0
	MOVE.L	n_wavestart(A6),A0
	ADDQ.L	#1,A0
	CMP.L	D0,A0
	BLO.S	mt_funkok
	MOVE.L	n_loopstart(A6),A0
mt_funkok
	MOVE.L	A0,n_wavestart(A6)
	MOVEQ	#-1,D0
	SUB.B	(A0),D0
	MOVE.B	D0,(A0)
mt_funkend
	MOVEM.L	(SP)+,A0/D1
	RTS


mt_FunkTable dc.b 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

mt_VibratoTable	
	dc.b   0, 24, 49, 74, 97,120,141,161
	dc.b 180,197,212,224,235,244,250,253
	dc.b 255,253,250,244,235,224,212,197
	dc.b 180,161,141,120, 97, 74, 49, 24

mt_PeriodTable
; Tuning 0, Normal
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113
; Tuning 1
	dc.w	850,802,757,715,674,637,601,567,535,505,477,450
	dc.w	425,401,379,357,337,318,300,284,268,253,239,225
	dc.w	213,201,189,179,169,159,150,142,134,126,119,113
; Tuning 2
	dc.w	844,796,752,709,670,632,597,563,532,502,474,447
	dc.w	422,398,376,355,335,316,298,282,266,251,237,224
	dc.w	211,199,188,177,167,158,149,141,133,125,118,112
; Tuning 3
	dc.w	838,791,746,704,665,628,592,559,528,498,470,444
	dc.w	419,395,373,352,332,314,296,280,264,249,235,222
	dc.w	209,198,187,176,166,157,148,140,132,125,118,111
; Tuning 4
	dc.w	832,785,741,699,660,623,588,555,524,495,467,441
	dc.w	416,392,370,350,330,312,294,278,262,247,233,220
	dc.w	208,196,185,175,165,156,147,139,131,124,117,110
; Tuning 5
	dc.w	826,779,736,694,655,619,584,551,520,491,463,437
	dc.w	413,390,368,347,328,309,292,276,260,245,232,219
	dc.w	206,195,184,174,164,155,146,138,130,123,116,109
; Tuning 6
	dc.w	820,774,730,689,651,614,580,547,516,487,460,434
	dc.w	410,387,365,345,325,307,290,274,258,244,230,217
	dc.w	205,193,183,172,163,154,145,137,129,122,115,109
; Tuning 7
	dc.w	814,768,725,684,646,610,575,543,513,484,457,431
	dc.w	407,384,363,342,323,305,288,272,256,242,228,216
	dc.w	204,192,181,171,161,152,144,136,128,121,114,108
; Tuning -8
	dc.w	907,856,808,762,720,678,640,604,570,538,508,480
	dc.w	453,428,404,381,360,339,320,302,285,269,254,240
	dc.w	226,214,202,190,180,170,160,151,143,135,127,120
; Tuning -7
	dc.w	900,850,802,757,715,675,636,601,567,535,505,477
	dc.w	450,425,401,379,357,337,318,300,284,268,253,238
	dc.w	225,212,200,189,179,169,159,150,142,134,126,119
; Tuning -6
	dc.w	894,844,796,752,709,670,632,597,563,532,502,474
	dc.w	447,422,398,376,355,335,316,298,282,266,251,237
	dc.w	223,211,199,188,177,167,158,149,141,133,125,118
; Tuning -5
	dc.w	887,838,791,746,704,665,628,592,559,528,498,470
	dc.w	444,419,395,373,352,332,314,296,280,264,249,235
	dc.w	222,209,198,187,176,166,157,148,140,132,125,118
; Tuning -4
	dc.w	881,832,785,741,699,660,623,588,555,524,494,467
	dc.w	441,416,392,370,350,330,312,294,278,262,247,233
	dc.w	220,208,196,185,175,165,156,147,139,131,123,117
; Tuning -3
	dc.w	875,826,779,736,694,655,619,584,551,520,491,463
	dc.w	437,413,390,368,347,328,309,292,276,260,245,232
	dc.w	219,206,195,184,174,164,155,146,138,130,123,116
; Tuning -2
	dc.w	868,820,774,730,689,651,614,580,547,516,487,460
	dc.w	434,410,387,365,345,325,307,290,274,258,244,230
	dc.w	217,205,193,183,172,163,154,145,137,129,122,115
; Tuning -1
	dc.w	862,814,768,725,684,646,610,575,543,513,484,457
	dc.w	431,407,384,363,342,323,305,288,272,256,242,228
	dc.w	216,203,192,181,171,161,152,144,136,128,121,114

mt_chan1temp	dc.l	0,0,0,0,0,$00010000,0,  0,0,0,0
mt_chan2temp	dc.l	0,0,0,0,0,$00020000,0,  0,0,0,0
mt_chan3temp	dc.l	0,0,0,0,0,$00040000,0,  0,0,0,0
mt_chan4temp	dc.l	0,0,0,0,0,$00080000,0,  0,0,0,0

mt_SampleStarts	dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

mt_SongDataPtr	dc.l 0

mt_speed	dc.b 6
mt_counter	dc.b 0
mt_SongPos	dc.b 0
mt_PBreakPos	dc.b 0
mt_PosJumpFlag	dc.b 0
mt_PBreakFlag	dc.b 0
mt_LowMask	dc.b 0
mt_PattDelTime	dc.b 0
mt_PattDelTime2	dc.b 0,0

mt_PatternPos	dc.w 0
mt_DMACONtemp	dc.w 0

;--------------------------------------;

DMACon	dc.w	0
IntEna	dc.w	0
OldIRQ	dc.l	0
OldView	dc.l	0
GfxBase	dc.b	"graphics.library",0,0
ColSwch	dc.b	15
StrSwch	dc.b	0
SptSwch	dc.w	448
SinSwch	dc.w	53
SnePntX	dc.l	SneHorz
SnePntY	dc.l	SneVert
CharPnt	dc.l	ScrMess
Counter	dc.w	0
SinePnt	dc.l	SinTble
CurrScn	dc.l	MskArea
WorkScn	dc.l	Screen2
ComdPnt	dc.l	ComList
ComList	dc.l	SptLght
	dc.l	InitFde
	dc.l	FadeLgo
	dc.l	MveCols
	dc.l	SinWait
	dc.l	SinScrl

;--------------------------------------;

CList	dc.w	$008e,$2c81,$0090,$2cc1
	dc.w	$0092,$0038,$0094,$00d0
	dc.w	$0102,$0000,$0104,$003f
	dc.w	$0106,$0000,$01fc,$0000
	dc.w	$0108,$0000,$010a,$0000

SPR1	dc.w	$0120,$0000,$0122,$0000
	dc.w	$0124,$0000,$0126,$0000
SPR2	dc.w	$0128,$0000,$012a,$0000
SPR3	dc.w	$012c,$0000,$012e,$0000
	dc.w	$0130,$0000,$0132,$0000
	dc.w	$0134,$0000,$0136,$0000
	dc.w	$0138,$0000,$013a,$0000
	dc.w	$013c,$0000,$013e,$0000

	dc.w	$7007,$fffe,$0180,$0bcf
	dc.w	$7107,$fffe

Colours	dc.w	$0180,$0004,$0182,$0004
	dc.w	$0184,$0004,$0186,$0004
	dc.w	$0188,$0004,$018a,$0004
	dc.w	$018c,$0004,$018e,$0004
MskCols	dc.w	$0190,$0008,$0192,$0bcf
	dc.w	$0194,$09bd,$0196,$089b
	dc.w	$0198,$0789,$019a,$0568
	dc.w	$019c,$0456,$019e,$0fff
	dc.w	$01a2,$0bcf,$01a4,$0125
StarCol	dc.w	$01a6,$0004,$01ae,$0004

	dc.w	$7207,$fffe,$0100,$4200
BPL1	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
BPL2	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$c407,$fffe,$0100,$3200

	dc.w	$c507,$fffe,$0180,$0bcf
	dc.w	$c607,$fffe,$0180,$0000

	dc.w	$c907,$fffe,$0100,$0200
	dc.w	$ffff,$fffe,$ffff,$fffe

;--------------------------------------;

SneHorz	dc.b	$83,$8b,$93,$9b,$a2,$aa,$b1,$b9,$c0,$c6
	dc.b	$cd,$d3,$d9,$de,$e3,$e8,$ec,$f0,$f4,$f6
	dc.b	$f9,$fb,$fc,$fd,$fe,$fe,$fd,$fc,$fb,$f9
	dc.b	$f6,$f4,$f0,$ec,$e8,$e3,$de,$d9,$d3,$cd
	dc.b	$c6,$c0,$b9,$b1,$aa,$a2,$9b,$93,$8b,$83
	dc.b	$7b,$73,$6b,$63,$5c,$54,$4d,$45,$3e,$38
	dc.b	$31,$2b,$25,$20,$1b,$16,$12,$0e,$0a,$08
	dc.b	$05,$03,$02,$01,$00,$00,$01,$02,$03,$05
	dc.b	$08,$0a,$0e,$12,$16,$1b,$20,$25,$2b,$31
	dc.b	$38,$3e,$45,$4d,$54,$5c,$63,$6b,$73,$7b
SneHorzEnd

SneVert	dc.b	$52,$52,$51,$51,$50,$50,$4f,$4e,$4c,$4b
	dc.b	$49,$48,$46,$44,$42,$40,$3e,$3c,$39,$37
	dc.b	$34,$32,$2f,$2d,$2a,$28,$25,$23,$20,$1e
	dc.b	$1b,$19,$16,$14,$12,$10,$0e,$0c,$0a,$09
	dc.b	$07,$06,$04,$03,$02,$02,$01,$01,$00,$00
	dc.b	$00,$00,$01,$01,$02,$02,$03,$04,$06,$07
	dc.b	$09,$0a,$0c,$0e,$10,$12,$14,$16,$19,$1b
	dc.b	$1e,$20,$23,$25,$28,$2a,$2d,$2f,$32,$34
	dc.b	$37,$39,$3c,$3e,$40,$42,$44,$46,$48,$49
	dc.b	$4b,$4c,$4e,$4f,$50,$50,$51,$51,$52,$52
SneVertEnd

	dc.w	0
SinTble	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02
	dc.b	$02,$02,$02,$02,$03,$03,$03,$03,$04,$04,$04,$05,$05,$05,$06,$06
	dc.b	$06,$07,$07,$08,$08,$09,$09,$09,$0a,$0a,$0b,$0b,$0c,$0c,$0d,$0d
	dc.b	$0e,$0e,$0f,$0f,$10,$11,$11,$12,$12,$13,$13,$14,$15,$15,$16,$16
	dc.b	$17,$18,$18,$19,$1a,$1a,$1b,$1c,$1c,$1d,$1d,$1e,$1f,$1f,$20,$21
	dc.b	$21,$22,$23,$23,$24,$25,$25,$26,$26,$27,$28,$28,$29,$2a,$2a,$2b
	dc.b	$2c,$2c,$2d,$2d,$2e,$2f,$2f,$30,$30,$31,$31,$32,$33,$33,$34,$34
	dc.b	$35,$35,$36,$36,$37,$37,$38,$38,$39,$39,$39,$3a,$3a,$3b,$3b,$3c
	dc.b	$3c,$3c,$3d,$3d,$3d,$3e,$3e,$3e,$3f,$3f,$3f,$3f,$40,$40,$40,$40
	dc.b	$40,$41,$41,$41,$41,$41,$41,$42,$42,$42,$42,$42,$42,$42,$42,$42
	dc.b	$42,$42,$42,$42,$42,$42,$42,$42,$42,$41,$41,$41,$41,$41,$41,$40
	dc.b	$40,$40,$40,$40,$3f,$3f,$3f,$3f,$3e,$3e,$3e,$3d,$3d,$3d,$3c,$3c
	dc.b	$3c,$3b,$3b,$3a,$3a,$39,$39,$39,$38,$38,$37,$37,$36,$36,$35,$35
	dc.b	$34,$34,$33,$33,$32,$31,$31,$30,$30,$2f,$2f,$2e,$2d,$2d,$2c,$2c
	dc.b	$2b,$2a,$2a,$29,$28,$28,$27,$26,$26,$25,$25,$24,$23,$23,$22,$21
	dc.b	$21,$20,$1f,$1f,$1e,$1d,$1d,$1c,$1c,$1b,$1a,$1a,$19,$18,$18,$17
	dc.b	$16,$16,$15,$15,$14,$13,$13,$12,$12,$11,$11,$10,$0f,$0f,$0e,$0e
	dc.b	$0d,$0d,$0c,$0c,$0b,$0b,$0a,$0a,$09,$09,$09,$08,$08,$07,$07,$06
	dc.b	$06,$06,$05,$05,$05,$04,$04,$04,$03,$03,$03,$03,$02,$02,$02,$02
	dc.b	$02,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
SineTbleEnd

;--------------------------------------;

ScrMess	dc.b	"PRESENTING THE 4TH ISSUE OF ""AMIGA DOWN UNDER""    "
	dc.b	"ON THIS DISK WE HAVE LOTS OF DIFFERENT AND COOL THINGS.     "
	dc.b	"INTRO WRITTEN BY ROBSTER, MUSIC BY WAL OF "
	dc.b	"PUNISHERS, GRAPHICS BY ROBSTER,    ---LATER DUDES!!!---    "
	dc.b	"      ",0
	even
ColOffs	dc.w	$0000,$0bcb,$09b9,$0897,$0785,$0564,$0452,$0ffb
ColChrt	dc.w	$0448,$078b,$0579,$0458,$0448,$0448,$0448,$0bbb
Picture	incbin	"Amiga.raw"
Circle	incbin	"Circle.raw"
FntData	incbin	"Font.raw"
Sprite	dc.b	$c0,$cc,$c9,$00,$00,$00,$33,$73,$33,$73,$4c
	dc.b	$8c,$4c,$8c,$b3,$52,$4c,$b3,$90,$0c,$54,$88
	dc.b	$8b,$11,$f3,$6a,$2c,$f7,$0c,$f7,$13,$08,$00
	dc.b	$00,$0c,$f7,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$c0,$d4,$c9,$00,$00,$00,$e7,$30,$e7,$30,$10
	dc.b	$c8,$18,$48,$24,$04,$1e,$48,$81,$14,$98,$50
	dc.b	$04,$8c,$ff,$ee,$60,$30,$10,$00,$8f,$c0,$10
	dc.b	$00,$00,$00,$00,$00,$10,$00,$00,$00,$00,$00

Spr0	dc.l	$72307300,$80008000
	dc.l	$741a7500,$80008000
	dc.l	$76247700,$80008000
	dc.l	$78787900,$80008000
	dc.l	$7af97b00,$80008000
	dc.l	$7cb17d00,$80008000
	dc.l	$7e0b7f00,$80008000
	dc.l	$80928100,$80008000
	dc.l	$82e78300,$80008000
	dc.l	$84508500,$80008000
	dc.l	$86558700,$80008000
	dc.l	$88258900,$80008000
	dc.l	$8a0a8b00,$80008000
	dc.l	$8cd68d00,$80008000
	dc.l	$8e908f00,$80008000
	dc.l	$90429100,$80008000
	dc.l	$92f79300,$80008000
	dc.l	$94209500,$80008000
	dc.l	$96759700,$80008000
	dc.l	$98159900,$80008000
	dc.l	$9a4a9b00,$80008000
	dc.l	$9c669d00,$80008000
	dc.l	$9e449f00,$80008000
	dc.l	$a023a100,$00000000
	dc.l	$a237a300,$80008000
	dc.l	$a487a500,$80008000
	dc.l	$a612a700,$80008000
	dc.l	$a8d4a900,$80008000
	dc.l	$aaf5ab00,$80008000
	dc.l	$ac12ad00,$80008000
	dc.l	$ae76af00,$80008000
	dc.l	$b033b100,$00000000
	dc.l	$b230b300,$80008000
	dc.l	$b412b500,$80008000
	dc.l	$b658b700,$80008000
	dc.l	$b812b900,$80008000
	dc.l	$ba03bb00,$80008000
	dc.l	$bc68bd00,$80008000
	dc.l	$be98bf00,$80008000
	dc.l	$c011c100,$00000000
	dc.l	$c296c300,$80008000
Spr0End	dc.l	$00000000
SPRBlnk	dc.l	0,0,0,0
SclArea	dcb.b	17*(336/8),0
OutSide	dcb.b	32*(320/8),0
MskArea	dcb.b	82*(320/8),0
Screen2	dcb.b	82*(320/8),0
MT_Data	incbin	"mod.happyending"

