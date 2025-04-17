// Game States
final int STATE_START = 0;
final int STATE_COUNTDOWN = 1;
final int STATE_PLAY = 2;
final int STATE_GAMEOVER = 3;
int gameState = STATE_START;

int countdownStartTime;
int countdown = 3;

ArrayList<Enemy> enemies;
ArrayList<Bullet> bullets;
ArrayList<Item> items;
Player player;
int score = 0;
int highScore = 0;

boolean moveLeft = false;
boolean moveRight = false;
boolean moveUp = false;
boolean moveDown = false;

PImage[] backgrounds;
PImage meteorImg, playerImg, lifeImg;
int currentBGIndex = 0;
int bgCount = 3;

boolean invincible = false;
int invincibleStartTime = 0;
int invincibleDuration = 3000;

int lastShotTime = 0;
int shotCooldown = 500;
int enemySpeed = 4;
int itemDropInterval = 180;

void setup() {
  size(600, 800);
  enemies = new ArrayList<Enemy>();
  bullets = new ArrayList<Bullet>();
  items = new ArrayList<Item>();
  player = new Player();

  backgrounds = new PImage[bgCount];
  for (int i = 0; i < bgCount; i++) {
    backgrounds[i] = loadImage("data/bg" + i + ".PNG");
  }

  meteorImg = loadImage("data/meteor.png");
  playerImg = loadImage("data/player.png");
  lifeImg = loadImage("data/life.png");

  loadHighScore();
}

void draw() {
  switch (gameState) {
    case STATE_START:
      drawStartScreen();
      break;
    case STATE_COUNTDOWN:
      drawCountdown();
      break;
    case STATE_PLAY:
      drawGame();
      break;
    case STATE_GAMEOVER:
      drawGameOver();
      break;
  }
}

void drawStartScreen() {
  background(0);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("SPACE SHOOTER", width / 2, height / 2 - 50);
  textSize(24);
  text("Press ENTER to Start", width / 2, height / 2 + 20);
  text("High Score: " + highScore, width / 2, height / 2 + 60);
}

void drawCountdown() {
  background(0);
  int elapsed = millis() - countdownStartTime;
  int secondsLeft = 3 - elapsed / 1000;
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(64);
  text(secondsLeft > 0 ? str(secondsLeft) : "GO!", width / 2, height / 2);
  if (elapsed >= 3000) {
    gameState = STATE_PLAY;
  }
}

void drawGameOver() {
  background(0);
  fill(255, 0, 0);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("GAME OVER", width / 2, height / 2 - 80);

  fill(255);
  textSize(24);
  text("Score: " + score, width / 2, height / 2 - 30);
  text("High Score: " + highScore, width / 2, height / 2);
  text("Press R to Restart or E to Exit", width / 2, height / 2 + 40);
}

void drawGame() {
  currentBGIndex = (frameCount / 10) % bgCount;
  image(backgrounds[currentBGIndex], 0, 0, width, height);

  // Shooting logic for automatic shooting
  if (millis() - lastShotTime > player.shotSpeed) {
    player.shoot();
    lastShotTime = millis();
  }

  enemySpeed = 4 + (score / 30);
  int enemyCount = 1 + (score / 30);
  if (frameCount % 60 == 0) {
    for (int i = 0; i < enemyCount; i++) {
      enemies.add(new Enemy(enemySpeed));
    }
  }

  if (frameCount % itemDropInterval == 0) {
    if (random(1) < 90) {
      items.add(new Item());
    }
  }

  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    if (b.offscreen()) bullets.remove(i);
  }

  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();

    for (int j = bullets.size() - 1; j >= 0; j--) {
      Bullet b = bullets.get(j);
      if (e.hits(b)) {
        enemies.remove(i);
        bullets.remove(j);
        score++;
        break;
      }
    }

    if (!invincible && e.hitsPlayer(player)) {
      enemies.remove(i);
      player.decreaseLives();
      if (player.currentLives <= 0) {
        if (score > highScore) {
          highScore = score;
          saveHighScore();
        }
        gameState = STATE_GAMEOVER;
        return;
      } else {
        invincible = true;
        invincibleStartTime = millis();
      }
    }

    if (i < enemies.size() && e.offscreen()) {
      enemies.remove(i);
    }
  }

  for (int i = items.size() - 1; i >= 0; i--) {
    Item item = items.get(i);
    item.update();
    item.display();
    if (item.hits(player)) {
      items.remove(i);
      item.applyEffect(player);
    }
  }

  if (moveLeft) player.move(-1, 0);
  if (moveRight) player.move(1, 0);
  if (moveUp) player.move(0, -1);
  if (moveDown) player.move(0, 1);

  if (invincible && millis() - invincibleStartTime > invincibleDuration) {
    invincible = false;
  }

  if (player.canSpreadShot && millis() - player.spreadShotStartTime > player.spreadShotDuration) {
    player.canSpreadShot = false;
  }

  player.display();

  fill(255);
  textSize(24);
  textAlign(LEFT, TOP);
  text("Score: " + score, 10, 10);
  text("High: " + highScore, 10, 40);

  for (int i = 0; i < player.currentLives; i++) {
    image(lifeImg, 10 + i * 40, 70, 30, 30);
  }
}

void keyPressed() {
  if (gameState == STATE_START && key == ENTER) {
    countdownStartTime = millis();
    gameState = STATE_COUNTDOWN;
    return;
  }

  if (gameState == STATE_GAMEOVER) {
    if (key == 'r' || key == 'R') {
      restartGame();
    } else if (key == 'e' || key == 'E' || keyCode == ESC) {
      exit();
    }
    return;
  }

  if (gameState != STATE_PLAY) return;

  if (keyCode == LEFT) moveLeft = true;
  if (keyCode == RIGHT) moveRight = true;
  if (keyCode == UP) moveUp = true;
  if (keyCode == DOWN) moveDown = true;
}

void keyReleased() {
  if (keyCode == LEFT) moveLeft = false;
  if (keyCode == RIGHT) moveRight = false;
  if (keyCode == UP) moveUp = false;
  if (keyCode == DOWN) moveDown = false;
}

void restartGame() {
  score = 0;
  enemies.clear();
  bullets.clear();
  items.clear();
  player = new Player();
  gameState = STATE_START;
}

void saveHighScore() {
  String[] hs = { str(highScore) };
  saveStrings("highscore.txt", hs);
}

void loadHighScore() {
  String[] hs = loadStrings("highscore.txt");
  if (hs != null && hs.length > 0) {
    highScore = int(hs[0]);
  }
}
class Player {
  float x, y;
  float w = 60, h = 60;
  float speed = 6;
  int maxLives = 3;
  int currentLives = maxLives;
  int shotSpeed = 500;
  boolean canSpreadShot = false;
  int spreadShotStartTime = 0;
  int spreadShotDuration = 15000;

  Player() {
    x = width / 2 - w / 2;
    y = height - 80;
  }

  void move(int dx, int dy) {
    x += dx * speed;
    y += dy * speed;
    x = constrain(x, 0, width - w);
    y = constrain(y, 0, height - h);
  }

  void display() {
    if (invincible && (millis() / 100) % 2 == 0) return;
    image(playerImg, x, y, w, h);
  }

  void increaseLives() {
    if (currentLives < maxLives) currentLives++;
  }

  void decreaseLives() {
    currentLives--;
  }

  void increaseShotSpeed() {
    shotSpeed = max(100, shotSpeed - 100);
  }

  void activateSpreadShot() {
    canSpreadShot = true;
    spreadShotStartTime = millis();
  }

  void shoot() {
    if (canSpreadShot) {
      bullets.add(new Bullet(x + w / 2 - 15, y));
      bullets.add(new Bullet(x + w / 2, y));
      bullets.add(new Bullet(x + w / 2 + 15, y));
    } else {
      bullets.add(new Bullet(x + w / 2, y));
    }
  }
}

class Bullet {
  float x, y;
  float r = 5;
  float speed = 10;

  Bullet(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    y -= speed;
  }

  void display() {
    fill(255, 255, 0);
    ellipse(x, y, r * 2, r * 2);
  }

  boolean offscreen() {
    return y < 0;
  }
}

class Enemy {
  float x, y;
  float r = 25;
  float speed;

  Enemy(float speed) {
    this.speed = speed;
    x = random(r, width - r);
    y = -r;
  }

  void update() {
    y += speed;
  }

  void display() {
    image(meteorImg, x - r, y - r, r * 2, r * 2);
  }

  boolean hits(Bullet b) {
    float d = dist(x, y, b.x, b.y);
    return d < r + b.r;
  }

  boolean hitsPlayer(Player p) {
    float px = p.x + p.w / 2;
    float py = p.y + p.h / 2;
    float d = dist(x, y, px, py);
    return d < r + max(p.w, p.h) / 2;
  }

  boolean offscreen() {
    return y > height + r;
  }
}

class Item {
  float x, y;
  float r = 20;
  int type;
  PImage img;

  static final int HP = 0;
  static final int SPEED = 1;
  static final int SPREAD = 2;

  Item() {
    x = random(width);
    y = -r;
    type = int(random(3));

    if (type == HP) {
      img = loadImage("data/item_hp.png");
    } else if (type == SPEED) {
      img = loadImage("data/item_rapid.png");
    } else if (type == SPREAD) {
      img = loadImage("data/item_spread.png");
    }
  }

  void update() {
    y += 3;
  }

  void display() {
    image(img, x - r, y - r, r * 2, r * 2);
  }

  boolean hits(Player p) {
    float d = dist(x, y, p.x + p.w / 2, p.y + p.h / 2);
    return d < r + max(p.w, p.h) / 2;
  }

  void applyEffect(Player p) {
    if (type == HP) {
      p.increaseLives();
    } else if (type == SPEED) {
      p.increaseShotSpeed();
    } else if (type == SPREAD) {
      p.activateSpreadShot();
    }
  }
}
