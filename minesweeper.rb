# todo:
# gui: I think cells should extend Qt::PushButton
# check for end game
# player should not be able to lose on first click. if first click is a mine, move the mine somewhere else

require 'pry'
require 'pry-nav'
require 'Qt4'

N = 12 #NxN board
X = 10 #X bombs

class Cell
	attr_accessor :is_flipped, :is_flagged, :surrounding_mines, :x, :y
	def initialize(mines, x, y)
		@is_flagged = @is_flipped = false
		@surrounding_mines = mines
		@x = x
		@y = y
	end
	
	def to_button
		b = Qt::PushButton.new
		b.set_text self.to_str
		b.set_flat self.is_flipped
		b.resize 40, 40
		b.connect(SIGNAL :clicked) do
			$g.process_input(@y, @x)
		end
		return b
	end
end

class MineCell < Cell
	def initialize(x, y)
		super(nil, x, y)
	end
	
	def to_str
		if self.is_flipped
			return "x"
		elsif self.is_flagged
			return "F"
		else
			return " "
		end
	end
end

class EmptyCell < Cell
	def initialize(x, y)
		super(0, x, y)
	end
	
	def to_str
		if self.is_flipped
			if self.surrounding_mines.zero?
				return "0"
			else
				return self.surrounding_mines.to_s
			end
		elsif self.is_flagged
			return "F"
		else
			return " "
		end
	end
end

class MineSweeper
	def start_game
		# create NxN map
		@board = N.times.map{ |x| N.times.map{ |y| EmptyCell.new(x, y)}}
		
		@cells_left = N*N

		# add X bombs
		X.times do
			begin
				x = rand(1..N) - 1
				y = rand(1..N) - 1
			end while @board[y][x].is_a?(MineCell)
		
			@board[y][x] = MineCell.new(y, x)
			(-1..1).each do |i|
				(-1..1).each do |j|
					unless (i.zero? && j.zero?) || !([x + i, y + j] & [-1, N]).empty? || @board[y + j][x + i].is_a?(MineCell)
						@board[y + j][x + i].surrounding_mines += 1
					end
				end
			end
		end
	
		# start the game
		puts "New Game!"

		a = Qt::Application.new(ARGV)

		@w = Qt::Widget.new
		@w.setFixedSize N*40, N*40
		draw_field
		@w.show

		a.exec
	end
	
	#returns a bool: true means go to next turn, false means game over
	def process_input(x, y)
		chosen_cell = @board[y][x]

		if chosen_cell.is_flipped
			puts 'this cell has already been flipped, select a different one'
		else
			if chosen_cell.is_a?(MineCell)
				chosen_cell.is_flipped = true
				end_game false
			else
				floodfill(x, y)
			end
		end
		return draw_field
	end

	def floodfill(x, y)
		cell = @board[y][x]
		return if cell.is_flipped || cell.is_a?(MineCell)
		cell.is_flipped = true
		@cells_left -= 1
		return if cell.surrounding_mines > 0
		
		(-1..1).each do |i|
			(-1..1).each do |j|
				next if (i.zero? && j.zero?) || !([x + i, y + j] & [-1, N]).empty?
				floodfill(x + i, y + j)
			end
		end
	end


	def draw_field
		@w.children.each {|c| c.dispose }
		l = Qt::GridLayout.new(@w) do
			setColumnStretch 1, 1
		end
		@board.each do |x|
			x.each do |y|
				l.add_widget(y.to_button, y.x, y.y)
			end
		end
		l.add_widget(Qt::Label.new("Clear this many cells to win: #{@cells_left - X}"), N, 0, 1, N-1)
		if @cells_left == X
			end_game true
		end
	end
	
	def end_game(win)
		if win
			puts "winner"
		else
			puts "loser"
		end
	end
end

$g = MineSweeper.new
$g.start_game
