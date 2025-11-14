import 'package:flutter/material.dart';

/// Custom page transition animations for better user experience

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      );
}

class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;

  FadeScaleRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic;

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve)).animate(animation);

          var scaleAnimation = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).chain(CurveTween(curve: curve)).animate(animation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      );
}

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      );
}

class RotateScaleRoute extends PageRouteBuilder {
  final Widget page;

  RotateScaleRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutBack;

          var scaleAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve)).animate(animation);

          var rotateAnimation = Tween<double>(
            begin: 0.2,
            end: 0.0,
          ).chain(CurveTween(curve: curve)).animate(animation);

          return ScaleTransition(
            scale: scaleAnimation,
            child: RotationTransition(turns: rotateAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      );
}

/// Shared axis transition - material design pattern
class SharedAxisRoute extends PageRouteBuilder {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisRoute({
    required this.page,
    this.transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const curve = Curves.easeInOutCubic;

           var fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0)
               .chain(CurveTween(curve: curve))
               .animate(
                 CurvedAnimation(
                   parent: animation,
                   curve: const Interval(0.3, 1.0),
                 ),
               );

           var fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0)
               .chain(CurveTween(curve: curve))
               .animate(
                 CurvedAnimation(
                   parent: secondaryAnimation,
                   curve: const Interval(0.0, 0.3),
                 ),
               );

           Offset beginOffset;
           Offset endOffset;

           switch (transitionType) {
             case SharedAxisTransitionType.horizontal:
               beginOffset = const Offset(0.3, 0.0);
               endOffset = const Offset(-0.3, 0.0);
               break;
             case SharedAxisTransitionType.vertical:
               beginOffset = const Offset(0.0, 0.3);
               endOffset = const Offset(0.0, -0.3);
               break;
             case SharedAxisTransitionType.scaled:
               beginOffset = Offset.zero;
               endOffset = Offset.zero;
               break;
           }

           var slideInAnimation =
               Tween<Offset>(begin: beginOffset, end: Offset.zero)
                   .chain(CurveTween(curve: curve))
                   .animate(
                     CurvedAnimation(
                       parent: animation,
                       curve: const Interval(0.3, 1.0),
                     ),
                   );

           if (transitionType == SharedAxisTransitionType.scaled) {
             var scaleInAnimation = Tween<double>(begin: 0.8, end: 1.0)
                 .chain(CurveTween(curve: curve))
                 .animate(
                   CurvedAnimation(
                     parent: animation,
                     curve: const Interval(0.3, 1.0),
                   ),
                 );

             return FadeTransition(
               opacity: fadeInAnimation,
               child: ScaleTransition(scale: scaleInAnimation, child: child),
             );
           }

           return SlideTransition(
             position: slideInAnimation,
             child: FadeTransition(opacity: fadeInAnimation, child: child),
           );
         },
         transitionDuration: const Duration(milliseconds: 500),
       );
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// Hero-style expansion animation
class ExpansionRoute extends PageRouteBuilder {
  final Widget page;
  final Offset? centerOffset;

  ExpansionRoute({required this.page, this.centerOffset})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;

          var scaleAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve)).animate(animation);

          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn))
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5),
                ),
              );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: centerOffset != null
                  ? FractionalOffset(
                      centerOffset.dx.clamp(0.0, 1.0),
                      centerOffset.dy.clamp(0.0, 1.0),
                    )
                  : Alignment.center,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      );
}
