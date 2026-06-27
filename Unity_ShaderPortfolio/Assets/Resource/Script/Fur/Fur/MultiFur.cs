using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

[ExecuteAlways]
[RequireComponent(typeof(MeshFilter))]
public class MultiFur : MonoBehaviour
{
    [Header("Fur Settings")]
    public int instanceCount = 30; // 您的30个实例
    public Material furMaterial;
    private Mesh furMesh;

    private ComputeBuffer furStepBuffer;
    private ComputeBuffer argsBuffer;
    private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    private MaterialPropertyBlock materialPropertyBlock;
    private List<float> furSteps = new List<float>();

    void OnEnable()
    {
        if (furMesh == null)
        {
            MeshFilter mf = GetComponent<MeshFilter>();
            if (mf != null) furMesh = mf.sharedMesh;
        }

        materialPropertyBlock = new MaterialPropertyBlock();
        InitializeBuffers();
    }

    void InitializeBuffers()
    {
        // 清理旧缓冲区
        ReleaseBuffers();

        // 计算实例数据
        furSteps.Clear();
        for (int i = 0; i < instanceCount; i++)
        {
            float furStep = (float)i / (instanceCount - 1); // 0 到 1
            furSteps.Add(furStep);
        }

        // 创建并填充毛发步长缓冲区
        furStepBuffer = new ComputeBuffer(instanceCount, sizeof(float));
        furStepBuffer.SetData(furSteps);

        // 设置材质属性块
        materialPropertyBlock.SetBuffer("_FurStepBuffer", furStepBuffer);
        
        // 启用USE_STRUCTURED_BUFFER关键字
        furMaterial.EnableKeyword("USE_STRUCTURED_BUFFER");

        // 设置间接渲染参数
        args[0] = (uint)furMesh.GetIndexCount(0);
        args[1] = (uint)instanceCount;
        args[2] = (uint)furMesh.GetIndexStart(0);
        args[3] = (uint)furMesh.GetBaseVertex(0);
        args[4] = 0;

        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);
    }

    void Update()
    {
        if (furMaterial == null || argsBuffer == null || furMesh == null)
            return;

        // 使用间接绘制调用
        Graphics.DrawMeshInstancedIndirect(
            furMesh, 
            0, 
            furMaterial, 
            new Bounds(transform.position, transform.localScale), 
            argsBuffer, 
            0, 
            materialPropertyBlock, 
            ShadowCastingMode.Off, 
            false, 
            gameObject.layer
        );
    }

    void OnDestroy()
    {
        ReleaseBuffers();
    }

    void OnDisable()
    {
        ReleaseBuffers();
    }

    void ReleaseBuffers()
    {
        if (furStepBuffer != null)
        {
            furStepBuffer.Release();
            furStepBuffer = null;
        }
        if (argsBuffer != null)
        {
            argsBuffer.Release();
            argsBuffer = null;
        }
        
        // 禁用关键字
        if (furMaterial != null)
        {
            furMaterial.DisableKeyword("USE_STRUCTURED_BUFFER");
        }
    }
}