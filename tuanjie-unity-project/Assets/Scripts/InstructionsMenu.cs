using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Instructions page controller. Shows chess rules and how to play.
/// Attach to a Canvas with an instructions panel UI.
/// </summary>
public class InstructionsMenu : MonoBehaviour
{
    public GameObject instructionsPanel;
    public Text instructionsText;

    private void Start()
    {
        if (instructionsText != null)
            instructionsText.text = GetInstructionsContent();

        if (instructionsPanel != null)
            instructionsPanel.SetActive(false);
    }

    public void ShowInstructions()
    {
        if (instructionsPanel != null)
        {
            instructionsPanel.SetActive(true);
            Time.timeScale = 0f;
        }
    }

    public void HideInstructions()
    {
        if (instructionsPanel != null)
        {
            instructionsPanel.SetActive(false);
            Time.timeScale = 1f;
        }
    }

    private string GetInstructionsContent()
    {
        return
            "<b>HOW TO PLAY</b>\n\n" +
            "<b>Selecting a Piece:</b>\n" +
            "Click on one of your pieces (White) to select it.\n" +
            "The selected piece will be highlighted in yellow.\n" +
            "Valid moves are shown in blue, captures in red,\n" +
            "and special moves (castling/en passant) in purple.\n\n" +

            "<b>Making a Move:</b>\n" +
            "Click on a highlighted square to move your piece there.\n" +
            "Click on another one of your pieces to switch selection.\n\n" +

            "<b>Chess Piece Rules:</b>\n" +
            "- King: Moves 1 square in any direction. Cannot move into check.\n" +
            "- Queen: Moves any number of squares in any direction.\n" +
            "- Rook: Moves any number of squares horizontally or vertically.\n" +
            "- Bishop: Moves any number of squares diagonally.\n" +
            "- Knight: Moves in an L-shape (2+1 squares). Can jump over pieces.\n" +
            "- Pawn: Moves 1 square forward. Captures diagonally.\n" +
            "  First move can be 2 squares forward.\n\n" +

            "<b>Special Moves:</b>\n" +
            "- Castling: King moves 2 squares toward a rook (shown in purple).\n" +
            "  Neither piece must have moved, and the king cannot be in check.\n" +
            "- En Passant: A pawn can capture an opponent's pawn that just\n" +
            "  moved 2 squares forward, as if it only moved 1 (shown in purple).\n" +
            "- Promotion: When a pawn reaches the last rank, it becomes a queen.\n\n" +

            "<b>Winning:</b>\n" +
            "Checkmate your opponent's king to win!\n" +
            "If no legal moves remain but the king is not in check,\n" +
            "the game is a draw (stalemate).\n\n" +

            "<b>Controls:</b>\n" +
            "- Press ESC to pause the game.\n" +
            "- Press U to undo your last move.";
    }
}
