using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class MainMenu : MonoBehaviour
{
	public GameObject continueButton;

	private void Start()
	{
		// Show Continue button only if a saved game exists
		if(continueButton != null)
			continueButton.SetActive(PlayerPrefs.HasKey("ChessSaveData"));
	}

	public void PlayGame()
	{
		// Clear any pending load so we start fresh
		SaveSystem.PendingLoad = null;
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
	}

	public void ContinueGame()
	{
		string json = PlayerPrefs.GetString("ChessSaveData", "");
		if(!string.IsNullOrEmpty(json))
		{
			SaveSystem.PendingLoad = JsonUtility.FromJson<SaveData>(json);
			SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1);
		}
	}

	public void QuitGame()
	{
		Debug.Log("Quit Game!");
		Application.Quit();
	}
}
