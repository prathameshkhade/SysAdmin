import 'package:flutter/material.dart';

class OnboardingContent {
  String picture, title, description;
  Color bgColor;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.picture,
    required this.bgColor
  });
}

List<OnboardingContent> onBoardingData = [
  OnboardingContent(
      title: "Seamless Server Control",
      description:
          "Manage users, groups, and access levels effortlessly from one centralized interface. With our user-friendly design, system administration has never been easier.",
      picture: "assets/onboarding/svgs/serverControl.svg",
      bgColor: Colors.white70),
  OnboardingContent(
      title: "SSH at Your Fingertips",
      description:
          "Connect to multiple servers simultaneously and manage them on the go. Quickly switch between sessions and maintain full control from your mobile device.",
      picture: "assets/onboarding/svgs/manageMultipleServers.svg",
      bgColor: Colors.green.shade400),
  OnboardingContent(
      title: "Effortless File Transfers",
      description:
          "Navigate server files, upload, and download with ease using our integrated SFTP module. Stay productive wherever you are.",
      picture: "assets/onboarding/svgs/fileTransfer.svg",
      bgColor: Colors.blue.shade400),
  OnboardingContent(
      title: "Automate with a Click",
      description:
          "Schedule and manage cron jobs in seconds. Let sysAdmin handle the repetitive tasks, so you can focus on what matters.",
      picture: "assets/onboarding/svgs/cronjobs.svg",
      bgColor: Colors.amber.shade200),
  OnboardingContent(
      title: "Your Personal App Store",
      description:
          "Easily install, update, or remove applications from your server. sysAdmin puts package management in your hands, making updates and maintenance a breeze.",
      picture: "assets/onboarding/svgs/appStore.svg",
      bgColor: Colors.purpleAccent),
];
