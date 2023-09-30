public abstract class Primitive {
}

public class Circle extends Primitive {
  public Vec2 pos;
  public float r;

  public Circle(Vec2 pos, float r) {
    this.pos = pos;
    this.r = r;
  }
}

public class Rect extends Primitive {
  public Vec2 pos;
  public float w;
  public float h;

  public Rect(Vec2 pos, float w, float h) {
    this.w = w;
    this.h = h;
    this.pos = pos;
  }
}

public class Line extends Primitive {
  public Vec2 p1;
  public Vec2 p2;

  public Line(Vec2 p1, Vec2 p2) {
    this.p1 = p1;
    this.p2 = p2;
  }
}

public class GeometricShape {
  Primitive shape;
  int type; //0 - Circle, 1 - Line, 2 - Box
  int ID;
  boolean hit = false;

  public GeometricShape(Primitive shape, int type, int ID) {
    this.shape = shape;
    this.type = type;
    this.ID = ID;
  }
}
