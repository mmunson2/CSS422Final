*-------------------------------------------------------------------------------
* Title      : PUSH_BWT / EA_MODE_ID Development
* Written by : Ihsan Halimun, Camden Brewster, Matthew Munson
* Date       : May 16th 2020
* Description: It's the whole damn thing!
*-------------------------------------------------------------------------------
    ORG    $1000
*-------------------------------------------------------------------------------
*      ________   ___        ________   ________   ________   ___
*     |\   ____\ |\  \      |\   __  \ |\   __  \ |\   __  \ |\  \
*     \ \  \___| \ \  \     \ \  \|\  \\ \  \|\ /_\ \  \|\  \\ \  \
*      \ \  \  ___\ \  \     \ \  \\\  \\ \   __  \\ \   __  \\ \  \
*       \ \  \|\  \\ \  \____ \ \  \\\  \\ \  \|\  \\ \  \ \  \\ \  \____
*        \ \_______\\ \_______\\ \_______\\ \_______\\ \__\ \__\\ \_______\
*         \|_______| \|_______| \|_______| \|_______| \|__|\|__| \|_______|
*-------------------------------------------------------------------------------

START_ADDR   DS.L  1   *User defined memory start address
END_ADDR     DS.L  1   *User defined memory end address

CR    EQU   $0D
LF    EQU   $0A

PRINT_COUNT    DS.W    1    *How many print statements are sitting in the stack
PRINT_OPCODE_LOOP_INDEX  DS.W  1   * The print loop index
STACK_BASE     DS.L    1    *Where we begin putting print calls into stack

LOOP_INC       DS.W    1    * How many words to skip to find the next opcode
LOOP_INDEX     DS.L    1    * The opcode loop's index

DATA1          DS.L    1	* The first line of opcode data
DATA2          DS.L    1	* The second line of opcode data

START:

*-------------------------------------------------------------------------------
*                ________  ________  ________  _______
*               |\   ____\|\   __  \|\   ___ \|\  ___ \
*               \ \  \___|\ \  \|\  \ \  \_|\ \ \   __/|
*                \ \  \    \ \  \\\  \ \  \ \\ \ \  \_|/__
*                 \ \  \____\ \  \\\  \ \  \_\\ \ \  \_|\ \
*                  \ \_______\ \_______\ \_______\ \_______\
*                   \|_______|\|_______|\|_______|\|_______|
*
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
INITIALIZE

* ------ Test Initializations ------


*  MOVE.W    #$4E91, $4000   * JSR Opcode
*  MOVE.W    #$4EB9,$4000      * JSR 1016 (1)
*  MOVE.L    #$00001016, $4002 * JSR 1016 (2)
*  (^ Add 8 to memory address if you want something after this ^)

*  MOVE.W    #$4E71, $4002   * NOP Opcode
*  MOVE.W    #$4E75, $4004   * RTS Opcode
*  MOVE.W    #$5241, $4000   * ADDQ Opcode
*  MOVE.W    #$D240, $4000   * ADD Opcode
*  MOVE.W    #$D5C9, $4000   * ADDA Opcode (ADDA.L A1,A2)
*   MOVE.L    #$60000002, $4000   * BRA Opcode
*   MOVE.L    #$6E000018, $4004   * BRA Opcode
*   MOVE.W    #$6FE6, $4008
*   MOVE.W    #$67E2, $400A

* ------ ASL TEST ------
   MOVE.W     #$E140,$4000	* ASL	#8,D0
   MOVE.W     #$E1D1,$4004	* ASL 	(A1) 
   MOVE.W     #$E1C9,$4008	* ASL 	A1 (ILLEGAL) 

* ------ ASR TEST ------
   MOVE.W     #$E061,$400C	* ASR	D0,D1
   MOVE.W     #$E0D2,$4010	* ASR 	(A2)
   MOVE.W     #$E0CA,$4014	* ASR 	A2 (ILLEGAL)

* ------ LSL TEST ------
   MOVE.W     #$EB49,$4018	* LSL	#5,D1
   MOVE.W     #$E3E3,$401C	* LSL 	-(A3)
   MOVE.W     #$E3CB,$4020	* LSL   A3 (ILLEGAL)

* ------ LSR TEST ------
   MOVE.W     #$E26A,$4024	* LSR	D1,D2
   MOVE.W     #$E2DC,$4028	* LSR 	(A4)+
   MOVE.W     #$E2D2,$402C	* LSR 	A4 (ILLEGAL)

* ------ ROL TEST ------
   MOVE.W     #$E31B,$4030 	* ROL.B	#1,D3
   MOVE.W     #$E55C,$4034	* ROL.W #2,D4
   MOVE.W     #$E79D,$4038	* ROL.L #3,D5
   MOVE.W     #$E7D5,$403C	* ROL 	(A5)
   MOVE.W     #$E7C0,$4040	* ROL 	D0 (ILLEGAL)	

* ------ ROR TEST ------
   MOVE.W     #$E21B,$4044	* ROR.B	#1,D3
   MOVE.W     #$E45C,$4048	* ROR.W #2,D4
   MOVE.W     #$E69D,$404C	* ROR.L	#3,D5
   MOVE.W     #$E6D6,$4050	* ROR 	(A6)
   MOVE.W     #$E6C0,$4054	* ROL 	(D0) (ILLEGAL)
  MOVE.L    #$4000, START_ADDR
  MOVE.L    #$5000, END_ADDR


* ------ Standard Initializations ------
  MOVE.W    #0, PRINT_COUNT
  MOVE.B    #0, MISC_NUMBER

  * JSR GET_INPUT

  MOVEA.L  START_ADDR,A0
  MOVE.L   A0,LOOP_INDEX * Both A0 and LOOP_INDEX contain the start address



*-------------------------------------------------------------------------------
*    OPCODE LOOP
*
*    The disassembler's main loop. Gets the contents of a memory location,
*    sends it to BRANCHBLOCK to be decoded and printed, and checks if we're
*    at the user defined endpoint.
*
* ________________________________________
* Register Use Summary:
*
* D7: CONST - The opcode to decode. Set before BRANCHBLOCK
*
* A0: The current Loop Index, updated before and after BRANCHBLOCK
* A1: How much we should increment the loop index
* A2: Local Variable - used for retrieving DATA
*-------------------------------------------------------------------------------
OPCODE_LOOP

    MOVEA.L LOOP_INDEX,A0
    CMPA.L  END_ADDR, A0  * Check to see if we're done
    BGT     DONE

* ------ Reset Loop Variables ------
    MOVE.W  #0,PRINT_COUNT  * Reset print count to zero
    MOVE.W  #0,LOOP_INC     * Reset loop index increment to zero
    CLR.L   D7

* ------ Get memory at loop index ------
    MOVE.W  (A0),D7

* ------ Fill DATA1 and DATA2 ------
    MOVEA.L  A0,A2
    ADDA     #2,A2        * Increment by 1 word to get the long afterwards
    MOVE.L  (A2),DATA1   * Fill DATA1 with the long after the opcode
    ADDA     #4,A2
    MOVE.L  (A2),DATA2   * Fill DATA2 with the long after DATA1


* ------ Execute Subroutines ------
    JSR     PRINTADDR             * Print the memory address
    JSR     BRANCHBLOCK           * Figure out what opcode this is and print


* ------ Increment Loop ------
    MOVEA.L     LOOP_INDEX,A0
    MOVEA.W     LOOP_INC,A1
    ADDA    A1,A0  * Move the index to the next opcode
    MOVE.L  A0,LOOP_INDEX

    BRA     OPCODE_LOOP

DONE

    * This will eventually RTE to the user input section

    SIMHALT



*-------------------------------------------------------------------------------
*     BRANCHBLOCK
*
*  Decodes the opcode in D7 and jumps to the corresponding opcode subroutine
*
*  Because 1 line is pulled out of memory at a time, it's possible that the
*  next opcode only takes up one word, and it's in the upper word of the
*  opcode long (eg.4E71FFFF is NOP then empty). We must check for single word
*  opcodes before we use any of the data in the lower word of D7.
*________________________________________
* Register Use Summary:
*
* D0: General variable, cleared every use to be safe
* D1:
* D2:
* D3:
* D4: (Keep in mind this is parameter for BWL)
* D5:
* D6:
* D7: CONST - The opcode to decode - NO TOUCH
*________________________________________
* A0:
* A1:
* A2:
* A3:
* A4:
* A5:
* A6:
* A7:
*-------------------------------------------------------------------------------
BRANCHBLOCK

  MOVE.L  SP,STACK_BASE   * Save the position of the stack for later

* ---- DEBUG ----
  CMP.L   #$FFFF,D7
  BEQ   DONE * For debug only! Exit if memory is unset

* ---- CONSTANT OPCODES ----
  CMP.W   #$4E71,D7
  BEQ   NOP

  CMP.W   #$4E75,D7
  BEQ   RTS

* ---- ADDQ ----
  CLR.L   D0
  MOVE.W  D7,D0
  SWAP    D0
  ROL.L   #$04,D0
  AND.B   #$F,D0
  CMP.B   #5,D0
  BEQ     ADDQ

* ---- ADDA ----
  CLR.L   D0
  MOVE.L  D7,D0   *DXXX
  AND.W   #$F000,D0
  CMP.W   #$D000,D0
  BEQ     ADD_ADDA

* ---- BCC ----
  CLR.L   D0
  MOVE.L  D7,D0
  AND.W   #$F000,D0
  CMP.W   #$6000,D0
  BEQ     BCC

* ---- LSX_ASX_ROR ----
  CLR.L   D0
  MOVE.L  D7,D0
  AND.W   #$F000,D0
  CMP.W   #$E000,D0
  BEQ     LSX_ASX_ROX

* ---- 10 BIT OPCODES ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$FFC0,D0   * Mask opcode to get first 10 bits only

  ASR.W   #6,D0
  CMP     #$13A,D0
  BEQ     JSR


* ---- UH OH ----

  BRA     PRINT_ILLEGAL


*-------------------------------------------------------------------------------
* ________   ________   ________   ________   ________   _______
*|\   __  \ |\   __  \ |\   ____\ |\   __  \ |\   ___ \ |\  ___ \
*\ \  \|\  \\ \  \|\  \\ \  \___| \ \  \|\  \\ \  \_|\ \\ \   __/|
* \ \  \\\  \\ \   ____\\ \  \     \ \  \\\  \\ \  \ \\ \\ \  \_|/__
*  \ \  \\\  \\ \  \___| \ \  \____ \ \  \\\  \\ \  \_\\ \\ \  \_|\ \
*   \ \_______\\ \__\     \ \_______\\ \_______\\ \_______\\ \_______\
*    \|_______| \|__|      \|_______| \|_______| \|_______| \|_______|
*
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*   LSX_ASX_ROX
*
*
*-------------------------------------------------------------------------------
LSX_ASX_ROX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$FEC0,D0
  
  CMP.W #$E0C0,D0
  BEQ   ASX

  CMP.W #$E2C0,D0
  BEQ   LSX

  CMP.W #$E6C0,D0
  BEQ   ROX

  MOVE.L    D7,D0      * Reset D0  
  AND.W     #$18,D0  * Isolate bits 4,3

  CMP.W #0,D0
  BEQ   ASX

  CMP.W #8,D0
  BEQ   LSX

  CMP.W #$18,D0
  BEQ   ROX

LSX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$100,D0   * Isolate bit 8
  CMP.W     #0,D0
  BEQ       LSR
  BRA       LSL

LSR
  LEA     PRINT_LSR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

LSL
  LEA     PRINT_LSL,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

ASX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$100,D0   * Isolate bit 8
  CMP.W     #0,D0
  BEQ       ASR
  BRA       ASL

ASR
  LEA     PRINT_ASR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

ASL
  LEA     PRINT_ASL,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

ROX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$100,D0   * Isolate bit 8
  CMP.W     #0,D0
  BEQ       ROR
  BRA       ROL

ROR
  LEA     PRINT_ROR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

ROL
  LEA     PRINT_ROL,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

LSX_ASX_ROX_CONTINUE
  MOVE.L    D7,D0      * Reset D0
  ROR.L     #$06,D0    * Isolate bits 7,6
  AND.L     #3,D0
  CLR.L     D4
  MOVE.B    D0,D4      * Move bits 7,6 to D4 for BWL

  CMP.B     #3,D0
  BEQ       LSX_ASX_ROX_MEM

  JSR PUSH_BWL

  MOVE.L    D7,D0      * Reset D0
  AND.W     #$20,D0    * Isolate bit 5
  CMP.W     #0,D0
  BEQ       LSX_ASX_ROX_SHIFT
  BRA       LSX_ASX_ROX_REGISTER

LSX_ASX_ROX_SHIFT
  MOVE.L  D7,D0             * Reset D0
  AND.L   #$E00,D0           * Get bits 11 - 9
  CMP.L   #0,D0
  BEQ     LSX_ASX_ROX_SHIFT_8  * If 0, shift count is 8

  MOVE.L  #0,DATA1
  ASR.L   #$8,D0
  ASR.L   #$1,D0
  MOVE.L  D0,DATA1

  LEA PRINT_EA_MODE_ID_ABS_DATA,A5 * Print shift count
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  LEA   PRINT_EA_MODE_ID_DN,A5  * Print data register
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  BRA LSX_ASX_ROX_CONTINUE2

LSX_ASX_ROX_SHIFT_8
  MOVE.L  #8,DATA1
  LEA PRINT_EA_MODE_ID_ABS_DATA,A5  * Print shift count 8
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long


  LEA   PRINT_EA_MODE_ID_DN,A5  * Print data register
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  BRA LSX_ASX_ROX_CONTINUE2

LSX_ASX_ROX_REGISTER
  MOVE.L    D7,D0      * Reset D0
  AND.L   #$E00,D0           * Get bits 11 - 9  LEA PRINT_FOURSPACE,A5
  MOVE.L    A5,-(SP)
  ADD.W    #4,PRINT_COUNT
  ASR.L   #$8,D0
  ASR.L   #$1,D0

  MOVE.L  D0,D7
  LEA   PRINT_EA_MODE_ID_DN,A5  * Print data register
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  LEA LSX_ASX_ROX_RESET_D7,A5
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  LEA   PRINT_EA_MODE_ID_DN,A5  * Print data register
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  BRA LSX_ASX_ROX_CONTINUE2

LSX_ASX_ROX_MEM
  MOVE.L D7,D6
  AND.L #$38,D6
  CMP.W #8,D6
  BLE   LSX_ASX_ROX_PRINT_ILLEGAL

  LEA PRINT_FOURSPACE,A5
  MOVE.L    A5,-(SP)
  ADD.W    #4,PRINT_COUNT

  JSR     PUSH_EA_MODE_ID
  BRA LSX_ASX_ROX_CONTINUE2
  
LSX_ASX_ROX_PRINT_ILLEGAL
  ADD #4,SP
  BRA PRINT_ILLEGAL

LSX_ASX_ROX_CONTINUE2
  MOVE.W  #4,LOOP_INC
  BRA   PRINT_OPCODE

LSX_ASX_ROX_RESET_D7
  MOVE.L    D7,D0
  BRA   PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*   BCC
*
*
*-------------------------------------------------------------------------------
BCC
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$0F00,D0  * Isolate bits 11-8
  CMP.W     #0,D0
  BEQ       BRA

  CMP.W     #$E00,D0
  BEQ       BGT

  CMP.W     #$F00,D0
  BEQ       BLE

  CMP.W     #$700,D0
  BEQ       BEQ

  BRA       PRINT_ILLEGAL

BRA
  LEA     PRINT_BRA,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA   BCC_CONTINUE

BGT
  LEA     PRINT_BGT,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA   BCC_CONTINUE

BLE
  LEA     PRINT_BLE,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA   BCC_CONTINUE

BEQ
  LEA     PRINT_BEQ,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA   BCC_CONTINUE

BCC_CONTINUE
  MOVE.L    #0,D0
  MOVE.B    D7,D0      * Reset D0
  CMP.B     #0,D0
  BEQ       BCC_16     * if 16 bit displacement, print the following short

  CMP.B     #$FF,D0    * if 32 bit displacement, print the following long
  BEQ       BCC_32

  MOVE.L    #0,DATA1
  *ROR.L     #4,D0
  MOVE.L    D0,DATA1

  MOVE.W  #2,LOOP_INC

  BRA     BCC_END

BCC_16
  MOVE.L          DATA1,D1
  SWAP            D1              * We only want the upper word
  AND.L           #$0000FFFF,D1   * Bit mask for upper word
  MOVE.L          D1,DATA1

  MOVE.W  #4,LOOP_INC

  BRA     BCC_END

BCC_32
  MOVE.W  #6,LOOP_INC
  BRA     BCC_END

BCC_END
  LEA     PRINT_EA_MODE_ID_ABS_DATA,A5
  MOVE.L  A5, -(SP)
  ADD.W   #4, PRINT_COUNT

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
*   ADD ADDA
*
* Because ADD and ADDA have the same first four bits (1101), we need to do
* some additional branching to differentiate them.
*________________________________________
* Register Use Summary:
*
* D0: General variable, cleared every use to be safe
* D7: CONST - The opcode to decode - NO TOUCH
*
*-------------------------------------------------------------------------------
ADD_ADDA

  CLR.L   D0
  MOVE.L  D7,D0

  ROR.W   #06,D0     * Get bits 7,6 on end
  AND.B   #03,D0     * Isolate bits 7,6
  CMP.B   #03,D0
  BEQ   ADDA

  BRA   ADD          * Else it's ADD
*-------------------------------------------------------------------------------


*-------------------------------------------------------------------------------
*   ADDA
*
*
*-------------------------------------------------------------------------------
ADDA

  MOVE.L  D7,D0         * Reset D0

  LEA     PRINT_ADDA,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  ROR.W   #$6,D0        * Get bits 9,8,7,6 on end byte
  AND.B   #7,D0         * Isolate bits 8,7,6

  CMP.B   #3,D0         * If 8,7,6 == 011
  BEQ     ADDA_W

  CMP.B   #7,D0         * If 8,7,6 == 111
  BEQ     ADDA_L

  BRA     PRINT_ILLEGAL

* ------ Long Opmode ------
ADDA_L

  LEA     PRINT_LONG_DESIGNATOR,A5 * Load the ".L" print subroutine
  MOVE.L  A5, -(SP)       * Put the subroutine onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  BRA     ADDA_CONTINUE

* ------ Word Opmode ------
ADDA_W

  LEA     PRINT_WORD_DESIGNATOR,A5 * Load the ".W" print subroutine
  MOVE.L  A5, -(SP)         * Put the subroutine onto the stack
  ADD.W   #4,PRINT_COUNT    * Increment Print Count by 1 long

  BRA     ADDA_CONTINUE

* ------ Continue ------
ADDA_CONTINUE

* Push the effective address print subroutine onto the stack
  MOVE.L  D7,D6 * Put full opcode into D6 as parameter
  JSR     PUSH_EA_MODE_ID


  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long



* Reset and push the address register print subroutine onto the stack
  MOVE.L D7,D0    * Reset D0

  ASR.L   #$8,D0
  ASR.L   #$1,D0
  AND.B   #$7,D0

  MOVE.B  D0,MISC_NUMBER

  LEA     PRINT_MISC_NUMBER_AS_ADDRESS,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 4 bytes

  BRA   PRINT_OPCODE

*-------------------------------------------------------------------------------
*   ADD
*
*
*-------------------------------------------------------------------------------
ADD

* ------ Print "ADD" ------
  LEA     PRINT_ADD,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

* ------ Print size ------
  MOVE.B   D0,D4            * Move bits 7,6 to D4 for BWL
  JSR      PUSH_BWL

* ------ Reset D0, determine order ------
  MOVE.L  D7,D0
  ROR.W   #08,D0     * Get bit 8 on the end
  AND.W   #1,D0

  * If bit 8 == 0 the order is <ea> + Dn
  * If bit 8 == 1 the order is Dn + <ea>

  CMP.B   #1,D0
  BEQ     ADD_DN_FIRST

* ------ Print order is effective address, data register ------
ADD_EA_FIRST


  * ------ Print the effective address ------
  MOVE.L  D7,D6 * Put full opcode into D6 as parameter
  JSR     PUSH_EA_MODE_ID

  * ------ Print a comma ------
  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  * ------ Determine the register number ------
  MOVE.L  D7,D0
  ROR.W   #08,D0 * Get bits 9, 10, and 11 on the end
  ROR.W   #01,D0 * Get bits 9, 10, and 11 on the end
  AND.W   #7,D0 * Mask against 111 to only get 3 bits

  * ------ Print the register number ------
  MOVE.B  D0,MISC_NUMBER
  LEA     PRINT_MISC_NUMBER_AS_REGISTER,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 4 bytes

  BRA   PRINT_OPCODE


* ------ Print order is data register, effective address ------
ADD_DN_FIRST


  * ------ Determine the register number ------
  MOVE.L  D7,D0
  ROR.W   #08,D0 * Get bits 9, 10, and 11 on the end
  ROR.W   #01,D0 * Get bits 9, 10, and 11 on the end
  AND.W   #7,D0 * Mask against 111 to only get 3 bits

  * ------ Print the register number ------
  MOVE.B  D0,MISC_NUMBER
  LEA     PRINT_MISC_NUMBER_AS_REGISTER,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  * ------ Print a comma ------
  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  * ------ Print the effective address ------
  MOVE.L  D7,D6 * Put full opcode into D6 as parameter
  JSR     PUSH_EA_MODE_ID

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 4 bytes

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
*   ADDQ
*
*
*-------------------------------------------------------------------------------
ADDQ


* ------ Ensure that opcode is valid ------
  MOVE.L  D7,D0
  ROR.W   #$08,D0
  AND.B   #1,D0
  CMP.B   #0,D0             * Check for 0 in 8th bit
  BNE     PRINT_ILLEGAL

* ------ Print "ADDQ" ------
  LEA     PRINT_ADDQ,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

* ------ Print Size ------
  MOVE.L  D7,D0
  ROR.W   #6,D0
  AND.W   #3,D0

  CLR.L   D4
  MOVE.B  D0,D4            * Move bits 7,6 to D4 for BWL
  JSR     PUSH_BWL

* ------ Retrieve Data ------
  MOVE.L  D7,D0             * Reset D0
  ROR.W   #$8, D0           * Get bits 11 - 9
  ROR.W   #$1, D0           * Get bits 11 - 9
  AND.B   #$7, D0           * Clear bit 11


* ADDQ converts 000 to 8 since nobody wants to add 0 to their number
  CMPI.B   #0,D0
  BNE      ADDQ_NOT_ZERO

*Else: D0 is 0, so we convert to 8
  MOVE.B   #8,D0

ADDQ_NOT_ZERO

  MOVE.B  D0,MISC_NUMBER

* ------ Print Data ------
  LEA     PRINT_MISC_NUMBER_AS_DATA,A5
  MOVE.L  A5, -(SP)
  ADD.W   #4, PRINT_COUNT

* ------ Print a comma ------
  LEA     PRINT_COMMA,A5  * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Print Effective Address ------
  MOVE.L  D7,D6 * Put full opcode into D6 as parameter
  JSR     PUSH_EA_MODE_ID


  MOVE.W  #2,LOOP_INC     * Increment the loop counter by 2 bytes
  BRA     PRINT_OPCODE    * Always put this at the end



*-------------------------------------------------------------------------------
*   NOP
*
*   NONSTANDARD OPCODE! Don't base your design off of this :)
*
*-------------------------------------------------------------------------------
NOP

  LEA     STRING_NOP,A1
  MOVE.B  #14,D0
  TRAP    #15

  MOVE.W  #2,LOOP_INC   * Increment the loop counter by 2 bytes

  JSR     PRINT_IMMEDIATE_NEWLINE

  RTS

*-------------------------------------------------------------------------------
*   RTS
*
*   NONSTANDARD OPCODE! Don't base your design off of this :)
*
*-------------------------------------------------------------------------------
RTS

  LEA     STRING_RTS,A1
  MOVE.B  #14,D0
  TRAP    #15

  MOVE.W  #2,LOOP_INC   * Increment the loop counter by 2 bytes

  JSR     PRINT_IMMEDIATE_NEWLINE

  RTS


*-------------------------------------------------------------------------------
*   JSR
*
*
*-------------------------------------------------------------------------------
JSR

  LEA     PRINT_JSR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W           #4,PRINT_COUNT

* ---- Custom Branching Block ----
* Supported Modes: (An), Indirect short, Indirect Long

  CLR.L     D0
  MOVE.B    D7,D0 * Copy opcode into local variable
  AND.B     #$38,D0 * Mask D0 with 0111000 to get MODE bits only
  ASR.B   #3,D0	* Shift the result so D0 ranges between 000 and 111

  CMP.B   #2,D0			*010 -> Address Register   Indirect
  BEQ   JSR_PUSH_EA_MODE_ID_AN_INDIRECT
  CMP.B   #7,D0			*111 -> All Data Operations
  BEQ     JSR_EA_MODE_ELSE

  BRA     PRINT_ILLEGAL


*________________________________________
* Handle Data Branching Logic
* Only short and long indirect allowed
*----------------------------------------
JSR_EA_MODE_ELSE

  CLR.L   D0
  MOVE.B  D7,D0
  AND.B   #7,D0

  CMP.B   #0,D0
  BEQ     JSR_PUSH_EA_MODE_ID_IND_SHORT

  CMP.B   #1,D0
  BEQ     JSR_PUSH_EA_MODE_ID_IND_LONG

  BRA     PRINT_ILLEGAL

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
JSR_PUSH_EA_MODE_ID_AN_INDIRECT
  JSR   PUSH_EA_MODE_ID_AN_INDIRECT
  BRA   JSR_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
JSR_PUSH_EA_MODE_ID_IND_SHORT
  JSR   PUSH_EA_MODE_ID_IND_SHORT
  BRA   JSR_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
JSR_PUSH_EA_MODE_ID_IND_LONG
  JSR   PUSH_EA_MODE_ID_IND_LONG
  BRA   JSR_FINISH

JSR_FINISH

  ADD.W   #2,LOOP_INC     * Increment the loop counter by 1 word

  BRA     PRINT_OPCODE    * Always put this at the end

*-------------------------------------------------------------------------------
*   PRINT OPCODE
*-------------------------------------------------------------------------------

PRINT_OPCODE

  MOVE.L  STACK_BASE,SP * Put the stack back to where it was when we started
  MOVE.W  #0,PRINT_OPCODE_LOOP_INDEX

PRINT_OPCODE_LOOP

  MOVEA.W   PRINT_OPCODE_LOOP_INDEX,A1

  CMPA.W   PRINT_COUNT,A1 * Check if we're done
  BGE     PRINT_OPCODE_LOOP_FINISH

  MOVE.L  -(SP),A2  * Pop the next item on the stack and put it in A1
  JMP     (A2)        * Jump to the routine we stored on the stack

PRINT_OPCODE_LOOP_RETURN * Print methods come back here

  ADD.W    #4,PRINT_OPCODE_LOOP_INDEX

  BRA     PRINT_OPCODE_LOOP

PRINT_OPCODE_LOOP_FINISH

  MOVE.L  STACK_BASE,SP  * Return the stack to normal so we can RTS

  JSR     PRINT_IMMEDIATE_NEWLINE
  RTS

*-------------------------------------------------------------------------------










*-------------------------------------------------------------------------------
*     _______    ________
*    |\  ___ \  |\   __  \
*    \ \   __/| \ \  \|\  \
*     \ \  \_|/__\ \   __  \
*      \ \  \_|\ \\ \  \ \  \
*       \ \_______\\ \__\ \__\
*        \|_______| \|__|\|__|
*
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*
*		PUSH EFFECTIVE ADDRESS MODE IDENTIFIER
*
* Determines the addressing mode of the effective address. Used for opcodes
* with the last five bits dedicated to the effective address.
*
* TODO: Implement a counter for how many prints we've made
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE - low byte of opcode
* D6: PARAMETER - The effective address bits. Assumes bits are shifted into
*                 the lowest 6 bits of the register.
*
* A4: LOCAL VARIABLE - RTS value temporary storage - must be swapped
* A5: LOCAL VARIABLE - Print Label to be pushed to stack
*
*-------------------------------------------------------------------------------
PUSH_EA_MODE_ID


* ---- Input Processing ----

    MOVE.B  D6,D0	* Put opcode in D0
    AND.B   #$38,D0	* Mask D0 with 0111000 to get MODE bits only
    ASR.B   #3,D0	* Shift the result so D0 ranges between 000 and 111


* ---- Branching Block ----

    CMP.B   #0,D0			*000 -> Register
    BEQ     PUSH_EA_MODE_ID_DN
    CMP.B   #1,D0			*001 -> Address Register
    BEQ     PUSH_EA_MODE_ID_AN
    CMP.B   #2,D0			*010 -> Address Register   Indirect
    BEQ     PUSH_EA_MODE_ID_AN_INDIRECT
    CMP.B   #3,D0			*011 -> Address Register  (Indirect)+
    BEQ     PUSH_EA_MODE_ID_AN_POST_INC
    CMP.B   #4,D0			*100 -> Address Register -(Indirect)
    BEQ     PUSH_EA_MODE_ID_AN_PRE_DEC
    CMP.B   #7,D0			*111 -> All Data Operations
    BEQ     PUSH_EA_MODE_ID_ELSE

    BRA     PRINT_ILLEGAL

*________________________________________
* Load Register Print Label
*----------------------------------------
PUSH_EA_MODE_ID_DN
    LEA     PRINT_EA_MODE_ID_DN,A5
    BRA     PUSH_EA_MODE_ID_FINISH

*________________________________________
* Load Address Register Print Label
*----------------------------------------
PUSH_EA_MODE_ID_AN
    LEA     PRINT_EA_MODE_ID_AN,A5
    BRA     PUSH_EA_MODE_ID_FINISH

*________________________________________
* Load (Address Register) Print Label
*----------------------------------------
PUSH_EA_MODE_ID_AN_INDIRECT
    LEA     PRINT_EA_MODE_ID_AN_INDIRECT,A5
    BRA     PUSH_EA_MODE_ID_FINISH

*________________________________________
* Load (Address Register)+ Print Label
*----------------------------------------
PUSH_EA_MODE_ID_AN_POST_INC
    LEA     PRINT_EA_MODE_ID_AN_POST_INC,A5
    BRA     PUSH_EA_MODE_ID_FINISH

*________________________________________
* Load -(Address Register) Print Label
*----------------------------------------
PUSH_EA_MODE_ID_AN_PRE_DEC
    LEA     PRINT_EA_MODE_ID_AN_PRE_DEC,A5
    BRA     PUSH_EA_MODE_ID_FINISH

*________________________________________
* Handle Data Branching Logic
*----------------------------------------
PUSH_EA_MODE_ID_ELSE
    MOVE.B  D6,D0
    AND.B   #7,D0

    CMP.B   #0,D0
    BEQ     PUSH_EA_MODE_ID_IND_SHORT

    CMP.B   #1,D0
    BEQ     PUSH_EA_MODE_ID_IND_LONG

    CMP.B   #4,D0
    BEQ     PUSH_EA_MODE_ID_ABS_DATA

    BRA     PRINT_ILLEGAL

PUSH_EA_MODE_ID_IND_SHORT
    LEA     PRINT_EA_MODE_ID_IND_SHORT,A5
    ADD.W           #4, LOOP_INC * Adjust the Loop increment to skip the data
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_IND_LONG
    LEA     PRINT_EA_MODE_ID_IND_LONG,A5
    ADD.W           #8,LOOP_INC * Adjust the Loop increment to skip the data
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_ABS_DATA
    LEA     PRINT_EA_MODE_ID_ABS_DATA,A5
    ADD.W           #8,LOOP_INC * Adjust the Loop increment to skip the data
    BRA     PUSH_EA_MODE_ID_FINISH

*________________________________________
PUSH_EA_MODE_ID_FINISH
    MOVEA.L         (SP),A4	* Store the value we're going to RTS to
    ADD.L           #4,SP	* Move the stack pointer down to the RTS value
    MOVE.L          A5,-(SP)	* Overwrite the RTS value with the print label
    MOVE.L          A4,-(SP)	* Push the RTS so we can return like normal

    ADD.W           #4,PRINT_COUNT

    RTS

*-------------------------------------------------------------------------------
*                 ________  ___       __   ___
*                |\   __  \|\  \     |\  \|\  \
*                \ \  \|\ /\ \  \    \ \  \ \  \
*                 \ \   __  \ \  \  __\ \  \ \  \
*                  \ \  \|\  \ \  \|\__\_\  \ \  \____
*                   \ \_______\ \____________\ \_______\
*                    \|_______|\|____________|\|_______|
*

*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*
*		PUSH BYTE, WORD, OR LONG
*
* TODO: Implement a counter for how many prints we've made
*________________________________________
* Register Use Summary:
*
* D4: PARAMETER       - The size bits to print
* D7: CONST PARAMETER - The opcode word
*
* A4: LOCAL VARIABLE  - Temp RTS location
* A5: LOCAL VARIABLE  - Label for the print routine to store on the stack
*-------------------------------------------------------------------------------
PUSH_BWL

* ---- Branching Block ----

    CMP.B           #0,D4		*00 -> Byte
    BEQ             PUSH_BWL_BYTE
    CMP.B           #1,D4		*01 -> Word
    BEQ             PUSH_BWL_WORD
    CMP.B           #2,D4		*10 -> Long
    BEQ             PUSH_BWL_LONG

    BRA             PRINT_ILLEGAL

*________________________________________
* Load Byte Print Label
*----------------------------------------
PUSH_BWL_BYTE
    LEA             PRINT_BYTE_DESIGNATOR,A5
    BRA             PUSH_BWL_FINISH
*________________________________________
* Load Word Print Label
*----------------------------------------
PUSH_BWL_WORD
    LEA             PRINT_WORD_DESIGNATOR,A5
    BRA             PUSH_BWL_FINISH

*________________________________________
* Load Long Print Label
*----------------------------------------
PUSH_BWL_LONG
    LEA             PRINT_LONG_DESIGNATOR,A5
    BRA             PUSH_BWL_FINISH

*________________________________________
PUSH_BWL_FINISH

    MOVEA.L         (SP),A4	* Store the value we're going to RTS to
    ADD.L           #4,SP	* Move the stack pointer down to the RTS value
    MOVE.L          A5,-(SP)	* Overwrite the RTS value with the print label
    MOVE.L          A4,-(SP)	* Push the RTS so we can return like normal

    ADD.W           #4,PRINT_COUNT

    RTS


*-------------------------------------------------------------------------------
*     ________   ________   ___   ________    _________
*    |\   __  \ |\   __  \ |\  \ |\   ___  \ |\___   ___\
*    \ \  \|\  \\ \  \|\  \\ \  \\ \  \\ \  \\|___ \  \_|
*     \ \   ____\\ \   _  _\\ \  \\ \  \\ \  \    \ \  \
*      \ \  \___| \ \  \\  \|\ \  \\ \  \\ \  \    \ \  \
*       \ \__\     \ \__\\ _\ \ \__\\ \__\\ \__\    \ \__\
*        \|__|      \|__|\|__| \|__| \|__| \|__|     \|__|
*
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
*
*		PRINT LSR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_LSR
    LEA             STRING_LSR,A1	* Load "LSR" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "LSR "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT LSL
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_LSL
    LEA             STRING_LSL,A1	* Load "LSL" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "LSL "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT ASR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ASR
    LEA             STRING_ASR,A1	* Load "ASR" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "ASR "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT ASL
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ASL
    LEA             STRING_ASL,A1	* Load "ASL" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "ASL "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT ROR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ROR
    LEA             STRING_ROR,A1	* Load "ROR" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "ROR "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT ROL
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ROL
    LEA             STRING_ROL,A1	* Load "ROL" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "ROL"
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT DATA1_WORD
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - DATA1 local copy
*
* D2: LOCAL VARIABLE  - Base in which to print
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_DATA1_LONG
    MOVE.L          DATA1,D1
    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

*-------------------------------------------------------------------------------
*
*		PRINT DATA1_WORD
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - DATA1 local copy
*
* D2: LOCAL VARIABLE  - Base in which to print
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_DATA1_WORD
    MOVE.L          DATA1,D1
    SWAP            D1              * We only want the upper word
    AND             #$0000FFFF,D1   * Bit mask for upper word
    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

*-------------------------------------------------------------------------------
*
*		PRINT BGT
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_BGT
    LEA             STRING_BGT,A1	* Load "BGT" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "BGT "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT BLE
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_BLE
    LEA             STRING_BLE,A1	* Load "BLE" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "BLE "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT BEQ
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_BEQ
    LEA             STRING_BEQ,A1	* Load "BEQ" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "BEQ "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT BRA
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_BRA
    LEA             STRING_BRA,A1	* Load "BRA" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "BRA "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT ADD
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ADD
    LEA             STRING_ADD,A1	* Load "ADD" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "ADD "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT ADDA
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ADDA
    LEA             STRING_ADDA,A1	* Load "ADDA" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "ADDA "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT MISC_NUMBER
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - MISC_NUMBER to be printed
*
* D2: LOCAL VARIABLE  - Base of MISC_NUMBER
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MISC_NUMBER
    CLR.L   D1

    MOVE.B  #15,D0
    MOVE.B  MISC_NUMBER,D1
    MOVE.B  #10,D2
    TRAP #15

    BRA     PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT MISC_NUMBER_AS_ADDRESS
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - MISC_NUMBER to be printed
*
* D2: LOCAL VARIABLE  - Base of MISC_NUMBER
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MISC_NUMBER_AS_ADDRESS

    LEA             STRING_A,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L   D0
    CLR.L   D1
    CLR.L   D2

    MOVE.B  #15,D0
    MOVE.B  MISC_NUMBER,D1
    MOVE.B  #10,D2
    TRAP #15

    BRA     PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT MISC_NUMBER_AS_REGISTER
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - MISC_NUMBER to be printed
*
* D2: LOCAL VARIABLE  - Base of MISC_NUMBER
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MISC_NUMBER_AS_REGISTER

    LEA             STRING_D,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L   D0
    CLR.L   D1
    CLR.L   D2

    MOVE.B  #15,D0
    MOVE.B  MISC_NUMBER,D1
    MOVE.B  #10,D2
    TRAP #15

    BRA     PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT MISC_NUMBER_AS_DATA
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - MISC_NUMBER to be printed
*
* D2: LOCAL VARIABLE  - Base of MISC_NUMBER
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MISC_NUMBER_AS_DATA

    LEA             STRING_POUND,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L   D0
    CLR.L   D1
    CLR.L   D2

    MOVE.B  #15,D0
    MOVE.B  MISC_NUMBER,D1
    MOVE.B  #10,D2
    TRAP #15

    BRA     PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT ADDQ
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_ADDQ
    LEA             STRING_ADDQ,A1	* Load "ADDQ" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT BYTE DESIGNATOR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - low byte of opcode
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_BYTE_DESIGNATOR
    LEA             STRING_BYTE_DESIGNATOR,A1
    MOVE.B          #14,D0
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT WORD DESIGNATOR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - low byte of opcode
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_WORD_DESIGNATOR
    LEA             STRING_WORD_DESIGNATOR,A1
    MOVE.B          #14,D0
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT LONG DESIGNATOR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - low byte of opcode
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_LONG_DESIGNATOR
    LEA             STRING_LONG_DESIGNATOR,A1
    MOVE.B          #14,D0
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - Dn REGISTER
*
* Prints "Dx, " where x ranges between 0 and 7. This is determined by masking
* the last four bits of the current opcode stored in D7.
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_DN
    LEA             STRING_D,A1		* Load "D" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print "D"

    CLR.L           D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed MISC_NUMBER
    TRAP            #15			* Print the register MISC_NUMBER

    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - ADDRESS REGISTER
*
* Prints "Ax, " where x ranges between 0 and 7. This is determined by masking
* the last four bits of the current opcode stored in D7.
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_AN
    LEA             STRING_A,A1
    MOVE.B          #14,D0
    TRAP            #15


    CLR.L           D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed MISC_NUMBER
    TRAP            #15			* Print the register MISC_NUMBER

    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - (ADDRESS REGISTER)
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register MISC_NUMBER to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_AN_INDIRECT
    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_A,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L           D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed MISC_NUMBER
    TRAP            #15			* Print the register MISC_NUMBER

    LEA             STRING_RIGHT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - (ADDRESS REGISTER)+
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_AN_POST_INC
    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_A,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L           D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed MISC_NUMBER
    TRAP            #15			* Print the register MISC_NUMBER

    LEA             STRING_RIGHT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_PLUS,A1
    MOVE.B          #14,D0
    TRAP            #15

    BRA             PRINT_OPCODE_LOOP_RETURN



*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - -(ADDRESS REGISTER)
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_AN_PRE_DEC
    LEA             STRING_MINUS,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_A,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L           D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed MISC_NUMBER
    TRAP            #15			* Print the register MISC_NUMBER

    LEA             STRING_RIGHT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    BRA             PRINT_OPCODE_LOOP_RETURN





*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - WORD DATA
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_IND_SHORT
    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    MOVE.L          DATA1,D1
    SWAP            D1              * We only want the upper word
    AND             #$0000FFFF,D1   * Bit mask for upper word

    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - LONG DATA
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_IND_LONG
    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    MOVE.L          DATA1,D1
    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - ABSOLUTE
*
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
* D1: LOCAL VARIABLE  - Dn Register number to display
* D7: CONST PARAMETER - The opcode word
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_EA_MODE_ID_ABS_DATA
    LEA             STRING_POUND,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    MOVE.L          DATA1,D1
    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT JSR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_JSR
    LEA             STRING_JSR,A1	* Load "JSR" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT FOURSPACE
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_FOURSPACE
    LEA             STRING_FOURSPACE,A1 * Load four spaces into A1
    MOVE.B          #14,D0              * Set trap task to String
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT COMMA
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_COMMA
    LEA             STRING_COMMA,A1 * Load the comma into A1
    MOVE.B          #14,D0              * Set trap task to String
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT ILLEGAL
*
* Incomplete implementation - final version will depend on opcode logic.
* Currently clears stack entirely, future implementation may need to keep
* some RTS addresses
*
* D7: RTS address (opcode shouldn't be necessary at this point)
*-------------------------------------------------------------------------------
PRINT_ILLEGAL       * INCOMPLETE *
    MOVE.L          (SP),D7

    MOVE.L          #0,SP
    LEA             STRING_ILLEGAL,A1
    MOVE.B          #13,D0
    TRAP            #15

    MOVE.L          D7,(SP)

    MOVE.W  #2,LOOP_INC     * Increment the loop counter by 4 bytes


    RTS

*--------------------------------------------------------------------------------
* PRINTADDR SUBROUTINE
*
* Prints the memory address and some blank spaces before the disassembled
* instruction is appended.
*
* Registers Used:
*	D0: Trap task designator
*	D1: Memory address to display
* D2: Trap task numerical base (Hex = 16)
*
*
* A1: Data memory location
*
*
PRINTADDR

	MOVE.L   LOOP_INDEX,D1 * Print the loop index (memory location)
	MOVEQ    #15,D0
	MOVEQ    #16,D2

	TRAP     #15

	LEA	     STRING_FOURSPACE,A1 * Print some spaces
	MOVEQ	   #14,D0
	TRAP	   #15

	RTS

*--------------------------------------------------------------------------------
* PRINT_IMMEDIATE_NEWLINE
*
* CANNOT PUSH TO STACK - Used to put a newline after each opcode
*
* Registers Used:
*	D0: Trap task designator
*	D1: Memory address to display
*
* A1: Data memory location
*
PRINT_IMMEDIATE_NEWLINE

  LEA	     STRING_NEWLINE,A1
	MOVEQ	   #14,D0
	TRAP	   #15

  RTS

*-----------------------------------------------------------------
* GET_INPUT
*
* Called before anything else, clears what it uses
*-----------------------------------------------------------------
GET_INPUT

    MOVE.L  #0,START_ADDR
    MOVE.L  #0,END_ADDR

    CLR.L   D3

    LEA     STRING_ENTER_START,A1
    MOVE.B  #13,D0
    TRAP    #15

    MOVEA   #0,A1
    MOVE.B  #2,D0
    TRAP    #15

    JSR     STRING_TO_HEX
    MOVE.L  D3,START_ADDR

    CLR.L   D3

    LEA     STRING_ENTER_END,A1
    MOVE.B  #13,D0
    TRAP    #15

    MOVEA   #0,A1
    MOVE.B  #2,D0
    TRAP    #15

    JSR     STRING_TO_HEX
    MOVE.L  D3,END_ADDR

    MOVE.L  START_ADDR,D2
    CMP.L   D2,D3
    BLT     OUT_OF_ORDER

    CLR.L     D0
    CLR.L     D1
    CLR.L     D2
    CLR.L     D3

    RTS

OUT_OF_ORDER

    LEA     STRING_OUT_OF_ORDER,A1
    MOVE.B  #13,D0
    TRAP    #15

    JMP     GET_INPUT

STRING_TO_HEX

    CLR.L   D2
    CMP.B   #0,D1
    BEQ     STH_END
    JSR     STH_SET_VALUE
    JMP     STRING_TO_HEX

STH_UPDATE

    SUB.W   #1,D1
    ADDA.W  #1,A1
    RTS

STH_END     RTS

STH_BAD_INPUT

    LEA     STRING_INVALID_INPUT,A1
    MOVE.B  #13,D0
    TRAP    #15

    MOVEA   #0,A1
    MOVE.B  #2,D0
    TRAP    #15

    RTS

STH_SET_VALUE

    MOVE.L  #$0,D2
    CMP.B   #$30,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$1,D2
    CMP.B   #$31,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$2,D2
    CMP.B   #$32,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$3,D2
    CMP.B   #$33,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$4,D2
    CMP.B   #$34,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$5,D2
    CMP.B   #$35,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$6,D2
    CMP.B   #$36,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$7,D2
    CMP.B   #$37,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$8,D2
    CMP.B   #$38,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$9,D2
    CMP.B   #$39,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$A,D2
    CMP.B   #$41,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$B,D2
    CMP.B   #$42,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$C,D2
    CMP.B   #$43,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$D,D2
    CMP.B   #$44,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$E,D2
    CMP.B   #$45,(A1)
    BEQ     STH_SHIFT_BITS

    MOVE.L  #$F,D2
    CMP.B   #$46,(A1)
    BEQ     STH_SHIFT_BITS

    JMP     STH_BAD_INPUT

STH_SHIFT_BITS

    CMP.B   #1,D1
    BEQ     STH_INCREASE_VALUE

    ROL.L   #4,D2
    CMP.B   #2,D1
    BEQ     STH_INCREASE_VALUE

    ROL.L   #4,D2
    CMP.B   #3,D1
    BEQ     STH_INCREASE_VALUE

    ROL.L   #4,D2
    CMP.B   #4,D1
    BEQ     STH_INCREASE_VALUE

    ROL.L   #4,D2
    CMP.B   #5,D1
    BEQ     STH_INCREASE_VALUE

    ROL.L   #4,D2
    CMP.B   #6,D1
    BEQ     STH_INCREASE_VALUE

    JMP     STH_BAD_INPUT

STH_INCREASE_VALUE

    ADD.L   D2,D3
    JMP     STH_UPDATE

* END OF GET_INPUT -----------------------------------------------

    SIMHALT

*-------------------------------------------------------------------------------
*                ________  ________  _________  ________
*               |\   ___ \|\   __  \|\___   ___\\   __  \
*               \ \  \_|\ \ \  \|\  \|___ \  \_\ \  \|\  \
*                \ \  \ \\ \ \   __  \   \ \  \ \ \   __  \
*                 \ \  \_\\ \ \  \ \  \   \ \  \ \ \  \ \  \
*                  \ \_______\ \__\ \__\   \ \__\ \ \__\ \__\
*                   \|_______|\|__|\|__|    \|__|  \|__|\|__|
*
*-------------------------------------------------------------------------------


* Data for GET_INPUT
STRING_ENTER_START      DC.B    'Please enter a start address, eg. 4A6C',0
STRING_ENTER_END        DC.B    'Please enter a end address, eg. 5D3F',0
STRING_INVALID_INPUT    DC.B    'INVALID INPUT, must be a valid EASy68k hexidecimal memory address',0
STRING_OUT_OF_ORDER     DC.B    'Start address must be less than end address',0


STRING_ILLEGAL              DC.B    'ILLEGAL',0
STRING_BYTE_DESIGNATOR      DC.B    '.B ',0
STRING_WORD_DESIGNATOR      DC.B    '.W ',0
STRING_LONG_DESIGNATOR      DC.B    '.L ',0
STRING_D                    DC.B    'D',0
STRING_A                    DC.B    'A',0
STRING_COMMA                DC.B    ',',0
STRING_LEFT_PAREN           DC.B    '(',0
STRING_RIGHT_PAREN          DC.B    ')',0
STRING_PLUS                 DC.B    '+',0
STRING_MINUS                DC.B    '-',0
STRING_POUND                DC.B    '#',0
STRING_DOLLAR               DC.B    '$',0

STRING_FOURSPACE            DC.B    '    ',0
STRING_NEWLINE              DC.B    '',CR,LF,0

STRING_ASR                  DC.B    'ASR',0
STRING_ASL                  DC.B    'ASL',0
STRING_LSR                  DC.B    'LSR',0
STRING_LSL                  DC.B    'LSL',0
STRING_ROR                  DC.B    'ROR',0
STRING_ROL                  DC.B    'ROL',0
STRING_NOP                  DC.B    'NOP',0
STRING_RTS                  DC.B    'RTS',0
STRING_ADDQ                 DC.B    'ADDQ',0
STRING_ADD                  DC.B    'ADD',0
STRING_ADDA                 DC.B    'ADDA',0
STRING_BEQ                  DC.B    'BEQ ',0
STRING_BLE                  DC.B    'BLE ',0
STRING_BRA                  DC.B    'BRA ',0
STRING_BGT                  DC.B    'BGT ',0
STRING_JSR                  DC.B    'JSR    ',0

MISC_NUMBER  DS.B    1    * MISC_NUMBER to be printed
MISC_OPCODE  DS.W    1
MISC_REGISTER DS.B   1



    END    START







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
