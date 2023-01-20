import 'package:xml/xml.dart' as xml;

import 'model.dart';

Iterable<xml.XmlElement> _childElements(xml.XmlElement element) =>
    element.children.whereType<xml.XmlElement>();

class AssetsParser {
  AssetsParser();

  Assets parse(String content) {
    if (content.isEmpty) {
      throw StateError("empty files");
    }
    final document = xml.XmlDocument.parse(content);
    final rootElement = document.rootElement;

    if (rootElement.name.toString() != 'assets') {
      throw StateError("root element should be `assets`");
    }
    final name = rootElement.getAttribute("name") ??
        (throw StateError("a name must be precised for assets"));
    final definitions = rootElement
        .findElements('defs')
        .expand((x) => _childElements(x).map(_parseDefinition));

    final vectors =
        rootElement.findElements('vector').map(_parseVector).toList();
    return Assets(
      name: name,
      vectors: vectors,
      definitions: definitions.toList(),
    );
  }

  Definition _parseDefinition(xml.XmlElement element) {
    final id = element.getAttribute("id") ??
        (throw StateError("an id must be precised for definitions"));

    if (element.name.toString() == "linearGradient") {
      final x1 = element.getAttribute("x1") ?? "0%";
      final x2 = element.getAttribute("x2") ?? "100%";
      final y1 = element.getAttribute("y1") ?? "0%";
      final y2 = element.getAttribute("y2") ?? "0%";
      return LinearGradient(
          id: id,
          x1: _parseLength(x1),
          x2: _parseLength(x2),
          y1: _parseLength(y1),
          y2: _parseLength(y2),
          stops:
              element.findAllElements("stop").map(_parseGradientStop).toList());
    }

    if (element.name.toString() == "radialGradient") {
      final cx = element.getAttribute("cx") ?? "50%";
      final cy = element.getAttribute("x2") ?? "50%";
      final r = element.getAttribute("r") ?? "50%";
      return RadialGradient(
          id: id,
          cx: _parseLength(cx),
          cy: _parseLength(cy),
          r: _parseLength(r),
          stops:
              element.findAllElements("stop").map(_parseGradientStop).toList());
    }

    error("unknown definition `${element.name}`");
  }

  GradientStop _parseGradientStop(xml.XmlElement element) {
    final color = element.getAttribute("stop-color") ?? "#000000";
    final offset = element.getAttribute("offset") ?? "0.0";
    final opacity = element.getAttribute("stop-opacity") ?? "1.0";
    return GradientStop(
      color: Color(_parseColor(color)),
      offset: _parseAmount(offset),
      opacity: double.parse(opacity),
    );
  }

  Length _parseLength(String s) {
    final value = s.trim();
    if (value.endsWith("%")) {
      return Length.amount(
          double.parse(value.substring(0, value.length - 1)).clamp(0.0, 100.0) /
              100.0);
    }
    return Length.absolute(double.parse(value));
  }

  double _parseAmount(String s) {
    if (s.isEmpty) {
      return 0;
    }
    final value = s.trim();
    if (value.endsWith("%")) {
      return double.parse(value.substring(0, value.length - 1))
              .clamp(0.0, 100.0) /
          100.0;
    }
    return double.parse(value).clamp(0.0, 1.0);
  }

  Vector _parseVector(xml.XmlElement element) {
    final name = element.getAttribute("name") ??
        error("a name must be precised for each vector");
    final fill =
        _parseBrush(element.getAttribute("fill")) ?? const Color(0xFF000000);
    final viewBox = _parseViewBox(element.getAttribute("viewBox") ??
        error("a viewBox must be precised for each vector"));
    final fills =
        _childElements(element).map((x) => _parseShape(x, fill)).toList();
    return Vector(name: name, fill: fill, viewBox: viewBox, fills: fills);
  }

  ViewBox _parseViewBox(String value) {
    final split = value.split(" ").where((v) => v.isNotEmpty).toList();
    if (split.length > 3) {
      return ViewBox(
        x: double.parse(split[0]),
        y: double.parse(split[1]),
        width: double.parse(split[2]),
        height: double.parse(split[3]),
      );
    }

    if (split.length > 1) {
      return ViewBox(
        x: 0,
        y: 0,
        width: double.parse(split[2]),
        height: double.parse(split[3]),
      );
    }

    error("`viewBox` should be `x y width height` or `width height`");
  }

  Shape _parseShape(xml.XmlElement element, Brush defaultFill) {
    final fill = _parseBrush(element.getAttribute("fill")) ?? defaultFill;

    if (element.name.toString() == "path") {
      final data = element.getAttribute("d") ??
          error("data ('d') must be precised for all paths");
      return Path(fill: fill, data: data);
    } else if (element.name.toString() == "rect") {
      final x = double.parse(element.getAttribute("x") ?? "0.0");
      final y = double.parse(element.getAttribute("y") ?? "0.0");
      final w = double.parse(element.getAttribute("width") ?? "0.0");
      final h = double.parse(element.getAttribute("height") ?? "0.0");
      return Rectangle(fill: fill, x: x, y: y, width: w, height: h);
    } else if (element.name.toString() == "circle") {
      final cx = double.parse(element.getAttribute("cx") ?? "0.0");
      final cy = double.parse(element.getAttribute("cy") ?? "0.0");
      final radius = double.parse(element.getAttribute("r") ?? "0.0");
      return Circle(fill: fill, centerX: cx, centerY: cy, radius: radius);
    }

    error("unknown shape `${element.name}`");
  }

  Brush? _parseBrush(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.startsWith("#")) {
        return Color(_parseColor(value));
      }
    }
    return null;
  }

  int _parseColor(String s) {
    var v = s;
    if (v.startsWith("#")) {
      v = v.substring(1);
    }

    if (v.length > 8) {
      v = v.substring(0, 8);
    } else if (v.length > 5) {
      v = "FF${v.substring(0, 6)}";
    } else if (v.length > 2) {
      final r = v[0];
      final g = v[1];
      final b = v[2];
      v = "FF$r$r$g$g$b$b";
    } else if (v.isNotEmpty) {
      final r = v[0];
      v = "FF$r$r$r$r$r$r";
    } else {
      v = "FF000000";
    }

    return int.parse(v, radix: 16);
  }

  static Never error(String message) => throw StateError(message);

  static Never required(String name) =>
      throw StateError("field `$name` is required");
}
