% EMBase: basic image processing for EM.
%
% N-dimensional extensions to functions
%
% sumn
% maxn
% minn
% max2di	- Find maximum with quadratic interpolation
% max3di
%
%          ---Image display primitives---
% imac		- Image in cartesian coordinates
% imacs		- Image in cartesian coordinates, autoscaled
% imax      - Image of complex numbers, cartesian
% imacx     - Autoscaled complex image
% SetGrayscale	- Set 256-gray colormap
% SetGrayRed	- 255-gray colormap + red
% SetGrayBunt   - 256 grays plus 5 colors
% SetComplex    -256 grays plus complex numbers (use with imax, imaxs)
% 
%         ---Operations for 2D and 3D maps---
% LRotate	- 2D rotation with linear interpolation.
% MRotate	- 2D rotation with cubic interpolation.
% ERotate3      - 3D rotation through Euler angles
% shift		- 2D translation.
% symmetrize    - 2D enforce rotational symmetry.
% 
% Filtering
% GaussFilt - nD Gaussian lowpass
% GaussHP   - nD Gaussian high-pass
% SharpFilt2
% SharpFilt3
% 
% Masking
% GaussMask - nD Gaussian
% FuzzyMask - nD disc/sphereoid using error function
% Mask      - Modify regions of an image, e.g. to draw cursors
% ExtractImage - Copy regions of an image, e.g. for boxing
%
% Transformations
% ToPolar	- 2D Cartesian to Polar conversion
% ToRect	- 2D Polar to Cartesian
% LRotate	- 2D rotation with linear interpolation.
% MRotate	- 2D rotation with cubic interpolation.
% grotate (see GriddingLib) high-precision 2D rotation
% EulerMatrix - create the 3x3 rotation matrix
% ERotate3  - 3D rotation through Euler angles
% 
% shift		- 2D translation.
% symmetrize    - 2D enforce rotational symmetry.
%
% CenterOfMass  - Find 3D centroid
% fuzzydisc     - Create a disc with filtered edges.
% Mask      - Mask a small region in an image
% EWavelength       -Compute the electron wavelength
%
%
% Simplex       -Simplex minimization