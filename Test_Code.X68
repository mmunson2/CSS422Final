JSR Test

* ------ JSR TEST ------

* Matthew's current JSR test, sorry if pushed by accident!
   MOVE.W    #$4E90, $4000   * JSR (A0)
   MOVE.W    #$4E91, $4002   * JSR (A1)
   MOVE.W    #$4E92, $4004   * JSR (A2)
   MOVE.W    #$4E93, $4006   * JSR (A3)
   MOVE.W    #$4E94, $4008   * JSR (A4)
   MOVE.W    #$4E95, $400A   * JSR (A5)
   MOVE.W    #$4E96, $400C   * JSR (A6)
   MOVE.W    #$4E97, $400E   * JSR (A7)


   MOVE.W    #$4EB9,$4010     * JSR 1016 (1)
   MOVE.L    #$00001016, $4012 * JSR 1016 (2)

* ------ ADD TEST ------
  MOVE.W  #$D151, $4000 * ADD.W   D0,(A1)
  MOVE.W  #$D191, $4002 * ADD.L   D0,(A1)
  MOVE.W  #$D049, $4004 * ADD.W   A1,D0
  MOVE.W  #$D089, $4006 * ADD.L   A1,D0

  MOVE.W  #$DF57, $4008 * ADD.W   D7,(A7)
  MOVE.W  #$DF97, $400A * ADD.L   D7,(A7)
  MOVE.W  #$DE4F, $400C * ADD.W   A7,D7
  MOVE.W  #$DE8F, $400E * ADD.L   A7,D7

* ------ ADDQ TEST ------
  MOVE.W  #$5200, $4000 * ADDQ.B  #1,D0
  MOVE.W  #$5441, $4002 * ADDQ.W  #2,D1
  MOVE.W  #$5682, $4004 * ADDQ.L  #3,D2

  MOVE.W  #$5E51, $4006 * ADDQ.W  #7,(A1)
  MOVE.W  #$505F, $4008 * ADDQ.W  #8,(A7)+




* ------ ADDA TEST ------
  MOVE.W   #$D2C0, $4000 * ADDA.W    D0,A1
  MOVE.W   #$D3C0, $4002 * ADDA.L    D0,A1
  MOVE.W   #$DEC7, $4004 * ADDA.W    D7,A7
  MOVE.W   #$DFC7, $4006 * ADDA.L    D7,A7

  MOVE.W   #$D2C8, $4008 * ADDA.W    A0,A1
  MOVE.W   #$D5C9, $400A * ADDA.L    A1,A2
  MOVE.W   #$D6CA, $400C * ADDA.W    A2,A3
  MOVE.W   #$DFCE, $400E * ADDA.L    A6,A7

  MOVE.W   #$D2D0, $4010 * ADDA.W    (A0),A1
  MOVE.W   #$D3D0, $4012 * ADDA.L    (A0),A1
  MOVE.W   #$DED7, $4014 * ADDA.W    (A7),A7
  MOVE.W   #$DFD7, $4016 * ADDA.L    (A7),A7

  MOVE.W   #$D2D8, $4018 * ADDA.W    (A0)+,A1
  MOVE.W   #$D3D8, $401A * ADDA.L    (A0)+,A1
  MOVE.W   #$DEDF, $401C * ADDA.W    (A7)+,A7
  MOVE.W   #$DFDF, $401E * ADDA.L    (A7)+,A7

  MOVE.W   #$D2E0, $4020 * ADDA.W    -(A0),A1
  MOVE.W   #$D3E0, $4022 * ADDA.L    -(A0),A1
  MOVE.W   #$DEE7, $4024 * ADDA.W    -(A7),A7
  MOVE.W   #$DFE7, $4026 * ADDA.L    -(A7),A7

  MOVE.W   #$D3F9, $4028 * ADDA.L    DEADBEEF,A1
  MOVE.L   #$00001032, $402A

  MOVE.W   #$D4F9, $402E * ADDA.W    DEAD,A1
  MOVE.L   #$00001032, $4030

  MOVE.W   #$D7FC, $4034 * ADDA.W    #$DEADBEEF,A1
  MOVE.L   #$DEADBEEF, $4036


* ------ MOVE TEST ------
  MOVE.W    #$1200, $4000   * MOVE.B    D0,D1
  MOVE.W    #$3804, $4002   * MOVE.W    D4,D4
  MOVE.W    #$2E07, $4004   * MOVE.L    D7,D7

  MOVE.W    #$380C, $4006   * MOVE.W    A4,D4
  MOVE.W    #$2E0F, $4008   * MOVE.L    A7,D7

  MOVE.W    #$1290, $400A   * MOVE.B    (A0),(A1)
  MOVE.W    #$3894, $400C   * MOVE.W    (A4),(A4)
  MOVE.W    #$2E97, $400E   * MOVE.L    (A7),(A7)

  MOVE.W    #$12D8, $4010   * MOVE.B    (A0)+,(A1)+
  MOVE.W    #$38DC, $4012   * MOVE.W    (A4)+,(A4)+
  MOVE.W    #$2EDF, $4014   * MOVE.L    (A7)+,(A7)+

  MOVE.W    #$1320, $4016   * MOVE.B    -(A0),-(A1)
  MOVE.W    #$3924, $4018   * MOVE.W    -(A4),-(A4)
  MOVE.W    #$2F27, $401A   * MOVE.L    -(A7),-(A7)

  MOVE.W    #$33CC, $401C   * MOVE.W    A4,TEST2
  MOVE.L    #$00001028, $401E * (Data portion)

  MOVE.W    #$23CF, $4022   * MOVE.L    A7,TEST3
  MOVE.L    #$00001028, $4024 * Data portion)

  MOVE.W    #$3239, $402C   * MOVE.W    TEST2,D1
  MOVE.L    #$00001034, $402E * (Data portion)

  MOVE.W    #$2439, $4032   * MOVE.L    TEST3,D2
  MOVE.L    #$00001034, $4034 * Data portion)

  MOVE.W    #$23F9, $4038 * MOVE.L  TEST1,TEST2
  MOVE.L    #$0000100A, $403A * Data1 Portion
  MOVE.L    #$0000100C, $403E * Data2 Portion


* ------ MOVEM TEST ------

  MOVE.L    #$48911400, $4000 * MOVEM.W   A2/A4, (A1)
  MOVE.L    #$48D10014, $4004 * MOVEM.L   D2/D4, (A1)
  MOVE.L    #$48A20180, $4008 * MOVEM.W   D7/A0, -(A2)
  MOVE.L    #$48E20FF8, $400C * MOVEM.L   D4-A4, -(A2)

  MOVE.L    #$48B9FFFF, $4010 * MOVEM.W   D0-A7, $1040
  MOVE.L    #$00001040, $4014 * (EA Data)

  MOVE.L    #$48F9FFFF, $4018 * MOVEM.W   D0-A7, $1042
  MOVE.L    #$00001042, $401C * (EA Data)

  MOVE.L    #$4C911400, $4020 * MOVEM.W   (A1), A2/A4
  MOVE.L    #$4CD10014, $4024 * MOVEM.L   (A1), D2/D4
  MOVE.L    #$4C9A0180, $4028 * MOVEM.W   (A2)+, D7/A0
  MOVE.L    #$4CDA1FF0, $402C * MOVEM.L   (A2)+, D4-A4

  MOVE.L    #$4CB9FFFF, $4030 * MOVEM.W $1040, D0-A7
  MOVE.L    #$00001040, $4034 * (EA Data)

  MOVE.L    #$4CF9FFFF, $4038 * MOVEM.L $1042, D0-A7
  MOVE.L    #$00001042, $403C * (EA Data)


* ------ MOVEA TEST ------

  MOVE.W    #$2449, $4000   * MOVEA.L   A1,A2
  MOVE.W    #$364A, $4002   * MOVEA.W   A2,A3
  MOVE.W    #$284B, $4004   * MOVEA.L   A3,A4
  MOVE.W    #$3A4C, $4006   * MOVEA.W   A4,A5
  MOVE.W    #$2C4D, $4008   * MOVEA.L   A5,A6


* ------ MOVEQ TEST ------

  MOVE.W    #$7200, $4000   * MOVEQ #0,D1
  MOVE.W    #$7401, $4002   * MOVEQ #1,D2
  MOVE.W    #$7E0A, $4004   * MOVEQ #10,D7
  MOVE.W    #$7AFF, $4006   * MOVEQ #255,D5


* ------ ASL TEST ------
   MOVE.W     #$E940,$4000	* ASL	#8,D0
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
   MOVE.W     #$E26A,$4024	* LSR	D1,S2
   MOVE.W     #$E2DC,$4028	* LSR 	(A4)+
   MOVE.W     #$E0D2,$402C	* LSR 	A4 (ILLEGAL)

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
