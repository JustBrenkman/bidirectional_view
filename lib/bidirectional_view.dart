import 'package:flutter/material.dart';

import 'package:vector_math/vector_math_64.dart' as math;
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

import 'scaling_gesture_detector.dart';

class BiDirectionalView extends StatefulWidget {
  final List<BiWrapper> children;

  const BiDirectionalView({Key key, this.children}) : super(key: key);

  @override
  _BiDirectionalViewState createState() =>
      _BiDirectionalViewState(children: children);
}

class _BiDirectionalViewState extends State<BiDirectionalView> {
  final List<BiWrapper> children;

  Matrix4 matrix;

  _BiDirectionalViewState({this.children}) {
    matrix = Matrix4.identity();
  }

  @override
  initState() {
    matrix = Matrix4.identity();
    super.initState();
  }

  double scale = 0.3;
  @override
  Widget build(BuildContext context) {
    return ScalingGestureDetector(
      onScaleUpdate: (avgPos, scale_) {
        setState(() {
          print('scale update: $scale');
          // TODO: update the scale (can't test with trackpad)
        });
      },
      onPanUpdate: (pos, delta) {
        setState(() {
          math.Vector4 vec = math.Vector4(
              delta.dx / (scale * 3), delta.dy / (scale * 3), 0.0, 0.0);
          Matrix4 toAdd = Matrix4.zero();
          toAdd.setColumn(3, vec);
          matrix = matrix + toAdd;
        });
      },
      child: GestureDetector(
        onDoubleTap: () {
          setState(() {
            scale += 0.1;
            Matrix4 toAdd = Matrix4.zero();
            toAdd.setDiagonal(math.Vector4(scale, scale, 0.0, 0.0));
            matrix = matrix + toAdd;
          });
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[700],
          child: Transform(
            transform: matrix,
            child: CustomMultiChildLayout(
              delegate:
                  BiDirectionalViewLayoutDelegate(this, children: children),
              children: children,
            ),
          ),
        ),
      ),
    );

    /*
    // TODO: Still may work?
    return MatrixGestureDetector(
      onMatrixUpdate: (Matrix4 m, Matrix4 tm, Matrix4 sm, Matrix4 rm) {
        // print ('here${i++}');

        setState(() {
          double sc = 5;
          matrix = m * (Matrix4.identity()..setColumn(3, math.Vector4(tm[3]*sm[15]*sc,tm[7]*sm[15]*sc,0,1)));
          print (matrix);
          // matrix += (tm + sm) - (Matrix4.identity() * 2.0);
          // matrix = m * (sm..scale(1.5));
          // matrix = Matrix4.identity();
        });
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[700],
        child: Transform(
          transform: matrix,
          child: CustomMultiChildLayout(
            delegate: BiDirectionalViewLayoutDelegate(this, children: children),
            children: children,
          ),
        ),
      ),
    );
    */
  }
}

class BiDirectionalViewLayoutDelegate extends MultiChildLayoutDelegate {
  final List<BiWrapper> children;
  final Size size = Size(200, 200);

  final _BiDirectionalViewState viewState;

  BiDirectionalViewLayoutDelegate(this.viewState, {this.children});

  @override
  void performLayout(Size size) {
    List<double> vec = [0, 0, 0];
    viewState?.matrix?.getTranslation()?.copyIntoArray(vec);
    if (children != null) {
      children.forEach((child) {
        layoutChild(child.key, BoxConstraints.loose(size));
        positionChild(child.key, Offset(vec[0], vec[1]) + child.worldPos);
      });
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class BiWrapper extends StatelessWidget {
  final Offset worldPos;

  BiWrapper({
    this.worldPos = const Offset(0, 0),
  }) : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return LayoutId(
      id: key,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.red,
      ),
    );
  }
}
