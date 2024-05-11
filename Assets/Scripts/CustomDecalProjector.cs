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

    private void Awake()
    {
        _meshFilter = GetComponent<MeshFilter>();
        _renderer = GetComponent<MeshRenderer>();
    }

    private void Update()
    {
    }
}
