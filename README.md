 /$$$$$$            /$$$$$$   /$$$$$$ 
|_  $$_/           /$$__  $$ /$$__  $$
  | $$   /$$$$$$$ | $$  \__/| $$  \ $$
  | $$  | $$__  $$| $$      | $$$$$$$$
  | $$  | $$  \ $$| $$      | $$__  $$
  | $$  | $$  | $$| $$    $$| $$  | $$
 /$$$$$$| $$  | $$|  $$$$$$/| $$  | $$
|______/|__/  |__/ \______/ |__/  |__/

---Installation Notes---
* This application was designed with R2020a
* Performance and compatibility with older versions is not guaranteed however core aspects of the program should continue to function. Please refer to official MATLAB 
  documentation for features that have changed between your version and R2020a
* There are two installation options: A universal installation using the .mlapp MATLAB App file and a Windows only .exe. As of now the universal installation option is
  recommended. Equivalent executables for Mac and Linux are being considered for development. 

---MATLAB App Installation--- 
* Supported Platforms: Windows, Mac, Linux
* Required toolboxes:
  - Image Processing Toolbox
  - Curve Fitting Toolbox 
  - Parallel Computing Toolbox

* In order to install and run this application download InCA.zip and unzip the folder in your preferred directory. Make sure the folder heirarchy matches the one below.
---------------------------------------
+---- InCA.mlapp                      |
\---- main\                           |
     +---- main runtime files (.m)    |
\---- themes\                         |
     +---- theme files (.m)           |
\---- logs\                           |
     +---- logging files (.log)       |
\---- images\                         |
     +---- program icons (.png/.ico)  |
---------------------------------------

---Running the MATLAB App---
In order to properly run InCA make sure that the working path of your MATLAB instance is set to the location of the InCA.mlapp file, it is NOT necessary to add the other
folders to the working path, running InCA automatically adds them. Double clicking InCA.mlapp will open up MATLAB App Designer by default. The program can be launched with 
the green play/run button found at the top of the MATLAB App Designer window. A user manual for the current software version can be found included in the .zip file.


---Windows Only Experimental Installation---
* Supported Platforms: Windows
* Download and launch the installer. This installer installs not only the application but also MATLAB Runtime on your machine regardless of whether or not your machine already
  has MATLAB installed or not. InCA is installed and run as a .exe file.
* Logging features are currently in development for the .exe variant of InCA.


---Runtime Notes (Both Installation Methods)---
* Despite having a custom title bar icon (and launching with a custom splashscreen for the .exe installation method), InCA does not have its own task bar icon (because of MATLAB
  restrictions). 
* Videos with more frames and larger bubbles generate larger data sets so it is possible to run out of memory on certain systems. Data compression algorithms for certain sets of 
  data (particularly Fourier plotting) are being looked into.
* This application is not fool-proof, it does crash and/or freeze from time to time, data is not saved in the case of a forced shutdown of InCA.
* Data saved in the .exe version of InCA CAN be opened up in the .mlapp version and vice-versa
* Due to MATLAB restrictions the InCA window will occasionally hide/show itself when opening/saving files, do not be alarmed by this behavior. MATLAB is not designed for graphic applications

