require 'ruby2d'

set title: "Boario (Mario) in Ruby2D"
set background: 'blue'
set width: 800, height: 600

player = Image.new('assets/Boar60.png', x: 50, y: 500, width: 60, height: 50)

ground_parts = [
  { x: 0, width: 160 },
  { x: 320, width: 80 },
  { x: 640, width: 500 },
  { x: 1600, width: 400 },
  { x: 2800, width: 700}
]

platforms_positions = [
  { x: 0, y: 450, w: 120, h: 20 },
  { x: 400, y: 450, w: 160, h: 20 },
  { x: 700, y: 480, w: 500, h: 20 },
  { x: 1320, y: 400, w: 160, h: 20 },
  { x: 1100, y: 310, w: 80, h: 20 },
  { x: 1650, y: 400, w: 160, h: 20 },
  { x: 2000, y: 480, w: 160, h: 20 },
  { x: 2400, y: 540, w: 80, h: 20 },
  { x: 2350, y: 390, w: 80, h: 20 },
  { x: 2560, y: 480, w: 40, h: 20 },
  { x: 2580, y: 300, w: 40, h: 20 },
  { x: 3270, y: 0, w: 300, h: 550}
]

acorn_positions = [
  { x: 10, y: 400 },
  { x: 400, y: 480 },
  { x: 700, y: 500 },
  { x: 1100, y: 500 },
  { x: 1050, y: 200 },
  { x: 1530, y: 190 },
  { x: 1750, y: 340 },
  { x: 2400, y: 480 },
  { x: 2800, y: 190 }
]

ground_rects = []

ground_parts.each do |part|
  ground_rects << Rectangle.new(
    x: part[:x],
    y: 550,
    width: part[:width],
    height: 50,
    color: 'green'
  )
end

platforms = platforms_positions.map do |pos|
  Rectangle.new(x: pos[:x], y: pos[:y], width: pos[:w], height: pos[:h], color: 'brown')
end

acorn = acorn_positions.map do |pos|
  Image.new('assets/Treasure.png', x: pos[:x], y: pos[:y], width: 50, height: 50)
end

goal = Image.new('assets/Cave.png', x: 3000, y: 310, width: 300, height: 300)

speed_x = 0
speed_y = 0
gravity = 1
jump_strength = -16
on_ground = false
world_offset = 0
player_alive = true
game_won = false
score = 0

score_text = Text.new(
  "Score: #{score}",
  x: 10,
  y: 10,
  size: 30,
  color: 'white',
  z: 10
)

game_over_text = Text.new(
  "GAME OVER!",
  x: 200,
  y: 250,
  size: 60,
  color: [1.0, 0.0, 0.0, 0.0],
  z: 10
)

congratulations_text = Text.new(
  "",
  x: 100,
  y: 200,
  size: 50,
  color: 'green',
  z: 10
)

def collision?(obj1, obj2)
  obj1.x < obj2.x + obj2.width &&
    obj1.x + obj1.width > obj2.x &&
    obj1.y < obj2.y + obj2.height &&
    obj1.y + obj1.height > obj2.y
end

on_ground = false

update do
  next unless player_alive && !game_won

  on_ground = false
  speed_y += gravity unless (on_ground || speed_y>14)

  if player.x > 400 && speed_x > 0
    world_offset -= speed_x
    ground_rects.each { |ground| ground.x -= speed_x }
    platforms.each { |platform| platform.x -= speed_x }
    acorn.each { |point| point.x -= speed_x }
    goal.x -= speed_x
  else
    player.x += speed_x
  end

  player.y += speed_y
  # if player.y + player.height <= obj.y + 20
  #   on_ground = false
  # end

  (ground_rects + platforms).each do |obj|
    if collision?(player, obj)
      if player.y + player.height <= obj.y + 15
        player.y = obj.y - player.height
        speed_y = 0
        on_ground = true
      else
        on_ground = false
      end

      if player.y >= obj.y + obj.height - 20 && speed_y < 0
        player.y = obj.y + obj.height
        speed_y = 0
      end

      if player.x + player.width <= obj.x + 6 && speed_x > 0
        player.x = obj.x - player.width
      end

      if player.x >= obj.x + obj.width - 7 && speed_x < 0
        player.x = obj.x + obj.width
      end
    end
  end


  if !on_ground && player.y + player.height >= 590
    player_alive = false
    game_over_text.color = [1.0, 0.0, 0.0, 1.0]
    puts "Game Over!"
  end

  acorn.each do |point|
    if collision?(player, point)
      acorn.delete(point)
      point.remove
      score += 3
      score_text.text = "score: #{score}"
    end
  end

  if collision?(player, goal)
    game_won = true
    congratulations_text.text = "Congratulations! Your score: #{score}"
    puts "Congratulations! You won with a score #{score} acorns."
  end

  player.x = [0, [player.x, Window.width - player.width].min].max
end

on :key_held do |event|
  case event.key
  when "left"
    speed_x = -7
  when "right"
    speed_x = 7
  end
end

on :key_up do |event|
  case event.key
  when "left", "right"
    speed_x = 0
  end
end

on :key_down do |event|
  if event.key == "up" && on_ground
    speed_y = jump_strength
    on_ground = false
  end
end

show
