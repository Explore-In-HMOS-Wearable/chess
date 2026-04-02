using UnityEngine;

/// <summary>
/// Centralized audio manager for chess game sound effects.
/// Attach to a GameObject with an AudioSource component.
/// Assign AudioClips in the Inspector.
/// </summary>
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    [Header("Audio Source")]
    [SerializeField] private AudioSource audioSource;

    [Header("Sound Effects")]
    [SerializeField] private AudioClip moveSound;
    [SerializeField] private AudioClip captureSound;
    [SerializeField] private AudioClip checkSound;
    [SerializeField] private AudioClip castleSound;
    [SerializeField] private AudioClip promoteSound;
    [SerializeField] private AudioClip winSound;
    [SerializeField] private AudioClip loseSound;
    [SerializeField] private AudioClip drawSound;
    [SerializeField] private AudioClip selectSound;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
            return;
        }

        if (audioSource == null)
            audioSource = GetComponent<AudioSource>();
    }

    private void PlayClip(AudioClip clip)
    {
        if (clip != null && audioSource != null)
            audioSource.PlayOneShot(clip);
    }

    public void PlayMove()
    {
        PlayClip(moveSound);
    }

    public void PlayCapture()
    {
        PlayClip(captureSound);
    }

    public void PlayCheck()
    {
        PlayClip(checkSound);
    }

    public void PlayCastle()
    {
        PlayClip(castleSound);
    }

    public void PlayPromote()
    {
        PlayClip(promoteSound);
    }

    public void PlayWin()
    {
        PlayClip(winSound);
    }

    public void PlayLose()
    {
        PlayClip(loseSound);
    }

    public void PlayDraw()
    {
        PlayClip(drawSound);
    }

    public void PlaySelect()
    {
        PlayClip(selectSound);
    }
}
