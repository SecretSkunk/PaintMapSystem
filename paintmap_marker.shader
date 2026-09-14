Shader "paintmap_marker"
{
    Properties
    {
       
        _MarkerWriteColor ("Marker Color", Color) = (0,0,0,0)
		_ColorR ("Color Red Channel Multiplyer", Range(0.0, 1.0)) = 1
        _ColorG ("Color Green Channel Multiplyer", Range(0.0, 1.0)) = 1
        _ColorB ("Color Blue Channel Multiplyer", Range(0.0, 1.0)) = 1
        _ColorA ("Color Alpha Channel Multiplyer", Range(0.0, 1.0)) = 1

        _ClipWidthToSearch ("Clip Width to search (for IDing Camera only!)", Range(0.0, 10.0)) = 0.01
        _ClipWidth ("Clip width (Actual)", Range(0.0, 10.0)) = 0.1


        [Enum(Square,0,Circle,1)] _CameraShape("TF Camera Field Shape", Float) = 0
		_CameraRadius("TF Camera Field Radius", Float) = 0.02


    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" "PreviewType"="Plane" }
        LOD 100
        ZTest Always
        ZWrite Off
        Blend one one 
		BlendOp Add
        Lighting Off
		Cull Off
        //Conservative True

        Pass
        {
            CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
            
			#if defined(UNITY_COMPILER_HLSL)
			#define PoiInitStruct(type, name) name = (type)0;
			#else
			#define PoiInitStruct(type, name)
			#endif

            #pragma vertex vert
            #pragma fragment frag
			//#pragma geometry geom

            #pragma target 3.0

            float4      _MarkerWriteColor;
			float _ColorR;
			float _ColorG;
			float _ColorB;
			float _ColorA;

			float _Transparency;
			float _WriteAmmount;
			float _ClipWidthToSearch;
			float _ClipWidth;
			float _CameraShape;
			float _CameraRadius;

			//UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);



			
		struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 color : COLOR;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
				float2 uv3 : TEXCOORD3;
				uint vertexId : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
	    struct VertexOut
			{
				float4 pos : SV_POSITION;
				float4 uv[2] : TEXCOORD0;
				float3 normal : TEXCOORD2;
				float4 tangent : TEXCOORD3;
				float4 worldPos : TEXCOORD4;
				float4 localPos : TEXCOORD5;

				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
        

			VertexOut vert(	appdata v){
                UNITY_SETUP_INSTANCE_ID(v);
				VertexOut o;
				PoiInitStruct(VertexOut, o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				//o.normal = UnityObjectToWorldNormal(v.normal);
				//o.tangent.xyz = UnityObjectToWorldDir(v.tangent);
				//o.tangent.w = v.tangent.w;
				//o.vertexColor = v.color;
				
				o.uv[0] = float4(v.uv0.xy, v.uv1.xy);
				o.uv[1] = float4(v.uv2.xy, v.uv3.xy);
                
				o.localPos = v.vertex;
				//o.worldPos = mul(unity_ObjectToWorld, o.localPos);
				
                o.pos = mul(UNITY_MATRIX_MV,o.localPos);
				float l = -_CameraRadius;
				float r =  _CameraRadius;
				float b = -_CameraRadius;
				float t =  _CameraRadius;
				float n =  -_ClipWidth/2;
				float f =  _ClipWidth/2;

				float4x4  projection = float4x4(
					float4(2.0/(r-l),     0.0,          0.0,         0.0),
					float4(0.0,           2.0/(t-b),    0.0,         0.0),
					float4(0.0,           0.0,         -2.0/(f-n),   0.0),
					float4(-(r+l)/(r-l), -(t+b)/(t-b), -(f+n)/(f-n), 1.0)
				);
				o.pos=mul(projection, o.pos);

				o.localPos=o.pos/o.pos.w;

				
                o.pos=float4((o.uv[0].xy-float2(.5,.5))*float2(2,-2), 1, 1);
				
				return o;

            }



   			[maxvertexcount(3)]
            void geom(triangle VertexOut input[3],uint pid : SV_PrimitiveID, inout TriangleStream<VertexOut> OutputStream)
            {
                VertexOut test = (VertexOut)0;
                //float3 normal = normalize(cross(input[1].worldPos.xyz - input[0].worldPos.xyz, input[2].worldPos.xyz - input[0].worldPos.xyz));
                /*
				for(int i = 0; i < 3; i++)
                {    
					if(input[i].localPos.x > 1 ||input[i].localPos.x < -1 || input[i].localPos.y > 1 ||input[i].localPos.y < -1 || input[i].localPos.z <0 ){
						return;
					}
				}            
					*/
				#define fixedZ 0.0
				if(pid == 0) {
					test.pos.xyz = float3(1,-3,fixedZ);
					test.uv[0].xy = float2(0,0);
					OutputStream.Append(test);
					test.pos.xyz = float3(1,3,fixedZ);
					test.uv[0].xy = float2(0,0);
					OutputStream.Append(test);
					test.pos.xyz = float3(-3,3,fixedZ);
					test.uv[0].xy = float2(0,0);
                    OutputStream.Append(test);
					return;
				}
				

				for(int i = 0; i < 3; i++)
                {
                    //test.normal = normal;
					//test.normal = float4(1,0,1,1);
                    test.pos = input[i].pos;
                    test.uv = input[i].uv;
					test.localPos=input[i].localPos;
                    OutputStream.Append(test);
                }
            }



            float4 frag(VertexOut i) : COLOR
            {			
		

				//clip(i.localPos);
				bool isWallCamera = (_ProjectionParams.z - _ProjectionParams.y) == _ClipWidthToSearch;
				clip(isWallCamera - 0.5);
				//clip(i.localPos.z);
				//clip(i.localPos.xy*.5+.5);
				//clip(-1* (i.localPos.z-1));
				
			
				if(i.localPos.x > 1 ||i.localPos.x < -1 || i.localPos.y > 1 || i.localPos.y < -1 || i.localPos.z >1 || i.localPos.z < -1 ){
					discard;
				}
				//shape rejection (for circles)
				if (_CameraShape ==1 && ( i.localPos.x*i.localPos.x+i.localPos.y*i.localPos.y > 1)){
						discard;
				}
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);  
                return _MarkerWriteColor*float4(_ColorR,_ColorG,_ColorB,_ColorA)*_WriteAmmount;
            } 
            ENDCG
        }
    }
}