using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

/// <summary>
/// Auto-initializes all game managers and UI at runtime.
/// Attach to any GameObject in the FIRST scene (Menu), or use [RuntimeInitializeOnLoadMethod].
/// This script ensures AudioManager, GameSettings, SaveSystem exist without manual scene wiring.
/// </summary>
public class GameBootstrap
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Init()
    {
        // Create persistent managers (survive scene loads)
        CreateAudioManager();
        CreateGameSettings();

        // Listen for scene loads to set up per-scene objects
        SceneManager.sceneLoaded += OnSceneLoaded;
    }

    private static void CreateAudioManager()
    {
        if (AudioManager.Instance != null) return;

        GameObject go = new GameObject("AudioManager");
        go.AddComponent<AudioSource>();
        go.AddComponent<AudioManager>();
        Object.DontDestroyOnLoad(go);
    }

    private static void CreateGameSettings()
    {
        if (GameSettings.Instance != null) return;

        GameObject go = new GameObject("GameSettings");
        go.AddComponent<GameSettings>();
        // DontDestroyOnLoad is handled inside GameSettings.Awake()
    }

    private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        // Only run setup on actual game scenes, skip Init/Splash
        string sceneName = scene.name.ToLower();
        if (sceneName == "init" || sceneName == "splash")
            return;

        var helper = new GameObject("BootstrapHelper").AddComponent<BootstrapSceneHelper>();
        helper.sceneName = sceneName;
        helper.StartCoroutine(helper.DelayedSetup());
    }

    public static void RunGameSceneSetup() { SetupGameScene(); }
    public static void RunMenuSceneSetup() { SetupMenuScene(); }

    private static void SetupGameScene()
    {
        // Add SaveSystem if not present
        if (SaveSystem.Instance == null)
        {
            GameObject go = new GameObject("SaveSystem");
            go.AddComponent<SaveSystem>();
        }

        // Add GameHUD for touch buttons (Undo, Pause)
        if (GameHUD.Instance == null)
        {
            GameObject hud = new GameObject("GameHUD");
            hud.AddComponent<GameHUD>();
        }

        // Apply loaded game if pending
        if (SaveSystem.PendingLoad != null && SaveSystem.Instance != null)
        {
            // Delay one frame to let BoardManager.Start() finish
            var helper = new GameObject("LoadHelper").AddComponent<DelayedLoadHelper>();
            helper.data = SaveSystem.PendingLoad;
            SaveSystem.PendingLoad = null;
        }

        // Add ButtonAnimator to all existing buttons in the scene
        AddButtonAnimators();
    }

    private static void SetupMenuScene()
    {
        // Find MainMenu to set up continue button
        MainMenu mainMenu = Object.FindObjectOfType<MainMenu>();
        if (mainMenu != null && mainMenu.continueButton == null)
        {
            // Try to find a button named "ContinueButton"
            // If not found, create one if save exists
            if (PlayerPrefs.HasKey("ChessSaveData"))
            {
                CreateContinueButton(mainMenu);
            }
        }

        AddButtonAnimators();
    }

    private static void CreateContinueButton(MainMenu mainMenu)
    {
        // Find existing canvas
        Canvas canvas = Object.FindObjectOfType<Canvas>();
        if (canvas == null) return;

        // Find play button to copy style from
        Button[] buttons = canvas.GetComponentsInChildren<Button>(true);
        if (buttons.Length == 0) return;

        Button playButton = null;
        foreach (var btn in buttons)
        {
            if (btn.gameObject.name.Contains("Play") || btn.gameObject.name.Contains("play"))
            {
                playButton = btn;
                break;
            }
        }
        if (playButton == null) playButton = buttons[0];

        // Clone the play button for continue
        GameObject continueGO = Object.Instantiate(playButton.gameObject, playButton.transform.parent);
        continueGO.name = "ContinueButton";

        // Position it (move it above play button)
        RectTransform rt = continueGO.GetComponent<RectTransform>();
        RectTransform playRT = playButton.GetComponent<RectTransform>();
        rt.anchoredPosition = playRT.anchoredPosition + new Vector2(0, 50);

        // Update text
        Text btnText = continueGO.GetComponentInChildren<Text>();
        if (btnText != null)
            btnText.text = "Continue";

        // Wire up click event
        Button btn2 = continueGO.GetComponent<Button>();
        btn2.onClick.RemoveAllListeners();
        btn2.onClick.AddListener(() => mainMenu.ContinueGame());

        mainMenu.continueButton = continueGO;
        continueGO.SetActive(true);
    }

    private static void AddButtonAnimators()
    {
        Button[] allButtons = Object.FindObjectsOfType<Button>(true);
        foreach (var btn in allButtons)
        {
            if (btn.GetComponent<ButtonAnimator>() == null)
                btn.gameObject.AddComponent<ButtonAnimator>();
        }
    }
}

/// <summary>
/// Delays scene setup by one frame so all MonoBehaviour.Start() calls complete first.
/// </summary>
public class BootstrapSceneHelper : MonoBehaviour
{
    public string sceneName;

    public System.Collections.IEnumerator DelayedSetup()
    {
        yield return null; // Wait one frame for Start() to finish

        if (sceneName == "game" && BoardManager.Instance != null)
        {
            // Game scene only: HUD buttons, SaveSystem, etc.
            GameBootstrap.RunGameSceneSetup();
        }
        else
        {
            // Menu scene: Continue button, etc.
            GameBootstrap.RunMenuSceneSetup();
        }

        Destroy(gameObject);
    }
}

/// <summary>
/// Helper to delay game load by one frame so BoardManager.Start() completes first.
/// </summary>
public class DelayedLoadHelper : MonoBehaviour
{
    public SaveData data;
    private int frameCount = 0;

    void Update()
    {
        frameCount++;
        if (frameCount >= 2)
        {
            if (SaveSystem.Instance != null && data != null)
                SaveSystem.Instance.ApplyLoadedGame(data);
            Destroy(gameObject);
        }
    }
}
