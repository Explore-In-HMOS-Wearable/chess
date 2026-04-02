using UnityEngine;
using UnityEngine.EventSystems;

/// <summary>
/// Adds press/hover scale animation feedback to UI buttons.
/// Attach this component to any Button GameObject.
/// </summary>
public class ButtonAnimator : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler, IPointerDownHandler, IPointerUpHandler
{
    [SerializeField] private float hoverScale = 1.1f;
    [SerializeField] private float pressScale = 0.95f;
    [SerializeField] private float animSpeed = 10f;

    private Vector3 originalScale;
    private Vector3 targetScale;
    private bool isHovering;

    private void Awake()
    {
        originalScale = transform.localScale;
        targetScale = originalScale;
    }

    private void Update()
    {
        transform.localScale = Vector3.Lerp(transform.localScale, targetScale, Time.unscaledDeltaTime * animSpeed);
    }

    public void OnPointerEnter(PointerEventData eventData)
    {
        isHovering = true;
        targetScale = originalScale * hoverScale;
    }

    public void OnPointerExit(PointerEventData eventData)
    {
        isHovering = false;
        targetScale = originalScale;
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        targetScale = originalScale * pressScale;
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        targetScale = isHovering ? originalScale * hoverScale : originalScale;
    }

    private void OnDisable()
    {
        transform.localScale = originalScale;
        targetScale = originalScale;
    }
}
