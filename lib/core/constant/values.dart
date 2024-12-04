import 'package:flutter/material.dart';


/// Dimensions and animation configurations for the dock widget.
/// These constants control the appearance and behavior of dock items.
///
 const double baseWidth = 50.0;
 const double maxWidth = 75.0;
 const double baseHeight = 50.0;
 const double maxHeight = 75.0;
 const double spacing = 8.0;
 const double maxScaleIncrease = 0.7;
 const Duration animationDuration = Duration(milliseconds: 300);
 const Duration swapDuration = Duration(milliseconds: 200);

/// Animation curve used for smooth transitions.
/// Uses [Curves.easeOutCubic] for natural-feeling animations.
 const Curve animationCurve = Curves.easeOutCubic;