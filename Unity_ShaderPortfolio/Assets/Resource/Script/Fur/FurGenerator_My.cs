using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshFilter))]
public class FurGenerator_My : MonoBehaviour
{
    [Header("Fur Settings")]
    public int instanceCount = 30;
    public Material furMaterial;
    public Mesh furMesh;

    private Matrix4x4[] matrices;
    private MaterialPropertyBlock materialPropertyBlock;
    private float[] _FurStepArray;

    private void OnEnable()
    {
        if (furMesh == null)
        {
            MeshFilter mf = GetComponent<MeshFilter>();
            if (mf != null) furMesh = mf.sharedMesh;
        }

        materialPropertyBlock = new MaterialPropertyBlock();
        InitArrays();
    }

    private void OnValidate()
    {
        if (instanceCount < 1)
            instanceCount = 1;

        InitArrays();
    }

    private void InitArrays()
    {
        _FurStepArray = new float[instanceCount];
        matrices = new Matrix4x4[instanceCount];
    }

    private void Update()
    {
        if (furMaterial == null || furMesh == null)
            return;

        if (matrices == null || _FurStepArray == null || matrices.Length != instanceCount || _FurStepArray.Length != instanceCount)
        {
            InitArrays();
        }

        for (int i = 0; i < instanceCount; i++)
        {
            matrices[i] = transform.localToWorldMatrix;
            float furStep = (instanceCount == 1) ? 0f : (float)i / (instanceCount - 1);
            _FurStepArray[i] = furStep;
        }

        materialPropertyBlock.Clear();
        materialPropertyBlock.SetFloatArray("_FurStep", _FurStepArray);

        Graphics.DrawMeshInstanced(
            furMesh,
            0,
            furMaterial,
            matrices,
            instanceCount,
            materialPropertyBlock,
            ShadowCastingMode.Off,
            false,
            gameObject.layer
        );
    }
}