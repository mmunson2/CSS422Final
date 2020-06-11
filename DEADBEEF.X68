*-------------------------------------------------------------------------------
* Title      : PUSH_BWT / EA_MODE_ID Development
* Written by : Ihsan Halimun, Camden Brewster, Matthew Munson
* Created    : May 16th 2020
* Last Edited: June 10th 2020
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

* How many print statements are sitting in the stack:
PRINT_COUNT              DS.W    1

PRINT_OPCODE_LOOP_INDEX  DS.W    1   * The print loop index
STACK_BASE               DS.L    1   * Where the print calls start

LOOP_INC       DS.W    1    * How many words to skip to find the next opcode
LOOP_INDEX     DS.L    1    * The opcode loop's index


DATA1          DS.L    1	* The first line of opcode data
DATA1_IN_USE   DS.W    1  * Boolean: Whether or not DATA1 is being used

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
* ------ ASL TEST ------
   MOVE.W     #$E940,$413A	* ASL	#8,D0
   MOVE.W     #$E1D1,$413C	* ASL 	(A1)
   MOVE.W     #$E1C9,$413E	* ASL 	A1 (ILLEGAL)

* ------ ASR TEST ------
   MOVE.W     #$E061,$4140	* ASR	D0,D1
   MOVE.W     #$E0D2,$4142	* ASR 	(A2)
   MOVE.W     #$E0CA,$4144	* ASR 	A2 (ILLEGAL)

* ------ LSL TEST ------
   MOVE.W     #$EB49,$4146	* LSL	#5,D1
   MOVE.W     #$E3E3,$4148	* LSL 	-(A3)
   MOVE.W     #$E3CB,$414A	* LSL   A3 (ILLEGAL)

* ------ LSR TEST ------
   MOVE.W     #$E26A,$414C	* LSR	D1,S2
   MOVE.W     #$E2DC,$414E	* LSR 	(A4)+
   MOVE.W     #$E0D2,$4150	* LSR 	A4 (ILLEGAL)

* ------ ROL TEST ------
   MOVE.W     #$E31B,$4152 	* ROL.B	#1,D3
   MOVE.W     #$E55C,$4154	* ROL.W #2,D4
   MOVE.W     #$E79D,$4156	* ROL.L #3,D5
   MOVE.W     #$E7D5,$4158	* ROL 	(A5)
   MOVE.W     #$E7C0,$415A	* ROL 	D0 (ILLEGAL)

* ------ ROR TEST ------
   MOVE.W     #$E21B,$415C	* ROR.B	#1,D3
   MOVE.W     #$E45C,$4160	* ROR.W #2,D4
   MOVE.W     #$E69D,$4162	* ROR.L	#3,D5
   MOVE.W     #$E6D6,$4164	* ROR 	(A6)
   MOVE.W     #$E6C0,$4166	* ROL 	(D0) (ILLEGAL)
* ------ Standard Initializations ------
  MOVE.W    #0, PRINT_COUNT
  MOVE.B    #0, MISC_NUMBER
  MOVE.W    #0, LINE_COUNT

  * Begin the user input loop
  JSR GET_INPUT

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
    CMP.L   END_ADDR,A0  * Check to see if we're done
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

    MOVE.W  #0,DATA1_IN_USE  * Reset data boolean
    MOVE.B  #0,MISC_NUMBER   * Reset MISC_NUMBER
    MOVE.B  #0,MISC_REGISTER * Reset MISC_REGISTER

* ------ Execute Subroutines ------
    JSR     PRINTADDR             * Print the memory address
    JSR     BRANCHBLOCK           * Figure out what opcode this is and print


* ------ Increment Loop ------
    MOVEA.L     LOOP_INDEX,A0
    MOVEA.W     LOOP_INC,A1
    ADDA    A1,A0  * Move the index to the next opcode
    MOVE.L  A0,LOOP_INDEX


* ------ Check for pause ------
    MOVEA.L   #0,A2
    MOVEA.W   LINE_COUNT,A2
    ADDA.W    #1,A2
    MOVE.W    A2,LINE_COUNT

    CMP.W     #30,A2
    BGE       OPCODE_LOOP_PAUSE


    BRA     OPCODE_LOOP_CONTINUE

OPCODE_LOOP_PAUSE
    JSR     PAUSE_CONSOLE
    MOVE.W  #0, LINE_COUNT

OPCODE_LOOP_CONTINUE
    BRA     OPCODE_LOOP

DONE

    JSR     PAUSE_CONSOLE
    BRA     QUERY_CONTINUE

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

* ---- EMPTY MEMORY ----
  CMP.L   #$FFFF,D7
  BEQ     PRINT_NON_OPCODE_DATA

* ---- CONSTANT OPCODES ----
  CMP.W   #$4E71,D7
  BEQ     NOP

  CMP.W   #$4E75,D7
  BEQ     RTS

* ------ MOVE / MOVEA ------
  CLR.L   D0
  MOVE.W  D7,D0

  ROL.L   #$02,D0 * Move the first two bits into the upper word
  SWAP    D0      * Swap the upper word and the lower word

  CMP.W   #0,D0
  BEQ     MOVE_MOVEA

* ------ MOVEQ ------
  CLR.L   D0
  CLR.L   D1
  MOVE.W  D7,D0

  ROR.W   #$8,D0 * Check bit 8 to make sure it's zero
  MOVE.W  D0,D1 * D1 is where we'll do the mask
  ANDI.W  #1,D1 * Mask 1

  CMP.W   #0,D1
  BNE     BRANCHBLOCK_MOVEQ_END

  ROR.W   #$4,D0 * Check bits 12-15 for 0111
  AND.W   #$F,D0
  CMP.B   #$7,D0
  BEQ     MOVEQ

BRANCHBLOCK_MOVEQ_END * Go here if it's not MOVEQ

* ------ MOVEM ------
  CLR.L   D0
  MOVE.W  D7,D0

  AND.W   #$FB80,D0 * Mask 1111 1011 1000 0000
  CMP.W   #$4880,D0

  BEQ     MOVEM

* ---- NOT ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$FF00,D0
  CMP.W   #$4600,D0
  BEQ     NOT

* ---- LEA ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$F1C0,D0
  CMP.W   #$41C0,D0
  BEQ     LEA

* ---- ADDQ ----
  CLR.L   D0
  MOVE.W  D7,D0
  SWAP    D0
  ROL.L   #$04,D0
  AND.B   #$F,D0
  CMP.B   #5,D0
  BEQ     ADDQ

* ---- ADDA / ADD ----
  CLR.L   D0
  MOVE.W  D7,D0   *DXXX
  AND.W   #$F000,D0
  CMP.W   #$D000,D0
  BEQ     ADD_ADDA

* ---- SUB ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$F000,D0
  CMP.W   #$9000,D0
  BEQ     SUB

* ---- OR ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$F000,D0
  CMP.W   #$8000,D0
  BEQ     OR

* ---- AND ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$F000,D0
  CMP.W   #$C000,D0
  BEQ     AND

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

* ---- JSR ----
  CLR.L   D0
  MOVE.W  D7,D0
  AND.W   #$FFC0,D0   * Mask opcode to get first 10 bits only

  ASR.W   #6,D0
  CMP     #$13A,D0
  BEQ     JSR

* ---- Data is not recognized as opcode ----

  BRA     PRINT_NON_OPCODE_DATA


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
* LEA
*
* Load Effective address
*
* "LEA" -> "    " -> <ea> -> "," -> An
*
* Effective address does not allow Dn, An, (An)+, -(An)
*-------------------------------------------------------------------------------
LEA

  * ------ Print "LEA" ------
  LEA     PRINT_LEA,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  * ------ Print some spaces ------
  LEA     PRINT_FOURSPACE,A5    * Load the print subroutine into temp
  MOVE.L  A5, -(SP)             * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  * ------ Dn,An,(An)+,-(An) are not allowed ------
  CLR.L   D0
  MOVE.B  D7,D0	* Put opcode in D0
  AND.B   #$38,D0	* Mask D0 with 0111000 to get MODE bits only
  ASR.B   #3,D0	* Shift the result so D0 ranges between 000 and 111

  CMP.B   #0,D0			*000 -> Register
  BEQ     PRINT_ILLEGAL
  CMP.B   #1,D0			*001 -> Address Register
  BEQ     PRINT_ILLEGAL
  CMP.B   #3,D0			*011 -> Address Register  (Indirect)+
  BEQ     PRINT_ILLEGAL
  CMP.B   #4,D0			*100 -> Address Register -(Indirect)
  BEQ     PRINT_ILLEGAL

  * ------ Print the effective address ------
  MOVE.L  D7,D6 * Put full opcode into D6 as parameter
  JSR     PUSH_EA_MODE_ID

* ------ Print a comma ------
  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Get Destination Address ------
  MOVE.L    D7,D0
  ROR.W     #$8,D0 * Get the three register bits
  ROR.W     #$1,D0
  AND.W     #$7,D0 * Mask 111

  MOVE.B    D0,MISC_NUMBER

* ------ Print Destination Address ------
  LEA       PRINT_MISC_NUMBER_AS_ADDRESS,A5
  MOVE.L    A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W     #4,PRINT_COUNT


  ADD.W  #2,LOOP_INC     * Increment the loop counter by 4 bytes

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
* NOT
*
* "NOT" -> <.Size> -> <ea>
*
* Effective address does not allow An
*-------------------------------------------------------------------------------
NOT

* ------ Print "NOT" ------
  LEA     PRINT_NOT,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  * ------ Print size ------
    CLR.L   D0
    MOVE.L  D7,D0

    ROR.W   #06,D0     * Get bits 7,6 on end
    AND.B   #03,D0     * Isolate bits 7,6

    MOVE.B   D0,D4      * Move bits 7,6 to D4 for BWL
    JSR      PUSH_BWL


  * ------ An is not allowed ------
  CLR.L   D0
  MOVE.B  D7,D0	* Put opcode in D0
  AND.B   #$38,D0	* Mask D0 with 0111000 to get MODE bits only
  ASR.B   #3,D0	* Shift the result so D0 ranges between 000 and 111

  CMP.B   #1,D0			*001 -> Address Register
  BEQ     PRINT_ILLEGAL

  * ------ Print the effective address ------
  MOVE.L  D7,D6 * Put full opcode into D6 as parameter
  JSR     PUSH_EA_MODE_ID

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 4 bytes

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
* AND
*
*-------------------------------------------------------------------------------
AND

* ------ Print "AND" ------
  LEA     PRINT_AND,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

* ------ Print size ------
  CLR.L    D0
  MOVE.L   D7,D0

  ROR.W    #06,D0     * Get bits 7,6 on end
  AND.B    #03,D0     * Isolate bits 7,6

  MOVE.B   D0,D4     * Move bits 7,6 to D4 for BWL
  JSR      PUSH_BWL

* ------ Reset D0, determine order ------
  MOVE.L  D7,D0
  ROR.W   #08,D0     * Get bit 8 on the end
  AND.W   #1,D0

  * If bit 8 == 0 the order is <ea> AND Dn
  * If bit 8 == 1 the order is Dn AND <ea>

  CMP.B   #1,D0
  BEQ     AND_DN_FIRST

* ------ Print order is effective address, data register ------
AND_EA_FIRST

  * ------ An is not allowed ------
  CLR.L   D0
  MOVE.B  D7,D0	* Put opcode in D0
  AND.B   #$38,D0	* Mask D0 with 0111000 to get MODE bits only
  ASR.B   #3,D0	* Shift the result so D0 ranges between 000 and 111

  CMP.B   #1,D0			*001 -> Address Register
  BEQ     PRINT_ILLEGAL

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
AND_DN_FIRST


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
* OR
*
*
*-------------------------------------------------------------------------------
OR

* ------ Print "OR" ------
  LEA     PRINT_OR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

* ------ Print size ------
  CLR.L   D0
  MOVE.L  D7,D0

  ROR.W   #06,D0     * Get bits 7,6 on end
  AND.B   #03,D0     * Isolate bits 7,6

  MOVE.B   D0,D4            * Move bits 7,6 to D4 for BWL
  JSR      PUSH_BWL

* ------ Reset D0, determine order ------
  MOVE.L  D7,D0
  ROR.W   #08,D0     * Get bit 8 on the end
  AND.W   #1,D0

  * If bit 8 == 0 the order is <ea> OR Dn
  * If bit 8 == 1 the order is Dn OR <ea>


  CMP.B   #1,D0
  BEQ     OR_DN_FIRST

* ------ Print order is effective address, data register ------
OR_EA_FIRST

  * ------ An is not allowed ------
  CLR.L   D0
  MOVE.B  D7,D0	* Put opcode in D0
  AND.B   #$38,D0	* Mask D0 with 0111000 to get MODE bits only
  ASR.B   #3,D0	* Shift the result so D0 ranges between 000 and 111

  CMP.B   #1,D0			*001 -> Address Register
  BEQ     PRINT_ILLEGAL

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
OR_DN_FIRST


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
* SUB
*
*
*-------------------------------------------------------------------------------
SUB

* ------ Print "SUB" ------
  LEA     PRINT_SUB,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

* ------ Print size ------
  CLR.L   D0
  MOVE.L  D7,D0

  ROR.W   #06,D0     * Get bits 7,6 on end
  AND.B   #03,D0     * Isolate bits 7,6

  MOVE.B   D0,D4            * Move bits 7,6 to D4 for BWL
  JSR      PUSH_BWL

* ------ Reset D0, determine order ------
  MOVE.L  D7,D0
  ROR.W   #08,D0     * Get bit 8 on the end
  AND.W   #1,D0

  * If bit 8 == 0 the order is Dn - <ea>
  * If bit 8 == 1 the order is <ea> - Dn

  CMP.B   #0,D0
  BEQ     SUB_DN_FIRST

* ------ Print order is effective address, data register ------
SUB_EA_FIRST


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
SUB_DN_FIRST


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
* MOVEM
*
*
*-------------------------------------------------------------------------------
MOVEM

* ------ Check for ILLEGAL ------
* Bits 7-9 must equal 001
  CLR.L   D0
  MOVE.W  D7,D0

  ROR.W   #7,D0 * Shift to bit 7
  AND.W   #7,D0 * Mask 111

  CMP.B   #1,D0
  BNE     PRINT_ILLEGAL


* ------ Put List Mask in MISC_OPCODE ------
  MOVE.L    DATA1,D0
  SWAP      D0
  MOVE.W    D0,MISC_OPCODE

* ------ Shift so DATA1 is standard ------
* The Effective Address Subroutine expects data in DATA1
* So we've moved the List Mask to MISC_OPCODE
* and shifted everything back 1 word so it fits nicely

  MOVE.L    DATA2,D1
  SWAP      D1

  MOVE.W    D1,D0
  MOVE.L    D0,DATA1

* ------ Print "MOVEM" ------

  LEA     PRINT_MOVEM,A5
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Get Size Bit ------
  CLR.L   D0
  MOVE.W  D7,D0

  ROR.W   #6,D0 * Bit 6 is size bit
  AND.W   #1,D0 * Mask 0001

* ------ Size Branching ------
  CMP.B   #0,D0 * 0 = Word
  BEQ     MOVEM_SIZE_WORD
  BNE     MOVEM_SIZE_LONG

* ------ Print ".L" ------
MOVEM_SIZE_LONG

  LEA     PRINT_LONG_DESIGNATOR,A5 * Load the ".L" print subroutine
  MOVE.L  A5, -(SP)       * Put the subroutine onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  BRA   MOVEM_SIZE_CONTINUE

* ------ Print ".W" ------
MOVEM_SIZE_WORD

  LEA     PRINT_WORD_DESIGNATOR,A5 * Load the ".W" print subroutine
  MOVE.L  A5, -(SP)         * Put the subroutine onto the stack
  ADD.W   #4,PRINT_COUNT    * Increment Print Count by 1 long

  BRA   MOVEM_SIZE_CONTINUE

MOVEM_SIZE_CONTINUE

* ------ Get the direction bit ------
  CLR.L   D0
  MOVE.W  D7,D0

  ROR.W   #8,D0   * Get bit 10
  ROR.W   #2,D0

  AND.W   #1,D0   * Mask 0000 0001

  CMP.B   #1,D0
  BEQ     MOVEM_MEM2REG * If direction bit is 1, do memory -> register(s)

  BRA     MOVEM_REG2MEM * else, do register(s) -> memory


*-------------------------------------------------------------------------------
* MOVEM_MEM2REG
*
* • Do modified EA_MODE first
*   • (An), (An)+, (xxx).W, (xxx).L only!
* • Then push MOVEM register print
*-------------------------------------------------------------------------------
MOVEM_MEM2REG


* ---- Custom Branching Block ----
  CLR.L     D0
  CLR.L     D6
  MOVE.B    D7,D0 * Copy opcode into local variable
  MOVE.W    D7,D6

  AND.B     #$38,D0 * Mask D0 with 0111000 to get MODE bits only
  ASR.B     #3,D0	* Shift the result so D0 ranges between 000 and 111
  MOVE.B    D0,D1 * Save result for later.

  CMP.B     #2,D0
  BEQ       MOVEM_MEM2REG_AN_IND
  CMP.B     #3,D0
  BEQ       MOVEM_MEM2REG_POST_INC
  CMP.B     #7,D0
  BEQ       MOVEM_MEM2REG_ELSE

  BRA       PRINT_ILLEGAL

MOVEM_MEM2REG_ELSE

  CLR.L   D0
  MOVE.B  D7,D0
  AND.B   #7,D0

  CMP.B   #0,D0
  BEQ     MOVEM_MEM2REG_IND_SHORT
  CMP.B   #1,D0
  BEQ     MOVEM_MEM2REG_IND_LONG

  BRA     PRINT_ILLEGAL

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_MEM2REG_AN_IND

  JSR     PUSH_EA_MODE_ID_AN_INDIRECT
  BRA     MOVEM_MEM2REG_EA_FINISH
*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_MEM2REG_POST_INC

  JSR     PUSH_EA_MODE_ID_AN_POST_INC
  BRA     MOVEM_MEM2REG_EA_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_MEM2REG_IND_SHORT

  JSR   PUSH_EA_MODE_ID_IND_SHORT
  BRA   MOVEM_MEM2REG_EA_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_MEM2REG_IND_LONG

  JSR   PUSH_EA_MODE_ID_IND_LONG
  BRA     MOVEM_MEM2REG_EA_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_MEM2REG_EA_FINISH

  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  LEA     PRINT_SPACE,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  LEA     PRINT_MOVEM_STANDARD,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long


  ADD.W  #4,LOOP_INC     * Increment the loop counter by 2 bytes

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
* MOVEM_REG2MEM
*
* • Push MOVEM register print first
* • Then do modified EA_MODE
*     • (An), -(An), (xxx).W, (xxx.L) only!
*
*-------------------------------------------------------------------------------
MOVEM_REG2MEM


  * ---- Custom Branching Block ----
    CLR.L     D0
    CLR.L     D6
    MOVE.B    D7,D0 * Copy opcode into local variable
    MOVE.W    D7,D6

    AND.B     #$38,D0 * Mask D0 with 0111000 to get MODE bits only
    ASR.B     #3,D0	* Shift the result so D0 ranges between 000 and 111

    CMP.B     #2,D0
    BEQ       MOVEM_REG2MEM_AN_IND
    CMP.B     #4,D0
    BEQ       MOVEM_REG2MEM_PRE_DEC
    CMP.B     #7,D0
    BEQ       MOVEM_REG2MEM_ELSE

    BRA       PRINT_ILLEGAL

MOVEM_REG2MEM_ELSE

    CLR.L   D0
    MOVE.B  D7,D0
    AND.B   #7,D0

    CMP.B   #0,D0
    BEQ     MOVEM_REG2MEM_IND_SHORT
    CMP.B   #1,D0
    BEQ     MOVEM_REG2MEM_IND_LONG

    BRA     PRINT_ILLEGAL

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_REG2MEM_AN_IND

    LEA     PRINT_MOVEM_STANDARD,A5   * Load the print subroutine
    MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
    ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

    JSR     PUSH_EA_MODE_ID_AN_INDIRECT
    BRA     MOVEM_REG2MEM_EA_FINISH
*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_REG2MEM_PRE_DEC

    LEA     PRINT_MOVEM_REVERSE,A5   * Load the print subroutine
    MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
    ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

    JSR     PUSH_EA_MODE_ID_AN_PRE_DEC
    BRA     MOVEM_REG2MEM_EA_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_REG2MEM_IND_SHORT

    LEA     PRINT_MOVEM_STANDARD,A5   * Load the print subroutine
    MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
    ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long


    JSR   PUSH_EA_MODE_ID_IND_SHORT
    BRA   MOVEM_REG2MEM_EA_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_REG2MEM_IND_LONG

    LEA     PRINT_MOVEM_STANDARD,A5   * Load the print subroutine
    MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
    ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

    JSR   PUSH_EA_MODE_ID_IND_LONG
    BRA     MOVEM_REG2MEM_EA_FINISH

*________________________________________
* Jump directly into the middle of
* the PUSH_EA_MODE subroutine
*----------------------------------------
MOVEM_REG2MEM_EA_FINISH

  ADD.W  #4,LOOP_INC     * Increment the loop counter by 2 bytes

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
* MOVEQ
* Assumption: Bit 8 is checked for zero so this subroutine is always valid
*
*-------------------------------------------------------------------------------
MOVEQ

  CLR.L   D0
  MOVE.W  D7,D0

* ------ Print "MOVEQ" ------

  LEA     PRINT_MOVEQ,A5
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Print Data ------

  AND.W   #$FF,D0 * Get bits 0-7
  MOVE.B  D0,MISC_NUMBER

  LEA     PRINT_MISC_NUMBER_AS_DATA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Print a comma ------
  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Print Register ------

  MOVE.W  D7,D0
  ROR.W   #8,D0 *Shift to get bits 9 - 11
  ROR.W   #1,D0

  AND.W   #7,D0 * Mask 111
  MOVE.B  D0,MISC_REGISTER

  LEA     PRINT_MISC_REGISTER,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 2 bytes

  BRA   PRINT_OPCODE




*-------------------------------------------------------------------------------
* MOVE_MOVEA
*
* Both opcodes start with 00 so we need to figure out which is which
*-------------------------------------------------------------------------------
MOVE_MOVEA
    CLR.L   D0
    MOVE.W  D7,D0

    ROR     #$6,D0    *Get bits 6, 7, and 8
    ANDI.B  #$07,D0   * Mask against 111

    CMPI.B  #1,D0     * If bits equal 001, it's MOVEA
    BEQ     MOVEA

    BRA     MOVE      * Else it's MOVE

*-------------------------------------------------------------------------------
* MOVE
*
* This hurts me
*
*-------------------------------------------------------------------------------
MOVE

  MOVE.L    D7,D0 * Load the print subroutine into intermediate address

* ------ Print "MOVE" ------

  LEA       PRINT_MOVE,A5
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Determine Size ------
  ROR.W   #$8,D0 * Shift a total of 12 bits to retrieve SIZE designator
  ROR.W   #$4,D0
  AND.W   #$7,D0 * Mask 111

  CLR.L   D4 * Clear D4 for use as BWL parameter

  CMP.B   #1,D0
  BEQ     MOVE_B
  CMP.B   #3,D0
  BEQ     MOVE_W
  CMP.B   #2,D0
  BEQ     MOVE_L

  BRA     PRINT_ILLEGAL

* ------ Size Branching ------
* MOVE uses a nonstandard size code. We convert it to the standard so we can
* easily use the existing PUSH_BWL subroutine
MOVE_B
  MOVE.B  #0,D4
  JSR     PUSH_BWL
  BRA     MOVE_SIZE_CONTINUE

MOVE_W
  MOVE.B  #1,D4
  JSR     PUSH_BWL
  BRA     MOVE_SIZE_CONTINUE

MOVE_L
  MOVE.B  #2,D4
  JSR     PUSH_BWL
  BRA     MOVE_SIZE_CONTINUE

MOVE_SIZE_CONTINUE

* ------ Print Source ------
  MOVE.L    D7,D6
  JSR       PUSH_EA_MODE_ID

* ------ Print a comma ------
  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Print Destination ------
* Unfortunately our PUSH_EA_MODE_ID wasn't designed for this :/

  MOVE.L    D7,D0 * D0 holds MODE bits
  MOVE.L    D7,D1 * D1 holds REGISTER bits

  ROR.W     #$6,D0 * Get the three mode bits
  AND.W     #$7,D0 * Mask 111

  ROR.W     #$8,D1 * Get the three register bits
  ROR.W     #$1,D1
  AND.W     #$7,D1 * Mask 111

* ---- Branching Block ----


  MOVE.B  D1,MISC_NUMBER * For modes that print the register bits as a number

  CMP.B   #0,D0			*000 -> Register
  BEQ     MOVE_MODE_DN
  CMP.B   #2,D0			*010 -> Address Register   Indirect
  BEQ     MOVE_MODE_AN_INDIRECT
  CMP.B   #3,D0			*011 -> Address Register  (Indirect)+
  BEQ     MOVE_MODE_AN_POST_INC
  CMP.B   #4,D0			*100 -> Address Register -(Indirect)
  BEQ     MOVE_MODE_AN_PRE_DEC
  CMP.B   #7,D0			*111 -> All Data Operations
  BEQ     MOVE_MODE_ELSE

  BRA     PRINT_ILLEGAL

*________________________________________
* Load Register Print Label
*----------------------------------------
MOVE_MODE_DN
  LEA   PRINT_MISC_NUMBER_AS_REGISTER,A5
  BRA   MOVE_MODE_FINISH
*________________________________________
* Load (Address Register) Print Label
*----------------------------------------
MOVE_MODE_AN_INDIRECT
  LEA   PRINT_MISC_ADDRESS_IND,A5
  BRA   MOVE_MODE_FINISH
*________________________________________
* Load (Address Register)+ Print Label
*----------------------------------------
MOVE_MODE_AN_POST_INC
  LEA   PRINT_MISC_POST_INC,A5
  BRA   MOVE_MODE_FINISH
*________________________________________
* Load -(Address Register) Print Label
*----------------------------------------
MOVE_MODE_AN_PRE_DEC
  LEA   PRINT_MISC_PRE_DEC,A5
  BRA   MOVE_MODE_FINISH

*________________________________________
* Handle Data Branching Logic
*----------------------------------------
MOVE_MODE_ELSE

    CMP.B   #0,D1
    BEQ     MOVE_MODE_IND_SHORT

    CMP.B   #1,D1
    BEQ     MOVE_MODE_IND_LONG

* ------ Data is short ------
MOVE_MODE_IND_SHORT
    CMP.W  #1,DATA1_IN_USE
    BEQ     MOVE_MODE_IND_SHORT_DATA2
    ADD.W           #2, LOOP_INC * Adjust the Loop increment to skip the data
    MOVE.W  #1,DATA1_IN_USE

    LEA     PRINT_EA_MODE_ID_IND_SHORT,A5
    BRA     MOVE_MODE_FINISH

* ------ Data is short, DATA1 is in use ------
MOVE_MODE_IND_SHORT_DATA2
    ADD.W           #2, LOOP_INC * Adjust the Loop increment to skip the data

    LEA     PRINT_EA_MODE_ID_IND_SHORT_DATA2,A5
    BRA     MOVE_MODE_FINISH

* ------ Data is Long ------
MOVE_MODE_IND_LONG
    CMP.W  #1,DATA1_IN_USE
    BEQ     MOVE_MODE_IND_LONG_DATA2

    LEA     PRINT_EA_MODE_ID_IND_LONG,A5
    ADD.W           #4,LOOP_INC * Adjust the Loop increment to skip the data
    MOVE.W  #1,DATA1_IN_USE
    BRA     MOVE_MODE_FINISH


* ------ Data is Long, DATA1 is in use ------
MOVE_MODE_IND_LONG_DATA2

    LEA     PRINT_EA_MODE_ID_IND_LONG_DATA2,A5
    ADD.W           #4,LOOP_INC * Adjust the Loop increment to skip the data
    BRA     MOVE_MODE_FINISH


MOVE_MODE_FINISH

  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W           #4,PRINT_COUNT

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 2 bytes

  BRA   PRINT_OPCODE


*-------------------------------------------------------------------------------
* MOVEA
*
*
*-------------------------------------------------------------------------------
MOVEA

  MOVE.L    D7,D0 * Load the print subroutine into intermediate address

* ------ Print "MOVEA" ------

  LEA     PRINT_MOVEA,A5
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Determine Size ------
  ROR.W   #$8,D0 * Shift a total of 12 bits to retrieve SIZE designator
  ROR.W   #$4,D0
  AND.W   #$7,D0 * Mask 111

  CLR.L   D4 * Clear D4 for use as BWL parameter

  CMP.B   #3,D0
  BEQ     MOVEA_W
  CMP.B   #2,D0
  BEQ     MOVEA_L

  BRA     PRINT_ILLEGAL


* ------ Size Branching ------
* MOVEA uses a nonstandard size code. We convert it to the standard so we can
* easily use the existing PUSH_BWL subroutine
MOVEA_W
  MOVE.B  #1,D4
  JSR     PUSH_BWL
  BRA     MOVEA_SIZE_CONTINUE

MOVEA_L
  MOVE.B  #2,D4
  JSR     PUSH_BWL
  BRA     MOVEA_SIZE_CONTINUE

MOVEA_SIZE_CONTINUE

* ------ Print Source ------
  MOVE.L    D7,D6
  JSR       PUSH_EA_MODE_ID

* ------ Print a comma ------
  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

* ------ Get Destination Address ------
  MOVE.L    D7,D0
  ROR.W     #$8,D0 * Get the three register bits
  ROR.W     #$1,D0
  AND.W     #$7,D0 * Mask 111

  MOVE.B    D0,MISC_NUMBER

* ------ Print Destination Address ------
  LEA       PRINT_MISC_NUMBER_AS_ADDRESS,A5
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W           #4,PRINT_COUNT

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 2 bytes

  BRA   PRINT_OPCODE

*-------------------------------------------------------------------------------
*   LSX_ASX_ROX
*
*
*-------------------------------------------------------------------------------
LSX_ASX_ROX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$FEC0,D0
   
* ------ Arithmetic Shift MEM ------   
  CMP.W #$E0C0,D0
  BEQ   ASX

* ------ Logical Shift MEM -----
  CMP.W #$E2C0,D0
  BEQ   LSX

* ------ Rotate MEM ------
  CMP.W #$E6C0,D0
  BEQ   ROX
  
  MOVE.L    D7,D0      * Reset D0  
  AND.W     #$18,D0  * Isolate bits 4,3 
  
* ------ Arithmetic Shift ------
  CMP.W #0,D0
  BEQ   ASX

* ------ Logical Shift ------
  CMP.W #8,D0
  BEQ   LSX

* ------ Rotate ------
  CMP.W #$18,D0
  BEQ   ROX

*______________________________
*Determine Logical Shift Direction
*------------------------------
LSX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$100,D0   * Isolate bit 8
  CMP.W     #0,D0
  BEQ       LSR
  BRA       LSL

*______________________________
* Logical Shift Right
*------------------------------
LSR
  LEA     PRINT_LSR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

*______________________________
* Logical Shift Left
*------------------------------
LSL
  LEA     PRINT_LSL,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

*______________________________
*Determine Arithmetic Shift Direction
*------------------------------
ASX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$100,D0   * Isolate bit 8
  CMP.W     #0,D0
  BEQ       ASR
  BRA       ASL

*______________________________
* Arithmetic Shift Right
*------------------------------
ASR
  LEA     PRINT_ASR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

*______________________________
* Arithmetic Shift Left
*------------------------------
ASL
  LEA     PRINT_ASL,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

*______________________________
* Determine Rotate Direction
*------------------------------
ROX
  MOVE.L    D7,D0      * Reset D0
  AND.W     #$100,D0   * Isolate bit 8
  CMP.W     #0,D0
  BEQ       ROR
  BRA       ROL

*______________________________
* Rotate Right
*------------------------------
ROR
  LEA     PRINT_ROR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

*______________________________
* Rotate Left
*------------------------------
ROL
  LEA     PRINT_ROL,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT

  BRA     LSX_ASX_ROX_CONTINUE

*______________________________
* All Subroutine Continue
*------------------------------
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

*__________________________________
* Print the number of bits to shift
*----------------------------------
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

  BRA LSX_ASX_ROX_FINISH

*__________________________________
* Convert 0 to 8 (Special case)
*----------------------------------
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

  BRA LSX_ASX_ROX_FINISH

*__________________________________
* Print the register that contains the number of bits to shift
*----------------------------------
LSX_ASX_ROX_REGISTER
  MOVE.L    D7,D0      * Reset D0
  AND.L   #$E00,D0

  ASR.L   #$8,D0
  ASR.L   #$1,D0

  MOVE.B  D0,MISC_NUMBER
  LEA   PRINT_MISC_NUMBER_AS_REGISTER,A5  * Print data register
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  LEA     PRINT_COMMA,A5   * Load the print subroutine
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #4,PRINT_COUNT  * Increment Print Count by 1 long

  LEA   PRINT_EA_MODE_ID_DN,A5  * Print data register
  MOVE.L    A5, -(SP)
  ADD.W     #4, PRINT_COUNT

  BRA LSX_ASX_ROX_FINISH

*__________________________________
* Memory Shift mode
*----------------------------------
LSX_ASX_ROX_MEM
  MOVE.L D7,D6
  AND.L #$38,D6
  CMP.W #8,D6
  BLE   PRINT_ILLEGAL

  LEA PRINT_FOURSPACE,A5
  MOVE.L    A5,-(SP)
  ADD.W    #4,PRINT_COUNT

  JSR     PUSH_EA_MODE_ID
  BRA LSX_ASX_ROX_FINISH


*__________________________________
* Finish
*----------------------------------
LSX_ASX_ROX_FINISH
  MOVE.W  #2,LOOP_INC
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

  ADD.W  #2,LOOP_INC     * Increment the loop counter by 2 bytes

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

  CMP.W   PRINT_COUNT,A1 * Check if we're done
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
    ADD.W           #2, LOOP_INC * Adjust the Loop increment to skip the data
    MOVE.W  #1,DATA1_IN_USE
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_IND_LONG
    LEA     PRINT_EA_MODE_ID_IND_LONG,A5
    ADD.W           #4,LOOP_INC * Adjust the Loop increment to skip the data
    MOVE.W  #1,DATA1_IN_USE
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_ABS_DATA
    LEA     PRINT_EA_MODE_ID_ABS_DATA,A5
    ADD.W           #4,LOOP_INC * Adjust the Loop increment to skip the data
        MOVE.W  #1,DATA1_IN_USE
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
* May god have mercy on your soul
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
*		PRINT MISC_REGISTER
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
PRINT_MISC_REGISTER

    LEA             STRING_D,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR.L   D0
    CLR.L   D1
    CLR.L   D2

    MOVE.B  #15,D0
    MOVE.B  MISC_REGISTER,D1
    MOVE.B  #10,D2
    TRAP #15

    BRA     PRINT_OPCODE_LOOP_RETURN



*-------------------------------------------------------------------------------
*
*		PRINT_MISC_PRE_DEC
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
PRINT_MISC_PRE_DEC

    LEA             STRING_MINUS,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

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

    LEA             STRING_RIGHT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    BRA     PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT_MISC_POST_INC
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
PRINT_MISC_POST_INC

    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

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

    LEA             STRING_RIGHT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_PLUS,A1
    MOVE.B          #14,D0
    TRAP            #15

    BRA     PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT_MISC_ADDRESS_IND
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
PRINT_MISC_ADDRESS_IND

    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

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

    LEA             STRING_RIGHT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

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
*		PRINT MOVE
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MOVE
    LEA             STRING_MOVE,A1	* Load "MOVE" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT MOVEA
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MOVEA
    LEA             STRING_MOVEA,A1	* Load "MOVEA" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT MOVEQ
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MOVEQ
    LEA             STRING_MOVEQ,A1	* Load "MOVEQ" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT MOVEM
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_MOVEM
    LEA             STRING_MOVEM,A1	* Load "MOVEM" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT SUB
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_SUB
    LEA             STRING_SUB,A1	* Load "SUB" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT AND
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_AND
    LEA             STRING_AND,A1	* Load "AND" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15			* Print ", "
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT OR
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_OR
    LEA             STRING_OR,A1	* Load "OR" into A1
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
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - WORD DATA - DATA2
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
PRINT_EA_MODE_ID_IND_SHORT_DATA2
    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    MOVE.L          DATA2,D1
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
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - LONG DATA - DATA2
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
PRINT_EA_MODE_ID_IND_LONG_DATA2
    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    MOVE.L          DATA2,D1
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
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - ABSOLUTE DATA2
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
PRINT_EA_MODE_ID_ABS_DATA2
    LEA             STRING_POUND,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_DOLLAR,A1
    MOVE.B          #14,D0
    TRAP            #15

    MOVE.L          DATA2,D1
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
*		PRINT NOT
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_NOT
    LEA             STRING_NOT,A1	* Load "NOT" into A1
    MOVE.B          #14,D0		* Set trap task to String
    TRAP            #15
    BRA             PRINT_OPCODE_LOOP_RETURN

*-------------------------------------------------------------------------------
*
*		PRINT LEA
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_LEA
    LEA             STRING_LEA,A1	* Load "LEA" into A1
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
*		PRINT SPACE
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_SPACE
    LEA             STRING_SPACE,A1 * Load four spaces into A1
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
    MOVE.L          STACK_BASE,SP
    * SUBA.L          #4,SP

    LEA             STRING_ILLEGAL,A1
    MOVE.B          #13,D0
    TRAP            #15


    MOVE.W  #2,LOOP_INC     * Increment the loop counter by 1 word


    RTS

*-------------------------------------------------------------------------------
*
*		PRINT NON_OPCODE_DATA
*
* Incomplete implementation - final version will depend on opcode logic.
* Currently clears stack entirely, future implementation may need to keep
* some RTS addresses
*
* D5: RTS address
*-------------------------------------------------------------------------------
PRINT_NON_OPCODE_DATA
    MOVE.L          STACK_BASE,SP
 *    SUBA.L          #4,SP

* ------ Print "DATA: " ------
    LEA             STRING_DATA,A1
    MOVE.B          #14,D0
    TRAP            #15

* ------ Print D7 contents ------
    MOVE.L          D7,D1
    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

    JSR             PRINT_IMMEDIATE_NEWLINE

    MOVE.W  #2,LOOP_INC     * Increment the loop counter by 1 word

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



*--------------------------------------------------------------------------------
* PAUSE_CONSOLE
*
* Takes user input and promptly throws it away
*
*
PAUSE_CONSOLE

  MOVEQ	   #2,D0
	TRAP	   #15
  CLR.W    D1
  MOVEA.L  #0,A1

  RTS



*--------------------------------------------------------------------------------
* PRINT_MOVEM_STANDARD
*
* Oh no
*
* Registers Used:
*	D0: Trap task designator
*	D1: Memory address to display
*
* A1: Data memory location
*
PRINT_MOVEM_STANDARD

  CLR.L     D2 * D2 is where full data is stored
  MOVE.W    MISC_OPCODE,D2

  CLR.L     D1 * D1 is where we'll do the masking
  MOVE.W    D2,D1

PRINT_MOVEM_STANDARD_A7

  AND.W     #$8000,D1
  CMP.W     #$8000,D1
  BNE       PRINT_MOVEM_STANDARD_A6

  LEA	     STRING_A7,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A6

  MOVE.W    D2,D1
  AND.W     #$4000,D1
  CMP.W     #$4000,D1
  BNE       PRINT_MOVEM_STANDARD_A5

  LEA	     STRING_A6,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A5

  MOVE.W    D2,D1
  AND.W     #$2000,D1
  CMP.W     #$2000,D1
  BNE       PRINT_MOVEM_STANDARD_A4

  LEA	     STRING_A5,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A4

  MOVE.W    D2,D1
  AND.W     #$1000,D1
  CMP.W     #$1000,D1
  BNE       PRINT_MOVEM_STANDARD_A3

  LEA	     STRING_A4,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A3

  MOVE.W    D2,D1
  AND.W     #$0800,D1
  CMP.W     #$0800,D1
  BNE       PRINT_MOVEM_STANDARD_A2

  LEA	     STRING_A3,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A2

  MOVE.W    D2,D1
  AND.W     #$0400,D1
  CMP.W     #$0400,D1
  BNE       PRINT_MOVEM_STANDARD_A1

  LEA	     STRING_A2,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A1

  MOVE.W    D2,D1
  AND.W     #$0200,D1
  CMP.W     #$0200,D1
  BNE       PRINT_MOVEM_STANDARD_A0

  LEA	     STRING_A1,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_A0

  MOVE.W    D2,D1
  AND.W     #$0100,D1
  CMP.W     #$0100,D1
  BNE       PRINT_MOVEM_STANDARD_D7

  LEA	     STRING_A0,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D7

  MOVE.W    D2,D1
  AND.W     #$0080,D1
  CMP.W     #$0080,D1
  BNE       PRINT_MOVEM_STANDARD_D6

  LEA	     STRING_D7,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D6

  MOVE.W    D2,D1
  AND.W     #$0040,D1
  CMP.W     #$0040,D1
  BNE       PRINT_MOVEM_STANDARD_D5

  LEA	     STRING_D6,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D5

  MOVE.W    D2,D1
  AND.W     #$0020,D1
  CMP.W     #$0020,D1
  BNE       PRINT_MOVEM_STANDARD_D4

  LEA	     STRING_D5,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D4

  MOVE.W    D2,D1
  AND.W     #$0010,D1
  CMP.W     #$0010,D1
  BNE       PRINT_MOVEM_STANDARD_D3

  LEA	     STRING_D4,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D3

  MOVE.W    D2,D1
  AND.W     #$0008,D1
  CMP.W     #$0008,D1
  BNE       PRINT_MOVEM_STANDARD_D2

  LEA	     STRING_D3,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D2

  MOVE.W    D2,D1
  AND.W     #$0004,D1
  CMP.W     #$0004,D1
  BNE       PRINT_MOVEM_STANDARD_D1

  LEA	     STRING_D2,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D1

  MOVE.W    D2,D1
  AND.W     #$0002,D1
  CMP.W     #$0002,D1
  BNE       PRINT_MOVEM_STANDARD_D0

  LEA	     STRING_D1,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_D0

  MOVE.W    D2,D1
  AND.W     #$0001,D1
  CMP.W     #$0001,D1
  BNE       PRINT_MOVEM_STANDARD_END

  LEA	     STRING_D0,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_STANDARD_END

  LEA	     STRING_SPACE,A1
  MOVEQ	   #14,D0
  TRAP	   #15


  BRA      PRINT_OPCODE_LOOP_RETURN


*--------------------------------------------------------------------------------
* PRINT_MOVEM_REVERSE
*
* it hurts
*
* Registers Used:
*	D0: Trap task designator
*	D1: Memory address to display
*
* A1: Data memory location
*
PRINT_MOVEM_REVERSE


  CLR.L     D2 * D2 is where full data is stored
  MOVE.W    MISC_OPCODE,D2

  CLR.L     D1 * D1 is where we'll do the masking
  MOVE.W    D2,D1

PRINT_MOVEM_REVERSE_D0

  AND.W     #$8000,D1
  CMP.W     #$8000,D1
  BNE       PRINT_MOVEM_REVERSE_D1

  LEA	     STRING_D0,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D1

  MOVE.W    D2,D1
  AND.W     #$4000,D1
  CMP.W     #$4000,D1
  BNE       PRINT_MOVEM_REVERSE_D2

  LEA	     STRING_D1,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D2

  MOVE.W    D2,D1
  AND.W     #$2000,D1
  CMP.W     #$2000,D1
  BNE       PRINT_MOVEM_REVERSE_D3

  LEA	     STRING_D2,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D3

  MOVE.W    D2,D1
  AND.W     #$1000,D1
  CMP.W     #$1000,D1
  BNE       PRINT_MOVEM_REVERSE_D4

  LEA	     STRING_D3,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D4

  MOVE.W    D2,D1
  AND.W     #$0800,D1
  CMP.W     #$0800,D1
  BNE       PRINT_MOVEM_REVERSE_D5

  LEA	     STRING_D4,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D5

  MOVE.W    D2,D1
  AND.W     #$0400,D1
  CMP.W     #$0400,D1
  BNE       PRINT_MOVEM_REVERSE_D6

  LEA	     STRING_D5,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D6

  MOVE.W    D2,D1
  AND.W     #$0200,D1
  CMP.W     #$0200,D1
  BNE       PRINT_MOVEM_REVERSE_D7

  LEA	     STRING_D6,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_D7

  MOVE.W    D2,D1
  AND.W     #$0100,D1
  CMP.W     #$0100,D1
  BNE       PRINT_MOVEM_REVERSE_A0

  LEA	     STRING_D7,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A0

  MOVE.W    D2,D1
  AND.W     #$0080,D1
  CMP.W     #$0080,D1
  BNE       PRINT_MOVEM_REVERSE_A1

  LEA	     STRING_A0,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A1

  MOVE.W    D2,D1
  AND.W     #$0040,D1
  CMP.W     #$0040,D1
  BNE       PRINT_MOVEM_REVERSE_A2

  LEA	     STRING_A1,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A2

  MOVE.W    D2,D1
  AND.W     #$0020,D1
  CMP.W     #$0020,D1
  BNE       PRINT_MOVEM_REVERSE_A3

  LEA	     STRING_A2,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A3

  MOVE.W    D2,D1
  AND.W     #$0010,D1
  CMP.W     #$0010,D1
  BNE       PRINT_MOVEM_REVERSE_A4

  LEA	     STRING_A3,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A4

  MOVE.W    D2,D1
  AND.W     #$0008,D1
  CMP.W     #$0008,D1
  BNE       PRINT_MOVEM_REVERSE_A5

  LEA	     STRING_A4,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A5

  MOVE.W    D2,D1
  AND.W     #$0004,D1
  CMP.W     #$0004,D1
  BNE       PRINT_MOVEM_REVERSE_A6

  LEA	     STRING_A5,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A6

  MOVE.W    D2,D1
  AND.W     #$0002,D1
  CMP.W     #$0002,D1
  BNE       PRINT_MOVEM_REVERSE_A7

  LEA	     STRING_A6,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_A7

  MOVE.W    D2,D1
  AND.W     #$0001,D1
  CMP.W     #$0001,D1
  BNE       PRINT_MOVEM_REVERSE_END

  LEA	     STRING_A7,A1
	MOVEQ	   #14,D0
	TRAP	   #15

PRINT_MOVEM_REVERSE_END

  LEA	     STRING_SPACE,A1
	MOVEQ	   #14,D0
	TRAP	   #15


  BRA   PRINT_OPCODE_LOOP_RETURN


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

*-----------------------------------------------------------------
* QUERY_CONTINUE
*
* Called before anything else, clears what it uses
*-----------------------------------------------------------------
QUERY_CONTINUE

    LEA     STRING_QUERY_CONTINUE,A1
    MOVE.B  #13,D0
    TRAP    #15

    MOVEA   #0,A1
    MOVE.B  #2,D0
    TRAP    #15

    CMP.B   #$79,(A1)
    BEQ     INITIALIZE

    LEA     STRING_EXITING,A1
    MOVE.B  #13,D0
    TRAP    #15

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


* Data for GET_INPUT and QUERY_CONTINUE ----------
STRING_ENTER_START      DC.B    'Please enter a start address, eg. 4A6C',0
STRING_ENTER_END        DC.B    'Please enter a end address, eg. 5D3F',0
STRING_INVALID_INPUT    DC.B    'INVALID INPUT, must be a valid EASy68k hexidecimal memory address',0
STRING_OUT_OF_ORDER     DC.B    'Start address must be less than end address',0
STRING_QUERY_CONTINUE   DC.B    'Would you like to disassemble another memory image? (y/n)',0
STRING_EXITING          DC.B    'Now exiting, have a nice day',0
* -------------------------------------------------

STRING_DATA                 DC.B    'DATA: ',0
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

STRING_SPACE                DC.B    ' ',0
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
STRING_MOVE                 DC.B    'MOVE',0
STRING_MOVEA                DC.B    'MOVEA',0
STRING_MOVEQ                DC.B    'MOVEQ    ',0
STRING_MOVEM                DC.B    'MOVEM',0
STRING_SUB                  DC.B    'SUB',0
STRING_AND                  DC.B    'AND',0
STRING_OR                   DC.B    'OR',0
STRING_NOT                  DC.B    'NOT',0
STRING_LEA                  DC.B    'LEA',0

STRING_A0                   DC.B    'A0,',0
STRING_A1                   DC.B    'A1,',0
STRING_A2                   DC.B    'A2,',0
STRING_A3                   DC.B    'A3,',0
STRING_A4                   DC.B    'A4,',0
STRING_A5                   DC.B    'A5,',0
STRING_A6                   DC.B    'A6,',0
STRING_A7                   DC.B    'A7,',0

STRING_D0                   DC.B    'D0,',0
STRING_D1                   DC.B    'D1,',0
STRING_D2                   DC.B    'D2,',0
STRING_D3                   DC.B    'D3,',0
STRING_D4                   DC.B    'D4,',0
STRING_D5                   DC.B    'D5,',0
STRING_D6                   DC.B    'D6,',0
STRING_D7                   DC.B    'D7,',0

MISC_NUMBER  DS.B    1    * MISC_NUMBER to be printed
MISC_OPCODE  DS.W    1
MISC_REGISTER DS.B   1
LINE_COUNT    DS.W    1    * How many lines are currently displayed onscreen



    END    START








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
