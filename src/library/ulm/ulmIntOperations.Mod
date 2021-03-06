(* Ulm's Oberon Library
   Copyright (C) 1989-1997 by University of Ulm, SAI, D-89069 Ulm, Germany
   ----------------------------------------------------------------------------
   Ulm's Oberon Library is free software; you can redistribute it
   and/or modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either version
   2 of the License, or (at your option) any later version.

   Ulm's Oberon Library is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   ----------------------------------------------------------------------------
   E-mail contact: oberon@mathematik.uni-ulm.de
   ----------------------------------------------------------------------------
   $Id: IntOperatio.om,v 1.1 1997/04/03 09:38:51 borchert Exp $
   ----------------------------------------------------------------------------
   $Log: IntOperatio.om,v $
   Revision 1.1  1997/04/03  09:38:51  borchert
   Initial revision

   ----------------------------------------------------------------------------
*)

MODULE ulmIntOperations; (* Frank B.J. Fischer *)

   IMPORT Operations := ulmOperations, PersistentObjects := ulmPersistentObjects, Services := ulmServices, Streams := ulmStreams, Types := ulmTypes, SYSTEM;

(* SYSTEM added to make casts necessary to port ulm library because ulm compiler is not as strict (read it's wrong) as it had to be --noch *)

   CONST 
      mod* = 5; pow* = 6; inc* = 7; dec* = 8; mmul* = 9; mpow* = 10;
      odd* = 11; shift* = 12;

   TYPE 
      Operation* = Operations.Operation;  (* Operations.add..mpow *)
      Operand* = POINTER TO OperandRec;

   TYPE
      CapabilitySet* = Operations.CapabilitySet; 
	 (* SET of [Operations.add..shift] *)
      IsLargeEnoughForProc* = PROCEDURE (op: Operations.Operand;
					n: LONGINT): BOOLEAN;
      UnsignedProc* = PROCEDURE (op: Operations.Operand): BOOLEAN;
      IntToOpProc* = PROCEDURE (int32: Types.Int32; VAR op: Operations.Operand);
      OpToIntProc* = PROCEDURE (op: Operations.Operand; VAR int32: Types.Int32);
      Log2Proc* = PROCEDURE (op: Operations.Operand): LONGINT;
      OddProc* = PROCEDURE (op: Operations.Operand): BOOLEAN;
      ShiftProc* = PROCEDURE (op: Operations.Operand; 
			     n: INTEGER): Operations.Operand;
      IntOperatorProc* = PROCEDURE(op: Operation; 
				  op1, op2, op3: Operations.Operand; 
				  VAR result: Operations.Operand);
      Interface* = POINTER TO InterfaceRec;
      InterfaceRec* = RECORD
			(Operations.InterfaceRec)
			isLargeEnoughFor*: IsLargeEnoughForProc;
			unsigned*        : UnsignedProc;
			intToOp*         : IntToOpProc;
			opToInt*         : OpToIntProc;
			log2*            : Log2Proc;
			odd*             : OddProc;
			shift*           : ShiftProc;
			intOp*           : IntOperatorProc;
                     END;

   TYPE
      OperandRec* = RECORD
	              (Operations.OperandRec);
		      (* private components *)
		      if  : Interface;
		      caps: CapabilitySet;
                   END;

   VAR
      operandType: Services.Type;


   PROCEDURE Init*(op: Operand; if: Interface; caps: CapabilitySet);
   BEGIN
      Operations.Init(op, if, caps);
      op.if := if;
      op.caps := caps;
   END Init;


   PROCEDURE Capabilities*(op: Operand): CapabilitySet;
   BEGIN
      RETURN op.caps
   END Capabilities;


   PROCEDURE IsLargeEnoughFor*(op: Operations.Operand; n: LONGINT): BOOLEAN;
   BEGIN
      WITH op: Operand DO
	 RETURN op.if.isLargeEnoughFor(op, n)
      END;
   END IsLargeEnoughFor;


   PROCEDURE Unsigned*(op: Operations.Operand): BOOLEAN;
   BEGIN
      WITH op: Operand DO
	 RETURN op.if.unsigned(op)
      END;
   END Unsigned;


   PROCEDURE IntToOp*(int32: Types.Int32; VAR op: Operations.Operand);
      (* converts int32 into operand type, and stores result in already
	 initialized op
      *)
   BEGIN
      (*WITH op: Operand DO*)
      (*
        with original ulm source we were getting:

        WITH op: Operand DO
	      ^
    pos  4101  err 245  guarded pointer variable may be manipulated by non-local operations; use auxiliary pointer variable
      
      thus we considered changing WITH op: Operand by op(Operand) 
       
       -- noch

      *)
         (*ASSERT(op.if # NIL);*)
         ASSERT(op(Operand).if # NIL);
         (*op.if.intToOp(int32, op);*)
         op(Operand).if.intToOp(int32, op(Operations.Operand));
      (*END;*)
   END IntToOp;


   PROCEDURE OpToInt*(op: Operations.Operand; VAR int32: Types.Int32);
      (* converts op into int32 *)
   BEGIN
      WITH op: Operand DO
	 op.if.opToInt(op, int32);
      END;
   END OpToInt;


   PROCEDURE Log2*(op: Operations.Operand): LONGINT;
   BEGIN
      WITH op: Operand DO
	 RETURN op.if.log2(op)
      END;
   END Log2;


   PROCEDURE Odd*(op: Operations.Operand): BOOLEAN;
   BEGIN
      WITH op: Operand DO
         ASSERT(odd IN op.caps);
         RETURN op.if.odd(op)
      END;
   END Odd;


   PROCEDURE Op(op: Operation; op1, op2, op3: Operations.Operand; 
		VAR result: Operations.Operand);
      VAR
         tmpresult: Operations.Operand;
   BEGIN
      WITH op1: Operand DO
	    IF (op2#NIL) & (op3#NIL) THEN 
	       ASSERT((op1.if = op2(Operand).if) & 
		      (op2(Operand).if = op3(Operand).if));
	    ELSIF (op2#NIL) THEN
	       ASSERT(op1.if = op2(Operand).if);
	    END;
	    ASSERT(op IN op1.caps);
	    op1.if.create(tmpresult);
	    op1.if.intOp(op, op1, op2, op3, tmpresult);
	    result := tmpresult;
      END;
   END Op;


   PROCEDURE Shift*(op1: Operations.Operand; n: INTEGER): Operations.Operand;
   BEGIN
      WITH op1: Operand DO
         ASSERT(shift IN op1.caps);
         RETURN op1.if.shift(op1,n);
      END;
   END Shift;


   PROCEDURE Shift2*(VAR op1: Operations.Operand; n: INTEGER);
   BEGIN
      op1 := Shift(op1, n);
   END Shift2;


   PROCEDURE Shift3*(VAR result: Operations.Operand; op1: Operations.Operand; 
		    n : INTEGER);
      VAR
         tmpresult: Operations.Operand;
   BEGIN
      WITH op1: Operand DO
	 op1.if.create(tmpresult);
	 tmpresult := Shift(op1, n);
	 result := tmpresult;
      END;
   END Shift3;


   PROCEDURE Inc*(op1: Operations.Operand): Operations.Operand;
      VAR
         result: Operations.Operand;
   BEGIN
      result := NIL;
      Op(inc,op1,NIL,NIL,result);
      RETURN result
   END Inc;


   PROCEDURE Inc2*(VAR op1: Operations.Operand);
   BEGIN
      Op(inc,op1,NIL,NIL,op1);
   END Inc2;


   PROCEDURE Inc3*(VAR result: Operations.Operand; op1: Operations.Operand);
   BEGIN
      Op(inc,op1,NIL,NIL,result);
   END Inc3;
    

   PROCEDURE Dec*(op1: Operations.Operand): Operations.Operand;
      VAR
         result: Operations.Operand;
   BEGIN
      result := NIL;
      Op(dec,op1,NIL,NIL,result);
      RETURN result
   END Dec;


   PROCEDURE Dec2*(VAR op1: Operations.Operand);
   BEGIN
      Op(dec,op1,NIL,NIL,op1);
   END Dec2;


   PROCEDURE Dec3*(VAR result: Operations.Operand; op1: Operations.Operand);
   BEGIN
      Op(dec,op1,NIL,NIL,result);
   END Dec3;
    

   PROCEDURE Mod*(op1, op2: Operations.Operand): Operations.Operand;
      VAR
         result: Operations.Operand;
   BEGIN
      result := NIL;
      Op(mod, op1, op2, NIL, result);
      RETURN result
   END Mod;


   PROCEDURE Mod2*(VAR op1: Operations.Operand; op2: Operations.Operand);
   BEGIN
      Op(mod, op1, op2, NIL, op1);
   END Mod2;


   PROCEDURE Mod3*(VAR result: Operations.Operand; op1, op2: Operations.Operand);
   BEGIN
      Op(mod, op1, op2, NIL, result);
   END Mod3;


   PROCEDURE Pow*(op1, op2: Operations.Operand): Operations.Operand;
      VAR
         result : Operand;
   BEGIN
      result := NIL;
      (*Op(pow, op1, op2, NIL, result);*)
      Op(pow, op1, op2, NIL, SYSTEM.VAL(Operations.Operand, result)); (* -- noch *)
      RETURN result
   END Pow;


   PROCEDURE Pow2*(VAR op1: Operations.Operand; op2: Operations.Operand);
   BEGIN
      Op(pow, op1, op2, NIL, op1);
   END Pow2;


   PROCEDURE Pow3*(VAR result: Operations.Operand; op1, op2: Operations.Operand);
   BEGIN
      Op(pow, op1, op2, NIL, result);
   END Pow3;


   PROCEDURE MMul*(op1, op2, op3: Operations.Operand): Operations.Operand;
      VAR
         result : Operand;
   BEGIN
      result := NIL;
      (*Op(mmul, op1, op2, op3, result); *)
      Op(mmul, op1, op2, op3, SYSTEM.VAL(Operations.Operand, result)); (* --noch*)
      RETURN result
   END MMul;


   PROCEDURE MMul2*(VAR op1: Operations.Operand; op2, op3: Operations.Operand);
   BEGIN
      Op(mmul, op1, op2, op3, op1);
   END MMul2;


   PROCEDURE MMul3*(VAR result: Operations.Operand; 
		   op1, op2, op3: Operations.Operand);
   BEGIN
      Op(mmul, op1, op2, op3, result);
   END MMul3;


   PROCEDURE MPow*(op1, op2, op3: Operations.Operand): Operations.Operand;
      VAR
         result : Operand;
   BEGIN
      result := NIL;
      (*Op(mpow, op1, op2, op3, result); *)
      Op(mpow, op1, op2, op3, SYSTEM.VAL(Operations.Operand, result)); (* -- noch*)
      RETURN result
   END MPow;


   PROCEDURE MPow2*(VAR op1: Operations.Operand; op2, op3: Operations.Operand);
   BEGIN
      Op(mpow, op1, op2, op3, op1);
   END MPow2;


   PROCEDURE MPow3*(VAR result: Operations.Operand; 
		   op1, op2, op3: Operations.Operand);
   BEGIN
      Op(mpow, op1, op2, op3, result);
   END MPow3;


BEGIN
    PersistentObjects.RegisterType(operandType,"IntOperations.Operand",
                                   "Operations.Operand", NIL);
END ulmIntOperations.
