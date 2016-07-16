program MS_PacMan;

{ Wedding 2014}


uses Crt, Graph, Advanced, Objects;

{$S-}
const
  Left  = 1;
  Right = 2;
  Up    = 3;
  Down  = 4;

  Blinky = 1;
  Inky   = 2;
  Pinky  = 3;
  Sue    = 4;

  Normal = 0;
  Blind  = 1;
  Dead   = 2;
  Halted = 3;

  mzMaxX = 20;
  mzMaxY = 22;

  Chase: array[1..4,1..2] of Shortint = ((0,0),(0,0),(0,0),(0,0));
  GBonus: array[1..4] of Integer = (200, 400, 800, 1600);

  ActStr: array[1..3] of String[100]=('It all started in 2011 on a canoe trip on the Danube...',
   'Then we were flying across the world to see each other...', 'From now on we will be together...');

type
  ByteSet = Set of Byte;

  PFrames = ^TFrames;
  TFrames = array[1..4, 0..1] of Pointer;

  PBlindFrames = ^TBlindFrames;
  TBlindFrames = array[0..1, 0..1] of Pointer;

  P4Frames = ^T4Frames;
  T4Frames = array[1..4] of Pointer;

  TLevelImages = array[0..18] of Pointer;

  PMazeData = ^TMazeData;
  TMazeData = array[0..mzMaxX, 0..mzMaxY] of Byte;

  PLevel = ^TLevel;
  TLevel = object
    Data: TMazeData;
    No: Byte;
    X, Y, Color: Integer;
    OX, OY, HX, HY, Height: Byte; { origin of pacman, home of ghosts}
    DrawMode: Byte;
    Dots: Integer;
    WallColor, FrameColor: Shortint;
  { for ghosts }
    cblind: Word; { blind counter init }
    cblindb: Word; { where blinking starts }
    cblindd: Word; { last of blinking }
    procedure Init(ANo, AHeight, AOX, AOY, AHX, AHY: Byte; ADots: Integer; AWallColor,
      AFrameColor: Shortint; AMazeData: PMazeData);
    procedure DrawAt(Xp, Yp: Byte);
    procedure Draw;
    function XFix(p: Byte): Integer;
    function YFix(p: Byte): Integer;
    function XPos(AX: Integer): Byte;
    function YPos(AY: Integer): Byte;
  end;
  PGhost = ^TGhost;
  TGhost = object
    Frames: PFrames;
    BlindFrames : PBlindFrames;
    DeadFrames: P4Frames;
    Level: PLevel;
    Name: Byte;
    cwf: Byte; { current walking frame }
    wd: Byte; { walking direction }
    X, Y: Integer;
    State: Byte;
    cb: Word; { blind counter }
    DrawMode: Byte;
    Obstacles: ByteSet;
    procedure Init(AFrames: PFrames; AName: Byte; ALevel: PLevel);
    procedure Draw;
    procedure UnDraw;
    procedure Move;
              procedure GoHome;
    function SetDir(ADir: Byte): Boolean;
    function WhatIs(ADir: Byte): Byte;
    function ExactX: Byte;
    function ExactY: Byte;
    procedure MakeBlind;
  end;

  TPacMan = object
    Frames: PFrames;
    Lives: Byte;
    Level: PLevel;
    Score: Longint;
    cwf, wd: Byte;
    X, Y: Integer;
    Stopped: Boolean;
    Invisible: Boolean;
    DrawMode: Byte;
    Obstacles: ByteSet;
    GotLife: Boolean;
    procedure Init(AFrames: PFrames; ALevel: PLevel);
    procedure Draw;
    procedure UnDraw;
    procedure Move;
    procedure GoHome;
    function SetDir(ADir: Byte): Boolean;
    function WhatIs(ADir: Byte): Byte;
    function ExactX: Byte;
    function ExactY: Byte;
  end;

var
  GhostFrames : array[1..4] of TFrames;
  DefaultBlindFrames : TBlindFrames;
  DefaultDeadFrames: T4Frames;
  LevelImages: TLevelImages;
  GBonusImages: T4Frames;
  ActImages: array[1..30] of Pointer;
  Mazes: array[1..3] of PMazeData;
  Ghosts: Array [1..4] of TGhost;
  MsPacFrames, PacFrames : TFrames;
  MsPac : TPacMan;
  LastMove: Byte;
  CurLevel: PLevel;
  GBonusC: Byte;
  l:Byte;
{  DelayPac: Boolean;}

procedure Retrace; assembler;
asm
        mov   dx, $3DA
@l1:    in    al, dx
        test  al, 8
        jnz   @l1
@l2:    in    al, dx
        test  al, 8
        jz    @l2
end;

procedure ClearKeyb;
begin
  while KeyPressed do ReadKey;
end;

function Test(a, b: Integer): Shortint;
begin
  if a > b then Test := 1;
  if a < b then Test := -1;
  if a = b then Test := 0;
end;

procedure LoadImages;
begin
{ Load Ghosts }
{   load Blinky }
  BLoad('blinkyl1', GhostFrames[Blinky][Left, 0]);
  BLoad('blinkyl2', GhostFrames[Blinky][Left, 1]);
  BLoad('blinkyr1', GhostFrames[Blinky][Right, 0]);
  BLoad('blinkyr2', GhostFrames[Blinky][Right, 1]);
  BLoad('blinkyu1', GhostFrames[Blinky][Up, 0]);
  BLoad('blinkyu2', GhostFrames[Blinky][Up, 1]);
  BLoad('blinkyd1', GhostFrames[Blinky][Down, 0]);
  BLoad('blinkyd2', GhostFrames[Blinky][Down, 1]);
{   load Pinky }
  BLoad('pinkyl1', GhostFrames[Pinky][Left, 0]);
  BLoad('pinkyl2', GhostFrames[Pinky][Left, 1]);
  BLoad('pinkyr1', GhostFrames[Pinky][Right, 0]);
  BLoad('pinkyr2', GhostFrames[Pinky][Right, 1]);
  BLoad('pinkyu1', GhostFrames[Pinky][Up, 0]);
  BLoad('pinkyu2', GhostFrames[Pinky][Up, 1]);
  BLoad('pinkyd1', GhostFrames[Pinky][Down, 0]);
  BLoad('pinkyd2', GhostFrames[Pinky][Down, 1]);
{   load Inky }
  BLoad('inkyl1', GhostFrames[Inky][Left, 0]);
  BLoad('inkyl2', GhostFrames[Inky][Left, 1]);
  BLoad('inkyr1', GhostFrames[Inky][Right, 0]);
  BLoad('inkyr2', GhostFrames[Inky][Right, 1]);
  BLoad('inkyu1', GhostFrames[Inky][Up, 0]);
  BLoad('inkyu2', GhostFrames[Inky][Up, 1]);
  BLoad('inkyd1', GhostFrames[Inky][Down, 0]);
  BLoad('inkyd2', GhostFrames[Inky][Down, 1]);
{   load Sue }
  BLoad('suel1', GhostFrames[Sue][Left, 0]);
  BLoad('suel2', GhostFrames[Sue][Left, 1]);
  BLoad('suer1', GhostFrames[Sue][Right, 0]);
  BLoad('suer2', GhostFrames[Sue][Right, 1]);
  BLoad('sueu1', GhostFrames[Sue][Up, 0]);
  BLoad('sueu2', GhostFrames[Sue][Up, 1]);
  BLoad('sued1', GhostFrames[Sue][Down, 0]);
  BLoad('sued2', GhostFrames[Sue][Down, 1]);
{   load blind state }
  BLoad('blind11', DefaultBlindFrames[0][0]);
  BLoad('blind12', DefaultBlindFrames[0][1]);
  BLoad('blind21', DefaultBlindFrames[1][0]);
  BLoad('blind22', DefaultBlindFrames[1][1]);

{   load dead state }
  BLoad('deadl', DefaultDeadFrames[1]);
  BLoad('deadr', DefaultDeadFrames[2]);
  BLoad('deadu', DefaultDeadFrames[3]);
  BLoad('deadd', DefaultDeadFrames[4]);

{ Load MsPacman }
  Bload('mspacl1', MsPacFrames[Left][0]);
  Bload('mspaclf', MsPacFrames[Left][1]);
  Bload('mspacr1', MsPacFrames[Right][0]);
  Bload('mspacrf', MsPacFrames[Right][1]);
  Bload('mspacu1', MsPacFrames[Up][0]);
  Bload('mspacuf', MsPacFrames[Up][1]);
  Bload('mspacd1', MsPacFrames[Down][0]);
  Bload('mspacdf', MsPacFrames[Down][1]);

{ Load Pacman }
  Bload('pacl1', PacFrames[Left][0]);
  Bload('paclf', PacFrames[Left][1]);
  Bload('pacr1', PacFrames[Right][0]);
  Bload('pacrf', PacFrames[Right][1]);
  Bload('pacu1', PacFrames[Up][0]);
  Bload('pacuf', PacFrames[Up][1]);
  Bload('pacd1', PacFrames[Down][0]);
  Bload('pacdf', PacFrames[Down][1]);

{ Load Level Images }
  Bload('wblank', LevelImages[0]);
  Bload('wfull', LevelImages[1]);
  Bload('wup', LevelImages[2]);
  Bload('wdown', LevelImages[3]);
  Bload('wleft', LevelImages[4]);
  Bload('wright', LevelImages[5]);
  Bload('whoriz', LevelImages[6]);
  Bload('wvert',  LevelImages[7]);
  Bload('wupl', LevelImages[8]);
  Bload('wupr', LevelImages[9]);
  Bload('wdownl', LevelImages[10]);
  Bload('wdownr', LevelImages[11]);
  Bload('wupt', LevelImages[12]);
  Bload('wdownt', LevelImages[13]);
  Bload('wleftt', LevelImages[14]);
  Bload('wrightt', LevelImages[15]);
  Bload('ghdoor', LevelImages[16]);
  Bload('msdot', LevelImages[17]);
  Bload('mspill', LevelImages[18]);

{ Load Mazes }
  Bload('pclv1', Pointer(Mazes[1]));
  Bload('pclv2', Pointer(Mazes[2]));
  Bload('pclv3', Pointer(Mazes[3]));

{ Load Bonus }
  Bload('200', GBonusImages[1]);
  Bload('400', GBonusImages[2]);
  Bload('800', GBonusImages[3]);
  Bload('1600', GBonusImages[4]);

{ Load Act images }
  Bload('act1', ActImages[1]);
  Bload('act2', ActImages[2]);
  Bload('act3', ActImages[3]);
  Bload('actc', ActImages[4]);
  Bload('acto', ActImages[5]);
  Bload('domona', ActImages[6]);
  Bload('domonaf', ActImages[7]);
  Bload('domobaja', ActImages[8]);
  Bload('obajaf', ActImages[9]);
  Bload('dom1', ActImages[10]);
  Bload('dom1f', ActImages[11]);
  Bload('dom2', ActImages[12]);
  Bload('dom2f', ActImages[13]);
  Bload('dom3', ActImages[14]);
  Bload('dom3f', ActImages[15]);
  Bload('dom4', ActImages[16]);
  Bload('dom4f', ActImages[17]);
  Bload('domsrd', ActImages[18]);
  Bload('domsrd2', ActImages[19]);
  Bload('doms3', ActImages[20]);
  Bload('doms4', ActImages[21]);
  Bload('dom', ActImages[25]);
end;

function OppDir(ADir: Byte): Byte;
begin
  case ADir of
    Left : OppDir := Right;
    Right: OppDir := Left;
    Up   : OppDir := Down;
    Down : OppDir := Up;
  end;
end;

procedure Message(s: String; MS: Word);
var x, y: Integer;
begin
  x := CurLevel^.XFix(CurLevel^.HX+1) - 8 - TextWidth(s) shr 1;
  y := CurLevel^.YFix(CurLevel^.HY + 2);
  SetColor(Yellow);
  OutTextXY(x, y, s);
  Delay(MS);
  SetColor(Black);
  OutTextXY(x, y, s);
  SetColor(White);
end;

procedure ShowScore;
var s: String;
begin
  Str(MsPac.Score:7, s);
  Bar(CurLevel^.X, CurLevel^.Y - 16, CurLevel^.X + TextWidth(s), CurLevel^.Y);
  OutTextXY(CurLevel^.X, CurLevel^.Y - 16, s);
end;

procedure ShowLives;
var
  i: Byte;
  y: Integer;
begin
  y := CurLevel^.Y + (CurLevel^.Height + 1) shl 4;
  i := 0;
  while (i < MsPac.Lives) do
  begin
    if ((l=1) or (l = 2) or (l=5)) then
    begin
   	 PutImage(CurLevel^.X + i shl 4, y, PacFrames[Right, 0]^, CopyPut);
    end
    else
    begin
   	PutImage(CurLevel^.X + i shl 4, y, MsPacFrames[Right, 0]^, CopyPut);
    end;
    Inc(i);
  end;
  PutImage(CurLevel^.X + i shl 4, y, LevelImages[0]^, CopyPut);
end;

procedure ScoreUp(By: Integer);
begin
  Inc(MsPac.Score, By);
  ShowScore;
  if MsPac.GotLife then Exit;
  if MsPac.Score >= 20000 then
  begin
    Inc(MsPac.Lives);
    MsPac.GotLife := True;
    ShowLives;
  end;
end;

procedure TLevel.Init(ANo, AHeight, AOX, AOY, AHX, AHY: Byte; ADots: Integer;
  AWallColor, AFrameColor: Shortint; AMazeData: PMazeData);
begin
  No := ANo;
  Data := AMazeData^;
  Color := 8;
  X := 640 shr 1 - mzMaxX shl 3;
  Y := 480 shr 1 - mzMaxY shl 3;
{  Y := 0;}
  OX := AOX; OY := AOY;
  HX := AHX; HY := AHY;
  Height := AHeight;
  DrawMode := OrPut;
  Dots := ADots;
  WallColor := AWallColor;
  FrameColor := AFrameColor;
  cblind  := 512; { blind counter init }
  cblindb := 214; { where blinking starts }
  cblindd :=  48; { last of blinking }
end;

procedure TLevel.DrawAt(Xp, Yp: Byte);
begin
  PutImage(X + Xp shl 4, Y + Yp shl 4, LevelImages[Data[Xp, Yp]]^, DrawMode);
end;

procedure TLevel.Draw;
var i, j: Byte;
begin
  for j := 0 to mzMaxY do for i := 0 to mzMaxX do DrawAt(i, j);
end;

function TLevel.XFix(p: Byte): Integer;
begin
  XFix := X + p shl 4;
end;

function TLevel.YFix(p: Byte): Integer;
begin
  YFix := Y + p shl 4;
end;

function TLevel.XPos(AX: Integer): Byte;
begin
  XPos := (AX - X) shr 4;
end;

function TLevel.YPos(AY: Integer): Byte;
begin
  YPos := (AY - Y) shr 4;
end;

procedure TGhost.Init(AFrames: PFrames; AName: Byte; ALevel: PLevel);
begin
  Level := ALevel;
  if Level^.No = 1 then
  begin
    Frames := AFrames;
    BlindFrames := @DefaultBlindFrames;
    DeadFrames := @DefaultDeadFrames;
    Name := AName;
    DrawMode := CopyPut;
    Obstacles := [2..15];
  end;
  GoHome;
end;

procedure TGhost.Draw;
var ax, ay: Byte;
begin
  ax := Level^.XPos(X);
  ay := Level^.YPos(Y);
  case State of
    Normal: PutImage(X, Y, Frames^[wd][Byte(cwf mod 24 >= 12)]^, DrawMode);
    Blind: PutImage(X, Y,
      BlindFrames^[Byte((cb<Level^.cblindb) and (cb mod Level^.cblindd > Level^.cblindd shr 1))][Byte(cwf mod 24 >= 12)]^,
        DrawMode);
    Dead: PutImage(X, Y, DeadFrames^[wd]^, DrawMode);
  end;
  if not ((ExactX < 5) and (ExactY < 5)) then
  case wd of
    Left: Level^.DrawAt(ax+1, ay);
    Right: Level^.DrawAt(ax, ay);
    Up: Level^.DrawAt(ax, ay+1);
    Down: Level^.DrawAt(ax, ay);
  end;
end;

procedure TGhost.UnDraw;
var ax, ay: Byte;
begin
  ax := Level^.XPos(X);
  ay := Level^.YPos(Y);
  Draw;
  DrawMode := XORPut;
  Draw;
  DrawMode := CopyPut;
  case wd of
    Left, Right:
    begin
      Level^.DrawAt(ax+1, ay);
      Level^.DrawAt(ax, ay);
    end;
    Up, Down:
    begin
      Level^.DrawAt(ax, ay+1);
      Level^.DrawAt(ax, ay);
    end;
  end;
end;

procedure TGhost.Move;
begin
  if (wd = Right) and (Level^.XPos(X) = 18) then
  begin
    PutImage(X, Y, LevelImages[0]^, CopyPut);
    X := Level^.X;
    Draw;
  end;
  if (wd = Left) and (X = Level^.X) then
  begin
    PutImage(X, Y, LevelImages[0]^, CopyPut);
    X := Level^.X + 18*16;
    Draw;
  end;
  case wd of
    Left  : Dec(X);
    Right : Inc(X);
    Up    : Dec(Y);
    Down  : Inc(Y);
  end;
  Inc(cwf);
  if State = Blind then
  begin
    Dec(cb);
    if cb = 0 then State := Normal;
  end;
end;

procedure TGhost.GoHome;
begin
  case Name of
    Blinky, Pinky: X := Level^.XFix(Level^.HX);
    Inky: X := Level^.XFix(Level^.HX - 1);
    Sue: X := Level^.XFix(Level^.HX + 1);
  end;
  case Name of
    Blinky: Y := Level^.YFix(Level^.HY - 1);
    Inky..Sue: Y := Level^.YFix(Level^.HY);
  end;
  case Name of
    Blinky, Pinky: wd := Up;
    Inky: wd := Right;
    Sue: wd := Left;
  end;
  cwf := 0;
  State := Normal;
end;

function TGhost.SetDir(ADir: Byte): Boolean;
var s: ByteSet;
begin
  SetDir := False;
  if (ADir = Down) and (State <> Dead) then s := [16] else s := [];
  if (((ADir in [Left, Right]) and (ExactY = 0)) or ((ADir in [Up, Down]) and (ExactX = 0)))
    and not (WhatIs(ADir) in (Obstacles + s)) then
    begin
      wd := ADir;
      SetDir := True;
    end;
end;

function TGhost.WhatIs(ADir: Byte): Byte;
begin
  case ADir of
    Left: WhatIs := Level^.Data[Level^.XPos(X) - 1,Level^.YPos(Y)];
    Right: WhatIs := Level^.Data[Level^.XPos(X) + 1,Level^.YPos(Y)];
    Up: WhatIs := Level^.Data[Level^.XPos(X),Level^.YPos(Y) - 1];
    Down: WhatIs := Level^.Data[Level^.XPos(X),Level^.YPos(Y) + 1];
  end;
end;

function TGhost.ExactX: Byte;
begin
  ExactX := (X - Level^.X) mod 16;
end;

function TGhost.ExactY: Byte;
begin
  ExactY := (Y - Level^.Y) mod 16;
end;

procedure TGhost.MakeBlind;
begin
  if State = Dead then Exit;
  if Level^.cblind = 0 then Exit;
  if (State = Normal) and not (WhatIs(OppDir(wd)) in Obstacles) then
    wd := OppDir(wd);
  State := Blind;
  cb := Level^.cblind;
end;

procedure TPacMan.Init(AFrames: PFrames; ALevel: PLevel);
begin
  Level  := ALevel;
  Frames := AFrames;
  DrawMode := CopyPut;
  if Level^.No = 1 then
   begin
    
    Lives  := 4;
    Score  := 0;
    GotLife := False;
   
    Obstacles := [2..16];
    Invisible := False;
  end;
  GoHome;
end;

procedure TPacMan.Draw;
begin
  PutImage(X, Y, Frames^[wd][Byte(cwf mod 6 >= 3)]^, DrawMode)
end;

procedure TPacMan.UnDraw;
begin
  Draw;
  DrawMode := XORPut;
  Draw;
  DrawMode := CopyPut;
end;

procedure TPacMan.Move;
var
  OX, OY: Integer;
  R: TRect;
  i: Byte;
begin
  if Stopped then Exit;
  if (wd = Right) and (Level^.XPos(X) = 18) then
  begin
    PutImage(X, Y, LevelImages[0]^, CopyPut);
    X := Level^.X;
    Draw;
  end;
  if (wd = Left) and (X = Level^.X) then
  begin
    PutImage(X, Y, LevelImages[0]^, CopyPut);
    X := Level^.X + 18*16;
    Draw;
  end;
  case wd of
    Left, Right: if (WhatIs(wd) in Obstacles) and (ExactX = 0) then Stopped := True;
    Up, Down: if (WhatIs(wd) in Obstacles) and (ExactY = 0) then Stopped := True;
  end;
  if Stopped then Exit;
  OX := X;
  OY := Y;
  case wd of
    Left  : Dec(X);
    Right : Inc(X);
    Up    : Dec(Y);
    Down  : Inc(Y);
  end;
  Inc(cwf);
  if Stopped then begin X := OX; Y := OY; Dec(cwf) end;
  OX := Level^.XPos(X);
  OY := Level^.YPos(Y);
  case wd of
    Right: Inc(OX, Byte(not(ExactX=0)));
    Down: Inc(OY, Byte(not(ExactY=0)));
  end;
  if Level^.Data[OX, OY] <> 0 then
  begin
    if Level^.Data[OX, OY] = 18 then
    begin
      for i := 1 to 4 do Ghosts[i].MakeBlind;
      GBonusC := 0;
      ScoreUp(50);
    end;
{    DelayPac := True;}
    if Level^.Data[OX, OY] = 17 then ScoreUp(10);
    Level^.Data[OX, OY] := 0;
    Level^.DrawMode := CopyPut;
    Level^.DrawAt(OX, OY);
    Level^.DrawMode := OrPut;
    Dec(Level^.Dots);
  end;{ else DelayPac := False;}
end;

procedure TPacMan.GoHome;
begin
  X := Level^.XFix(Level^.OX);
  Y := Level^.YFix(Level^.OY);
  wd := Left;
  cwf := 0;
  Stopped := False;
end;

function TPacMan.SetDir(ADir: Byte): Boolean;
begin
  SetDir := False;
  if (((ADir in [Left, Right]) and (ExactY = 0)) or ((ADir in [Up, Down]) and (ExactX = 0)))
    and not (WhatIs(ADir) in Obstacles) then
    begin
      wd := ADir;
      Stopped := False;
      SetDir := True;
    end;
end;

function TPacMan.WhatIs(ADir: Byte): Byte;
begin
  case ADir of
    Left: WhatIs := Level^.Data[Level^.XPos(X) - 1,Level^.YPos(Y)];
    Right: WhatIs := Level^.Data[Level^.XPos(X) + 1,Level^.YPos(Y)];
    Up: WhatIs := Level^.Data[Level^.XPos(X),Level^.YPos(Y) - 1];
    Down: WhatIs := Level^.Data[Level^.XPos(X),Level^.YPos(Y) + 1];
  end;
end;

function TPacMan.ExactX: Byte;
begin
  ExactX := (X - Level^.X) mod 16;
end;

function TPacMan.ExactY: Byte;
begin
  ExactY := (Y - Level^.Y) mod 16;
end;

var
  i: word;
  ch: Char;
  Levels: array[1..6] of TLevel;
  gd, gm: Integer;
  t: word;
  pal: shortint;
  om   : byte;
  del: byte;

procedure EatGhost(i: Byte);
begin
  MsPac.UnDraw;
  Inc(GBonusC);
  PutImage(Ghosts[i].X, Ghosts[i].Y, GBonusImages[GBonusC]^, CopyPut);
  ScoreUp(GBonus[GBonusC]);
  Delay(500);
  PutImage(Ghosts[i].X, Ghosts[i].Y, GBonusImages[GBonusC]^, XorPut);
  if GBonusC = 4 then GBonusC := 0;
  Ghosts[i].State := Dead;
  Ghosts[i].Draw;
  case Ghosts[i].wd of
    Left, Right: if Odd(Ghosts[i].X) then Ghosts[i].Move;
    Up, Down: if Odd(Ghosts[i].Y) then Ghosts[i].Move;
  end;
  Ghosts[i].Draw;
  MsPac.Draw;
end;

procedure LooseLife;
const dd: array[1..4] of byte = (Down, Up, Left, Right);
var i: Byte;
begin
  if MsPac.Invisible or (CurLevel^.Dots = 0) then Exit;
  Delay(700);
  for i := Blinky to Sue do Ghosts[i].UnDraw;
  MsPac.cwf := 0;
  MsPac.Draw;
  Delay(500);
  for i := 1 to 4 do
  begin
    MsPac.wd := dd[MsPac.wd];
    MsPac.Draw;
    Delay(200);
    MsPac.UnDraw;
  end;
  if MsPac.Lives = 0 then
  begin
    Message('TRY AGAIN OR READ CHEATS :)', 3000);
    CloseGraph;
    Halt;
  end;
  Dec(MsPac.Lives);
  ShowLives;
  for i := Blinky to Sue do Ghosts[i].GoHome;
  MsPac.GoHome;
  for i := Blinky to Sue do Ghosts[i].Draw;
  MsPac.Draw;
  ClearKeyb;
  Message('READY', 1000);
end;

procedure MoveRest;
var i, j, p, ox, oy, gx, gy: byte;
    l: String;
    v: ByteSet;
begin
  oy := MsPac.Level^.YPos(MsPac.Y);
  ox := MsPac.Level^.XPos(MsPac.X);
  i := oy;
  j := ox;
{  while (MsPac.Level^.Data[j-1,i] = 0) and (MsPac.Level^.Data[j-1,i-1]<>0)
  and (MsPac.Level^.Data[j-1,i+1]<>0) do Dec(j);}
  Chase[1,1] := j-1;
  Chase[1,2] := i;

  i := oy;
  j := ox;
  if MsPac.wd = Right then
  while (MsPac.Level^.Data[j+1,i] = 0) and (MsPac.Level^.Data[j+1,i-1]<>0)
  and (MsPac.Level^.Data[j+1,i+1]<>0) do Inc(j)
  else while (MsPac.Level^.Data[j-1,i] = 0) and (MsPac.Level^.Data[j-1,i-1]<>0)
  and (MsPac.Level^.Data[j-1,i+1]<>0) do Dec(j);
  Chase[2,1] := j;
  Chase[2,2] := i;

  i := oy;
  j := ox;
  while (MsPac.Level^.Data[j,i-1] = 0) and (MsPac.Level^.Data[j-1,i-1]<>0)
  and (MsPac.Level^.Data[j+1,i-1]<>0) do Dec(i);
  Chase[3,1] := j;
  Chase[3,2] := i-1;

  i := oy;
  j := ox;
{  while (MsPac.Level^.Data[j,i+1] = 0) and (MsPac.Level^.Data[j-1,i+1]<>0)
  and (MsPac.Level^.Data[j+1,i+1]<>0) do Inc(i);}
  if Random(1) = 1 then Chase[4,1] := j+2 else Chase[4,1]:=j-2;
  if Random(1) = 1 then Chase[4,2] := i+1 else Chase[4,2]:=i-1;

  for i := Blinky to Sue do with Ghosts[i] do
  begin
    gx := Level^.XPos(X);
    gy := Level^.YPos(Y);
    if (State = Dead) and (gx = Level^.HX) and (gy = Level^.HY) then State := Normal;
    case wd of
      Left, Right: if (MsPac.ExactY = 0) and (ExactY = 0) and (gy = oy) and (Abs(X - MsPac.X) <= 10) then
      case State of
        Normal: LooseLife;
        Blind: EatGhost(i);
      end;
      Up, Down: if (MsPac.ExactX = 0) and (ExactX = 0) and (gx = ox) and (Abs(Y - MsPac.Y) <= 10) then
      case State of
        Normal: LooseLife;
        Blind: EatGhost(i);
      end;
    end;
    if ((wd in [Left, Right]) and (ExactX = 0)) or ((wd in [Up, Down]) and (ExactY = 0)) then
    begin
      j := 0;
      l := '';
      v := [];
      repeat
        Inc(j);
        if not (WhatIs(j) in Obstacles) then
        begin
          l := l + Chr(j);
          Include(v, j);
        end;
      until (j = 4);
      if (Length(l) > 1) then
      begin
        Delete(l, Pos(Chr(OppDir(wd)), l), 1);
        Exclude(v, OppDir(wd));
      end;
      p := Byte(l[Random(Length(l))+1]);
      case State of
        Normal:
        begin
          if (Chase[i,1] > gx) and (Right in v) then p := Right;
          if (Chase[i,1] < gx) and (Left in v) then p := Left;
          if (Chase[i,2] < gy) and (Up in v) then p := Up;
          if (Chase[i,2] > gy) and (Down in v) then p := Down;
        end;
        Dead:
        begin
          if (Level^.HX < gx) and (Left in v) then p := Left;
          if (Level^.HX > gx) and (Right in v) then p := Right;
          if (Level^.HY-2 < gy) and (Up in v) then p := Up;
          if (Level^.HY-2 > gy) and (Down in v) then p := Down;
          if (Level^.HX = gx) and (Level^.HY-2 = gy) then p := Down;
        end;
      end;
{      if State = Blind then
      begin
        if (Chase[i,1] < gx) and (Right in v) then p := Right;
        if (Chase[i,1] > gx) and (Left in v) then p := Left;
        if (Chase[i,2] > gy) and (Up in v) then p := Up;
        if (Chase[i,2] < gy) and (Down in v) then p := Down;
      end;}
      SetDir(p);
    end;
  end;
end;

procedure Cheat(ch: Char);
begin
  case ch of
    #108: begin {l, lives up}
            Inc(MsPac.Lives);
            ShowLives;
          end;
    #97: ScoreUp(1000); {a, score up}
    #98: begin {b, make blind}
            for i := 1 to 4 do Ghosts[i].MakeBlind;
            GBonusC := 0;
          end;
    #105: MsPac.Invisible := not MsPac.Invisible; {i, make invisible}
  end;
end;

procedure Act(actno: Byte);
  procedure Act1;
  var
    i, x1, x2: Integer;
    cwf1, cwf2: Byte;
    wd1, wd2: Byte;
  begin
    wd1 := Right; wd2 := Right;
    cwf1 := 0; cwf2 := 0;
    x1 := 640 shr 1 - mzMaxX shl 3;
    x2 := x1 + 32;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(6);
      if x1 mod 24 = 0 then
      begin

        PutImage(x1, 150, GhostFrames[Inky][wd1][Byte(cwf1 mod 24 >= 12)]^, CopyPut);
        Inc(x1)      ;
      end;
      PutImage(x1, 150, GhostFrames[Inky][wd1][Byte(cwf1 mod 24 >= 12)]^, CopyPut);
      PutImage(x2, 150, PacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      Inc(x1); Inc(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    ClearDevice;
    Delay(200);

    wd1 := Left; wd2 := Left;
    cwf1 := 0; cwf2 := 0;
    x2 := 640 shr 1 + mzMaxX shl 3;
    x1 := x2 - 32;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(6);
      if x1 mod 24 = 0 then
      begin
        PutImage(x2, 250, GhostFrames[Pinky][wd1][Byte(cwf1 mod 24 >= 12)]^, CopyPut);
        Dec(x2);
      end;
      PutImage(x2, 250, GhostFrames[Pinky][wd2][Byte(cwf2 mod 24 >= 12)]^, CopyPut);
      PutImage(x1, 250, MsPacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      Dec(x1); Dec(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    ClearDevice;
    Delay(200);

    wd1 := Left; wd2 := Right;
    cwf1 := 0; cwf2 := 0;
    x1 := 640 shr 1 + mzMaxX shl 3;
    x2 := 640 shr 1 - mzMaxX shl 3;;
    for i := 1 to mzMaxX * 8 - 8 do
    begin
      Delay(6);
      PutImage(x1, 210, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x2, 210, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      PutImage(x1+20, 210, GhostFrames[Inky][wd1][Byte(cwf1 mod 24 >= 12)]^, CopyPut);
      PutImage(x2-20, 210, GhostFrames[Pinky][wd2][Byte(cwf2 mod 24 >= 12)]^, CopyPut);
      Dec(x1); Inc(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    wd1 := Up; wd2 := Up;
    cwf1 := 0; cwf2 := 0;
    for i := 210 downto 170 do
    begin
      Delay(6);
      PutImage(x1, i, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x2, i, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      if (x1 - x2 + 2 * i > 392) then
      begin
        PutImage(x1+20+i-210, 210, GhostFrames[Inky][Left][Byte(cwf1 mod 24 >= 12)]^, CopyPut);
        PutImage(x2-20-i+210, 210, GhostFrames[Pinky][Right][Byte(cwf2 mod 24 >= 12)]^, CopyPut);
      end else
      begin
        PutImage(326+186-i, 210+Random(2), GhostFrames[Inky][Left][Byte(cwf1 mod 24 >= 12)]^, CopyPut);
        PutImage(314+i-186, 210+Random(2), GhostFrames[Pinky][Right][Byte(cwf2 mod 24 >= 12)]^, CopyPut);
      end;
      Inc(cwf1); Inc(cwf2);
    end;

    wd1 := Left; wd2 := Right;
    cwf1 := 0; cwf2 := 0;
    PutImage(x1, i, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
    PutImage(x2, i, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
    PutImage((x1 + x2) div 2, i - 8, LevelImages[17]^, OrPut);
    Delay(700);
    ClearDevice;
    Delay(500);
  end;

  procedure Act2;
  var
    	i, x1, x2: Integer;
    cwf1, cwf2: Byte;
    wd1, wd2: Byte;
  begin
    wd1 := Right; wd2 := Right;
    cwf1 := 0; cwf2 := 0;
    x1 := 640 shr 1 - mzMaxX shl 3;
    x2 := x1 + 32;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(4);
      if x1 mod 24 = 0 then
      begin
        PutImage(x1, 150, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
        Inc(x1);
      end;
      PutImage(x1, 150, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x2, 150, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      Inc(x1); Inc(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    ClearDevice;
    Delay(200);

    wd1 := Left; wd2 := Left;
    cwf1 := 0; cwf2 := 0;
    x1 := 640 shr 1 + mzMaxX shl 3;
    x2 := x1 - 32;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(4);
      if x1 mod 24 = 0 then
      begin
        PutImage(x1, 250, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
        Dec(x1);
      end;
      PutImage(x1, 250, MsPacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x2, 250, PacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      Dec(x1); Dec(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    ClearDevice;
    Delay(200);

    wd1 := Right; wd2 := Right;
    cwf1 := 0; cwf2 := 0;
    x1 := 640 shr 1 - mzMaxX shl 3;
    x2 := x1 + 32;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(4);
      if x1 mod 24 = 0 then
      begin
        PutImage(x1, 200, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
        Inc(x1);
      end;
      PutImage(x1, 200, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x2, 200, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      Inc(x1); Inc(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    ClearDevice;
    Delay(200);

    wd1 := Right;
    cwf1 := 0;
    x1 := 640 shr 1 - mzMaxX shl 3;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(1);
      PutImage(x1, 150, MsPacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      Inc(x1);
      Inc(cwf1);
    end;
    ClearDevice;
    wd1 := Right;
    cwf1 := 0;
    x1 := 640 shr 1 - mzMaxX shl 3;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(1);
      PutImage(x1, 150, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      Inc(x1);
      Inc(cwf1);
    end;
    ClearDevice;
    Delay(200);

    wd1 := Left;
    cwf1 := 0;
    x1 := 640 shr 1 + mzMaxX shl 3;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(1);
      PutImage(x1, 250, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      Dec(x1);
      Inc(cwf1);
    end;
    ClearDevice;
    wd1 := Left;
    cwf1 := 0;
    x1 := 640 shr 1 + mzMaxX shl 3;
    for i := 1 to mzMaxX * 16 do
    begin
      Delay(1);
      PutImage(x1, 250, MsPacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      Dec(x1);
      Inc(cwf1);
    end;
    ClearDevice;
    Delay(1000);
  end;

  procedure Act3;
  var
    i, x1, x2: Integer;
    cwf1, cwf2: Byte;
    wd1, wd2: Byte;
    dom_x:Integer;
  begin
    delay(1000);
    wd1 := Left; wd2 := Right;
    cwf1 := 0; cwf2 := 0;
    x1 := 640 shr 1 - mzMaxX shl 3;
    x2 := 640-x1;

    cwf1 := 0; cwf2 := 0;
    x2 := 640 shr 1 + mzMaxX shl 3;
    x1 := 640 shr 1 - mzMaxX shl 3;;
    for i := 1 to mzMaxX * 8 - 8 do
    begin
      Delay(6);
      PutImage(x2, 210, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x1, 210, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      Inc(x1); Dec(x2);
      Inc(cwf1); Inc(cwf2);

    end;
    Bload('black', ActImages[22]);
    PutImage((x1 + x2) div 2, 210 - 8 , LevelImages[17]^, OrPut);
    Delay(700);
    PutImage((x1 + x2) div 2, 210 - 8, ActImages[22]^, CopyPut);


    wd1 := Left; wd2 := Left;
    for i := 1 to mzMaxX * 3 do
    begin
      PutImage(x2, 210, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x1, 210, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      Delay(30);
      Dec(x1); Dec(x2);
      Inc(cwf1); Inc(cwf2);
    end;
    dom_x:=30;
     for i :=   1 to mzMaxX * 4+7 do
    begin
      Delay(10);
      PutImage(x2, 210, PacFrames[wd1][Byte(cwf1 mod 6 >= 3)]^, CopyPut);
      PutImage(x1, 210, MsPacFrames[wd2][Byte(cwf2 mod 6 >= 3)]^, CopyPut);
      PutImage(dom_x, 210-48, ActImages[25]^, CopyPut);
      Dec(x1); Dec(x2); Inc(dom_x);
      Inc(cwf1); Inc(cwf2);
    end;
    ClearDevice;
    for i := 1 to 12 do
    begin
      PutImage(dom_x, 210-48, ActImages[Byte(i mod 6 >= 3)+6]^, CopyPut);
      Delay(60);
    end;
    for i := 1 to 12 do
    begin
      PutImage(dom_x, 210-48, ActImages[Byte( i mod 6 >= 3)+8]^, CopyPut);
      Delay(60);
    end; 
    
    for i := 1 to 12 do
    begin
      PutImage(dom_x, 210-48, ActImages[Byte(i mod 6 >= 3)+10]^, CopyPut);
      Delay(60);
    end;
    for i := 1 to 12 do
    begin
      PutImage(dom_x, 210-48, ActImages[Byte(i mod 6 >= 3)+12]^, CopyPut);
      Delay(60);
    end;
    for i := 1 to 12 do
    begin
      PutImage(dom_x, 210-48, ActImages[Byte(i mod 6 >= 3)+14]^, CopyPut);
      Delay(60);
    end;
    for i := 1 to 12 do
    begin
      PutImage(dom_x, 210-48, ActImages[Byte(i mod 6 >= 3)+16]^, CopyPut);
      Delay(60);
    end;
    PutImage(dom_x, 210-48, ActImages[18]^, CopyPut);
    Delay(60);
    PutImage(dom_x, 210-48-16-7, ActImages[19]^, CopyPut);
    Delay(60);
    for i:=1 to 39 do
    begin
      PutImage(dom_x, 210-48-16-7, ActImages[Byte(i mod 6 >= 3) + 20]^, CopyPut);
      Delay(60);
    end;
    Delay(1000);

  end;


begin
  ClearDevice;
  OutTextXY((640-TextWidth(ActStr[actno])) shr 1, 128, ActStr[actno]);
  PutImage(52, 120, ActImages[actno]^, CopyPut);
  PutImage(52, 100, ActImages[4]^, CopyPut);
  Delay(800);
  PutImage(52, 100, ActImages[5]^, CopyPut);
  Delay(400);
  PutImage(52, 100, ActImages[4]^, CopyPut);
  Delay(5000);
  ClearDevice;
  case actno of 1: Act1; 2: Act2; 3: Act3; end;
end;

begin
  clrscr;
  Writeln(#10'We cordially invite you to our wedding ceremony.');
  Writeln;
  Writeln('The ceremony will take place on July 12, 2014 at 3pm in Hall of Mirrors ');
  Writeln('in Primate',#39, 's Palace, Bratislava, Slovakia'#10);
  Writeln;
  Writeln('In the meanwhile, you can play the game starring');
  Writeln;
  Writeln('  Lucia Simanova as Ms. Pacman');
  Writeln('  David Pal as Mr. Pacman');

  Delay(10000);
  Writeln;
  Write('Loading ...');
  Randomize;
  LoadImages;
  Levels[1].Init(1, 20, 9, 15, 9, 9, 139, 39, 4, Mazes[1]);
  Levels[2].Init(2, 20, 9, 15, 9, 9, 139, 39, 4, Mazes[1]);
  Levels[2].cblind := 392;
  Levels[3].Init(3, 21, 9, 16, 9, 10, 159, 43, 63, Mazes[2]);
  Levels[3].cblind := 256;
  Levels[4].Init(4, 21, 9, 16, 9, 10, 159, 43, 63, Mazes[2]);
  Levels[4].cblind := 192;
  Levels[5].Init(5, 21, 9, 16, 9, 10, 159, 43, 63, Mazes[2]);
  Levels[5].cblind := 128;
  Levels[6].Init(6, 21, 9, 16, 9, 10, 158, 4, 63, Mazes[3]);
  Levels[6].cblind := 392;
  l := 0;
  pal := 63;
  del := 0;
  if paramstr(1) = 'r' then del := 1;
  if paramstr(1) = 'd' then del := 2;
  gd := VGA;
  gm := 2;
  InitGraph(gd, gm, '');
  SetFillStyle(SolidFill, Black);
  repeat
    Inc(l);
    CurLevel := @Levels[l];
    Ghosts[Blinky].Init(@GhostFrames[Blinky], Blinky, CurLevel);
    Ghosts[Pinky].Init(@GhostFrames[Pinky], Inky, CurLevel);
    Ghosts[Inky].Init(@GhostFrames[Inky], Pinky, CurLevel);
    Ghosts[Sue].Init(@GhostFrames[Sue], Sue, CurLevel);
    if ((l=1) or (l = 2) or (l=5)) then
    begin
	    MsPac.Init(@PacFrames, CurLevel)
    end
    else
    begin
	    MsPac.Init(@MsPacFrames, CurLevel);
    end;
    Delay(1000);
    SetPalette(8, CurLevel^.WallColor);
    SetPalette(7, CurLevel^.FrameColor);
    SetPalette(6, pal);
    ClearDevice;
    CurLevel^.draw;
    MsPac.Draw;
    ShowLives;
    ShowScore;
    for i := Blinky to Sue do Ghosts[i].Draw;
    ch := #0;
    LastMove := 0;
    om := LastMove;
    t := 0;
    GBonusC := 0;
  {  DelayPac := False;}
    Message('READY', 1000);
    ch := #0;
    repeat
      Inc(t);
      while KeyPressed do
      begin
        ch := ReadKey;
        if ch = #0 then ch := ReadKey;
        case ch of
          #75: LastMove := Left;
          #77: LastMove := Right;
          #72: LastMove := Up;
          #80: LastMove := Down;
          #108, #97, #98, #105: Cheat(ch);
        end;
      end;
      if LastMove <> 0 then if MsPac.SetDir(LastMove) then
      begin
        if om <> LastMove then
        begin
          om := LastMove;
          MsPac.Move;
          MsPac.Draw;
          MsPac.Move;
          MsPac.Draw;
        end;
        LastMove := 0;
      end;
      MoveRest;
      MsPac.Move;
      MsPac.Draw;
      if t mod 8 = 0 then
      begin
        MsPac.Move;
        MsPac.Draw;
      end;
      for i := Blinky to Sue do
      begin
        Ghosts[i].Move;
        if Ghosts[i].State = Dead then Ghosts[i].Move;
      end;
      for i := Blinky to Sue do Ghosts[i].Draw;
      if t mod 8 = 0 then
      begin
        pal := pal xor 63;
        SetPalette(6, pal);
      end;
    if del = 1 then Retrace;
    if del = 2 then Delay(10);

    if ch = #115 then CurLevel^.Dots := 0; {s}
    until (ch=#113) or (CurLevel^.Dots = 0);{q}
    MsPac.cwf := 0;
    MsPac.Draw;
    if CurLevel^.Dots = 0 then
    begin
      Delay(700);
      for i := Blinky to Sue do Ghosts[i].UnDraw;
      MsPac.UnDraw;
      Delay(300);
      SetPalette(8, 0);
      SetPalette(7, 63);
      Delay(300);
      SetPalette(8, CurLevel^.WallColor);
      SetPalette(7, CurLevel^.FrameColor);
      Delay(300);
      SetPalette(8, 0);
      SetPalette(7, 63);
      Delay(300);
      SetPalette(8, CurLevel^.WallColor);
      SetPalette(7, CurLevel^.FrameColor);
      Delay(300);
      SetPalette(8, 0);
      SetPalette(7, 63);
      Delay(300);
      ClearDevice;
      Delay(500);
    end;
    if ch <> #113 then case l of 2: Act(1); 4: Act(2); 6: Act(3) end;
    ClearKeyb;
  until (ch = #113) or (l = 6);
  CloseGraph;
end.
