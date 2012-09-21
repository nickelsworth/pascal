{         SUPERPASCAL COMPILER
              MAIN PROGRAM
             20 August 1993
  Copyright (c) 1993 Per Brinch Hansen }

program main(input, output);
#include "common.p"
#include "scan.p"
#include "parse.p"
#include "assemble.p"

procedure compile;
label 1 { exit };
type
  table =
    array [1..maxbuf] of
      integer;
  buffer =
    record
      contents: table;
      length: integer
    end;
var
  sourcename, codename: phrase;
  errors, source: text;
  code: binary;
  inpbuf, outbuf: buffer;
  compiled, endline, lineok,
  optimizing, testing: boolean;
  lineno, pass: integer;

procedure error(kind: phrase);
var n: integer;
begin
  if lineok then
    begin
      if compiled then
        begin
          compiled := false;
          writeln
        end;
      n := phraselength(kind);
      writeln(errors,
        'line ', lineno:4, sp,
        kind:n);
      writeln(
        'line ', lineno:4, sp,
        kind:n);
      lineok := false
    end
end;

procedure halt(kind: phrase);
var n: integer;
begin
  if compiled then
    begin
      compiled := false;
      writeln
    end;
  n := phraselength(kind);
  writeln(errors,
    'line ', lineno:4, sp,
    kind:n);
  writeln(
    'line ', lineno:4, sp,
    kind:n);
  goto 1
end;

procedure newline(no: integer);
begin
  lineno := no;
  lineok := true
end;

procedure accept(var ch: char);
begin
  if eof(source) then
    begin
      lineno := lineno + 1;
      ch := chr(etx)
    end
  else
    begin
      if endline then
        begin
          lineno := lineno + 1;
          endline := false;
          lineok := true;
          if testing then
            write(lineno:4, sp)
        end;
      if eoln(source) then
        begin
          readln(source);
          ch := chr(nl);
          endline := true;
          if testing then
            writeln
        end
      else
        begin
          read(source, ch);
          if testing then
            write(ch)
        end
    end
end;

procedure put(value: integer);
begin
  if outbuf.length = maxbuf
    then halt(maxbuf5);
  outbuf.length :=
    outbuf.length + 1;
  outbuf.contents[
    outbuf.length] := value
end;

procedure get(
  var value: integer);
begin
  inpbuf.length :=
    inpbuf.length + 1;
  value := inpbuf.contents[
    inpbuf.length];
  if testing then
    writeln(pass:1, sp,
      value:12)
end;

procedure getreal(
  var value: real);
var dual: dualreal;
begin
  dual.split := true;
  get(dual.b);
  get(dual.c);
  dual.split := false;
  value := dual.a
end;

procedure putreal(value: real);
var dual: dualreal;
begin
  dual.split := false;
  dual.a := value;
  dual.split := true;
  put(dual.b);
  put(dual.c)
end;

procedure getstring(
  var length: integer;
  var value: string);
var c, i: integer;
begin
  get(length);
  for i := 1 to length do
    begin
      get(c);
      value[i] := chr(c)
    end;
  for i := length + 1
    to maxstring do
      value[i] := chr(null)
end;

procedure putstring(
  length: integer;
  value: string);
var i: integer;
begin
  put(length);
  for i := 1 to length do
    put(ord(value[i]))
end;

procedure getcase(
  var lineno, length: integer;
  var table: casetable);
var i: integer;
begin
  get(lineno); get(length);
  for i := 1 to length do
    begin
      get(table[i].value);
      get(table[i].index)
    end
end;

procedure putcase(
  lineno, length: integer;
  table: casetable);
var i: integer;
begin
  put(lineno); put(length);
  for i := 1 to length do
    begin
      put(table[i].value);
      put(table[i].index)
    end
end;

function checksum: integer;
const n = 8191;
var i, sum, x: integer;
begin
  sum := 0;
  for i := 1 to outbuf.length do
    begin
      x := outbuf.contents[i];
      sum :=
       (sum + x mod n) mod n
    end;
  checksum := sum
end;

procedure testoutput(
  kind: phrase);
const
  max = 5 { symbols/line };
var i, n: integer;
  log: text;
begin
  if testing then
    begin
      { nonstandard rewrite }
      rewrite(log, kind);
      writephrase(log,
        sourcename);
      write(log, sp);
      writephrase(log, kind);
      writeln(log);
      n := outbuf.length;
      for i := 1 to
        outbuf.length do
          begin
            if i mod max = 1
              then
                writeln(log);
            write(log, outbuf.
              contents[i]:12)
          end;
      writeln(log);
      writeln(log);
      writeln(log,
         'check sum = ',
        checksum:4);
      writeln
    end
end;

procedure codeoutput;
var i: integer;
begin
  { nonstandard rewrite }
  rewrite(code, codename);
  for i := 1 to outbuf.length do
    write(code,
      outbuf.contents[i])
end;

procedure rerun;
begin
  inpbuf.length := 0;
  outbuf.length := 0
end;

procedure firstpass;
begin
  write('    source = ');
  readphrase(sourcename);
  write('    code = ');
  readphrase(codename);
  if testoptions then
    begin
      write(
        '    test output? ');
      readboolean(testing);
      write(
        '    optimize? ');
      readboolean(optimizing);
      if testing then writeln
    end
  else
    begin
      testing := false;
      optimizing := true
    end;
  compiled := true;
  lineno := 0;
  { nonstandard rewrite }
  rewrite(errors, errorfile);
  writephrase(errors,
    sourcename);
  writeln(errors);
  writeln(errors);
  if sourcename = codename
    then halt(fileconflict);
  { nonstandard reset }
  reset(source, sourcename);
  pass := 1;
  outbuf.length := 0;
  endline := true;
  lineno := 0
end;

procedure nextpass;
begin
  pass := pass + 1;
  { swap buffers }
  inpbuf := outbuf;
  inpbuf.length := 0;
  outbuf.length := 0
end;

procedure exit;
begin
  if compiled then
    writeln(errors,
      'no errors found')
  else writeln
end;

begin
  firstpass;
  scan(lineno, accept, put,
    putreal, putstring,
    error, halt);
  if compiled then
    begin
      testoutput(scanned);
      nextpass;
      parse(newline, get, put,
        getreal, putreal,
        getstring, putstring,
        putcase, error, halt);
      if compiled then
        begin
          testoutput(parsed);
          nextpass;
          assemble(optimizing,
            get, put, getreal,
            putreal, getstring,
            putstring, getcase,
            putcase, rerun,
            halt);
          if compiled then
            begin
              testoutput(
                assembled);
              codeoutput
            end
        end
    end;
  1: exit
end { compile };

begin compile end.
