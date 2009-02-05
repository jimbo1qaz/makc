// this is Flash CS3 timeline script

import alternativa.engine3d.core.*
import alternativa.engine3d.display.*
import alternativa.engine3d.materials.*
import alternativa.engine3d.primitives.*
import alternativa.types.*

stage.align = "top"; stage.scaleMode = "noScale";

// we start with previous code here...
var view:View = new View; view.width = 550; view.height = 400; addChild (view);

var scene:Scene3D = new Scene3D; view.camera = new Camera3D; view.camera.z = -700;
scene.root = new Object3D; scene.root.addChild (view.camera);

// we make two materials now
var mat1:FillMaterial = new FillMaterial (0xFF80FF, 1, "normal", 1);
var mat2:FillMaterial = new FillMaterial (0x00FF00, 1, "normal", 1);

var box1:Box = new Box (200, 200, 200); box1.cloneMaterialToAllSurfaces (mat1);

var box1papa:Object3D = new Object3D; box1papa.addChild (box1); scene.root.addChild (box1papa);

box1.z = 250;

// we make second box and add it to scene directly
var box2:Box = new Box (200, 200, 200); box2.cloneMaterialToAllSurfaces (mat2); scene.root.addChild (box2);

// we are going to need few variables for doing our math
var rotateYMatrix:Matrix3D = new Matrix3D;
var rollingMatrix:Matrix3D = new Matrix3D;
var rollingAxis:Point3D = new Point3D;
var eulerAngles:Point3D = new Point3D;

// rock and roll :)
var rotY:Number = 0, roll:Number = 0, PI2:Number = Math.PI * 2;
addEventListener ("enterFrame", function (event:*):void {
	rotY += 0.1; if (rotY > PI2) rotY -= PI2;
	roll += 0.1; if (roll > PI2) roll -= PI2;

	box1papa.rotationY = rotY;
	box1.rotationZ = roll;

	// we compute transformation matrix for rotY alone
	// (note that it will be the same as box1papa.transformation)
	rotateYMatrix.toIdentity ();
	rotateYMatrix.rotate (0, rotY, 0);

	// we compute new "local" Z axis
	rollingAxis.x = rotateYMatrix.c;
	rollingAxis.y = rotateYMatrix.g;
	rollingAxis.z = rotateYMatrix.k;

	// we compute transformation matrix for roll after rotY
	rollingMatrix.fromAxisAngle (rollingAxis, roll);

	// we replace rotateYMatrix with combined transformation matrix
	rotateYMatrix.combine (rollingMatrix);

	// we compute euler angles that represent this combined transformation
	rotateYMatrix.getRotations (eulerAngles);

	// we rotate second box
	box2.rotationX = eulerAngles.x;
	box2.rotationY = eulerAngles.y;
	box2.rotationZ = eulerAngles.z;

	scene.calculate ();
}
);
