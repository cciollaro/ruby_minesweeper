# todo:
# gui: I think cells should extend Qt::PushButton
# check for end game
# player should not be able to lose on first click. if first click is a mine, move the mine somewhere else

require 'pry'
require 'pry-nav'
require 'Qt4'

class Cell
	attr_accessor :is_flipped, :is_flagged, :surrounding_mines, :x, :y
	def initialize(mines, x, y)
		@is_flipped = false
		@surrounding_mines = mines
		@x = x
		@y = y
	end
end

class MineCell < Cell
	def initialize(x, y)
		super(nil, x, y)
	end
end

class EmptyCell < Cell
	def initialize(x, y)
		super(0, x, y)
	end
end


N = 8 #NxN board
X = 10 #X bombs
	

	 
# get some user input
def user_input
	begin
		puts 'do you want to guess or flag? (g)uess/(f)lag' 
	end until (action = gets).match(/[gfs]/)
	
	print_board(true) if action =~ /s/
	
	puts 'which spot?'
	print 'x: '
	x = gets.to_i - 1
	print 'y: '
	y = gets.to_i - 1
	return [action, x, y]
end
  
#returns a bool: true means go to next turn, false means game over
def process_input(action, x, y)
	chosen_cell = @board[y][x]
	if action =~ /f/
		if chosen_cell.is_flipped
			puts('you can\'t flag a flipped cell')
		else
			chosen_cell.is_flagged = !chosen_cell.is_flagged
		end
		return true
	elsif action =~ /[gs]/
		if chosen_cell.is_flipped
			puts 'this cell has already been flipped, select a different one'
			return true
		else
			if chosen_cell.is_a?(MineCell)
				chosen_cell.is_flipped = true
				return false
			else
				floodfill(x, y)
				return true
			end
		end
	else
		puts "what does #{action} even mean?"
		return true
	end
end

def floodfill(x, y)
	cell = @board[y][x]
	return if cell.is_flipped || cell.is_a?(MineCell)
	cell.is_flipped = true
	return if cell.surrounding_mines > 0
	
	(-1..1).each do |i|
		(-1..1).each do |j|
			next if (i.zero? && j.zero?) || !([x + i, y + j] & [-1, N]).empty?
			floodfill(y + j, x + i)
		end
	end
end

def print_board(reveal_bombs=false)
	s = ""
	@board.each do |x|
		x.each do |y|
			if y.is_a?(MineCell) && (y.is_flipped || reveal_bombs)
				s << "x"
			elsif y.is_flipped
				s << y.surrounding_mines.to_s
			else
				if y.is_flagged
					s << "F"
				else
					s << "?"
				end
			end
			s << " "
		end
		s << "\n"
	end
	s << "\n"
	puts s
	return s
end

# create NxN map
@board = N.times.map{ |x| N.times.map{ |y| EmptyCell.new(x, y)}}

# add X bombs
X.times do |z|

	begin
		x = rand(1..N) - 1
		y = rand(1..N) - 1
	end while @board[y][x].is_a?(MineCell)
	
	@board[y][x] = MineCell.new(x, y)
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
#begin
#	print_board
#end while process_input(*user_input)
#puts 'you picked a mine!'
#exit(1)

app = Qt::Application.new(ARGV)
 
hello = Qt::PushButton.new('Hello World')
hello.resize(200, 60)
hello.connect(SIGNAL :clicked) {
  Qt::MessageBox.new(Qt::MessageBox::Information, "dallagnese.fr", "Ruby Rocks!").exec
  app.quit
}
hello.show
 
app.exec
