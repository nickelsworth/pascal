{2:}{4:}{$C-,A+,D-}{$C+,D+}{:4}
program TANGLE(WEBFILE, CHANGEFILE, PASCALFILE, POOL);

label
  9999;
const{8:}
  BUFSIZE = 100;
  MAXBYTES = 45000;
  MAXTOKS = 50000;
  MAXNAMES = 4000;
  MAXTEXTS = 2000;
  HASHSIZE = 353;
  LONGESTNAME = 400;
  LINELENGTH = 72;
  OUTBUFSIZE = 144;
  STACKSIZE = 50;
  MAXIDLENGTH = 12;
  UNAMBIGLENGT = 7;{:8}
type
  {11:}ASCIICODE = 0..127;{:11}{12:}
  TEXTFILE = packed file of char;
  {:12}{37:}EIGHTBITS = 0..255;
  SIXTEENBITS = 0..65535;
  {:37}{39:}NAMEPOINTER = 0..MAXNAMES;{:39}{43:}
  TEXTPOINTER = 0..MAXTEXTS;{:43}{78:}

  OUTPUTSTATE = record
    ENDFIELD: SIXTEENBITS;
    BYTEFIELD: SIXTEENBITS;
    NAMEFIELD: NAMEPOINTER;
    REPLFIELD: TEXTPOINTER;
    MODFIELD: 0..12287;
  end;{:78}
var
  {9:}HISTORY: 0..3;
  {:9}{13:}XORD: array[char] of ASCIICODE;
  XCHR: array[ASCIICODE] of char;
  {:13}{20:}TERMOUT: TEXTFILE;{:20}{23:}
  WEBFILE: TEXTFILE;
  CHANGEFILE: TEXTFILE;
  {:23}{25:}PASCALFILE: TEXTFILE;
  POOL: TEXTFILE;
  {:25}{27:}BUFFER: array[0..BUFSIZE] of ASCIICODE;{:27}{29:}
  PHASEONE: boolean;{:29}{38:}
  BYTEMEM: packed array[0..1, 0..MAXBYTES] of ASCIICODE;
  TOKMEM: packed array[0..2, 0..MAXTOKS] of EIGHTBITS;
  BYTESTART: array[0..MAXNAMES] of SIXTEENBITS;
  TOKSTART: array[0..MAXTEXTS] of SIXTEENBITS;
  LINK: array[0..MAXNAMES] of SIXTEENBITS;
  ILK: array[0..MAXNAMES] of SIXTEENBITS;
  EQUIV: array[0..MAXNAMES] of SIXTEENBITS;
  TEXTLINK: array[0..MAXTEXTS] of SIXTEENBITS;
  {:38}{40:}NAMEPTR: NAMEPOINTER;
  STRINGPTR: NAMEPOINTER;
  BYTEPTR: array[0..1] of 0..MAXBYTES;
  POOLCHECKSUM: integer;
  {:40}{44:}TEXTPTR: TEXTPOINTER;
  TOKPTR: array[0..2] of 0..MAXTOKS;
  Z: 0..2;
  MAXTOKPTR: array[0..2] of 0..MAXTOKS;
  {:44}{50:}IDFIRST: 0..BUFSIZE;
  IDLOC: 0..BUFSIZE;
  DOUBLECHARS: 0..BUFSIZE;
  HASH, CHOPHASH: array[0..HASHSIZE] of SIXTEENBITS;
  CHOPPEDID: array[0..UNAMBIGLENGT] of ASCIICODE;{:50}{65:}
  MODTEXT: array[0..LONGESTNAME] of ASCIICODE;{:65}{70:}
  LASTUNNAMED: TEXTPOINTER;
  {:70}{79:}CURSTATE: OUTPUTSTATE;
  STACK: array[1..STACKSIZE] of OUTPUTSTATE;
  STACKPTR: 0..STACKSIZE;{:79}{80:}
  ZO: 0..2;
  {:80}{82:}BRACELEVEL: EIGHTBITS;
  {:82}{86:}CURVAL: integer;{:86}
  {94:}OUTBUF: array[0..OUTBUFSIZE] of ASCIICODE;
  OUTPTR: 0..OUTBUFSIZE;
  BREAKPTR: 0..OUTBUFSIZE;
  SEMIPTR: 0..OUTBUFSIZE;{:94}{95:}
  OUTSTATE: EIGHTBITS;
  OUTVAL, OUTAPP: integer;
  OUTSIGN: ASCIICODE;
  LASTSIGN: -1.. +1;
  {:95}{100:}OUTCONTRIB: array[1..LINELENGTH] of ASCIICODE;
  {:100}{124:}LINE: integer;
  OTHERLINE: integer;
  TEMPLINE: integer;
  LIMIT: 0..BUFSIZE;
  LOC: 0..BUFSIZE;
  INPUTHASENDE: boolean;
  CHANGING: boolean;
  {:124}{126:}CHANGEBUFFER: array[0..BUFSIZE] of ASCIICODE;
  CHANGELIMIT: 0..BUFSIZE;
  {:126}{143:}CURMODULE: NAMEPOINTER;
  SCANNINGHEX: boolean;
  {:143}{156:}NEXTCONTROL: EIGHTBITS;{:156}{164:}
  CURREPLTEXT: TEXTPOINTER;
  {:164}{171:}MODULECOUNT: 0..12287;{:171}{179:}
  TROUBLESHOOT: boolean;
  DDT: integer;
  DD: integer;
  DEBUGCYCLE: integer;
  DEBUGSKIPPED: integer;
  TERMIN: TEXTFILE;
  {:179}{185:}WO: 0..1;
  {:185}{30:}
  procedure DEBUGHELP; forward;{:30}{31:}

  procedure ERROR;
  var
    J: 0..OUTBUFSIZE;
    K, L: 0..BUFSIZE;
  begin
    if PHASEONE then{32:}
    begin
      if CHANGING then
        Write(TERMOUT, '. (change file ')
      else
        Write(
          TERMOUT, '. (');
      WRITELN(TERMOUT, 'l.', LINE: 1, ')');
      if LOC >= LIMIT then
        L := LIMIT
      else
        L := LOC;
      for K := 1 to L do
        if BUFFER[K - 1] = 9 then
          Write(TERMOUT, ' ')
        else
          Write(
            TERMOUT, XCHR[BUFFER[K - 1]]);
      WRITELN(TERMOUT);
      for K := 1 to L do
        Write(TERMOUT, ' ');
      for K := L + 1 to LIMIT do
        Write(TERMOUT, XCHR[BUFFER[K - 1]]);
      Write(TERMOUT, ' ');
    end{:32}
    else{33:}
    begin
      WRITELN(TERMOUT, '. (l.', LINE: 1, ')');
      for J := 1 to OUTPTR do
        Write(TERMOUT, XCHR[OUTBUF[J - 1]]);
      Write(TERMOUT, '... ');
    end{:33};
    BREAK(TERMOUT);
    HISTORY := 2;
    DEBUGHELP;
  end;

  {:31}{34:}
  procedure JUMPOUT;
  begin
    goto 9999;
  end;{:34}

  procedure Initialize;
  var
    {16:}I: 0..127;
    {:16}{41:}WI: 0..1;{:41}{45:}
    ZI: 0..2;
    {:45}{51:}H: 0..HASHSIZE;{:51}
  begin
    {10:}HISTORY := 0;{:10}{14:}
    XCHR[32] := ' ';
    XCHR[33] := '!';
    XCHR[34] := '"';
    XCHR[35] := '#';
    XCHR[36] := '$';
    XCHR[37] := '%';
    XCHR[38] := '&';
    XCHR[39] := '''';
    XCHR[40] := '(';
    XCHR[41] := ')';
    XCHR[42] := '*';
    XCHR[43] := '+';
    XCHR[44] := ',';
    XCHR[45] := '-';
    XCHR[46] := '.';
    XCHR[47] := '/';
    XCHR[48] := '0';
    XCHR[49] := '1';
    XCHR[50] := '2';
    XCHR[51] := '3';
    XCHR[52] := '4';
    XCHR[53] := '5';
    XCHR[54] := '6';
    XCHR[55] := '7';
    XCHR[56] := '8';
    XCHR[57] := '9';
    XCHR[58] := ':';
    XCHR[59] := ';';
    XCHR[60] := '<';
    XCHR[61] := '=';
    XCHR[62] := '>';
    XCHR[63] := '?';
    XCHR[64] := '@';
    XCHR[65] := 'A';
    XCHR[66] := 'B';
    XCHR[67] := 'C';
    XCHR[68] := 'D';
    XCHR[69] := 'E';
    XCHR[70] := 'F';
    XCHR[71] := 'G';
    XCHR[72] := 'H';
    XCHR[73] := 'I';
    XCHR[74] := 'J';
    XCHR[75] := 'K';
    XCHR[76] := 'L';
    XCHR[77] := 'M';
    XCHR[78] := 'N';
    XCHR[79] := 'O';
    XCHR[80] := 'P';
    XCHR[81] := 'Q';
    XCHR[82] := 'R';
    XCHR[83] := 'S';
    XCHR[84] := 'T';
    XCHR[85] := 'U';
    XCHR[86] := 'V';
    XCHR[87] := 'W';
    XCHR[88] := 'X';
    XCHR[89] := 'Y';
    XCHR[90] := 'Z';
    XCHR[91] := '[';
    XCHR[92] := '\';
    XCHR[93] := ']';
    XCHR[94] := '^';
    XCHR[95] := '_';
    XCHR[96] := '`';
    XCHR[97] := 'a';
    XCHR[98] := 'b';
    XCHR[99] := 'c';
    XCHR[100] := 'd';
    XCHR[101] := 'e';
    XCHR[102] := 'f';
    XCHR[103] := 'g';
    XCHR[104] := 'h';
    XCHR[105] := 'i';
    XCHR[106] := 'j';
    XCHR[107] := 'k';
    XCHR[108] := 'l';
    XCHR[109] := 'm';
    XCHR[110] := 'n';
    XCHR[111] := 'o';
    XCHR[112] := 'p';
    XCHR[113] := 'q';
    XCHR[114] := 'r';
    XCHR[115] := 's';
    XCHR[116] := 't';
    XCHR[117] := 'u';
    XCHR[118] := 'v';
    XCHR[119] := 'w';
    XCHR[120] := 'x';
    XCHR[121] := 'y';
    XCHR[122] := 'z';
    XCHR[123] := '{';
    XCHR[124] := '|';
    XCHR[125] := '}';
    XCHR[126] := '~';
    XCHR[0] := ' ';
    XCHR[127] := ' ';{:14}{17:}
    for I := 1 to 31 do
      XCHR[I] := ' ';{:17}{18:}
    for I := 0 to 127 do
      XORD[CHR(I)] := 32;
    for I := 1 to 126 do
      XORD[XCHR[I]] := I;
    {:18}{21:}REWRITE(TERMOUT, 'TTY:');
    {:21}{26:}REWRITE(PASCALFILE);
    REWRITE(POOL);
    {:26}{42:}for WI := 0 to 1 do
    begin
      BYTESTART[WI] := 0;
      BYTEPTR[WI] := 0;
    end;
    BYTESTART[2] := 0;
    NAMEPTR := 1;
    STRINGPTR := 128;
    POOLCHECKSUM := 271828;
    {:42}{46:}for ZI := 0 to 2 do
    begin
      TOKSTART[ZI] := 0;
      TOKPTR[ZI] := 0;
    end;
    TOKSTART[3] := 0;
    TEXTPTR := 1;
    Z := 1 mod 3;{:46}{48:}
    ILK[0] := 0;
    EQUIV[0] := 0;{:48}{52:}
    for H := 0 to HASHSIZE - 1 do
    begin
      HASH[H] := 0;
      CHOPHASH[H] := 0;
    end;{:52}{71:}
    LASTUNNAMED := 0;
    TEXTLINK[0] := 0;
    {:71}{144:}SCANNINGHEX := False;{:144}{152:}
    MODTEXT[0] := 32;
    {:152}{180:}TROUBLESHOOT := True;
    DEBUGCYCLE := 1;
    DEBUGSKIPPED := 0;
    TROUBLESHOOT := False;
    DEBUGCYCLE := 99999;
    RESET(TERMIN, 'TTY:', '/I');{:180}
  end;{:2}{24:}

  procedure OPENINPUT;
  begin
    RESET(WEBFILE);
    RESET(CHANGEFILE);
  end;{:24}{28:}

  function INPUTLN(var F: TEXTFILE): boolean;
  var
    FINALLIMIT: 0..BUFSIZE;
  begin
    LIMIT := 0;
    FINALLIMIT := 0;
    if EOF(F) then
      INPUTLN := False
    else
    begin
      while not EOLN(F) do
      begin
        BUFFER
          [LIMIT] := XORD[F^];
        GET(F);
        LIMIT := LIMIT + 1;
        if BUFFER[LIMIT - 1] <> 32 then
          FINALLIMIT := LIMIT;
        if LIMIT = BUFSIZE then
        begin
          while not EOLN(F) do
            GET(F);
          LIMIT := LIMIT - 1;
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Input line too long');
          end;
          LOC := 0;
          ERROR;
        end;
      end;
      READLN(F);
      LIMIT := FINALLIMIT;
      INPUTLN := True;
    end;
  end;

  {:28}{49:}
  procedure PRINTID(P: NAMEPOINTER);
  var
    K: 0..MAXBYTES;
    W: 0..1;
  begin
    if P >= NAMEPTR then
      Write(TERMOUT, 'IMPOSSIBLE')
    else
    begin
      W := P mod 2;
      for K := BYTESTART[P] to BYTESTART[P + 2] - 1 do
        Write(TERMOUT, XCHR[BYTEMEM[W, K]]);
    end;
  end;{:49}{53:}

  function IDLOOKUP(T: EIGHTBITS): NAMEPOINTER;
  label
    31, 32;
  var
    C: EIGHTBITS;
    I: 0..BUFSIZE;
    H: 0..HASHSIZE;
    K: 0..MAXBYTES;
    W: 0..1;
    L: 0..BUFSIZE;
    P, Q: NAMEPOINTER;
    S: 0..UNAMBIGLENGT;
  begin
    L := IDLOC - IDFIRST;
    {54:}H := BUFFER[IDFIRST];
    I := IDFIRST + 1;
    while I < IDLOC do
    begin
      H := (H + H + BUFFER[I]) mod HASHSIZE;
      I := I + 1;
    end{:54};
    {55:}P := HASH[H];
    while P <> 0 do
    begin
      if BYTESTART[P + 2] - BYTESTART[P] = L then{56:}
      begin
        I := IDFIRST;
        K := BYTESTART[P];
        W := P mod 2;
        while (I < IDLOC) and (BUFFER[I] = BYTEMEM[W, K]) do
        begin
          I := I + 1;
          K := K + 1;
        end;
        if I = IDLOC then
          goto 31;
      end{:56};
      P := LINK[P];
    end;
    P := NAMEPTR;
    LINK[P] := HASH[H];
    HASH[H] := P;
    31:
    {:55};
    if (P = NAMEPTR) or (T <> 0) then{57:}
    begin
      if ((P <> NAMEPTR) and (T <> 0) and (ILK[P] = 0)) or ((P = NAMEPTR) and (T = 0) and (BUFFER[IDFIRST] <> 34)) then
        {58:}
      begin
        I := IDFIRST;
        S := 0;
        H := 0;
        while (I < IDLOC) and (S < UNAMBIGLENGT) do
        begin
          if BUFFER[I] <> 95 then
          begin
            if BUFFER[I] >= 97 then
              CHOPPEDID[S] := BUFFER[I] - 32
            else
              CHOPPEDID[S] := BUFFER[I];
            H := (H + H + CHOPPEDID[S]) mod HASHSIZE;
            S := S + 1;
          end;
          I := I + 1;
        end;
        CHOPPEDID[S] := 0;
      end{:58};
      if P <> NAMEPTR then{59:}
      begin
        if ILK[P] = 0 then
        begin
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! This identifier has already appeared');
            ERROR;
          end;{60:}
          Q := CHOPHASH[H];
          if Q = P then
            CHOPHASH[H] := EQUIV[P]
          else
          begin
            while EQUIV[Q] <> P do
              Q :=
                EQUIV[Q];
            EQUIV[Q] := EQUIV[P];
          end{:60};
        end
        else
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! This identifier was defined before');
          ERROR;
        end;
        ILK[P] := T;
      end{:59}
      else{61:}
      begin
        if (T = 0) and (BUFFER[IDFIRST] <> 34) then{62:}
        begin
          Q := CHOPHASH[H];
          while Q <> 0 do
          begin{63:}
            begin
              K := BYTESTART[Q];
              S := 0;
              W := Q mod 2;
              while (K < BYTESTART[Q + 2]) and (S < UNAMBIGLENGT) do
              begin
                C := BYTEMEM[W, K];
                if C <> 95 then
                begin
                  if C >= 97 then
                    C := C - 32;
                  if CHOPPEDID[S] <> C then
                    goto 32;
                  S := S + 1;
                end;
                K := K + 1;
              end;
              if (K = BYTESTART[Q + 2]) and (CHOPPEDID[S] <> 0) then
                goto 32;
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Identifier conflict with ');
              end;
              for K := BYTESTART[Q] to BYTESTART[Q + 2] - 1 do
                Write(TERMOUT, XCHR[BYTEMEM[W, K]]);
              ERROR;
              Q := 0;
              32: ;
            end{:63};
            Q := EQUIV[Q];
          end;
          EQUIV[P] := CHOPHASH[H];
          CHOPHASH[H] := P;
        end{:62};
        W := NAMEPTR mod 2;
        K := BYTEPTR[W];
        if K + L > MAXBYTES then
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Sorry, ', 'byte memory', ' capacity exceeded');
          ERROR;
          HISTORY := 3;
          JUMPOUT;
        end;
        if NAMEPTR > MAXNAMES - 2 then
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Sorry, ', 'name', ' capacity exceeded');
          ERROR;
          HISTORY := 3;
          JUMPOUT;
        end;
        I := IDFIRST;
        while I < IDLOC do
        begin
          BYTEMEM[W, K] := BUFFER[I];
          K := K + 1;
          I := I + 1;
        end;
        BYTEPTR[W] := K;
        BYTESTART[NAMEPTR + 2] := K;
        NAMEPTR := NAMEPTR + 1;
        if BUFFER[IDFIRST] <> 34 then
          ILK[P] := T
        else{64:}
        begin
          ILK[P] := 1;
          if L - DOUBLECHARS = 2 then
            EQUIV[P] := BUFFER[IDFIRST + 1] + 32768
          else
          begin
            EQUIV[P] := STRINGPTR + 32768;
            L := L - DOUBLECHARS - 1;
            if L > 99 then
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Preprocessed string is too long');
              ERROR;
            end;
            STRINGPTR := STRINGPTR + 1;
            Write(POOL, XCHR[48 + L div 10], XCHR[48 + L mod 10]);
            POOLCHECKSUM := POOLCHECKSUM + POOLCHECKSUM + L;
            while POOLCHECKSUM > 536870839 do
              POOLCHECKSUM := POOLCHECKSUM - 536870839;
            I := IDFIRST + 1;
            while I < IDLOC do
            begin
              Write(POOL, XCHR[BUFFER[I]]);
              POOLCHECKSUM := POOLCHECKSUM + POOLCHECKSUM + BUFFER[I];
              while POOLCHECKSUM > 536870839 do
                POOLCHECKSUM := POOLCHECKSUM - 536870839;
              if (BUFFER[I] = 34) or (BUFFER[I] = 64) then
                I := I + 2
              else
                I := I + 1;
            end;
            WRITELN(POOL);
          end;
        end{:64};
      end{:61};
    end{:57};
    IDLOOKUP := P;
  end;{:53}{66:}

  function MODLOOKUP(L: SIXTEENBITS): NAMEPOINTER;
  label
    31;
  var
    C: 0..4;
    J: 0..LONGESTNAME;
    K: 0..MAXBYTES;
    W: 0..1;
    P: NAMEPOINTER;
    Q: NAMEPOINTER;
  begin
    C := 2;
    Q := 0;
    P := ILK[0];
    while P <> 0 do
    begin{68:}
      begin
        K := BYTESTART[P];
        W := P mod 2;
        C := 1;
        J := 1;
        while (K < BYTESTART[P + 2]) and (J <= L) and (MODTEXT[J] = BYTEMEM[W, K]) do
        begin
          K :=
            K + 1;
          J := J + 1;
        end;
        if K = BYTESTART[P + 2] then
          if J > L then
            C := 1
          else
            C := 4
        else if J > L then
          C := 3
        else if MODTEXT[J] < BYTEMEM[W, K] then
          C := 0
        else
          C := 2;
      end{:68};
      Q := P;
      if C = 0 then
        P := LINK[Q]
      else if C = 2 then
        P := ILK[Q]
      else
        goto 31;
    end;{67:}
    W := NAMEPTR mod 2;
    K := BYTEPTR[W];
    if K + L > MAXBYTES then
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Sorry, ', 'byte memory', ' capacity exceeded');
      ERROR;
      HISTORY := 3;
      JUMPOUT;
    end;
    if NAMEPTR > MAXNAMES - 2 then
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Sorry, ', 'name', ' capacity exceeded');
      ERROR;
      HISTORY := 3;
      JUMPOUT;
    end;
    P := NAMEPTR;
    if C = 0 then
      LINK[Q] := P
    else
      ILK[Q] := P;
    LINK[P] := 0;
    ILK[P] := 0;
    C := 1;
    EQUIV[P] := 0;
    for J := 1 to L do
      BYTEMEM[W, K + J - 1] := MODTEXT[J];
    BYTEPTR[W] := K + L;
    BYTESTART[NAMEPTR + 2] := K + L;
    NAMEPTR := NAMEPTR + 1;
    {:67};
    31:
      if C <> 1 then
      begin
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Incompatible section names');
          ERROR;
        end;
        P := 0;
      end;
    MODLOOKUP := P;
  end;{:66}{69:}

  function PREFIXLOOKUP(L: SIXTEENBITS): NAMEPOINTER;
  var
    C: 0..4;
    Count: 0..MAXNAMES;
    J: 0..LONGESTNAME;
    K: 0..MAXBYTES;
    W: 0..1;
    P: NAMEPOINTER;
    Q: NAMEPOINTER;
    R: NAMEPOINTER;
  begin
    Q := 0;
    P := ILK[0];
    Count := 0;
    R := 0;
    while P <> 0 do
    begin{68:}
      begin
        K := BYTESTART[P];
        W := P mod 2;
        C := 1;
        J := 1;
        while (K < BYTESTART[P + 2]) and (J <= L) and (MODTEXT[J] = BYTEMEM[W, K]) do
        begin
          K :=
            K + 1;
          J := J + 1;
        end;
        if K = BYTESTART[P + 2] then
          if J > L then
            C := 1
          else
            C := 4
        else if J > L then
          C := 3
        else if MODTEXT[J] < BYTEMEM[W, K] then
          C := 0
        else
          C := 2;
      end{:68};
      if C = 0 then
        P := LINK[P]
      else if C = 2 then
        P := ILK[P]
      else
      begin
        R := P;
        Count := Count + 1;
        Q := ILK[P];
        P := LINK[P];
      end;
      if P = 0 then
      begin
        P := Q;
        Q := 0;
      end;
    end;
    if Count <> 1 then
      if Count = 0 then
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Name does not match');
        ERROR;
      end
      else
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Ambiguous prefix');
        ERROR;
      end;
    PREFIXLOOKUP := R;
  end;{:69}{73:}

  procedure STORETWOBYTE(X: SIXTEENBITS);
  begin
    if TOKPTR[Z] + 2 > MAXTOKS then
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
      ERROR;
      HISTORY := 3;
      JUMPOUT;
    end;
    TOKMEM[Z, TOKPTR[Z]] := X div 256;
    TOKMEM[Z, TOKPTR[Z] + 1] := X mod 256;
    TOKPTR[Z] := TOKPTR[Z] + 2;
  end;{:73}{74:}

  procedure PRINTREPL(P: TEXTPOINTER);
  var
    K: 0..MAXTOKS;
    A: SIXTEENBITS;
    ZP: 0..2;
  begin
    if P >= TEXTPTR then
      Write(TERMOUT, 'BAD')
    else
    begin
      K := TOKSTART[P];
      ZP := P mod 3;
      while K < TOKSTART[P + 3] do
      begin
        A := TOKMEM[ZP, K];
        if A >= 128 then{75:}
        begin
          K := K + 1;
          if A < 168 then
          begin
            A := (A - 128) * 256 + TOKMEM[ZP, K];
            PRINTID(A);
            if BYTEMEM[A mod 2, BYTESTART[A]] = 34 then
              Write(TERMOUT, '"')
            else
              Write(
                TERMOUT, ' ');
          end
          else if A < 208 then
          begin
            Write(TERMOUT, '@<');
            PRINTID((A - 168) * 256 + TOKMEM[ZP, K]);
            Write(TERMOUT, '@>');
          end
          else
          begin
            A := (A - 208) * 256 + TOKMEM[ZP, K];
            Write(TERMOUT, '@', XCHR[123], A: 1, '@', XCHR[125]);
          end;
        end{:75}
        else{76:}
          case A of
            9: Write(TERMOUT, '@', XCHR[123]);
            10: Write(TERMOUT, '@', XCHR[125]);
            12: Write(TERMOUT, '@''');
            13: Write(TERMOUT, '@"');
            125: Write(TERMOUT, '@$');
            0: Write(TERMOUT, '#');
            64: Write(TERMOUT, '@@');
            2: Write(TERMOUT, '@=');
            3: Write(TERMOUT, '@\');
            OTHERS: Write(TERMOUT, XCHR[A])
          end{:76};
        K := K + 1;
      end;
    end;
  end;{:74}{84:}

  procedure PUSHLEVEL(P: NAMEPOINTER);
  begin
    if STACKPTR = STACKSIZE then
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Sorry, ', 'stack', ' capacity exceeded');
      ERROR;
      HISTORY := 3;
      JUMPOUT;
    end
    else
    begin
      STACK[STACKPTR] := CURSTATE;
      STACKPTR := STACKPTR + 1;
      CURSTATE.NAMEFIELD := P;
      CURSTATE.REPLFIELD := EQUIV[P];
      ZO := CURSTATE.REPLFIELD mod 3;
      CURSTATE.BYTEFIELD := TOKSTART[CURSTATE.REPLFIELD];
      CURSTATE.ENDFIELD := TOKSTART[CURSTATE.REPLFIELD + 3];
      CURSTATE.MODFIELD := 0;
    end;
  end;{:84}{85:}

  procedure POPLEVEL;
  label
    10;
  begin
    if TEXTLINK[CURSTATE.REPLFIELD] = 0 then
    begin
      if ILK[CURSTATE.NAMEFIELD] = 3 then{91:}
      begin
        NAMEPTR := NAMEPTR - 1;
        TEXTPTR := TEXTPTR - 1;
        Z := TEXTPTR mod 3;
        if TOKPTR[Z] > MAXTOKPTR[Z] then
          MAXTOKPTR[Z] := TOKPTR[Z];
        TOKPTR[Z] := TOKSTART[TEXTPTR];
        BYTEPTR[NAMEPTR mod 2] := BYTEPTR[NAMEPTR mod 2] - 1;
      end{:91};
    end
    else if TEXTLINK[CURSTATE.REPLFIELD] < MAXTEXTS then
    begin
      CURSTATE.
        REPLFIELD := TEXTLINK[CURSTATE.REPLFIELD];
      ZO := CURSTATE.REPLFIELD mod 3;
      CURSTATE.BYTEFIELD := TOKSTART[CURSTATE.REPLFIELD];
      CURSTATE.ENDFIELD := TOKSTART[CURSTATE.REPLFIELD + 3];
      goto 10;
    end;
    STACKPTR := STACKPTR - 1;
    if STACKPTR > 0 then
    begin
      CURSTATE := STACK[STACKPTR];
      ZO := CURSTATE.REPLFIELD mod 3;
    end;
    10: ;
  end;{:85}{87:}

  function GETOUTPUT: SIXTEENBITS;
  label
    20, 30, 31;
  var
    A: SIXTEENBITS;
    B: EIGHTBITS;
    BAL: SIXTEENBITS;
    K: 0..MAXBYTES;
    W: 0..1;
  begin
    20:
      if STACKPTR = 0 then
      begin
        A := 0;
        goto 31;
      end;
    if CURSTATE.BYTEFIELD = CURSTATE.ENDFIELD then
    begin
      CURVAL := -CURSTATE.MODFIELD;
      POPLEVEL;
      if CURVAL = 0 then
        goto 20;
      A := 129;
      goto 31;
    end;
    A := TOKMEM[ZO, CURSTATE.BYTEFIELD];
    CURSTATE.BYTEFIELD := CURSTATE.BYTEFIELD + 1;
    if A < 128 then
      if A = 0 then{92:}
      begin
        PUSHLEVEL(NAMEPTR - 1);
        goto 20;
      end{:92}
      else
        goto 31;
    A := (A - 128) * 256 + TOKMEM[ZO, CURSTATE.BYTEFIELD];
    CURSTATE.BYTEFIELD := CURSTATE.BYTEFIELD + 1;
    if A < 10240 then{89:}
    begin
      case ILK[A] of
        0:
        begin
          CURVAL := A;
          A := 130;
        end;
        1:
        begin
          CURVAL := EQUIV[A] - 32768;
          A := 128;
        end;
        2:
        begin
          PUSHLEVEL(A);
          goto 20;
        end;
        3:
        begin{90:}
          while (CURSTATE.BYTEFIELD = CURSTATE.ENDFIELD) and (STACKPTR > 0) do
            POPLEVEL;
          if (STACKPTR = 0) or (TOKMEM[ZO, CURSTATE.BYTEFIELD] <> 40) then
          begin
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! No parameter given for ');
            end;
            PRINTID(A);
            ERROR;
            goto 20;
          end;
          {93:}BAL := 1;
          CURSTATE.BYTEFIELD := CURSTATE.BYTEFIELD + 1;
          while True do
          begin
            B := TOKMEM[ZO, CURSTATE.BYTEFIELD];
            CURSTATE.BYTEFIELD := CURSTATE.BYTEFIELD + 1;
            if B = 0 then
              STORETWOBYTE(NAMEPTR + 32767)
            else
            begin
              if B >= 128 then
              begin
                begin
                  if TOKPTR[Z] = MAXTOKS then
                  begin
                    WRITELN(TERMOUT);
                    Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                    ERROR;
                    HISTORY := 3;
                    JUMPOUT;
                  end;
                  TOKMEM[Z, TOKPTR[Z]] := B;
                  TOKPTR[Z] := TOKPTR[Z] + 1;
                end;
                B := TOKMEM[ZO, CURSTATE.BYTEFIELD];
                CURSTATE.BYTEFIELD := CURSTATE.BYTEFIELD + 1;
              end
              else
                case B of
                  40: BAL := BAL + 1;
                  41:
                  begin
                    BAL := BAL - 1;
                    if BAL = 0 then
                      goto 30;
                  end;
                  39: repeat
                      begin
                        if TOKPTR[Z] = MAXTOKS then
                        begin
                          WRITELN(TERMOUT);
                          Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                          ERROR;
                          HISTORY := 3;
                          JUMPOUT;
                        end;
                        TOKMEM[Z, TOKPTR[Z]] := B;
                        TOKPTR[Z] := TOKPTR[Z] + 1;
                      end;
                      B := TOKMEM[ZO, CURSTATE.BYTEFIELD];
                      CURSTATE.BYTEFIELD := CURSTATE.BYTEFIELD + 1;
                    until B = 39;
                  OTHERS:
                end;
              begin
                if TOKPTR[Z] = MAXTOKS then
                begin
                  WRITELN(TERMOUT);
                  Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                  ERROR;
                  HISTORY := 3;
                  JUMPOUT;
                end;
                TOKMEM[Z, TOKPTR[Z]] := B;
                TOKPTR[Z] := TOKPTR[Z] + 1;
              end;
            end;
          end;
          30:
          {:93};
          EQUIV[NAMEPTR] := TEXTPTR;
          ILK[NAMEPTR] := 2;
          W := NAMEPTR mod 2;
          K := BYTEPTR[W];
          if K = MAXBYTES then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Sorry, ', 'byte memory', ' capacity exceeded');
            ERROR;
            HISTORY := 3;
            JUMPOUT;
          end;
          BYTEMEM[W, K] := 35;
          K := K + 1;
          BYTEPTR[W] := K;
          if NAMEPTR > MAXNAMES - 2 then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Sorry, ', 'name', ' capacity exceeded');
            ERROR;
            HISTORY := 3;
            JUMPOUT;
          end;
          BYTESTART[NAMEPTR + 2] := K;
          NAMEPTR := NAMEPTR + 1;
          if TEXTPTR > MAXTEXTS - 3 then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Sorry, ', 'text', ' capacity exceeded');
            ERROR;
            HISTORY := 3;
            JUMPOUT;
          end;
          TEXTLINK[TEXTPTR] := 0;
          TOKSTART[TEXTPTR + 3] := TOKPTR[Z];
          TEXTPTR := TEXTPTR + 1;
          Z := TEXTPTR mod 3{:90};
          PUSHLEVEL(A);
          goto 20;
        end;
        OTHERS:
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! This can''t happen (', 'output', ')');
          ERROR;
          HISTORY := 3;
          JUMPOUT;
        end
      end;
      goto 31;
    end{:89};
    if A < 20480 then{88:}
    begin
      A := A - 10240;
      if EQUIV[A] <> 0 then
        PUSHLEVEL(A)
      else if A <> 0 then
      begin
        begin
          WRITELN(
            TERMOUT);
          Write(TERMOUT, '! Not present: <');
        end;
        PRINTID(A);
        Write(TERMOUT, '>');
        ERROR;
      end;
      goto 20;
    end{:88};
    CURVAL := A - 20480;
    A := 129;
    CURSTATE.MODFIELD := CURVAL;
    31:
      if TROUBLESHOOT then
        DEBUGHELP;
    GETOUTPUT := A;
  end;{:87}{97:}

  procedure FLUSHBUFFER;
  var
    K: 0..OUTBUFSIZE;
    B: 0..OUTBUFSIZE;
  begin
    B := BREAKPTR;
    if (SEMIPTR <> 0) and (OUTPTR - SEMIPTR <= LINELENGTH) then
      BREAKPTR := SEMIPTR;
    for K := 1 to BREAKPTR do
      Write(PASCALFILE, XCHR[OUTBUF[K - 1]]);
    WRITELN(PASCALFILE);
    LINE := LINE + 1;
    if LINE mod 100 = 0 then
    begin
      Write(TERMOUT, '.');
      if LINE mod 500 = 0 then
        Write(TERMOUT, LINE: 1);
      BREAK(TERMOUT);
    end;
    if BREAKPTR < OUTPTR then
    begin
      if OUTBUF[BREAKPTR] = 32 then
      begin
        BREAKPTR := BREAKPTR + 1;
        if BREAKPTR > B then
          B := BREAKPTR;
      end;
      for K := BREAKPTR to OUTPTR - 1 do
        OUTBUF[K - BREAKPTR] := OUTBUF[K];
    end;
    OUTPTR := OUTPTR - BREAKPTR;
    BREAKPTR := B - BREAKPTR;
    SEMIPTR := 0;
    if OUTPTR > LINELENGTH then
    begin
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Long line must be truncated');
        ERROR;
      end;
      OUTPTR := LINELENGTH;
    end;
  end;{:97}{99:}

  procedure APPVAL(V: integer);
  var
    K: 0..OUTBUFSIZE;
  begin
    K := OUTBUFSIZE;
    repeat
      OUTBUF[K] := V mod 10;
      V := V div 10;
      K := K - 1;
    until V = 0;
    repeat
      K := K + 1;
      begin
        OUTBUF[OUTPTR] := OUTBUF[K] + 48;
        OUTPTR := OUTPTR + 1;
      end;
    until K = OUTBUFSIZE;
  end;{:99}{101:}

  procedure SENDOUT(T: EIGHTBITS; V: SIXTEENBITS);
  label
    20;
  var
    K: 0..LINELENGTH;
  begin{102:}
    20:
      case OUTSTATE of
        1: if T <> 3 then
          begin
            BREAKPTR := OUTPTR;
            if T = 2 then
            begin
              OUTBUF[OUTPTR] := 32;
              OUTPTR := OUTPTR + 1;
            end;
          end;
        2:
        begin
          begin
            OUTBUF[OUTPTR] := 44 - OUTAPP;
            OUTPTR := OUTPTR + 1;
          end;
          if OUTPTR > LINELENGTH then
            FLUSHBUFFER;
          BREAKPTR := OUTPTR;
        end;
        3, 4:
        begin{103:}
          if (OUTVAL < 0) or ((OUTVAL = 0) and (LASTSIGN < 0)) then
          begin
            OUTBUF[OUTPTR] := 45;
            OUTPTR := OUTPTR + 1;
          end
          else if OUTSIGN > 0 then
          begin
            OUTBUF[OUTPTR] := OUTSIGN;
            OUTPTR := OUTPTR + 1;
          end;
          APPVAL(ABS(OUTVAL));
          if OUTPTR > LINELENGTH then
            FLUSHBUFFER;
          {:103};
          OUTSTATE := OUTSTATE - 2;
          goto 20;
        end;
        5:{104:}
        begin
          if (T = 3) or ({105:}
          ((T = 2) and (V = 3) and (((OUTCONTRIB[1] = 68) and (OUTCONTRIB[2] = 73) and (OUTCONTRIB[3] = 86)) or
          ((OUTCONTRIB[1] = 77) and (OUTCONTRIB[2] = 79) and (OUTCONTRIB[3] = 68)))) or
          ((T = 0) and ((V = 42) or (V = 47))){:105}) then
          begin{103:}
            if (OUTVAL < 0) or ((OUTVAL = 0) and (LASTSIGN < 0)) then
            begin
              OUTBUF[OUTPTR] := 45;
              OUTPTR := OUTPTR + 1;
            end
            else if OUTSIGN > 0 then
            begin
              OUTBUF[OUTPTR] := OUTSIGN;
              OUTPTR := OUTPTR + 1;
            end;
            APPVAL(ABS(OUTVAL));
            if OUTPTR > LINELENGTH then
              FLUSHBUFFER;
            {:103};
            OUTSIGN := 43;
            OUTVAL := OUTAPP;
          end
          else
            OUTVAL := OUTVAL + OUTAPP;
          OUTSTATE := 3;
          goto 20;
        end{:104};
        0: if T <> 3 then
            BREAKPTR := OUTPTR;
        OTHERS:
      end{:102};
    if T <> 0 then
      for K := 1 to V do
      begin
        OUTBUF[OUTPTR] := OUTCONTRIB[K];
        OUTPTR := OUTPTR + 1;
      end
    else
    begin
      OUTBUF[OUTPTR] := V;
      OUTPTR := OUTPTR + 1;
    end;
    if OUTPTR > LINELENGTH then
      FLUSHBUFFER;
    if (T = 0) and ((V = 59) or (V = 125)) then
    begin
      SEMIPTR := OUTPTR;
      BREAKPTR := OUTPTR;
    end;
    if T >= 2 then
      OUTSTATE := 1
    else
      OUTSTATE := 0;
  end;{:101}{106:}

  procedure SENDSIGN(V: integer);
  begin
    case OUTSTATE of
      2, 4: OUTAPP := OUTAPP * V;
      3:
      begin
        OUTAPP := V;
        OUTSTATE := 4;
      end;
      5:
      begin
        OUTVAL := OUTVAL + OUTAPP;
        OUTAPP := V;
        OUTSTATE := 4;
      end;
      OTHERS:
      begin
        BREAKPTR := OUTPTR;
        OUTAPP := V;
        OUTSTATE := 2;
      end
    end;
    LASTSIGN := OUTAPP;
  end;{:106}{107:}

  procedure SENDVAL(V: integer);
  label
    666, 10;
  begin
    case OUTSTATE of
      1:
      begin{110:}
        if (OUTPTR = BREAKPTR + 3) or ((OUTPTR = BREAKPTR + 4) and (OUTBUF[BREAKPTR] = 32)) then
          if ((OUTBUF[OUTPTR - 3] = 68) and (OUTBUF[OUTPTR - 2] = 73) and (OUTBUF[OUTPTR - 1] = 86)) or
            ((OUTBUF[OUTPTR - 3] = 77) and (OUTBUF[OUTPTR - 2] = 79) and (OUTBUF[OUTPTR - 1] = 68)) then
            goto 666{:110};
        OUTSIGN := 32;
        OUTSTATE := 3;
        OUTVAL := V;
        BREAKPTR := OUTPTR;
        LASTSIGN := +1;
      end;
      0:
      begin{109:}
        if (OUTPTR = BREAKPTR + 1) and ((OUTBUF[BREAKPTR] = 42) or (OUTBUF[BREAKPTR] = 47)) then
          goto 666{:109};
        OUTSIGN := 0;
        OUTSTATE := 3;
        OUTVAL := V;
        BREAKPTR := OUTPTR;
        LASTSIGN := +1;
      end;
      {108:}2:
      begin
        OUTSIGN := 43;
        OUTSTATE := 3;
        OUTVAL := OUTAPP * V;
      end;
      3:
      begin
        OUTSTATE := 5;
        OUTAPP := V;
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Two numbers occurred without a sign between them');
          ERROR;
        end;
      end;
      4:
      begin
        OUTSTATE := 5;
        OUTAPP := OUTAPP * V;
      end;
      5:
      begin
        OUTVAL := OUTVAL + OUTAPP;
        OUTAPP := V;
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Two numbers occurred without a sign between them');
          ERROR;
        end;
      end;
      {:108}OTHERS: goto 666
    end;
    goto 10;
    666:{111:}
      if V >= 0 then
      begin
        if OUTSTATE = 1 then
        begin
          BREAKPTR := OUTPTR;
          begin
            OUTBUF[OUTPTR] := 32;
            OUTPTR := OUTPTR + 1;
          end;
        end;
        APPVAL(V);
        if OUTPTR > LINELENGTH then
          FLUSHBUFFER;
        OUTSTATE := 1;
      end
      else
      begin
        begin
          OUTBUF[OUTPTR] := 40;
          OUTPTR := OUTPTR + 1;
        end;
        begin
          OUTBUF[OUTPTR] := 45;
          OUTPTR := OUTPTR + 1;
        end;
        APPVAL(-V);
        begin
          OUTBUF[OUTPTR] := 41;
          OUTPTR := OUTPTR + 1;
        end;
        if OUTPTR > LINELENGTH then
          FLUSHBUFFER;
        OUTSTATE := 0;
      end{:111};
    10: ;
  end;

  {:107}{113:}
  procedure SENDTHEOUTPU;
  label
    2, 21, 22;
  var
    CURCHAR: EIGHTBITS;
    K: 0..LINELENGTH;
    J: 0..MAXBYTES;
    W: 0..1;
    N: integer;
  begin
    while STACKPTR > 0 do
    begin
      CURCHAR := GETOUTPUT;
      21:
        case CURCHAR of
          0: ;{116:}
          65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88,
          89, 90:
          begin
            OUTCONTRIB[1] := CURCHAR;
            SENDOUT(2, 1);
          end;
          97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122:
          begin
            OUTCONTRIB[1] := CURCHAR - 32;
            SENDOUT(2, 1);
          end;
          130:
          begin
            K := 0;
            J := BYTESTART[CURVAL];
            W := CURVAL mod 2;
            while (K < MAXIDLENGTH) and (J < BYTESTART[CURVAL + 2]) do
            begin
              K := K + 1;
              OUTCONTRIB[K] := BYTEMEM[W, J];
              J := J + 1;
              if OUTCONTRIB[K] >= 97 then
                OUTCONTRIB[K] := OUTCONTRIB[K] - 32
              else if OUTCONTRIB[K] = 95 then
                K := K - 1;
            end;
            SENDOUT(2, K);
          end;{:116}{119:}
          48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
          begin
            N := 0;
            repeat
              CURCHAR := CURCHAR - 48;
              if N >= 214748364 then
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Constant too big');
                ERROR;
              end
              else
                N := 10 * N + CURCHAR;
              CURCHAR := GETOUTPUT;
            until (CURCHAR > 57) or (CURCHAR < 48);
            SENDVAL(N);
            K := 0;
            if CURCHAR = 101 then
              CURCHAR := 69;
            if CURCHAR = 69 then
              goto 2
            else
              goto 21;
          end;
          125: SENDVAL(POOLCHECKSUM);
          12:
          begin
            N := 0;
            CURCHAR := 48;
            repeat
              CURCHAR := CURCHAR - 48;
              if N >= 268435456 then
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Constant too big');
                ERROR;
              end
              else
                N := 8 * N + CURCHAR;
              CURCHAR := GETOUTPUT;
            until (CURCHAR > 55) or (CURCHAR < 48);
            SENDVAL(N);
            goto 21;
          end;
          13:
          begin
            N := 0;
            CURCHAR := 48;
            repeat
              if CURCHAR >= 65 then
                CURCHAR := CURCHAR - 55
              else
                CURCHAR := CURCHAR - 48;
              if N >= 134217728 then
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Constant too big');
                ERROR;
              end
              else
                N := 16 * N + CURCHAR;
              CURCHAR := GETOUTPUT;
            until (CURCHAR > 70) or (CURCHAR < 48) or ((CURCHAR > 57) and (CURCHAR < 65));
            SENDVAL(N);
            goto 21;
          end;
          128: SENDVAL(CURVAL);
          46:
          begin
            K := 1;
            OUTCONTRIB[1] := 46;
            CURCHAR := GETOUTPUT;
            if CURCHAR = 46 then
            begin
              OUTCONTRIB[2] := 46;
              SENDOUT(1, 2);
            end
            else if (CURCHAR >= 48) and (CURCHAR <= 57) then
              goto 2
            else
            begin
              SENDOUT(0, 46);
              goto 21;
            end;
          end;
          {:119}43, 45: SENDSIGN(44 - CURCHAR);{114:}
          4:
          begin
            OUTCONTRIB[1] := 65;
            OUTCONTRIB[2] := 78;
            OUTCONTRIB[3] := 68;
            SENDOUT(2, 3);
          end;
          5:
          begin
            OUTCONTRIB[1] := 78;
            OUTCONTRIB[2] := 79;
            OUTCONTRIB[3] := 84;
            SENDOUT(2, 3);
          end;
          6:
          begin
            OUTCONTRIB[1] := 73;
            OUTCONTRIB[2] := 78;
            SENDOUT(2, 2);
          end;
          31:
          begin
            OUTCONTRIB[1] := 79;
            OUTCONTRIB[2] := 82;
            SENDOUT(2, 2);
          end;
          24:
          begin
            OUTCONTRIB[1] := 58;
            OUTCONTRIB[2] := 61;
            SENDOUT(1, 2);
          end;
          26:
          begin
            OUTCONTRIB[1] := 60;
            OUTCONTRIB[2] := 62;
            SENDOUT(1, 2);
          end;
          28:
          begin
            OUTCONTRIB[1] := 60;
            OUTCONTRIB[2] := 61;
            SENDOUT(1, 2);
          end;
          29:
          begin
            OUTCONTRIB[1] := 62;
            OUTCONTRIB[2] := 61;
            SENDOUT(1, 2);
          end;
          30:
          begin
            OUTCONTRIB[1] := 61;
            OUTCONTRIB[2] := 61;
            SENDOUT(1, 2);
          end;
          32:
          begin
            OUTCONTRIB[1] := 46;
            OUTCONTRIB[2] := 46;
            SENDOUT(1, 2);
          end;
          {:114}39:{117:}
          begin
            K := 1;
            OUTCONTRIB[1] := 39;
            repeat
              if K < LINELENGTH then
                K := K + 1;
              OUTCONTRIB[K] := GETOUTPUT;
            until (OUTCONTRIB[K] = 39) or (STACKPTR = 0);
            if K = LINELENGTH then
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! String too long');
              ERROR;
            end;
            SENDOUT(1, K);
            CURCHAR := GETOUTPUT;
            if CURCHAR = 39 then
              OUTSTATE := 6;
            goto 21;
          end{:117};
          {115:}
          33, 34, 35, 36, 37, 38, 40, 41, 42, 44, 47, 58, 59, 60, 61, 62, 63, 64, 91, 92, 93, 94, 95, 96,
          123, 124{:115}: SENDOUT(0, CURCHAR);{121:}
          9:
          begin
            if BRACELEVEL = 0 then
              SENDOUT(0, 123)
            else
              SENDOUT(0, 91);
            BRACELEVEL := BRACELEVEL + 1;
          end;
          10: if BRACELEVEL > 0 then
            begin
              BRACELEVEL := BRACELEVEL - 1;
              if BRACELEVEL = 0 then
                SENDOUT(0, 125)
              else
                SENDOUT(0, 93);
            end
            else
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Extra @}');
              ERROR;
            end;
          129:
          begin
            if BRACELEVEL = 0 then
              SENDOUT(0, 123)
            else
              SENDOUT(0, 91);
            if CURVAL < 0 then
            begin
              SENDOUT(0, 58);
              SENDVAL(-CURVAL);
            end
            else
            begin
              SENDVAL(CURVAL);
              SENDOUT(0, 58);
            end;
            if BRACELEVEL = 0 then
              SENDOUT(0, 125)
            else
              SENDOUT(0, 93);
          end;{:121}
          127:
          begin
            SENDOUT(3, 0);
            OUTSTATE := 6;
          end;
          2:{118:}
          begin
            K := 0;
            repeat
              if K < LINELENGTH then
                K := K + 1;
              OUTCONTRIB[K] := GETOUTPUT;
            until (OUTCONTRIB[K] = 2) or (STACKPTR = 0);
            if K = LINELENGTH then
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Verbatim string too long');
              ERROR;
            end;
            SENDOUT(1, K - 1);
          end{:118};
          3:{122:}
          begin
            SENDOUT(1, 0);
            while OUTPTR > 0 do
            begin
              if OUTPTR <= LINELENGTH then
                BREAKPTR := OUTPTR;
              FLUSHBUFFER;
            end;
            OUTSTATE := 0;
          end{:122};
          OTHERS:
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Can''t output ASCII code ', CURCHAR: 1);
            ERROR;
          end
        end;
      goto 22;
      2:
          {120:}repeat
          if K < LINELENGTH then
            K := K + 1;
          OUTCONTRIB[K] := CURCHAR;
          CURCHAR := GETOUTPUT;
          if (OUTCONTRIB[K] = 69) and ((CURCHAR = 43) or (CURCHAR = 45)) then
          begin
            if K < LINELENGTH then
              K := K + 1;
            OUTCONTRIB[K] := CURCHAR;
            CURCHAR := GETOUTPUT;
          end
          else if CURCHAR = 101 then
            CURCHAR := 69;
        until (CURCHAR <> 69) and ((CURCHAR < 48) or (CURCHAR > 57));
      if K = LINELENGTH then
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Fraction too long');
        ERROR;
      end;
      SENDOUT(3, K);
      goto 21{:120};
      22: ;
    end;
  end;{:113}{127:}

  function LINESDONTMAT: boolean;
  label
    10;
  var
    K: 0..BUFSIZE;
  begin
    LINESDONTMAT := True;
    if CHANGELIMIT <> LIMIT then
      goto 10;
    if LIMIT > 0 then
      for K := 0 to LIMIT - 1 do
        if CHANGEBUFFER[K] <> BUFFER[K] then
          goto 10;
    LINESDONTMAT := False;
    10: ;
  end;{:127}{128:}

  procedure PRIMETHECHAN;
  label
    22, 30, 10;
  var
    K: 0..BUFSIZE;
  begin
    CHANGELIMIT := 0;{129:}
    while True do
    begin
      LINE := LINE + 1;
      if not INPUTLN(CHANGEFILE) then
        goto 10;
      if LIMIT < 2 then
        goto 22;
      if BUFFER[0] <> 64 then
        goto 22;
      if (BUFFER[1] >= 88) and (BUFFER[1] <= 90) then
        BUFFER[1] := BUFFER[1] + 32;
      if BUFFER[1] = 120 then
        goto 30;
      if (BUFFER[1] = 121) or (BUFFER[1] = 122) then
      begin
        LOC := 2;
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Where is the matching @x?');
          ERROR;
        end;
      end;
      22: ;
    end;
    30:
    {:129};
    {130:}repeat
      LINE := LINE + 1;
      if not INPUTLN(CHANGEFILE) then
      begin
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Change file ended after @x');
          ERROR;
        end;
        goto 10;
      end;
    until LIMIT > 0;
    {:130};{131:}
    begin
      CHANGELIMIT := LIMIT;
      if LIMIT > 0 then
        for K := 0 to LIMIT - 1 do
          CHANGEBUFFER[K] := BUFFER[K];
    end{:131};
    10: ;
  end;{:128}{132:}

  procedure CHECKCHANGE;
  label
    10;
  var
    N: integer;
    K: 0..BUFSIZE;
  begin
    if LINESDONTMAT then
      goto 10;
    N := 0;
    while True do
    begin
      CHANGING := not CHANGING;
      TEMPLINE := OTHERLINE;
      OTHERLINE := LINE;
      LINE := TEMPLINE;
      LINE := LINE + 1;
      if not INPUTLN(CHANGEFILE) then
      begin
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Change file ended before @y');
          ERROR;
        end;
        CHANGELIMIT := 0;
        CHANGING := not CHANGING;
        TEMPLINE := OTHERLINE;
        OTHERLINE := LINE;
        LINE := TEMPLINE;
        goto 10;
      end;{133:}
      if LIMIT > 1 then
        if BUFFER[0] = 64 then
        begin
          if (BUFFER[1] >= 88) and (BUFFER[1] <= 90) then
            BUFFER[1] := BUFFER[1] + 32;
          if (BUFFER[1] = 120) or (BUFFER[1] = 122) then
          begin
            LOC := 2;
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Where is the matching @y?');
              ERROR;
            end;
          end
          else if BUFFER[1] = 121 then
          begin
            if N > 0 then
            begin
              LOC := 2;
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Hmm... ', N: 1, ' of the preceding lines failed to match');
                ERROR;
              end;
            end;
            goto 10;
          end;
        end{:133};{131:}
      begin
        CHANGELIMIT := LIMIT;
        if LIMIT > 0 then
          for K := 0 to LIMIT - 1 do
            CHANGEBUFFER[K] := BUFFER[K];
      end{:131};
      CHANGING := not CHANGING;
      TEMPLINE := OTHERLINE;
      OTHERLINE := LINE;
      LINE := TEMPLINE;
      LINE := LINE + 1;
      if not INPUTLN(WEBFILE) then
      begin
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! WEB file ended during a change');
          ERROR;
        end;
        INPUTHASENDE := True;
        goto 10;
      end;
      if LINESDONTMAT then
        N := N + 1;
    end;
    10: ;
  end;

  {:132}{135:}
  procedure GETLINE;
  label
    20;
  begin
    20:
      if CHANGING then{137:}
      begin
        LINE := LINE + 1;
        if not INPUTLN(CHANGEFILE) then
        begin
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Change file ended without @z');
            ERROR;
          end;
          BUFFER[0] := 64;
          BUFFER[1] := 122;
          LIMIT := 2;
        end;
        if LIMIT > 1 then
          if BUFFER[0] = 64 then
          begin
            if (BUFFER[1] >= 88) and (BUFFER[1] <= 90) then
              BUFFER[1] := BUFFER[1] + 32;
            if (BUFFER[1] = 120) or (BUFFER[1] = 121) then
            begin
              LOC := 2;
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Where is the matching @z?');
                ERROR;
              end;
            end
            else if BUFFER[1] = 122 then
            begin
              PRIMETHECHAN;
              CHANGING := not CHANGING;
              TEMPLINE := OTHERLINE;
              OTHERLINE := LINE;
              LINE := TEMPLINE;
            end;
          end;
      end{:137};
    if not CHANGING then
    begin{136:}
      begin
        LINE := LINE + 1;
        if not INPUTLN(WEBFILE) then
          INPUTHASENDE := True
        else if LIMIT = CHANGELIMIT then
          if BUFFER[0] = CHANGEBUFFER[0] then
            if CHANGELIMIT > 0 then
              CHECKCHANGE;
      end{:136};
      if CHANGING then
        goto 20;
    end;
    LOC := 0;
    BUFFER[LIMIT] := 32;
  end;

  {:135}{139:}
  function CONTROLCODE(C: ASCIICODE): EIGHTBITS;
  begin
    case C of
      64: CONTROLCODE := 64;
      39: CONTROLCODE := 12;
      34: CONTROLCODE := 13;
      36: CONTROLCODE := 125;
      32, 9: CONTROLCODE := 136;
      42:
      begin
        Write(TERMOUT, '*', MODULECOUNT + 1: 1);
        BREAK(TERMOUT);
        CONTROLCODE := 136;
      end;
      68, 100: CONTROLCODE := 133;
      70, 102: CONTROLCODE := 132;
      123: CONTROLCODE := 9;
      125: CONTROLCODE := 10;
      80, 112: CONTROLCODE := 134;
      84, 116, 94, 46, 58: CONTROLCODE := 131;
      38: CONTROLCODE := 127;
      60: CONTROLCODE := 135;
      61: CONTROLCODE := 2;
      92: CONTROLCODE := 3;
      OTHERS: CONTROLCODE := 0
    end;
  end;{:139}{140:}

  function SKIPAHEAD: EIGHTBITS;
  label
    30;
  var
    C: EIGHTBITS;
  begin
    while True do
    begin
      if LOC > LIMIT then
      begin
        GETLINE;
        if INPUTHASENDE then
        begin
          C := 136;
          goto 30;
        end;
      end;
      BUFFER[LIMIT + 1] := 64;
      while BUFFER[LOC] <> 64 do
        LOC := LOC + 1;
      if LOC <= LIMIT then
      begin
        LOC := LOC + 2;
        C := CONTROLCODE(BUFFER[LOC - 1]);
        if (C <> 0) or (BUFFER[LOC - 1] = 62) then
          goto 30;
      end;
    end;
    30:
      SKIPAHEAD := C;
  end;{:140}{141:}

  procedure SKIPCOMMENT;
  label
    10;
  var
    BAL: EIGHTBITS;
    C: ASCIICODE;
  begin
    BAL := 0;
    while True do
    begin
      if LOC > LIMIT then
      begin
        GETLINE;
        if INPUTHASENDE then
        begin
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Input ended in mid-comment');
            ERROR;
          end;
          goto 10;
        end;
      end;
      C := BUFFER[LOC];
      LOC := LOC + 1;
      {142:}if C = 64 then
      begin
        C := BUFFER[LOC];
        if (C <> 32) and (C <> 9) and (C <> 42) and (C <> 122) and (C <> 90) then
          LOC := LOC + 1
        else
        begin
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Section ended in mid-comment');
            ERROR;
          end;
          LOC := LOC - 1;
          goto 10;
        end;
      end
      else if (C = 92) and (BUFFER[LOC] <> 64) then
        LOC := LOC + 1
      else if C = 123 then
        BAL := BAL + 1
      else if C = 125 then
      begin
        if BAL = 0 then
          goto 10;
        BAL := BAL - 1;
      end{:142};
    end;
    10: ;
  end;{:141}{145:}

  function GETNEXT: EIGHTBITS;
  label
    20, 30, 31;
  var
    C: EIGHTBITS;
    D: EIGHTBITS;
    J, K: 0..LONGESTNAME;
  begin
    20:
      if LOC > LIMIT then
      begin
        GETLINE;
        if INPUTHASENDE then
        begin
          C := 136;
          goto 31;
        end;
      end;
    C := BUFFER[LOC];
    LOC := LOC + 1;
    if SCANNINGHEX then{146:}
      if ((C >= 48) and (C <= 57)) or ((C >= 65) and (C <= 70)) then
        goto 31
      else
        SCANNINGHEX := False{:146};
    case C of
      65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122:{148:}
      begin
        if ((C = 101) or (C = 69)) and (LOC > 1) then
          if (BUFFER[LOC - 2] <= 57) and (BUFFER[LOC - 2] >= 48) then
            C := 0;
        if C <> 0 then
        begin
          LOC := LOC - 1;
          IDFIRST := LOC;
          repeat
            LOC := LOC + 1;
            D := BUFFER[LOC];
          until ((D < 48) or ((D > 57) and (D < 65)) or ((D > 90) and (D < 97)) or (D > 122)) and (D <> 95);
          if LOC > IDFIRST + 1 then
          begin
            C := 130;
            IDLOC := LOC;
          end;
        end
        else
          C := 69;
      end{:148};
      34:{149:}
      begin
        DOUBLECHARS := 0;
        IDFIRST := LOC - 1;
        repeat
          D := BUFFER[LOC];
          LOC := LOC + 1;
          if (D = 34) or (D = 64) then
            if BUFFER[LOC] = D then
            begin
              LOC := LOC + 1;
              D := 0;
              DOUBLECHARS := DOUBLECHARS + 1;
            end
            else
            begin
              if D = 64 then
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Double @ sign missing');
                ERROR;
              end;
            end
          else if LOC > LIMIT then
          begin
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! String constant didn''t end');
              ERROR;
            end;
            D := 34;
          end;
        until D = 34;
        IDLOC := LOC - 1;
        C := 130;
      end{:149};
      64:{150:}
      begin
        C := CONTROLCODE(BUFFER[LOC]);
        LOC := LOC + 1;
        if C = 0 then
          goto 20
        else if C = 13 then
          SCANNINGHEX := True
        else if C = 135 then{151:}
        begin
          {153:}K := 0;
          while True do
          begin
            if LOC > LIMIT then
            begin
              GETLINE;
              if INPUTHASENDE then
              begin
                begin
                  WRITELN(TERMOUT);
                  Write(TERMOUT, '! Input ended in section name');
                  ERROR;
                end;
                goto 30;
              end;
            end;
            D := BUFFER[LOC];
            {154:}if D = 64 then
            begin
              D := BUFFER[LOC + 1];
              if D = 62 then
              begin
                LOC := LOC + 2;
                goto 30;
              end;
              if (D = 32) or (D = 9) or (D = 42) then
              begin
                begin
                  WRITELN(TERMOUT);
                  Write(TERMOUT, '! Section name didn''t end');
                  ERROR;
                end;
                goto 30;
              end;
              K := K + 1;
              MODTEXT[K] := 64;
              LOC := LOC + 1;
            end{:154};
            LOC := LOC + 1;
            if K < LONGESTNAME - 1 then
              K := K + 1;
            if (D = 32) or (D = 9) then
            begin
              D := 32;
              if MODTEXT[K - 1] = 32 then
                K := K - 1;
            end;
            MODTEXT[K] := D;
          end;
          30:{155:}
            if K >= LONGESTNAME - 2 then
            begin
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Section name too long: ');
              end;
              for J := 1 to 25 do
                Write(TERMOUT, XCHR[MODTEXT[J]]);
              Write(TERMOUT, '...');
              if HISTORY = 0 then
                HISTORY := 1;
            end{:155};
          if (MODTEXT[K] = 32) and (K > 0) then
            K := K - 1;
          {:153};
          if K > 3 then
          begin
            if (MODTEXT[K] = 46) and (MODTEXT[K - 1] = 46) and (MODTEXT[K - 2] = 46) then
              CURMODULE := PREFIXLOOKUP(K - 3)
            else
              CURMODULE := MODLOOKUP(K);
          end
          else
            CURMODULE := MODLOOKUP(K);
        end{:151}
        else if C = 131 then
        begin
          repeat
            C := SKIPAHEAD;
          until C <> 64;
          if BUFFER[LOC - 1] <> 62 then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Improper @ within control text');
            ERROR;
          end;
          goto 20;
        end;
      end{:150};{147:}
      46: if BUFFER[LOC] = 46 then
        begin
          if LOC <= LIMIT then
          begin
            C := 32;
            LOC := LOC + 1;
          end;
        end
        else if BUFFER[LOC] = 41 then
        begin
          if LOC <= LIMIT then
          begin
            C := 93;
            LOC := LOC + 1;
          end;
        end;
      58: if BUFFER[LOC] = 61 then
        begin
          if LOC <= LIMIT then
          begin
            C := 24;
            LOC := LOC + 1;
          end;
        end;
      61: if BUFFER[LOC] = 61 then
        begin
          if LOC <= LIMIT then
          begin
            C := 30;
            LOC := LOC + 1;
          end;
        end;
      62: if BUFFER[LOC] = 61 then
        begin
          if LOC <= LIMIT then
          begin
            C := 29;
            LOC := LOC + 1;
          end;
        end;
      60: if BUFFER[LOC] = 61 then
        begin
          if LOC <= LIMIT then
          begin
            C := 28;
            LOC := LOC + 1;
          end;
        end
        else if BUFFER[LOC] = 62 then
        begin
          if LOC <= LIMIT then
          begin
            C := 26;
            LOC := LOC + 1;
          end;
        end;
      40: if BUFFER[LOC] = 42 then
        begin
          if LOC <= LIMIT then
          begin
            C := 9;
            LOC := LOC + 1;
          end;
        end
        else if BUFFER[LOC] = 46 then
        begin
          if LOC <= LIMIT then
          begin
            C := 91;
            LOC := LOC + 1;
          end;
        end;
      42: if BUFFER[LOC] = 41 then
        begin
          if LOC <= LIMIT then
          begin
            C := 10;
            LOC := LOC + 1;
          end;
        end;
      {:147}32, 9: goto 20;
      123:
      begin
        SKIPCOMMENT;
        goto 20;
      end;
      OTHERS:
    end;
    31:
      if TROUBLESHOOT then
        DEBUGHELP;
    GETNEXT := C;
  end;{:145}{157:}

  procedure SCANNUMERIC(P: NAMEPOINTER);
  label
    21, 30;
  var
    ACCUMULATOR: integer;
    NEXTSIGN: -1.. +1;
    Q: NAMEPOINTER;
    VAL: integer;
  begin
    {158:}ACCUMULATOR := 0;
    NEXTSIGN := +1;
    while True do
    begin
      NEXTCONTROL := GETNEXT;
      21:
        case NEXTCONTROL of
          48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
          begin
            {160:}VAL := 0;
            repeat
              VAL := 10 * VAL + NEXTCONTROL - 48;
              NEXTCONTROL := GETNEXT;
            until (NEXTCONTROL > 57) or (NEXTCONTROL < 48){:160};
            begin
              ACCUMULATOR := ACCUMULATOR + NEXTSIGN * (VAL);
              NEXTSIGN := +1;
            end;
            goto 21;
          end;
          12:
          begin
            {161:}VAL := 0;
            NEXTCONTROL := 48;
            repeat
              VAL := 8 * VAL + NEXTCONTROL - 48;
              NEXTCONTROL := GETNEXT;
            until (NEXTCONTROL > 55) or (NEXTCONTROL < 48){:161};
            begin
              ACCUMULATOR := ACCUMULATOR + NEXTSIGN * (VAL);
              NEXTSIGN := +1;
            end;
            goto 21;
          end;
          13:
          begin
            {162:}VAL := 0;
            NEXTCONTROL := 48;
            repeat
              if NEXTCONTROL >= 65 then
                NEXTCONTROL := NEXTCONTROL - 7;
              VAL := 16 * VAL + NEXTCONTROL - 48;
              NEXTCONTROL := GETNEXT;
            until (NEXTCONTROL > 70) or (NEXTCONTROL < 48) or ((NEXTCONTROL > 57) and (NEXTCONTROL < 65)){:162};
            begin
              ACCUMULATOR := ACCUMULATOR + NEXTSIGN * (VAL);
              NEXTSIGN := +1;
            end;
            goto 21;
          end;
          130:
          begin
            Q := IDLOOKUP(0);
            if ILK[Q] <> 1 then
            begin
              NEXTCONTROL := 42;
              goto 21;
            end;
            begin
              ACCUMULATOR := ACCUMULATOR + NEXTSIGN * (EQUIV[Q] - 32768);
              NEXTSIGN := +1;
            end;
          end;
          43: ;
          45: NEXTSIGN := -NEXTSIGN;
          132, 133, 135, 134, 136: goto 30;
          59:
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Omit semicolon in numeric definition');
            ERROR;
          end;
          OTHERS:{159:}
          begin
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Improper numeric definition will be flushed');
              ERROR;
            end;
            repeat
              NEXTCONTROL := SKIPAHEAD
            until (NEXTCONTROL >= 132);
            if NEXTCONTROL = 135 then
            begin
              LOC := LOC - 2;
              NEXTCONTROL := GETNEXT;
            end;
            ACCUMULATOR := 0;
            goto 30;
          end{:159}
        end;
    end;
    30:
    {:158};
    if ABS(ACCUMULATOR) >= 32768 then
    begin
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Value too big: ', ACCUMULATOR: 1);
        ERROR;
      end;
      ACCUMULATOR := 0;
    end;
    EQUIV[P] := ACCUMULATOR + 32768;
  end;{:157}{165:}

  procedure SCANREPL(T: EIGHTBITS);
  label
    22, 30, 31;
  var
    A: SIXTEENBITS;
    B: ASCIICODE;
    BAL: EIGHTBITS;
  begin
    BAL := 0;
    while True do
    begin
      22:
        A := GETNEXT;
      case A of
        40: BAL := BAL + 1;
        41: if BAL = 0 then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Extra )');
            ERROR;
          end
          else
            BAL := BAL - 1;
        39:{168:}
        begin
          B := 39;
          while True do
          begin
            begin
              if TOKPTR[Z] = MAXTOKS then
              begin
                WRITELN(
                  TERMOUT);
                Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                ERROR;
                HISTORY := 3;
                JUMPOUT;
              end;
              TOKMEM[Z, TOKPTR[Z]] := B;
              TOKPTR[Z] := TOKPTR[Z] + 1;
            end;
            if B = 64 then
              if BUFFER[LOC] = 64 then
                LOC := LOC + 1
              else
              begin
                WRITELN(
                  TERMOUT);
                Write(TERMOUT, '! You should double @ signs in strings');
                ERROR;
              end;
            if LOC = LIMIT then
            begin
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! String didn''t end');
                ERROR;
              end;
              BUFFER[LOC] := 39;
              BUFFER[LOC + 1] := 0;
            end;
            B := BUFFER[LOC];
            LOC := LOC + 1;
            if B = 39 then
            begin
              if BUFFER[LOC] <> 39 then
                goto 31
              else
              begin
                LOC := LOC + 1;
                begin
                  if TOKPTR[Z] = MAXTOKS then
                  begin
                    WRITELN(TERMOUT);
                    Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                    ERROR;
                    HISTORY := 3;
                    JUMPOUT;
                  end;
                  TOKMEM[Z, TOKPTR[Z]] := 39;
                  TOKPTR[Z] := TOKPTR[Z] + 1;
                end;
              end;
            end;
          end;
          31: ;
        end{:168};
        35: if T = 3 then
            A := 0;{167:}
        130:
        begin
          A := IDLOOKUP(0);
          begin
            if TOKPTR[Z] = MAXTOKS then
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
              ERROR;
              HISTORY := 3;
              JUMPOUT;
            end;
            TOKMEM[Z, TOKPTR[Z]] := (A div 256) + 128;
            TOKPTR[Z] := TOKPTR[Z] + 1;
          end;
          A := A mod 256;
        end;
        135: if T <> 135 then
            goto 30
          else
          begin
            begin
              if TOKPTR[Z] = MAXTOKS then
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                ERROR;
                HISTORY := 3;
                JUMPOUT;
              end;
              TOKMEM[Z, TOKPTR[Z]] := (CURMODULE div 256) + 168;
              TOKPTR[Z] := TOKPTR[Z] + 1;
            end;
            A := CURMODULE mod 256;
          end;
        2:{169:}
        begin
          begin
            if TOKPTR[Z] = MAXTOKS then
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
              ERROR;
              HISTORY := 3;
              JUMPOUT;
            end;
            TOKMEM[Z, TOKPTR[Z]] := 2;
            TOKPTR[Z] := TOKPTR[Z] + 1;
          end;
          BUFFER[LIMIT + 1] := 64;
          while BUFFER[LOC] <> 64 do
          begin
            begin
              if TOKPTR[Z] = MAXTOKS then
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                ERROR;
                HISTORY := 3;
                JUMPOUT;
              end;
              TOKMEM[Z, TOKPTR[Z]] := BUFFER[LOC];
              TOKPTR[Z] := TOKPTR[Z] + 1;
            end;
            LOC := LOC + 1;
            if LOC < LIMIT then
              if (BUFFER[LOC] = 64) and (BUFFER[LOC + 1] = 64) then
              begin
                begin
                  if TOKPTR[Z] = MAXTOKS then
                  begin
                    WRITELN(TERMOUT);
                    Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
                    ERROR;
                    HISTORY := 3;
                    JUMPOUT;
                  end;
                  TOKMEM[Z, TOKPTR[Z]] := 64;
                  TOKPTR[Z] := TOKPTR[Z] + 1;
                end;
                LOC := LOC + 2;
              end;
          end;
          if LOC >= LIMIT then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Verbatim string didn''t end');
            ERROR;
          end
          else if BUFFER[LOC + 1] <> 62 then
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! You should double @ signs in verbatim strings');
            ERROR;
          end;
          LOC := LOC + 2;
        end{:169};
        133, 132, 134: if T <> 135 then
            goto 30
          else
          begin
            begin
              WRITELN(TERMOUT);
              Write(TERMOUT, '! @', XCHR[BUFFER[LOC - 1]], ' is ignored in Pascal text');
              ERROR;
            end;
            goto 22;
          end;
        136: goto 30;
        {:167}OTHERS:
      end;
      begin
        if TOKPTR[Z] = MAXTOKS then
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
          ERROR;
          HISTORY := 3;
          JUMPOUT;
        end;
        TOKMEM[Z, TOKPTR[Z]] := A;
        TOKPTR[Z] := TOKPTR[Z] + 1;
      end;
    end;
    30:
      NEXTCONTROL := A;{166:}
    if BAL > 0 then
    begin
      if BAL = 1 then
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Missing )');
        ERROR;
      end
      else
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Missing ', BAL: 1, ' )''s');
        ERROR;
      end;
      while BAL > 0 do
      begin
        begin
          if TOKPTR[Z] = MAXTOKS then
          begin
            WRITELN(
              TERMOUT);
            Write(TERMOUT, '! Sorry, ', 'token', ' capacity exceeded');
            ERROR;
            HISTORY := 3;
            JUMPOUT;
          end;
          TOKMEM[Z, TOKPTR[Z]] := 41;
          TOKPTR[Z] := TOKPTR[Z] + 1;
        end;
        BAL := BAL - 1;
      end;
    end{:166};
    if TEXTPTR > MAXTEXTS - 3 then
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Sorry, ', 'text', ' capacity exceeded');
      ERROR;
      HISTORY := 3;
      JUMPOUT;
    end;
    CURREPLTEXT := TEXTPTR;
    TOKSTART[TEXTPTR + 3] := TOKPTR[Z];
    TEXTPTR := TEXTPTR + 1;
    if Z = 2 then
      Z := 0
    else
      Z := Z + 1;
  end;{:165}{170:}

  procedure DEFINEMACRO(T: EIGHTBITS);
  var
    P: NAMEPOINTER;
  begin
    P := IDLOOKUP(T);
    SCANREPL(T);
    EQUIV[P] := CURREPLTEXT;
    TEXTLINK[CURREPLTEXT] := 0;
  end;{:170}{172:}

  procedure SCANMODULE;
  label
    22, 30, 10;
  var
    P: NAMEPOINTER;
  begin
    MODULECOUNT := MODULECOUNT + 1;{173:}
    NEXTCONTROL := 0;
    while True do
    begin
      22:
        while NEXTCONTROL <= 132 do
        begin
          NEXTCONTROL :=
            SKIPAHEAD;
          if NEXTCONTROL = 135 then
          begin
            LOC := LOC - 2;
            NEXTCONTROL := GETNEXT;
          end;
        end;
      if NEXTCONTROL <> 133 then
        goto 30;
      NEXTCONTROL := GETNEXT;
      if NEXTCONTROL <> 130 then
      begin
        begin
          WRITELN(TERMOUT);
          Write(TERMOUT, '! Definition flushed, must start with ',
            'identifier of length > 1');
          ERROR;
        end;
        goto 22;
      end;
      NEXTCONTROL := GETNEXT;
      if NEXTCONTROL = 61 then
      begin
        SCANNUMERIC(IDLOOKUP(1));
        goto 22;
      end
      else if NEXTCONTROL = 30 then
      begin
        DEFINEMACRO(2);
        goto 22;
      end
      else{174:}if NEXTCONTROL = 40 then
      begin
        NEXTCONTROL := GETNEXT;
        if NEXTCONTROL = 35 then
        begin
          NEXTCONTROL := GETNEXT;
          if NEXTCONTROL = 41 then
          begin
            NEXTCONTROL := GETNEXT;
            if NEXTCONTROL = 61 then
            begin
              begin
                WRITELN(TERMOUT);
                Write(TERMOUT, '! Use == for macros');
                ERROR;
              end;
              NEXTCONTROL := 30;
            end;
            if NEXTCONTROL = 30 then
            begin
              DEFINEMACRO(3);
              goto 22;
            end;
          end;
        end;
      end;
      {:174};
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, '! Definition flushed since it starts badly');
        ERROR;
      end;
    end;
    30:
    {:173};
    {175:}case NEXTCONTROL of
      134: P := 0;
      135:
      begin
        P := CURMODULE;
        {176:}repeat
          NEXTCONTROL := GETNEXT;
        until NEXTCONTROL <> 43;
        if (NEXTCONTROL <> 61) and (NEXTCONTROL <> 30) then
        begin
          begin
            WRITELN(TERMOUT);
            Write(TERMOUT, '! Pascal text flushed, = sign is missing');
            ERROR;
          end;
          repeat
            NEXTCONTROL := SKIPAHEAD;
          until NEXTCONTROL = 136;
          goto 10;
        end{:176};
      end;
      OTHERS: goto 10
    end;
    {177:}STORETWOBYTE(53248 + MODULECOUNT);
    {:177};
    SCANREPL(135);{178:}
    if P = 0 then
    begin
      TEXTLINK[LASTUNNAMED] := CURREPLTEXT;
      LASTUNNAMED := CURREPLTEXT;
    end
    else if EQUIV[P] = 0 then
      EQUIV[P] := CURREPLTEXT
    else
    begin
      P := EQUIV[P];
      while TEXTLINK[P] < MAXTEXTS do
        P := TEXTLINK[P];
      TEXTLINK[P] := CURREPLTEXT;
    end;
    TEXTLINK[CURREPLTEXT] := MAXTEXTS;
    {:178};
    {:175};
    10: ;
  end;{:172}{181:}

  procedure DEBUGHELP;
  label
    888, 10;
  var
    K: integer;
  begin
    DEBUGSKIPPED := DEBUGSKIPPED + 1;
    if DEBUGSKIPPED < DEBUGCYCLE then
      goto 10;
    DEBUGSKIPPED := 0;
    while True do
    begin
      Write(TERMOUT, '#');
      BREAK(TERMOUT);
      Read(TERMIN, DDT);
      if DDT < 0 then
        goto 10
      else if DDT = 0 then
      begin
        goto 888;
        888:
          DDT := 0;
      end
      else
      begin
        Read(TERMIN, DD);
        case DDT of
          1: PRINTID(DD);
          2: PRINTREPL(DD);
          3: for K := 1 to DD do
              Write(TERMOUT, XCHR[BUFFER[K]]);
          4: for K := 1 to DD do
              Write(TERMOUT, XCHR[MODTEXT[K]]);
          5: for K := 1 to OUTPTR do
              Write(TERMOUT, XCHR[OUTBUF[K]]);
          6: for K := 1 to DD do
              Write(TERMOUT, XCHR[OUTCONTRIB[K]]);
          OTHERS: Write(TERMOUT, '?')
        end;
      end;
    end;
    10: ;
  end;
  {:181}{182:}
begin
  Initialize;
  {134:}OPENINPUT;
  LINE := 0;
  OTHERLINE := 0;
  CHANGING := True;
  PRIMETHECHAN;
  CHANGING := not CHANGING;
  TEMPLINE := OTHERLINE;
  OTHERLINE := LINE;
  LINE := TEMPLINE;
  LIMIT := 0;
  LOC := 1;
  BUFFER[0] := 32;
  INPUTHASENDE := False;
  {:134};
  WRITELN(TERMOUT, 'This is TANGLE, Version 2.8');
  {183:}PHASEONE := True;
  MODULECOUNT := 0;
  repeat
    NEXTCONTROL := SKIPAHEAD;
  until NEXTCONTROL = 136;
  while not INPUTHASENDE do
    SCANMODULE;{138:}
  if CHANGELIMIT <> 0 then
  begin
    for LOC := 0 to CHANGELIMIT do
      BUFFER[LOC] :=
        CHANGEBUFFER[LOC];
    LIMIT := CHANGELIMIT;
    CHANGING := True;
    LINE := OTHERLINE;
    LOC := CHANGELIMIT;
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Change file entry did not match');
      ERROR;
    end;
  end{:138};
  PHASEONE := False;
  {:183};
  for ZO := 0 to 2 do
    MAXTOKPTR[ZO] := TOKPTR[ZO];
  {112:}if TEXTLINK[0] = 0 then
  begin
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! No output was specified.');
    end;
    if HISTORY = 0 then
      HISTORY := 1;
  end
  else
  begin
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, 'Writing the output file');
    end;
    BREAK(TERMOUT);{83:}
    STACKPTR := 1;
    BRACELEVEL := 0;
    CURSTATE.NAMEFIELD := 0;
    CURSTATE.REPLFIELD := TEXTLINK[0];
    ZO := CURSTATE.REPLFIELD mod 3;
    CURSTATE.BYTEFIELD := TOKSTART[CURSTATE.REPLFIELD];
    CURSTATE.ENDFIELD := TOKSTART[CURSTATE.REPLFIELD + 3];
    CURSTATE.MODFIELD := 0;
    {:83};
    {96:}OUTSTATE := 0;
    OUTPTR := 0;
    BREAKPTR := 0;
    SEMIPTR := 0;
    OUTBUF[0] := 0;
    LINE := 1;
    {:96};
    SENDTHEOUTPU;
    {98:}BREAKPTR := OUTPTR;
    SEMIPTR := 0;
    FLUSHBUFFER;
    if BRACELEVEL <> 0 then
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '! Program ended at brace level ', BRACELEVEL: 1);
      ERROR;
    end;
    {:98};
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, 'Done.');
    end;
  end{:112};
  9999:
    if STRINGPTR > 128 then{184:}
    begin
      begin
        WRITELN(TERMOUT);
        Write(TERMOUT, STRINGPTR - 128: 1, ' strings written to string pool file.');
      end;
      Write(POOL, '*');
      for STRINGPTR := 1 to 9 do
      begin
        OUTBUF[STRINGPTR] := POOLCHECKSUM mod 10;
        POOLCHECKSUM := POOLCHECKSUM div 10;
      end;
      for STRINGPTR := 9 downto 1 do
        Write(POOL, XCHR[48 + OUTBUF[STRINGPTR]]);
      WRITELN(POOL);
    end{:184};{186:}
  begin
    WRITELN(TERMOUT);
    Write(TERMOUT, 'Memory usage statistics:');
  end;
  begin
    WRITELN(TERMOUT);
    Write(TERMOUT, NAMEPTR: 1, ' names, ', TEXTPTR: 1, ' replacement texts;');
  end;
  begin
    WRITELN(TERMOUT);
    Write(TERMOUT, BYTEPTR[0]: 1);
  end;
  for WO := 1 to 1 do
    Write(TERMOUT, '+', BYTEPTR[WO]: 1);
  Write(TERMOUT, ' bytes, ', MAXTOKPTR[0]: 1);
  for ZO := 1 to 2 do
    Write(TERMOUT, '+', MAXTOKPTR[ZO]: 1);
  Write(TERMOUT, ' tokens.');
  {:186};{187:}
  case HISTORY of
    0:
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '(No errors were found.)');
    end;
    1:
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '(Did you see the warning message above?)');
    end;
    2:
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '(Pardon me, but I think I spotted something wrong.)');
    end;
    3:
    begin
      WRITELN(TERMOUT);
      Write(TERMOUT, '(That was a fatal error, my friend.)');
    end;
  end{:187};
end.{:182}
