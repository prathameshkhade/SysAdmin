import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sysadmin/presentation/screens/dashboard/index.dart';

import 'onboarding_data.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget buildDots(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 10.0,
      width: _currentIndex == index ? 32 : 12,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: _currentIndex == index ? Colors.white : Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _onFinish() async {
    // Save onboarding status
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isOnBoardingDone', true);

    if (!mounted) return;

    // Navigate to Dashboard
    Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const DashboardScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CupertinoButton(
        onPressed: () {
          _pageController.animateToPage(
            onBoardingData.length - 1,
            duration: Duration(milliseconds: (onBoardingData.length - 1 - _currentIndex) * 800),
            curve: Curves.easeInOutSine,
          );
        },
        child: const Text(
          "Skip",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Stack(
        children: [
          ConcentricPageView(
            colors: onBoardingData.map((item) => item.bgColor).toList(),
            pageController: _pageController,
            itemCount: onBoardingData.length,
            radius: 32.0,
            onChange: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            nextButtonBuilder: (context) => const Icon(
              Icons.navigate_next_rounded,
              size: 40,
              color: Colors.black,
            ),
            curve: Curves.easeInOutSine,
            verticalPosition: 0.85,
            physics: const BouncingScrollPhysics(),
            onFinish: () => _onFinish(),
            itemBuilder: (index) {
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 80.0, 8.0, 12.0),
                      child: Column(
                        children: <Widget>[
                          Text(
                            onBoardingData[index].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            onBoardingData[index].description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
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
                    ),
                  ],
                ),
              );
            },

          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onBoardingData.length,
                (index) => buildDots(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
