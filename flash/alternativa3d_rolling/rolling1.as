// this is Flash CS3 timeline script

import alternativa.engine3d.core.*
import alternativa.engine3d.display.*
import alternativa.engine3d.materials.*
import alternativa.engine3d.primitives.*
import alternativa.types.*

stage.align = "top"; stage.scaleMode = "noScale";

// we make 3D viewport
var view:View = new View; view.width = 550; view.height = 400; addChild (view);

// we make scene and camera
var scene:Scene3D = new Scene3D; view.camera = new Camera3D; view.camera.z = -700;
scene.root = new Object3D; scene.root.addChild (view.camera);

// we make solid color material
var mat1:FillMaterial = new FillMaterial (0xFF80FF, 1, "normal", 1);

// we make the box
var box1:Box = new Box (200, 200, 200); box1.cloneMaterialToAllSurfaces (mat1);

// we wrap the box into dummy object and add to scene
var box1papa:Object3D = new Object3D; box1papa.addChild (box1); scene.root.addChild (box1papa);

// we offset the box to demonstrate why this is called "rolling" :)
box1.z = 250;

// rock and roll :)
var rotY:Number = 0, roll:Number = 0, PI2:Number = Math.PI * 2;
addEventListener ("enterFrame", function (event:*):void {
	rotY += 0.1; if (rotY > PI2) rotY -= PI2;
	roll += 0.1; if (roll > PI2) roll -= PI2;

	box1papa.rotationY = rotY;
	box1.rotationZ = roll;

	scene.calculate ();
}
);
