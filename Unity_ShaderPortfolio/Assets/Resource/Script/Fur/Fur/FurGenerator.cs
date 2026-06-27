using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;

[ExecuteAlways]
[RequireComponent(typeof(MeshFilter))]
public class FurGenerator : MonoBehaviour
{
    [Header("Fur Settings")]
    public int instanceCount = 30; // 您的30个实例
    public Material furMaterial;
    private Mesh furMesh;

    // 用于存储每个实例的世界矩阵
    private Matrix4x4[] matrices;
    private MaterialPropertyBlock materialPropertyBlock;
    private float[] _FurStepArray;

    void OnEnable()
    {
        if (furMesh == null)
        {
            MeshFilter mf = GetComponent<MeshFilter>();
            if (mf != null) furMesh = mf.sharedMesh;
        }
        materialPropertyBlock = new MaterialPropertyBlock();
        matrices = new Matrix4x4[instanceCount];
        _FurStepArray = new float[instanceCount];

    }

    void Update()
    {
        if (furMaterial == null || furMesh == null)
            return;
        Matrix4x4 baseWorldMatrix = transform.localToWorldMatrix;

        // 为每个实例计算世界矩阵
        for (int i = 0; i < instanceCount; i++)
        {
            float furStep = (float)i / (instanceCount - 1); // 0 到 1
            _FurStepArray[i] = furStep;
            matrices[i] = baseWorldMatrix;
        }
        
        materialPropertyBlock.SetFloatArray("_FurStep",_FurStepArray);

        // 绘制实例
        Graphics.DrawMeshInstanced(furMesh, 0, furMaterial, matrices, instanceCount, materialPropertyBlock, ShadowCastingMode.Off, false, gameObject.layer);
    }

    void OnDisable()
    {
        // 清理工作
        matrices = null;
    }
}