{         SUPERPASCAL COMPILER
                ASSEMBLER
             20 August 1993
  Copyright (c) 1993 Per Brinch Hansen }

procedure assemble(
  optimizing: boolean;
  procedure get(var value: integer);
  procedure put(value: integer);
  procedure getreal(var value: real);
  procedure putreal(value: real);
  procedure getstring(
    var length: integer;
    var value: string);
  procedure putstring(
    length: integer;
    value: string);
  procedure getcase(
    var lineno, length: integer;
    var table: casetable);
  procedure putcase(
    lineno, length: integer;
    table: casetable);
  procedure rerun;
  procedure halt(kind: phrase));
type
  operations = set of minoperation
    ..maxoperation;
  assemblytable =
    array [1..maxlabel] of integer;
var
  noarguments, oneargument,
  twoarguments, threearguments,
  fourarguments, fivearguments,
  jumps: operations;
  blockno, address, op, arg1, arg2,
  arg3, arg4, arg5: integer;
  realarg: real;
  stringarg: string;
  casearg: casetable;
  table: assemblytable;

procedure nextinstruction;
begin
  get(op);
  if op in noarguments then
    { skip }
  else if op in oneargument then
    get(arg1)
  else if op in twoarguments then
    begin
      get(arg1); get(arg2)
    end
  else if op in threearguments then
    begin
      get(arg1); get(arg2);
      get(arg3)
    end
  else if op in fourarguments then
    begin
      get(arg1); get(arg2);
      get(arg3); get(arg4)
    end
  else if op in fivearguments then
    begin
      get(arg1); get(arg2);
      get(arg3); get(arg4);
      get(arg5)
    end
  else if op = realconst2 then
    getreal(realarg)
  else if op = stringconst2 then
    getstring(arg1, stringarg)
  else { op = caseconst2 }
    getcase(arg1, arg2,
      casearg)
end;

procedure emit1(op: integer);
begin
  put(op);
  address := address + 1
end;

procedure emit2(
  op, arg: integer);
begin
  put(op); put(arg);
  address := address + 2
end;

procedure emit3(
  op, arg1, arg2: integer);
begin
  put(op); put(arg1);
  put(arg2);
  address := address + 3
end;

procedure emit4(
  op, arg1, arg2,
  arg3: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3);
  address := address + 4
end;

procedure emit5(
  op, arg1, arg2, arg3,
  arg4: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3);  
  put(arg4);
  address := address + 5
end;

procedure emit6(
  op, arg1, arg2, arg3,
  arg4, arg5: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3);
  put(arg4); put(arg5);
  address := address + 6
end;

procedure emit7(
  op, arg1, arg2, arg3, arg4,
  arg5, arg6: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3);
  put(arg4); put(arg5);
  put(arg6);
  address := address + 7
end;

procedure emitreal(
  value: real);
begin
  put(realconst2);
  putreal(value);
  address := address + 3
end;

procedure emitstring(
  length: integer;
  value: string);
begin
  put(stringconst2);
  putstring(length, value);
  address :=
    address + length + 2
end;

procedure emitcase(
  lineno, length: integer;
  table: casetable);
begin
  put(case2);
  putcase(lineno, length,
    table);
  address :=
    address + 2*length + 3
end;

procedure newblock;
begin
  if blockno = maxblock then
    halt(maxblock5);
  blockno := blockno + 1
end;

function optimize(condition:
  boolean): boolean;
begin
  optimize :=
    optimizing and condition
end;

function templength(labelno:
  integer): integer;
begin
  { include block link
    (or process state)
    of length 4 (or 3) }
  templength :=
    table[labelno] + 4
end;

function jumpdispl(labelno:
  integer): integer;
begin
  jumpdispl :=
    table[labelno] - address
end;

procedure assign(
  length: integer);
begin
  if optimize(length = 1)
    then emit1(ordassign2)
  else if optimize(length = 2)
    then emit1(realassign2)
  else emit2(assign2, length);
  nextinstruction
end;

procedure casex(
  lineno, length: integer;
  table: casetable);
var i: integer;
begin
  for i := 1 to length do
    table[i].index :=
      jumpdispl(
        table[i].index);
  emitcase(lineno, length,
    table);
  nextinstruction
end;

procedure defaddr(labelno:
  integer);
begin
  table[labelno] := address;
  nextinstruction
end;

procedure defarg(labelno,
  value: integer);
begin
  table[labelno] := value;
  nextinstruction
end;

procedure endprocess(exitlabel,
  lineno: integer);
begin
  emit3(endprocess2,
    jumpdispl(exitlabel),
    lineno);
  nextinstruction
end;

procedure field(displ: integer);
begin
  if optimize(displ = 0)
    then { empty }
    else emit2(field2, displ);
  nextinstruction
end;

procedure forall(templabel,
  endlabel, lineno: integer);
begin
  newblock;
  emit5(forall2, blockno,
    templength(templabel),
    jumpdispl(endlabel),
    lineno);
  nextinstruction
end;

procedure jump(op, labelno:
  integer);
begin
  { op in [do2, downto2,
      enddown2, endto2,
        goto2, to2] }
  emit2(op,
    jumpdispl(labelno));
  nextinstruction
end;

procedure proccall(level,
  labelno: integer);
var displ: integer;
begin
  displ := jumpdispl(labelno);
  if optimize(level = 1) then
    emit2(globalcall2, displ)
  else
    emit3(proccall2, level,
      displ);
  nextinstruction
end;

procedure procedur(paramlength,
  varlabel, templabel,
  beginlabel, lineno: integer);
begin
  newblock;
  emit7(procedure2, blockno,
    paramlength,
    table[varlabel],
    templength(templabel),
    jumpdispl(beginlabel),
    lineno);
  nextinstruction
end;

procedure process(templabel,
  endlabel, lineno: integer);
begin
  newblock;
  emit5(process2, blockno,
    templength(templabel),
    jumpdispl(endlabel),
    lineno);
  nextinstruction
end;

procedure programx(varlabel,
  templabel, beginlabel,
  lineno: integer);
begin
  newblock;
  emit6(program2, blockno,
    table[varlabel],
    templength(templabel),
    jumpdispl(beginlabel),
    lineno);
  nextinstruction
end;

procedure value(length: integer);
begin
  if optimize(length = 1)
    then emit1(ordvalue2)
  else if optimize(length = 2)
    then emit1(realvalue2)
  else emit2(value2, length);
  nextinstruction
end;

procedure variable(level, displ:
  integer);
begin
  if displ >= 0 then
    { include block link
      of length 4 }
    displ := displ + 4;
  nextinstruction;
  while optimize(op = field2) do
    begin
      displ := displ + arg1;
      nextinstruction
    end;
  if optimize(level = 0) then
    if (op = value2) and
      (arg1 = 1) then
        begin
          emit2(localvalue2,
            displ);
          nextinstruction
        end
    else if (op = value2) and
      (arg1 = 2) then
        begin
          emit2(localreal2,
            displ);
          nextinstruction
        end
    else emit2(localvar2, displ)
  else if optimize(level = 1) then
    if (op = value2) and
      (arg1 = 1) then
        begin
          emit2(globalvalue2,
            displ);
          nextinstruction
        end
    else emit2(globalvar2, displ)
  else
    emit3(variable2, level, displ)
end;

procedure copyinstruction;
begin
  if op in noarguments
    then emit1(op)
  else if op in oneargument
    then emit2(op, arg1)
  else if op in twoarguments
    then emit3(op, arg1, arg2)
  else if op in threearguments
    then
      emit4(op, arg1, arg2,
        arg3)
  else if op in fourarguments
    then
      emit5(op, arg1, arg2,
        arg3, arg4)
  else if op in fivearguments
    then
      emit6(op, arg1, arg2,
        arg3, arg4, arg5)
  else if op = realconst2
    then emitreal(realarg)
  else { op = stringconst2 }
    emitstring(arg1,
      stringarg);
  nextinstruction
end;

procedure assemble;
begin
  blockno := 0;
  address := 0;
  nextinstruction;
  while op <> endprog2 do
    if op = assign2 then
      assign(arg1)
    else if op = case2 then
      casex(arg1, arg2, casearg)
    else if op = defaddr2 then
      defaddr(arg1) 
    else if op = defarg2 then
      defarg(arg1, arg2)
    else if op = endprocess2 then
      endprocess(arg1, arg2)
    else if op = field2 then
      field(arg1)
    else if op = forall2 then
      forall(arg1, arg2, arg3)
    else if op in jumps then
      jump(op, arg1)
    else if op = proccall2 then
      proccall(arg1, arg2)
    else if op = procedure2 then
      procedur(arg1, arg2, arg3,
        arg4, arg5)
    else if op = process2 then
      process(arg1, arg2, arg3)
    else if op = program2 then
      programx(arg1, arg2, arg3,
        arg4)
    else if op = value2 then
      value(arg1)
    else if op = variable2 then
      variable(arg1, arg2)
    else copyinstruction;
  emit1(endprog2)
end;

procedure initialize;
var labelno: integer;
begin
  noarguments :=
    [and2, endio2, endproc2,
    endprog2, eqord2, eqreal2,
    eqstring2, float2,
    floatleft2, for2, grord2,
    grreal2, grstring2, lsord2,
    lsreal2, lsstring2, neord2,
    nereal2, nestring2, ngord2,
    ngreal2, ngstring2, nlord2,
    nlreal2, nlstring2, not2,
    odd2, or2, parallel2];
  oneargument :=
    [abs2, absint2, add2,
    addreal2, arctan2, assign2,
    assume2, checkio2, chr2,
    cos2, divide2, divreal2,
    do2, downto2, endall2,
    enddown2, endparallel2,
    endto2, eof2, eoln2,
    equal2, exp2, field2,
    goto2, ln2, minus2,
    minusreal2, modulo2, multiply2,
    multreal2, notequal2, open2,
    ordconst2, read2, readint2,
    readln2, readreal2, result2,
    round2, sin2, sqr2,
    sqrint2, sqrt2, subreal2,
    subtract2, to2, trunc2,
    value2, writeln2, defaddr2];
  twoarguments :=
    [endprocess2, pred2,
    proccall2, succ2, variable2,
    varparam2, write2,
    writebool2, writeint2,
    writestring2, defarg2];
  threearguments :=
    [forall2, process2,
    receive2, send2,
    writereal2];
  fourarguments :=
    [index2, program2];
  fivearguments :=
    [procedure2];
  jumps :=
    [do2, downto2, enddown2,
    endto2, goto2, to2]; 
  for labelno := 1 to maxlabel
    do table[labelno] := 0
end;

begin
  initialize; assemble;
  rerun; assemble
end;
