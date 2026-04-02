using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class PauseMenu : MonoBehaviour
{
    public static bool GameIsPaused = false;

    public GameObject pauseMenuUI;

    private bool optionsButtonCreated;

    /// <summary>
    /// Toggles pause state. Called from GameHUD pause button.
    /// </summary>
    public void TogglePause()
    {
        if(GameIsPaused)
            Resume();
        else
            Pause();
    }

    public void Resume()
    {
        pauseMenuUI.SetActive(false);
        Time.timeScale = 1f;
        GameIsPaused = false;
    }

    void Pause()
    {
        pauseMenuUI.SetActive(true);
        Time.timeScale = 0f;
        GameIsPaused = true;

        if (!optionsButtonCreated)
            CreateOptionsButton();
    }

    public void LoadOptions()
    {
        if(GameSettings.Instance != null)
            GameSettings.Instance.ShowSettings();
    }

    public void SaveAndQuit()
    {
        if(SaveSystem.Instance != null)
            SaveSystem.Instance.SaveGame();
        Resume();
        UnityEngine.SceneManagement.SceneManager.LoadScene(0);
    }

    public void Quit()
    {
        if(SaveSystem.Instance != null)
            SaveSystem.Instance.SaveGame();
        Application.Quit();
    }

    /// <summary>
    /// Finds existing buttons in the pause menu and clones one to create OPTIONS.
    /// </summary>
    private void CreateOptionsButton()
    {
        if (pauseMenuUI == null) return;

        // Find an existing button to clone style from (e.g. ResumeButton)
        Button[] buttons = pauseMenuUI.GetComponentsInChildren<Button>(true);
        if (buttons.Length == 0) return;

        // Pick the first button as template
        Button template = buttons[0];
        GameObject optionsGO = Instantiate(template.gameObject, template.transform.parent);
        optionsGO.name = "OptionsButton";

        // Position it after existing buttons
        RectTransform templateRT = template.GetComponent<RectTransform>();
        RectTransform optRT = optionsGO.GetComponent<RectTransform>();
        // Place below the last button
        Button lastBtn = buttons[buttons.Length - 1];
        RectTransform lastRT = lastBtn.GetComponent<RectTransform>();
        optRT.anchoredPosition = lastRT.anchoredPosition + new Vector2(0, -lastRT.sizeDelta.y - 15);

        // Update text - try TMP first, then legacy Text
        TextMeshProUGUI tmp = optionsGO.GetComponentInChildren<TextMeshProUGUI>();
        if (tmp != null)
        {
            tmp.text = "OPTIONS";
        }
        else
        {
            Text legacyText = optionsGO.GetComponentInChildren<Text>();
            if (legacyText != null)
                legacyText.text = "OPTIONS";
        }

        // Wire click
        Button btn = optionsGO.GetComponent<Button>();
        btn.onClick.RemoveAllListeners();
        btn.onClick.AddListener(() => LoadOptions());

        optionsGO.SetActive(true);
        optionsButtonCreated = true;
    }
}
