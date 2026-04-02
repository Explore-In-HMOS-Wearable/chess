using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using UnityEngine.SceneManagement;

public class SplashManager : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(ChangeSceneAfterDelay(3f));

    }

    // Update is called once per frame
    void Update()
    {

    }


    IEnumerator ChangeSceneAfterDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        SceneManager.LoadScene("Init");
    }
}
