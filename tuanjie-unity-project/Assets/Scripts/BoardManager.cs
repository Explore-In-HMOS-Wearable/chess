using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoardManager : MonoBehaviour
{
    public static BoardManager Instance { set; get; }

    private const float TILE_SIZE = 1.0f;
    private const float TILE_OFFSET = TILE_SIZE / 2;

    // Camera
    private Camera cam;

    // List of Chessman prefabs
    public List<GameObject> ChessmanPrefabs;
    // List of chessmans being on the board
    private List<GameObject> ActiveChessmans;
    // Array of the chessmans present on the particular board cell
    public Chessman[,] Chessmans{ set; get; }
    // Currently Selected Chessman
    public Chessman SelectedChessman;
    // Kings
    public Chessman WhiteKing;
    public Chessman BlackKing;
    public Chessman WhiteRook1;
    public Chessman WhiteRook2;
    public Chessman BlackRook1;
    public Chessman BlackRook2;

    // Allowed moves
    public bool[,] allowedMoves;
    // EnPassant move
    public int[] EnPassant { set; get; }

    // The selected tile
    private int selectionX = -1;
    private int selectionY = -1;

    // Variable to store turn
    public bool isWhiteTurn = true;

    // Game result for display
    public bool isStalemate { get; private set; }

    // Move history for undo
    private Stack<MoveRecord> moveHistory = new Stack<MoveRecord>();

    private void Start()
    {
        Instance = this;
        cam = FindObjectOfType<Camera>();
        ActiveChessmans = new List<GameObject>();
        Chessmans = new Chessman[8, 8];
        EnPassant = new int[2] { -1, -1 };


        // Spawning all chessmans on the board
        SpawnAllChessmans();
    }

    private void Update()
    {
        // Update Selected tile
        UpdateSelection();
        // Draw chessboard in every frame update
        DrawChessBoard();

        // Undo is now handled via UI button (see GameHUD)

        // Select/Move chessman on mouse click & it is Player's turn : White
        if(Input.GetMouseButtonDown(0) && isWhiteTurn)
        {
            if (selectionX >= 0 && selectionY >= 0 && selectionX <= 7 && selectionY <= 7)
            {
                // if no chessman is selected then we need to select it first
                if (SelectedChessman == null)
                {
                    SelectChessman();
                }
                // if chessman is already selected then we need to move it
                else
                {
                    MoveChessman(selectionX, selectionY);
                }
            }
        }
        // // If it is NPC's turn : Black
        else if(!isWhiteTurn)
        {
            // NPC will make a move
            ChessAI.Instance.NPCMove();
        }
        
    }

    private void SelectChessman()
    {
        // if no chessman is on the clicked tile
        if (Chessmans[selectionX, selectionY] == null) return;
        // if it is not the turn of the selected chessman's team
        if (Chessmans[selectionX, selectionY].isWhite != isWhiteTurn) return;

        // Selecting chessman with yellow highlight
        SelectedChessman = Chessmans[selectionX, selectionY];
        if(AudioManager.Instance != null) AudioManager.Instance.PlaySelect();
        BoardHighlights.Instance.SetTileYellow(selectionX, selectionY);

        // Allowed moves highlighted in blue and enemy in Red
        allowedMoves = SelectedChessman.PossibleMoves();
        BoardHighlights.Instance.HighlightPossibleMoves(allowedMoves, isWhiteTurn);
    }

    public void MoveChessman(int x, int y)
    {
        // If clicking on own piece, re-select it instead of trying to move
        if(Chessmans[x, y] != null && Chessmans[x, y].isWhite == SelectedChessman.isWhite && Chessmans[x, y] != SelectedChessman)
        {
            BoardHighlights.Instance.DisableAllHighlights();
            SelectedChessman = Chessmans[x, y];
            BoardHighlights.Instance.SetTileYellow(x, y);
            allowedMoves = SelectedChessman.PossibleMoves();
            BoardHighlights.Instance.HighlightPossibleMoves(allowedMoves, isWhiteTurn);
            return;
        }

        if(allowedMoves[x,y])
        {
            // -------Record move for undo-------
            MoveRecord record = new MoveRecord();
            record.movedPiece = SelectedChessman;
            record.fromX = SelectedChessman.currentX;
            record.fromY = SelectedChessman.currentY;
            record.toX = x;
            record.toY = y;
            record.wasMoved = SelectedChessman.isMoved;
            record.prevEnPassantX = EnPassant[0];
            record.prevEnPassantY = EnPassant[1];

            Chessman opponent = Chessmans[x, y];
            bool wasCapture = false;
            bool wasCastling = false;
            bool wasPromotion = false;

            if(opponent != null)
            {
                wasCapture = true;

                // Nullify rook references if a rook is captured
                if(opponent == WhiteRook1) WhiteRook1 = null;
                else if(opponent == WhiteRook2) WhiteRook2 = null;
                else if(opponent == BlackRook1) BlackRook1 = null;
                else if(opponent == BlackRook2) BlackRook2 = null;

                // Capture: deactivate instead of destroy for undo support
                record.capturedPieceObject = opponent.gameObject;
                record.capturedX = x;
                record.capturedY = y;
                ActiveChessmans.Remove(opponent.gameObject);
                opponent.gameObject.SetActive(false);
            }
            // -------EnPassant Move Manager------------
            if (EnPassant[0] == x && EnPassant[1] == y && SelectedChessman.GetType() == typeof(Pawn))
            {
                wasCapture = true;
                if(isWhiteTurn)
                    opponent = Chessmans[x, y + 1];
                else
                    opponent = Chessmans[x, y - 1];

                record.capturedPieceObject = opponent.gameObject;
                record.capturedX = opponent.currentX;
                record.capturedY = opponent.currentY;
                Chessmans[opponent.currentX, opponent.currentY] = null;
                ActiveChessmans.Remove(opponent.gameObject);
                opponent.gameObject.SetActive(false);
            }

            // Reset the EnPassant move
            EnPassant[0] = EnPassant[1] = -1;

            // Set EnPassant available for opponent
            if(SelectedChessman.GetType() == typeof(Pawn))
            {
                //-------Promotion Move Manager------------
                if (y == 7)
                {
                    wasPromotion = true;
                    record.wasPromotion = true;
                    record.originalPawnObject = SelectedChessman.gameObject;
                    record.promotionPrefabIndex = 10;
                    ActiveChessmans.Remove(SelectedChessman.gameObject);
                    SelectedChessman.gameObject.SetActive(false);
                    SpawnChessman(10, new Vector3(x, 0, y));
                    SelectedChessman = Chessmans[x, y];
                    record.promotedPieceObject = SelectedChessman.gameObject;
                }
                if (y == 0)
                {
                    wasPromotion = true;
                    record.wasPromotion = true;
                    record.originalPawnObject = SelectedChessman.gameObject;
                    record.promotionPrefabIndex = 4;
                    ActiveChessmans.Remove(SelectedChessman.gameObject);
                    SelectedChessman.gameObject.SetActive(false);
                    SpawnChessman(4, new Vector3(x, 0, y));
                    SelectedChessman = Chessmans[x, y];
                    record.promotedPieceObject = SelectedChessman.gameObject;
                }
                //-------Promotion Move Manager Over-------

                if (SelectedChessman.currentY == 1 && y == 3)
                {
                    EnPassant[0] = x;
                    EnPassant[1] = y - 1;
                }
                if (SelectedChessman.currentY == 6 && y == 4)
                {
                    EnPassant[0] = x;
                    EnPassant[1] = y + 1;
                }
            }
            // -------EnPassant Move Manager Over-------

            // -------Castling Move Manager------------
            if(SelectedChessman.GetType() == typeof(King) && System.Math.Abs(x - SelectedChessman.currentX) == 2)
            {
                wasCastling = true;
                record.wasCastling = true;
                // King Side (towards (0, 0))
                if(x - SelectedChessman.currentX < 0)
                {
                    record.castleKingSide = true;
                    record.rookFromX = x - 1;
                    record.rookToX = x + 1;
                    record.rookY = y;
                    record.rookWasMoved = Chessmans[x - 1, y].isMoved;

                    Chessmans[x + 1, y] = Chessmans[x - 1, y];
                    Chessmans[x - 1, y] = null;
                    Chessmans[x + 1, y].SetPosition(x + 1, y);
                    Chessmans[x + 1, y].transform.position = new Vector3(x + 1, 0, y);
                    Chessmans[x + 1, y].isMoved = true;
                }
                // Queen side (away from (0, 0))
                else
                {
                    record.castleKingSide = false;
                    record.rookFromX = x + 2;
                    record.rookToX = x - 1;
                    record.rookY = y;
                    record.rookWasMoved = Chessmans[x + 2, y].isMoved;

                    Chessmans[x - 1, y] = Chessmans[x + 2, y];
                    Chessmans[x + 2, y] = null;
                    Chessmans[x - 1, y].SetPosition(x - 1, y);
                    Chessmans[x - 1, y].transform.position = new Vector3(x - 1, 0, y);
                    Chessmans[x - 1, y].isMoved = true;
                }
            }
            // -------Castling Move Manager Over-------

            Chessmans[SelectedChessman.currentX, SelectedChessman.currentY] = null;
            Chessmans[x, y] = SelectedChessman;
            SelectedChessman.SetPosition(x, y);
            SelectedChessman.transform.position = new Vector3(x, 0, y);
            SelectedChessman.isMoved = true;
            isWhiteTurn = !isWhiteTurn;

            // Save move record
            moveHistory.Push(record);

            // Play appropriate sound effect
            if(AudioManager.Instance != null)
            {
                if(wasPromotion) AudioManager.Instance.PlayPromote();
                else if(wasCastling) AudioManager.Instance.PlayCastle();
                else if(wasCapture) AudioManager.Instance.PlayCapture();
                else AudioManager.Instance.PlayMove();
            }
        }

        // De-select the selected chessman
        SelectedChessman = null;
        // Disabling all highlights
        BoardHighlights.Instance.DisableAllHighlights();

        // ------- King Check Alert Manager -----------
        // Is it Check to the King
        // If now White King is in Check
        if(isWhiteTurn)
        {
            if(WhiteKing.InDanger())
            {
                BoardHighlights.Instance.SetTileCheck(WhiteKing.currentX, WhiteKing.currentY);
                if(AudioManager.Instance != null) AudioManager.Instance.PlayCheck();
            }
        }
        // If now Black King is in Check
        else
        {
            if(BlackKing.InDanger())
            {
                BoardHighlights.Instance.SetTileCheck(BlackKing.currentX, BlackKing.currentY);
                if(AudioManager.Instance != null) AudioManager.Instance.PlayCheck();
            }
        }
        // ------- King Check Alert Manager Over ----

       
        // Check if it is Checkmate
        isCheckmate();
    }

    private void UpdateSelection()
    {
        Ray ray = cam.ScreenPointToRay(Input.mousePosition);
        RaycastHit hit;
        if(Physics.Raycast(ray, out hit, 25.0f, LayerMask.GetMask("ChessPlane")))
        {
            // Debug.Log(hit.point);
            selectionX = (int)(hit.point.x + 0.5f);
            selectionY = (int)(hit.point.z + 0.5f);
        }
        else
        {
            selectionX = -1;
            selectionY = -1;
        }
    }

    private void DrawChessBoard()
    {
        Vector3 widthLine = Vector3.right * 8;
        Vector3 heightLine = Vector3.forward * 8;
        Vector3 offset = new Vector3(0.5f, 0f, 0.5f);
        for (int i=0; i<=8; i++)
        {
            Vector3 start = Vector3.forward * i - offset;
            Debug.DrawLine(start, start + widthLine);
            for(int j=0; j<=8; j++)
            {
                start = Vector3.right * i - offset;
                Debug.DrawLine(start, start + heightLine);
            }
        }
        

        // Draw Selection
        if(selectionX >= 0 && selectionY >= 0 && selectionX <= 7 && selectionY <= 7)
        {
            Debug.DrawLine(
                Vector3.forward * selectionY + Vector3.right * selectionX - offset,
                Vector3.forward * (selectionY + 1) + Vector3.right * (selectionX + 1) - offset
                );
            Debug.DrawLine(
                Vector3.forward * (selectionY + 1) + Vector3.right * selectionX - offset,
                Vector3.forward * selectionY + Vector3.right * (selectionX + 1) - offset
                );
        }
    }

    private void SpawnChessman(int index, Vector3 position)
    {
        GameObject ChessmanObject = Instantiate(ChessmanPrefabs[index], position, ChessmanPrefabs[index].transform.rotation) as GameObject;
        ChessmanObject.transform.SetParent(this.transform);
        ActiveChessmans.Add(ChessmanObject);

        int x = (int)(position.x);
        int y = (int)(position.z);
        Chessmans[x, y] = ChessmanObject.GetComponent<Chessman>();
        Chessmans[x, y].SetPosition(x, y);

    }
    
    private void SpawnAllChessmans()
    {
        // Spawn White Pieces
        // Rook1
        SpawnChessman(0, new Vector3(0, 0, 7));
        // Knight1
        SpawnChessman(1, new Vector3(1, 0, 7));
        // Bishop1
        SpawnChessman(2, new Vector3(2, 0, 7));
        // King
        SpawnChessman(3, new Vector3(3, 0, 7));
        // Queen
        SpawnChessman(4, new Vector3(4, 0, 7));
        // Bishop2
        SpawnChessman(2, new Vector3(5, 0, 7));
        // Knight2
        SpawnChessman(1, new Vector3(6, 0, 7));
        // Rook2
        SpawnChessman(0, new Vector3(7, 0, 7));
        // Pawns
        for(int i=0; i<8; i++)
        {
            SpawnChessman(5, new Vector3(i, 0, 6));
        }

        // Spawn Black Pieces
        // Rook1
        SpawnChessman(6, new Vector3(0, 0, 0));
        // Knight1
        SpawnChessman(7, new Vector3(1, 0, 0));
        // Bishop1
        SpawnChessman(8, new Vector3(2, 0, 0));
        // King
        SpawnChessman(9, new Vector3(3, 0, 0));
        // Queen
        SpawnChessman(10, new Vector3(4, 0, 0));
        // Bishop2
        SpawnChessman(8, new Vector3(5, 0, 0));
        // Knight2
        SpawnChessman(7, new Vector3(6, 0, 0));
        // Rook2
        SpawnChessman(6, new Vector3(7, 0, 0));
        // Pawns
        for (int i = 0; i < 8; i++)
        {
            SpawnChessman(11, new Vector3(i, 0, 1));
        }

        WhiteKing = Chessmans[3, 7];
        BlackKing = Chessmans[3, 0];

        WhiteRook1 = Chessmans[0, 7];
        WhiteRook2 = Chessmans[7, 7];
        BlackRook1 = Chessmans[0, 0];
        BlackRook2 = Chessmans[7, 0];
    }

    public void EndGame()
    {
        if (!isWhiteTurn)
            Debug.Log("White team wins");
        else
            Debug.Log("Black team wins");

        foreach (GameObject go in ActiveChessmans)
            Destroy(go);

        // New Game
        isWhiteTurn = true;
        BoardHighlights.Instance.DisableAllHighlights();
        SpawnAllChessmans();
    }

    private void isCheckmate()
    {
        bool hasAllowedMove = false;
        foreach(GameObject chessman in ActiveChessmans)
        {
            if(chessman.GetComponent<Chessman>().isWhite != isWhiteTurn)
                continue;

            bool[,] allowedMoves = chessman.GetComponent<Chessman>().PossibleMoves();

            for(int x=0; x<8; x++)
            {
                for(int y=0; y<8; y++)
                {
                    if(allowedMoves[x, y])
                    {
                        hasAllowedMove = true;
                        break;
                    }
                }
                if(hasAllowedMove) break;
            }
            if(hasAllowedMove) break;
        }

        if(!hasAllowedMove)
        {
            // Determine if it's checkmate or stalemate
            Chessman king = isWhiteTurn ? WhiteKing : BlackKing;
            bool kingInCheck = king.InDanger();

            if(kingInCheck)
            {
                isStalemate = false;
                BoardHighlights.Instance.HighlightCheckmate(isWhiteTurn);
                Debug.Log("Checkmate!");
                if(AudioManager.Instance != null)
                {
                    if(isWhiteTurn) AudioManager.Instance.PlayLose();
                    else AudioManager.Instance.PlayWin();
                }
            }
            else
            {
                isStalemate = true;
                Debug.Log("Stalemate - Draw!");
                if(AudioManager.Instance != null) AudioManager.Instance.PlayDraw();
            }

            Debug.Log("Average Response Time of computer (in seconds): " + (ChessAI.Instance.averageResponseTime/1000.0));

            // Delete save on game over
            if(SaveSystem.Instance != null) SaveSystem.Instance.DeleteSave();

            // Display Game Over Menu
            GameOver.Instance.GameOverMenu();
        }
    }

    /// <summary>
    /// Undoes both AI and player moves so it returns to the player's turn.
    /// Called from GameHUD undo button.
    /// </summary>
    public void UndoMove()
    {
        if(!isWhiteTurn || moveHistory.Count < 2) return;
        UndoLastMove(); // Undo AI move
        UndoLastMove(); // Undo player move
        BoardHighlights.Instance.DisableAllHighlights();
        SelectedChessman = null;
    }

    private void UndoLastMove()
    {
        if(moveHistory.Count == 0) return;

        MoveRecord record = moveHistory.Pop();

        // Undo promotion: destroy the promoted queen, reactivate original pawn
        if(record.wasPromotion)
        {
            ActiveChessmans.Remove(record.promotedPieceObject);
            Destroy(record.promotedPieceObject);

            record.originalPawnObject.SetActive(true);
            ActiveChessmans.Add(record.originalPawnObject);
            Chessman pawn = record.originalPawnObject.GetComponent<Chessman>();

            // Clear destination
            Chessmans[record.toX, record.toY] = null;
            // Restore pawn to original position
            Chessmans[record.fromX, record.fromY] = pawn;
            pawn.SetPosition(record.fromX, record.fromY);
            pawn.transform.position = new Vector3(record.fromX, 0, record.fromY);
            pawn.isMoved = record.wasMoved;
        }
        else
        {
            // Move piece back to original position
            Chessmans[record.toX, record.toY] = null;
            Chessmans[record.fromX, record.fromY] = record.movedPiece;
            record.movedPiece.SetPosition(record.fromX, record.fromY);
            record.movedPiece.transform.position = new Vector3(record.fromX, 0, record.fromY);
            record.movedPiece.isMoved = record.wasMoved;
        }

        // Undo castling: move rook back
        if(record.wasCastling)
        {
            Chessman rook = Chessmans[record.rookToX, record.rookY];
            Chessmans[record.rookToX, record.rookY] = null;
            Chessmans[record.rookFromX, record.rookY] = rook;
            rook.SetPosition(record.rookFromX, record.rookY);
            rook.transform.position = new Vector3(record.rookFromX, 0, record.rookY);
            rook.isMoved = record.rookWasMoved;
        }

        // Restore captured piece
        if(record.capturedPieceObject != null)
        {
            record.capturedPieceObject.SetActive(true);
            ActiveChessmans.Add(record.capturedPieceObject);
            Chessman captured = record.capturedPieceObject.GetComponent<Chessman>();
            Chessmans[record.capturedX, record.capturedY] = captured;
            captured.SetPosition(record.capturedX, record.capturedY);
            captured.transform.position = new Vector3(record.capturedX, 0, record.capturedY);

            // Restore rook references if needed
            if(captured.GetType() == typeof(Rook))
            {
                if(captured.isWhite)
                {
                    if(record.capturedX == 0) WhiteRook1 = captured;
                    else if(record.capturedX == 7) WhiteRook2 = captured;
                }
                else
                {
                    if(record.capturedX == 0) BlackRook1 = captured;
                    else if(record.capturedX == 7) BlackRook2 = captured;
                }
            }
        }

        // Restore EnPassant state
        EnPassant[0] = record.prevEnPassantX;
        EnPassant[1] = record.prevEnPassantY;

        // Switch turn back
        isWhiteTurn = !isWhiteTurn;
    }
}
