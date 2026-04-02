using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// Creates in-game HUD buttons (Undo, Pause) at runtime.
/// Designed for touch devices (HarmonyNext smartwatch) - no keyboard dependency.
/// Uses TextMeshPro for reliable text rendering.
/// </summary>
public class GameHUD : MonoBehaviour
{
    public static GameHUD Instance { get; private set; }

    private Canvas hudCanvas;
    private Button undoButton;
    private Button pauseButton;
    private TMP_FontAsset tmpFont;

    private void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
    }

    private void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    private void Start()
    {
        // Load TMP font from Resources (same font the project already uses)
        tmpFont = Resources.Load<TMP_FontAsset>("Fonts & Materials/LiberationSans SDF");

        CreateHUDCanvas();
        CreatePauseButton();
        CreateUndoButton();
    }

    private void CreateHUDCanvas()
    {
        GameObject canvasGO = new GameObject("HUDCanvas");
        canvasGO.transform.SetParent(transform);
        hudCanvas = canvasGO.AddComponent<Canvas>();
        hudCanvas.renderMode = RenderMode.ScreenSpaceOverlay;
        hudCanvas.sortingOrder = 90;

        CanvasScaler scaler = canvasGO.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(466, 466);
        scaler.matchWidthOrHeight = 0.5f;

        canvasGO.AddComponent<GraphicRaycaster>();
    }

    private Button CreateButton(string name, string label, Vector2 anchoredPos, Vector2 size, Color bgColor, float fontSize = 18f)
    {
        // Button container
        GameObject btnGO = new GameObject(name);
        btnGO.transform.SetParent(hudCanvas.transform, false);

        RectTransform rt = btnGO.AddComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 1);
        rt.anchorMax = new Vector2(0.5f, 1);
        rt.pivot = new Vector2(0.5f, 1);
        rt.anchoredPosition = anchoredPos;
        rt.sizeDelta = size;

        // Background image
        Image img = btnGO.AddComponent<Image>();
        img.color = bgColor;

        // Button component
        Button btn = btnGO.AddComponent<Button>();
        ColorBlock colors = btn.colors;
        colors.normalColor = Color.white;
        colors.highlightedColor = Color.white;
        colors.pressedColor = new Color(0.7f, 0.7f, 0.7f, 1f);
        btn.colors = colors;
        btn.targetGraphic = img;

        // Label text using TextMeshPro
        GameObject textGO = new GameObject("Label");
        textGO.transform.SetParent(btnGO.transform, false);

        RectTransform textRT = textGO.AddComponent<RectTransform>();
        textRT.anchorMin = Vector2.zero;
        textRT.anchorMax = Vector2.one;
        textRT.offsetMin = Vector2.zero;
        textRT.offsetMax = Vector2.zero;

        TextMeshProUGUI tmp = textGO.AddComponent<TextMeshProUGUI>();
        tmp.text = label;
        tmp.fontSize = fontSize;
        tmp.color = Color.white;
        tmp.alignment = TextAlignmentOptions.Center;
        tmp.fontStyle = FontStyles.Bold;
        if (tmpFont != null) tmp.font = tmpFont;

        return btn;
    }

    private void CreatePauseButton()
    {
        pauseButton = CreateButton(
            "PauseBtn", "II",
            new Vector2(35, -10),
            new Vector2(60, 60),
            new Color(0.2f, 0.2f, 0.35f, 0.9f),
            fontSize: 22f
        );

        pauseButton.onClick.AddListener(() =>
        {
            PauseMenu pm = FindObjectOfType<PauseMenu>();
            if (pm != null) pm.TogglePause();
        });
    }

    private void CreateUndoButton()
    {
        undoButton = CreateButton(
            "UndoBtn", "UNDO",
            new Vector2(-35, -10),
            new Vector2(70, 60),
            new Color(0.15f, 0.3f, 0.15f, 0.9f),
            fontSize: 16f
        );

        undoButton.onClick.AddListener(() =>
        {
            if (BoardManager.Instance != null)
                BoardManager.Instance.UndoMove();
        });
    }

    /// <summary>
    /// Hides HUD buttons (e.g., during game over).
    /// </summary>
    public void Hide()
    {
        if (hudCanvas != null) hudCanvas.gameObject.SetActive(false);
    }

    /// <summary>
    /// Shows HUD buttons.
    /// </summary>
    public void Show()
    {
        if (hudCanvas != null) hudCanvas.gameObject.SetActive(true);
    }
}
