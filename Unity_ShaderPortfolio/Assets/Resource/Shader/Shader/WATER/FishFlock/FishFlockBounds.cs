using UnityEngine;

namespace GYD.FishFlock
{
    /// <summary>
    /// Box volume that keeps fish inside the water area.
    /// Place it slightly below the water surface.
    /// </summary>
    public class FishFlockBounds : MonoBehaviour
    {
        public Vector3 size = new Vector3(20f, 3f, 30f);

        public Vector3 Center => transform.position;
        public Vector3 Extents => size * 0.5f;

        public bool Contains(Vector3 worldPosition)
        {
            Vector3 local = worldPosition - Center;
            return Mathf.Abs(local.x) <= Extents.x &&
                   Mathf.Abs(local.y) <= Extents.y &&
                   Mathf.Abs(local.z) <= Extents.z;
        }

        public Vector3 GetSteerBackVector(Vector3 worldPosition)
        {
            Vector3 local = worldPosition - Center;
            Vector3 steer = Vector3.zero;

            if (Mathf.Abs(local.x) > Extents.x) steer.x = -Mathf.Sign(local.x);
            if (Mathf.Abs(local.y) > Extents.y) steer.y = -Mathf.Sign(local.y);
            if (Mathf.Abs(local.z) > Extents.z) steer.z = -Mathf.Sign(local.z);

            if (steer.sqrMagnitude < 0.0001f)
            {
                return (Center - worldPosition).normalized;
            }

            return steer.normalized;
        }

        public Vector3 GetRandomPoint()
        {
            Vector3 e = Extents;
            return Center + new Vector3(
                Random.Range(-e.x, e.x),
                Random.Range(-e.y, e.y),
                Random.Range(-e.z, e.z)
            );
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(0f, 0.8f, 1f, 0.8f);
            Gizmos.DrawWireCube(transform.position, size);
        }
    }
}
