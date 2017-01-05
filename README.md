# Simple MIPS SC for FPGAedu

Simple Single Cycle MIPS Processor implemented in VHDL. Original taken from 
https://github.com/tcamolesi/simple-mips and adapted to FPGAedu platform. This
implementation is part of a project that explores the capabilities of the 
concept of an address space as a means of interaction with stateful
elements contained within digital logic designs. The project report is 
contained within the `report/` directory. 

## Instruction Set
Supported Instructions:
  + I-Type
    - ADDI

  + R-Type
    - ADD
    - SUB
    - AND
    - OR
    - SLT

  + Branch
    - BNE
    - BEQ

  + J-Type
    - J
