using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// Game settings manager. Creates its own UI panel at runtime.
/// Persists difficulty preferences via PlayerPrefs.
/// </summary>
public class GameSettings : MonoBehaviour
{
    public static GameSettings Instance { get; private set; }

    // Difficulty levels mapped to AI search depth
    private static readonly string[] DifficultyNames = { "Easy", "Medium", "Hard" };
    private static readonly int[] DifficultyDepths = { 3, 5, 7 };

    private int difficultyIndex;

    public int AIDifficulty => DifficultyDepths[difficultyIndex];

    // Runtime UI references
    private GameObject settingsPanel;
    private TextMeshProUGUI difficultyLabel;
    private TMP_FontAsset tmpFont;
    private bool uiCreated;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
            LoadSettings();
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public void ShowSettings()
    {
        if (!uiCreated) CreateSettingsUI();

        if (settingsPanel != null)
        {
            settingsPanel.SetActive(true);
            Time.timeScale = 0f;
            UpdateLabel();
        }
    }

    public void HideSettings()
    {
        if (settingsPanel != null)
        {
            settingsPanel.SetActive(false);
            Time.timeScale = 1f;
            SaveSettings();
        }
    }

    public void NextDifficulty()
    {
        difficultyIndex = (difficultyIndex + 1) % DifficultyNames.Length;
        UpdateLabel();
    }

    public void PrevDifficulty()
    {
        difficultyIndex = (difficultyIndex - 1 + DifficultyNames.Length) % DifficultyNames.Length;
        UpdateLabel();
    }

    private void UpdateLabel()
    {
        if (difficultyLabel != null)
            difficultyLabel.text = DifficultyNames[difficultyIndex];
    }

    private void SaveSettings()
    {
        PlayerPrefs.SetInt("Difficulty", difficultyIndex);
        PlayerPrefs.Save();
    }

    private void LoadSettings()
    {
        difficultyIndex = PlayerPrefs.GetInt("Difficulty", 1); // Default: Medium
    }

    // =========================================================
    // Runtime UI Creation
    // =========================================================
    private void CreateSettingsUI()
    {
        tmpFont = Resources.Load<TMP_FontAsset>("Fonts & Materials/LiberationSans SDF");

        // Canvas
        GameObject canvasGO = new GameObject("SettingsCanvas");
        canvasGO.transform.SetParent(transform);
        Canvas canvas = canvasGO.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 100;

        CanvasScaler scaler = canvasGO.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(466, 466);
        scaler.matchWidthOrHeight = 0.5f;
        canvasGO.AddComponent<GraphicRaycaster>();

        // Dark overlay background
        settingsPanel = new GameObject("SettingsPanel");
        settingsPanel.transform.SetParent(canvasGO.transform, false);
        RectTransform panelRT = settingsPanel.AddComponent<RectTransform>();
        panelRT.anchorMin = Vector2.zero;
        panelRT.anchorMax = Vector2.one;
        panelRT.offsetMin = Vector2.zero;
        panelRT.offsetMax = Vector2.zero;

        Image overlay = settingsPanel.AddComponent<Image>();
        overlay.color = new Color(0, 0, 0, 0.85f);

        // Center card
        GameObject card = CreateChild(settingsPanel, "Card", Vector2.zero, new Vector2(350, 280));
        Image cardImg = card.AddComponent<Image>();
        cardImg.color = new Color(0.13f, 0.13f, 0.23f, 1f);

        // Title: "SETTINGS"
        CreateTMPText(card, "Title", new Vector2(0, 105), new Vector2(300, 40),
            "SETTINGS", 26f, Color.white, TextAlignmentOptions.Center);

        // Divider line
        GameObject divider = CreateChild(card, "Divider", new Vector2(0, 82), new Vector2(280, 2));
        Image divImg = divider.AddComponent<Image>();
        divImg.color = new Color(0.94f, 0.75f, 0.25f, 1f); // Gold

        // "AI Difficulty" label
        CreateTMPText(card, "DiffLabel", new Vector2(0, 45), new Vector2(300, 30),
            "AI Difficulty", 20f, new Color(0.8f, 0.8f, 0.8f), TextAlignmentOptions.Center);

        // Difficulty row: [<]  Easy/Medium/Hard  [>]
        // Left arrow
        GameObject leftBtn = CreateChild(card, "LeftBtn", new Vector2(-100, 0), new Vector2(50, 50));
        Image leftImg = leftBtn.AddComponent<Image>();
        leftImg.color = new Color(0.3f, 0.3f, 0.5f, 1f);
        Button leftButton = leftBtn.AddComponent<Button>();
        leftButton.targetGraphic = leftImg;
        CreateTMPText(leftBtn, "Txt", Vector2.zero, new Vector2(50, 50),
            "<", 28f, Color.white, TextAlignmentOptions.Center);
        leftButton.onClick.AddListener(() => { PrevDifficulty(); });

        // Difficulty display
        GameObject diffDisplay = CreateChild(card, "DiffDisplay", new Vector2(0, 0), new Vector2(120, 50));
        Image diffBg = diffDisplay.AddComponent<Image>();
        diffBg.color = new Color(0.2f, 0.2f, 0.35f, 1f);
        difficultyLabel = CreateTMPText(diffDisplay, "Val", Vector2.zero, new Vector2(120, 50),
            DifficultyNames[difficultyIndex], 22f, new Color(0.94f, 0.75f, 0.25f), TextAlignmentOptions.Center);

        // Right arrow
        GameObject rightBtn = CreateChild(card, "RightBtn", new Vector2(100, 0), new Vector2(50, 50));
        Image rightImg = rightBtn.AddComponent<Image>();
        rightImg.color = new Color(0.3f, 0.3f, 0.5f, 1f);
        Button rightButton = rightBtn.AddComponent<Button>();
        rightButton.targetGraphic = rightImg;
        CreateTMPText(rightBtn, "Txt", Vector2.zero, new Vector2(50, 50),
            ">", 28f, Color.white, TextAlignmentOptions.Center);
        rightButton.onClick.AddListener(() => { NextDifficulty(); });

        // Depth info text
        CreateTMPText(card, "DepthInfo", new Vector2(0, -45), new Vector2(300, 25),
            "Easy=3 | Medium=5 | Hard=7 moves ahead", 13f, new Color(0.6f, 0.6f, 0.6f), TextAlignmentOptions.Center);

        // Close button
        GameObject closeBtn = CreateChild(card, "CloseBtn", new Vector2(0, -95), new Vector2(160, 45));
        Image closeImg = closeBtn.AddComponent<Image>();
        closeImg.color = new Color(0.15f, 0.5f, 0.15f, 1f);
        Button closeButton = closeBtn.AddComponent<Button>();
        closeButton.targetGraphic = closeImg;
        CreateTMPText(closeBtn, "Txt", Vector2.zero, new Vector2(160, 45),
            "CLOSE", 20f, Color.white, TextAlignmentOptions.Center);
        closeButton.onClick.AddListener(() => { HideSettings(); });

        settingsPanel.SetActive(false);
        uiCreated = true;
    }

    private GameObject CreateChild(GameObject parent, string name, Vector2 pos, Vector2 size)
    {
        GameObject go = new GameObject(name);
        go.transform.SetParent(parent.transform, false);
        RectTransform rt = go.AddComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 0.5f);
        rt.anchorMax = new Vector2(0.5f, 0.5f);
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = pos;
        rt.sizeDelta = size;
        return go;
    }

    private TextMeshProUGUI CreateTMPText(GameObject parent, string name, Vector2 pos, Vector2 size,
        string text, float fontSize, Color color, TextAlignmentOptions align)
    {
        GameObject go = CreateChild(parent, name, pos, size);
        TextMeshProUGUI tmp = go.AddComponent<TextMeshProUGUI>();
        tmp.text = text;
        tmp.fontSize = fontSize;
        tmp.color = color;
        tmp.alignment = align;
        tmp.fontStyle = FontStyles.Bold;
        if (tmpFont != null) tmp.font = tmpFont;
        return tmp;
    }
}
