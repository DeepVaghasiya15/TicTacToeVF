import 'package:flutter/material.dart';
import 'package:flutter_tic_tac_toe/UserAuthentication/LogIn.dart';
import 'package:flutter_tic_tac_toe/screens/players_names_screen.dart';
import 'package:flutter_tic_tac_toe/theme/app_sizes.dart';
import 'package:flutter_tic_tac_toe/theme/colors.dart';
import 'package:flutter_tic_tac_toe/widgets/wrapper_container.dart';
import 'game_base_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  List<bool> textClicked = [false, false];

  void _onTextClicked(int index) {
    setState(() {
      textClicked[index] = true;
      if (textClicked.every((clicked) => clicked)) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        textClicked = [false, false]; // Reset after navigation
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WrapperContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _onTextClicked(0),
                  child: const Text(
                    'Tic',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  "Tac",
                  style: TextStyle(
                    fontFamily: 'PermanentMarker',
                    fontSize: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _onTextClicked(1),
                  child: const Text(
                    'Toe',
                    style: TextStyle(
                      fontFamily: 'PermanentMarker',
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            gap2XL(),
            Image.asset(
              "assets/OXlogo.png",
              width: 200,
              height: 200,
            ),
            gap4XL(),
            gap4XL(),
            MainMenuButtons(
              btnText: 'Single Player',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameBaseScreen(
                      playerOName: "AI",
                      playerXName: "You",
                      isAgainstAI: true,
                    ),
                  ),
                );
              },
            ),
            gapXL(),
            MainMenuButtons(
              btnText: 'Multiplayer',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlayerNames()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MainMenuButtons extends StatelessWidget {
  const MainMenuButtons(
      {super.key, required this.btnText, required this.onPressed});

  final String btnText;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.kWhitish,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            btnText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
