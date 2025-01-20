const config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 3000 },
            debug: false
        }
    },
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

const game = new Phaser.Game(config);
let player;
let platforms;
let cursors;
let gameOver = false;
let camera;
let finishLine;
let points;
let score = 0;
let scoreText;
const holes = [3, 6, 7, 14, 15, 16, 17, 21, 24, 28, 31, 40, 41, 43, 47, 51, 52, 54, 55, 57, 58, 63, 64, 65, 67, 68, 69, 70, 71, 74];
const acornPositions = [
    { x: 0, y: 200 },
    { x: 400, y: 480 },
    { x: 700, y: 480 },
    { x: 1050, y: 200 },
    { x: 1530, y: 200 },//
    { x: 2000, y: 480 },
    { x: 2400, y: 480 },
    { x: 2960, y: 480 },
    { x: 3360, y: 480 },
    { x: 3520, y: 480 },
    { x: 4240, y: 480 },
    { x: 4480, y: 200 },
    { x: 4800, y: 480 },
    { x: 5280, y: 200 },
    { x: 5760, y: 480 },
    { x: 5860, y: 200 }
];
const wall_1 = [10, 29, 35, 39, 45, 62, 68];
const wall_2 = [3, 4, 5, 8, 9, 10, 24, 30, 35, 47, 53, 61, 74];
const wall_3 = [0, 10, 13, 14, 15, 19, 20, 24, 25, 26, 31, 36, 37, 38, 39, 44, 45, 47, 50, 53, 56, 59, 60, 69, 73, 74];

function preload() {
    this.load.image('sky', 'https://labs.phaser.io/assets/skies/sky4.png');
    this.load.image('brick', 'Brick80.png');    //80x80
    this.load.image('ground', 'Grass80.png');   //80x80
    this.load.image('player', 'Boar60.png');    //60x60
    this.load.image('finish', 'Cave.png');      //360 x 360
    this.load.image('acorn', 'Treasure.png');   //112 x 80
}

function create() {
    this.add.image(400, 300, 'sky').setScrollFactor(0);
    platforms = this.physics.add.staticGroup();
    for (let i = 0; i < 85; i++) {
        if (!holes.includes(i)) { 
            platforms.create(80 * i, 560, 'ground');
        }
        if (wall_1.includes(i)) { 
            platforms.create(80 * i, 480, 'brick');
        }
        if (wall_2.includes(i)) {
            platforms.create(80 * i, 400, 'brick');
        }
        // if (i % 5 === 0) {
        //     platforms.create(80 * i, 20, 'brick');
        // }
        if (wall_3.includes(i)) {
            platforms.create(80 * i, 320, 'brick');
        }
    }
    player = this.physics.add.sprite(100, 450, 'player');
    player.setCollideWorldBounds(true);
    this.physics.add.collider(player, platforms);
    //
    finishLine = this.physics.add.sprite(6300, 420, 'finish');
    finishLine.body.allowGravity = false;
    finishLine.setImmovable(true);
    this.physics.add.overlap(player, finishLine, reachFinish, null, this);
    //
    points = this.physics.add.group();
    acornPositions.forEach(pos => {
        const acorn = points.create(pos.x, pos.y, 'acorn');
        acorn.setBounceY(Phaser.Math.FloatBetween(0.4, 0.8));
    });
    this.physics.add.collider(points, platforms);
    this.physics.add.overlap(player, points, collectPoints, null, this);
    scoreText = this.add.text(16, 16, 'Score: 0', { fontSize: '32px', fill: '#ffffff' });
    scoreText.setScrollFactor(0);
    //
    endText = this.add.text(400, 300, '', { fontSize: '48px', fill: '#ffffff' });
    endText.setOrigin(0.5);
    endText.setScrollFactor(0);
    endText.setVisible(false);
    cursors = this.input.keyboard.createCursorKeys();
    this.cameras.main.startFollow(player, true, 0.1, 0.1);
    this.cameras.main.setBounds(0, 0, 6500, 600);
    this.physics.world.setBounds(0, 0, 6500, 600);
    }
    
    function update() {
        if (gameOver) {
            return;
        }
        if (cursors.left.isDown) {
            if (player.x > this.cameras.main.scrollX) {
                player.setVelocityX(-300);
            } else {
                player.setVelocityX(0);
            }
        } else if (cursors.right.isDown) {
            player.setVelocityX(300);
        } else {
            player.setVelocityX(0);
        }
        if (cursors.up.isDown && player.body.touching.down) {
            player.setVelocityY(-1100);
        }
        if (player.y > 550) {
            this.physics.pause();
            player.setTint(0xff0000);
            gameOver = true;
            displayEndText('Game Over', score);
        }
    }
    
function reachFinish(player, finishLine) {
    this.physics.pause();
    player.setTint(0x00ff00);
    gameOver = true;
    displayEndText('Congratulations!\nFinal Score: ' + score);
}

function collectPoints(player, acorn) {
    acorn.disableBody(true, true);
    score += 3;
    scoreText.setText('Score: ' + score);
}

function displayEndText(message) {
    endText.setText(message);
    endText.setVisible(true);
}
