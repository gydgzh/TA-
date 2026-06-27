#if UNITY_EDITOR
using System.IO;
using GYD.FishFlock;
using UnityEditor;
using UnityEngine;

public static class FishFlockSetupEditor
{
    private const string RootFolder = "Assets/FishFlock";
    private const string PrefabFolder = RootFolder + "/Prefabs";
    private const string MaterialFolder = RootFolder + "/Materials";
    private const string FishPrefabPath = PrefabFolder + "/PF_ProceduralFish.prefab";
    private const string FishMaterialPath = MaterialFolder + "/M_ProceduralFish.mat";

    [MenuItem("Tools/Fish Flock/Create Simple Fish Flock For Selected Water")]
    public static void CreateFishFlockForSelectedWater()
    {
        EnsureFolders();

        GameObject selected = Selection.activeGameObject;
        Renderer waterRenderer = selected != null ? selected.GetComponent<Renderer>() : null;

        Bounds waterBounds = new Bounds(Vector3.zero, new Vector3(20f, 1f, 30f));
        if (waterRenderer != null)
        {
            waterBounds = waterRenderer.bounds;
        }
        else
        {
            Debug.LogWarning("No water Renderer selected. Creating fish flock at world origin with default bounds.");
        }

        FishFlockAgent fishPrefab = CreateOrLoadFishPrefab();

        GameObject root = new GameObject("FishFlockSystem");
        Undo.RegisterCreatedObjectUndo(root, "Create Fish Flock System");

        GameObject boundsObj = new GameObject("FishSwimBounds");
        Undo.RegisterCreatedObjectUndo(boundsObj, "Create Fish Swim Bounds");
        boundsObj.transform.SetParent(root.transform);
        boundsObj.transform.position = waterBounds.center + Vector3.down * 0.8f;

        FishFlockBounds swimBounds = boundsObj.AddComponent<FishFlockBounds>();
        swimBounds.size = new Vector3(
            Mathf.Max(4f, waterBounds.size.x * 0.88f),
            2.4f,
            Mathf.Max(4f, waterBounds.size.z * 0.88f)
        );

        GameObject managerObj = new GameObject("FishFlockManager");
        Undo.RegisterCreatedObjectUndo(managerObj, "Create Fish Flock Manager");
        managerObj.transform.SetParent(root.transform);
        managerObj.transform.position = swimBounds.Center;

        FishFlockManager manager = managerObj.AddComponent<FishFlockManager>();
        manager.fishPrefab = fishPrefab;
        manager.swimBounds = swimBounds;
        manager.fishCount = 40;
        manager.spawnRadius = Mathf.Min(swimBounds.size.x, swimBounds.size.z) * 0.35f;
        manager.minSpeed = 0.8f;
        manager.maxSpeed = 2.4f;
        manager.turnSpeed = 4f;
        manager.neighborRadius = 2.5f;
        manager.avoidanceRadius = 0.75f;
        manager.cohesionWeight = 1.15f;
        manager.alignmentWeight = 1.0f;
        manager.avoidanceWeight = 2.4f;
        manager.boundsWeight = 5.0f;
        manager.noiseWeight = 0.2f;

        Selection.activeGameObject = managerObj;
        EditorGUIUtility.PingObject(managerObj);

        Debug.Log("Created FishFlockSystem. Press Play to see the fish school. Replace PF_ProceduralFish with your own fish model later if needed.");
    }

    [MenuItem("Tools/Fish Flock/Create Only Procedural Fish Prefab")]
    public static void CreateOnlyProceduralFishPrefab()
    {
        EnsureFolders();
        FishFlockAgent prefab = CreateOrLoadFishPrefab();
        Selection.activeObject = prefab.gameObject;
        EditorGUIUtility.PingObject(prefab.gameObject);
        Debug.Log("Created/loaded procedural fish prefab: " + FishPrefabPath);
    }

    private static void EnsureFolders()
    {
        CreateFolderIfMissing("Assets", "FishFlock");
        CreateFolderIfMissing(RootFolder, "Prefabs");
        CreateFolderIfMissing(RootFolder, "Materials");
    }

    private static void CreateFolderIfMissing(string parent, string folder)
    {
        string path = parent + "/" + folder;
        if (!AssetDatabase.IsValidFolder(path))
        {
            AssetDatabase.CreateFolder(parent, folder);
        }
    }

    private static FishFlockAgent CreateOrLoadFishPrefab()
    {
        FishFlockAgent existing = AssetDatabase.LoadAssetAtPath<FishFlockAgent>(FishPrefabPath);
        if (existing != null)
        {
            return existing;
        }

        Material mat = CreateOrLoadFishMaterial();

        GameObject temp = new GameObject("PF_ProceduralFish");
        temp.transform.position = Vector3.zero;

        ProceduralSimpleFishMesh fishMesh = temp.AddComponent<ProceduralSimpleFishMesh>();
        fishMesh.length = 0.45f;
        fishMesh.width = 0.12f;
        fishMesh.height = 0.16f;
        fishMesh.tailSize = 0.18f;
        fishMesh.BuildMesh();

        MeshRenderer renderer = temp.GetComponent<MeshRenderer>();
        renderer.sharedMaterial = mat;

        BoxCollider collider = temp.AddComponent<BoxCollider>();
        collider.size = new Vector3(0.28f, 0.22f, 0.65f);
        collider.center = new Vector3(0f, 0f, 0.02f);

        FishFlockAgent agent = temp.AddComponent<FishFlockAgent>();
        agent.visualRoot = temp.transform;

        GameObject prefab = PrefabUtility.SaveAsPrefabAsset(temp, FishPrefabPath);
        Object.DestroyImmediate(temp);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        return prefab.GetComponent<FishFlockAgent>();
    }

    private static Material CreateOrLoadFishMaterial()
    {
        Material existing = AssetDatabase.LoadAssetAtPath<Material>(FishMaterialPath);
        if (existing != null)
        {
            return existing;
        }

        Shader shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null)
        {
            shader = Shader.Find("Standard");
        }

        Material mat = new Material(shader);
        mat.name = "M_ProceduralFish";
        mat.color = new Color(0.08f, 0.55f, 0.75f, 1f);

        AssetDatabase.CreateAsset(mat, FishMaterialPath);
        AssetDatabase.SaveAssets();
        return mat;
    }
}
#endif
