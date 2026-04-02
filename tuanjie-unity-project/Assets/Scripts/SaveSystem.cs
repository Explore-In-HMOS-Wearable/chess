using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Saves and loads the chess board state using PlayerPrefs (JSON serialization).
/// Call SaveGame() on pause/exit, LoadGame() on "Continue" from main menu.
/// </summary>
public class SaveSystem : MonoBehaviour
{
    public static SaveSystem Instance { get; private set; }

    private const string SAVE_KEY = "ChessSaveData";

    private void Awake()
    {
        Instance = this;
    }

    public bool HasSavedGame()
    {
        return PlayerPrefs.HasKey(SAVE_KEY);
    }

    public void DeleteSave()
    {
        PlayerPrefs.DeleteKey(SAVE_KEY);
        PlayerPrefs.Save();
    }

    public void SaveGame()
    {
        SaveData data = new SaveData();
        data.isWhiteTurn = BoardManager.Instance.isWhiteTurn;
        data.enPassantX = BoardManager.Instance.EnPassant[0];
        data.enPassantY = BoardManager.Instance.EnPassant[1];
        data.pieces = new List<PieceData>();

        Chessman[,] board = BoardManager.Instance.Chessmans;
        for (int x = 0; x < 8; x++)
        {
            for (int y = 0; y < 8; y++)
            {
                Chessman piece = board[x, y];
                if (piece != null)
                {
                    PieceData pd = new PieceData();
                    pd.x = x;
                    pd.y = y;
                    pd.isWhite = piece.isWhite;
                    pd.isMoved = piece.isMoved;
                    pd.type = GetPieceTypeName(piece);
                    data.pieces.Add(pd);
                }
            }
        }

        string json = JsonUtility.ToJson(data);
        PlayerPrefs.SetString(SAVE_KEY, json);
        PlayerPrefs.Save();
        Debug.Log("Game saved.");
    }

    public bool LoadGame()
    {
        if (!HasSavedGame()) return false;

        string json = PlayerPrefs.GetString(SAVE_KEY);
        SaveData data = JsonUtility.FromJson<SaveData>(json);

        if (data == null || data.pieces == null) return false;

        // Store data for BoardManager to use when scene loads
        PendingLoad = data;
        return true;
    }

    // Pending load data - BoardManager reads this on Start
    public static SaveData PendingLoad { get; set; }

    public void ApplyLoadedGame(SaveData data)
    {
        if (data == null) return;

        BoardManager bm = BoardManager.Instance;

        // Clear current board
        bm.EndGame();

        // Clear default spawned pieces
        // EndGame already respawns - we need to clear again
        foreach (var go in GameObject.FindGameObjectsWithTag("Untagged"))
        {
            Chessman c = go.GetComponent<Chessman>();
            if (c != null)
                Destroy(go);
        }

        // Reset board array
        bm.Chessmans = new Chessman[8, 8];
        bm.isWhiteTurn = data.isWhiteTurn;
        bm.EnPassant = new int[2] { data.enPassantX, data.enPassantY };

        // Spawn pieces from save data
        foreach (PieceData pd in data.pieces)
        {
            int prefabIndex = GetPrefabIndex(pd.type, pd.isWhite);
            if (prefabIndex < 0) continue;

            SpawnSavedPiece(bm, prefabIndex, pd.x, pd.y, pd.isMoved);
        }

        // Restore king and rook references
        for (int x = 0; x < 8; x++)
        {
            for (int y = 0; y < 8; y++)
            {
                Chessman piece = bm.Chessmans[x, y];
                if (piece == null) continue;

                if (piece.GetType() == typeof(King))
                {
                    if (piece.isWhite) bm.WhiteKing = piece;
                    else bm.BlackKing = piece;
                }
                else if (piece.GetType() == typeof(Rook))
                {
                    if (piece.isWhite)
                    {
                        if (x < 4) bm.WhiteRook1 = piece;
                        else bm.WhiteRook2 = piece;
                    }
                    else
                    {
                        if (x < 4) bm.BlackRook1 = piece;
                        else bm.BlackRook2 = piece;
                    }
                }
            }
        }

        Debug.Log("Game loaded.");
        DeleteSave();
    }

    private void SpawnSavedPiece(BoardManager bm, int prefabIndex, int x, int y, bool isMoved)
    {
        GameObject prefab = bm.ChessmanPrefabs[prefabIndex];
        GameObject obj = Instantiate(prefab, new Vector3(x, 0, y), prefab.transform.rotation);
        obj.transform.SetParent(bm.transform);

        Chessman piece = obj.GetComponent<Chessman>();
        bm.Chessmans[x, y] = piece;
        piece.SetPosition(x, y);
        piece.isMoved = isMoved;
    }

    private string GetPieceTypeName(Chessman piece)
    {
        if (piece.GetType() == typeof(King)) return "King";
        if (piece.GetType() == typeof(Queen)) return "Queen";
        if (piece.GetType() == typeof(Rook)) return "Rook";
        if (piece.GetType() == typeof(Bishup)) return "Bishop";
        if (piece.GetType() == typeof(Knight)) return "Knight";
        if (piece.GetType() == typeof(Pawn)) return "Pawn";
        return "Unknown";
    }

    private int GetPrefabIndex(string type, bool isWhite)
    {
        // White prefabs: 0=Rook, 1=Knight, 2=Bishop, 3=King, 4=Queen, 5=Pawn
        // Black prefabs: 6=Rook, 7=Knight, 8=Bishop, 9=King, 10=Queen, 11=Pawn
        int offset = isWhite ? 0 : 6;
        switch (type)
        {
            case "Rook": return 0 + offset;
            case "Knight": return 1 + offset;
            case "Bishop": return 2 + offset;
            case "King": return 3 + offset;
            case "Queen": return 4 + offset;
            case "Pawn": return 5 + offset;
            default: return -1;
        }
    }
}

[System.Serializable]
public class SaveData
{
    public bool isWhiteTurn;
    public int enPassantX;
    public int enPassantY;
    public List<PieceData> pieces;
}

[System.Serializable]
public class PieceData
{
    public int x;
    public int y;
    public bool isWhite;
    public bool isMoved;
    public string type;
}
