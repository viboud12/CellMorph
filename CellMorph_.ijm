// This plugin identifies cell-cell boundaries in epithilial cross-sections and measures
// different morphological parameters of each identifed cell.
// Initially, the plugin was developed to measure cell size and cell shape in newly cellularized 
// Drosophila embryos, but could easily be used to measure other tissues or cell types.

// Saves an image with the identified cells and the measurements in a
// user-defined folder (line 19)

// n.b. MAKE SURE TO MODIFY THE IMAGES SCALE WITH YOUR PIXEL SIZE INFORMAITON BELOW (line 27)
// n.b. MAKE SURE TO MODIFY THE AREA AND CIRCULARITY RESTRICTIONS IMPOSED BELOW IF THE PLUGIN
// DOESN'T IDENTIFY ANY CELLS (line 136)

run("Set Measurements...", "area perimeter fit shape feret's  display redirect=None decimal=4");

raw = getImageID();
t = getTitle();

// Choosing where you want your files saved
dir2 = getDirectory("Choose Destination Directory ");

setBatchMode(true);

selectImage(raw);
run("Duplicate...", "  channels=1");
// MODIFY YOUR IMAGE'S SCALE HERE BY REPLACING THE 9.61538462 VALUE WITH THE NUMBER OF PIXELS
// IN YOUR IMAGE THAT WOULD FIT IN 1µm
run("Set Scale...", "distance=9.61538462 known=1 pixel=1 unit=µm");
viboud = getImageID();
run("Duplicate...", " ");

// Running a pseudo flat field correction to get rid of the variation in intensity across the sample
major = getImageID();
run("Duplicate...", " ");
run("Gaussian Blur...", "sigma=6");
majorBlur = getImageID();
imageCalculator("Subtract create 32-bit", majorBlur,major);
viboud2 = getImageID();

// fluorescence intensity mask
selectImage(viboud2);
run("Duplicate...", " ");
run("Invert");
run("Despeckle");
run("Median...", "radius=5");
getStatistics(area, mean, min, max, std, histogram);

favThresh = min + 0.42*(max-min);
setThreshold(favThresh, max);
run("Convert to Mask");
run("Invert");
run("Minimum...", "radius=4");
run("Invert");
run("Median...", "radius=4");

mask1 = getImageID();

// tubeness mask
selectImage(viboud2);
run("Duplicate...", " ");
viboud3 = getImageID();
run("8-bit");


run("Tubeness", "sigma=0.105 use");
run("Gaussian Blur...", "sigma=2");
getStatistics(area, mean, min, max, std, histogram);
favThresh = min + 0.5*(max-min);
setThreshold(favThresh, max);
run("Convert to Mask");
mask2 = getImageID();
rename("Tubeness");

selectImage(viboud3);
close();

// edge mask
selectImage(viboud2);
run("Duplicate...", " ");
viboud4 = getImageID();
run("8-bit");
run("Mean...", "radius=3");
run("Area filter...", "median=1 deriche=1 hysteresis_high=150 hysteresis_low=80");
run("Invert LUT");
run("Maximum...", "radius=2");
run("Median...", "radius=1");
mask3 = getImageID();
rename("Edge");
selectImage(viboud4);
close();


// combining masks
imageCalculator("Add create", mask2,mask3);
int1 = getImageID();
run("Median...", "radius=1");
run("Maximum...", "radius=1");
imageCalculator("Add create", int1,mask1);
final = getImageID();

// Closing all the image biproducts we don't need
selectImage(major);
close();
selectImage(raw);
close();
selectImage(viboud);
close();
selectImage(majorBlur);
close();
selectImage(mask1);
close();
selectImage(mask2);
close();
selectImage(mask3);
close();
selectImage(int1);
close();
selectImage(viboud2);
close();

// Resetting the ROI manager and emptying the results table
roiManager("reset"); 
run("Clear Results"); 

// Last image processing steps to smoothen the areas we're segmenting
selectImage(final);
run("Median...", "radius=1");
run("Maximum...", "radius=1");
run("Minimum...", "radius=3");
run("Median...", "radius=4");
run("Skeletonize");
run("Maximum...", "radius=1");
run("Invert");

// Identifying the cells and adding them to the ROI manager
// Change size restrictions and circularity restrictions for your given cells/images
run("Analyze Particles...", "size=10-Infinity circularity=0.60-0.90 show=Outlines display exclude add");

quantified = getImageID();
t3= t +' quantification';
saveAs("Tiff", dir2 + t3 + ".tif"); 
if (nResults==0) exit("Results table is empty");
   saveAs("Measurements", dir2 + t3 + ".xls");

selectImage(final);
close();
selectImage(quantified);
close();

setBatchMode("exit and display");