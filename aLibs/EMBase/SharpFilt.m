function [out,h]=SharpFilt(in, fc, deltaf, stack)
% function out=SharpFilt(in, fc, deltaf, stack)
%        [out,h]=SharpFilt(in,fc,deltaf, stack)
%	SharpFilt: 1D, 2D or 3D Fourier filter.
% Filter the input array or stack to give the half-power frequency fc
% (in units of the sampling frequency).
% The output array is the same size as the input; the filter
% uses ffts so the boundaries are periodic.  The input array need not be
% square or a cube. The optional argument deltaf is the
% width of the filter transition region, in the same units as fc.
% If deltaf=0, this is a conventional sharp filter.  If stack=1, the 3D
% array is interpreted as a stack of 2D images.
% The optional output h is the Fourier kernel; q(1,1,1) corresponds to zero
% frequency.
if nargin<3
    deltaf=0;
end;
if nargin<4
    stack=0;
end;
realInput=isreal(in);
m=size(in);
dims=numel(m); % number of dimensions

if any(m==1)  % Check if we have a 1D vector
    dims=1;
    in=in(:);
    m=m(m>1);
end;

if stack
    nim=m(dims);
    m=m(1:dims-1);
    dims=dims-1;
else
    nim=1;
end;

% the unit of frequency in the x direction will be
% 1/m(1), etc.  We want the output to be zero at fc, i.e.
% at fx=fc*m(1) units.

k=1./(fc^2*m.^2);

switch dims
    case 1
        x=(-m(1)/2:m(1)/2-1)';
        if deltaf<=0
            h=(k*x.^2)<1;
        else
            r=sqrt(k*x.^2);
            w=deltaf/fc;
            h=0.5*(1-erf((r-1)/w));
        end;
        h=ifftshift(h);
        
        out=zeros(size(in));  % allocate the output array
        for i=1:nim
            fq=h.*fft(in(:,i));
            %     out(:,:,i)=real(fftn(conj(fq)))/prod(m); % This saves memory, to use fftn instead.
            if realInput
                out(:,i)=real(ifft(fq));
            else
                out(:,i)=ifft(fq);
            end;
        end;
        
        
    case 2
        
        [x,y]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1);
        if deltaf<=0
            h=(k(1)*x.^2+k(2)*y.^2)<1;
        else
            r=sqrt(k(1)*x.^2+k(2)*y.^2);
            w=deltaf/fc;
            h=0.5*(1-erf((r-1)/w));
        end;
        h=ifftshift(h);  % shift the FT to the origin
        
        out=zeros(size(in));  % allocate the output array
        for i=1:nim
            fq=h.*fftn(in(:,:,i));
            if realInput
                out(:,:,i)=real(ifftn(fq));
            else
                out(:,:,i)=ifftn(fq);
            end;        
        end;
        
    case 3
        
        % 3D case
        [x,y,z]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1, -m(3)/2:m(3)/2-1);
        if deltaf<=0
            h=(k(1)*x.^2+k(2)*y.^2+k(3)*z.^2)<1; % totally sharp filter
        else
            r=sqrt(k(1)*x.^2+k(2)*y.^2+k(3)*z.^2);
            w=deltaf/fc;
            h=0.5*(1-erf((r-1)/w));  % error function of radius
        end;
        h=ifftshift(h);
        out=zeros(size(in));  % allocate the output array
        for i=1:nim
            fq=h.*fftn(in(:,:,:,i));
            if realInput
                out(:,:,:,i)=real(ifftn(fq));
            else
                out(:,:,:,i)=ifftn(fq);
            end;        
        end;
    otherwise
        error('SharpFilt: can operate on 1D, 2D or 3D data only.');
end;

