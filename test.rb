
require 'FlashRuntime/movie'

movie [0, 11000, 0, 8000], 6144 do
backgroundColor 255, 255, 255
shape(
1,
[0, 7459, 0, 4340],
[SolidFill.new(0, 0, 0, 255.0)],
lambda {
move 7084, 375
curvedLine -375, -375, -531, 0
straightLine -4897, 0
curvedLine -531, 0, -375, 375
curvedLine -375, 375, 0, 531
straightLine 0, 1778
curvedLine 0, 531, 375, 375
curvedLine 375, 375, 531, 0
straightLine 4897, 0
curvedLine 531, 0, 375, -375
curvedLine 375, -375, 0, -531
straightLine 0, -1778
curvedLine 0, -531, -375, -375
}
)
shape(
3,
[1590, 9069, 1890, 6250],
[SolidFill.new(0, 0, 0, 255)],
lambda {
move 8684, 2275
curvedLine -375, -375, -531, 0
straightLine -4897, 0
curvedLine -531, 0, -375, 375
curvedLine -375, 375, 0, 531
straightLine 0, 1778
curvedLine 0, 531, 375, 375
curvedLine 375, 375, 531, 0
straightLine 4897, 0
curvedLine 531, 0, 375, -375
curvedLine 375, -375, 0, -531
straightLine 0, -1778
curvedLine 0, -531, -375, -375
}
)
place(3, 1,
[
1, 0, 0, 0,
0, 1, 0, 0,
0, 0, 1, 0,
0, 0, 0, 1
], nil)
place(2, 2,
[
1, 0, 0, 0,
0, 1, 0, 0,
0, 0, 1, 0,
1600, 1900, 0, 1
], nil)
show
end
