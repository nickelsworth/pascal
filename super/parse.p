{         SUPERPASCAL COMPILER
                 PARSER
             28 October 1993
  Copyright (c) 1993 Per Brinch Hansen }

procedure parse(
  procedure newline(lineno: integer);
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
  procedure putcase(
    lineno, length: integer;
    table: casetable);
  procedure error(kind: phrase);
  procedure halt(kind: phrase));
const
  nameless = 0;
type
  tokens = set of mintoken..maxtoken;
  messagepointer = ^ messagerecord;
  pointer = ^ objectrecord;
  stringpointer = ^ string;
  varset = ^ atom;
  class =
    (arraytype, channeltype, field,
    funktion, ordconst, ordtype,
    procedur, realconst, realtype,
    recordtype, standardfile,
    standardfunc, standardproc,
    stringconst, valueparameter,
    variable, varparameter,
    undefined);
  classes = set of class;
  atom =
    record
      next: varset;
      item: pointer
    end;
  context =
    record
      exprvar, targetvar: varset
    end;
  messagerecord =
    record
      previous: messagepointer;
      typex: pointer;
    end;
  objectrecord =
    record
      id: integer;
      previous: pointer;
      case kind: class of
        ordconst:
          (ordvalue: integer;
           ordtypex: pointer);
        realconst:
          (realvalue: real);
        stringconst:
          (stringptr: stringpointer);
        ordtype:
          (minvalue, maxvalue:
           integer);
        realtype:
          ( );
        arraytype:
          (lowerbound, upperbound,
           arraylength: integer; 
           indextype, elementtype:
           pointer);
        recordtype:
          (recordlength: integer;
           lastfield: pointer);
        channeltype:
          (messagelist:
             messagepointer);
        field:
          (fielddispl: integer;
           fieldtype: pointer);
        valueparameter, variable,
          varparameter:
          (varlevel, vardispl:
           integer; vartype:
           pointer);
        funktion, procedur:
          (proclevel, proclabel,
           paramlength, varlength:
           integer; lastparam,
           resulttype: pointer;
           recursive: boolean;
           implicit: context);
        standardfile, standardfunc,
          standardproc, undefined:
          ( )
    end;
  blockrecord =
    record
      templength, maxtemp: integer;
      heading, lastobject: pointer
    end;
  blocktable = array [0..maxlevel] of
    blockrecord;
var
  lineno, token, argument: integer;
  realarg: real; stringarg: string;
  addtokens, blocktokens,
  constanttokens, declarationtokens,
  doubletokens, expressiontokens,
  factortokens, literaltokens,
  longtokens, multiplytokens,
  parametertokens, relationtokens,  
  routinetokens, selectortokens,
  signtokens, simpleexprtokens,
  statementtokens, termtokens,
  unsignedtokens: tokens;
  block: blocktable;
  blocklevel: integer;
  constants, functions, leftparts,
  types, variables, parameters,
  procedures: classes;
  inputfile, outputfile,
  typeboolean, typechar,
  typeinteger, typereal,
  typestring, typeuniversal:
  pointer;
  labelno, minint: integer;

{ FORWARD DECLARATIONS }

procedure push(length: integer);
forward;

procedure pop(length: integer);
forward;

procedure expression(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
forward;

procedure statementsequence(
  var used: context;  
  restricted: boolean;
  stop: tokens);
forward;

procedure statement(
  var used: context;
  restricted: boolean;
  stop: tokens);
forward;

procedure declarationpart(
  var varlength: integer;
  stop: tokens);
forward;

procedure statementpart(
  var templength: integer;
  var used: context;
  stop: tokens);
forward;

{ INPUT }

procedure nexttoken;
begin
  get(token);
  while token = newline1 do
    begin
      get(lineno); newline(lineno);
      get(token)
    end;
  if token in longtokens then
    if token in doubletokens then
      get(argument)
    else if token = realconst1 then
      getreal(realarg)
    else { token = stringconst1 }
      getstring(
        argument {(redundant)},
        stringarg)
end;

{ OUTPUT }

procedure emit1(op: integer);
begin put(op) end;

procedure emit2(
  op, arg: integer); 
begin put(op); put(arg) end;

procedure emit3(
  op, arg1, arg2: integer);
begin
  put(op); put(arg1);
  put(arg2)
end;

procedure emit4(
  op, arg1, arg2,
  arg3: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3)
end;

procedure emit5(
  op, arg1, arg2, arg3,
  arg4: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3);
  put(arg4)
end;

procedure emit6(
  op, arg1, arg2, arg3,
  arg4, arg5: integer);
begin
  put(op); put(arg1);
  put(arg2); put(arg3);
  put(arg4); put(arg5)
end;

procedure emitreal(
  value: real);
begin
  put(realconst2);
  putreal(value)
end;

procedure emitstring(
  value: string);
begin
  put(stringconst2);
  putstring(
    stringlength(value),
    value);
end;

procedure emitcase(
  lineno, length: integer;
  table: casetable);
begin
  put(case2);
  putcase(lineno, length,
    table);
end;

{ VARIABLE SETS }

function empty(x: varset)
  : boolean;
{ empty = (x = []) }
begin
  empty := x = nil
end;

function member(x: varset;
  y: pointer): boolean;
{ member = y in x }
var correct: boolean;
begin
  correct := false;
  while not correct
    and (x <> nil) do
      if x^.item = y then
        correct := true
      else x := x^.next;
  member := correct
end;

function disjoint(
  x, y: varset): boolean;
{ disjoint = empty(x*y) }
var correct: boolean;
begin
  correct := true;
  while correct and
    (x <> nil) do
      if member(y, x^.item)
        then correct := false
        else x := x^.next;
  disjoint := correct
end;

procedure newset(
  var x: varset);
{ x := [] }
begin x := nil end;

procedure include(
  var x: varset;
  y: pointer);
{ x := x + [y] }
var v: varset;
begin
  if not member(x, y) then
    begin
      new(v);
      v^.next := x;
      v^.item := y;
      x := v
    end
end;

procedure addset(
  var x: varset;
  y: varset);
{ x := x + y }
begin
  while y <> nil do
    begin
      include(x, y^.item);
      y := y^.next
    end
end;

procedure copyset(
  var x: varset;
  y: varset);
{ x := y }
begin
  newset(x);
  addset(x, y)
end;

{ GLOBAL VARIABLES }

function globalvar(
  proc, object: pointer)
    : boolean;
{ globalvar = the object
  is a variable that is
  global to a procedure
  (or function) }
var kind: class;
begin
  kind := object^.kind;
  if kind in variables then
    globalvar :=
      object^.varlevel <=
        proc^.proclevel
  else if kind = standardfile
    then globalvar := true
  else globalvar := false
end;

procedure globalset(
  proc: pointer;
  var left: varset;
  right: varset);
{ left := all members of
  right which are global
  to a procedure (or
  function) }
var item: pointer;
begin
  newset(left);
  while right <> nil do
    begin
      item := right^.item;
      if globalvar(proc, item)
        then
          include(left, item);
      right := right ^.next
    end
end;

{ STATEMENT CONTEXTS }

function emptycontext(
  used: context): boolean;
{ emptycontext =
    (used = []) }
begin
  emptycontext :=
    empty(used.exprvar) and
    empty(used.targetvar)
end;

procedure newcontext(
  var used: context);
{ used := [] }
begin
  newset(used.targetvar);
  newset(used.exprvar)
end;

procedure addcontext(
  var left: context;
  right: context);
{ left := left + right }
begin
  addset(left.targetvar,
    right.targetvar);
  addset(left.exprvar,
    right.exprvar)
end;

procedure copycontext(
  var left: context;
  right: context);
{ left := right }
begin
  newcontext(left);
  addcontext(left, right)
end;

procedure globalcontext(
  proc: pointer;
  var left: context;
  right: context);
{ left := all members of
  right which are global
  to a procedure or
  function }
begin
  globalset(proc,
    left.targetvar,
    right.targetvar);
  globalset(proc,
    left.exprvar,
    right.exprvar)
end;

{ SCOPE ANALYSIS }

procedure search(
  id, levelno: integer;
  var found: boolean;
  var object: pointer);
var more: boolean;
begin
  more := true;
  object :=
    block[levelno].lastobject;
  while more do
    if object = nil then
      begin
        more := false;
        found := false
      end
    else if object^.id = id then
      begin
        more := false;
        found := true
      end
    else
      object := object^.previous
end;

procedure declare(
  id: integer; kind: class;
  var object: pointer);
var found: boolean;
  other: pointer;
begin
  if id <> nameless then
    begin
      search(id, blocklevel,
        found, other);
      if found then
        error(ambiguous3)
    end;
  new(object);
  object^.id := id;
  object^.previous :=
    block[blocklevel].lastobject;
  object^.kind := kind;
  block[blocklevel].lastobject :=
    object
end;

procedure find(id: integer;
  var object: pointer);
var more, found: boolean;
  levelno: integer;
begin
  more := true;
  levelno := blocklevel;
  while more do
    begin
      search(id, levelno, found,
        object);
      if found or
        (levelno = 0) then
          more := false
      else levelno := levelno - 1
    end;
  if not found then
    begin
      error(undefined3);
      declare(id, undefined, object)
    end
end;

function within(proc: pointer)
  : boolean;
var levelno: integer;
  more: boolean;
begin
  more := true;
  levelno := blocklevel;
  while more do
    if block[blocklevel].heading
        = proc then
      begin
        more := false;
        within := true
      end
    else if levelno = 0 then
      begin
        more := false;
        within := false
      end
    else levelno := levelno - 1
end;

procedure checkblock;
var proc: pointer;
begin
  proc :=
    block[blocklevel].heading;
  if proc <> nil then
    if proc^.kind = funktion then
       error(block3)
end;
    

procedure newblock(
  heading: pointer);
var current: blockrecord;
begin
  if blocklevel = maxlevel then
    halt(maxlevel5);
  blocklevel := blocklevel + 1;
  current.templength := 0;
  current.maxtemp := 0;
  current.heading := heading;
  current.lastobject := nil;
  block[blocklevel] := current
end;

procedure endblock;
begin
  blocklevel := blocklevel - 1
end;

procedure standardblock;
var p: pointer;
begin
  blocklevel := -1;
  newblock(nil);
  { standard files }
  declare(nameless, standardfile,
    inputfile);
  declare(nameless, standardfile,
    outputfile);
  { standard types }
  declare(boolean0, ordtype, p);
  typeboolean := p;
  p^.minvalue := ord(false);
  p^.maxvalue := ord(true);
  declare(char0, ordtype, p);
  typechar := p;
  p^.minvalue := ord(chr(null));
  p^.maxvalue := ord(chr(del));
  declare(integer0, ordtype, p);
  typeinteger := p;
  p^.minvalue := minint;
  p^.maxvalue := maxint;
  declare(real0, realtype, p);
  typereal := p;
  declare(string0, arraytype, p);
  typestring := p;
  p^.lowerbound := 1;
  p^.upperbound := maxstring;
  p^.arraylength := maxstring;
  p^.indextype := typeinteger;
  p^.elementtype := typechar;
  declare(nameless, ordtype, p);
  typeuniversal := p;
  p^.minvalue := 0;
  p^.maxvalue := 0;
  { standard constants }
  declare(false0, ordconst, p);
  p^.ordvalue := ord(false);
  p^.ordtypex := typeboolean;
  declare(maxint0, ordconst, p);
  p^.ordvalue := maxint;
  p^.ordtypex := typeinteger;
  declare(maxstring0, ordconst, p);
  p^.ordvalue := maxstring;
  p^.ordtypex := typeinteger;
  declare(null0, ordconst, p);
  p^.ordvalue := ord(chr(null));
  p^.ordtypex := typechar;
  declare(true0, ordconst, p);
  p^.ordvalue := ord(true);
  p^.ordtypex := typeboolean;
  { standard procedures }
  declare(open0, standardproc, p);
  declare(read0, standardproc, p);
  declare(readln0, standardproc, p);
  declare(receive0, standardproc, p);
  declare(send0, standardproc, p);
  declare(write0, standardproc, p);
  declare(writeln0, standardproc, p);
  { standard functions }
  declare(abs0, standardfunc, p);
  declare(arctan0, standardfunc, p);
  declare(chr0, standardfunc, p);
  declare(cos0, standardfunc, p);
  declare(eof0, standardfunc, p);
  declare(eoln0, standardfunc, p);
  declare(exp0, standardfunc, p);
  declare(ln0, standardfunc, p);
  declare(odd0, standardfunc, p);
  declare(ord0, standardfunc, p);
  declare(pred0, standardfunc, p);
  declare(round0, standardfunc, p);
  declare(sin0, standardfunc, p);
  declare(sqr0, standardfunc, p);
  declare(sqrt0, standardfunc, p);
  declare(succ0, standardfunc, p);
  declare(trunc0, standardfunc, p)
end;

{ TYPE ANALYSIS }

procedure checktypes(
  var type1: pointer;
  type2: pointer);
begin
  if type1 <> type2 then
    begin
      if (type1 <> typeuniversal)
        and
          (type2 <> typeuniversal)
            then error(type3);
      type1 := typeuniversal
    end
end;

procedure typeerror(
  var typex: pointer);
begin
  if typex <> typeuniversal then
    begin
      error(type3);
      typex := typeuniversal
    end
end;

procedure checktype(
  var typex: pointer;
  kind: class);
begin
  if typex^.kind <> kind then
    typeerror(typex)
end;

procedure checkmessage(
  var type1, type2: pointer;
  var typeno: integer);
{ typeno > 0 }
var mess: messagepointer;
  found: boolean;
begin
  typeno := 1;
  if type1^.kind = channeltype then
    begin
      mess := type1^.messagelist;
      found := false;
      while not found and
          (mess <> nil) do
        if mess^.typex <> type2 then
          begin
            typeno := typeno + 1;
            mess := mess^.previous
          end
        else found := true;
      if not found then
        typeerror(type2)
    end
  else typeerror(type1)
end;

procedure kinderror(
  object: pointer);
begin
  if object^.kind <> undefined
    then error(kind3)
end;

procedure convert1(
  var type1: pointer;
  type2: pointer);
begin
  if (type1 = typeinteger) and
    (type2 = typereal) then
      begin
        emit1(float2);
        pop(1); push(2);
        type1 := typereal
      end
end;

procedure convert2(
  var type1, type2: pointer);
begin
  if (type1 = typeinteger) and
    (type2 = typereal) then
      begin
        emit1(floatleft2);
        pop(1); push(2);
        type1 := typereal
      end
   else convert1(type2, type1)
end;

{ VARIABLE ADDRESSING }

function typelength(
  typex: pointer) : integer;
begin
  if typex^.kind = ordtype
    then typelength := 1
  else if typex^.kind = realtype
    then typelength := 2
  else if typex^.kind = arraytype
    then typelength :=
      typex^.arraylength
  else if typex^.kind = recordtype
    then typelength :=
      typex^.recordlength
  else
    { typex^.kind = channeltype }
      typelength := 1
end;

procedure fieldaddressing(
  recordlength: integer;
  lastfield: pointer);
var displ: integer;
begin
  displ := recordlength;
  while displ > 0 do
    begin
      { skip undefined
        object (if any) }
      if lastfield^.kind = field
        then
          begin
            displ := displ -
              typelength(lastfield^.
                fieldtype);
            lastfield^.fielddispl
              := displ
          end;
      lastfield :=
        lastfield^.previous
    end
end;

procedure variableaddressing(
  varlength: integer;
  lastvar: pointer);
var displ: integer;
begin
  displ := varlength;
  while displ > 0 do
    begin
      { skip undefined
        object (if any) }
      if lastvar^.kind = variable
        then
          begin
            displ := displ -
              typelength(
                lastvar^.vartype);
            lastvar^.varlevel :=
              blocklevel;
            lastvar^.vardispl :=
              displ
          end;
      lastvar := lastvar^.previous
    end
end;

procedure parameteraddressing(
  paramlength: integer;
  lastparam: pointer);
var displ: integer;
begin
  displ := 0;
  while displ > - paramlength do
    begin
      { skip undefined
        object (if any) }
      if lastparam^.kind =
          varparameter then
        begin
          displ := displ - 1;
          lastparam^.varlevel :=
            blocklevel;
          lastparam^.vardispl :=
            displ
        end
      else if lastparam^.kind =
          valueparameter then
        begin
          displ := displ -
            typelength(
              lastparam^.vartype);
          lastparam^.varlevel :=
            blocklevel;
          lastparam^.vardispl :=
            displ
        end;
      lastparam :=
        lastparam^.previous
    end
end;

{ LABELS }

procedure newlabel(
  var no: integer);
begin
  if labelno = maxlabel then
    halt(maxlabel5);
  labelno := labelno + 1;
  no := labelno
end;

{ TEMPORARIES }

procedure push{length: integer};
begin
  with block[blocklevel] do
    begin
      templength :=
        templength + length;
      if maxtemp < templength then
        maxtemp := templength
    end
end;

procedure pop{length: integer};
begin
  with block[blocklevel] do
    templength :=
      templength - length
end;

{ CASE TABLES }

procedure insertcase(
  value, index: integer;
  var length: integer;
  var table: casetable;
  var found: boolean);
var x, y: caserecord;
  i: integer;
begin
  { 0 <= length < maxcase
    and table ordered by
    case values }
  x.value := value;
  x.index := index;
  found := false;
  for i := 1 to length do
    begin
      y := table[i];
      if x.value < y.value
        then
          begin
            table[i] := x;
            x := y
          end
      else
        if x.value = y.value
          then found := true
     end;
  length := length + 1;
  table[length] := x
end;

{ INITIALIZATION }

procedure initialize;
begin
  addtokens :=
    [minus1, or1, plus1];
  declarationtokens :=
    [const1, function1,
     procedure1, type1, var1];
  blocktokens := [begin1]
    + declarationtokens;
  doubletokens := [charconst1,
    intconst1, identifier1];
  literaltokens :=
    [charconst1, intconst1,
     realconst1, stringconst1];
  longtokens := [realconst1,
    stringconst1] + doubletokens;
  multiplytokens :=
    [and1, asterisk1, div1,
     mod1, slash1];
  parametertokens :=
    [identifier1, var1];
  relationtokens := [equal1,
    greater1, less1, notequal1,
    notgreater1, notless1];
  routinetokens :=
    [function1, procedure1];
  selectortokens :=
    [leftbracket1, period1];
  signtokens := [minus1, plus1];
  statementtokens :=
    [assume1, begin1, case1,
     for1, forall1, if1,
     identifier1, leftbracket1,
     parallel1, repeat1, while1];
  unsignedtokens := [identifier1]
    + literaltokens;
  constanttokens := signtokens
    + unsignedtokens;
  factortokens := [leftparenthesis1,
    not1] + unsignedtokens;
  termtokens := factortokens;
  simpleexprtokens := signtokens
    + termtokens;
  expressiontokens :=
    simpleexprtokens;
  constants := [ordconst, realconst,
    stringconst];
  functions :=
    [funktion, standardfunc];
  parameters := [valueparameter,
    varparameter];
  procedures :=
    [procedur, standardproc];
  types := [ordtype, realtype,
    arraytype, recordtype,
    channeltype];
  variables :=
    [variable] + parameters;
  leftparts :=
    [funktion] + variables;
  labelno := 0;
  minint := - maxint - 1
end;

{ SYNTAX ANALYSIS }

procedure syntaxerror(
  stop: tokens);
begin
  error(syntax3);
  while not (token in stop) do
    nexttoken
end;

procedure syntaxcheck(
  stop: tokens);
begin
  if not (token in stop) then
    syntaxerror(stop)
end;

procedure expect(t: integer;
  stop: tokens);
begin
  if token = t then
    begin
      nexttoken;
      syntaxcheck(stop)
    end
  else syntaxerror(stop)
end;

procedure expectid(
  var id: integer;
  stop: tokens);
begin
  if token = identifier1 then
    begin
      id := argument;
      nexttoken
    end
  else
    begin
      id := nameless;
      syntaxerror(stop)
    end;
  syntaxcheck(stop)
end;

{ TypeIdentifier =
    Identifier . }

procedure typeidentifier(
  var typex: pointer;
  stop: tokens);
var object: pointer;
begin
  if token = identifier1 then
    begin
      find(argument, object);
      if object^.kind in types
      then typex := object
      else
        begin
          kinderror(object);
          typex := typeuniversal
        end
    end
  else typex := typeuniversal;
  expect(identifier1, stop)
end;

{ UnsignedOrdinal =
    CharacterConstant |
      UnsignedInteger |
        ConstantIdentifier . }

procedure unsignedordinal(
  var value: integer;
  var typex: pointer;
  stop: tokens);
var object: pointer;
begin
  if token = charconst1 then
    begin
      value := argument;
      typex := typechar;
      expect(token, stop)
    end
  else if token = intconst1 then
    begin
      value := argument;
      typex := typeinteger;
      expect(token, stop)
    end
  else if token = identifier1 then
    begin
      find(argument, object);
      if object^.kind = ordconst
      then
        begin
          value := object^.ordvalue;
          typex := object^.ordtypex
        end
      else
        begin
          kinderror(object);
          value := 0;
          typex := typeuniversal
        end;
      expect(identifier1, stop)
    end
  else
    begin
      syntaxerror(stop);
      value := 0;
      typex := typeuniversal
    end
end;

{ UnsignedConstant =
    UnsignedOrdinal |
    UnsignedReal |
    StringConstant |
    ConstantIdentifier . }

procedure unsignedconstant(
  var value: integer;
  var realvalue: real;
  var stringvalue: string;
  var typex: pointer;
  stop: tokens);
var object: pointer;
begin
  { returns the type of an
    unsigned constant and
    its ordinal, real or
    string value }
  if token = realconst1 then
    begin
      realvalue := realarg;
      typex := typereal;
      expect(token, stop)
    end
  else if token = stringconst1
    then
      begin
        stringvalue := stringarg;
        typex := typestring;
        expect(token, stop)
      end
  else if token = identifier1 then
    begin
      find(argument, object);
      if object^.kind = realconst
          then
        begin
          realvalue :=
            object^.realvalue;
          typex := typereal;
          expect(identifier1, stop)
        end
      else
        if object^.kind = stringconst
      then
        begin
          stringvalue :=
            object^.stringptr^;
          typex := typestring;
          expect(identifier1, stop)
        end
      else
         unsignedordinal(value,
           typex, stop)
    end
  else
    unsignedordinal(value, typex,
      stop)
end;

{ Constant =
    [ Sign ] UnsignedConstant .
  Sign =
    "+" | "-" . }

procedure constant(
  var value: integer;
  var realvalue: real;
  var stringvalue: string;
  var typex: pointer;
  stop: tokens);
var sign: integer;
begin
  syntaxcheck(constanttokens
    + stop);
  if token in signtokens then
    begin
      sign := token;
      expect(sign, unsignedtokens
        + stop);
      unsignedconstant(value,
        realvalue, stringvalue,
        typex, stop);
      if typex = typeinteger then
        if sign = minus1 then
          if value <> maxint then
            value := - value
          else error(number3)
        else { sign = plus1 }
      else if typex = typereal then
        if sign = minus1 then
          realvalue := - realvalue
        else { skip }
      else
        begin
          typeerror(typex);
          value := 0
        end
    end
  else
    unsignedconstant(value,
      realvalue, stringvalue,
      typex, stop)
end;

{ OrdinalConstant =
    Constant . }

procedure ordinalconstant(
  var value: integer;
  var typex: pointer;
  stop: tokens);
var realvalue: real;
  stringvalue: string;
begin
  constant(value, realvalue,
    stringvalue, typex, stop);
  if typex^.kind <> ordtype then
    begin
      typeerror(typex);
      value := 0
    end
end;

{ ConstantDefinition =
    ConstantIdentifier
      "=" Constant . }

procedure constantdefinition(
  stop: tokens);
var id, value: integer;
  realvalue: real;
  stringvalue: string;
  constx, typex: pointer;
  stop2: tokens;
begin
  stop2 := constanttokens + stop;
  expectid(id, [equal1] + stop2);
  expect(equal1, stop2);
  constant(value, realvalue,
    stringvalue, typex, stop);
  if typex^.kind = ordtype then
    begin
      declare(id, ordconst, constx);
      constx^.ordvalue := value;
      constx^.ordtypex := typex
    end
  else if typex = typereal then
    begin
      declare(id, realconst, constx);
      constx^.realvalue :=
        realvalue
    end
  else { typex = typestring }
    begin
      declare(id, stringconst,
        constx);
      new(constx^.stringptr);
      constx^.stringptr^ :=
        stringvalue
    end
end;

{ ConstantDefinitions =
    "const" ConstantDefinition ";"
      [ ConstantDefinition ";" ]*
        . }

procedure constantdefinitions(
  stop: tokens);
var stop2, stop3: tokens;
begin
  stop2 := [identifier1] + stop;
  stop3 := [semicolon1] + stop2;
  expect(const1, stop3);
  constantdefinition(stop3);
  expect(semicolon1, stop2);
  while token = identifier1 do
    begin
      constantdefinition(stop3);
      expect(semicolon1, stop2)
    end
end;

{ NewConstantList =
    ConstantIdentifier [ ","
      NewConstantList ] . }

procedure newconstantlist(
  value: integer;
  typex: pointer;
  stop: tokens);
var constx: pointer;
  id: integer;
begin
  expectid(id, [comma1]
    + stop);
  declare(id, ordconst, constx);
  constx^.ordvalue := value;
  constx^.ordtypex := typex;
  if token = comma1 then
    begin
      expect(comma1,
        [identifier1] + stop);
      newconstantlist(
        value + 1, typex, stop)
    end
  else
    begin
      typex^.minvalue := 0;
      typex^.maxvalue := value
    end
end;

{ EnumeratedType =
    "(" NewConstantList ")" . }

procedure enumeratedtypex(
  id: integer; stop: tokens);
var newtype: pointer;
  stop2: tokens;
begin
  stop2 :=
    [rightparenthesis1] + stop;
  declare(id, ordtype, newtype);
  expect(leftparenthesis1,
    [identifier1] + stop2);
  newconstantlist(0, newtype,
    stop2);
  expect(rightparenthesis1,
    stop)
end;

{ IndexRange =
    "[" OrdinalConstant ".."
      OrdinalConstant "]" .  }

procedure indexrange(
  var lowerbound, upperbound:
    integer;
  var indextype: pointer;
  stop: tokens);
var stop2, stop3: tokens;
  uppertype: pointer;
begin
  stop2 := [rightbracket1] + stop;
  stop3 := constanttokens + stop2;
  expect(leftbracket1,
    [doubledot1] + stop3);
  ordinalconstant(
    lowerbound, indextype,
    [doubledot1] + stop3);
  expect(doubledot1, stop3);
  ordinalconstant(upperbound,
    uppertype, stop2);
  checktypes(indextype, uppertype);
  if lowerbound > upperbound then
    begin
      error(range3);
      lowerbound := upperbound
    end;
  expect(rightbracket1, stop)
end;

{ ArrayType =
    "array" IndexRange "of"
      TypeIdentifier . }

procedure arraytypex(id: integer;
  stop: tokens);
var newtype, indextype,
  elementtype: pointer;
  lowerbound, upperbound: integer;
  stop2, stop3: tokens;
begin
  stop2 := [identifier1] + stop;
  stop3 := [of1] + stop2;
  expect(array1, [leftbracket1]
    + stop3);
  indexrange(lowerbound, upperbound,
    indextype, stop3);
  expect(of1, stop2);
  typeidentifier(elementtype, stop);
  declare(id, arraytype, newtype);
  newtype^.lowerbound := lowerbound;
  newtype^.upperbound := upperbound;
  newtype^.arraylength :=
    (upperbound - lowerbound + 1) *
      typelength(elementtype);
  newtype^.indextype := indextype;
  newtype^.elementtype :=
    elementtype
end;

{ RecordSection =
    FieldIdentifier SectionTail .
  SectionTail =
    "," RecordSection |
    ":" TypeIdentifier . }

procedure recordsection(
  var number: integer;
  var lastfield, typex: pointer;
  stop: tokens);
var id: integer; fieldx: pointer;
  stop2: tokens;
begin
  stop2 := [identifier1] + stop;
  expectid(id, [comma1, colon1]
    + stop);
  declare(id, field, fieldx);
  if token = comma1 then
    begin
      expect(comma1, stop2);
      recordsection(number,
        lastfield, typex, stop);
      number := number + 1
    end
  else
    begin
      expect(colon1, stop2);
      typeidentifier(typex, stop);
      lastfield := fieldx;
      number := 1
    end;
  fieldx^.fieldtype := typex
end;

{ FieldList =
    RecordSection
      [ ";" RecordSection ]*
        [ ";" ] . }

procedure fieldlist(
  var lastfield: pointer;
  var length: integer;
  stop: tokens);
var number: integer;
  typex: pointer;
  stop2: tokens;
begin
  stop2 := [semicolon1] + stop;
  recordsection(
    number, lastfield,
    typex, stop2);
  length :=
    number * typelength(typex);
  while token = semicolon1 do
    begin
      { use "stop" here }
      expect(semicolon1,
        [identifier1] + stop);
      if token = identifier1 then
        begin
          recordsection(
            number, lastfield,
            typex, stop2);
          length :=
            length + number *
              typelength(typex)
        end
    end;
  fieldaddressing(length,
    lastfield)
end;

{ RecordType =
    "record" FieldList "end" . }

procedure recordtypex(id: integer;
  stop: tokens);
var newtype, lastfield: pointer;
  length: integer; stop2: tokens;
begin
  stop2 := [end1] + stop;
  newblock(nil);
  expect(record1, [identifier1]
    + stop2);
  fieldlist(lastfield, length,
    stop2);
  expect(end1, stop);
  endblock;
  declare(id, recordtype, newtype);
  newtype^.recordlength := length;
  newtype^.lastfield := lastfield
end;

{ MessageTypeIdentifier =
    TypeIdentifier . }

procedure messagetypeidentifier(
  var last: messagepointer;
    stop: tokens);
var typex: pointer;
begin
  typeidentifier(typex, stop);
  new(last);
  last^.previous := nil;
  last^.typex := typex
end;

{ MessageTypeList =
    MessageTypeIdentifier [ ","
      MessageTypeIdentifier ]* . }

procedure messagetypelist(
  var last: messagepointer;
    stop: tokens);
var next: messagepointer;
  stop2: tokens;
begin
  stop2 := [comma1] + stop;
  messagetypeidentifier(
    last, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        [identifier1] + stop2);
      messagetypeidentifier(
        next, stop2);
      next^.previous := last;
      last := next
    end
end;

{ ChannelType =
    "*" "(" MessageTypeList ")"
      . }

procedure channeltypex(
  id: integer; stop: tokens);
var stop2, stop3: tokens;
  newtype: pointer;
  last: messagepointer;
begin
  stop2 := [rightparenthesis1]
    + stop;
  stop3 :=
    [identifier1] + stop2;
  expect(asterisk1,
    [leftparenthesis1] + stop3);
  expect(leftparenthesis1,
    stop3);
  messagetypelist(last, stop2);
  expect(rightparenthesis1,
    stop);
  declare(id, channeltype,
    newtype);
  newtype^.messagelist := last
end;

{ TypeDefinition =
    TypeIdentifier "=" NewType .
  NewType =
    EnumeratedType | ArrayType |
    RecordType | ChannelType . }

procedure typedefinition(
  stop: tokens);
var stop2: tokens; id: integer;
  object: pointer;
begin
  stop2 := [array1, asterisk1,
    leftparenthesis1, record1]
      + stop;
  expectid(id, [equal1] + stop2);
  expect(equal1, stop2);
  if token = leftparenthesis1
    then enumeratedtypex(id, stop)
  else if token = array1
    then arraytypex(id, stop)
  else if token = record1
    then recordtypex(id, stop)
  else if token = asterisk1
    then channeltypex(id, stop)
  else
    begin
      declare(id, undefined, object);
      syntaxerror(stop)
    end
end;

{ TypeDefinitions =
    "type" TypeDefinition ";"
      [ TypeDefinition ";" ]* . }

procedure typedefinitions(
  stop: tokens);
var stop2, stop3: tokens;
begin
  stop2 := [identifier1] + stop;
  stop3 := [semicolon1] + stop2;
  expect(type1, stop3);
  typedefinition(stop3);
  expect(semicolon1, stop2);
  while token = identifier1 do
    begin
      typedefinition(stop3);
      expect(semicolon1, stop2)
    end
end;

{ VariableDeclaration =
    VariableIdentifier
      VariableTail .
  VariableTail =
    "," VariableDeclaration |
    ":" TypeIdentifier . }

procedure variabledeclaration(
  kind: class; var number: integer;
  var lastvar, typex: pointer;
  stop: tokens);
var id: integer; varx: pointer;
  stop2: tokens;
begin
  stop2 := [identifier1] + stop;
  expectid(id, [comma1, colon1]
    + stop);
  declare(id, kind, varx);
  if token = comma1 then
    begin
      expect(comma1, stop2);
      variabledeclaration(kind,
        number, lastvar, typex,
        stop);
      number := number + 1
    end
  else
    begin
      expect(colon1, stop2);
      typeidentifier(typex, stop);
      lastvar := varx;
      number := 1
    end;
  varx^.vartype := typex
end;

{ VariableDeclarations =
    "var" VariableDeclaration ";"
      [ VariableDeclaration ";" ]*
        . }

procedure variabledeclarations(
  var length: integer; stop: tokens);
var lastvar, typex: pointer;
  number: integer;
  stop2, stop3: tokens;
begin
  stop2 := [identifier1] + stop;
  stop3 := [semicolon1] + stop2;
  expect(var1, stop3);
  variabledeclaration(variable,
    number, lastvar, typex, stop3);
  length :=
    number * typelength(typex);
  expect(semicolon1, stop2);
  while token = identifier1 do
    begin
      variabledeclaration(variable,
        number, lastvar, typex,
        stop3);
      length := length +
        number * typelength(typex);
      expect(semicolon1, stop2)
    end;
  variableaddressing(length,
    lastvar)
end;

{ FormalParameterSection =
    [ "var" ]
      VariableDeclaration . }

procedure formalparametersection(
  proc: pointer;
  var lastparam: pointer;
  var length: integer;
  stop: tokens);
var stop2: tokens; number: integer;
  typex: pointer;
begin
  stop2 := [identifier1] + stop;
  syntaxcheck([var1] + stop2);
  if token = var1 then
    begin
      expect(var1, stop2);
      variabledeclaration(
        varparameter, length,
        lastparam, typex, stop);
      if proc^.kind = funktion
        then error(parameter3)
    end
  else
    begin
      variabledeclaration(
        valueparameter, number,
        lastparam, typex, stop);
      length :=
        number * typelength(typex)
    end
end;

{ FormalParameters =
    FormalParameterSection [ ";"
      FormalParameterSection ]* . }

procedure formalparameters(
  proc: pointer;
  var lastparam: pointer;
  var length: integer;
  stop: tokens);
var more: integer; stop2: tokens;
begin
  stop2 := [semicolon1] + stop;
  formalparametersection(
    proc, lastparam,
    length, stop2); 
  while token = semicolon1 do
    begin
      expect(semicolon1,
        parametertokens + stop2);
      formalparametersection(
        proc, lastparam,
        more, stop2);
      length := length + more
    end;
  parameteraddressing(length,
    lastparam)
end;

{ FormalParameterList =
    "(" FormalParameters ")" . }

procedure formalparameterlist(
  proc: pointer;
  var lastparam: pointer;
  var length: integer;
  stop: tokens);
var stop2: tokens;
begin
  stop2 := [rightparenthesis1]
    + stop;
  expect(leftparenthesis1,
    parametertokens + stop2);
  formalparameters(proc,
    lastparam, length, stop2);
  expect(rightparenthesis1, stop)
end;

{ FormalParameterPart =
    [ FormalParameterList ] . }

procedure formalparameterpart(
  proc: pointer;
  var lastparam: pointer;
  var length: integer;
  stop: tokens);
begin
  syntaxcheck([leftparenthesis1]
    + stop);
  if token = leftparenthesis1
    then
      formalparameterlist(
        proc, lastparam,
        length, stop)
    else { no parameter list }
      begin
        lastparam := nil;
        length := 0
      end
end;

{ FunctionHeading =
    "function" FunctionIdentifier
      FormalParameterPart ":"
        TypeIdentifier . }

procedure functionheading(
  var proc: pointer;
  stop: tokens);
var stop2, stop3: tokens;
  id: integer;
begin
  stop2 := [identifier1] + stop;
  stop3 := [colon1] + stop2;
  expect(function1,
    [leftparenthesis1] + stop3);
  expectid(id, [leftparenthesis1]
    + stop3);
  declare(id, funktion, proc);
  proc^.proclevel := blocklevel;
  newlabel(proc^.proclabel);
  newblock(proc);
  formalparameterpart(
    proc, proc^.lastparam,
    proc^.paramlength, stop3);
  expect(colon1, stop2);
  typeidentifier(
    proc^.resulttype, stop)
end;

{ ProcedureBlock =
    Block .
  Block =
    DeclarationPart
      StatementPart . }

procedure procedureblock(
  proc: pointer; stop: tokens);
var implicit, used: context;
  varlabel, templabel,
  beginlabel, templength:
    integer;
begin
  newlabel(varlabel);
  newlabel(templabel);
  newlabel(beginlabel);
  emit2(defaddr2,
    proc^.proclabel);
  emit6(procedure2,
    proc^.paramlength,
    varlabel, templabel,
    beginlabel, lineno);
  proc^.recursive := false;
  newcontext(proc^.implicit);
  declarationpart(
    proc^.varlength,
    [begin1] + stop);
  emit3(defarg2, varlabel,
    proc^.varlength);
  emit2(defaddr2, beginlabel);
  statementpart(templength,
    used, stop);
  globalcontext(proc,
    implicit, used);
  if (proc^.kind = funktion)
      and not
    empty(implicit.targetvar)
      then error(parameter3)
  else if proc^.recursive
      and not
    emptycontext(implicit)
      then error(recursion3)
  else
    proc^.implicit := implicit;
  emit3(defarg2, templabel,
    templength);
  emit1(endproc2);
  endblock
end;

{ FunctionDeclaration =
    FunctionHeading ";"
      ProcedureBlock . }

procedure functiondeclaration(
  stop: tokens);
var proc: pointer; stop2: tokens;
begin
  stop2 := blocktokens + stop;
  functionheading(proc,
    [semicolon1] + stop2);
  expect(semicolon1, stop2);
  procedureblock(proc, stop)
end;

{ ProcedureHeading =
    "procedure"
      ProcedureIdentifier
        FormalParameterPart . }

procedure procedureheading(
  var proc: pointer;
  stop: tokens);
var id: integer; stop2: tokens;
begin
  stop2 :=
    [leftparenthesis1] + stop;
  expect(procedure1,
    [identifier1] + stop2);
  expectid(id, stop2);
  declare(id, procedur, proc);
  proc^.proclevel := blocklevel;
  newlabel(proc^.proclabel);
  newblock(proc);
  formalparameterpart(
    proc, proc^.lastparam,
    proc^.paramlength, stop);
  proc^.resulttype := nil
end;

{ ProcedureDeclaration =
    ProcedureHeading ";"
      ProcedureBlock. }

procedure proceduredeclaration(
  stop: tokens);
var proc: pointer;
  stop2: tokens;
begin
  stop2 := blocktokens + stop;
  procedureheading(proc,
    [semicolon1] + stop2);
  expect(semicolon1, stop2);
  procedureblock(proc, stop)
end;

{ RoutineDeclarationPart =
    [ FunctionDeclaration ";" |
      ProcedureDeclaration ";"
        ]* . }

procedure routinedeclarationpart(
  stop: tokens);
var stop2, stop3: tokens;
begin
  stop2 := routinetokens + stop;
  stop3 := [semicolon1] + stop2;
  syntaxcheck(stop2);
  while token in routinetokens do
    begin
      if token = function1 then
        functiondeclaration(stop3)
      else { symbol = procedure1 }
        proceduredeclaration(stop3);
      expect(semicolon1, stop2)
    end
end;

{ DeclarationPart =
    [ ConstantDefinitions ]
      [ TypeDefinitions ]
        [ VariableDeclarations ]
          RoutineDeclarationPart . }

procedure declarationpart{
  var varlength: integer;
  stop: tokens};
var stop2: tokens;
begin
  stop2 := routinetokens + stop;
  syntaxcheck(declarationtokens
    + stop);
  if token = const1 then
    constantdefinitions(
      [type1, var1] + stop2);
  if token = type1 then
    typedefinitions([var1] + stop2);
  if token = var1 then
    variabledeclarations(varlength,
      stop2)
  else varlength := 0;
  routinedeclarationpart(stop)
end;

{ IndexExpression =
    Expression . }

procedure indexexpression(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var exprtype: pointer;
begin
  expression(exprtype, used,
    restricted, stop);
  if typex^.kind = arraytype then
    begin
      checktypes(exprtype,
        typex^.indextype);
      emit5(index2,
        typex^.lowerbound,
        typex^.upperbound,
        typelength(
          typex^.elementtype),
        lineno);
      pop(1);
      typex := typex^.elementtype
    end
  else
    begin
      kinderror(typex);
      typex := typeuniversal
    end
end;

{ IndexExpressions =
    IndexExpression
      [ "," IndexExpression ]* . }

procedure indexexpressions(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context; stop2: tokens;
begin
  stop2 := [comma1] + stop;
  indexexpression(typex, used,
    restricted, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        expressiontokens + stop2);
      indexexpression(typex, used2,
        restricted, stop2);
      addcontext(used, used2)
    end
end;

{ IndexedSelector =
    "[" IndexExpressions "]" . }

procedure indexedselector(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2: tokens;
begin
  stop2 := [rightbracket1] + stop;
  expect(leftbracket1,
    expressiontokens + stop2);
  indexexpressions(typex, used,
    restricted, stop2);
  expect(rightbracket1, stop)
end;

{ FieldSelector =
    "." FieldIdentifier . }

procedure fieldselector(
  var typex: pointer;
  stop: tokens);
var found: boolean;
  fieldx: pointer;
begin
  expect(period1, [identifier1]
    + stop);
  if token = identifier1 then
    begin
      if typex^.kind = recordtype
          then
        begin
          found := false;
          fieldx :=
            typex^.lastfield;
          while not found and
              (fieldx <> nil) do
            if fieldx^.id =
              argument
                then
                  found := true
                else
                  fieldx :=
                    fieldx^.
                      previous;
          if found then
            begin
              typex :=
                fieldx^.
                  fieldtype;
              emit2(field2,
                fieldx^.
                  fielddispl)
            end
          else
            begin
              error(undefined3);
              typex :=
                typeuniversal
            end
        end
      else
        begin
          kinderror(typex);
          typex := typeuniversal
        end;
      expect(identifier1, stop)
    end
  else
    begin
      syntaxerror(stop);
      typex := typeuniversal
    end
end;

{ EntireVariableAccess =
    VariableIdentifier . }

procedure entirevariableaccess(
  var typex: pointer;
  var used: context;
  target: boolean;
  stop: tokens);
var level, displ: integer;
  object: pointer; 
begin
  newcontext(used);
  if token = identifier1 then
    begin
      find(argument, object);
      expect(identifier1, stop);
      if object^.kind in variables
        then
          begin
            typex :=
              object^.vartype;
            level := blocklevel -
              object^.varlevel;
            displ :=
              object^.vardispl;
            if object^.kind =
              varparameter
                then
                  emit3(varparam2,
                    level, displ)
                else
                  emit3(variable2,
                    level, displ);
            if target then
              include(
                used.targetvar,
                object)
            else
              include(
                used.exprvar,
                object);
            push(1)
          end
      else
        begin
          kinderror(object);
          typex := typeuniversal
        end
    end
  else
    begin
      syntaxerror(stop);
      typex := typeuniversal
    end
end;

{ VariableAccess =
    EntireVariableAccess
      [ ComponentSelector ]* .
  ComponentSelector =
    IndexedSelector |
    FieldSelector . }

procedure variableaccess(
  var typex: pointer;
  var used: context;
  target, restricted: boolean;
  stop: tokens);
var used2: context;
  stop2: tokens;
begin
  stop2 :=
    selectortokens + stop;
  entirevariableaccess(
    typex, used, target,
    stop2);
  while token in
    selectortokens do
      if token = leftbracket1
        then
          begin
            indexedselector(
              typex, used2,
              restricted,
              stop2);
            addcontext(used,
              used2)
           end
         else
           { token = period1 }
           fieldselector(
             typex, stop2)
end;

{ FileFunctionDesignator =
    "eof" | "eoln" . }

procedure filefunctiondesignator(
  var typex: pointer;
  var used: context;
  stop: tokens);
var id: integer;
begin
  { symbol = (file function)
      identifier }
  newcontext(used);
  include(used.exprvar,
    inputfile);
  expectid(id, stop);
  if id = eof0 then
    emit2(eof2, lineno)
  else { id = eoln0 }
    emit2(eoln2, lineno);
  push(1);
  typex := typeboolean
end;

{ MathFunctionDesignator =
    MathFunctionIdentifier
      "(" Expression ")" .
  MathFunctionIdentifier =
    "abs" | "arctan" | "chr" |
    "cos" | "exp" | "ln" |
    "odd" | "ord" | "pred" |
    "round" | "sin" | "sqr" |
    "sqrt" | "succ" | "trunc". }

procedure mathfunctiondesignator(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2, stop3: tokens;
  exprtype: pointer;
  id: integer;
begin
  { token = (math function)
      identifier }
  stop2 :=
    [rightparenthesis1] + stop;
  stop3 :=
    expressiontokens + stop2;
  expectid(id, [leftparenthesis1]
    + stop3);
  expect(leftparenthesis1,
    stop3);
  expression(exprtype, used,
    restricted, stop2);
  case id of
    arctan0, cos0, exp0, ln0,
      sin0, sqrt0:
        begin
          convert1(exprtype,
            typereal);
          checktypes(exprtype,
            typereal);
          if id = arctan0 then
            emit2(arctan2, lineno)
          else if id = cos0 then
            emit2(cos2, lineno)
          else if id = exp0 then
            emit2(exp2, lineno)
          else if id = ln0 then
            emit2(ln2, lineno)
          else if id = sin0 then
            emit2(sin2, lineno)
          else { id = sqrt0 }
            emit2(sqrt2, lineno);
          typex := typereal
        end;
    abs0, sqr0:
      begin
        if exprtype = typeinteger
          then
            if id = abs0 then
              emit2(absint2,
                lineno)
            else { id = sqr0 }
              emit2(sqrint2,
                lineno)
          else
            begin
              checktypes(exprtype,
                typereal);
              if id = abs0 then
                emit2(abs2, lineno)
              else { id = sqr0 }
                emit2(sqr2, lineno)
            end;
        typex := exprtype
      end;
    odd0:
      begin
        checktypes(exprtype,
          typeinteger);
        typex := typeboolean;
        emit1(odd2)
      end;
    ord0:
      begin
        checktype(exprtype,
          ordtype);
        typex := typeinteger
      end;
    pred0, succ0:
      begin
        checktype(exprtype,
          ordtype);
        if id = pred0 then
          emit3(pred2,
            exprtype^.minvalue,
            lineno)
        else { id = succ0 }
          emit3(succ2,
            exprtype^.maxvalue,
            lineno);
        typex := exprtype
      end;
    chr0:
      begin
        checktypes(exprtype,
          typeinteger);
        emit2(chr2, lineno);
        typex := typechar
      end;
    round0, trunc0:
      begin
        convert1(exprtype,
          typereal);
        checktypes(exprtype,
          typereal);
        if id = round0 then
          emit2(round2, lineno)
        else { id = trunc0 }
          emit2(trunc2, lineno);
        typex := typeinteger
      end
  end;
  expect(rightparenthesis1,
    stop);
  pop(typelength(exprtype));
  push(typelength(typex))
end;

{ StandardFunctionDesignator =
    FileFunctionDesignator |
    MathFunctionDesignator . }

procedure
  standardfunctiondesignator(
    var typex: pointer;
    var used: context;
    restricted: boolean;
    stop: tokens);
{ access restrictions always
  satisfied }
begin
  { token = (standard function)
      identifier }
  if argument in [eof0, eoln0]
    then
      filefunctiondesignator(
        typex, used, stop)
    else
      mathfunctiondesignator(
        typex, used, restricted,
        stop)
end;

{ ActualParameters =
    [ ActualParameters "," ]
      ActualParameter .
  ActualParameter =
    Expression |
    VariableAccess . }

procedure actualparameters(
  lastparam: pointer;
  var length: integer;
  var distinct: varset;
  var used: context;
  restricted: boolean;
  stop: tokens);
var typex: pointer;
  more: integer;
  used2: context;
  stop2: tokens;
begin
  { lastparam <> nil }
  if lastparam^.previous <> nil
    then
      begin
        stop2 :=
          expressiontokens
            + stop;
        actualparameters(
          lastparam^.previous,
          more, distinct,
          used, restricted,
          [comma1] + stop2);
        expect(comma1, stop2)
      end
  else more := 0;
  if lastparam^.kind =
    valueparameter then
      begin
        expression(typex, used2,
          restricted, stop);
        addcontext(used, used2);
        convert1(typex,
          lastparam^.vartype);
        length :=
          typelength(typex)
            + more
      end
    else
    { lastparam^.kind =
        varparameter }
      begin
        variableaccess(
          typex, used2, true,
          restricted, stop);
        if restricted and not
          disjoint(distinct,
            used2.targetvar)
          then error(procedure3);
        addset(distinct,
          used2.targetvar);
        addcontext(used, used2);
        length := 1 + more
      end;
  checktypes(typex,
    lastparam^.vartype)
end;

{ ActualParameterPart =
    [ ActualParameterList ] .
  ActualParameterList =
    "(" ActualParameters ")" . }

procedure actualparameterpart(
  proc: pointer;
  var length: integer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var distinct: varset;
  stop2: tokens;
begin
  copycontext(used,
    proc^.implicit);
  if proc^.lastparam <> nil then
    begin
      stop2 :=
        [rightparenthesis1]
          + stop;
      expect(leftparenthesis1,
        expressiontokens
          + stop2);
      copyset(distinct,
        used.exprvar);
      addset(distinct,
        used.targetvar);
      actualparameters(
        proc^.lastparam,
        length, distinct,
        used, restricted,
        stop2);
      expect(rightparenthesis1,
        stop)
    end
  else { no parameter list }
    begin
      length := 0;
      syntaxcheck(stop)
    end
end;

{ FunctionDesignator =
    FunctionIdentifier
      ActualParameterPart |
    StandardFunctionDesignator
      . }

procedure functiondesignator(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var proc: pointer; paramlength,
  resultlength: integer;
begin
  { token = (function)
      identifier }
  find(argument, proc);
  if proc^.kind = standardfunc
    then
      standardfunctiondesignator(
        typex, used, restricted,
        stop)
    else
      begin
        expect(identifier1,
          [leftparenthesis1]
            + stop);
        typex :=
          proc^.resulttype;
        resultlength :=
          typelength(typex);
        emit2(result2,
          resultlength);
        push(resultlength);
        actualparameterpart(
          proc, paramlength,
          used, restricted,
          stop);
        if within(proc) then
          proc^.recursive :=
            true;
        emit3(proccall2,
          blocklevel -
            proc^.proclevel,
          proc^.proclabel);
        push(proc^.varlength);
        pop(proc^.paramlength
          + proc^.varlength)
      end
end;

{ Factor =
    UnsignedConstant |
    VariableAccess |
    FunctionDesignator |
    "(" Expression ")" |
    "not" Factor . }

procedure factor(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var length, value: integer;
  object: pointer;
  realvalue: real;
  stringvalue: string;
  stop2: tokens;
begin
  if token in literaltokens then
    begin
      newcontext(used);
      unsignedconstant(value,
        realvalue, stringvalue,
        typex, stop);
      if typex^.kind = ordtype
        then
          emit2(ordconst2, value)
      else if typex = typereal
        then
          emitreal(realvalue)
      else { typex = typestring }
        emitstring(stringvalue);
      push(typelength(typex))
    end
  else if token = identifier1 then
    begin
      find(argument, object);
      if object^.kind in constants
          then
        begin
          newcontext(used);
          unsignedconstant(value,
            realvalue, stringvalue,
            typex, stop);
          if typex^.kind = ordtype
            then
              emit2(ordconst2,
                value)
          else if typex = typereal
            then
              emitreal(realvalue)
          else
            { typex = typestring }
            emitstring(stringvalue);
          push(typelength(typex))
        end
      else if object^.kind in
        variables then
          begin
            variableaccess(
              typex, used, false,
              restricted, stop);
            length :=
              typelength(typex);
            emit2(value2, length);
            pop(1); push(length)
          end
      else if object^.kind in
        functions then
          functiondesignator(typex,
            used, restricted, stop)
      else
        begin
          newcontext(used);
          kinderror(object);
          typex := typeuniversal;
          expect(identifier1,
            stop)
        end
    end
  else if token = leftparenthesis1
      then
    begin
      stop2 := [rightparenthesis1]
        + stop;
      expect(leftparenthesis1,
        expressiontokens + stop2);
      expression(typex, used,
        restricted, stop2);
      expect(rightparenthesis1,
        stop)
    end
  else if token = not1 then
    begin
      expect(not1,
        factortokens + stop);
      factor(typex, used,
        restricted, stop);
      checktypes(typex,
        typeboolean);
      emit1(not2)
    end
  else
    begin
      newcontext(used);
      syntaxerror(stop);
      typex := typeuniversal
    end
end;

{ Term =
    Factor [ MultiplyingOperator
      Factor ]* .
  MultiplyingOperator =
    "*" | "/" | "div" | "mod" |
    "and" . }

procedure term(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var operator: integer;
  type2: pointer;
  used2: context;
  stop2: tokens;
begin
  stop2 := multiplytokens + stop;
  factor(typex, used, restricted,
    stop2);
  while token in multiplytokens do
    begin
      operator := token;
      expect(token, factortokens
        + stop2);
      factor(type2, used2,
        restricted, stop2);
      addcontext(used, used2);
      convert2(typex, type2);
      if typex = typeboolean then
        begin
          checktypes(typex, type2);
          if operator = and1 then
            emit1(and2)
          else
            { arithmetic operator }
            typeerror(typex)
        end
      else if typex = typeinteger
          then
        begin
          checktypes(typex, type2);
          if operator = asterisk1
            then 
              emit2(multiply2,
                lineno)
          else
            if operator = div1
              then
                emit2(divide2,
                  lineno)
          else
            if operator = mod1
              then
                emit2(modulo2,
                  lineno)
          else { operator = and1 }
            typeerror(typex)
        end
      else if typex = typereal then
        begin
          checktypes(typex, type2);
          if operator = asterisk1
            then
              emit2(multreal2,
                lineno)
          else
            if operator = slash1
              then
                emit2(divreal2,
                  lineno)
          else { operator in
            [and1, div1, mod1] }
              typeerror(typex)
        end
      else typeerror(typex);
      pop(typelength(typex))
    end
end;

{ SimpleExpression =
    [ Sign ] Term
       [ AddingOperator Term ]* .
  AddingOperator =
    "+" | "-" | "or" . }

procedure simpleexpression(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var operator: integer;
  type2: pointer;
  used2: context;
  stop2: tokens;
begin
  stop2 := addtokens + stop;
  syntaxcheck(signtokens
    + termtokens + stop2);
  if token in signtokens then
    begin
      operator := token;
      expect(token, termtokens
        + stop2);
      term(typex, used,
        restricted, stop2);
      if typex = typeinteger then
        if operator = minus1 then
          emit2(minus2, lineno)
        else { operator = plus1 }
      else if typex = typereal then
        if operator = minus1 then
          emit2(minusreal2, lineno)
        else { operator = plus1 }
      else typeerror(typex)
    end
  else
    term(typex, used, restricted,
      stop2);
  while token in addtokens do
    begin
      operator := token;
      expect(token, termtokens
        + stop2);
      term(type2, used2,
        restricted, stop2);
      addcontext(used, used2);
      convert2(typex, type2);
      if typex = typeboolean then
        begin
          checktypes(typex, type2);
          if operator = or1 then
            emit1(or2)
          else
            { arithmetic operator }
            typeerror(typex)
        end
      else if typex = typeinteger
        then
          begin
            checktypes(typex,
              type2);
            if operator = plus1
              then
                emit2(add2, lineno)
            else
              if operator = minus1
                then
                  emit2(subtract2,
                    lineno)
            else { operator = or1 }
              typeerror(typex)
          end
      else if typex = typereal then
        begin
          checktypes(typex, type2);
          if operator = plus1 then
            emit2(addreal2, lineno)
          else
            if operator = minus1
              then
                emit2(subreal2,
                  lineno)
          else { operator = or1 }
            typeerror(typex)
        end
      else typeerror(typex);
      pop(typelength(typex))
    end
end;

{ Expression =
    SimpleExpression
      [ RelationalOperator
        SimpleExpression ] .
  RelationalOperator =
    "<" | "=" | ">" |
    "<=" | "<>" | ">=" . }

procedure expression{
  typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens};
var length, operator: integer;
  type2: pointer; used2: context;
begin
  simpleexpression(typex,
    used, restricted,
    relationtokens + stop);
  if token in relationtokens then
    begin
      operator := token;
      expect(token, simpleexprtokens
        + stop);
      simpleexpression(type2, used2,
        restricted, stop);
      addcontext(used, used2);
      convert2(typex, type2);
      if typex^.kind = ordtype then
        begin
          checktypes(typex, type2);
          if operator = less1
            then emit1(lsord2)
          else if operator = equal1
            then emit1(eqord2)
          else if operator = greater1
            then emit1(grord2)
          else
            if operator = notgreater1
              then emit1(ngord2)
          else
            if operator = notequal1
              then emit1(neord2)
          else
            { operator = notless1 }
              emit1(nlord2)
        end
      else if typex = typereal then
        begin
          checktypes(typex, type2);
          if operator = less1
            then emit1(lsreal2)
          else if operator = equal1
            then emit1(eqreal2)
          else if operator = greater1
            then emit1(grreal2)
          else
            if operator = notgreater1
              then emit1(ngreal2)
          else
            if operator = notequal1
              then emit1(nereal2)
          else
            { operator = notless1 }
              emit1(nlreal2)
        end
      else if typex = typestring then
        begin
          checktypes(typex, type2);
          if operator = less1
            then emit1(lsstring2)
          else if operator = equal1
            then emit1(eqstring2)
          else if operator = greater1
            then emit1(grstring2)
          else
            if operator = notgreater1
              then emit1(ngstring2)
          else
            if operator = notequal1
              then emit1(nestring2)
          else
            { operator = notless1 }
              emit1(nlstring2)
        end
      else { array, record or
         channel type }
        begin
          checktypes(typex, type2);
          length :=
            typelength(typex);
          if operator = equal1 then
            emit2(equal2, length)
          else
            if operator = notequal1
              then
                emit2(notequal2,
                  length)
          else typeerror(typex)
        end;
      pop(2*typelength(typex));
      push(1);
      typex := typeboolean
    end
end;

{ FunctionVariable =
    FunctionIdentifier . }

procedure functionvariable(
  var typex: pointer;
  var used: context;
  stop: tokens);
var proc: pointer;
begin
  { token = (function)
      identifier }
  find(argument, proc);
  newcontext(used);
  if proc =
      block[blocklevel].heading
    then { in function block }
      begin
        typex := proc^.resulttype;
        emit3(variable2, 0,
          - proc^.paramlength
            - typelength(typex));
        include(used.targetvar,
          proc);
        push(1)
      end
    else
      begin
        kinderror(proc);
        typex := typeuniversal
      end;
  expect(identifier1, stop)
end;

{ AssignmentStatement =
    LeftPart ":=" Expression .
  LeftPart =
    VariableAccess |
    FunctionVariable . }

procedure assignmentstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var leftpart, lefttype,
  exprtype: pointer;
  length: integer;
  used2: context;
  stop2, stop3: tokens;
begin
  { token = (left part)
      identifier }
  stop2 :=
    expressiontokens + stop;
  stop3 := [becomes1] + stop2;
  find(argument, leftpart);
  if leftpart^.kind in variables
    then
      variableaccess(lefttype,
        used, true, restricted,
        stop3)
    else
      functionvariable(
        lefttype, used, stop3);
  expect(becomes1, stop2);
  expression(exprtype, used2,
    restricted, stop);
  addcontext(used, used2);
  convert1(exprtype, lefttype);
  checktypes(lefttype, exprtype);
  length := typelength(exprtype);
  emit2(assign2, length);
  pop(1 + length)
end;

{ ReadParameter =
    VariableAccess . }

procedure readparameter(
  var used: context;
  restricted: boolean;
  stop: tokens);
var typex: pointer;
begin
  variableaccess(typex, used,
    true, restricted, stop);
  include(used.targetvar,
    inputfile);
  if typex = typechar then
    emit2(read2, lineno)
  else if typex = typeinteger then
    emit2(readint2, lineno)
  else if typex = typereal then
    emit2(readreal2, lineno)
  else typeerror(typex);
  pop(1)
end;

{ ReadParameters =
    ReadParameter
      [ "," ReadParameter ]* . }

procedure readparameters(
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context; stop2: tokens;
begin
  stop2 := [comma1] + stop;
  readparameter(used,
    restricted, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        [identifier1] + stop2);
      readparameter(used2,
        restricted, stop2);
      addcontext(used, used2)
    end
end;

{ ReadParameterList =
    "(" ReadParameters ")" . }

procedure readparameterlist(
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2: tokens;
begin
  stop2 :=
    [rightparenthesis1] + stop;
  expect(leftparenthesis1,
    [identifier1] + stop2);
  readparameters(used,
    restricted, stop2);
  expect(rightparenthesis1, stop)
end;

{ ReadStatement =
    "read" ReadParameterList |
    "readln"
       [ ReadParameterList ] . }

procedure readstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var id: integer;
begin
  { token = (read procedure)
      identifier }
  expectid(id, [leftparenthesis1]
    + stop);
  if id = read0 then
    readparameterlist(used,
      restricted, stop)
  else { id = readln0 }
    begin
      if token = leftparenthesis1
        then
          readparameterlist(used,
            restricted, stop)
        else
          begin
            newcontext(used);
            include(used.targetvar,
              inputfile)
          end;
      emit2(readln2, lineno)
    end;
end;

{ WriteOption =
    [ ":" Expression ] . }

procedure writeoption(
  var option: integer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var typex: pointer;
begin
  syntaxcheck([colon1] + stop);
  if token = colon1 then
    begin
      expect(colon1,
        expressiontokens + stop);
      expression(typex, used,
        restricted, stop);
      checktypes(typex,
        typeinteger);
      option := ord(true)
    end
  else
    begin
      newcontext(used);
      option := ord(false)
    end
end;

{ WriteParameter =
    Expression WriteOption
      WriteOption . }

procedure writeparameter(
  var used: context;
  restricted: boolean;
  stop: tokens);
var option1, option2: integer;
  typex: pointer;
  used2: context;
  stop2: tokens;
begin
  stop2 := [colon1] + stop;
  expression(typex, used,
    restricted, stop2);
  if typex = typereal then
    begin
      writeoption(option1, used2,
        restricted, stop2);
      addcontext(used, used2);
      writeoption(option2, used2,
        restricted, stop);
      addcontext(used, used2);
      emit4(writereal2, option1,
        option2, lineno)
    end
  else
    begin
      writeoption(option1, used2,
        restricted, stop);
      addcontext(used, used2);
      if typex = typechar then
        emit3(write2, option1,
          lineno)
      else if typex = typeboolean
        then
          emit3(writebool2,
            option1, lineno)
      else if typex = typeinteger
        then
          emit3(writeint2, option1,
            lineno)
      else if typex = typestring
        then
          emit3(writestring2,
            option1, lineno)
      else typeerror(typex)
    end;
  include(used.targetvar,
    outputfile);
  pop(typelength(typex))
end;

{ WriteParameters =
    WriteParameter
      [ "," WriteParameter ]* . }

procedure writeparameters(
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context; stop2: tokens;
begin
  stop2 := [comma1] + stop;
  writeparameter(used,
    restricted, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        expressiontokens + stop2);
      writeparameter(used2,
        restricted, stop2);
      addcontext(used, used2)
    end
end;

{ WriteParameterList =
    "(" WriteParameters ")" . }

procedure writeparameterlist(
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2: tokens;
begin
  stop2 :=
    [rightparenthesis1] + stop;
  expect(leftparenthesis1,
    expressiontokens + stop2);
  writeparameters(used,
    restricted, stop2);
  expect(rightparenthesis1, stop)
end;

{ WriteStatement =
    "write" WriteParameterList |
    "writeln"
      [ WriteParameterList ] . }

procedure writestatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var id: integer;
begin
  { token = (write procedure)
      identifier }
  expectid(id, [leftparenthesis1]
    + stop);
  if id = write0 then
    writeparameterlist(used,
      restricted, stop)
  else { id = writeln0 }
    begin
      if token = leftparenthesis1
        then
          writeparameterlist(used,
            restricted, stop)
        else
          begin
            newcontext(used);
            include(used.targetvar,
              outputfile)
          end;
      emit2(writeln2, lineno)
    end
end;

{ OpenParameter =
    ChannelVariableAccess . }

procedure openparameter(
  var used: context;
  restricted: boolean;
  stop: tokens);
var typex: pointer;
begin
  variableaccess(typex, used,
    true, restricted, stop);
  checktype(typex, channeltype);
  emit2(open2, lineno);
  pop(1)
end;

{ OpenParameters =
    OpenParameter [ ","
      OpenParameter ]* . }

procedure openparameters(
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context; stop2: tokens;
begin
  stop2 := [comma1] + stop;
  openparameter(used,
    restricted, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        [identifier1] + stop2);
      openparameter(used2,
        restricted, stop2);
      addcontext(used, used2)
    end
end;

{ OpenStatement =
    "open" "("
      OpenParameters ")" . }

procedure openstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2, stop3: tokens;
begin
  { token = (open procedure)
      identifier }
  stop2 := [rightparenthesis1]
    + stop;
  stop3 := [identifier1]
    + stop2;
  expect(identifier1,
    [leftparenthesis1]
      + stop3);
  expect(leftparenthesis1,
    stop3);
  openparameters(used,
    restricted, stop2);
  expect(rightparenthesis1,
    stop)
end;

{ InputVariableAccess =
    VariableAccess . }

procedure inputvariableaccess(
  chantype: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var vartype: pointer;
  typeno: integer;
begin
  variableaccess(
    vartype, used, true,
    restricted, stop);
  checkmessage(chantype,
    vartype, typeno);
  emit4(receive2, typeno,
    typelength(vartype),
      lineno);
  push(1); pop(2)
end;

{ InputVariableList =
    InputVariableAccess
      [ ","
        InputVariableAccess ]*
          . }

procedure inputvariablelist(
  chantype: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context;
  stop2: tokens;
begin
  stop2 := [comma1] + stop;
  inputvariableaccess(
    chantype, used,
    restricted, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        [identifier1]
          + stop2);
      inputvariableaccess(
        chantype, used2,
        restricted, stop2);
      addcontext(used,
        used2)
    end
end;

{ ReceiveParameters =
    ChannelExpression ","
      InputVariableList . }

procedure receiveparameters(
  var used: context;
  restricted: boolean;
  stop: tokens);
var chantype: pointer;
  used2: context;
  stop2: tokens;
begin
  stop2 := [identifier1]
    + stop;
  expression(chantype,
    used, restricted,
    [comma1] + stop2);
  emit2(checkio2, lineno);
  expect(comma1, stop2);
  inputvariablelist(chantype,
    used2, restricted, stop);
  addcontext(used, used2);
  emit1(endio2);
  pop(1)
end;

{ ReceiveStatement =
    "receive" "("
      ReceiveParameters ")" . }

procedure receivestatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2, stop3: tokens;
begin
  { token = (receive procedure)
      identifier }
  stop2 := [rightparenthesis1]
    + stop;
  stop3 := expressiontokens
    + stop2;
  expect(identifier1,
    [leftparenthesis1]
      + stop3);
  expect(leftparenthesis1,
    stop3);
  receiveparameters(used,
    restricted, stop2);
  expect(rightparenthesis1,
    stop)
end;

{ OutputExpression =
    Expression . }

procedure outputexpression(
  chantype: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var typeno, length: integer;
  exprtype: pointer;
begin
  expression(exprtype,
    used, restricted, stop);
  checkmessage(chantype,
    exprtype, typeno);
  length :=
    typelength(exprtype);
  emit4(send2, typeno,
    length, lineno);
  push(1); pop(length + 1)
end;

{ OutputExpressionList =
    OutputExpression [ ","
      OutputExpression ]*
        . }

procedure
  outputexpressionlist(
    chantype: pointer;
    var used: context;
    restricted: boolean;
    stop: tokens);
var used2: context;
  stop2: tokens;
begin
  stop2 := [comma1] + stop;
  outputexpression(
    chantype, used,
    restricted, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        expressiontokens
          + stop2);
      outputexpression(
        chantype, used2,
        restricted, stop2);
      addcontext(used,
        used2)
    end
end;

{ SendParameters =
    ChannelExpression ","
      OutputExpressionList
        . }

procedure sendparameters(
  var used: context;
  restricted: boolean;
  stop: tokens);
var chantype: pointer;
  used2: context;
  stop2: tokens;
begin
  stop2 :=
    expressiontokens
      + stop;
  expression(chantype,
    used, restricted, 
    [comma1] + stop2);
  emit2(checkio2, lineno);
  expect(comma1, stop2);
  outputexpressionlist(
    chantype, used2,
    restricted, stop);
  addcontext(used, used2);
  emit1(endio2);
  pop(1)
end;

{ SendStatement =
    "send" "("
      SendParameters ")"
        . }

procedure sendstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2, stop3: tokens;
begin
  { token =
      (send procedure)
        identifier }
  stop2 :=
    [rightparenthesis1]
      + stop;
  stop3 :=
    expressiontokens
      + stop2;
  expect(identifier1,
    [leftparenthesis1]
      + stop3);
  expect(leftparenthesis1,
    stop3);
  sendparameters(used,
    restricted, stop2);
  expect(rightparenthesis1,
    stop)
end;

{ StandardProcedureStatement =
    ReadStatement |
    WriteStatement |
    OpenStatement |
    ReceiveStatement |
    SendStatement . }

procedure
  standardprocedurestatement(
    var used: context;
    restricted: boolean;
    stop: tokens);
{ restrictions always satisfied }
begin
  { token =
      (standard procedure)
        identifier }
  if argument in
    [read0, readln0] then
      readstatement(used,
        restricted, stop)
  else if argument in
    [write0, writeln0] then
      writestatement(used,
        restricted, stop)
  else if argument = open0 then
    openstatement(used,
      restricted, stop)
  else if argument = receive0 then
    receivestatement(used,
      restricted, stop)
  else { argument = send0 }
    sendstatement(used,
      restricted, stop)
end;

{ ProcedureStatement =
    ProcedureIdentifier
      ActualParameterPart |
    StandardProcedureStatement
      . }

procedure procedurestatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var paramlength: integer;
  proc: pointer;
begin
  { token = (procedure)
      identifier }
  checkblock;
  find(argument, proc);
  if proc^.kind = standardproc
    then
      standardprocedurestatement(
        used, restricted, stop)
    else
      begin
        expect(identifier1,
          [leftparenthesis1]
            + stop);
        actualparameterpart(
          proc, paramlength,
          used, restricted,
          stop);
        if within(proc) then
          proc^.recursive :=
            true;
        emit3(proccall2,
          blocklevel -
            proc^.proclevel,
          proc^.proclabel);
        push(proc^.varlength);
        pop(proc^.paramlength
          + proc^.varlength)
      end
end;

{ IfStatement =
    "if" Expression
      "then" Statement
        [ "else" Statement ] . }

procedure ifstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var label1, label2: integer;
  exprtype: pointer;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 :=
    statementtokens + stop;
  stop3 :=
    [then1, else1] + stop2;
  expect(if1, expressiontokens
    + stop3);
  expression(exprtype, used,
    restricted, stop3);
  checktypes(exprtype,
    typeboolean);
  expect(then1,
    [else1] + stop2);
  newlabel(label1);
  emit2(do2, label1);
  pop(1);
  statement(used2,
    restricted,
    [else1] + stop);
  addcontext(used, used2);
  if token = else1 then
    begin
      expect(else1, stop2);
      newlabel(label2);
      emit2(goto2, label2);
      emit2(defaddr2, label1);
      statement(used2,
        restricted, stop);
      addcontext(used, used2);
      emit2(defaddr2, label2)
    end
  else emit2(defaddr2, label1)
end;

{ WhileStatement =
    "while" Expression
      "do" Statement . }

procedure whilestatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var label1, label2: integer;
  exprtype: pointer;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 :=
    statementtokens + stop;
  stop3 := [do1] + stop2;
  newlabel(label1);
  emit2(defaddr2, label1);
  expect(while1,
    expressiontokens + stop3);
  expression(exprtype, used,
    restricted, stop3);
  checktypes(exprtype,
    typeboolean);
  expect(do1, stop2);
  newlabel(label2);
  emit2(do2, label2);
  pop(1);
  statement(used2,
    restricted, stop);
  addcontext(used, used2);
  emit2(goto2, label1);
  emit2(defaddr2, label2)
end;

{ RepeatStatement =
    "repeat" StatementSequence
      "until" Expression . }

procedure repeatstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var exprtype: pointer;
  labelx: integer;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 := expressiontokens
    + stop;
  stop3 := [until1] + stop2;
  newlabel(labelx);
  emit2(defaddr2, labelx);
  expect(repeat1,
    statementtokens + stop3);
  statementsequence(used,
    restricted, stop3);
  expect(until1, stop2);
  expression(exprtype, used2,
    restricted, stop);
  addcontext(used, used2);
  checktypes(exprtype,
    typeboolean);
  emit2(do2, labelx);
  pop(1)
end;

{ ForClause =
    "for" EntireVariableAccess
      ":=" Expression . }

procedure forclause(
  var vartype: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var exprtype: pointer;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 :=
    expressiontokens + stop;
  stop3 := [becomes1] + stop2;
  expect(for1, stop3);
  entirevariableaccess(
    vartype, used, true,
    stop3);
  checktype(vartype, ordtype);
  expect(becomes1, stop2);
  expression(exprtype, used2,
    restricted, stop);
  addcontext(used, used2);
  checktypes(vartype, exprtype);
  emit1(for2); pop(1)
end;

{ UpClause =
    "to" Expression
      "do" Statement . }

procedure upclause(
  vartype: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var label1, label2: integer;
  exprtype: pointer;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 :=
    statementtokens + stop;
  stop3 := [do1] + stop2;
  newlabel(label1);
  newlabel(label2);
  expect(to1, expressiontokens
    + stop3);
  expression(exprtype, used,
    restricted, stop3);
  checktypes(vartype, exprtype);
  expect(do1, stop2);
  emit2(defaddr2, label1);
  emit2(to2, label2);
  statement(used2,
    restricted, stop);
  addcontext(used, used2);
  emit2(endto2, label1);
  emit2(defaddr2, label2);
  pop(2)
end;

{ DownClause =
    "downto" Expression
      "do" Statement . }

procedure downclause(
  vartype: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var label1, label2: integer;
  exprtype: pointer;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 :=
    statementtokens + stop;
  stop3 := [do1] + stop2;
  newlabel(label1);
  newlabel(label2);
  expect(downto1,
    expressiontokens + stop3);
  expression(exprtype, used,
    restricted, stop3);
  checktypes(vartype, exprtype);
  expect(do1, stop2);
  emit2(defaddr2, label1);
  emit2(downto2, label2);
  statement(used2,
    restricted, stop);
  addcontext(used, used2);
  emit2(enddown2, label1);
  emit2(defaddr2, label2);
  pop(2)
end;

{ ForStatement =
    ForClause ForOption .
  ForOption =
    UpClause | DownClause . }

procedure forstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var vartype: pointer;
  used2: context;
begin
  forclause(vartype,
    used, restricted,
    [downto1, to1] + stop);
  if token = to1 then
    upclause(vartype, used2,
      restricted, stop)
  else
    downclause(vartype, used2,
      restricted, stop);
  addcontext(used, used2)
end;

{ CaseConstant =
    OrdinalConstant . }

procedure caseconstant(
  exprtype: pointer;
  statlabel: integer;
  var length: integer;
  var table: casetable;
  stop: tokens);
var value: integer;
  found: boolean;
  typex: pointer;
begin
  ordinalconstant(value,
    typex, stop);
  checktypes(typex, exprtype);
  if length < maxcase then
    begin
      insertcase(value,
        statlabel, length,
        table, found);
      if found then
          error(case3)
    end
  else halt(maxcase5)
end;

{ CaseConstantList =
    CaseConstant
      [ "," CaseConstant ]* . }

procedure caseconstantlist(
  exprtype: pointer;
  statlabel: integer;
  var length: integer;
  var table: casetable;
  stop: tokens);
var stop2: tokens;
begin
  stop2 := [comma1] + stop;
  caseconstant(
    exprtype, statlabel,
    length, table, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        constanttokens + stop2);
      caseconstant(
        exprtype, statlabel,
        length, table, stop2)
    end
end;

{ CaseListElement =
    CaseConstantList
      ":" Statement . }

procedure caselistelement(
  exprtype: pointer;
  endlabel: integer;
  var length: integer;
  var table: casetable;
  var used: context;
  restricted: boolean;
  stop: tokens);
var statlabel: integer;
  stop2: tokens;
begin
  newlabel(statlabel);
  stop2 :=
    statementtokens + stop;
  caseconstantlist(
    exprtype, statlabel,
    length, table,
    [colon1] + stop2);
  expect(colon1, stop2);
  emit2(defaddr2, statlabel);
  statement(used, restricted,
    stop);
  emit2(goto2, endlabel)
end;

{ CaseList =
    CaseListElement
      [ ";" CaseListElement ]* .
        [ ";" ] . }

procedure caselist(
  exprtype: pointer;
  endlabel: integer;
  var length: integer;
  var table: casetable;
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context;
  stop2: tokens;
begin
  stop2 := [semicolon1] + stop;
  length := 0;
  caselistelement(
    exprtype, endlabel,
    length, table,
    used, restricted,
    stop2);
  while token = semicolon1 do
    begin
      { use "stop" here }
      expect(semicolon1,
        constanttokens + stop);
      if token in constanttokens
        then
          begin
            caselistelement(
              exprtype, endlabel,
              length, table,
              used2, restricted,
              stop2);
            addcontext(used,
              used2)
           end
    end
end;

{ CaseStatement =
    "case" Expression "of"
      CaseList "end" . }

procedure casestatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var exprtype: pointer;
  beginlabel, endlabel,
  firstline, length:
    integer;
  table: casetable;
  used2: context;
  stop2, stop3: tokens;
begin
  stop2 := [end1] + stop;
  stop3 :=
    constanttokens + stop2;
  newlabel(beginlabel);
  newlabel(endlabel);
  firstline := lineno;
  expect(case1, [of1] +
    expressiontokens + stop3);
  expression(exprtype, used,
    restricted, [of1] + stop3);
  checktype(exprtype, ordtype);
  expect(of1, stop3);
  emit2(goto2, beginlabel);
  pop(1);
  caselist(exprtype, endlabel,
    length, table, used2,
    restricted, stop2);
  addcontext(used, used2);
  emit2(defaddr2, beginlabel);
  emitcase(firstline, length,
    table);
  emit2(defaddr2, endlabel);
  expect(end1, stop)
end;

{ StatementSequence =
    Statement
      [ ";" Statement ]* . }

procedure statementsequence{
  var used: context;
  restricted: boolean;
  stop: tokens};
var used2: context;
  stop2: tokens;
begin
  stop2 := [semicolon1] + stop;
  statement(used,
    restricted, stop2);
  while token = semicolon1 do
    begin
      expect(semicolon1,
        statementtokens + stop2);
      statement(used2,
        restricted, stop2);
      addcontext(used, used2)
    end
end;

{ CompoundStatement =
    "begin" StatementSequence
       "end" . }

procedure compoundstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var stop2: tokens;
begin
  stop2 := [end1] + stop;
  expect(begin1,
    statementtokens + stop2);
  statementsequence(used,
    restricted, stop2);
  expect(end1, stop)
end;

{ ProcessStatement =
    StatementSequence . }

procedure processstatement(
    exitlabel: integer;
    var used: context;
    restricted: boolean;
    stop: tokens);
var templabel, endlabel:
  integer;
begin
  newblock(block[blocklevel]
    .heading);
  newlabel(templabel);
  newlabel(endlabel);
  emit4(process2, templabel,
    endlabel, lineno);
  statementsequence(used,
    restricted, stop);
  emit3(defarg2, templabel,
    block[blocklevel].
      maxtemp);
  emit3(endprocess2,
    exitlabel, lineno);
  emit2(defaddr2, endlabel);
  endblock
end;

{ ProcessStatementList =
    ProcessStatement
      [ "|" ProcessStatement ]*
        . }

procedure processstatementlist(
  exitlabel: integer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var used2: context;
  stop2: tokens;
begin
  stop2 := [bar1] + stop;
  processstatement(
    exitlabel, used,
    restricted, stop2);
  while token = bar1 do
    begin
      expect(bar1,
        statementtokens + stop2);
      processstatement(
        exitlabel, used2,
        restricted, stop2);
      if restricted and not
        (disjoint(
           used.targetvar,
           used2.targetvar)
        and
         disjoint(
           used.targetvar,
           used2.exprvar)
        and
         disjoint(
           used.exprvar,
           used2.targetvar))
        then error(parallel3);
      addcontext(used, used2)
    end
end;

{ ParallelStatement =
    "parallel"
      ProcessStatementList
        "end" . }

procedure parallelstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var exitlabel: integer;
  stop2: tokens;
begin
  stop2 := [end1] + stop;
  emit1(parallel2);
  push(1);
  expect(parallel1,
    statementtokens + stop2);
  newlabel(exitlabel);
  processstatementlist(
    exitlabel, used,
    restricted, stop2);
  expect(end1, stop);
  emit2(endparallel2, lineno);
  emit2(defaddr2, exitlabel);
  pop(1)
end;

{ ProcessIndexRange =
    Expression "to"
      Expression . }

procedure processindexrange(
  var typex: pointer;
  var used: context;
  restricted: boolean;
  stop: tokens);
var type2: pointer;
  used2: context;
  stop2: tokens;
begin
  stop2 := expressiontokens
    + stop;
  expression(typex, used,
    restricted,
    [to1] + stop2);
  expect(to1, stop2);
  expression(type2, used2,
    restricted, stop);
  addcontext(used, used2);
  checktype(typex, ordtype);
  checktypes(typex, type2)
end;

{ IndexVariableDeclaration =
    VariableIdentifier ":="
      ProcessIndexRange . }

procedure
  indexvariabledeclaration(
    var used: context;
    restricted: boolean;
    stop: tokens);
var id: integer; typex,
  varx: pointer;
  stop2: tokens;
begin
  stop2 := expressiontokens
    + stop;
  expectid(id, [becomes1]
    + stop2);
  expect(becomes1, stop2);
  processindexrange(typex,
    used, restricted, stop);
  newblock(block[blocklevel]
    .heading);
  declare(id, variable, varx);
  varx^.vartype := typex;
  variableaddressing(1, varx);
  include(used.exprvar, varx)
end;

{ ForallStatement =
    "forall"
      IndexVariableDeclaration
        "do" Statement . }

procedure forallstatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var endlabel, templabel:
  integer; used2: context;
  stop2, stop3: tokens;
begin
  stop2 := statementtokens
    + stop;
  stop3 := [do1] + stop2;
  expect(forall1,
    [identifier1] + stop3);
  indexvariabledeclaration(
    used, restricted, stop3);
  expect(do1, stop2);
  newlabel(templabel);
  newlabel(endlabel);
  emit4(forall2, templabel,
    endlabel, lineno);
  statement(used2, restricted,
    stop);
  if restricted and not
    empty(used2.targetvar)
      then error(forall3);
  addcontext(used, used2);
  emit3(defarg2, templabel,
    block[blocklevel].
      maxtemp);
  emit2(endall2, lineno);
  emit2(defaddr2, endlabel);
  endblock;
  pop(2)
end;

{ UnrestrictedStatement =
    SicClause Statement .
  SicClause =
    "[" "sic" "]" . }

procedure
  unrestrictedstatement(
    var used: context;
    stop: tokens);
const restricted = false;
var stop2, stop3: tokens;
begin
  stop2 := statementtokens
    + stop;
  stop3 := [rightbracket1]
    + stop2;
  expect(leftbracket1,
    [sic1] + stop3);
  expect(sic1, stop3);
  expect(rightbracket1, stop2);
  statement(used, restricted,
    stop)
end;

{ AssumeStatement =
    "assume" Expression . }

procedure assumestatement(
  var used: context;
  restricted: boolean;
  stop: tokens);
var typex: pointer;
begin
  expect(assume1,
    expressiontokens + stop);
  expression(typex, used,
    restricted, stop);
  checktypes(typex,
    typeboolean);
  emit2(assume2, lineno);
  pop(1)
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
    UnrestrictedStatement |
    AssumeStatement |
    EmptyStatement .
  EmptyStatement = . }

procedure statement{
  var used: context;
  restricted: boolean;
  stop: tokens};
var object: pointer;
begin
  if token = identifier1 then
    begin
      find(argument, object);
      if object^.kind in leftparts
        then
          assignmentstatement(
            used, restricted,
            stop)
      else if object^.kind in
        procedures then
          procedurestatement(
            used, restricted,
            stop)
        else
          begin
            newcontext(used);
            kinderror(object);
            expect(identifier1,
              stop)
          end
    end
  else if token = if1 then
    ifstatement(used,
      restricted, stop)
  else if token = while1 then
    whilestatement(used,
      restricted, stop)
  else if token = repeat1 then
    repeatstatement(used,
      restricted, stop)
  else if token = for1 then
    forstatement(used,
      restricted, stop)
  else if token = case1 then
    casestatement(used,
      restricted, stop)
  else if token = begin1 then
    compoundstatement(used,
      restricted, stop)
  else if token = parallel1 then
    parallelstatement(used,
      restricted, stop)
  else if token = forall1 then
    forallstatement(used,
      restricted, stop)
  else if token = leftbracket1
  then
    unrestrictedstatement(used,
      stop)
  else if token = assume1 then
    assumestatement(used,
      restricted, stop)
  else { empty statement }
    begin
      newcontext(used);
      syntaxcheck(stop)
    end
end;

{ StatementPart =
    CompoundStatement . }

procedure statementpart{
  var templength: integer;
  var used: context;
  stop: tokens};
begin
  { restricted is a
    global constant }
  compoundstatement(used,
    restricted, stop);
  templength :=
    block[blocklevel].maxtemp
end;

{ ProgramParameters =
    ParameterIdentifier [ ","
      ParameterIdentifier ]* . }

procedure programparameters(
  stop: tokens);
var stop2: tokens;
begin
  stop2 := [comma1] + stop;
  expect(identifier1, stop2);
  while token = comma1 do
    begin
      expect(comma1,
        [identifier1] + stop2);
      expect(identifier1, stop2)
  end
end;

{ ProgramParameterPart =
   [ "(" ProgramParameters ")" ]
     . }

procedure programparameterpart(
  stop: tokens);
var stop2: tokens;
begin
  syntaxcheck([leftparenthesis1]
    + stop);
  if token = leftparenthesis1 then
    begin
      stop2 := [rightparenthesis1]
        + stop;
      expect(leftparenthesis1,
        [identifier1] + stop2);
      programparameters(stop2);
      expect(rightparenthesis1,
        stop)
    end
end;

{ ProgramHeading =
   "program" ProgramIdentifier
     ProgramParameterPart . }

procedure programheading(
  stop: tokens);
var stop2: tokens;
begin
  stop2 :=
    [leftparenthesis1] + stop;
  expect(program1,
    [identifier1] + stop2);
  expect(identifier1, stop2);
  programparameterpart(stop)
end;

{ Program =
    ProgramHeading ";"
      Block "." . }

procedure programx(stop: tokens);
var used: context;
  varlabel, templabel,
  beginlabel, varlength,
  templength: integer;
  stop2, stop3, stop4: tokens;
begin
  stop2 := [period1] + stop;
  stop3 := [begin1] + stop2;
  stop4 := declarationtokens
    + stop3;
  programheading([semicolon1]
    + stop4);
  newlabel(varlabel);
  newlabel(templabel);
  newlabel(beginlabel);
  emit5(program2,
    varlabel, templabel,
    beginlabel, lineno);
  expect(semicolon1, stop4);
  newblock(nil);
  declarationpart(varlength,
    stop3);
  emit3(defarg2, varlabel,
    varlength);
  emit2(defaddr2, beginlabel);
  statementpart(templength,
    used, stop2);
  emit3(defarg2, templabel,
    templength);
  emit1(endprog2);
  endblock;
  expect(period1, stop)
end;

begin
  initialize;
  standardblock;
  nexttoken;
  programx([endtext1])
end;
