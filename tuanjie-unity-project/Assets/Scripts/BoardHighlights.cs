using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoardHighlights : MonoBehaviour
{
    public static BoardHighlights Instance { set; get; }

    public GameObject BlueHighlightPrefab;
    public GameObject YellowHighlightPrefab;
    public GameObject RedHighlightPrefab;
    public GameObject PurpleHighlightPrefab;
    public GameObject CheckHighlightPrefab;

    private GameObject[,] BlueTiles = new GameObject[8, 8];
    private GameObject[,] YellowTiles = new GameObject[8, 8];
    private GameObject[,] RedTiles = new GameObject[8, 8];
    private GameObject[,] PurpleTiles = new GameObject[8, 8];
    private GameObject[,] CheckTiles = new GameObject[8, 8];

    private void Start()
    {
        Instance = this;
        PlaceAllTiles();
    }

    public void PlaceAllTiles()
    {
        GameObject tile;
        for (int i = 0; i < 8; i++)
        {
            for (int j = 0; j < 8; j++)
            {
                // Blue Tiles
                tile = Instantiate(BlueHighlightPrefab);
                tile.transform.position = new Vector3(i, 0.0001f, j);
                tile.transform.SetParent(this.transform);
                BlueTiles[i, j] = tile;
                // Yellow Tiles
                tile = Instantiate(YellowHighlightPrefab);
                tile.transform.position = new Vector3(i, 0.0001f, j);
                tile.transform.SetParent(this.transform);
                YellowTiles[i, j] = tile;
                // Red Tiles
                tile = Instantiate(RedHighlightPrefab);
                tile.transform.position = new Vector3(i, 0.0001f, j);
                tile.transform.SetParent(this.transform);
                RedTiles[i, j] = tile;
                // Purple Tiles
                tile = Instantiate(PurpleHighlightPrefab);
                tile.transform.position = new Vector3(i, 0.0001f, j);
                tile.transform.SetParent(this.transform);
                PurpleTiles[i, j] = tile;
                // Check Tiles
                tile = Instantiate(CheckHighlightPrefab);
                tile.transform.position = new Vector3(i, 0.0001f, j);
                tile.transform.SetParent(this.transform);
                CheckTiles[i, j] = tile;
            }
        }
    }

    public void DisableAllHighlights()
    {
        for(int i=0; i<8; i++)
        {
            for(int j=0; j<8; j++)
            {
                BlueTiles[i, j].SetActive(false);
                YellowTiles[i, j].SetActive(false);
                RedTiles[i, j].SetActive(false);
                PurpleTiles[i, j].SetActive(false);
                CheckTiles[i, j].SetActive(false);
            }
        }
    }

    public void SetTileBlue(int x, int y)
    {
        BlueTiles[x, y].SetActive(true);
    }

    public void SetTileYellow(int x, int y)
    {
        YellowTiles[x, y].SetActive(true);
    }

    public void SetTileRed(int x, int y)
    {
        RedTiles[x, y].SetActive(true);
    }

    public void SetTilePurple(int x, int y)
    {
        PurpleTiles[x, y].SetActive(true);
    }

    public void SetTileCheck(int x, int y)
    {
        CheckTiles[x, y].SetActive(true);
    }

    public void HighlightPossibleMoves(bool[,] allowedMoves, bool White)
    {
        for(int i=0; i<8; i++)
        {
            for(int j=0; j<8; j++)
            {
                if(allowedMoves[i,j])
                {
                    // Highlight Opponent
                    if(BoardManager.Instance.Chessmans[i,j] != null && BoardManager.Instance.Chessmans[i, j].isWhite != White)
                    {
                        SetTileRed(i, j);
                    }
                    else
                    {
                        // Highlight EnPassant move
                        if (BoardManager.Instance.EnPassant[0] == i && BoardManager.Instance.EnPassant[1] == j 
                            && BoardManager.Instance.SelectedChessman.GetType() == typeof(Pawn))
                            SetTilePurple(i, j);
                        // Highlight Castling move
                        else if (BoardManager.Instance.SelectedChessman.GetType() == typeof(King) 
                            && System.Math.Abs(i - BoardManager.Instance.SelectedChessman.currentX) == 2)
                            SetTilePurple(i, j);
                        // Highlight Empty Cell
                        else
                            SetTileBlue(i, j);
                    }
                }
            }
        }
    }

    public void HighlightCheckmate(bool isWhiteTurn)
    {
        Chessman king;
        if(isWhiteTurn)
            king = BoardManager.Instance.WhiteKing;
        else
            king = BoardManager.Instance.BlackKing;

        int x = king.currentX;
        int y = king.currentY;

        // Current Position
        HighlightCheckers(x , y, king);

        // Down
        HighlightCheckers(x , y - 1, king);

        // Left
        HighlightCheckers(x - 1, y , king);

        // Right
        HighlightCheckers(x + 1, y , king);

        // Up
        HighlightCheckers(x , y + 1, king);

        // DownLeft
        HighlightCheckers(x - 1, y - 1, king);

        // DownRight
        HighlightCheckers(x + 1, y - 1, king);

        // UpLeft
        HighlightCheckers(x - 1, y + 1, king);

        // UpRight
        HighlightCheckers(x + 1, y + 1, king);
    }

    private void HighlightCheckers(int x, int y, Chessman king)
    {
        Chessman[,] Chessmans = BoardManager.Instance.Chessmans;
        Chessman piece = null;

        if(!(x >= 0 && x <= 7 && y >= 0 && y <= 7))
            return;

        int X = x;
        int Y = y;

        // Down - adjacent King check
        if(y - 1 >= 0)
        {
            piece = BoardManager.Instance.Chessmans[x, y - 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x, y - 1);
        }
        // Down - long range Rook/Queen check
        while (y-- > 0)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // Right - adjacent King check
        if(x + 1 <= 7)
        {
            piece = BoardManager.Instance.Chessmans[x + 1, y];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x + 1, y);
        }
        // Right - long range Rook/Queen check
        while (x++ < 7)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // Left - adjacent King check
        if(x - 1 >= 0)
        {
            piece = BoardManager.Instance.Chessmans[x - 1, y];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x - 1, y);
        }
        // Left - long range Rook/Queen check
        while (x-- > 0)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // Up - adjacent King check
        if(y + 1 <= 7)
        {
            piece = BoardManager.Instance.Chessmans[x, y + 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x, y + 1);
        }
        // Up - long range Rook/Queen check
        while (y++ < 7)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Rook) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // LR Down Diagonal - Pawn check (white king threatened by black pawn)
        if(x + 1 <= 7 && y - 1 >= 0 && king.isWhite)
        {
            piece = BoardManager.Instance.Chessmans[x + 1, y - 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(Pawn))
                SetTileRed(x + 1, y - 1);
        }
        // LR Down Diagonal - adjacent King check
        if(x + 1 <= 7 && y - 1 >= 0)
        {
            piece = BoardManager.Instance.Chessmans[x + 1, y - 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x + 1, y - 1);
        }
        // LR Down Diagonal - long range Bishop/Queen check
        while (x++ < 7 && y-- > 0)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // LR Up Diagonal - Pawn check (black king threatened by white pawn)
        if(x + 1 <= 7 && y + 1 <= 7 && !king.isWhite)
        {
            piece = BoardManager.Instance.Chessmans[x + 1, y + 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(Pawn))
                SetTileRed(x + 1, y + 1);
        }
        // LR Up Diagonal - adjacent King check
        if(x + 1 <= 7 && y + 1 <= 7)
        {
            piece = BoardManager.Instance.Chessmans[x + 1, y + 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x + 1, y + 1);
        }
        // LR Up Diagonal - long range Bishop/Queen check
        while (x++ < 7 && y++ < 7)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // RL Down Diagonal - Pawn check (white king threatened by black pawn)
        if(x - 1 >= 0 && y - 1 >= 0 && king.isWhite)
        {
            piece = BoardManager.Instance.Chessmans[x - 1, y - 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(Pawn))
                SetTileRed(x - 1, y - 1);
        }
        // RL Down Diagonal - adjacent King check
        if(x - 1 >= 0 && y - 1 >= 0)
        {
            piece = BoardManager.Instance.Chessmans[x - 1, y - 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x - 1, y - 1);
        }
        // RL Down Diagonal - long range Bishop/Queen check
        while (x-- > 0 && y-- > 0)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // RL Up Diagonal - Pawn check (black king threatened by white pawn)
        if(x - 1 >= 0 && y + 1 <= 7 && !king.isWhite)
        {
            piece = BoardManager.Instance.Chessmans[x - 1, y + 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(Pawn))
                SetTileRed(x - 1, y + 1);
        }
        // RL Up Diagonal - adjacent King check
        if(x - 1 >= 0 && y + 1 <= 7)
        {
            piece = BoardManager.Instance.Chessmans[x - 1, y + 1];
            if(piece != null && piece.isWhite != king.isWhite && piece.GetType() == typeof(King))
                SetTileRed(x - 1, y + 1);
        }
        // RL Up Diagonal - long range Bishop/Queen check
        while (x-- > 0 && y++ < 7)
        {
            piece = BoardManager.Instance.Chessmans[x, y];
            if (piece == null) continue;
            else if (piece.isWhite == king.isWhite) break;
            if(piece.GetType() == typeof(Bishup) || piece.GetType() == typeof(Queen))
                SetTileRed(x, y);
            break;
        }

        x = X; y = Y;
        // Knight Threats - check all 8 positions without early return
        if(king.KnightThreat(x - 1, y - 2)) SetTileRed(x - 1, y - 2);
        if(king.KnightThreat(x + 1, y - 2)) SetTileRed(x + 1, y - 2);
        if(king.KnightThreat(x + 2, y - 1)) SetTileRed(x + 2, y - 1);
        if(king.KnightThreat(x + 2, y + 1)) SetTileRed(x + 2, y + 1);
        if(king.KnightThreat(x - 2, y - 1)) SetTileRed(x - 2, y - 1);
        if(king.KnightThreat(x - 2, y + 1)) SetTileRed(x - 2, y + 1);
        if(king.KnightThreat(x - 1, y + 2)) SetTileRed(x - 1, y + 2);
        if(king.KnightThreat(x + 1, y + 2)) SetTileRed(x + 1, y + 2);
    }
}
