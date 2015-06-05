// Should find possible overflow

method Sum(X: int, Y: int) returns (sum: int)
  requires X < 6
  requires Y < 7
  ensures sum ==X + Y;
{
  sum := X + Y;
}

