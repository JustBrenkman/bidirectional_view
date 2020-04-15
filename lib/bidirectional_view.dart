import 'dart:math';

import 'package:flutter/material.dart';

/// Contains all [BiWrapper]s to display using a [_BiDirectionalViewLayoutDelegate].
///
/// This should be passed to a [BiDirectionalView].
class BiDirectionalLayout extends ChangeNotifier {
  /// The list of children to display.
  List<BiWrapper> children;

  /// Default constructor.
  BiDirectionalLayout({List<BiWrapper> children})
      : this.children = children ?? const [],
        super();

  /// All [Widget]s that this layout displays.
  ///
  /// This function returns each [BiWrapper.child] wrapped with a
  /// [LayoutId] so that they can be used by the delegate.
  List<LayoutId> widgets(double scale) => children
      .map((w) => LayoutId(
          id: w.key,
          child: Transform(
            transform: _transform(scale),
            child: GestureDetector(
                child: w.child,
                onPanUpdate: (details) {
                  w.updatePos(details.delta);
                  notifyListeners();
                }),
          )))
      .toList();

  /// The scaling for this widget based on the scale of the [_BiDirectionalViewState.scale].
  ///
  /// NOTE: The translation is not handled in this function, that should be handled
  /// by the [_BiDirectionalViewLayoutDelegate]. All this does is scale the widget.
  Matrix4 _transform(double scale) {
    return Matrix4.identity()..scale(scale, scale);
  }
}

/// A widget which can be translated and scaled in 2 directions.
///
/// It requires a [BiDirectionalLayout] which has the children it should display.
class BiDirectionalView extends StatefulWidget {
  /// The layout this [Widget] displays.
  final BiDirectionalLayout _layout;

  /// The layout this [Widget] displays.
  BiDirectionalLayout get layout => _layout;

  /// The [Color] of the background.
  final Color backgroundColor;

  /// Default constructor which requires a [layout].
  const BiDirectionalView(
      {Key key, @required BiDirectionalLayout layout, Color backgroundColor})
      : _layout = layout,
        this.backgroundColor = backgroundColor ?? Colors.grey,
        super(key: key);

  @override
  _BiDirectionalViewState createState() => _BiDirectionalViewState();
}

/// The State for a [BiDirectionalView].
class _BiDirectionalViewState extends State<BiDirectionalView> {
  /// The scale (zoom) of the view.
  double scale;

  /// The offset from (0,0).
  Offset origin;

  /// Default constructor.
  _BiDirectionalViewState();

  @override
  initState() {
    scale = 1.0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    origin = origin ??
        Offset(MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2);

    _BiDirectionalViewLayoutDelegate delegate =
        _BiDirectionalViewLayoutDelegate(this, layout: widget.layout);

    return ClipRect(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) => _updateMatrixTransform(details.delta),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: widget.backgroundColor,
            ),
          ),
          CustomMultiChildLayout(
            delegate: delegate,
            children: delegate.layout.widgets(scale),
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
                            onChanged: (double value) =>
                                _updateMatrixScale(value),
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

  /// Updates the scale to be [newScale] and calls [setState].
  void _updateMatrixScale(double newScale) {
    setState(() {
      scale = newScale;
    });
  }

  /// Updates the origin to be offset by [delta] and calls [setState].
  ///
  /// Note that this is not linear, it depends on the scale. Thus,
  /// it converts delta (which is in screen pixels) to a global position
  /// (same as [origin]) and then adds this to [origin].
  void _updateMatrixTransform(Offset delta) {
    setState(() {
      origin += delta * screenToGlobal(scale);
    });
  }

  /// This converts delta pixels to delta global (2D) space.
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
  double screenToGlobal(double x) => (-0.006 * pow(x, 5) +
          0.0686 * pow(x, 4) -
          0.3039 * pow(x, 3) +
          0.6859 * pow(x, 2) -
          0.9418 * pow(x, 1) +
          0.998)
      .abs();
}

/// Handles displaying all [BiDirectionalLayout.children] properly.
class _BiDirectionalViewLayoutDelegate extends MultiChildLayoutDelegate {
  /// The layout this is displaying.
  final BiDirectionalLayout layout;

  /// The state of the view it is displaying.
  ///
  /// This is necessary since it needs [_BiDirectionalViewState.origin] and [_BiDirectionalViewState.scale].
  final _BiDirectionalViewState viewState;

  /// Default constructor which requires a [layout].
  _BiDirectionalViewLayoutDelegate(this.viewState, {@required this.layout});

  @override
  void performLayout(Size size) {
    layout.children.forEach((wrapper) {
      layoutChild(wrapper.key, BoxConstraints.loose(size));
      positionChild(
          wrapper.key, viewState.origin + (wrapper.worldPos * viewState.scale));
    });
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

/// Wrapper for any sized [Widget] (eg cannot be infinite) which contains a position.
class BiWrapper {
  /// The [Widget] to display.
  Widget child;

  /// The position of this object when displaying it.
  Offset worldPos;

  /// A key to be used by a [MultiChildLayoutDelegate] during layout.
  final GlobalKey key;

  /// Default constructor. Must have a [child] and defaults to (0,0).
  BiWrapper({
    @required this.child,
    this.worldPos = const Offset(0, 0),
    GlobalKey key,
  }) : this.key = key ?? GlobalKey();

  /// Offset [worldPos] by [pos].
  void updatePos(Offset pos) => worldPos += pos;
}
