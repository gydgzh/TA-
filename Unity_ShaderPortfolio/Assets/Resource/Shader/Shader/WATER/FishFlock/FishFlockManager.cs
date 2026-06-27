using System.Collections.Generic;
using UnityEngine;

namespace GYD.FishFlock
{
    /// <summary>
    /// Simple 3D boids fish school adapted for water scenes.
    /// Based on classic cohesion / alignment / separation rules.
    /// </summary>
    public class FishFlockManager : MonoBehaviour
    {
        [Header("References")]
        public FishFlockAgent fishPrefab;
        public FishFlockBounds swimBounds;

        [Header("Spawn")]
        [Range(1, 300)] public int fishCount = 40;
        public float spawnRadius = 8f;

        [Header("Movement")]
        public float minSpeed = 0.8f;
        public float maxSpeed = 2.4f;
        public float turnSpeed = 4f;
        public float neighborRadius = 2.5f;
        public float avoidanceRadius = 0.75f;

        [Header("Boids Weights")]
        public float cohesionWeight = 1.15f;
        public float alignmentWeight = 1.0f;
        public float avoidanceWeight = 2.4f;
        public float boundsWeight = 5.0f;
        public float noiseWeight = 0.2f;

        [Header("Obstacle Avoidance")]
        public LayerMask obstacleMask;
        public float obstacleCheckDistance = 1.2f;
        public float obstacleAvoidanceWeight = 3.0f;

        [Header("Debug")]
        public bool respawnOnStart = true;
        public bool drawDebug = true;

        private readonly List<FishFlockAgent> agents = new List<FishFlockAgent>();

        private void Start()
        {
            if (respawnOnStart)
            {
                ClearExistingFish();
                SpawnFish();
            }
        }

        private void Update()
        {
            UpdateFish();
        }

        [ContextMenu("Respawn Fish")]
        public void RespawnFish()
        {
            ClearExistingFish();
            SpawnFish();
        }

        private void ClearExistingFish()
        {
            agents.Clear();

            for (int i = transform.childCount - 1; i >= 0; i--)
            {
                Transform child = transform.GetChild(i);
                if (Application.isPlaying)
                {
                    Destroy(child.gameObject);
                }
                else
                {
                    DestroyImmediate(child.gameObject);
                }
            }
        }

        private void SpawnFish()
        {
            if (fishPrefab == null)
            {
                Debug.LogError("FishFlockManager: fishPrefab is missing.", this);
                return;
            }

            Vector3 center = swimBounds != null ? swimBounds.Center : transform.position;

            for (int i = 0; i < fishCount; i++)
            {
                Vector3 spawnPos = swimBounds != null
                    ? swimBounds.GetRandomPoint()
                    : center + Random.insideUnitSphere * spawnRadius;

                Quaternion spawnRot = Quaternion.Euler(0f, Random.Range(0f, 360f), 0f);
                FishFlockAgent agent = Instantiate(fishPrefab, spawnPos, spawnRot, transform);
                agent.name = $"Fish_{i:000}";

                Vector3 dir = Random.onUnitSphere;
                dir.y *= 0.25f;
                if (dir.sqrMagnitude < 0.0001f) dir = Vector3.forward;
                dir.Normalize();

                Vector3 startVelocity = dir * Random.Range(minSpeed, maxSpeed);
                agent.Initialize(this, startVelocity);
                agents.Add(agent);
            }
        }

        private void UpdateFish()
        {
            if (agents.Count == 0) return;

            for (int i = 0; i < agents.Count; i++)
            {
                FishFlockAgent agent = agents[i];
                if (agent == null) continue;

                Vector3 cohesion = Vector3.zero;
                Vector3 alignment = Vector3.zero;
                Vector3 separation = Vector3.zero;

                int neighborCount = 0;
                int avoidCount = 0;

                Vector3 agentPos = agent.transform.position;

                for (int j = 0; j < agents.Count; j++)
                {
                    if (i == j) continue;

                    FishFlockAgent other = agents[j];
                    if (other == null) continue;

                    Vector3 toOther = other.transform.position - agentPos;
                    float sqrDist = toOther.sqrMagnitude;

                    if (sqrDist < neighborRadius * neighborRadius)
                    {
                        cohesion += other.transform.position;
                        alignment += other.velocity;
                        neighborCount++;

                        if (sqrDist < avoidanceRadius * avoidanceRadius)
                        {
                            float dist = Mathf.Sqrt(Mathf.Max(sqrDist, 0.0001f));
                            separation -= toOther / dist;
                            avoidCount++;
                        }
                    }
                }

                Vector3 acceleration = Vector3.zero;

                if (neighborCount > 0)
                {
                    cohesion = cohesion / neighborCount - agentPos;
                    alignment /= neighborCount;

                    acceleration += cohesion.normalized * cohesionWeight;
                    acceleration += alignment.normalized * alignmentWeight;
                }

                if (avoidCount > 0)
                {
                    separation /= avoidCount;
                    acceleration += separation.normalized * avoidanceWeight;
                }

                if (swimBounds != null && !swimBounds.Contains(agentPos))
                {
                    acceleration += swimBounds.GetSteerBackVector(agentPos) * boundsWeight;
                }

                acceleration += AvoidObstacles(agent) * obstacleAvoidanceWeight;
                acceleration += GetSoftNoise(agentPos) * noiseWeight;

                Vector3 newVelocity = agent.velocity + acceleration * Time.deltaTime;
                if (newVelocity.sqrMagnitude < 0.0001f)
                {
                    newVelocity = agent.transform.forward * minSpeed;
                }

                float speed = Mathf.Clamp(newVelocity.magnitude, minSpeed, maxSpeed);
                newVelocity = newVelocity.normalized * speed;

                agent.Move(newVelocity);
            }
        }

        private Vector3 GetSoftNoise(Vector3 position)
        {
            float t = Time.time * 0.35f;
            return new Vector3(
                Mathf.PerlinNoise(t, position.x * 0.1f) - 0.5f,
                (Mathf.PerlinNoise(t + 11.7f, position.y * 0.1f) - 0.5f) * 0.35f,
                Mathf.PerlinNoise(t + 23.4f, position.z * 0.1f) - 0.5f
            );
        }

        private Vector3 AvoidObstacles(FishFlockAgent agent)
        {
            if (obstacleMask.value == 0)
            {
                return Vector3.zero;
            }

            Ray ray = new Ray(agent.transform.position, agent.transform.forward);
            if (Physics.Raycast(ray, out RaycastHit hit, obstacleCheckDistance, obstacleMask, QueryTriggerInteraction.Ignore))
            {
                Vector3 reflected = Vector3.Reflect(agent.transform.forward, hit.normal);
                reflected.y *= 0.35f;
                return reflected.normalized;
            }

            return Vector3.zero;
        }

        private void OnDrawGizmosSelected()
        {
            if (!drawDebug) return;

            Gizmos.color = new Color(1f, 0.9f, 0.1f, 0.8f);
            Gizmos.DrawWireSphere(transform.position, spawnRadius);
        }
    }
}
