class Assets {
  const Assets({
    required this.name,
    this.vectors = const <Vector>[],
    this.definitions = const <Definition>[],
  });

  final String name;
  final List<Vector> vectors;
  final List<Definition> definitions;
}

class ViewBox {
  const ViewBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

class Vector {
  const Vector({
    required this.name,
    required this.fill,
    required this.viewBox,
    this.fills = const <Shape>[],
  });

  final String name;
  final Brush fill;
  final ViewBox viewBox;
  final List<Shape> fills;
}

abstract class Brush {}

class Color implements Brush {
  const Color(this.value);

  final int value;
}

abstract class Shape {
  const Shape({required this.fill});

  final Brush? fill;
}

class Path extends Shape {
  const Path({
    required super.fill,
    required this.data,
  });

  final String data;
}

class Circle extends Shape {
  const Circle({
    required super.fill,
    required this.centerX,
    required this.centerY,
    required this.radius,
  });

  final double centerX;
  final double centerY;
  final double radius;
}

class Rectangle extends Shape {
  const Rectangle({
    required super.fill,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

abstract class Definition {
  const Definition({required this.id});

  final String id;
}

class LinearGradient extends Definition {
  const LinearGradient({
    required super.id,
    required this.x1,
    required this.x2,
    required this.y1,
    required this.y2,
    this.stops = const <GradientStop>[],
  });

  final Length x1;
  final Length x2;
  final Length y1;
  final Length y2;
  final List<GradientStop> stops;
}

class RadialGradient extends Definition {
  const RadialGradient({
    required super.id,
    required this.cx,
    required this.cy,
    required this.r,
    this.stops = const <GradientStop>[],
  });

  final Length cx;
  final Length cy;
  final Length r;
  final List<GradientStop> stops;
}

class GradientStop {
  const GradientStop({
    required this.color,
    required this.offset,
    this.opacity = 1.0,
  });

  final double offset;
  final double opacity;
  final Color color;
}

class Length {
  Length.amount(this.value) : type = LengthType.amount;

  Length.absolute(this.value) : type = LengthType.absolute;
  final double value;
  final LengthType type;
}

enum LengthType {
  amount,
  absolute,
}
