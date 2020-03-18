import 'dart:math';

import 'package:flutter/material.dart';

import 'package:vector_math/vector_math_64.dart' as math;

class BiDirectionalLayout extends ChangeNotifier {
  final List<BiWrapper> children;

  BiDirectionalLayout({@required this.children}) : super();

  /// All [Widget]s that this layout displays.
  ///
  /// This function returns each [Widget] wrapped with a
  /// [LayoutId] so that they can be used by the delegate.
  List<LayoutId> get widgets => children
      .map((w) => LayoutId(
          id: w.key,
          child: GestureDetector(
              child: w.child,
              onPanUpdate: (details) {
                w.updatePos(details.delta);
                notifyListeners();
              })))
      .toList();
}

class BiDirectionalView extends StatefulWidget {
  final BiDirectionalLayout _layout;

  BiDirectionalLayout get layout => _layout;

  const BiDirectionalView({Key key, BiDirectionalLayout layout})
      : _layout = layout,
        super(key: key);

  @override
  _BiDirectionalViewState createState() => _BiDirectionalViewState();
}

class _BiDirectionalViewState extends State<BiDirectionalView> {
  double scale;
  Matrix4 matrix;

  _BiDirectionalViewState();

  @override
  initState() {
    scale = 1.0;
    matrix = Matrix4.identity();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    BiDirectionalViewLayoutDelegate delegate =
        BiDirectionalViewLayoutDelegate(this, layout: widget.layout);

    return Container(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              setState(() => _updateMatrixTransform(details.delta));
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () {
                setState(() => _updateMatrixScale(scale + 0.1));
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[700],
                child: Transform(
                  alignment: FractionalOffset.center, // This makes it scale from the center (make a setting for the user)
                  transform: matrix,
                  child: CustomMultiChildLayout(
                    delegate: delegate,
                    children: delegate.layout.widgets,
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
                child: Center(
                  child: Stack(
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
  }

  void _updateMatrixScale(double newScale) {
    scale = newScale;
    matrix.setDiagonal(math.Vector4(scale, scale, 1.0, 1.0));
  }

  void _updateMatrixTransform(Offset delta) {
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

    double y = f(scale);
    math.Vector4 vec = math.Vector4(delta.dx * y, delta.dy * y, 0.0, 0.0);

    Matrix4 toAdd = Matrix4.zero();
    toAdd.setColumn(3, vec);
    matrix = matrix + toAdd;
  }
}

class BiDirectionalViewLayoutDelegate extends MultiChildLayoutDelegate {
  final BiDirectionalLayout layout;
  final _BiDirectionalViewState viewState;

  BiDirectionalViewLayoutDelegate(this.viewState, {@required this.layout});

  @override
  void performLayout(Size size) {
    List<double> vec = [0, 0, 0];
    viewState?.matrix?.getTranslation()?.copyIntoArray(vec);

    layout.children.forEach((wrapper) {
      layoutChild(wrapper.key, BoxConstraints.loose(size));
      positionChild(wrapper.key, Offset(vec[0], vec[1]) + wrapper.worldPos);
    });
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class BiWrapper {
  Widget child;
  Offset worldPos;
  final GlobalKey key;

  BiWrapper({
    @required this.child,
    this.worldPos = const Offset(0, 0),
    GlobalKey key,
  }) : this.key = key ?? GlobalKey();

  void updatePos(Offset pos) => worldPos += pos;
}
