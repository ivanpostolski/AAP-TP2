// No overflow

method Sum(X: int, Y: int) returns (sum: int)
  requires X < 6
  requires X > -5
  requires Y < 6
  requires Y > -2
  ensures sum ==X + Y;
{
  sum := X + Y;
}



