//Fiji Lifeline 22 Dec 2015
//Author: E. Rebollo; Molecular Imaging Platform, IBMB.
/* This macro: 
	1. Segments & counts nuclei (based on local thresholding)
	2. Segments Dil and selects/counts Dil cells having dapi
	3. Counts pax7 and ki67 within dil+ cells
	4. Delivers a verification image to compare to the original
*/

//The plugin "Morphology" (from Landini) has to be installed

//CHOOSE A DIRECTORY TO SAVE RESULTS TABLE
//MyResultsFolder=getDirectory("Choose a folder to save results");

//PREPARE IMAGES
//Retrieve image name 
rawName = getTitle();
name = File.nameWithoutExtension;
rename(name);
getPixelSize(unit, pixelWidth, pixelHeight);
run("Properties...", "channels=4 slices=1 frames=1 unit=µm pixel_width=1.0000000 pixel_height=1.0000000 voxel_depth=0.0000000");
getChannels(name);

//SEGMENT DAPI
selectWindow("dapi");
run("Duplicate...", "title=dapimask");
run("Enhance Local Contrast (CLAHE)", "blocksize=25 histogram=25 maximum=3 mask=*None*");
run("Normalize Local Contrast", "block_radius_x=25 block_radius_y=25 standard_deviations=3 center stretch");
setAutoThreshold("Otsu dark");
run("Convert to Mask");
run("Watershed");
roiManager("reset");
run("Analyze Particles...", "size=40-Infinity pixel exclude add");
roiManager("Set Color", "cyan");
roiManager("Set Line Width", 1);
selectWindow("dapi");
roiManager("Show All without labels");
selectWindow("dapi");
run("Close");
//CREATE DAPI MASK
selectWindow("dapimask");
run("Select All");
setForegroundColor(255, 255, 255);
run("Fill", "slice");
roiManager("Deselect");
setForegroundColor(0, 0, 0);
roiManager("Fill");
run("Options...", "iterations=1 count=1 do=Open");
run("Options...", "iterations=1 count=1 do=Erode");
run("Options...", "iterations=1 count=1 do=Dilate");
//Count nuclei
NoNuclei = roiManager("Count");
print("No. Dapi: "+NoNuclei);

//SEGMENT DIL
selectWindow("dil");
resetMinAndMax();
run("Duplicate...", "title=dilmask");
run("Gaussian Blur...", "sigma=2");
run("8-bit");
run("Auto Local Threshold", "method=Phansalkar radius=150 parameter_1=0 parameter_2=0 white");
run("Convert to Mask");
run("Watershed");
roiManager("reset");
run("Analyze Particles...", "size=120-Infinity pixel exclude add");
roiManager("Set Color", "cyan");
roiManager("Set Line Width", 1);
selectWindow("dil");
roiManager("Show All without labels");
selectWindow("dil");
run("Close");
//CREATE DIL MASK
selectWindow("dilmask");
run("Select All");
setForegroundColor(255, 255, 255);
run("Fill", "slice");
roiManager("Deselect");
setForegroundColor(0, 0, 0);
roiManager("Fill");
run("Options...", "iterations=1 count=1 do=Open");
run("Options...", "iterations=1 count=1 do=Erode");
run("Options...", "iterations=1 count=1 do=Dilate");

//REMOVE DILS WITHOUT NUCLEI FROM ROI MANAGER
run("GreyscaleReconstruct ", "mask=dilmask seed=dapimask create");
rename("dilPlusMask");
run("Invert LUT");
roiManager("Reset");
run("Analyze Particles...", "size=0-Infinity add");
selectWindow("dilmask");
run("Close");

//MAKE COMPOSITE
run("Merge Channels...", "c1=dilPlusMask c3=dapimask create keep ignore");
run("RGB Color");
rename("resultImage");
selectWindow("Composite");
run("Close");
selectWindow("dapimask");
run("Close");

//COUNT/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

//COUNT DAPI+ DIL+ cells
NoDilCells = roiManager("Count");
print("No. Dapi+ Dil+ : "+NoDilCells);

//COUNT DIL+ PAX7+ CELLS & paint rois
NoTotalPax7 = discardROIs("pax7", 1000);
print("No. Dapi+ Dil+ Pax7+ : "+NoTotalPax7);
roiManager("Set Line Width", 2);
drawGreenROIs("resultImage");


//COUNT DIL+ PAX7+(HIGH) CELLS & paint rois
NoHighPax7 = discardROIs("pax7", 5000);
print("No. Dapi+ Dil+ Pax7+(High) : "+NoHighPax7);
for (i=0; i<roiManager("Count"); i++) {
	roiManager("Select", i);
	run("Enlarge...", "enlarge=2 pixel");
	roiManager("Update")
}
roiManager("Set Line Width", 4);
drawGreenROIs("resultImage");


//COUNT DIL+ KI67+ CELLS
//load dil mask to roi manager
selectWindow("dilPlusMask");
roiManager("Reset");
run("Analyze Particles...", "size=0-Infinity add");
selectWindow("dilPlusMask");
run("Close");
Noki67 = discardROIs("ki67", 4000);
print("No. Dapi+ Dil+ ki67 : "+Noki67);


//COUNT DIL+ PAX7+ KI67+ cells
Noki67Pax7 = discardROIs("pax7", 1000);
for (i=0; i<roiManager("Count"); i++) {
	roiManager("Select", i);
	run("Enlarge...", "enlarge=-4 pixel");
	roiManager("Update")
}
print("No. Dapi+ Dil+ pax7+ ki67+ :"+Noki67Pax7);
fillYellowROIs("resultImage");

//RENAME IMAGES & CLOSE WINDOWS
selectWindow("resultImage");
rename(name+"_macro");
selectWindow("pax7");
run("Close");
selectWindow("ki67");
run("Close");
selectWindow("Results");
run("Close");
selectWindow("ROI Manager");
run("Close");




//FUNCTIONS///////////////////////////////////////////////////////////

function getChannels(title){
	selectWindow(title);
	run("Duplicate...", "title=copy duplicate");
	run("Split Channels");
	selectWindow("C1-copy");
	run("Median...", "radius=1");
	rename("dil");
	selectWindow("C2-copy");
	run("Median...", "radius=1");
	rename("ki67");
	selectWindow("C3-copy");
	run("Median...", "radius=1");
	rename("pax7");
	selectWindow("C4-copy");
	run("Median...", "radius=1");
	rename("dapi");
}

function discardROIs(image, threshold){
	selectWindow(image);
	run("Select All");
	run("Set Measurements...", "min redirect=None decimal=2");
	//Dicard ROIs below threshold value
	noRois = roiManager("count");
	for(j=0; j<noRois; j++){
		roiManager("select", j);
		roiManager("measure");
		value=getResult("Max",0);
		if(value < threshold) {
			roiManager("delete");
			j--;
			noRois--;
			}
		run("Clear Results");
		}
	return noRois;
}

function drawGreenROIs(image){
	//Draw selections into image
	selectWindow(image);
	setForegroundColor(0, 255, 0);
	roiManager("deselect");
	roiManager("draw");
}

function fillYellowROIs(image){
	//Fill selections into image
	selectWindow(image);
	setForegroundColor(255, 255, 90);
	roiManager("deselect");
	roiManager("Fill");
}
