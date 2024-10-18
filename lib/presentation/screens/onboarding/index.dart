import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'onboarding_data.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Skip Button
      floatingActionButton: CupertinoButton(
        onPressed: () => _pageController.animateToPage(onBoardingData.length - 1,
            duration: const Duration(milliseconds: 3000), curve: Curves.easeInOutSine),
        child: const Text("Skip",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: ConcentricPageView(
          colors: onBoardingData.map((item) => item.bgColor).toList(),
          pageController: _pageController,
          itemCount: onBoardingData.length,
          radius: 32.0,
          nextButtonBuilder: (context) => const Icon(
                Icons.navigate_next_rounded,
                size: 40,
                color: Colors.black,
              ),
          curve: Curves.easeInOutSine,
          verticalPosition: 0.82,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (index) {
            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 80.0, 8.0, 12.0),
                    child: Column(
                      children: <Widget>[
                        // Title
                        Text(
                          onBoardingData[index].title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          onBoardingData[index].description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 18, color: Colors.black87),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  SvgPicture.asset(
                    onBoardingData[index].picture,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.contain,
                  )
                ],
              ),
            );
          }),
    );
  }
}
