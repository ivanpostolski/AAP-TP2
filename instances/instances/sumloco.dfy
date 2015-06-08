// Should find possible overflow

method Sum(X: int, Y: int) returns (sum: int)
{
  sum := SumLoco(X,Y);
}
method SumLoco(X : int,Y:int) returns (Z: int)
ensures Z == X + Y
{
  Z := X + Y;
}

