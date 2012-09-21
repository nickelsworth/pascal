{        SUPERPASCAL INTERPRETER
             20 August 1993
  Copyright (c) 1993 Per Brinch Hansen }

program interpret(input, output);
#include "common.p"

procedure run(
  var codefile: binary;
  var inpfile, outfile: text);
const minaddr = 1;
type
  store =
    array [minaddr..maxaddr] of
      integer;
  blocktable =
    array [1..maxblock] of integer;
  channeltable =
    array [1..maxchan] of integer;
var
  { permanent variables }
  b, cmax, p, ready, s,
  stackbottom, t: integer;
  running: boolean;
  st: store;
  free: blocktable;
  open: channeltable;

  { temporary variables }
  bi, blockno, c, i,
  j, k, length, level,
  lineno, lower, m, n,
  pi, si, templength,
  typeno, typeno2, upper,
  width, x, y: integer;
  dx, dy: dualreal;
  sx: string;
  cx: char;
  
{ Local procedures in run }

procedure error(lineno: integer; 
  kind: phrase);
begin
  writeln('line ', lineno:4, sp,
    kind:phraselength(kind));
  running := false
end;

procedure rangeerror(
  lineno: integer);
begin
  error(lineno, range4)
end;

procedure memorylimit(
  lineno: integer);
begin
  error(lineno, maxaddr5)
end;

procedure load(
  var codefile: binary);
var i: integer;
begin
  i := minaddr;
  while not eof(codefile)
    and (i < maxaddr) do 
      begin
        read(codefile, st[i]);
        i := i + 1
      end;
  if not eof(codefile)
    then memorylimit(1)
    else stackbottom := i
end;

procedure activate(
  bvalue, svalue, pvalue:
  integer);
begin
  svalue := svalue + 3;
  st[svalue - 2] := pvalue;
  st[svalue - 1] := bvalue;
  st[svalue] := ready;
  ready := svalue
end;

procedure select(
  lineno: integer);
begin
  if ready = 0 then
    error(lineno, deadlock4)
  else
    begin
      s := ready;
      ready := st[s];
      b := st[s - 1];
      p := st[s - 2];
      s := s - 3
    end
end;

procedure popstring(
  var value: string);
var i: integer;
begin
  s := s - maxstring;
  for i := 1 to maxstring do
    value[i] := chr(st[s + i])
end;

begin
  load(codefile);
  p := minaddr;
  running := true;
  while running do
    case st[p] of

    { VariableAccess =
        VariableName
        [ ComponentSelector ]* .
      VariableName =
        "variable" | "varparam" .
      ComponentSelector =
        Expression "index" |
        "field" . }

      variable2{level, displ}:
        begin
          level := st[p + 1];
          s := s + 1;
          x := b;
          while level > 0 do
            begin
              x := st[x];
              level := level - 1
            end;
          st[s] := x + st[p + 2];
          p := p + 3
        end;

      varparam2{level, displ}:
        begin
          level := st[p + 1];
          s := s + 1;
          x := b;
          while level > 0 do
            begin
              x := st[x];
              level := level - 1
            end;
          st[s] := st[x + st[p + 2]];
          p := p + 3
        end;

      index2{lower, upper, length,
          lineno}:
        begin
          lower := st[p + 1];
          i := st[s];
          s := s - 1;
          if (i < lower) or
            (i > st[p + 2]) then
              rangeerror(st[p + 4])
          else
            begin
              st[s] := st[s] +
                (i - lower) *
                  st[p + 3];
               p := p + 5
            end
        end;

      field2{displ}:
        begin
          st[s] :=
            st[s] + st[p + 1];
          p := p + 2
        end;

    { StandardFunctionDesignator =
        FileFunctionDesignator |
        MathFunctionDesignator .
      FileFunctionDesignator =
        "eol" | "eoln" . } 

      eof2{lineno}:
        begin
          s := s + 1;
          st[s] :=
            ord(eof(inpfile));
          p := p + 2
        end;

      eoln2{lineno}:
        begin
          s := s + 1;
          st[s] :=
            ord(eoln(inpfile));
          p := p + 2
        end;

    { MathFunctionDesignator =
        Expression [ "float" ]
          MathFunctionIdentifier .
      MathFunctionIdentifier =
        Abs | "arctan" | "chr" |
        "cos" | "exp" | "ln" |
        "odd" | "pred" | "round" |
        "sin" | Sqr | "sqrt" |
        "succ" | "trunc" .
      Abs =
       "abs" | "absint" .
      Sqr =
       "sqr" | "sqrint" . }

      float2:
        begin
          dx.a := st[s];
          s := s + 1;
          st[s - 1] := dx.b;
          st[s] := dx.c;
          p := p + 1
        end;

      abs2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := abs(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      absint2{lineno}:
        begin
          st[s] := abs(st[s]);
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      arctan2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := arctan(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      chr2{lineno}:
        begin
          x := st[s];
          if (x < null) or (x > del)
            then
              rangeerror(st[p + 1])
            else p := p + 2
        end;

      cos2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := cos(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      exp2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := exp(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
             rangeerror(st[p + 1])
          else } p := p + 2
        end;

      ln2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := ln(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      odd2:
        begin
          st[s] := ord(odd(st[s]));
          p := p + 1
        end;

      pred2{minvalue, lineno}:
        begin
          if st[s] > st[p + 1] then
            begin
              st[s] := pred(st[s]);
              p := p + 3
            end
          else
            rangeerror(st[p + 2])
        end;

      round2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          s := s - 1;
          st[s] := round(dx.a);
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      sin2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := sin(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      sqr2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := sqr(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      sqrint2{lineno}:
        begin
          st[s] := sqr(st[s]);
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      sqrt2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := sqrt(dx.a);
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      succ2{maxvalue, lineno}:
        begin
          if st[s] < st[p + 1] then
            begin
              st[s] := succ(st[s]);
              p := p + 3
            end
          else
            rangeerror(st[p + 2])
        end;

      trunc2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          s := s - 1;
          st[s] := trunc(dx.a);
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

    { FunctionDesignator =
       "result"
         ActualParameterPart
           "proccall" |
      StandardFunctionDesignator .
      ActualParameterPart =
        [ ActualParameter ]* .
      ActualParameter =
        Expression [ "float" ] |
        VariableAccess . }

      result2{length}:
        begin
          s := s + st[p + 1];
          p := p + 2
        end;

      proccall2{level, displ}:
        begin
          level := st[p + 1];
          s := s + 1;
          x := b;
          while level > 0 do
            begin
              x := st[x];
              level := level - 1
            end;
          st[s] := x;
          st[s + 2] := p + 3;
          p := p + st[p + 2]
        end;

    { ConstantFactor =
        "ordconst"| "realconst" |
        "strconst" . }

      ordconst2{value}:
        begin
          s := s + 1;
          st[s] := st[p + 1];
          p := p + 2
        end;

      realconst2{value}:
        begin
          st[s + 1] := st[p + 1];
          st[s + 2] := st[p + 2];
          s := s + 2;
          p := p + 3
        end;

      stringconst2{length, value}:
        begin
          length := st[p + 1];
          for i := 1 to length do
            st[s + i] :=
              st[p + i + 1];
          for i := length + 1
            to maxstring do
              st[s + i] := null;
          s := s + maxstring;
          p := p + length + 2
        end;

    { Factor =
        ConstantFactor |
        VariableAccess "value" |
        FunctionDesignator |
        Expression |
        Factor [ "not" ] . }

      value2{length}:
        begin
          length := st[p + 1];
          x := st[s];
          for i := 0 to
            length - 1 do
              st[s + i] :=
                st[x + i];
          s := s + length - 1;
          p := p + 2
        end;

      not2:
        begin
          if st[s] = ord(true)
            then
              st[s] := ord(false)
            else
              st[s] := ord(true);
          p := p + 1
        end;

    { Term =
        Factor [ Factor [ Float ]
          MultiplyingOperator ]* .
      Float =
        "floatleft" | "float" .
      MultiplyingOperator =
        Multiply | Divide |
        "modulo" | "and" .
      Multiply =
        "multiply" | "multreal" .
      Divide =
        "divide" | "divreal" . }

      floatleft2:
        begin
          dx.a := st[s - 2];
          s := s + 1;
          st[s] := st[s - 1];
          st[s - 1] := st[s - 2];
          st[s - 3] := dx.b;
          st[s - 2] := dx.c;
          p := p + 1
        end;

      multiply2{lineno}:
        begin
          s := s - 1;
          st[s] :=
            st[s] * st[s + 1];
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      divide2{lineno}:
        begin
          s := s - 1;
          st[s] :=
            st[s] div st[s + 1];
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      modulo2{lineno}:
        begin
          s := s - 1;
          st[s] :=
            st[s] mod st[s + 1];
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      multreal2{lineno}:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 2;
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := dx.a * dy.a;
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      divreal2{lineno}:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 2;
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := dx.a / dy.a;
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      and2:
        begin
          s := s - 1;
          if st[s] = ord(true)
            then
              st[s] := st[s + 1];
          p := p + 1
        end;

    { SimpleExpression =
        Term [ Sign ]
          [ Term [ Float ]
            AddingOperator ]* .
      Sign =
        Empty | Minus .
      Minus =
        "minus" | "minusreal" .
      AddingOperator =
        Add | Subtract | "or" .
      Add =
        "add" | "addreal" .
      Subtract =
        "subtract" |
        "subreal" . }

      minus2{(lineno}:
        begin
          st[s] := - st[s];
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      minusreal2{lineno}:
        begin
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := - dx.a;
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      add2{lineno}:
        begin
          s := s - 1;
          st[s] :=
            st[s] + st[s + 1];
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      subtract2{lineno}:
        begin
          s := s - 1;
          st[s] :=
            st[s] - st[s + 1];
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      addreal2{lineno}:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 2;
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := dx.a + dy.a;
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      subreal2{lineno}:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 2;
          dx.b := st[s - 1];
          dx.c := st[s];
          dx.a := dx.a - dy.a;
          st[s - 1] := dx.b;
          st[s] := dx.c;
        { if overflow then
            rangeerror(st[p + 1])
          else } p := p + 2
        end;

      or2:
        begin
          s := s - 1;
          if st[s] = ord(false) then
            st[s] := st[s + 1];
          p := p + 1
        end;

    { Expression = SimpleExpression
        [ SimpleExpression [ Float ]
          RelationalOperator ] .
      RelationalOperator =
        Less | Equal | Greater |
        NotGreater | NotEqual |
        NotLess.
      Less =
        "lsord" | "lsreal" |
        "lsstring" .
      Equal =
        "eqord" | "eqreal" |
        "eqstrig" | "equal" .
      Greater =
        "grord" | "grreal" |
        "grstring" .
      NotGreater =
        "ngord" | "ngreal" |
        "ngstring" .
      NotEqual =
        "neord" | "nereal" |
        "nestring" | "notequal" .
      NotLess =
        "nlord" | "nlreal" |
        "nlstring" . }

      lsord2:
        begin
          s := s - 1;
          st[s] :=
            ord(st[s] < st[s + 1]);
          p := p + 1
        end;

      eqord2:
        begin
          s := s - 1;
          st[s] :=
            ord(st[s] = st[s + 1]);
          p := p + 1
        end;

      grord2:
        begin
          s := s - 1;
          st[s] :=
            ord(st[s] > st[s + 1]);
          p := p + 1
        end;

      ngord2:
        begin
          s := s - 1;
          st[s] :=
            ord(st[s] <= st[s + 1]);
          p := p + 1
        end;

      neord2:
        begin
          s := s - 1;
          st[s] :=
            ord(st[s] <> st[s + 1]);
          p := p + 1
        end;

      nlord2:
        begin
          s := s - 1;
          st[s] :=
            ord(st[s] >= st[s + 1]);
          p := p + 1
        end;

      lsreal2:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 3;
          dx.b := st[s];
          dx.c := st[s + 1];
          st[s] := ord(dx.a < dy.a);
          p := p + 1
        end;

      eqreal2:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 3;
          dx.b := st[s];
          dx.c := st[s + 1];
          st[s] := ord(dx.a = dy.a);
          p := p + 1
        end;

      grreal2:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 3;
          dx.b := st[s];
          dx.c := st[s + 1];
          st[s] := ord(dx.a > dy.a);
          p := p + 1
        end;

      ngreal2:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 3;
          dx.b := st[s];
          dx.c := st[s + 1];
          st[s] := ord(dx.a <= dy.a);
          p := p + 1
        end;

      nereal2:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 3;
          dx.b := st[s];
          dx.c := st[s + 1];
          st[s] := ord(dx.a <> dy.a);
          p := p + 1
        end;

      nlreal2:
        begin
          dy.b := st[s - 1];
          dy.c := st[s];
          s := s - 3;
          dx.b := st[s];
          dx.c := st[s + 1];
          st[s] := ord(dx.a >= dy.a);
          p := p + 1
        end;

      lsstring2:
        begin
          y := s - maxstring + 1;
          s := y - maxstring;
          i := 0;
          while (i < maxstring - 1)
            and 
              (st[s + i] = st[y + i])
                 do i := i + 1;
          st[s] := ord(st[s + i] <
            st[y + i]);
          p := p + 1
        end;

      eqstring2:
        begin
          y := s - maxstring + 1;
          s := y - maxstring;
          i := 0;
          while (i < maxstring - 1)
            and
              (st[s + i] = st[y + i])
                do i := i + 1;
          st[s] := ord(st[s + i] =
            st[y + i]);
          p := p + 1
        end;

      grstring2:
        begin
          y := s - maxstring + 1;
          s := y - maxstring;
          i := 0;
          while (i < maxstring - 1)
            and
              (st[s + i] = st[y + i])
                do i := i + 1;
          st[s] := ord(st[s + i] >
            st[y + i]);
          p := p + 1
       end;

      ngstring2:
        begin
          y := s - maxstring + 1;
          s := y - maxstring;
          i := 0;
          while (i < maxstring - 1)
            and
              (st[s + i] = st[y + i])
                do i := i + 1;
          st[s] := ord(st[s + i] <=
            st[y + i]);
          p := p + 1
        end;

      nestring2:
        begin
          y := s - maxstring + 1;
          s := y - maxstring;
          i := 0;
          while (i < maxstring - 1)
            and
              (st[s + i] = st[y + i])
                do i := i + 1;
          st[s] := ord(st[s + i] <>
            st[y + i]);
          p := p + 1
        end;

      nlstring2:
        begin
          y := s - maxstring + 1;
          s := y - maxstring;
          i := 0;
          while (i < maxstring - 1)
            and
              (st[s + i] = st[y + i])
                do i := i + 1;
          st[s] := ord(st[s + i] >=
            st[y + i]);
          p := p + 1
        end;

      equal2{length}:
        begin
          length := st[p + 1];
          y := s - length + 1;
          s := y - length;
          i := 0;
          while (i < length - 1) and
            (st[s + i] = st[y + i])
              do i := i + 1;
          st[s] := ord(st[s + i] =
            st[y + i]);
          p := p + 2
        end;

      notequal2{length}:
        begin
          length := st[p + 1];
          y := s - length + 1;
          s := y - length;
          i := 0;
          while (i < length - 1) and
           (st[s + i] = st[y + i])
             do i := i + 1;
          st[s] := ord(st[s + i] <>
            st[y + i]);
           p := p + 2
      end;

    { AssignmentStatement =
        VariableAccess Expression
          [ "float" ] "assign" . }

      assign2{length}:
        begin
          length := st[p + 1];
          s := s - length - 1;
          x := st[s + 1];
          y := s + 2;
          for i := 0 to
            length - 1 do
              st[x + i] :=
                st[y + i];
          p := p + 2
        end;

    { ReadStatement =
        ReadParameters |
        [ ReadParameters ]
          "readln" .
      ReadParameters =
        ReadParameter
          [ ReadParameter ]* .
        ReadParameter =
          VariableAccess Read .
        Read =
          "read" | "readint" |
          "readreal" . }

      read2{lineno}:
        begin
          read(inpfile, cx);
          st[st[s]] := ord(cx);
          s := s - 1;
          p := p + 2
        end;

      readint2{lineno}:
        begin
          read(inpfile,
            st[st[s]]);
          s := s - 1;
          p := p + 2
        end;

      readreal2{lineno}:
        begin
          read(inpfile, dx.a);
          y := st[s];
          s := s - 1;
          st[y] := dx.b;
          st[y + 1] := dx.c;
          p := p + 2
       end;

      readln2{lineno}:
        begin
          readln(inpfile);
          p := p + 2
        end;

    { WriteStatement =
        WriteParameters |
        [ WriteParameters ]
          "writeln" .
      WriteParameters =
        WriteParameter
          [ WriteParameter ]* .
      WriteParameter =
        Expression
          [ TotalWidth
            [ FracDigits ] ]
              "writereal" |
        Expression
          [ TotalWidth ]
            OtherWrite .
      OtherWrite =
        "write" | "writebool" |
        "writeint" |
        "writestring" .
      TotalWidth =
        Expression .
      FracDigits =
        Expression . }

      write2{option, lineno}:
        begin
          if st[p + 1] = ord(true)
            then
              begin
                write(outfile,
                  chr(st[s - 1]):
                    st[s]);
               s := s - 2
              end
            else
              begin
                write(outfile,
                  chr(st[s]));
                s := s - 1
              end;
          p := p + 3
        end;

      writebool2{option, lineno}:
        begin
          if st[p + 1] = ord(true)
            then
              begin
                write(outfile,
                  (st[s - 1] = 1)
                    :st[s]);
                s := s - 2
              end
            else
              begin
                write(outfile,
                  st[s] = 1);
                s := s - 1
              end;
          p := p + 3
        end;

      writeint2{option, lineno}:
        begin
          if st[p + 1] = ord(true)
            then
              begin
                write(outfile,
                  st[s - 1]:
                    st[s]);
                s := s - 2
              end
            else
              begin
                write(outfile,
                  st[s]);
                s := s - 1
              end;
          p := p + 3
        end;

      writereal2{option1, option2,
          lineno}:
        begin
          if st[p + 1] = ord(true)
            then
              if st[p + 2] =
                ord(true) then
                  begin
                    s := s - 4;
                    dx.b :=
                      st[s + 1];
                    dx.c :=
                      st[s + 2];
                    m :=
                      st[s + 3];
                    n :=
                      st[s + 4];
                    write(outfile,
                      dx.a:m:n)
                  end
                else
                  begin
                    s := s - 3;
                    dx.b :=
                      st[s + 1];
                    dx.c :=
                      st[s + 2];
                    m :=
                      st[s + 3];
                    write(outfile,
                      dx.a:m)
                  end
            else
              begin
                s := s - 2;
                dx.b := st[s + 1];
                dx.c := st[s + 2];
                write(outfile,
                  dx.a);
              end;
          p := p + 4
        end;

      writestring2{option, lineno}:
        begin
          if st[p + 1] = ord(true)
            then
              begin
              { write(outfile,
                  sx:width) }
                width := st[s];
                s := s - 1;
                popstring(sx);
                writestring(outfile,
                  sx, width)
              end
            else
              begin
              { write(outfile, sx) }
                popstring(sx);
                writestring(outfile,
                  sx,
                  stringlength(sx))
              end;
          p := p + 3
        end;

      writeln2{lineno}:
        begin
          writeln(outfile);
          p := p + 2
        end;

    { OpenStatement =
        OpenParameters .
      OpenParameters =
        OpenParameter
          [ OpenParameter ]* .
      OpenParameter =
        VariableAccess "open" . }

      open2{lineno}:
        begin
          cmax := cmax + 1;
          if cmax > maxchan then
            error(st[p + 1],
              maxchan5)
          else
            begin
              open[cmax] := 0;
              st[st[s]] := cmax;
              s := s - 1;
              p := p + 2
            end
        end;

    { ReceiveStatement =
        ReceiveParameters .
      ReceiveParameters =
        ChannelExpression
          "checkio"
            InputVariableList
              "endio" .
      ChannelExpression =
        Expression .
      InputVariableList =
        InputVariableAccess
          [ InputVariableAccess ]*
            .
      InputVariableAccess =
        VariableAccess
          "receive" . }

      checkio2{lineno}:
        begin
          c := st[s];          
          if (c < 1) or (c > cmax)
            then
              error(st[p + 1],
                channel4)
          else p := p + 2
        end;

      endio2:
        begin
          s := s - 1;
          p := p + 1
        end;

      receive2{typeno, length,
          lineno}:
        begin
          typeno := st[p + 1];
          length := st[p + 2];
          lineno := st[p + 3];
          c := st[s - 1];
          si := open[c];
          if si = 0 then
            begin
              s := s + 3;
              st[s - 2] := -typeno;
              st[s - 1] := p + 4;
              st[s] := b;
              open[c] := s;
              select(lineno)
            end
          else
            begin
              typeno2 := st[si - 2];
              if typeno = typeno2 then
                begin
                  pi := st[si - 1];
                  bi := st[si];
                  si :=
                    si - length - 3;
                  x := st[s] - 1;
                  s := s - 1;
                  for i := 1 to length
                    do
                      st[x + i] :=
                        st[si + i];
                  open[c] := 0;
                  activate(bi, si, pi);
                  p := p + 4
                end
              else if typeno2 < 0 then
                error(lineno,
                  contention4)
              else
                error(lineno, type4)
            end
        end;

    { SendStatement =
        SendParameters .
      SendParameters =
        ChannelExpression
          "checkio"
            OutputExpressionList
              "endio" .
      OutputExpressionList =
        OutputExpression
          [ OutputExpression ]* .
      OutputExpression =
        Expression "send" . }

      send2{typeno, length,
          lineno}:
        begin
          typeno := st[p + 1];
          length := st[p + 2];
          lineno := st[p + 3];
          c := st[s - length];
          si := open[c];
          if si = 0 then
            begin
              s := s + 3;
              st[s - 2] := typeno;
              st[s - 1] := p + 4;
              st[s] := b;
              open[c] := s;
              select(lineno)
            end
          else
            begin
              typeno2 := st[si - 2];
              if typeno = -typeno2 then
                begin
                  pi := st[si - 1];
                  bi := st[si];
                  si := si - 4;
                  x := st[si + 1] - 1;
                  s := s - length;
                  for i := 1 to length
                    do
                      st[x + i] :=
                        st[s + i];
                  open[c] := 0;
                  activate(bi, si, pi);
                  p := p + 4
                end
              else if typeno2 > 0 then
                error(lineno,
                  contention4)
              else
                error(lineno, type4)
            end
        end;

    { ProcedureStatement =
        ActualParameterPart
          "proccall" |
        StandardProcedureStatement .
      StandardProcedureStatement =
        ReadStatement |
        WriteStatement |
        OpenStatement |
        ReceiveStatement |
        SendStatement .
      IfStatement =
        Expression "do" Statement
          [ "goto" Statement ] .
      WhileStatement =
        Expression "do"
          Statement "goto" .
      RepeatStatement =
        StatementSequence
         Expression "do" . }

      do2{displ}:
        begin
          if st[s] = ord(true) then
            p := p + 2
          else p := p + st[p + 1];
          s := s - 1
        end;

      goto2{displ}:
        p := p + st[p + 1];

    { ForStatement =
        ForClause ForOption .
      ForClause =
        VariableAccess
          Expression "for" .
      ForOption =
        UpClause | DownClause .
      UpClause =
        Expression "to"
          Statement "endto" .
      DownClause =
        Expression "downto"
          Statement "enddown" . }

      for2:
        begin
          st[st[s - 1]] := st[s];
          s := s - 1;
          p := p + 1
        end;

      to2{displ}:
        begin
          if st[st[s - 1]] <= st[s]
            then p := p + 2
            else
              begin
                s := s - 2;
                p := p + st[p + 1]
              end
        end;

      endto2{disp}:
        begin
          x := st[s - 1];
          st[x] := st[x] + 1;
          p := p + st[p + 1]
        end;

      downto2{displ}:
        begin
          if st[st[s - 1]] >= st[s]
            then p := p + 2
            else
              begin
                s := s - 2;
                p := p + st[p + 1]
              end
        end;

      enddown2{displ}:
        begin
          x := st[s - 1];
          st[x] := st[x] - 1;
          p := p + st[p + 1]
        end;

    { CaseStatement =
        Expression "goto"
          CaseList "case" .
      CaseList =
        StatementSequence . }

      case2{
        lineno, length, table}:
          begin
            x := st[s];
            s := s - 1;
            { binary search }  
            i := 1;
            j := st[p + 2];
            while i < j do
              begin
                k :=
                 (i + j) div 2;
                m := p + 2*k + 1;
                if st[m] < x
                  then i := k + 1
                  else j := k
              end;
            m := p + 2*i + 1;
            if st[m] = x then
              p := p + st[m + 1]
            else
              error(st[p + 1],
                case4)
          end;

    { ParallelStatement =
        "parallel"
          ProcessStatementList
            "endparallel" .
      ProcessStatementList =
        ProcessStatement
          [ ProcessStatement ]* .
      ProcessStatement =
        "process"
          StatementSequence
            "endprocess" . }

      parallel2:
        begin
           s := s + 1;
           st[s] := 0;
           p := p + 1
        end;

      endparallel2{lineno}:
        select(st[p + 1]);

      process2{blockno,
        templength, displ,
          lineno}:
        begin
          st[s] := st[s] + 1;
          blockno := st[p + 1];
          bi := free[blockno];
          if bi = 0 then
            begin
              bi := t + 1;
              t :=
                bi + st[p + 2] + 4
            end
          else
            free[blockno] :=
              st[bi];
          if t > maxaddr then
            memorylimit(st[p + 4])
          else
            begin
              st[bi] := b;
              st[bi + 1] := s;
              si := bi + 4;
              st[si] := blockno;
              activate(bi, si,
                p + 5);
              p := p + st[p + 3]
            end
        end;

      endprocess2{displ, lineno}:
        begin
          blockno := st[s];
          x := b;
          b := st[x];
          s := st[x + 1];
          st[x] := free[blockno];
          free[blockno] := x;
          st[s] := st[s] - 1;
          if st[s] > 0 then
            select(st[p + 2])
          else
            begin
              s := s - 1;
              p := p + st[p + 1]
            end
        end;

    { ForallStatement =
        IndexVariableDeclaration       
          "forall" Statement
            "endall" .
      IndexVariableDeclaration =
        Expression Expression . }

      forall2{blockno,
        templength, displ,
          lineno}:
        begin
          upper := st[s];
          lower := st[s - 1];
          if lower <= upper then
            begin
              s := s - 1;
              st[s] :=
                upper - lower + 1;
              blockno :=
                st[p + 1];
              templength :=
                st[p + 2];
              lineno := st[p + 4];
              for i := lower to
                upper do
              begin
                bi :=
                  free[blockno];
                if bi = 0 then
                  begin
                    bi := t + 1;
                    t := bi +
                      templength + 5
                  end
                else
                  free[blockno] :=
                    st[bi];
                if t > maxaddr then
                  memorylimit(lineno)
                else
                  begin
                    st[bi] := b;
                    st[bi + 1] := s;
                    st[bi + 4] := i;
                    si := bi + 5;
                    st[si] :=
                      blockno;
                    activate(bi, si,
                      p + 5)
                  end
              end;
              select(lineno)
            end
          else { lower > upper }
            begin
              s := s - 2;
              p := p + st[p + 3]
            end
        end;

      endall2{lineno}:
        begin
          blockno := st[s];
          x := b;
          b := st[x];
          s := st[x + 1];
          st[x] := free[blockno];
          free[blockno] := x;
          st[s] := st[s] - 1;
          if st[s] > 0 then
            select(st[p + 2])
          else
            begin
              s := s - 1;
              p := p + 2
            end
        end;

    { AssumeStatement =
        Expression "assume" . }

      assume2{lineno}:
        begin
          x := st[s];
          s := s - 1;
          if x = ord(false) then
            error(st[p + 1],
              assume4)
          else p := p + 2
        end;

    { Statement =
        AssignmentStatement |
        ProcedureStatement |
        IfStatement |
        WhileStatement |
        RepeatStatement |
        ForStatement |
        CaseStatement |
        CompoundStatement |
        ParallelStatement |
        ForallStatement |
        AssumeStatement |
        EmptyStatement .
      EmptyStatement =  .
      StatementSequence =
        Statement [ Statement ]* .
      CompoundStatement =
        StatementSequence .
      Block =
        [ ProcedureDeclaration ]*
          CompoundStatement .
      ProcedureDeclaration =
        "procedure" Block
           "endproc" . }

      procedure2{blockno,
        paramlength, varlength,
          templength, displ,
            lineno}:
        begin
          st[s + 1] :=
            s - st[p + 2] - 1;
          st[s + 3] := b;
          b := s;
          blockno := st[p + 1];
          s := free[blockno];
          if s = 0 then
            begin
              s := t + 1;
              t := s + st[p + 4];
              if t > maxaddr then
                memorylimit(
                  st[p + 6])
            end
          else
            free[blockno] := st[s];
          st[s] := blockno;
          p := p + st[p + 5]
        end;

      endproc2:
        begin
          blockno := st[s];
          x := s;
          s := st[b + 1];
          p := st[b + 2];
          b := st[b + 3];
          st[x] := free[blockno];
          free[blockno] := x
        end;

    { Program =
        "program" Block
          "endprog" . }

      program2{blockno,
        varlength, templength,
          displ, lineno}:
        begin
          for i := 1 to maxblock
            do free[i] := 0;
          ready := 0;
          cmax := 0;
          b := stackbottom;
          s := b + st[p + 2] + 4;
          t := s + st[p + 3];
          if t > maxaddr then
            memorylimit(st[p + 5])
          else p := p + st[p + 4]
        end;

      endprog2:
        running := false;

    { localvar(displ) =
        variable(0, displ) . }

      localvar2{displ}:
        begin
          s := s + 1;
          st[s] := b + st[p + 1];
          p := p + 2
        end;

    { localvalue(displ) =
        localvar(displ)
          value(1) . }

      localvalue2{displ}:
        begin
          s := s + 1;
          st[s] :=
            st[b + st[p + 1]];
          p := p + 2
        end;

    { localreal(displ) =
        localvar(displ)
          value(2) . }

      localreal2{displ}:
        begin
          x := b + st[p + 1];
          s := s + 2;
          st[s - 1] := st[x];
          st[s] := st[x + 1];
          p := p + 2
        end;

    { globalvar(displ) =
        variable(1, displ) . }

      globalvar2{displ}:
        begin
          s := s + 1;
          st[s] :=
            st[b] + st[p + 1];
          p := p + 2
        end;

    { globalvalue(displ) =
        globalvar(displ)
          value(1) . }

      globalvalue2{displ}:
        begin
          s := s + 1;
          st[s] := st[
            st[b] + st[p + 1]];
          p := p + 2
        end;

    { ordvalue =
        value(1) . }

      ordvalue2:
        begin
          st[s] := st[st[s]];
          p := p + 1
        end;

    { realvalue =
        value(2) . }

      realvalue2:
        begin
          x := st[s];
          s := s + 1;
          st[s - 1] := st[x];
          st[s] := st[x + 1];
          p := p + 1
        end;

    { ordassign =
        assign(1) . }

      ordassign2:
        begin
          st[st[s - 1]] := st[s];
          s := s - 2;
          p := p + 1
        end;

    { realassign =
        assign(2) . }

      realassign2:
        begin
          s := s - 3;
          x := st[s + 1];
          st[x] := st[s + 2];
          st[x + 1] := st[s + 3];
          p := p + 1
        end;

    { globalcall(displ) =
        proccall(1, displ) . }

      globalcall2{displ}:
        begin
          s := s + 1;
          st[s] := st[b];
          st[s + 2] := p + 2;
          p := p + st[p + 1]
        end

    end
end { run };

procedure readtime(
 var t:  integer);
begin
  { A nonstandard function reads
    the processor time in ms }
  t := clock
end;

procedure writetime(
  var outfile: text;
  t1, t2: integer);
begin
  { Outputs the time interval
    t2 - t1 ms in seconds }
  writeln(outfile);
  writeln(outfile,
    (t2 - t1 + 500) div 1000:1,
    ' s')
end;

procedure runtime(
  var codefile: binary;
  var inpfile, outfile: text);
var t1, t2: integer;
begin
  readtime(t1);
  run(codefile, inpfile, outfile);
  readtime(t2);
  writetime(outfile, t1, t2)
end;

procedure openoutput(
  var codefile: binary;
  var inpfile: text;
  outname: phrase);
var outfile: text;
begin
  if outname = screen then
    begin
      writeln(output);
      runtime(codefile,
        inpfile, output);
      writeln(output)
    end
  else
    begin
      { nonstandard rewrite }
      rewrite(outfile, outname);
      runtime(codefile,
        inpfile, outfile)
    end
end;

procedure openinput(
  var codefile: binary;
  inpname, outname: phrase);
var inpfile: text;
begin
  if inpname = keyboard then
    openoutput(codefile,
      input, outname)
  else
    begin
      { nonstandard reset }
      reset(inpfile, inpname);
      openoutput(codefile,
        inpfile, outname)
    end
end;

procedure start;
var codename, inpname,
  outname: phrase;
  codefile: binary;
  select: boolean;
begin
  write('    code = ');
  readphrase(codename);
  write('    select files? ');
  readboolean(select);
  if select then
    begin
      write('    input = ');
      readphrase(inpname);
      write('    output = ');
      readphrase(outname);
      { nonstandard reset }
      reset(codefile, codename);
      openinput(codefile,
        inpname, outname)
    end
  else
    begin
      { nonstandard reset }
      reset(codefile, codename);
      writeln(output);
      runtime(codefile, input,
        output);
      writeln(output)
    end
end;

begin start end.
