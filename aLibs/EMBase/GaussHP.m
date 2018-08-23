function out=GaussHP(in, fc, stack)% function out=GaussHP(in, fc, stack)% GaussHp2: 2D gaussian highpass filter.% out = GaussHp2( in, fc)% Filter the input image to give the half-power frequency fc% (in units of the sampling frequency).  A typical value of fc% to give 2 cycles across the width n of the image is 2/n.% The output matrix is the same size as the input; the filter% uses ffts so the boundaries are periodic.if nargin<3    stack=0;end;m=size(in);ndim=sum(m>1);% ndim=ndims(in);  % number of non-singleton dimensionsif stack    ns=m(ndim);    ndim=ndim-1;else    ns=1;  % number of stacked imagesend;if fc<.01/max(size(in))  % Zero frequency: don't filter    out=in;    returnend;k=-(log(2)/2)*fc^2;if ndim==0  % a scalar    out=in;    returnend;if ndim==1    n=size(in,1);    x=(-1/2:1/n:1/2-1/n)';    if m(1)==1 % a row vector        x=x';    end;        q=exp(k./(x.^2+eps));	% Gaussian kernelelseif ndim==2    [x,y]=ndgrid(-1/2:1/m(1):1/2-1/m(1), -1/2:1/m(2):1/2-1/m(2));    q=exp(k./(x.^2+y.^2+eps));	% Gaussian kernelelseif ndim==3    [x,y,z]=ndgrid(-1/2:1/m(1):1/2-1/m(1), -1/2:1/m(2):1/2-1/m(2), -1/2:1/m(3):1/2-1/m(3));    q=exp(k./(x.^2+y.^2+z.^2+eps));	% Gaussian kernelelse error('Input matrix has dimension > 3');end;q=fftshift(q);if ns==1    fq=q.*fftn(in);    out=real(ifftn(fq));else    out=zeros(m);    if ndim==1        for i=1:ns            fq=q.*fft(in(:,i));            out(:,i)=real(ifft(fq));        end;    elseif ndim==2        for i=1:ns            fq=q.*fftn(in(:,:,i));            out(:,:,i)=real(ifftn(fq));        end;    elseif ndim==3        for i=1:ns            fq=q.*fftn(in(:,:,:,i));            out(:,:,:,i)=real(ifftn(fq));        end;    end;end;% out=q;