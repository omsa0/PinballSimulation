import shapes3d.*; //<>//
import shapes3d.contour.*;
import shapes3d.org.apache.commons.math.*;
import shapes3d.org.apache.commons.math.geometry.*;
import shapes3d.path.*;
import shapes3d.utils.*;

boolean st = false;
int MAXOBJ = 25;
int MAXBALLS = 8;
int MAXL = 13;
String[] planets = {"earth.jpg", "jupiter.jpg", "mars.jpg", "mercury.jpg", "neptune.jpg", "saturn.jpg", "uranus.jpg", "venus.jpg"};

Circle[] obstacles = new Circle[MAXOBJ];
Line[] lines = new Line[MAXL];
Circle[] balls = new Circle[MAXBALLS];
Ellipsoid[] ellipsoids = new Ellipsoid[MAXBALLS+MAXOBJ]; //separate list for all spheres combined, drawing is easier this way
Vec2[] vels = new Vec2[MAXBALLS];
Vec2 acl; //acceleration

float COR = 0.7; // Coefficient of Restitution
float m = 100; //mass for all balls, they are all equal
PImage img;
float terminalVelocity = 1500;

void setup() {
  size(1000, 1000, P3D);
  generateObstacles();
  generateBalls();
  generateLines();
  generate3DModels();
  img = loadImage("../img/bg2.jpg");
  acl = new Vec2(0, height*2);
}

void generateObstacles() {
  obstacles[0] = new Circle(new Vec2(50, 50), 100);
  for (int i = 1; i < MAXOBJ; i++) {
    Circle c = new Circle(new Vec2(random(width - width/8 - height/25), random(height-height/5)+height/5), random(height/100, height/25));
    obstacles[i] = c;
  }
}

void generateBalls() {
  for (int i = 0; i < MAXBALLS; i++) {
    vels[i] = new Vec2(random(width) - width/2, 0);
    balls[i] = new Circle(new Vec2(random(3*width/4) + width/4, 0), height*0.015);
  }
}

void generateLines() {
  //constellations - aries and big dipper
  lines[0] = new Line(new Vec2(width/8, height/5), new Vec2(283, 160));
  lines[1] = new Line(new Vec2(7*width/8, height/5), new Vec2(4*width/5, 3*height/5));
  lines[2] = new Line(new Vec2(width/5, 4*height/5), new Vec2(2*width/5, 3.5*height/5));
  lines[3] = new Line(new Vec2(3*width/5, 3.5*height/5), new Vec2(4*width/5, 3*height/5));
  lines[4] = new Line(new Vec2(2*width/5, 3.5*height/5), new Vec2(453, 690));
  lines[5] = new Line(new Vec2(453, 690), new Vec2(467, 707));
  lines[6] = new Line(new Vec2(2*width/5, 3.5*height/5), new Vec2(453, 690));
  lines[7] = new Line(new Vec2(283, 160), new Vec2(375, 180));
  lines[8] = new Line(new Vec2(375, 180), new Vec2(462, 208));
  lines[9] = new Line(new Vec2(462, 208), new Vec2(645, 154));
  lines[10] = new Line(new Vec2(645, 154), new Vec2(654, 298));
  lines[11] = new Line(new Vec2(654, 298), new Vec2(517, 335));
  lines[12] = new Line(new Vec2(517, 335), new Vec2(462, 208));
}

void generate3DModels() {
  Circle c = obstacles[0];
  ellipsoids[0] = new Ellipsoid(c.r, c.r, c.r, 50, 25);
  ellipsoids[0].texture(this, "../img/sun.jpg").drawMode(S3D.TEXTURE);
  int i = 1;
  for (; i < MAXOBJ; i++) {
    c = obstacles[i];
    ellipsoids[i] = new Ellipsoid(c.r, c.r, c.r, 50, 25);
    String texture = "../img/" + planets[floor(random(planets.length))];
    ellipsoids[i].texture(this, texture).drawMode(S3D.TEXTURE);
  }
  for (; i < MAXBALLS+MAXOBJ; i++) {
    c = balls[i-MAXOBJ];
    ellipsoids[i] = new Ellipsoid(c.r, c.r, c.r, 50, 25);
    ellipsoids[i].texture(this, "../img/asteroid.jpg").drawMode(S3D.TEXTURE);
  }
}

void update(float dt) {
  for (int i = 0; i < MAXBALLS; i++) {

    // --------------
    // move balls

    Vec2 vel = vels[i];
    Circle ball = balls[i];
    vel.add(acl.times(dt));
    if (vel.y >= terminalVelocity) {
      vel.y = terminalVelocity;
    }
    //println(vel);
    ball.pos.add(vel.times(dt));

    // --------------
    // Wall Bounce

    if (ball.pos.y > height - ball.r) {
      ball.pos.y = height - ball.r;
      vel.y *= -COR;
    }
    if (ball.pos.y < ball.r) {
      ball.pos.y = ball.r;
      vel.y *= -COR;
    }
    if (ball.pos.x > width - ball.r) {
      ball.pos.x = width - ball.r;
      vel.x *= -COR;
    }
    if (ball.pos.x < ball.r) {
      ball.pos.x = ball.r;
      vel.x *= -COR;
    }

    // --------------
    // Obstacle Collision

    for (int j = 0; j < MAXOBJ; j++) {
      Circle obs = obstacles[j];
      boolean hit = circleCircle(ball, obs);
      if (hit) {
        Vec2 normal = (ball.pos.minus(obs.pos)).normalized();
        ball.pos = obs.pos.plus(normal.times(obs.r+ball.r));
        Vec2 velNormal = normal.times(dot(vel, normal));
        vel.subtract(velNormal.times(1 + COR));
      }
    }

    // --------------
    // Ball-Ball

    for (int j = i+1; j < MAXBALLS; j++) {
      Circle ball2 = balls[j];
      Vec2 vel2 = vels[j];
      Vec2 delta = ball.pos.minus(ball2.pos);
      float dist = delta.length();
      if (dist < ball.r + ball2.r) {
        // Move balls out of collision
        float overlap = 0.5f * (dist - ball.r - ball2.r);
        ball.pos.subtract(delta.normalized().times(overlap).times(1.008));
        ball2.pos.add(delta.normalized().times(overlap));


        // Collision
        Vec2 dir = delta.normalized();
        float v1 = dot(vel, dir);
        float v2 = dot(vel2, dir);
        float m1 = m; //set mass, same for all balls
        float m2 = m;
        // Pseudo-code for collision response
        float new_v1 = (m1 * v1 + m2 * v2 - m2 * (v1 - v2) * COR) / (m1 + m2);
        float new_v2 = (m1 * v1 + m2 * v2 - m1 * (v2 - v1) * COR) / (m1 + m2);
        Vec2 changev1 = dir.times(new_v1-v1);
        Vec2 changev2 = dir.times(new_v2-v2);
        vel.add(changev1); // Add the change in velocity along the collision axis
        vel2.add(changev2); //  ... collisions only affect velocity along this axis!
      }
    }

    // --------------
    // Ball-Line

    for (int j = 0; j < MAXL; j++) {
      Line l = lines[j];
      boolean hit = circleLine(ball, l);
      if (hit) {
        Vec2 dir = l.p2.minus(l.p1);
        Vec2 dir_norm = dir.normalized();
        Vec2 normal = new Vec2(-dir_norm.y, dir_norm.x);
        float impactPosition = dot(ball.pos.minus(l.p1), dir_norm);

        //finding closest point on line segment
        Vec2 closest;
        if (impactPosition < 0) {
          closest = l.p1;
        } else if (impactPosition > dir.length()) {
          closest = l.p2;
        } else {
          closest = l.p1.plus(dir_norm.times(impactPosition));
        }

        //reflect
        Vec2 ballDir = ball.pos.minus(closest).normalized();
        ball.pos = closest.plus(ballDir.times(ball.r));
        Vec2 vNorm = normal.times(dot(vel, normal));
        vel.subtract(vNorm.times(1 + COR));
      }
    }
  }
}

void keyPressed() { //reset sim
  if (key == 'r') {
    generateBalls();
    generateObstacles();
    generateLines();
    generate3DModels();
    println("reset simulation");
  }
  //if (key == 't') { //only for debugging, dont use
  //  st = !st;
  //}
}

void mouseClicked() {
  println(mouseX, mouseY);
}

void draw() {
  background(img);
  float dt = 1.0/frameRate;
  update(dt);
  println(frameRate);

  //Circle sun = obstacles[0];
  lightFalloff(1, 0, 0);
  spotLight(255, 255, 255, 110, 110, 0, 1, 0, 0, PI/2, 2);
  spotLight(255, 255, 255, 110, 110, 0, 0, 1, 0, PI/2, 2);
  spotLight(255, 255, 255, 150, 150, 220, 0, 0, -1, PI/2, 2);
  ambientLight(80, 80, 80);

  stroke(200, 200, 220);
  strokeWeight(1);
  for (int i = 0; i < MAXL; i++) {
    Line l = lines[i];
    line(l.p1.x, l.p1.y, l.p2.x, l.p2.y);
  }

  noStroke();
  int j = 0;
  for (; j < MAXOBJ; j++) {
    pushMatrix();
    Ellipsoid e = ellipsoids[j];
    Circle c = obstacles[j];
    e.rotateBy(0, dt, 0);
    translate(c.pos.x, c.pos.y, 0);
    e.draw(getGraphics());
    popMatrix();
  }
  for (; j < MAXBALLS+MAXOBJ; j++) {
    pushMatrix();
    Ellipsoid e = ellipsoids[j];
    Circle c = balls[j-MAXOBJ];
    translate(c.pos.x, c.pos.y, 0);
    e.draw(getGraphics());
    popMatrix();
  }

  if (st) { //debugging only
    // --------------
    //drawing obstacles
    fill(255, 0, 0);
    for (int i = 0; i < MAXOBJ; i++) {
      Circle c = obstacles[i];
      translate(c.pos.x, c.pos.y, 0);
      sphere(c.r);
      translate(-c.pos.x, -c.pos.y, 0);
    }

    // --------------
    //drawing balls
    noStroke();
    fill(0, 255, 0);
    for (int i = 0; i < MAXBALLS; i++) {
      Circle ball = balls[i];
      translate(ball.pos.x, ball.pos.y, 0);
      sphere(ball.r);
      translate(-ball.pos.x, -ball.pos.y, 0);
    }
  }
}
