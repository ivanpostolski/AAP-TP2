// No overflow

method F(X: int) returns (Y: int)
  requires X % 2 == 0;
{
  var Xdiv2: int;
  Xdiv2 := G(X); 
  Y := Xdiv2 + Xdiv2;
}

method G(X : int) returns (Y: int)
{
  Y := X / 2;
}
