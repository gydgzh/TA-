using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
    using UnityEditor;
#endif


public enum ModuleQuality : int { VeryLow, Low, Normal, High }

[System.Serializable]
public class FurPhysicsModule : MonoBehaviour
{
    public ModuleQuality quality = ModuleQuality.Normal;

    //public bool disabledOnLOD = false;

    public float gravityStrength = 0.5f;

    public float physicsSensitivity = 0.35f;

    private GameObject Owner;

    private int toPass = 0;

    //[SerializeField] protected bool[] perMatPhysics;

    private int internalRes;

    private struct PhysicsSimulationData
    {
        public RenderTexture internalPass0, internalPass1, physicsPass;
    }

    private PhysicsSimulationData perProfilePhysicsData;

    protected Shader physicsShader;
    protected Shader physicsShader2;
    protected Shader physicsShader3;

    private Material physicsMat;
    private Material physicsMat2;
    private Material physicsMat3;

    private Vector3 prevPos;

    public static Material FillerMaterial, PainterMaterial, UnwrapMaterial;

    private void Awake()
    {

        physicsShader =  Shader.Find("URP/PhysicsPass0");
        physicsShader2 = Shader.Find("URP/PhysicsPass1");
        physicsShader3 = Shader.Find("URP/PhysicsPass2");
    }
    private void Start()
    {
        Setup();
    }

    public void SetQuality(ModuleQuality targetQuality)
    {
        quality = targetQuality;

        switch (quality)
        {
            case ModuleQuality.VeryLow:
                internalRes = 16;
                break;
            case ModuleQuality.Low:
                internalRes = 32;
                break;
            case ModuleQuality.Normal:
                internalRes = 64;
                break;
            case ModuleQuality.High:
                internalRes = 128;
                break;
        }
    }

    void GenCamera()
    {

        GameObject cam = new GameObject("cam");
        var camera = cam.AddComponent<Camera>();
        cam.transform.position = new Vector3(0, 1, -10);
        cam.transform.rotation = Quaternion.identity;

    }


    public void FillTexture(Mesh targetMesh, Matrix4x4 targetMatrix, Color color, RenderTexture sourceTex, Color backgroundColor, int matIndex = 0)
    {

        var rd = new RenderTextureDescriptor(sourceTex.width, sourceTex.height, sourceTex.format, sourceTex.depth);

        var temp0 = RenderTexture.GetTemporary(rd);

        var currentActive = RenderTexture.active;
        RenderTexture.active = temp0;
        GL.Clear(true, true, backgroundColor);
        UnwrapMaterial.SetVector("_FillColor", color);
        UnwrapMaterial.SetPass(0);
        Graphics.DrawMeshNow(targetMesh, targetMatrix, matIndex);
        RenderTexture.active = currentActive;

        Graphics.Blit(temp0, (RenderTexture)sourceTex);
        RenderTexture.ReleaseTemporary(temp0);

    }

    void Setup()
    {

        Owner = this.gameObject;

        Shader.SetGlobalTexture("_XFurPhysics", Texture2D.blackTexture);

        SetQuality(quality);

        if (!UnwrapMaterial)
        {
            UnwrapMaterial = new Material(("Hidden/XFur Studio 2/Designer/Auto Unwrap"));
        }

        //GenCamera();
        perProfilePhysicsData = new PhysicsSimulationData();

        var rd = new RenderTextureDescriptor(internalRes, internalRes, RenderTextureFormat.ARGBHalf, 0, 0);

        perProfilePhysicsData.internalPass0 = new RenderTexture(rd);
        perProfilePhysicsData.internalPass1 = new RenderTexture(rd);
        perProfilePhysicsData.physicsPass = new RenderTexture(rd);

        Mesh targetMesh;
        Matrix4x4 targetMatrix;

        if (Owner.GetComponent<MeshFilter>())
        {
            targetMesh = Owner.GetComponent<MeshFilter>().sharedMesh;
            //targetMatrix = Owner.GetComponent<MeshFilter>().transform.localToWorldMatrix;

            targetMatrix = Owner.transform.localToWorldMatrix;

        }
        else
        {
            targetMesh = Owner.GetComponent<SkinnedMeshRenderer>().sharedMesh;
            //targetMatrix = Owner.GetComponent<SkinnedMeshRenderer>().transform.localToWorldMatrix;
            targetMatrix = Owner.transform.localToWorldMatrix;

        }

        FillTexture(targetMesh, targetMatrix, new Color(0, 0, 0), perProfilePhysicsData.internalPass0, new Color(0, 0, 0));
        FillTexture(targetMesh, targetMatrix, new Color(0, 0, 0), perProfilePhysicsData.internalPass1, new Color(0, 0, 0));
        FillTexture(targetMesh, targetMatrix, new Color(1, 1, 1), perProfilePhysicsData.physicsPass, new Color(1, 1, 1));

        perProfilePhysicsData.internalPass0.name = "PHYSPASS_A";
        perProfilePhysicsData.internalPass1.name = "PHYSPASS_B";
        perProfilePhysicsData.physicsPass.name = "PHYSPASS_C";

        //if (!physicsShader)
        //{
        //    physicsShader = Shader.Find("URP/Character/Physics/GPU Physics");
        //}

        if (!physicsMat)
        {
            physicsMat = new Material(physicsShader);
            physicsMat2 = new Material(physicsShader2);
            physicsMat3 = new Material(physicsShader3);
        }

    }

    void MainLoop()
    {
        if (Application.isPlaying)
        {
            PhysicsPass(toPass);
            toPass = toPass == 0 ? 1 : 0;
            PhysicsPass(2);
        }

        Shader.SetGlobalTexture("_PhysicsMap", perProfilePhysicsData.physicsPass);
        Shader.SetGlobalTexture("_InputMap0", perProfilePhysicsData.internalPass0);
        Shader.SetGlobalTexture("_InputMap1", perProfilePhysicsData.internalPass1);
    }

    void MainRenderLoop()
    {
        Shader.SetGlobalTexture("_XFurPhysics", perProfilePhysicsData.physicsPass);
    }

    private void Update()
    {
        MainLoop();
        MainRenderLoop();

    }

    protected void PhysicsPass(int pass = 0)
    {
        if (internalRes < 16)
        {
            SetQuality(quality);
        }
        if (pass == 0)
        {
            prevPos = Owner.transform.position;
        }


        //var targetMatrix = Owner.transform.GetComponent<MeshFilter>().transform.localToWorldMatrix;

        Matrix4x4 targetMatrix;

        Mesh targetMesh;

        if (Owner.transform.GetComponent<SkinnedMeshRenderer>())
        {
            targetMatrix = Owner.transform.GetComponent<SkinnedMeshRenderer>().transform.localToWorldMatrix;

            targetMesh = Owner.GetComponent<SkinnedMeshRenderer>().sharedMesh;
        }
        else
        {
            targetMesh = Owner.GetComponent<MeshFilter>().sharedMesh;
            //targetMatrix = Owner.GetComponent<MeshFilter>().transform.localToWorldMatrix;

            targetMatrix = Owner.transform.localToWorldMatrix;
        }

        var rd = new RenderTextureDescriptor(internalRes, internalRes, RenderTextureFormat.ARGBHalf, 0, 0);

        var tempRT1 = RenderTexture.GetTemporary(rd);

        var currentActive = RenderTexture.active;

        RenderTexture.active = tempRT1;

        Shader.SetGlobalFloat("_XFurBasicMode", 1.0f);
        Shader.SetGlobalMatrix("_XFurObjectMatrix", Owner.transform.localToWorldMatrix);

        switch (pass)
        {
            case 0:
                GL.Clear(true, true, new Color(0, 0, 0, 0));
                physicsMat.SetVector("_WorldPosition", Owner.transform.position);
                physicsMat.SetPass(0);
                Graphics.DrawMeshNow(targetMesh, targetMatrix, 0);
                Graphics.Blit(tempRT1, perProfilePhysicsData.internalPass0);
                break;
            case 1:
                GL.Clear(true, true, new Color(0, 0, 0, 0));
                physicsMat2.SetFloat("_XFurPhysicsSensitivity", physicsSensitivity * 150);
                physicsMat2.SetFloat("_XFurGravityStrength", gravityStrength);
                physicsMat2.SetVector("_WorldPosition", Owner.transform.position);
                physicsMat2.SetVector("_WorldDirection", (prevPos - Owner.transform.position));
                physicsMat2.SetTexture("_InputMap", perProfilePhysicsData.internalPass0);
                physicsMat2.SetPass(0);
                Graphics.DrawMeshNow(targetMesh, targetMatrix, 0);

                Graphics.Blit(tempRT1, perProfilePhysicsData.internalPass1);
                break;
            case 2:
                GL.Clear(true, true, new Color(0, 0, 0, 0));
                physicsMat3.SetTexture("_InputMap", perProfilePhysicsData.internalPass1);
                physicsMat3.SetTexture("_PhysicsMap", perProfilePhysicsData.physicsPass);
                physicsMat3.SetPass(0);
                Graphics.DrawMeshNow(targetMesh, targetMatrix, 0);

                //Graphics.DrawMeshNow(targetMesh, targetMatrix, 0);
                Graphics.Blit(tempRT1, perProfilePhysicsData.physicsPass);
                break;
        }

        RenderTexture.active = currentActive;
        RenderTexture.ReleaseTemporary(tempRT1);

    }
}
