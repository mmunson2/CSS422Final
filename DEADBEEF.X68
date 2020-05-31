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
*  MOVE.W    #$4E71, $4002   * NOP Opcode
*  MOVE.W    #$4E75, $4004   * RTS Opcode
*  MOVE.W    #$5241, $4000   * ADDQ Opcode
  MOVE.W    #$D240, $4000   * ADD Opcode

  MOVE.L    #$4000, START_ADDR
  MOVE.L    #$5000, END_ADDR

* ------ Standard Initializations ------
  MOVE.W    #0, PRINT_COUNT
  MOVE.B    #0, NUMBER

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
*-------------------------------------------------------------------------------
OPCODE_LOOP

    MOVEA.L LOOP_INDEX,A0
    CMPA.L  END_ADDR, A0  * Check to see if we're done
    BGT     DONE

    CLR     D7
    MOVE.W  (A0),D7       * Get the memory at the loop index
    JSR     PRINTADDR             * Print the memory address
    JSR     BRANCHBLOCK           * Figure out what opcode this is and print

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
  CLR     D0
  MOVE.W  D7,D0
  SWAP    D0
  ROL.L   #$04,D0
  AND.B   #$F,D0
  CMP.B   #5,D0
  BEQ     ADDQ

* ---- ADDA ----
  CLR     D0
  MOVE.L  D7,D0
  AND.W   #$F000,D0
  CMP.W   #$D000,D0
  BEQ     ADD_ADDA

* ---- 10 BIT OPCODES ----
  CLR     D0
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
*   ADD ADDA
*
*
*-------------------------------------------------------------------------------
ADD_ADDA

  ADDA    #2,A0  * Move the index to the data
  MOVE.L  (A0),DATA1
  SUBA    #2,A0


  MOVE.L  D7,D6
  SWAP    D6          * Restore D6
  ROR.W   #06,D6     * Get bits 7,6 on end
  AND.B   #03,D6     * Isolate bits 7,6
  CMP.B   #03,D6
  BEQ   ADDA
  BRA   ADD

RESUME_ADD
  MOVE.W #0,D3    * Number for LOOP_INC

  CMP.B #1,BOOL_HAS_DATA_W
  BEQ   ADD_ADDA_LOOP_ADD_W
  CMP.B #1,BOOL_HAS_DATA_L
  BNE   ADD_ADDA_LOOP_NO_ADD

  ADD.B  #2, D3

ADD_ADDA_LOOP_ADD_W
  ADD.B  #2, D3

ADD_ADDA_LOOP_NO_ADD
  ADD.B #2, D3
  ROR.B #2, D3
  AND.B #$C,D3

  MOVE.B  D3,LOOP_INC


  MOVE.B  #0,BOOL_HAS_DATA_W
  MOVE.B  #0,BOOL_HAS_DATA_L
  BRA   PRINT_OPCODE

  RTS
*-------------------------------------------------------------------------------
*   ADDA
*
*
*-------------------------------------------------------------------------------
ADDA

  LEA     PRINT_ADDA,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #2,PRINT_COUNT

  BRA   RESUME_ADD

*-------------------------------------------------------------------------------
*   ADD
*
*
*-------------------------------------------------------------------------------
ADD

  LEA     PRINT_ADD,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #2,PRINT_COUNT

  MOVE.B   D6,D4            * Move bits 7,6 to D4 for BWL

  LEA     PUSH_BWL,A5    * Load the PUSH_BWL subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the PUSH_BWL subroutine jump onto the stack
  ADD.W   #2,PRINT_COUNT

  SWAP    D7              * Reset D7 for EA MODE
  JSR     PUSH_EA_MODE_ID
  MOVE.W  #4,LOOP_INC     * Increment the loop counter by 4 bytes

  MOVE D7,D6    * Reset D6

  ASR.L   #$8,D6
  ASR.L   #$1,D6

  AND.B   #$8,D6
  BEQ     PUSH_EA_MODE_ID_DN

  BRA   RESUME_ADD

*-------------------------------------------------------------------------------
*   NOP
*
*
*-------------------------------------------------------------------------------
NOP

  LEA     STRING_NOP,A1
  MOVE.B  #14,D0
  TRAP    #15

  MOVE.W  #2,LOOP_INC   * Increment the loop counter by 2 bytes

  RTS

*-------------------------------------------------------------------------------
*   RTS
*
*
*-------------------------------------------------------------------------------
RTS

  LEA     STRING_RTS,A1
  MOVE.B  #14,D0
  TRAP    #15

  MOVE.W  #2,LOOP_INC   * Increment the loop counter by 2 bytes

  RTS

*-------------------------------------------------------------------------------
*   ADDQ
*
*
*-------------------------------------------------------------------------------
ADDQ
  MOVE.L  D7,D6             * Reset bit shit
  ROL.L   #$04,D6

  ROL.L   #$04,D6           * Isolate bits 11 - 8
  AND.B   #1,D6
  CMP.B   #0,D6             * Check for 0 in 8th bit
  BNE     PRINT_ILLEGAL

  LEA     PRINT_ADDQ,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W   #2,PRINT_COUNT

  ROL.L   #$02,D6           * Isolate bits 7 - 6
  CLR      D4
  MOVE.B   D6,D4            * Move bits 7,6 to D4 for BWL

  LEA     PUSH_BWL,A5    * Load the PUSH_BWL subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the PUSH_BWL subroutine jump onto the stack
  ADD.W   #2,PRINT_COUNT

  MOVE.L  D7,D6             * Reset D6
  ROL.L   #$7, D6           * Get bits 11 - 9
  AND.B   #$7, D6           * Clear bit 11

  MOVE.B  D6,NUMBER
  LEA     PRINT_NUMBER,A5
  MOVE.L  A5, -(SP)
  ADD.W   #2, PRINT_COUNT

  SWAP    D7              * Reset D7 for EA MODE
  JSR     PUSH_EA_MODE_ID
  MOVE.W  #4,LOOP_INC     * Increment the loop counter by 4 bytes


  BRA     PRINT_OPCODE    * Always put this at the end


*-------------------------------------------------------------------------------
*   JSR
*
*
*-------------------------------------------------------------------------------
JSR

  LEA     PRINT_JSR,A5    * Load the print subroutine into intermediate address
  MOVE.L  A5, -(SP)       * Put the print subroutine jump onto the stack
  ADD.W           #4,PRINT_COUNT

  JSR     PUSH_EA_MODE_ID

  MOVE.W  #4,LOOP_INC     * Increment the loop counter by 4 bytes

  BRA     PRINT_OPCODE    * Always put this at the end

  RTS


*-------------------------------------------------------------------------------
*   PRINT OPCODE
*-------------------------------------------------------------------------------

PRINT_OPCODE

  CLR     D2
  CLR     D3

  MOVE.W   PRINT_COUNT,D3
  MOVE.L  STACK_BASE,SP * Put the stack back to where it was when we started

PRINT_OPCODE_LOOP

  CMP.B   D3,D2
  BGE     PRINT_OPCODE_LOOP_FINISH

  MOVE.L  -(SP),A1  * Pop the next item on the stack and put it in A1
  JMP     (A1)        * Jump to the routine we stored on the stack

PRINT_OPCODE_LOOP_RETURN * Print methods come back here

  ADDQ    #4,D2     * Stack entries are 4 bytes, so add this as loop index
  BRA     PRINT_OPCODE_LOOP

PRINT_OPCODE_LOOP_FINISH

  MOVE.L  STACK_BASE,SP  * Return the stack to normal so we can RTS
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
* D7: CONST PARAMETER - The current opcode word
*
* A4: LOCAL VARIABLE - RTS value temporary storage - must be swapped
* A5: LOCAL VARIABLE - Print Label to be pushed to stack
*
*-------------------------------------------------------------------------------
PUSH_EA_MODE_ID


* ---- Input Processing ----

    MOVE.B  D7,D0	* Put opcode in D0
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
    MOVE.B  D7,D0
    AND.B   #7,D0

    CMP.B   #0,D0
    BEQ     PUSH_EA_MODE_ID_IND_SHORT

    CMP.B   #1,D0
    BEQ     PUSH_EA_MODE_ID_IND_LONG

    CMP.B   #4,D0
    BEQ     PUSH_EA_MODE_ID_ABS_DATA

    BRA     PRINT_ILLEGAL
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_IND_SHORT
    LEA     PRINT_EA_MODE_ID_IND_SHORT,A5
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_IND_LONG
    LEA     PRINT_EA_MODE_ID_IND_LONG,A5
    BRA     PUSH_EA_MODE_ID_FINISH

PUSH_EA_MODE_ID_ABS_DATA
    LEA     PRINT_EA_MODE_ID_ABS_DATA,A5
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
    CMP.B           #3,D4		*10 -> Long
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
*		PRINT NUMBER
*________________________________________
* Register Use Summary:
*
* D0: LOCAL VARIABLE  - Trap task designator
*
* D1: LOCAL VARIABLE  - Number to be printed
*
* D2: LOCAL VARIABLE  - Base of number
*
* A1: LOCAL VARIABLE  - String address
*-------------------------------------------------------------------------------
PRINT_NUMBER
    CLR D1

    MOVE.B  #15,D0
    MOVE.B  NUMBER,D1
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

    CLR             D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed number
    TRAP            #15			* Print the register number

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


    CLR             D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed number
    TRAP            #15			* Print the register number

    BRA             PRINT_OPCODE_LOOP_RETURN


*-------------------------------------------------------------------------------
*
*		PRINT EFFECTIVE ADDRESS MODE IDENTIFIER - (ADDRESS REGISTER)
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
PRINT_EA_MODE_ID_AN_INDIRECT
    LEA             STRING_LEFT_PAREN,A1
    MOVE.B          #14,D0
    TRAP            #15

    LEA             STRING_A,A1
    MOVE.B          #14,D0
    TRAP            #15

    CLR             D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed number
    TRAP            #15			* Print the register number

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

    CLR             D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed number
    TRAP            #15			* Print the register number

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

    CLR             D1
    MOVE.B          D7,D1  		* Get the lowest byte of the opcode
    AND.B           #$7,D1		* Get the lowest four bits (register #)
    MOVE.B          #3,D0		* Set trap task to signed number
    TRAP            #15			* Print the register number

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

    MOVE.W          DATA1,D1
    MOVEQ           #15,D0
    MOVEQ           #16,D2
    TRAP            #15

    MOVE.B          #1,BOOL_HAS_DATA_W

    JSR             PRINT_WORD_DESIGNATOR
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

    MOVE.B          #1,BOOL_HAS_DATA_L

    JSR             PRINT_LONG_DESIGNATOR
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

    MOVE.B          #1,BOOL_HAS_DATA_L

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
    TRAP            #15			* Print ", "
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


* Put variables and constants here
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

STRING_NOP                  DC.B    'NOP',0
STRING_RTS                  DC.B    'RTS',0
STRING_ADDQ                 DC.B    'ADDQ',0
STRING_ADD                  DC.B    'ADD',0
STRING_ADDA                 DC.B    'ADDA',0
STRING_JSR                  DC.B    'JSR',0

NUMBER  DS.B    1    * Misc number to be printed

BOOL_HAS_DATA_W             DS.B    1
BOOL_HAS_DATA_L             DS.B    1


    END    START






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
