{         SUPERPASCAL COMPILER
                SCANNER
            28 October 1993
  Copyright (c) 1993 Per Brinch Hansen }

procedure scan(var lineno: integer;
  procedure accept(var value: char);
  procedure put(value: integer);
  procedure putreal(value: real);
  procedure putstring(
    length: integer;
    value: string);
  procedure error(kind: phrase);
  procedure halt(kind: phrase));
const
  maxkey = 631; maxshort = 10;
type
  charset = set of char;
  short =
    packed array [1..maxshort] of
      char;
  spellingtable =
    array [1..maxchar] of char;
  wordpointer = ^ wordrecord;
  wordrecord =
    record
      nextword: wordpointer;
      symbol: boolean;
      index, length, lastchar:
        integer
    end;
  hashtable =
    array [1..maxkey] of wordpointer;
var
  ch: char; afterperiod: boolean;
  alphanumeric, capitalletters,
  digits, endcomment, endline,
  invisible, letters, radix,
  separators, smallletters: charset;
  spelling: spellingtable;
  characters, identifiers: integer;
  hash: hashtable;
  nulstring: string;

{ INPUT }

procedure nextchar;
var skipped: boolean;
begin
  repeat
    accept(ch);
    if (ch < chr(null))
      or (ch > chr(del))
    then
      skipped := true
    else
      skipped := ch in invisible
  until not skipped
end;

{ OUTPUT }

procedure emit1(sym: integer);
begin put(sym) end;

procedure emit2(
  sym, arg: integer);
begin
  put(sym); put(arg)
end;

procedure emitreal(value: real);
begin
  put(realconst1);
  putreal(value)
end;

procedure emitstring(
  length: integer;
  value: string);
begin
  put(stringconst1);
  putstring(length, value)
end;

{ WORD SYMBOLS AND IDENTIFIERS }

function key(text: string;
  length: integer): integer;
const w = 32641 { 32768 - 127 };
  n = maxkey;
var i, sum: integer;
begin
  sum := 0; i := 1;
  while i <= length do
    begin
      sum := (sum + ord(text[i]))
        mod w;
      i := i + 1
    end;
  key := sum mod n + 1
end;

procedure insert(
  symbol: boolean; text: string;
  length, index, keyno: integer);
var pointer: wordpointer;
  m, n: integer;
begin
  { insert word in
    spelling table }
  characters :=
    characters + length;
  if characters > maxchar then
    halt(maxchar5);
  m := length;
  n := characters - m;
  while m > 0 do
    begin
      spelling[m + n] := text[m];
      m := m - 1
    end;
  { insert word in a word list }
  new(pointer);  
  pointer^.nextword :=
    hash[keyno];
  pointer^.symbol := symbol;
  pointer^.index := index;
  pointer^.length := length;
  pointer^.lastchar :=
    characters;
  hash[keyno] := pointer
end;

function found(text: string;
  length: integer;
  pointer: wordpointer): boolean;
var same: boolean; m, n: integer;
begin
  if pointer^.length = length then
    begin
      same := true; m := length;
      n := pointer^.lastchar - m;
      while same and (m > 0) do
        begin
          same := text[m] =
            spelling[m + n];
          m := m - 1
        end
    end
  else same := false;
  found := same
end;

procedure declare(
  shorttext: short;
  index: integer;
  symbol: boolean);
var i, length: integer;
  text: string;
begin
  length := maxshort;
  while shorttext[length] = sp
    do length := length - 1;
  for i := 1 to length do
    text[i] := shorttext[i];
  insert(symbol, text, length,
    index, key(text, length))
end;

procedure search(
  text: string;
  length: integer;
  var symbol: boolean;
  var index: integer);
var keyno: integer;
  pointer: wordpointer;
  done: boolean;
begin
  keyno := key(text, length);
  pointer := hash[keyno];
  done := false;
  while not done do
    if pointer = nil then
      begin
        symbol := false;
        identifiers :=
          identifiers + 1;
        index := identifiers;
        insert(false, text,
          length, index, keyno);
        done := true
      end
    else if
      found(text, length, pointer)
        then
      begin
        symbol := pointer^.symbol;
        index := pointer^.index;
        done := true
      end
    else
      pointer := pointer^.nextword
end;

{ WordSymbol =
    "and" | "array" | "assume" |
    "begin" | "case" | "const" |
    "div" | "do" | "downto" |
    "else" | "end" | "for" |
    "forall" | "function" | "if" |
    "mod" | "not" | "of" | "or" |
    "parallel" | "procedure" |
    "program" | "record" |
    "repeat" | "sic" | "then" |
    "to" | "type" | "until" |
    "var" | "while" .
  UnusedWord =
    "file" | "goto" | "in" |
    "label" | "nil" | "packed" |
    "set" | "with" . }

procedure initialize;
var i: integer;
begin
  digits := ['0'..'9'];
  capitalletters := ['A'..'Z'];
  smallletters := ['a'..'z'];
  letters :=
    capitalletters + smallletters;
  alphanumeric := letters + digits;
  endcomment := ['}', chr(etx)];
  endline := [chr(nl), chr(etx)];
  invisible :=
    [chr(0)..chr(31), chr(127)]
      - [chr(nl), chr(etx)];
  radix := ['e', 'E'];
  separators := [sp, chr(nl), '{'];
  for i := 1 to maxkey do
    hash[i] := nil;
  for i := 1 to maxstring do
    nulstring[i] := chr(null);
  characters := 0;
  { insert word symbols }
  declare('and       ', and1,
    true);
  declare('array     ', array1,
    true);
  declare('assume    ', assume1,
    true);
  declare('begin     ', begin1,
    true);
  declare('case      ', case1,
    true);
  declare('const     ', const1,
    true);
  declare('div       ', div1,
    true);
  declare('do        ', do1,
    true);
  declare('downto    ', downto1,
    true);
  declare('else      ', else1,
    true);
  declare('end       ', end1,
    true);
  declare('file      ', unknown1,
    true);
  declare('for       ', for1,
    true);
  declare('forall    ', forall1,
    true);
  declare('function  ', function1,
    true);
  declare('goto      ', unknown1,
    true);
  declare('if        ', if1,
    true);
  declare('in        ', unknown1,
    true);
  declare('label     ', unknown1,
    true);
  declare('mod       ', mod1,
    true);
  declare('nil       ', unknown1,
    true);
  declare('not       ', not1,
    true);
  declare('of        ', of1,
    true);
  declare('or        ', or1,
    true);
  declare('packed    ', unknown1,
    true);
  declare('parallel  ', parallel1,
    true);
  declare('procedure ', procedure1,
    true);
  declare('program   ', program1,
    true);
  declare('record    ', record1,
    true);
  declare('repeat    ', repeat1,
    true);
  declare('set       ', unknown1,
    true);
  declare('sic       ', sic1,
    true);
  declare('then      ', then1,
    true);
  declare('to        ', to1,
    true);
  declare('type      ', type1,
    true);
  declare('until     ', until1,
    true);
  declare('var       ', var1,
    true);
  declare('while     ', while1,
    true);
  declare('with      ', unknown1,
    true);
  { insert standard identifiers }
  declare('abs       ', abs0,
    false);
  declare('arctan    ', arctan0,
    false);
  declare('boolean   ', boolean0,
    false);
  declare('char      ', char0,
    false);
  declare('chr       ', chr0,
    false);
  declare('cos       ', cos0,
    false);
  declare('eof       ', eof0,
    false);
  declare('eoln      ', eoln0,
    false);
  declare('exp       ', exp0,
    false);
  declare('false     ', false0,
    false);
  declare('integer   ', integer0,
    false);
  declare('ln        ', ln0,
    false);
  declare('maxint    ', maxint0,
    false);
  declare('maxstring ', maxstring0,
    false);
  declare('null      ', null0,
    false);
  declare('odd       ', odd0,
    false);
  declare('open      ', open0,
    false);
  declare('ord       ', ord0,
    false);
  declare('pred      ', pred0,
    false);
  declare('read      ', read0,
    false);
  declare('readln    ', readln0,
    false);
  declare('real      ', real0,
    false);
  declare('receive   ', receive0,
    false);
  declare('round     ', round0,
    false);
  declare('send      ', send0,
    false);
  declare('sin       ', sin0,
    false);
  declare('sqr       ', sqr0,
    false);
  declare('sqrt      ', sqrt0,
    false);
  declare('string    ', string0,
    false);
  declare('succ      ', succ0,
    false);
  declare('true      ', true0,
    false);
  declare('trunc     ', trunc0,
    false);
  declare('write     ', write0,
    false);
  declare('writeln   ', writeln0,
    false);
  identifiers := maxstandard;
  afterperiod := false
end;

{ LEXICAL ANALYSIS }

{ Comment =
    LeftBrace [ CommentElement ]*
      RightBrace .
  CommentElement =
    GraphicCharacter | NewLine |
    Comment . }

procedure comment;
begin
  (* ch = '{' *) nextchar;
  while not (ch in endcomment) do
    if ch = '{' then comment
    else
      begin
        if ch = chr(nl) then
          begin
            nextchar;
            emit2(newline1, lineno)
          end
        else nextchar
      end;
  if ch = '}' then nextchar
  else error(comment3)
end;

{ Word =
    WordSymbol | Identifier .
  Identifier =
    Letter [ Letter | Digit ]* . }

procedure word;
var symbol: boolean; text: string;
  length, index: integer;
begin
  { ch in letters }
  length := 0;
  while ch in alphanumeric do
    begin
      { convert a capital letter
        (if any) to lower case }
      if ch in capitalletters then
        ch := chr(ord(ch) +
          ord('a') - ord('A'));
      if length = maxstring then
        halt(maxstring5);
      length := length + 1;
      text[length] := ch;
      nextchar;
    end;
  search(text, length, symbol,
    index);
  if symbol then emit1(index)
  else emit2(identifier1, index)
end;

function scaled(r: real;
  s: integer): real;
{ scaled(r,s) = r*(10**s) }
var max, min: real;
begin
  max := maxreal / 10.0;
  while s > 0 do
    begin
      if r <= max then
        r := r * 10.0
      else error(number3);
      s := s - 1
    end;
  min := 10.0 * minreal;
  while s < 0 do
    begin
      if r >= min then
        r := r / 10.0
      else r := 0.0;
      s := s + 1
    end;
  scaled := r
end;

{ DigitSequence =
    Digit [ Digit ]* . }

procedure digitsequence(
  var r: real;
  var n: integer);
{ r := digitsequence;
  n := length(r) }
var d: real;
begin
  r := 0.0; n := 0;
  if ch in digits then
    while ch in digits do
      begin
        d := ord(ch) - ord('0');
        r := 10.0 * r + d;
        n := n + 1;
        nextchar
      end
  else error(number3)
end;

{ UnsignedScaleFactor =
    DigitSequence . }

procedure unsignedscalefactor(
  var s: integer);
{ s := scalefactor }
var r: real; n: integer;
begin
  digitsequence(r, n);
  if r > maxint then
    begin
      error(number3);
      s := 0
    end
  else s := trunc(r)
end;

{ ScaleFactor =
    [ Sign ]
      UnsignedScaleFactor .
  Sign =
    "+" | "-" . }

procedure scalefactor(
  var s: integer);
{ s := scalefactor }
begin
  if ch = '+' then
    begin
      nextchar;
      unsignedscalefactor(s)
    end
  else if ch = '-' then
    begin
      nextchar;
      unsignedscalefactor(s);
      s := - s
    end
  else unsignedscalefactor(s)
end;

{ UnsignedInteger =
    DigitSequence . }

procedure unsignedinteger(
  r: real);
var i: integer;
begin
  if r >  maxint then
    begin
      error(number3);
      i := 0
    end
  else i := trunc(r);
  emit2(intconst1, i)
end;

{ UnsignedNumber =
    UnsignedReal |
    UnsignedInteger .
  UnsignedReal =
    IntegerPart RealOption .
  IntegerPart =
    DigitSequence .
  RealOption =
    "." FractionalPart
      [ ScalingPart ] |
    ScalingPart .
  FractionalPart =
    DigitSequence .
  ScalingPart =
    Radix ScaleFactor .
  Radix =
    "e" | "E" . }

procedure unsignednumber;
var i, f, r: real;
  s, n: integer;
begin
  digitsequence(i, n);
  if ch = '.' then
    begin
      nextchar;
      if ch = '.' then
        begin
          { input = i..
            and ch = '.' }
          unsignedinteger(i);
          afterperiod := true
        end
      else
        begin
          digitsequence(f, n);
          r := i + scaled(f, -n);
          { r = i.f }
          if ch in radix then
            begin
              nextchar;
              scalefactor(s);
              r := scaled(r, s)
              {r = i.f*(10**s) }
            end;
          emitreal(r)
        end
    end
  else if ch in radix then
    begin
      nextchar;
      scalefactor(s);
      r := scaled(i, s);
      { r = i*(10**s) }
      emitreal(r)
    end
  else unsignedinteger(i)
end;

{ StringElement =
    StringCharacter |
    ApostropheImage .
  ApostropheImage =
    "''" . }

procedure stringelement(
  var text: string;
  var length: integer);
begin
  if length = maxstring then
    halt(maxstring5);
  length := length + 1;
  text[length] := ch;
  nextchar
end;

{ CharacterString =
    "'" StringElements "'" .
  StringElements =
    StringElement
      [ StringElement ]* . }

procedure characterstring;
type state =
  (extend, accept, reject);
var length: integer; s: state;
  text: string;
begin
  { ch = apostrophe }
  text := nulstring;
  length := 0;
  nextchar; s := extend;
  while s = extend do
    if ch in endline then
      s := reject
    else if ch = apostrophe then
      begin
        nextchar;
        if ch = apostrophe then
          stringelement(text,
            length)
        else s := accept
      end
    else
      stringelement(text, length);
  if (s = accept) and (length > 0)
    then
      if length = 1 then
        emit2(charconst1,
          ord(text[1]))
      else
        emitstring(length, text)
    else emit1(unknown1)
end;

{ TokenField =
    [ Separator ]* Token .
  Token =
    Literal | Identifier |
    SpecialSymbol | UnknownToken |
    EndText .
  Literal =
    UnsignedNumber |
    CharacterString .
  SpecialSymbol =
    "(" | ")" | "*" | "+" | "," |
    "-" | "." | "/" | ":" | ";" |
    "<" | "=" | ">" | "[" | "]" |
    ".." | ":=" | "<=" | "<>" |
    ">=" | "|" | WordSymbol .
  UnknownToken =
    UnusedWord | UnusedCharacter .
  UnusedCharacter =
    "!" | """ | "#" | "$" | "%" |
    "&" | "?" | "@" | "\" | "^" |
    "_" | "`" | "~" . }

procedure nexttoken;
begin
  while ch in separators do
    if ch = sp then nextchar
    else if ch = chr(nl) then
      begin
        nextchar;
        emit2(newline1, lineno)
      end
    else (* ch = '{' *) comment;
  if ch in letters then word
  else if ch in digits then
    unsignednumber
  else if ch = apostrophe then
    characterstring
  else if ch = '+' then
    begin
      emit1(plus1);
      nextchar
    end
  else if ch = '-' then
    begin
      emit1(minus1);
      nextchar
    end
  else if ch = '*' then
    begin
      emit1(asterisk1);
      nextchar;
    end
  else if ch = '/' then
    begin
      emit1(slash1);
      nextchar
    end
  else if ch = '<' then
    begin
      nextchar;
      if ch = '=' then
        begin
          emit1(notgreater1);
          nextchar
        end
      else if ch = '>' then
        begin
          emit1(notequal1);
          nextchar
        end
      else emit1(less1)
    end
  else if ch = '=' then
    begin
      emit1(equal1);
      nextchar
    end
  else if ch = '>' then
    begin
      nextchar;
      if ch = '=' then
        begin
          emit1(notless1);
          nextchar
        end
      else emit1(greater1)
    end
  else if ch = ':' then
    begin
      nextchar;
      if ch = '=' then
        begin
          emit1(becomes1);
          nextchar
        end
      else emit1(colon1)
    end
  else if ch = '(' then
    begin
      emit1(leftparenthesis1);
      nextchar
     end
  else if ch = ')' then
    begin
      emit1(rightparenthesis1);
      nextchar
    end
  else if ch = '[' then
    begin
      emit1(leftbracket1);
      nextchar
    end
  else if ch = ']' then
    begin
      emit1(rightbracket1);
      nextchar
    end
  else if ch = ',' then
    begin
      emit1(comma1);
      nextchar
    end
  else if ch = '.' then
    if afterperiod then
      begin
        emit1(doubledot1);
        nextchar;
        afterperiod := false
      end
    else
      begin
        nextchar;
        if ch = '.' then
          begin
            emit1(doubledot1);
            nextchar
          end
        else emit1(period1)
      end
  else if ch = ';' then
    begin
      emit1(semicolon1);
      nextchar
    end
  else if ch = '|' then
    begin
      emit1(bar1);
      nextchar
    end
  else if ch <> chr(etx) then
    begin
      emit1(unknown1);
      nextchar
    end
end;

{ Program =
    TokenField [ TokenField ]* . }

begin
  initialize; nextchar;
  emit2(newline1, lineno);
  while ch <> chr(etx) do
    nexttoken;
  emit1(endtext1)
end;
