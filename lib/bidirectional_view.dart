
import 'package:flutter/material.dart';

class BiDirectionalView extends StatefulWidget {
  final List<BiWrapper> children;

  const BiDirectionalView({Key key, this.children}) : super(key: key);

  @override
  _BiDirectionalViewState createState() => _BiDirectionalViewState(children: children);
}

class _BiDirectionalViewState extends State<BiDirectionalView> {
  double x = 0, y = 0;
  final List<BiWrapper> children;

  _BiDirectionalViewState({this.children});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (event) {
        setState(() {
          x += event.delta.dx;
          y += event.delta.dy;
        });
      },
      child: Container(
        color: Colors.grey[700],
        child: CustomMultiChildLayout(
          delegate: BiDirectionalViewLayoutDelegate(x, y, 0.0, children: children),
          children: children,
        ),
      ),
    );
  }
}

class BiDirectionalViewLayoutDelegate extends MultiChildLayoutDelegate {
  final double x, y, scale;
  final List<BiWrapper> children;
  final Size size = Size(200, 200);

  BiDirectionalViewLayoutDelegate(this.x, this.y, this.scale, {this.children});

  @override
  void performLayout(Size size) {
    Matrix4 matrix = Matrix4.identity()
        ..translate(x ?? 0, y ?? 0, 0);

    if (children != null) children.forEach((child) {
      layoutChild(child.key, BoxConstraints.loose(size));
      positionChild(child.key, Offset(x, y) + child.offset);
    });
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class BiWrapper extends StatelessWidget {
  final Size size;
  final Offset offset;

  BiWrapper({this.offset = const Offset(300, 300), this.size = const Size(100, 100)}) : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return LayoutId(
      id: key,
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.red,
      ),
    );
  }
}
