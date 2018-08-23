% Automatic vesicle picker.
% Asks for the location of an mi file, assumed to be in
%   --basePath-- Info/    (assuming mi.infoPath = 'Info/')
%  and then finds a merged image in
%   --basePath-- Merge/   (assuming that mi.procPath = 'Merge/')


sHP=.01;  % highpass frequency in downsampled pix^-1

fileSuffix1='mc.mrc';
fileSuffix1='m.jpg';

%     [fname inPath]=uigetfile('*mi.mat','Select an mi file');
fname='004_sq02_1_04mi.mat';
inPath='/Volumes/TetraData/EMWork/Hideki/120711/AMPA_R_dialyzed_centrifuged_sampleA/Info/';
cd(inPath)
load(fname);

% end;

%%
basePath = '../';
iname1=[basePath mi.procPath mi.baseFilename fileSuffix1];
iname2=[basePath mi.procPath mi.baseFilename 'm.mrc'];
if FileExists(iname1)
    m=single(ReadEMFile(iname1));
    iname=iname1;
elseif FileExists(iname2)
    m=single(ReadEMFile(iname2));
    iname=iname2;
else
    error(['Can''t find merged image in this directory: ' pwd mi.procPath]);
end;

outName=[mi.basePath mi.procPath mi.baseFilename 'mv'];
m=m-mean(m(:));

displayOn=1;
rExponent=0;

%%%%%%%
% mi.pixA=2.9;
% mi.imageSize=[4096 4096];


% membrane model
vLipid=1.6;
thk=60;
rise=6;
% Create the model, which is sampled in units of the original pixel size.
nm0=ceil(30/mi.pixA)*2+1;  % array for vesicle model; 60A nominal
mi.vesicleModel=fuzzymask(nm0,1,thk/mi.pixA/2,rise/mi.pixA)...
    *vLipid*mi.pixA;  % units of V.A per voxel


% Get image and pixel sizes
n=size(m,1);
ds0=mi.imageSize(1)/n;  % downsampling factor of m
pixA0=mi.pixA*ds0;    % pixel size of m

% m=Crop(m,1024);
% n=1024;

% downsample to about 10A per pixel, yielding the image ms
targetPixA=12;  % maximum pixel size
ns=NextNiceNumber(n*pixA0/targetPixA,5,4);  % multiple of 4, max factor 5.

highPass=exp(-sHP^2./(max(RadiusNorm(ns),1e-6).^2));  % zero-center highpass function


ms=Downsample(m,ns,0,highPass);
fms=fftn(ms);
ds=ds0*n/ns;  % downsampling factor of ms relative to original images.
pixA=ds*mi.pixA;  %pixA in the image ms.
nm=ceil((nm0-1)/ds+1);
vm=Interpolate1(mi.vesicleModel,nm,1/ds)*ds;  % downsampled vesicle model
% note that the density is scaled up to match the scattering per voxel.
mbnThickness=thk/pixA;


rmin=80/pixA; % minimum liposome radius in pixels
rmax=500/pixA; % maximum liposome radius
rstep=10/pixA; % radius step
nbin=2;  % binning of image for display
% mbnPhase2=2*1.2e-3;  % radians per A x 2 for phase contrast
% voltPhase2=.73e-3; % radians per V*A x 2 for phase contrast

figure(1);
SetGrayscale;
subplot(2,3,1);
imacs(ms);

sHP=.01;


% Get the effective CTF from the merging.
H=ifftshift(highPass.*meGetEffectiveCTF(mi,ns,ds));

%%
disp('Constructing references...');

nrsteps=round((rmax-rmin)/rstep+1);
%
rrefs=single(zeros(ns,ns,nrsteps));
frefs=single(zeros(ns,ns,nrsteps));
rads=zeros(nrsteps,1);
powers=zeros(nrsteps,1);

subplot(2,3,2);
nd=NextNiceNumber(3*rmax);  % size of box to display
nd=min(nd,ns);

for i=1:nrsteps
    r=rmin+(i-1)*rstep;  % radius in pixels
    rads(i)=r;  % radius in A
    v = VesicleFromModel(ns,r,vm);
    fv=-H.*fftn(ifftshift(v));    % FT of vesicle at origin.
    frefs(:,:,i)=fv;
    
    rv=fftshift(real(ifftn(fv)));  % CTF-filtered real image of vesicle, centered
    powers(i)=rv(:)'*rv(:);
    rrefs(:,:,i)=rv;
    if displayOn
        imacs(rv);
        title(i);
        drawnow;
    end;
end;


%%
% Compute all the cross-correlations, using a weight of r^rExponent to equalize
% the CC peak values
disp('Computing cross-correlations');
ccs=single(zeros(ns,ns,nrsteps));
% cc values are scaled by 1/r^rExponent to make small vesicles as easily found
for i=1:nrsteps
    ccs(:,:,i)=rads(i).^(-rExponent)/powers(i)*...
        real(ifftn(fms.*conj(frefs(:,:,i))));
end;
% ccs=ccs-min(ccs(:));  % min value is zero.
[ccmx ccmi]=max(ccs,[],3);
subplot(2,3,2);
imacs(ccmx);

% subplot(1,2,1);
% imacs(ccmx);
% subplot(1,2,2);
% imacs(ms);
drawnow;

ccMask=single(ones(ns,ns));



%%
disp('Finding vesicles');

eMask=meGetMask(mi,size(ccmx));

subplot(2,3,2);
imacs(ccmx.*eMask);

% ccmx2=ccmx;
ccmx2=ccmx.*ccMask.*eMask;
msub=ms;
mi1=mi;  % working copy
coords=zeros(2,1);
amps=zeros(2,1);
radii=zeros(2,1);
refis=zeros(2,1);
model=zeros(ns,ns);
umodel=zeros(ns,ns);


%%    % scan all the CC peaks
figure(1);
subplot(2,3,4);

nfound=0;
mi1.vesicle.x=[];
mi1.vesicle.y=[];
mi1.vesicle.r=[];
mi1.vesicle.s=[];
% find the first peak

[presentmax jx jy]=max2di(ccmx2);
[interpmax rind]=max1di(ccs(round(jx),round(jy),:));

maxfract=0.5;  % Minimum CC value accepted, relative to the global max
globalmax=presentmax;
thresh=globalmax*maxfract;

%     thresh=0.28

%
while presentmax>thresh
    nfound=nfound+1;
    mi1.vesicle.x(nfound)=(jx-1)*ds+1;
    mi1.vesicle.y(nfound)=(jy-1)*ds+1;
    
    % find out which reference gave rise to the maximum
    refi=ccmi(round(jx),round(jy));
    
    % Get the interpolated radius
    [mxv refii]=max1di(ccs(round(jx),round(jy),:));  % interpolated reference index
    refri=rmin+(refii-1)*rstep;  % interpolated radius in pixels
    mi1.vesicle.r(nfound)=refri*ds;
    
    ampi=presentmax*rads(refi)^rExponent; % undo the we ighting by r^-2 in the CC
    mi1.vesicle.s(nfound)=ampi;
    
    % get the approximate fit
    vref=ampi*circshift(rrefs(:,:,refi),round([jx jy]-ns/2-1));
    umodel=umodel+vref;  % approximate model
    msub=ms-umodel;
    % Blank the region in the cross-correlation
    blank=fuzzymask(ns,2,refri+mbnThickness/2,mbnThickness,[jx jy]);
    ccmx2=ccmx2.*(1-blank);
    if mod(nfound,10)==0
        imacs(msub);
        title(nfound);
        drawnow;
    end;
    
    [presentmax jx jy]=max2di(ccmx2);
end;
figure(1);
subplot(2,3,4); imacs(msub);
title(nfound);
%     subplot(2,3,3); imacs(ccmx);
subplot(2,3,2); imacs(umodel);
subplot(2,3,6); imacs(ccmx2);

subplot(2,3,3);
plot(mi.vesicle.r*mi.pixA,mi.vesicle.s,'k.');
xlabel('Vesicle radius, �');
ylabel('Image amplitude');
drawnow;
% %%
% % Create new vesicle model
% model=zeros(ns,ns);
% for i=1:nfound
%     model=model+amps(i)*VesicleDensity(ns,radii(i),mbnThickness,coords(:,i)+1);
% end;
% subplot(2,3,2); imacs(-model);

mi=mi1;
%     save(fname,'mi');
%     disp([fname ' saved']);

%%

disp('Final subtraction of vesicles');
vm=meMakeModelVesicles(mi,n);
mv=m-vm;
%%
figure(2);
imacs(GaussFilt(mv,.2));

figure(1);
subplot(2,3,1);
imacs(BinImage(m,4));
subplot(2,3,2);
imacs(vm);
subplot(2,3,3);
plot(mi.vesicle.r*mi.pixA,mi.vesicle.s,'k.','markersize',10);

subplot(2,3,4);
imacs(BinImage(mv,4));
title('Subtracted');
subplot(2,3,5);
hist(mi.vesicle.s,50);
xlabel('Vesicle amplitude s');
drawnow;

mi.basePath=ParsePath(inPath);  % make it the local path
bname=[mi.basePath mi.procPath mi.baseFilename];
WriteMRC(mv,ds0*mi.pixA,[bname 'mv.mrc']);
jname=[mi.basePath mi.procPath 'jpeg/' mi.baseFilename];
imwrite(uint8(imscale(rot90(mv),256,1e-3)),[jname 'mv.jpg']);

