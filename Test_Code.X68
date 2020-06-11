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
  MOVE.W  #$D151, $4014 * ADD.W   D0,(A1)
  MOVE.W  #$D191, $4016 * ADD.L   D0,(A1)
  MOVE.W  #$D049, $4018 * ADD.W   A1,D0
  MOVE.W  #$D089, $401A * ADD.L   A1,D0

  MOVE.W  #$DF57, $401C * ADD.W   D7,(A7)
  MOVE.W  #$DF97, $401E * ADD.L   D7,(A7)
  MOVE.W  #$DE4F, $4020 * ADD.W   A7,D7
  MOVE.W  #$DE8F, $4022 * ADD.L   A7,D7

* ------ SUB TEST ------
  MOVE.W  #$9151, $4024 * SUB.W   D0,(A1)
  MOVE.W  #$9191, $4026 * SUB.L   D0,(A1)
  MOVE.W  #$9049, $4028 * SUB.W   A1,D0
  MOVE.W  #$9089, $402A * SUB.L   A1,D0

  MOVE.W  #$9F57, $402C * SUB.W   D7,(A7)
  MOVE.W  #$9F97, $402E * SUB.L   D7,(A7)
  MOVE.W  #$9E4F, $4030 * SUB.W   A7,D7
  MOVE.W  #$9E8F, $4032 * SUB.L   A7,D7

* ------ AND TEST ------
  MOVE.W  #$C151, $4034 * AND.W   D0,(A1)
  MOVE.W  #$C191, $4036 * AND.L   D0,(A1)
  MOVE.W  #$C042, $4038 * AND.W   D2,D0
  MOVE.W  #$C082, $403A * AND.L   D2,D0

  MOVE.W  #$CF57, $403C * AND.W   D7,(A7)
  MOVE.W  #$CF97, $403E * AND.L   D7,(A7)
  MOVE.W  #$CE46, $4040 * AND.W   D6,D7
  MOVE.W  #$CE86, $4042 * AND.L   D6,D7

* ------ OR TEST ------
  MOVE.W  #$8151, $4044 * OR.W   D0,(A1)
  MOVE.W  #$8191, $4046 * OR.L   D0,(A1)
  MOVE.W  #$8042, $4048 * OR.W   D2,D0
  MOVE.W  #$8082, $404A * OR.L   D2,D0

  MOVE.W  #$8F57, $404C * OR.W   D7,(A7)
  MOVE.W  #$8F97, $404E * OR.L   D7,(A7)
  MOVE.W  #$8E46, $4050 * OR.W   D6,D7
  MOVE.W  #$8E86, $4052 * OR.L   D6,D7

* ------ NOT TEST ------

  MOVE.W  #$4600, $4054 * NOT.B   D0
  MOVE.W  #$4640, $4056 * NOT.W   D0
  MOVE.W  #$4680, $4058 * NOT.L   D0

  MOVE.W  #$4651, $405A * NOT.W   (A1)
  MOVE.W  #$4692, $405C * NOT.L   (A2)

* ------ LEA TEST ------

  MOVE.W  #$41D0, $405E * LEA (A0),A0
  MOVE.W  #$4FD7, $4060 * LEA (A7),A7

  MOVE.W  #$45F9, $4062 * LEA $0000100A,A2
  MOVE.L  #$0000100A, $4064 * (Data portion)



* ------ ADDQ TEST ------
  MOVE.W  #$5200, $4066 * ADDQ.B  #1,D0
  MOVE.W  #$5441, $4068 * ADDQ.W  #2,D1
  MOVE.W  #$5682, $406A * ADDQ.L  #3,D2

  MOVE.W  #$5E51, $406C * ADDQ.W  #7,(A1)
  MOVE.W  #$505F, $406E * ADDQ.W  #8,(A7)+




* ------ ADDA TEST ------
  MOVE.W   #$D2C0, $4070 * ADDA.W    D0,A1
  MOVE.W   #$D3C0, $4072 * ADDA.L    D0,A1
  MOVE.W   #$DEC7, $4074 * ADDA.W    D7,A7
  MOVE.W   #$DFC7, $4076 * ADDA.L    D7,A7

  MOVE.W   #$D2C8, $4078 * ADDA.W    A0,A1
  MOVE.W   #$D5C9, $407A * ADDA.L    A1,A2
  MOVE.W   #$D6CA, $407C * ADDA.W    A2,A3
  MOVE.W   #$DFCE, $407E * ADDA.L    A6,A7

  MOVE.W   #$D2D0, $4080 * ADDA.W    (A0),A1
  MOVE.W   #$D3D0, $4082 * ADDA.L    (A0),A1
  MOVE.W   #$DED7, $4084 * ADDA.W    (A7),A7
  MOVE.W   #$DFD7, $4086 * ADDA.L    (A7),A7

  MOVE.W   #$D2D8, $4088 * ADDA.W    (A0)+,A1
  MOVE.W   #$D3D8, $408A * ADDA.L    (A0)+,A1
  MOVE.W   #$DEDF, $408C * ADDA.W    (A7)+,A7
  MOVE.W   #$DFDF, $408E * ADDA.L    (A7)+,A7

  MOVE.W   #$D2E0, $4090 * ADDA.W    -(A0),A1
  MOVE.W   #$D3E0, $4092 * ADDA.L    -(A0),A1
  MOVE.W   #$DEE7, $4094 * ADDA.W    -(A7),A7
  MOVE.W   #$DFE7, $4096 * ADDA.L    -(A7),A7

  MOVE.W   #$D3F9, $4098 * ADDA.L    DEADBEEF,A1
  MOVE.L   #$00001032, $409A

  MOVE.W   #$D4F9, $409E * ADDA.W    DEAD,A1
  MOVE.L   #$00001032, $40A0

  MOVE.W   #$D7FC, $40A4 * ADDA.W    #$DEADBEEF,A1
  MOVE.L   #$DEADBEEF, $40A6


* ------ MOVE TEST ------
  MOVE.W    #$1200, $40AA   * MOVE.B    D0,D1
  MOVE.W    #$3804, $40AC   * MOVE.W    D4,D4
  MOVE.W    #$2E07, $40AE   * MOVE.L    D7,D7

  MOVE.W    #$380C, $40B0   * MOVE.W    A4,D4
  MOVE.W    #$2E0F, $40B2   * MOVE.L    A7,D7

  MOVE.W    #$1290, $40B4   * MOVE.B    (A0),(A1)
  MOVE.W    #$3894, $40B6   * MOVE.W    (A4),(A4)
  MOVE.W    #$2E97, $40B8   * MOVE.L    (A7),(A7)

  MOVE.W    #$12D8, $40BA   * MOVE.B    (A0)+,(A1)+
  MOVE.W    #$38DC, $40BC   * MOVE.W    (A4)+,(A4)+
  MOVE.W    #$2EDF, $40BE   * MOVE.L    (A7)+,(A7)+

  MOVE.W    #$1320, $40C0   * MOVE.B    -(A0),-(A1)
  MOVE.W    #$3924, $40C2   * MOVE.W    -(A4),-(A4)
  MOVE.W    #$2F27, $40C4   * MOVE.L    -(A7),-(A7)

  MOVE.W    #$33CC, $40C6   * MOVE.W    A4,TEST2
  MOVE.L    #$00001028, $40C8 * (Data portion)

  MOVE.W    #$23CF, $40CC   * MOVE.L    A7,TEST3
  MOVE.L    #$00001028, $40CE * Data portion)

  MOVE.W    #$3239, $40D2   * MOVE.W    TEST2,D1
  MOVE.L    #$00001034, $40D4 * (Data portion)

  MOVE.W    #$2439, $40D8   * MOVE.L    TEST3,D2
  MOVE.L    #$00001034, $40DA * Data portion)

  MOVE.W    #$23F9, $40DE * MOVE.L  TEST1,TEST2
  MOVE.L    #$0000100A, $40E0 * Data1 Portion
  MOVE.L    #$0000100C, $40E4 * Data2 Portion


* ------ MOVEM TEST ------

  MOVE.L    #$48911400, $40E8 * MOVEM.W   A2/A4, (A1)
  MOVE.L    #$48D10014, $40EC * MOVEM.L   D2/D4, (A1)
  MOVE.L    #$48A20180, $40F0 * MOVEM.W   D7/A0, -(A2)
  MOVE.L    #$48E20FF8, $40F4 * MOVEM.L   D4-A4, -(A2)

  MOVE.L    #$48B9FFFF, $40F8 * MOVEM.W   D0-A7, $1040
  MOVE.L    #$00001040, $40FC * (EA Data)
  
  MOVE.L    #$48F9FFFF, $4100 * MOVEM.W   D0-A7, $1042
  MOVE.L    #$00001042, $4104 * (EA Data)
  
  MOVE.L    #$4C911400, $4108 * MOVEM.W   (A1), A2/A4
  MOVE.L    #$4CD10014, $410C * MOVEM.L   (A1), D2/D4
  MOVE.L    #$4C9A0180, $4110 * MOVEM.W   (A2)+, D7/A0
  MOVE.L    #$4CDA1FF0, $4114 * MOVEM.L   (A2)+, D4-A4

  MOVE.L    #$4CB9FFFF, $4118 * MOVEM.W $1040, D0-A7
  MOVE.L    #$00001040, $411C * (EA Data)

  MOVE.L    #$4CF9FFFF, $4120 * MOVEM.L $1042, D0-A7
  MOVE.L    #$00001042, $4124 * (EA Data)


* ------ MOVEA TEST ------

  MOVE.W    #$2449, $4128   * MOVEA.L   A1,A2
  MOVE.W    #$364A, $412A   * MOVEA.W   A2,A3
  MOVE.W    #$284B, $412C   * MOVEA.L   A3,A4
  MOVE.W    #$3A4C, $412E   * MOVEA.W   A4,A5
  MOVE.W    #$2C4D, $4130   * MOVEA.L   A5,A6


* ------ MOVEQ TEST ------

  MOVE.W    #$7200, $4132   * MOVEQ #0,D1
  MOVE.W    #$7401, $4134   * MOVEQ #1,D2
  MOVE.W    #$7E0A, $4136   * MOVEQ #10,D7
  MOVE.W    #$7AFF, $4138   * MOVEQ #255,D5


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

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
