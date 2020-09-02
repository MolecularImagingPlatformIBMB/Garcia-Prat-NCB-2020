

WekaVersion = "Trainable Weka Segmentation v2.3.0";
Classifier01 = "classifier01.model";
Classifier02 = "classifier02.model";


//CALL ORIGEN AND DESTINATION FOLDERS
imagesFolder=getDirectory("Choose directory containing images");
classifiersFolder=getDirectory("Choose directory containing the classifiers");
resultsFolder=getDirectory("Choose directory to save results");
list=getFileList(imagesFolder);
File.makeDirectory(resultsFolder);


//CREATE LOOP TO ANALYZE ALL IMAGES
for(i=0; i<list.length; i++){
	showProgress(i+1, list.length);
	
	//OPEN IMAGE i FROM IMAGES FOLDER
	open(imagesFolder+list[i]);
	
	//PREPARE IMAGES
	//Retrieve image name 
	rawName = getTitle();
	name = File.nameWithoutExtension;
	rename(name);
	getPixelSize(unit, pixelWidth, pixelHeight);
	run("Properties...", "channels=2 slices=1 frames=1 unit=µm pixel_width=1.0000000 pixel_height=1.0000000 voxel_depth=0.0000000");
	getChannels(name);
	selectWindow(name);
	run("Close");
	
	
	//SEGMENT MUSCLE using WEKA and previously determined classifiers
	//Round one
	selectWindow("gfp");
	run("Trainable Weka Segmentation");
	wait(500);
	call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifiersFolder+File.separator+Classifier01);
	call("trainableSegmentation.Weka_Segmentation.getProbability");
	rename("Probability01");
	selectWindow(WekaVersion);
	close();
	//Round two
	selectWindow("Probability01");
	run("Trainable Weka Segmentation");
	wait(500);
	call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifiersFolder+File.separator+Classifier02);
	call("trainableSegmentation.Weka_Segmentation.getProbability");
	rename("Probability02");
	selectWindow("Probability01");
	run("Close");
	selectWindow(WekaVersion);
	close();

	//SAVE IMAGES & CLOSE WINDOWS
	selectWindow("Probability02");
	saveAs("TIFF", resultsFolder+name+"_ProbabilityMap.tif");
	run("Close");
	selectWindow("gfp");
	run("Close");
	
}
	

////////// FUNCTIONS

function getChannels(title){
	selectWindow(title);
	run("Duplicate...", "title=copy duplicate");
	run("Split Channels");
	selectWindow("C1-copy");
	//run("Median...", "radius=2");
	run("Grays");
	rename("gfp");
	selectWindow("C2-copy");
	run("Close");
}
