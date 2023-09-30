public boolean circleCircle(Circle c1, Circle c2) {
  return (c1.pos.distanceTo(c2.pos) < (c1.r + c2.r));
}

public boolean RectRect(Rect b1, Rect b2) {
  if (abs(b1.pos.x - b2.pos.x) > (b1.w + b2.w)/2.0) return false;
  if (abs(b1.pos.y - b2.pos.y) > (b1.h + b2.h)/2.0) return false;
  return true;
}

// checks if two points are on the same side of the given line l
public boolean sameSide(Line l, Vec2 p1, Vec2 p2) {
  float cp1 = cross(l.p2.minus(l.p1), p1.minus(l.p1));
  float cp2 = cross(l.p2.minus(l.p1), p2.minus(l.p1));
  return cp1*cp2 >= 0;
}

public boolean lineLine(Line l1, Line l2) {
  if (sameSide(l1, l2.p1, l2.p2)) return false;
  if (sameSide(l2, l1.p1, l1.p2)) return false;
  return true;
}

//Adapted from CCD LineCircles Exercise
public boolean circleLine(Circle circle, Line l) {

  Vec2 center = circle.pos;
  float r = circle.r;
  Vec2 l_start = l.p1;
  Vec2 l_dir = l.p2.minus(l_start).normalized(); //should be normalized
  float l_len = l.p2.distanceTo(l.p1);

  //Compute W - a displacement vector pointing from the start of the line segment to the center of the circle
  Vec2 toCircle = center.minus(l_start);

  //Solve quadratic equation for intersection point (in terms of l_dir and toCircle)
  float a = 1.0;  //Lenght of l_dir (we noramlized it)
  float b = -2*dot(l_dir, toCircle); //-2*dot(l_dir,toCircle)
  float c = toCircle.lengthSqr() - (r)*(r); //different of squared distances

  float d = b*b - 4*a*c; //discriminant

  if (d >=0 ) {
    //If d is positive we know the line is colliding, but we need to check if the collision line within the line segment
    //  ... this means t will be between 0 and the lenth of the line segment
    float t1 = (-b - sqrt(d))/(2.0*a);
    float t2 = (-b + sqrt(d))/(2.0*a);
    //println(hit.t,t1,t2);
    if (t1 > 0 && t1 < l_len) {
      return true;
    } else if (t2 > 0 && t2 < l_len) {
      return true;
    }
  }
  return false;
}

public boolean lineRect(Line l, Rect b) {
  //first check if either point (or both) of line is in the box (we will count this as a collision)
  float halfW = b.w/2.0;
  float halfH = b.h/2.0;

  if (abs(l.p1.x - b.pos.x) < halfW && abs(l.p1.y - b.pos.y) < halfH) return true;
  if (abs(l.p2.x - b.pos.x) < halfW && abs(l.p2.y - b.pos.y) < halfH) return true;

  //corner points of box
  // top left, top right, bottom left, bottom right, in order
  Vec2 tl = new Vec2(b.pos.x - halfW, b.pos.y + halfH);
  Vec2 tr = new Vec2(b.pos.x + halfW, b.pos.y + halfH);
  Vec2 bl = new Vec2(b.pos.x - halfW, b.pos.y - halfH);
  Vec2 br = new Vec2(b.pos.x + halfW, b.pos.y - halfH);

  Line left = new Line(tl, bl);
  Line right = new Line(tr, br);
  Line top = new Line(tl, tr);
  Line bottom = new Line(bl, br);

  boolean lhit = lineLine(l, left);
  boolean rhit = lineLine(l, right);
  boolean thit = lineLine(l, top);
  boolean bhit = lineLine(l, bottom);

  return (lhit || rhit || thit || bhit);
}

//helper function for circleBox collision testing
//Source from ChatGPT
public float clamp(float val, float min, float max) {
  if (val < min) val = min;
  if (val > max) val = max;
  return val;
}

public boolean circleRect(Circle c, Rect b) {
  //if circle pos is too far return false right away
  if (abs(c.pos.x - b.pos.x) > (b.w/2 + c.r)) return false;
  if (abs(c.pos.y - b.pos.y) > (b.h/2 + c.r)) return false;

  float x = clamp(c.pos.x, b.pos.x - b.w/2.0, b.pos.x + b.w/2.0);
  float y = clamp(c.pos.y, b.pos.y - b.h/2.0, b.pos.y + b.h/2.0);

  Vec2 closest = new Vec2(x, y);

  return (closest.distanceTo(c.pos) < c.r);
}

//Checks all shapes in the scene through a provided GeometricShape array which should represent all primitives in the scene
//returns an int array with the ORDERED list of collision IDs
public int[] sceneProcessing(GeometricShape shapes[]) {
  for (int i = 0; i < shapes.length; i++) {
    for (int j = i+1; j < shapes.length; j++) {
      GeometricShape shape1 = shapes[i];
      GeometricShape shape2 = shapes[j];

      if (!(shape1.hit && shape2.hit)) { //if both are hit no need to check again
        if (shape1.type == 0) { // s1 = circle
          if (shape2.type == 0) {
            Circle s1 = (Circle) shape1.shape;
            Circle s2 = (Circle) shape2.shape;
            boolean result = circleCircle(s1, s2);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit; //keeps it marked true if we know there is already a collision
          } else if (shape2.type == 1) {
            Circle s1 = (Circle) shape1.shape;
            Line s2 = (Line) shape2.shape;
            boolean result = circleLine(s1, s2);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          } else if(shape2.type == 2){
            Circle s1 = (Circle) shape1.shape;
            Rect s2 = (Rect) shape2.shape;
            boolean result = circleRect(s1, s2);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          }
        } else if (shape1.type == 1) { // s1 = line
          if (shape2.type == 0) {
            Line s1 = (Line) shape1.shape;
            Circle s2 = (Circle) shape2.shape;
            boolean result = circleLine(s2, s1);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          } else if (shape2.type == 1) {
            Line s1 = (Line) shape1.shape;
            Line s2 = (Line) shape2.shape;
            boolean result = lineLine(s1, s2);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          } else if(shape2.type == 2){
            Line s1 = (Line) shape1.shape;
            Rect s2 = (Rect) shape2.shape;
            boolean result = lineRect(s1, s2);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          }
        } else if(shape1.type == 2){ // s1 = Rect
          if (shape2.type == 0) {
            Rect s1 = (Rect) shape1.shape;
            Circle s2 = (Circle) shape2.shape;
            boolean result = circleRect(s2, s1);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          } else if (shape2.type == 1) {
            Rect s1 = (Rect) shape1.shape;
            Line s2 = (Line) shape2.shape;
            boolean result = lineRect(s2, s1);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          } else if(shape2.type == 2){
            Rect s1 = (Rect) shape1.shape;
            Rect s2 = (Rect) shape2.shape;
            boolean result = RectRect(s1, s2);
            shape1.hit = result || shape1.hit;
            shape2.hit = result || shape2.hit;
          }
        }
      }
    }
  }

  int result[] = new int[shapes.length+1];
  int resultSize = 0; //size of result array
  for (int i = 0; i < shapes.length; i++) {
    if (shapes[i].hit) {
      result[resultSize] = shapes[i].ID;
      resultSize++;
    }
  }
  result[resultSize] = -1; //to indicate end of list;
  //println(result);
  return result;
}
