/// <summary>
/// Records a single move for the player undo system.
/// Stores all data needed to fully restore the board to its previous state.
/// </summary>
public class MoveRecord
{
    // The piece that moved
    public Chessman movedPiece;
    public int fromX, fromY;
    public int toX, toY;
    public bool wasMoved; // isMoved state before this move

    // Captured piece (if any)
    public UnityEngine.GameObject capturedPieceObject;
    public int capturedX, capturedY;

    // EnPassant state before this move
    public int prevEnPassantX, prevEnPassantY;

    // Special move flags
    public bool wasCastling;
    public bool castleKingSide;
    public int rookFromX, rookToX, rookY;
    public bool rookWasMoved;

    public bool wasPromotion;
    public UnityEngine.GameObject promotedPieceObject; // the new queen object
    public UnityEngine.GameObject originalPawnObject;   // the destroyed pawn (null after destroy)
    public int promotionPrefabIndex;                    // prefab index used to spawn
}
