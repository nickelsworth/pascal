{ SUPERPASCAL COMPILER AND INTERPRETER
             COMMON BLOCK
            3 Novemver 1993
  Copyright (c) 1993 Per Brinch Hansen }

const
  { compilation options }

  testoptions = false;
  restricted = true;

  { software limits }

  maxaddr = 100000; maxblock = 200;
  maxbuf = 10000; maxcase = 128;
  maxchan = 10000; maxchar = 10000;
  maxlabel = 1000; maxlevel = 10;
  maxphrase = 30; maxstring = 80;
  minreal = 1.0e-307;
  maxreal = 1.0e+307;

  { standard identifiers }

  minstandard = 1;
  maxstandard = 34;
  abs0 = 1; arctan0 = 2;
  boolean0 = 3; char0 = 4;
  chr0 = 5; cos0 = 6;
  eof0 = 7; eoln0 = 8;
  exp0 = 9; false0 = 10;
  integer0 = 11; ln0 = 12;
  maxint0 = 13; maxstring0 = 14;
  null0 = 15; odd0 = 16;
  open0 = 17; ord0 = 18;
  pred0 = 19; read0 = 20;
  readln0 = 21; real0 = 22;
  receive0 = 23; round0 = 24;
  send0 = 25; sin0 = 26;
  sqr0 = 27; sqrt0 = 28;
  string0 = 29; succ0 = 30;
  true0 = 31; trunc0 = 32;
  write0 = 33; writeln0 = 34;

  { tokens }

  mintoken = 0; maxtoken = 59;
  and1 = 0; array1 = 1;
  assume1 = 2; asterisk1 = 3;
  bar1 = 4; becomes1 = 5;
  begin1 = 6; case1 = 7;
  charconst1 = 8; colon1 = 9;
  comma1 = 10; const1 = 11;
  div1 = 12; do1 = 13;
  downto1 = 14; doubledot1 = 15;
  else1 = 16; end1 = 17;
  endtext1 = 18; equal1 = 19;
  for1 = 20; forall1 = 21;
  function1 = 22; greater1 = 23;
  identifier1 = 24; if1 = 25;
  intconst1 = 26;
  leftbracket1 = 27;
  leftparenthesis1 = 28;
  less1 = 29; minus1 = 30;
  mod1 = 31; newline1 = 32;
  not1 = 33; notequal1 = 34;
  notgreater1 = 35; notless1 = 36;
  of1 = 37; or1 = 38;
  parallel1 = 39; period1 = 40;
  plus1 = 41; procedure1 = 42;
  program1 = 43; realconst1 = 44;
  record1 = 45; repeat1 = 46;
  rightbracket1 = 47;
  rightparenthesis1 = 48;
  semicolon1 = 49; sic1 = 50;
  slash1 = 51; stringconst1 = 52;
  then1 = 53; to1 = 54;
  type1 = 55; until1 = 56;
  var1 = 57; while1 = 58;
  unknown1 = 59;

  { operation parts }

  minoperation = 0;
  maxoperation = 110;
  abs2 = 0; absint2 = 1;
  add2 = 2; addreal2 = 3;
  and2 = 4; arctan2 = 5;
  assign2 = 6; assume2 = 7;
  case2 = 8; checkio2 = 9;
  chr2 = 10; cos2 = 11;
  divide2 = 12; divreal2 = 13;
  do2 = 14; downto2 = 15;
  endall2 = 16; enddown2 = 17;
  endio2 = 18; endparallel2 = 19;
  endproc2 = 20; endprocess2 = 21;
  endprog2 = 22; endto2 = 23;
  eof2 = 24; eoln2 = 25;
  eqord2 = 26; eqreal2 = 27;
  eqstring2 = 28; equal2 = 29;
  exp2 = 30; field2 = 31;
  float2 = 32; floatleft2 = 33;
  for2 = 34; forall2 = 35;
  goto2 = 36; grord2 = 37;
  grreal2 = 38; grstring2 = 39;
  index2 = 40; ln2 = 41;
  lsord2 = 42; lsreal2 = 43;
  lsstring2 = 44; minus2 = 45;
  minusreal2 = 46; modulo2 = 47;
  multiply2 = 48; multreal2 = 49;
  neord2 = 50; nereal2 = 51;
  nestring2 = 52; ngord2 = 53;
  ngreal2 = 54; ngstring2 = 55;
  nlord2 = 56; nlreal2 = 57;
  nlstring2 = 58; not2 = 59;
  notequal2 = 60; odd2 = 61;
  open2 = 62; or2 = 63;
  ordconst2 = 64; parallel2 = 65;
  pred2 = 66; proccall2 = 67;
  procedure2 = 68; process2 = 69;
  program2 = 70; read2 = 71;
  readint2 = 72; readln2 = 73;
  readreal2 = 74; realconst2 = 75;
  receive2 = 76; result2 = 77;
  round2 = 78; send2 = 79;
  sin2 = 80; sqr2 = 81;
  sqrint2 = 82; sqrt2 = 83;
  stringconst2 = 84;
  subreal2 = 85; subtract2 = 86;
  succ2 = 87; to2 = 88;
  trunc2 = 89; value2 = 90;
  variable2 = 91; varparam2 = 92;
  write2 = 93; writebool2 = 94;
  writeint2 = 95; writeln2 = 96;
  writereal2 = 97;
  writestring2 = 98;
  globalcall2 = 99;
  globalvalue2 = 100;
  globalvar2 = 101;
  localreal2 = 102;
  localvalue2 = 103;
  localvar2 = 104;
  ordassign2 = 105;
  ordvalue2 = 106;
  realassign2 = 107;
  realvalue2 = 108;
  defaddr2 = 109; defarg2 = 110;

  { compile-time errors }

  ambiguous3 =
    'ambiguous identifier          ';
  block3 =
    'function block error          ';
  case3 =
    'ambiguous case constant       ';
  comment3 =
    'incomplete comment            ';
  forall3 =
    'forall statement error        ';
  kind3 =
    'identifier kind error         ';
  number3 =
    'number error                  ';
  parallel3 =
    'parallel statement error      ';
  parameter3 =
    'function parameter error      ';
  procedure3 =
    'procedure statement error     ';
  range3 =
    'index range error             ';
  recursion3 =
    'recursion error               ';
  syntax3 =
    'syntax error                  ';
  type3 =
    'type error                    ';
  undefined3 =
    'undefined identifier          ';

  { run-time errors }

  assume4 =
    'false assumption              ';
  case4 =
    'undefined case constant       ';
  channel4 =
    'undefined channel reference   ';
  contention4 =
    'channel contention            ';
  deadlock4 =
    'deadlock                      ';
  range4 =
    'range error                   ';
  type4 =
    'message type error            ';

  { software failure }

  maxaddr5 =
    'memory limit exceeded         ';
  maxblock5 =
    'block limit exceeded          ';
  maxbuf5 =
    'buffer limit exceeded         ';
  maxcase5 =
    'case limit exceeded           ';
  maxchan5 =
    'channel limit exceeded        ';
  maxchar5 =
    'character limit exceeded      ';
  maxlabel5 =
    'branch limit exceeded         ';
  maxlevel5 =
    'nesting limit exceeded        ';
  maxstring5 =
    'string limit exceeded         ';

  { miscellaneous phrases }

  assembled =
    'assembled                     ';
  errorfile =
    'errors                        ';
  fileconflict =
    'use different source and code ';
  keyboard =
    'keyboard                      ';
  no =
    'no                            ';
  parsed =
    'parsed                        ';
  scanned =
    'scanned                       ';
  screen =
    'screen                        ';
  yes =
    'yes                           ';

  { characters and ordinal values }

  apostrophe = '''' ; sp = ' ';
  etx = 3; del = 127; nl = 10;
  null = 0;

type
  { common types }

  binary = file of integer;
  caserecord =
    record
      value, index: integer
    end;
  casetable =
    array [1..maxcase] of caserecord;
  phrase =
    packed array [1..maxphrase] of
      char;
  string =
    packed array [1..maxstring] of
      char;
  { a dual real is used with
    an undefined tag field to
    convert a real "a" to its
    binary representation by
    two integers "b" and "c"
    (or vice versa) }
  dualreal =
    record
      case split: boolean of
        false: (a: real);
        true: (b, c: integer)
    end;

{ phrase routines }

function phraselength(
  value: phrase): integer;
var i, j: integer;
begin
  i := 0; j := maxphrase;
  while i < j do
    if value[j] = sp
      then j := j - 1
      else i := j;
  phraselength := i
end;

procedure writephrase(
  var outfile: text;
  value: phrase);
begin
  write(outfile, value:
    phraselength(value))
end;

procedure readphrase(
  var value: phrase);
var ch: char; i: integer;
begin
  repeat
    while eoln do readln;
    read(ch)
  until ch <> sp;
  value[1] := ch;
  for i := 2 to maxphrase do
    if not eoln
      then read(value[i])
      else value[i] := sp;
  while not eoln do read(ch);
  readln
end;

procedure readboolean(
  var value: boolean);
var word: phrase;
begin
  readphrase(word);
  while (word <> yes)
    and (word <> no) do
      begin
        write(
          '      yes or no? ');
        readphrase(word)
      end;
  value := (word = yes)
end;

{ string routines }

function stringlength(
  value: string): integer;
var i, j: integer;
begin
  i := 0; j := maxstring;
  while i < j do
    if value[j] = chr(null)
      then j := j - 1
      else i := j;
  stringlength := i
end;

procedure writestring(
  var outfile: text;
  value: string;
  width: integer);
var i, n: integer;
begin
  n := stringlength(value);
  if width > n then
    for i := 1 to width - n do
      write(outfile, sp)
  else n := width;
  write(outfile, value:n)
end;
