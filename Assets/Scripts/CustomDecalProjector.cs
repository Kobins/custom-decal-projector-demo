using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
[ExecuteAlways]
public class CustomDecalProjector : MonoBehaviour
{
    private MeshFilter _meshFilter;
    private MeshRenderer _renderer;

    [SerializeField]
    [Range(0, 180)]
    private float m_StartAngleFade = 180.0f;
    /// <summary>
    /// Angle between decal backward orientation and vertex normal of receiving surface at which the Decal start to fade off.
    /// </summary>
    public float startAngleFade
    {
        get
        {
            return m_StartAngleFade;
        }
        set
        {
            m_StartAngleFade = Mathf.Clamp(value, 0.0f, 180.0f);
            OnValidate();
        }
    }

    [SerializeField]
    [Range(0, 180)]
    private float m_EndAngleFade = 180.0f;


    /// <summary>
    /// Angle between decal backward orientation and vertex normal of receiving surface at which the Decal end to fade off.
    /// </summary>
    public float endAngleFade
    {
        get
        {
            return m_EndAngleFade;
        }
        set
        {
            m_EndAngleFade = Mathf.Clamp(value, m_StartAngleFade, 180.0f);
            OnValidate();
        }
    }

    private void Awake()
    {
        _meshFilter = GetComponent<MeshFilter>();
        _renderer = GetComponent<MeshRenderer>();
    }

    private static readonly int AngleFade = Shader.PropertyToID("_AngleFade");
    private void OnValidate()
    {
        if(!_renderer) return;
        var mat = _renderer.sharedMaterial;
        if(!mat) return;
        mat.SetVector(AngleFade, new Vector4(startAngleFade / 180f, endAngleFade / 180f, 0f, 0f));
    }

    private void Update()
    {
    }
}
