import 'package:flutter/material.dart';
import 'package:flutter_tic_tac_toe/theme/app_sizes.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.playerXScore,
    required this.playerOScore,
    required this.isTurn,
    required this.playerXName,
    required this.playerOName,
  });

  final int playerXScore;
  final int playerOScore;
  final bool isTurn;
  final String playerXName;
  final String playerOName;

  Widget _buildPlayerScore(String playerLabel, int score, bool isTurn) =>
      Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: GameColors.kWhitish,
          borderRadius: borderRadiusM(),
          border: isTurn
              ? playerLabel == playerXName
                  ? Border.all(
                      color: Colors.green,
                      width: 2.0,
                    )
                  : Border.all(
                      color: Colors.red,
                      width: 2.0,
                    )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              playerLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: playerLabel == playerXName ? Colors.green : Colors.red,
              ),
            ),
            Text(
              score.toString(),
              style: TextStyle(
                fontSize: 26,
                fontFamily: GoogleFonts.caveat().fontFamily,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerScore(playerXName, playerXScore, isTurn),
          _buildPlayerScore(playerOName, playerOScore, !isTurn),
        ],
      );
}
