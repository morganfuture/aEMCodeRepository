function [coords,mxCC2,flags,vals,labels]=rspParticleChecker(amp,inCoords,mi,rscc,dis)
% Checks the values and geometry of the putative particle at (ix,iy) having
% amp=rxcc.mxCC(ix,iy)
% Returns the coords = [ ix iy flag iv amp template rsoFlag sval ampU 0  xVals  ]
%                         1  2  3    4   5    6        7      8    9  10  11-14
% where flag=0 (not found) or 32 (particle has been found).
% 
% Returns calculated values and corresponding flags; if all(flags), a particle is marked as auto-picked.
% The elements of vals and flags are identified by text in labels.
np=5;
patchCtr=ceil((np+1)/2);
patchMask=logical(fuzzymask(np,2,np/2,0));
zeroCC=1e-3;
pars=dis.pars;
% pars(12) is tFactor, the factor modifying the amplitude threshold
% minAmp=max(1e-6,pars(1)+dis.defSlope*(mi.ctf(1).defocus-2))*pars(12);
minAmp=pars(1);
% maxAmp=pars(2)*pars(12);
maxAmp=pars(2)*pars(12);
maxVar=pars(3);
rsoOffset=pars(4)/mi.pixA;  % offset of particle center from tip (for RSO selection)
partRadius=pars(5)/mi.pixA; % blanking radius around particle, in A
% overlapRadius=pars(6); % "forbidden zone" for overlap around each vesicle
maxBob=pars(7)/mi.pixA; % maximum distance of particle center outside the vesicle.
border=pars(8)/mi.pixA;   % border in A
% Get the spectrum threshold (max value)
% pars(11) is tFactor, the defocus-dependent factor modifying the spectrum
% threshold.
% sThresh=pars(10)*pars(11);  % threshold * threshFactor.
sThresh=pars(10);  % threshold

n0=mi.imageSize;
n=size(rscc.mxCC);
ds1=n0(1)/n(1);  % downsampling of micrograph to our images 

coords=inCoords;
coords(1,14)=0; % expand the size.
flags=false(1,9);
vals=zeros(1,9,'single');
labels={ 'minAmp';   'noBlank'; 'maxAmp'; 'maxVar';  'Vesicle';
    'rsoOffs'; 'maxBob'; 'border'; 'spectrum'};

mxCC2=rscc.mxCC2;

flags(1)=amp>minAmp;
vals(1)=amp;
% if ~flags(1)
%     return
% end;
% convert micrograph to local coords
localXY=min(n,max(1,round(inCoords/ds1+1)));

patch=ExtractImage(rscc.mxCC2,localXY,np); % Copy the neighborhood
flags(2)=all(patch(patchMask)>zeroCC); % no neighborhood points are blanked    iv=rscc.mxVesInds(ix,iy);
vals(2)=flags(2);  % 1 or 0
%     if flags(2)
ccVar=rscc.mxVars(localXY(1),localXY(2));
flags(3)= amp<maxAmp;
vals(3)=amp;
flags(4)=ccVar<maxVar;
vals(4)=ccVar;
%         if flags(3) && flags(4)
% [~, xi, yi]=max2di(rscc.mxCC2);  % get the interpolated values
[~, xi, yi]=max2di(patch);  % get the interpolated values
partCtr=([xi yi]-patchCtr+localXY-1)*ds1;
% ix=min(n(1),max(1,round(xi)));
% iy=min(n(2),max(1,round(yi)));
ix=localXY(1);
iy=localXY(2);

ampU=rscc.mxCCU(ix,iy);  % un-normalized amplitude, goes into coords(9)
templ=single(rscc.mxTemplInds(ix,iy));
rso=single(rscc.mxRsos(ix,iy));
% ixy=[ix iy];
iv=single(rscc.mxVesInds(ix,iy));
coords(1:9)=[partCtr   0  iv amp templ rso  0  ampU];
%                          1  2  flag  4  5    6    7  sval  9
%             flags(5)= ~dis.spMode && iv>0; % There is a matching vesicle.
flags(5)= iv>0; % There is a matching vesicle.
vals(5)=iv;
if flags(5)
    vesCtr=[mi.vesicle.x(iv) mi.vesicle.y(iv)];
    vesR=mi.vesicle.r(iv);
    rPart=sqrt(sum((partCtr-vesCtr).^2)); % distance of particle to ves ctr
    %             Geometry check:
    %               -particle center is beyond r-rsoOffset, or else rsoOffset=0
    %               -particle center is within r+maxBob
    %               -particle center is beyond the border
    flags(6)= rsoOffset==0 || rPart > vesR-rsoOffset;
    vals(6)=rPart;
    flags(7)= rPart <= vesR+maxBob;
    vals(7)=vesR;
else
%     We insert the alpha value into the rso variable.
    angList=rscc.angleList;
    angSz=size(angList);
    angList=reshape(angList,prod(angSz(1:3)),angSz(4));
    alpha=round(angList(max(1,templ),1)); % round to 1 degree
    if alpha>180
        alpha=alpha-360;
    end;
    coords(7)=alpha;
end;
distFromEdge= min(n0/2 - abs(n0/2 - partCtr));
flags(8)=distFromEdge>border;
vals(8)=distFromEdge;
if all(flags(2:4))
    %                     Check the residual spectrum value before inserting
    %                     the pick.
    [sval,xvals]=rspResidualSpectrum(mi,rscc,dis,partCtr,0);
    coords(8)=sval;
    coords(11:10+numel(xvals))=xvals;
    flags(9)=sval<=sThresh;
    vals(9)=sval;
    coords(3)=32;  % valid particle
end;

nb=2*ceil(partRadius/ds1)+4;  % size of the blanking mask box
blankMask=1-fuzzymask(nb,2,partRadius/ds1,1);
mxCC2=Mask(rscc.mxCC2,[ix iy],blankMask);

%                         nFound=nFound+1;
%                         put all the parameters into a row of the coords
%                         coords(1,10+numel(xvals))=0; % force the array bigger
%                         coords(1,:)=[ partCtr 32 single(iv) amp templ ...
%                                            rso sval ampU 0 xvals];
% %                                           1 2     3    4        5    6
% %                                           7    8    9  10  +
%              elseif dis.spMode
%                 templ=single(rscc.mxTemplInds(ix,iy));
%                 alpha=round(angList(max(1,templ),1)); % round to 1 degree
%                 if alpha>180
%                     alpha=alpha-360;
%                 end;

