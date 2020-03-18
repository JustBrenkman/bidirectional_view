import 'dart:math';

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

  double scale = 1.0;
  @override
  Widget build(BuildContext context) {
    /// This converts delta pixels to delta global (2D) space
    ///
    /// This was found with the following:
    /// ```
    /// double c = 65.0;
    /// math.Vector4 vec = math.Vector4((delta.dx) * (1/(scale*c)), (delta.dy) * (1/(scale*c)), 0.0, 0.0);
    /// print ('${delta.dx}: ($scale, ${(1/(scale*c))})');
    /// ```
    /// to find different `c` values given `scale`.
    ///
    /// Thus, f(x) returns the function that fits the scale to the transformation.
    /// This is used to keep the distance the users mouse travels consistent with the view.
    ///
    /// The distance travelled as `scale` changes is non-linear and this is function I found
    /// after trying many values (recorded here) and using regression to find a best fit line.
    ///
    /// Data (copy paste into excel, comma delimited):
    /// Note that x is `scale`, y is (1/(scale*c))
    /// where I found c manually to make the drag feel natural (keep mouse position consistent)
    ///
    /// x,y
    /// 0.015625,0.984615385
    /// 0.03125,0.96969697
    /// 0.0625,0.941176471
    /// 0.125,0.888888889
    /// 0.25,0.8
    /// 0.5,0.666666667
    /// 1,0.5
    /// 2,0.333333333
    /// 3,0.245098039
    /// 4,0.2
    ///
    /// Using excel, the best regression was polynomial (n=5, R^2=1):
    /// y = -0.006x^5 + 0.0686x^4 - 0.3039x^3 + 0.6859x^2 - 0.9418^x + 0.998
    double f(double x) => (-0.006 * pow(x, 5) +
            0.0686 * pow(x, 4) -
            0.3039 * pow(x, 3) +
            0.6859 * pow(x, 2) -
            0.9418 * pow(x, 1) +
            0.998)
        .abs();

    return Container(
      child: Stack(
        children: <Widget>[
          ScalingGestureDetector(
            onScaleUpdate: (avgPos, scale_) {
              setState(() {
                print('scale update: $scale');
                // TODO: update the scale (can't test with trackpad)
              });
            },
            onPanUpdate: (pos, delta) {
              setState(() {
                double y = f(scale);
                math.Vector4 vec =
                    math.Vector4(delta.dx * y, delta.dy * y, 0.0, 0.0);

                Matrix4 toAdd = Matrix4.zero();
                toAdd.setColumn(3, vec);
                matrix = matrix + toAdd;
              });
            },
            child: GestureDetector(
              onDoubleTap: () {
                setState(() => _updateMatrixScale(scale + 0.1));
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[700],
                child: Transform(
                  transform: matrix,
                  child: CustomMultiChildLayout(
                    delegate: BiDirectionalViewLayoutDelegate(this,
                        children: children),
                    children: children,
                  ),
                ),
              ),
            ),
          ),
          Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 300,
                height: 50,
                // color: Color.fromRGBO(200, 200, 200, 0.5),
                child: Center(
                  child: Stack(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.zoom_out)),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Slider(
                            inactiveColor: Colors.purple,
                            activeColor: Colors.purpleAccent,
                            value: scale,
                            min: 0.05,
                            max: 3.0,
                            divisions: 50,
                            label: scale.toStringAsFixed(2),
                            onChanged: (double value) {
                              setState(() => _updateMatrixScale(value));
                            },
                          ),
                        ),
                      ),
                      Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.zoom_in)),
                    ],
                  ),
                ),
              )),
        ],
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

  void _updateMatrixScale(double newScale) {
    scale = newScale;
    matrix.setDiagonal(math.Vector4(scale, scale, 1.0, 1.0));
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
