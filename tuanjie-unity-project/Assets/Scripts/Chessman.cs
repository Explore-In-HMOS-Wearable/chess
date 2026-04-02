using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class Chessman : MonoBehaviour
{
    public int currentX { set; get; }
    public int currentY { set; get; }
    public bool isWhite;
    public int value;
    public bool isMoved = false;

    public Chessman Clone()
    {
       return (Chessman) this.MemberwiseClone();
    }

    public void SetPosition(int x, int y)
    {
        currentX = x;
        currentY = y;
    }

    public virtual bool[,] PossibleMoves()
    {
        bool[,] arr = new bool[8,8];
        for(int i=0; i<8; i++)
        {
            for(int j=0; j<8; j++)
            {
                arr[i, j] = false;
            }
        }
        return arr;
    }

    public bool InDanger()
    {
        Chessman[,] board = BoardManager.Instance.Chessmans;
        Chessman piece;
        int x = currentX;
        int y = currentY;

        // Down - adjacent King
        if(y - 1 >= 0)
        {
            piece = board[x, y - 1];
            if(piece != null && piece.isWhite != isWhite && piece.GetType() == typeof(King))
                return true;
        }
        // Down - Rook/Queen
        while (y-- > 0)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // Right - adjacent King
        if(x + 1 <= 7)
        {
            piece = board[x + 1, y];
            if(piece != null && piece.isWhite != isWhite && piece.GetType() == typeof(King))
                return true;
        }
        // Right - Rook/Queen
        while (x++ < 7)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // Left - adjacent King
        if(x - 1 >= 0)
        {
            piece = board[x - 1, y];
            if(piece != null && piece.isWhite != isWhite && piece.GetType() == typeof(King))
                return true;
        }
        // Left - Rook/Queen
        while (x-- > 0)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // Up - adjacent King
        if(y + 1 <= 7)
        {
            piece = board[x, y + 1];
            if(piece != null && piece.isWhite != isWhite && piece.GetType() == typeof(King))
                return true;
        }
        // Up - Rook/Queen
        while (y++ < 7)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // LR Down Diagonal - Pawn (white threatened by black pawn)
        if(x + 1 <= 7 && y - 1 >= 0)
        {
            piece = board[x + 1, y - 1];
            if(piece != null && piece.isWhite != isWhite)
            {
                if((isWhite && piece.GetType() == typeof(Pawn)) || piece.GetType() == typeof(King))
                    return true;
            }
        }
        // LR Down Diagonal - Bishop/Queen
        while (x++ < 7 && y-- > 0)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // LR Up Diagonal - Pawn (black threatened by white pawn)
        if(x + 1 <= 7 && y + 1 <= 7)
        {
            piece = board[x + 1, y + 1];
            if(piece != null && piece.isWhite != isWhite)
            {
                if((!isWhite && piece.GetType() == typeof(Pawn)) || piece.GetType() == typeof(King))
                    return true;
            }
        }
        // LR Up Diagonal - Bishop/Queen
        while (x++ < 7 && y++ < 7)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // RL Down Diagonal - Pawn/King
        if(x - 1 >= 0 && y - 1 >= 0)
        {
            piece = board[x - 1, y - 1];
            if(piece != null && piece.isWhite != isWhite)
            {
                if((isWhite && piece.GetType() == typeof(Pawn)) || piece.GetType() == typeof(King))
                    return true;
            }
        }
        // RL Down Diagonal - Bishop/Queen
        while (x-- > 0 && y-- > 0)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // RL Up Diagonal - Pawn/King
        if(x - 1 >= 0 && y + 1 <= 7)
        {
            piece = board[x - 1, y + 1];
            if(piece != null && piece.isWhite != isWhite)
            {
                if((!isWhite && piece.GetType() == typeof(Pawn)) || piece.GetType() == typeof(King))
                    return true;
            }
        }
        // RL Up Diagonal - Bishop/Queen
        while (x-- > 0 && y++ < 7)
        {
            piece = board[x, y];
            if (piece == null) continue;
            if (piece.isWhite == isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                return true;
            break;
        }

        x = currentX; y = currentY;
        // Knight Threats
        if(KnightThreat(x - 1, y - 2, board)) return true;
        if(KnightThreat(x + 1, y - 2, board)) return true;
        if(KnightThreat(x + 2, y - 1, board)) return true;
        if(KnightThreat(x + 2, y + 1, board)) return true;
        if(KnightThreat(x - 2, y - 1, board)) return true;
        if(KnightThreat(x - 2, y + 1, board)) return true;
        if(KnightThreat(x - 1, y + 2, board)) return true;
        if(KnightThreat(x + 1, y + 2, board)) return true;

        return false;
    }

    private bool KnightThreat(int x, int y, Chessman[,] board)
    {
        if (x >= 0 && y >= 0 && x <= 7 && y <= 7)
        {
            Chessman piece = board[x, y];
            if(piece != null && piece.isWhite != isWhite && piece.GetType() == typeof(Knight))
                return true;
        }
        return false;
    }

    public bool KnightThreat(int x, int y)
    {
        return KnightThreat(x, y, BoardManager.Instance.Chessmans);
    }

    public bool KingInDanger(int x, int y)
    {
        // Critical Part : 
        // We are about to move piece on the chessboard(not in the scene) without yet recieving command
        // To check whether this move will put King in danger/Check State or not
        // So that we can disallowed the move
        // After checking we will undo the move we have made
        // And every change will be undone only in this function
        // Again : this won't have any effect on the scene

        // ------------- Backup start -------------
        // Storing the reference of chessman where we are about to move
        Chessman tmpChessman = BoardManager.Instance.Chessmans[x, y];
        int tmpCurrentX = currentX;
        int tmpCurrentY = currentY;
        // ------------- Backup end -------------

        // Leaving the position, making the move, updating co-ordinates
        BoardManager.Instance.Chessmans[currentX, currentY] = null;
        BoardManager.Instance.Chessmans[x, y] = this;
        this.SetPosition(x, y);

        // We will store the decision in result
        bool result = false;
        // Now checking whether the King is in danger now or not
        if(isWhite)
            result = BoardManager.Instance.WhiteKing.InDanger();
        else
            result = BoardManager.Instance.BlackKing.InDanger();

        // Now Undoing
        this.SetPosition(tmpCurrentX, tmpCurrentY);
        BoardManager.Instance.Chessmans[tmpCurrentX, tmpCurrentY] = this;
        BoardManager.Instance.Chessmans[x, y] = tmpChessman;
        

        // Return the result
        return result;
    }
}
