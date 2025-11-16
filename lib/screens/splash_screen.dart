import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:trueque/theme/app_theme.dart';
import 'package:trueque/widgets/circle_background.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CircleBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 120, width: 120),
           
              const SizedBox(height: 20),

              const SizedBox(height: 50),

              SpinKitFadingCircle(
                itemBuilder: (BuildContext context, int index) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? Colors.white
                          : AppTheme.primaryDarkColor,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
