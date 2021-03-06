package echo.util;

import hxmath.math.Vector2;

using Math;

class Ext {
  /**
   * Checks if two Floats are "equal" within the margin of error defined by the `diff` argument.
   * @param a The first Float to check for equality.
   * @param b The first Float to check for equality.
   * @param diff The margin of error to check by.
   * @return returns true if the floats are equal (within the defined margin of error)
   */
  public static inline function equals(a:Float, b:Float, diff:Float = 0.00001):Bool {
    return Math.abs(a - b) <= diff;
  }
  /**
   * Normalizes a `Vector2` (in place) to represent the closest cardinal direction (Up, Down, Left, or Right).
   * @param normal The `Vector2` to modify.
   * @return the modified `Vector2`
   */
  public static function square_normal(normal:Vector2):Vector2 {
    var len = normal.length;
    var dot_x = normal * Vector2.xAxis;
    var dot_y = normal * Vector2.yAxis;
    if (dot_x.abs() > dot_y.abs()) dot_x > 0 ? normal.set(1, 0) : normal.set(-1, 0);
    else dot_y > 0 ? normal.set(0, 1) : normal.set(0, -1);
    normal.normalizeTo(len);
    return normal;
  }
  
  public static function dispose_bodies(arr:Array<Body>):Array<Body> {
    for (body in arr) body.dispose();
    return arr;
  }
}
