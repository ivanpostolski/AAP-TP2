// No overflow

method F(X: int) returns (Y: int)
  requires X % 2 == 0;
 // ensures Y == X
{
  var Xdiv2: int;
  Xdiv2 := G(X); 
  Y := Xdiv2 + Xdiv2;
}

method G(X : int) returns (Y: int)
ensures Y == X / 2;
{
  Y := X / 2;
}
