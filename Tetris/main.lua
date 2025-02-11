love.window.setTitle("Tetris")
love.window.setMode(300, 600)

local gridWidth, gridHeight = 10, 20
local cellSize = 30
local grid = {}
local shapes = {
    {{1, 1, 1}, {0, 1, 0}}, -- T-shape
    {{1, 1, 0}, {0, 1, 1}}, -- Z-shape
    {{0, 1, 1}, {1, 1, 0}}, -- S-shape
    {{1, 1}, {1, 1}},       -- O-shape
    {{1, 1, 1, 1}},         -- I-shape
}
local linesToClear = {}
local clearStep = 0
local clearSpeed = 0.05 
local isClearing = false
local currentPiece = {shape = shapes[love.math.random(#shapes)], x = 4, y = 0}
local fallTimer, fallSpeed = 0, 0.5
local saveDir = "save"
local savePath = saveDir .. "/savegame.txt"
function love.load()
    place_sound = love.audio.newSource("sounds/stack.mp3", "static")
    gameover_sound = love.audio.newSource("sounds/gameover.mp3", "static")
end
print("Press 's' to Save game state \nPress 'r' to restore last saved game state")

for y = 1, gridHeight do
    grid[y] = {}
    for x = 1, gridWidth do
        grid[y][x] = 0
    end
end

function love.draw()
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            if grid[y][x] == 1 then
                love.graphics.rectangle("fill", (x - 1) * cellSize, (y - 1) * cellSize, cellSize, cellSize)
            end
        end
    end
    for y, row in ipairs(currentPiece.shape) do
        for x, cell in ipairs(row) do
            if cell == 1 then
                love.graphics.rectangle("fill", (currentPiece.x + x - 2) * cellSize, (currentPiece.y + y - 1) * cellSize, cellSize, cellSize)
            end
        end
    end
end

function love.update(dt)
    fallTimer = fallTimer + dt
    if fallTimer >= fallSpeed then
        fallTimer = 0
        currentPiece.y = currentPiece.y + 1
        if checkCollision() then
            currentPiece.y = currentPiece.y - 1
            placePiece()
            clearLines()
            currentPiece = {shape = shapes[love.math.random(#shapes)], x = 4, y = 0}
            if checkCollision() then
                resetGame()
            end
        end
    end
end

function love.keypressed(key)
    if key == "left" then
        currentPiece.x = currentPiece.x - 1
        if checkCollision() then
            currentPiece.x = currentPiece.x + 1
        end
    elseif key == "right" then
        currentPiece.x = currentPiece.x + 1
        if checkCollision() then
            currentPiece.x = currentPiece.x - 1
        end
    elseif key == "down" then
        currentPiece.y = currentPiece.y + 1
        if checkCollision() then
            currentPiece.y = currentPiece.y - 1
        end
    elseif key == "up" then
        currentPiece.shape = rotatePiece(currentPiece.shape)
        if checkCollision() then
            currentPiece.shape = rotatePiece(currentPiece.shape, true)
        end
    elseif key == "s" then
        saveGame()
    elseif key == "r" then
        loadGame()
    end
end

function checkCollision()
    for y, row in ipairs(currentPiece.shape) do
        for x, cell in ipairs(row) do
            if cell == 1 then
                local boardX = currentPiece.x + x - 1
                local boardY = currentPiece.y + y
                if boardX < 1 or boardX > gridWidth or boardY > gridHeight or (boardY > 0 and grid[boardY][boardX] == 1) then
                    return true
                end
            end
        end
    end
    return false
end

function placePiece()
    for y, row in ipairs(currentPiece.shape) do
        for x, cell in ipairs(row) do
            if cell == 1 then
                local boardX = currentPiece.x + x - 1
                local boardY = currentPiece.y + y
                if boardY > 0 then
                    grid[boardY][boardX] = 1
                end
            end
        end
    end
    place_sound:play()
end

function clearLines()
    linesToClear = {} 
    for y = 1, gridHeight do
        local full = true
        for x = 1, gridWidth do
            if grid[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            table.insert(linesToClear, y)
        end
    end
    if #linesToClear > 0 then
        clearStep = gridWidth
        isClearing = true
    end
end

function updateClearLines(dt)
    if isClearing and clearStep > 0 then
        clearStep = clearStep - 1
        for _, y in ipairs(linesToClear) do
            grid[y][clearStep + 1] = 0
        end
        love.timer.sleep(clearSpeed)
    elseif isClearing and clearStep == 0 then
        finalizeClear()
    end
end

function finalizeClear()
    for _, y in ipairs(linesToClear) do
        table.remove(grid, y)
        table.insert(grid, 1, {})
        for x = 1, gridWidth do
            grid[1][x] = 0
        end
    end
    linesToClear = {}
    isClearing = false
end

function love.update(dt)
    updateClearLines(dt)
    fallTimer = fallTimer + dt
    if fallTimer >= fallSpeed and not isClearing then
        fallTimer = 0
        currentPiece.y = currentPiece.y + 1
        if checkCollision() then
            currentPiece.y = currentPiece.y - 1
            placePiece()
            clearLines()
            currentPiece = {shape = shapes[love.math.random(#shapes)], x = 4, y = 0}
            if checkCollision() then
                gameOver()
            end
        end
    end
end

function gameOver()
    print("GAME OVER!")
    gameover_sound:play()
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            grid[y][x] = 0
        end
    end
    currentPiece = {shape = shapes[love.math.random(#shapes)], x = 4, y = 0}
end
function resetGame()
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            grid[y][x] = 0
        end
    end
    currentPiece = {shape = shapes[love.math.random(#shapes)], x = 4, y = 0}
end

function rotatePiece(shape, reverse)
    local rotated = {}
    local rows, cols = #shape, #shape[1]
    for x = 1, cols do
        rotated[x] = {}
        for y = 1, rows do
            rotated[x][y] = 0
        end
    end
    for y = 1, rows do
        for x = 1, cols do
            if reverse then
                rotated[cols - x + 1][y] = shape[y][x]
            else
                rotated[x][rows - y + 1] = shape[y][x]
            end
        end
    end
    return rotated
end

function saveGame()
    if not love.filesystem.getInfo(saveDir) then
        love.filesystem.createDirectory(saveDir)
    end
    local file = love.filesystem.newFile(savePath, "w")
    if not file then
        print("Error during opening save file")
        return
    end
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            file:write(grid[y][x] .. " ")
        end
        file:write("\n")
    end
    file:write(currentPiece.x .. " " .. currentPiece.y .. "\n")
    for y = 1, #currentPiece.shape do
        for x = 1, #currentPiece.shape[y] do
            file:write(currentPiece.shape[y][x] .. " ")
        end
        file:write("\n")
    end
    file:close()
    print("Game saved")
end

function loadGame()
    if not love.filesystem.getInfo(savePath) then
        print("There is no save file")
        return
    end
    local file = love.filesystem.read(savePath)
    if not file then
        print("Error during opening save file!")
        return
    end
    local lines = {}
    for line in file:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    local index = 1
    for y = 1, gridHeight do
        grid[y] = {}
        local values = {}
        for value in lines[index]:gmatch("%S+") do
            table.insert(values, tonumber(value))
        end
        for x = 1, gridWidth do
            grid[y][x] = values[x]
        end
        index = index + 1
    end
    local pieceData = {}
    for value in lines[index]:gmatch("%S+") do
        table.insert(pieceData, tonumber(value))
    end
    currentPiece.x = pieceData[1]
    currentPiece.y = pieceData[2]
    index = index + 1
    local shape = {}
    while index <= #lines do
        local row = {}
        for value in lines[index]:gmatch("%S+") do
            table.insert(row, tonumber(value))
        end
        table.insert(shape, row)
        index = index + 1
    end
    currentPiece.shape = shape
    print("Save loaded")
end