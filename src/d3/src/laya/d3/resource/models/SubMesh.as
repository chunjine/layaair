package laya.d3.resource.models {
	import laya.d3.component.animation.SkinAnimations;
	import laya.d3.core.MeshSprite3D;
	import laya.d3.core.Sprite3D;
	import laya.d3.core.material.BaseMaterial;
	import laya.d3.core.material.StandardMaterial;
	import laya.d3.core.render.IRenderable;
	import laya.d3.core.render.RenderElement;
	import laya.d3.core.render.RenderState;
	import laya.d3.graphics.IndexBuffer3D;
	import laya.d3.graphics.VertexBuffer3D;
	import laya.d3.graphics.VertexDeclaration;
	import laya.d3.graphics.VertexElementUsage;
	import laya.d3.math.Matrix4x4;
	import laya.d3.resource.models.Mesh;
	import laya.d3.utils.Utils3D;
	import laya.resource.IDispose;
	import laya.utils.Stat;
	import laya.webgl.WebGL;
	import laya.webgl.WebGLContext;
	import laya.webgl.shader.Shader;
	import laya.webgl.utils.Buffer2D;
	
	/**
	 * <code>SubMesh</code> 类用于创建子网格数据模板。
	 */
	public class SubMesh implements IRenderable, IDispose {
		/** @private */
		private var _mesh:Mesh;
		
		/** @private */
		public var _boneIndicesList:Vector.<Uint8Array>;
		/** @private */
		public var _subIndexBufferStart:Vector.<int>;
		/** @private */
		public var _subIndexBufferCount:Vector.<int>;
		/** @private */
		public var _skinAnimationDatas:Vector.<Float32Array>;
		
		/** @private */
		public var _bufferUsage:*;
		/** @private */
		public var _indexInMesh:int;
		
		/** @private */
		public var _vertexBuffer:VertexBuffer3D;
		/** @private */
		public var _vertexBufferStart:int;
		/** @private */
		public var __vertexBufferCount:int;
		/** @private */
		public var _indexBuffer:IndexBuffer3D;
		/** @private */
		public var _indexBufferStart:int;
		/** @private */
		public var _indexBufferCount:int;
		
		/**
		 * @private
		 */
		public function get _vertexBufferCount():int {
			return 1;
		}
		
		/**
		 * @private
		 */
		public function get indexOfHost():int {
			return _indexInMesh;
		}
		
		/**
		 * @private
		 */
		public function get triangleCount():int {
			return _indexBuffer.indexCount / 3;
		}
		
		/**
		 * 创建一个 <code>SubMesh</code> 实例。
		 * @param	mesh  网格数据模板。
		 */
		public function SubMesh(mesh:Mesh) {
			_bufferUsage = {};
			_mesh = mesh;
			_boneIndicesList = new Vector.<Uint8Array>();
			_subIndexBufferStart = new Vector.<int>();
			_subIndexBufferCount = new Vector.<int>();
		}
		
		/**
		 * @private
		 */
		public function _getVertexBuffer(index:int = 0):VertexBuffer3D {
			if (index === 0)
				return _vertexBuffer;
			else
				return null;
		}
		
		/**
		 * @private
		 */
		public function _getIndexBuffer():IndexBuffer3D {
			return _indexBuffer;
		}
		
		/**
		 * @private
		 */
		public function _beforeRender(state:RenderState):Boolean {
			_vertexBuffer._bind();
			_indexBuffer._bind();
			return true;
		}
		
		/**NATIVE*/
		public function _renderRuntime(conchGraphics3D:*, renderElement:RenderElement, state:RenderState):void {
			var material:BaseMaterial = renderElement._material, owner:Sprite3D = renderElement._sprite3D;
			//TODO NATIVE scene的shaderValue
			/*
			   var datas:Array=state.scene._shaderValues.data;
			   var len:int = datas.length;
			   for (var i:int = 0; i < len; i ++) {
			   var data:*= datas[i];
			   //(data)&&(renderElement._conchSubmesh.setShaderValue(i, data));
			   }
			 */
			conchGraphics3D.drawSubmesh(renderElement._conchSubmesh, 0, WebGLContext.TRIANGLES, 0, _indexBuffer.indexCount);
		}
		
		/**
		 * @private
		 * 渲染。
		 * @param	state 渲染状态。
		 */
		public function _render(state:RenderState):void {
			var indexCount:int = 0;
			var renderElement:RenderElement = state.renderElement;
			if (_indexBufferCount > 1) {
				var boneIndicesListCount:int = _boneIndicesList.length;
				if (boneIndicesListCount > 0) {
					for (var i:int = 0; i < boneIndicesListCount; i++) {
						if (_skinAnimationDatas) {
							renderElement._shaderValue.setValue(SkinAnimations.BONES, _skinAnimationDatas[i]);
							state._shader.uploadRenderElementUniforms(renderElement._shaderValue.data);
						}
						WebGL.mainContext.drawElements(WebGLContext.TRIANGLES, _subIndexBufferCount[i], WebGLContext.UNSIGNED_SHORT, _subIndexBufferStart[i] * 2);
					}
				} else {
					if (_skinAnimationDatas) {
						renderElement._shaderValue.setValue(SkinAnimations.BONES, _skinAnimationDatas[0]);
						state._shader.uploadRenderElementUniforms(renderElement._shaderValue.data);
					}
					WebGL.mainContext.drawElements(WebGLContext.TRIANGLES, _indexBufferCount, WebGLContext.UNSIGNED_SHORT, _indexBufferStart * 2);
				}
				indexCount = _indexBufferCount;
			} else {//TODO:兼容旧格式
				indexCount = _indexBuffer.indexCount;
				if (_skinAnimationDatas) {
					renderElement._shaderValue.setValue(SkinAnimations.BONES, _skinAnimationDatas[0]);
					state._shader.uploadRenderElementUniforms(renderElement._shaderValue.data);
				}
				WebGL.mainContext.drawElements(WebGLContext.TRIANGLES, indexCount, WebGLContext.UNSIGNED_SHORT, 0);
			}
			Stat.drawCall++;
			Stat.trianglesFaces += indexCount / 3;
		}
		
		/**
		 * <p>彻底清理资源。</p>
		 * <p><b>注意：</b>会强制解锁清理。</p>
		 */
		public function dispose():void {
			_boneIndicesList = null;
			_indexBuffer.dispose();
			_vertexBuffer.dispose();
		}
	
	}
}