using UnityEngine;

namespace GYD.FishFlock
{
    /// <summary>
    /// Runtime fish unit. The manager computes boids velocity, this component only moves and rotates the fish.
    /// Fish model should face Unity +Z direction.
    /// </summary>
    public class FishFlockAgent : MonoBehaviour
    {
        [HideInInspector] public FishFlockManager manager;
        [HideInInspector] public Vector3 velocity;

        [Header("Optional Visual Animation")]
        public Transform visualRoot;
        public float rollAmount = 8f;
        public float rollSmooth = 6f;

        private float currentRoll;

        public void Initialize(FishFlockManager owner, Vector3 startVelocity)
        {
            manager = owner;
            velocity = startVelocity;
        }

        public void Move(Vector3 newVelocity)
        {
            velocity = newVelocity;
            transform.position += velocity * Time.deltaTime;

            if (velocity.sqrMagnitude > 0.0001f)
            {
                Quaternion targetRotation = Quaternion.LookRotation(velocity.normalized, Vector3.up);
                transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, manager.turnSpeed * Time.deltaTime);
            }

            ApplySimpleRoll();
        }

        private void ApplySimpleRoll()
        {
            if (visualRoot == null || manager == null)
            {
                return;
            }

            float turnHint = Vector3.Dot(transform.right, velocity.normalized);
            float targetRoll = -turnHint * rollAmount;
            currentRoll = Mathf.Lerp(currentRoll, targetRoll, Time.deltaTime * rollSmooth);
            visualRoot.localRotation = Quaternion.Euler(0f, 0f, currentRoll);
        }
    }
}
