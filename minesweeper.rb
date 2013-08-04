# todo:
# gui: I think cells should extend Qt::PushButton
# check for end game
# player should not be able to lose on first click. initialize to all empty squares, then after first click, place bombs avoiding the click coord

require 'pry'
require 'pry-nav'
require 'Qt4'

N = 12 #NxN board
X = 10 #X bombs

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
		return draw_field true
	elsif action =~ /[gs]/
		if chosen_cell.is_flipped
			puts 'this cell has already been flipped, select a different one'
			 return draw_field true
		else
			if chosen_cell.is_a?(MineCell)
				chosen_cell.is_flipped = true
				 return draw_field false
			else
				floodfill(x, y)
				 return draw_field true
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
	@board.each do |x|
		x.each do |y|
			print "#{y.to_str} " 
		end
		puts ""
	end
	puts ""
end

#if bool is false, the game is over
def draw_field(bool)
	@w.children.each {|c| c.dispose }
	l = Qt::GridLayout.new(@w) do
		setColumnStretch 1, 1
	end
	@board.each do |x|
		x.each do |y|
			b = Qt::PushButton.new(y.to_str) do
				set_flat true if y.is_flipped
				resize 40, 40
			end
			b.connect(SIGNAL :clicked) do
				process_input('g', y.y, y.x)
			end
			l.add_widget(b, y.x, y.y)
		end
	end
end

# create NxN map
@board = N.times.map{ |x| N.times.map{ |y| EmptyCell.new(x, y)}}

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
draw_field true
@w.show

a.exec
