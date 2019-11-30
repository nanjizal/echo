package echo;

import haxe.ds.Either;
import echo.data.Data.IntersectionData;
import hxmath.math.Vector2;
import echo.Body;
import echo.Listener;
import echo.Collisions;
import echo.World;
import echo.data.Options;
import echo.shape.Rect;
import echo.util.BodyOrBodies;

@:expose
/**
 * Echo holds helpful utility methods to help streamline the creation and management of Physics Simulations.
 */
class Echo {
  static var listeners:Listeners = new Listeners();
  /**
   * Shortcut for creating a new `World`
   * @param options Options for the new `World`
   * @return World
   */
  public static function start(options:WorldOptions):World return new World(options);
  /**
   * Shortcut for creating a new `Body` and adding it to the `World`
   * @param world the `World` to add the `Body` to
   * @param options Options for the new `Body`
   * @return Body
   */
  public static function make(world:World, options:BodyOptions):Body return world.add(new Body(options));
  /**
   * Shortcut for creating a new `Listener` for a set of Bodies in the `World`.
   * @param world the `World` to add the `Listener` to
   * @param a The first `Body` or Array of Bodies to collide against
   * @param b The second `Body` or Array of Bodies to collide against
   * @param options Options to define the Listener's behavior
   * @return Listener
   */
  public static function listen(world:World, ?a:BodyOrBodies, ?b:BodyOrBodies, ?options:ListenerOptions):Listener {
    if (a == null) return b == null ? world.listeners.add(world.members, world.members, options) : world.listeners.add(b, b, options);
    if (b == null) return world.listeners.add(a, a, options);
    return world.listeners.add(a, b, options);
  }
  /**
   * Performs a one-time collision check.
   * @param world the `World` to check for collisions
   * @param a The first `Body` or Array of Bodies to collide against
   * @param b The second `Body` or Array of Bodies to collide against
   * @param options Options to define the Collision Check's behavior
   */
  public static function check(world:World, ?a:BodyOrBodies, ?b:BodyOrBodies, ?options:ListenerOptions):Listener {
    var listener:Listener;

    listeners.clear();

    if (a == null) listener = b == null ? listeners.add(world.members, world.members, options) : listeners.add(b, b, options);
    else if (b == null) listener = listeners.add(a, a, options);
    else listener = listeners.add(a, b, options);

    Collisions.query(world, listeners);
    Physics.separate(world, listeners);
    Collisions.notify(world, listeners);

    return listener;
  }

  public static inline function linecast_floats(x:Float, y:Float, dx:Float, dy:Float, test:BodyOrBodies):Null<IntersectionData> {
    var line = Line.get(x, y, dx, dy);
    var result = linecast(line, test);
    line.put();
    return result;
  }

  public static inline function linecast_vector(start:Vector2, angle:Float, length:Float, test:BodyOrBodies):Null<IntersectionData> {
    var line = Line.get_from_vector(start, angle, length);
    var result = linecast(line, test);
    line.put();
    return result;
  }

  public static inline function linecast_vectors(start:Vector2, end:Vector2, test:BodyOrBodies):Null<IntersectionData> {
    var line = Line.get_from_vectors(start, end);
    var result = linecast(line, test);
    line.put();
    return result;
  }

  public static inline function linecast(line:Line, test:BodyOrBodies):Null<IntersectionData> {
    var closest:Null<IntersectionData> = null;
    var lb = Rect.get_from_min_max(Math.min(line.start.x, line.end.x), Math.min(line.start.y, line.end.y), Math.max(line.start.x, line.end.x),
      Math.max(line.start.y, line.end.y));
    switch (cast test : Either<Body, Array<Body>>) {
      case Left(body):
        var bb = body.bounds();
        if (lb.overlaps(bb)) {
          for (i in 0...body.shapes.length) {
            var result = line.intersect(body.shapes[i]);
            if (result != null && (closest == null || closest.distance > result.distance)) closest = result;
          }
        }
        bb.put();
      case Right(arr):
        for (body in arr) {
          if (body == null) continue;
          var bb = body.bounds();
          if (lb.overlaps(bb)) {
            for (i in 0...body.shapes.length) {
              var result = line.intersect(body.shapes[i]);
              if (result != null && (closest == null || closest.distance > result.distance)) closest = result;
            }
          }
          bb.put();
        }
    }
    lb.put();
    return closest;
  }
  /**
   * Steps a `World` forward.
   * @param world
   * @param dt
   */
  public static function step(world:World, dt:Float) {
    // TODO: Save World State to History
    if (world.history != null) world.history.add([
      for (b in world.members) {
        id: b.id,
        x: b.x,
        y: b.y,
        rotation: b.rotation,
        velocity: b.velocity,
        acceleration: b.acceleration,
        rotational_velocity: b.rotational_velocity
      }
    ]);

    // Apply Gravity
    world.for_each(member -> {
      member.acceleration.x += world.gravity.x * member.gravity_scale;
      member.acceleration.y += world.gravity.y * member.gravity_scale;
    });
    // Step the World incrementally based on the number of iterations
    var fdt = dt / world.iterations;
    for (i in 0...world.iterations) {
      Physics.step(world, fdt);
      Collisions.query(world);
      Physics.separate(world);
      Collisions.notify(world);
    }
    // Reset acceleration
    world.for_each(member -> member.acceleration.set(0, 0));
  }
  /**
   * Undo the World's last step
   * @param world
   * @return World
   */
  public static function undo(world:World):World {
    if (world.history != null) {
      var state = world.history.undo();
      if (state != null) {
        for (item in state) {
          for (body in world.members) {
            if (item.id == body.id) {
              body.x = item.x;
              body.y = item.y;
              body.rotation = item.rotation;
              body.velocity = item.velocity;
            }
          }
        }
        world.refresh();
      }
    }
    return world;
  }
  /**
   * Redo the World's last step
   * @param world
   * @return World
   */
  public static function redo(world:World):World {
    if (world.history != null) {
      var state = world.history.redo();
      if (state != null) {
        for (item in state) {
          for (body in world.members) {
            if (item.id == body.id) {
              body.x = item.x;
              body.y = item.y;
              body.rotation = item.rotation;
              body.velocity = item.velocity;
              body.acceleration = item.acceleration;
              body.rotational_velocity = item.rotational_velocity;
            }
          }
        }
      }
      world.refresh();
    }
    return world;
  }
}
