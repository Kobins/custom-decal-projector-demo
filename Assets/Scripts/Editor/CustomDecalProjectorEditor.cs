using System;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(CustomDecalProjector))]
public class CustomDecalProjectorEditor : Editor
{        
    static readonly GUIContent k_AngleFadeContent = EditorGUIUtility.TrTextContent("Angle Fade", "Controls the fade out range of the decal based on the angle between the Decal backward direction and the vertex normal of the receiving surface. Requires 'Decal Layers' to be enabled in the URP Asset and Frame Settings.");

    SerializedProperty m_TintProperty;
    SerializedProperty m_StartAngleFadeProperty;
    SerializedProperty m_EndAngleFadeProperty;

    private void OnEnable()
    {
        m_TintProperty = serializedObject.FindProperty("m_Tint");
        m_StartAngleFadeProperty = serializedObject.FindProperty("m_StartAngleFade");
        m_EndAngleFadeProperty = serializedObject.FindProperty("m_EndAngleFade");
    }
    

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUI.BeginChangeCheck();
        {
            EditorGUILayout.PropertyField(m_TintProperty);
            float angleFadeMinValue = m_StartAngleFadeProperty.floatValue;
            float angleFadeMaxValue = m_EndAngleFadeProperty.floatValue;
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.MinMaxSlider(k_AngleFadeContent, ref angleFadeMinValue, ref angleFadeMaxValue, 0.0f, 180.0f);
            if (EditorGUI.EndChangeCheck())
            {
                m_StartAngleFadeProperty.floatValue = angleFadeMinValue;
                m_EndAngleFadeProperty.floatValue = angleFadeMaxValue;
            }
        }
        if (EditorGUI.EndChangeCheck())
        {
            serializedObject.ApplyModifiedProperties();
        }
        
    }
}