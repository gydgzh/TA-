using UnityEngine;

namespace GYD.FishFlock
{
    /// <summary>
    /// Creates a small low-poly placeholder fish mesh facing +Z.
    /// You can replace this prefab with a real fish model later.
    /// </summary>
    [ExecuteAlways]
    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    public class ProceduralSimpleFishMesh : MonoBehaviour
    {
        public float length = 0.45f;
        public float width = 0.12f;
        public float height = 0.16f;
        public float tailSize = 0.18f;

        private void OnEnable()
        {
            BuildMesh();
        }

        private void OnValidate()
        {
            BuildMesh();
        }

        public void BuildMesh()
        {
            MeshFilter mf = GetComponent<MeshFilter>();
            if (mf == null) return;

            float front = length * 0.55f;
            float back = -length * 0.45f;
            float tailBack = back - tailSize;

            Vector3[] v =
            {
                new Vector3(0f, 0f, front),                 // 0 nose
                new Vector3(0f, height, 0f),                // 1 top
                new Vector3(width, 0f, 0f),                 // 2 right
                new Vector3(0f, -height * 0.75f, 0f),       // 3 bottom
                new Vector3(-width, 0f, 0f),                // 4 left
                new Vector3(0f, 0f, back),                  // 5 tail root
                new Vector3(0f, height * 0.75f, tailBack),  // 6 tail top
                new Vector3(0f, -height * 0.75f, tailBack), // 7 tail bottom
                new Vector3(width * 1.1f, 0f, tailBack),    // 8 tail right
                new Vector3(-width * 1.1f, 0f, tailBack)    // 9 tail left
            };

            int[] t =
            {
                // body front pyramid
                0, 1, 2,
                0, 2, 3,
                0, 3, 4,
                0, 4, 1,

                // body back pyramid
                5, 2, 1,
                5, 3, 2,
                5, 4, 3,
                5, 1, 4,

                // vertical tail fin
                5, 6, 7,
                5, 7, 6,

                // horizontal tail fin
                5, 8, 9,
                5, 9, 8
            };

            Mesh mesh = mf.sharedMesh;
            if (mesh == null || mesh.name != "ProceduralSimpleFish")
            {
                mesh = new Mesh { name = "ProceduralSimpleFish" };
                mf.sharedMesh = mesh;
            }

            mesh.Clear();
            mesh.vertices = v;
            mesh.triangles = t;
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
        }
    }
}
