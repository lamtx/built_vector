import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:recase/recase.dart';

import 'model.dart';

abstract class Generator {
  String generate(Assets assets);
}

class FlutterGenerator extends Generator {
  @override
  String generate(Assets assets) {
    final library = Library((b) => b
      ..directives.addAll([
        Directive.import("package:flutter/widgets.dart"),
      ])
      ..body.add(Class((b) => b
        ..name = ReCase(assets.name).pascalCase
        ..methods.addAll(assets.vectors.map(_generateVector)))));
    final emitter = DartEmitter();
    final source = '${library.accept(emitter)}';
    return DartFormatter().format(source);
  }

  Method _generateVector(Vector vector) {
    final tx = _toFixedDouble(-vector.viewBox.x);
    final ty = _toFixedDouble(-vector.viewBox.y);
    final sx = "size.width / ${_toFixedDouble(vector.viewBox.width)}";
    final sy = "size.height / ${_toFixedDouble(vector.viewBox.height)}";

    final body = <Code>[
      Code("canvas.translate($tx, $ty);"),
      Code("canvas.scale($sx, $sy);"),
      const Code("final paint = Paint();"),
      const Code("if(fill != null) {"),
      const Code("paint.color = fill;"),
      const Code("}"),
    ];

    for (final s in vector.fills) {
      _generateShape(body, s);
    }
    return Method((b) => b
      ..name = ReCase(vector.name).camelCase
      ..returns = refer("void")
      ..body = Block((b) => b..statements.addAll(body))
      ..static = true
      ..optionalParameters.addAll([
        Parameter((p) => p
          ..type = refer("Color?")
          ..named = true
          ..name = "fill"),
      ])
      ..requiredParameters.addAll([
        Parameter((p) => p
          ..type = refer("Canvas")
          ..name = "canvas"),
        Parameter((p) => p
          ..type = refer("Size")
          ..name = "size"),
      ]));
  }

  void _generateShape(List<Code> code, Shape shape) {
    _generateBrush(code, shape.fill);

    if (shape is Path) {
      _generatePath(code, shape);
    } else if (shape is Rectangle) {
      _generateRect(code, shape);
    } else if (shape is Circle) {
      _generateCircle(code, shape);
    }
  }

  void _generateRect(List<Code> code, Rectangle rect) {
    final instance =
        "Rect.fromLTWH(${_toFixedDouble(rect.x)}, ${_toFixedDouble(rect.y)}, ${_toFixedDouble(rect.width)}, ${_toFixedDouble(rect.height)})";
    code.add(Code("canvas.drawRect(($instance), paint);"));
  }

  void _generateCircle(List<Code> code, Circle circle) {
    code.add(Code(
        "canvas.drawCircle(Offset(${_toFixedDouble(circle.centerX)}, ${_toFixedDouble(circle.centerY)}), ${_toFixedDouble(circle.radius)}, paint);"));
  }

  void _generatePath(List<Code> code, Path path) {
    final buffer = StringBuffer();
    final proxy = _FlutterPathProxy(buffer);
    writeSvgPathDataToPath(path.data, proxy);
    code.add(Code("canvas.drawPath(($buffer), paint);"));
  }

  void _generateBrush(List<Code> code, Brush? brush) {
    if (brush != null) {
      code.add(const Code("if(fill == null) {"));

      if (brush is Color) {
        final color =
            'const Color(0x${brush.value.toRadixString(16).padLeft(8, '0')})';
        code.add(Code("paint.color = $color;"));
      }

      code.add(const Code("}"));
    }
  }
}

class _FlutterPathProxy extends PathProxy {
  _FlutterPathProxy(this.statements) {
    statements.write("Path()");
  }

  final StringBuffer statements;

  @override
  void close() => statements.write("..close()");

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      statements.write(
          "..cubicTo(${_toFixedDouble(x1)}, ${_toFixedDouble(y1)}, ${_toFixedDouble(x2)}, ${_toFixedDouble(y2)}, ${_toFixedDouble(x3)}, ${_toFixedDouble(y3)})");

  @override
  void lineTo(double x, double y) =>
      statements.write("..lineTo(${_toFixedDouble(x)}, ${_toFixedDouble(y)})");

  @override
  void moveTo(double x, double y) =>
      statements.write("..moveTo(${_toFixedDouble(x)}, ${_toFixedDouble(y)})");
}

String _toFixedDouble(double value) {
  if (value == 0) {
    return "0";
  }
  if (value == value.floorToDouble()) {
    return value.floor().toString();
  }
  return value.toString();
}
