import 'package:flutter/material.dart';

class GameSelector extends StatelessWidget {
  final List<String> games;
  final int selectedIndex;
  final Function(int) onSelected;

  const GameSelector({
    required this.games,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white, // Floating style
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8, // Space between items
        runSpacing: 8, // Space between rows
        alignment: WrapAlignment.center, // Center-align the items
        children: List.generate(games.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                games[index],
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }),
      ),
    );
  }
}
