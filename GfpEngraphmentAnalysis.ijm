//Author: E. Rebollo; Molecular Imaging Platform, IBMB. January 2020
//Tested in Fiji Lifeline 22 Dec 2015
/* This macro: 
	1. Segments gfp cells (based on global thresholding)
	2. Segments dapi (based on local thresholding) and counts nuclei
	3. Selects nuclei from gfp+ cells and counts gfp+ cells
	4. Counts gfp+ pax7+ nuclei
	4. Delivers a verification image to compare to the original
*/

//CHOOSE A DIRECTORY TO SAVE RESULTS TABLE
//MyResultsFolder=getDirectory("Choose a folder to save results");

//Choose a threshold for the gfp, if signal is high enoogh use "Otse dark", if signal is bad compared to surrounding structures, use "Moments dar".
Global="Moments dark";
ThresholdGFP=8000;

//PREPARE IMAGES
//Retrieve image name 
rawName = getTitle();
name = File.nameWithoutExtension;
rename(name);
getPixelSize(unit, pixelWidth, pixelHeight);
run("Properties...", "channels=4 slices=1 frames=1 unit=µm pixel_width=1.0000000 pixel_height=1.0000000 voxel_depth=0.0000000");
getChannels(name);

function getChannels(title){
	selectWindow(title);
	run("Duplicate...", "title=copy duplicate");
	run("Split Channels");
	selectWindow("C1-copy");
	run("Median...", "radius=1");
	rename("pax7");
	selectWindow("C2-copy");
	run("Close");
	selectWindow("C3-copy");
	run("Median...", "radius=1");
	rename("gfp");
	selectWindow("C4-copy");
	run("Median...", "radius=1");
	rename("dapi");
}


//SEGMENT GFP AND CREATE CLEAN GFP MASK
selectWindow("gfp");
resetMinAndMax();
run("Duplicate...", "title=gfpmask");
run("Gaussian Blur...", "sigma=2");
setAutoThreshold(Global);
setOption("BlackBackground", false);
run("Convert to Mask");
//Eliminate long shapes (edges), small objects and weak signal objects
//This step is done using the macro function cleanMask() listed at the end
run("Analyze Particles...", "pixel circularity=0.00-0.40 exclude add");
cleanMask("gfpmask", "Round", 0.25);
selectWindow("gfpmask");
run("Select All");
run("Analyze Particles...", "size=0-Infinity pixel exclude add");
cleanMask("gfpmask", "Area", 100);


//Trick to eliminate cells on the edges that overlap with cells inside
selectWindow("gfpmask");
run("Watershed");
run("Select All");
run("Analyze Particles...", "size=0-Infinity pixel exclude add");
selectWindow("gfpmask");
run("Select All");
setForegroundColor(255, 255, 255);
run("Fill");
fillMask("gfpmask");
run("Options...", "iterations=1 count=1 do=Dilate");
run("Options...", "iterations=1 count=1 do=Erode");
roiManager("reset");

//Eliminate rois where gfp signal is under a certain threshold
//This step is done using the macro function discardROIs() listed at the end
selectWindow("gfpmask");
run("Select All");
run("Analyze Particles...", "size=0-Infinity pixel exclude add");
selectWindow("gfp");
roiManager("Show All");
discardROIsUnder("gfp", "Mean", ThresholdGFP);
//update gfpmask
selectWindow("gfpmask");
run("Select All");
setForegroundColor(255, 255, 255);
run("Fill");
fillMask("gfpmask");

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

//SELECT NUCLEI FROM GFP CELLS
discardROIsUnder("gfpmask", "Mode", 255);

//CREATE VERIFICATION IMAGE AND DRAW GFP+ NUCLEI
run("Merge Channels...", "c2=gfpmask c3=dapimask create keep ignore");
run("RGB Color");
rename("resultImage");
selectWindow("Composite");
run("Close");
selectWindow("dapimask");
run("Close");
drawYellowROIs("resultImage");

//COUNT DAPI+ GFP+ cells
NoGFPCells = roiManager("Count");
print("No. Dapi+ gfp+ : "+NoGFPCells);

//COUNT DAPI+ GFP+ PAX7+
discardROIsUnder("pax7", "Max", 2000);

//COUNT DAPI+ GFP+ PAX7+ cells
NoGFPPax7Cells = roiManager("Count");
print("No. Dapi+ gfp+ pax7+: "+NoGFPPax7Cells);
for (i=0; i<roiManager("Count"); i++) {
		roiManager("Select", i);
		run("Enlarge...", "enlarge=-3 pixel");
		}
fillMagentaROIs("resultImage");


//RENAME IMAGES & CLOSE WINDOWS
selectWindow("resultImage");
rename(name+"_macro2");


//CLOSE WINDOWS
roiManager("Show None");
selectWindow("ROI Manager");
run("Close");	
selectWindow("Results");
run("Close");	
selectWindow("pax7");
run("Close");	
selectWindow("gfp");
run("Close");
selectWindow("gfpmask");
run("Close");


////FUNCTIONS/////////////////////////


function cleanMask(image, parameter, threshold){
	selectWindow(image);
	run("Select All");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter shape feret's integrated median redirect=None decimal=2");
	//Dicard ROIs below threshold value
	noRois = roiManager("count");
	for(j=0; j<noRois; j++){
		roiManager("select", j);
		roiManager("measure");
		value=getResult(parameter,0);
		if(value > threshold) {
			roiManager("delete");
			j--;
			noRois--;
			}
		run("Clear Results");
		}
	
	for (j=0; j<roiManager("Count"); j++) {
		roiManager("Select", j);
		setForegroundColor(255, 255, 255);
		run("Fill");
		}
	roiManager("Show None");
	selectWindow("ROI Manager");
	run("Close");		
}

function discardROIsUnder(image, parameter, threshold){
	selectWindow(image);
	run("Select All");
	run("Set Measurements...", "area mean standard modal min centroid center perimeter shape feret's integrated median redirect=None decimal=2");
	//Dicard ROIs below threshold value
	noRois = roiManager("count");
	for(j=0; j<noRois; j++){
		roiManager("select", j);
		roiManager("measure");
		value=getResult(parameter,0);
		if(value < threshold) {
			roiManager("delete");
			j--;
			noRois--;
			}
		run("Clear Results");
		}
	return noRois;
}

function drawYellowROIs(image){
	//Draw selections into image
	selectWindow(image);
	setForegroundColor(255, 255, 90);
	roiManager("deselect");
	roiManager("Set Line Width", 2);
	roiManager("draw");
}

function fillMagentaROIs(image){
	//Fill selections into image
	selectWindow(image);
	setForegroundColor(255, 0, 255);
	roiManager("deselect");
	roiManager("Fill");
}

function fillMask(image){
	//Fill selections into image
	selectWindow(image);
	setForegroundColor(0, 0, 0);
	roiManager("deselect");
	roiManager("Fill");
}
