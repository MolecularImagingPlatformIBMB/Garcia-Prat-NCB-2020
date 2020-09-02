///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Name: Correct&measureMuscleArea.ijm
// Author: Elena Rebollo
// Date: 31/01/2020
// Description: uses the fluorescence (gfp + dapi) image and the probability map produced by weka segmentation;
//             it allows to correct the segmentation in three steps (separate object, complete objects and delete objects)
// .            it then measures the specified parameters in all objects
// Comment: works with Fiji lifeline 22 Dec 2015

///////////////////////////////////////////////////////////////////////////////////////////////////////////////


//OPEN FLUORESCENCE IMAGE AND PROBABILITY MAP. THE FIRST HAS TO BE SELECTED
//prepare images

open();
rawName = getTitle();
name = File.nameWithoutExtension;
rename("fluo");

open();
rename("probability map");

getChannels("fluo");
function getChannels(title){
	selectWindow(title);
	run("Duplicate...", "title=copy duplicate");
	run("Split Channels");
	selectWindow("C1-copy");
	run("Fire");
	rename("gfp");
	selectWindow("C2-copy");
	run("Close");
}
selectWindow("fluo");
run("Close");


//GENERATE MASK
selectWindow("probability map");
run("Select All");
run("Duplicate...", "title=mask");
run("8-bit");
setAutoThreshold("Otsu dark");
run("Convert to Mask");
run("Fill Holes");
selectWindow("probability map");
run("Close");


//CORRECT MASK

Correction = true;
while(Correction) ¨{


updateROIs("mask", "gfp");

//separate rois
GoOn = true;
setTool("freeline");
while(GoOn) {
	noRois=roiManager("Count");
	paintWhiteFreelines("mask", noRois);
	GoOn =  (selectionType()==7);
	if (GoOn == true) {
		updateROIs("mask", "gfp");
	}
	GoOn = getNumber("Go on?", 1);
}

updateROIs("mask", "gfp");

//fill rois
GoOn = true;
setTool("freeline");
while(GoOn) {
	noRois=roiManager("Count");
	paintBlackFreelines("mask", noRois);
	GoOn =  (selectionType()==7);
	if (GoOn == true) {
		updateROIs("mask", "gfp");
	}
	GoOn = getNumber("Go on?", 1);
}

updateROIs("mask", "gfp");

//delete rois
GoOn = true;
setTool("wand");
while(GoOn) {
	noRois=roiManager("Count");
	removeRois("mask", noRois);
	GoOn =  (selectionType()==4);
	if (GoOn == true) {
		updateROIs("mask", "gfp");
	}
	GoOn = getNumber("Go on?", 1);
}

updateROIs("mask", "gfp");

Correction = getNumber("More correction needed?", 1);
}

//MEASURE FIBERS
run("Set Measurements...", "area mean feret's integrated redirect=None decimal=2");
roiManager("deselect");
selectWindow("gfp");
roiManager("measure");

//CREATE VERIFICATION IMAGE
showROIs("gfp");

//RENAME MASK & RESULTS
selectWindow("mask");
rename(name+"_mask");
selectWindow("corrResult");
rename(name+"verificationImage");
selectWindow("Results");
rename(name+"_results");
selectWindow("gfp");
run("Close");
selectWindow("ROI Manager");
run("Close");



//////////FUNCTIONS/////////////////////////////


function paintWhiteFreelines(mask, count){
	selectWindow(mask);
	roiManager("Show None");
	run("Line Width...", "line=2");
	setTool("freeline");
	waitForUser("paint separation lines, click <t> after each line");
	setForegroundColor(255,255,255);
	for (i=count; i<roiManager("count"); i++) {
		roiManager("Select", i);
		run("Line to Area");
		run("Fill", "slice");
	}
	
}

function paintBlackFreelines(mask, count){
	selectWindow(mask);
	roiManager("Show None");
	run("Line Width...", "line=2");
	setTool("freeline");
	waitForUser("paint joining lines, click <t> after each line");
	setForegroundColor(0,0,0);
	for (i=count; i<roiManager("count"); i++) {
		roiManager("Select", i);
		run("Line to Area");
		run("Fill", "slice");
	}
	selectWindow("mask");
	run("Select All");
	run("Fill Holes");
}


function removeRois(image, count){
	selectWindow(image);
	roiManager("Show None");
	setTool("wand");
	waitForUser("click rois to be deleted, click <t> after selecting each roi");
	setForegroundColor(255,255,255);
	for (i=count; i<roiManager("count"); i++) {
		roiManager("Select", i);
		run("Fill", "slice");
	}
	
}

function updateROIs(mask, referenceImg){
	 selectWindow(mask);
	 run("Select All");
	 roiManager("reset");
	 run("Analyze Particles...", "add");
	 selectWindow(mask);
	 roiManager("Show None");
	 selectWindow(referenceImg);
	 roiManager("Show All without labels");
}


/////////////////////////////en principio no es muy práctca ya veremos

function showROIs(title) {
	selectWindow(title);
	run("Select All");
	run("Duplicate...", "title=corrResult");
	run("RGB Color");
	roiManager("deselect");
	setForegroundColor(0, 255, 255);
	roiManager("Draw");
}
