; your name(s)
; group #
; lab number
; date
; any collaborators

 .nolist
 .include "m328pdef.inc"
 .list

 .listmac

;Load Word Immediate - Load immediate Word into X,Z,or Z

.macro ldi16 ; [X,Y,Z],k16
	ldi @0H,high(@1)
	ldi @0L,low(@1)
.endmacro

;Load Word - Load Word from SRAM
;  Usage: LDSW [RegH], [RegL], [Addr16]
.macro LDSW
    LDS @0, @2
    LDS @1, @2+1
.endmacro

;STore Imm. byte - Store byte to sram
;  Usage: STI [Addr16],Rt,[k8]
.macro STI ;
	LDI @1,@2
	STS @0,@1
.endmacro

;STore Imm. Word - Load Word to sram
;  Usage: STIW [Addr16],Rt,[k16]
.macro STIW
	STI @0,@1,HIGH(@2)
	STI @0+1,@1,LOW(@2)
.endmacro






;************************************************************
; data space variable section
.dseg
.org SRAM_START 
 srcAddress:	.byte 2 
 dstAddress:	.byte 2
 numBytes:		.byte 1
; ***********************************************************

;************************************************************
; interrupt vector table
 .cseg
 .org 0x0000
 jmp main
;************************************************************


.org INT_VECTORS_SIZE
main:	

// provide test values
STIW srcAddress,R16,0x200
STIW dstAddress,R16,0x220
STI numbytes,R16,0x20
call LOADSRAM


// start code here
//loop init
LDSW XH,XL,srcAddress
LDSW YH,YL,dstAddress
LDS R7, numBytes

mainloop:
 //loop body
 LD R20,X+
 call convertByte // R2 and R3 hold result
 ST Y+,R3
 mov R5,R3
 //call output

 ST Y+,R2
 mov R5,R2
 //call output

 //loop update
 dec R7
brne mainloop

nop




here:	rjmp here	

ASCIILUT: .db "0123456789ABCDEF"

// assumes input on R16
// outputs ascii on r16
ASCIICONVERT:
 LDI16 Z,(ASCIILUT<<1)
 ADD ZL,R16
 CLR R16
 ADC ZH,R16
 LPM R16,Z
 ret


ASCIITEST:
 LDI16 X,0x200
 LDI R17,0xf
 Tloop:
  mov r16,r17
  call asciiconvert
  st X+,R16

  dec R17
  brne Tloop

  //assume byte is in R20
  // outputs are in R3,R2
convertByte:
 mov r16,R20
 SWAP R16
 ANDI R16, 0x0F
 call asciiconvert
 mov R3,R16

 mov r16,r20
 ANDI R16,0x0F
 call asciiconvert
 mov R2,R16

 ret

 // assumes that portd and B are setup
 // accepts values on R5
 // no return output
OUTPUT:
 OUT portd,r5// put data on portd
 call delay
 cbi PORTB,1 //Set B1 low
 call delay
 cbi PORTB,0//set B0 low
 call delay
 sbi PORTB,0 // set B0 HIGH
 call delay
 sbi PORTB,1 //set B1 high
 call delay
 clr R5
 out portd,r5  //clear portd
 call delay
 ret

LOADSRAM:               ;Subroutine to initialize source bytes in SRAM
    	PUSH XH
    	PUSH XL
    	PUSH R16
    	PUSH R17

    	;Load source address into X register
    	LDSW XH, XL, srcAddress
    	LDS R17, numBytes

    	LDI R16, $FF
LS: 	ST X+, R16
    	DEC R16
   		DEC R17
    	BRNE LS

    	POP R17
    	POP R16
    	POP XL
    	POP XH
    	ret

DELAY:
    	PUSH R16
    	PUSH R17
    
    	;Nested loop to take time
      	LDI R16, $FF
L2: 	LDI R17, $FF
L1: 	DEC R17
    	BRNE L1
	DEC R16
	BRNE L2

    	POP R17
    	POP R16
    	ret
