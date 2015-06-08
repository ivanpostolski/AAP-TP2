// Should find possible overflow

method Div(X: int, Y: int) returns (sum: int)
  requires Y < 7
  ensures Y  < 7
{ 
  sum := X / Y;
}