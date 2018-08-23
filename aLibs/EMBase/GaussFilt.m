function out=GaussFilt(in, fc, stack)% GaussFilt: 1D, 2D or 3D gaussian filter.% out = GaussFilt( in, fc,stack)% Filter the input matrix to give the half-power frequency fc% (in units of the sampling frequency).  Thus a 1 kHz filter on data% sampled at 10 kHz would have fc = 0.1.% A typical value of fc for an anti-aliasing filter is 0.2.% The output matrix is the same size as the input; the filter% uses ffts so the boundaries are periodic.% If stack>0 then the last dimension of in is taken to be the number of% images, which are processed separately.  These 'images' can be 1, 2 or% 3D.% The corner frequency fc is related to the standard deviation sigma of the% impulse response by the following:%           fc=.133/sigma, or equivalently, sigma=.133/fc% fc is related to a B factor (EM definition exp(-Bf^2)) according to%  fc=sqrt(log(2)/(2*B))*pixA where pixA is number of angstroms per pixel,%  and B has units of A^2.% F. Sigworth% 1D bug fixed 29 Aug 2005% Stack option added 26 Jan 08% Changed to handle complex inputs 3 Sep 09if nargin<3    stack=0;end;m=size(in);ndim=max(1,sum(m>1)); % number of non-singleton dimensionsif stack    ns=m(ndim);    ndim=ndim-1;else    ns=1;  % number of stacked imagesend;if abs(fc)<1e-9    out=in;    returnend;% The unit of frequency in the various dimensions will be% 1/m(1), 1/m(2), etc.  We want the output to be 1/sqrt(2) at fc, i.e.% at fx=fc*m units.  The output will be exp(-(x.^2/fx.^2)*ln(2)/2);k=-log(2)./(2*fc^2*m.^2);if ndim==1    n=m(1);    x=(-n/2:n/2-1)';    k=k(1);    q=exp(k*x.^2);	% Gaussian kernel    elseif ndim==2    [x,y]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1);    q=exp(k(1)*x.^2+k(2)*y.^2);	% Gaussian kernelelseif ndim==3    [x,y,z]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1, -m(3)/2:m(3)/2-1);    q=exp(k(1)*x.^2+k(2)*y.^2+k(3)*z.^2);	% Gaussian kernelelse error('GaussFilt', 'Input matrix has dimension > 3');end;q=fftshift(q);if ns==1    fq=q.*fftn(in);    if isreal(in)        out=real(fftn(conj(fq)))/prod(m); % This saves memory, to use fftn instead.    else        out=fftn(conj(fq))/prod(m);    end;else    out=zeros(m);    if ndim==1        for i=1:ns            fq=q.*fft(in(:,i));            if isreal(in)                out(:,i)=real(ifft(fq));            else                out(:,i)=ifft(fq);            end;        end;    elseif ndim==2        for i=1:ns            fq=q.*fftn(in(:,:,i));            if isreal(in)                out(:,:,i)=real(ifftn(fq));            else                out(:,:,i)=ifftn(fq);            end;        end;    elseif ndim==3        for i=1:ns            fq=q.*fftn(in(:,:,:,i));            if isreal(in)                out(:,:,:,i)=real(ifftn(fq));            else                out(:,:,:,i)=ifftn(fq);            end;        end;    end;    end;