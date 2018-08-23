function [logP, accumImg, accumPars, pAlphas, pTrans]=rsOneImgOneRef6(fUnrotImgs,logProbWC,a,sigmaN, ref)
% function [logP, accumImg, accumPars, pAlphas, pTrans]=rsOneImgOneRef6(fUnrotImgs,logProbWC,a,sigmaN, ref)
% Inputs:
%   fUnrotImgs: n x n x nAlphas stack of FT rotated images
%   logProbWC:  n x n x nAlphas stack of prior probability of w and click error
%   a:          scalar amplitude of this image
%   sigmaN:     scalar noise s.d.
%   ref:        n x n image
% Outputs:
%   logP:       scalar log(P(X | alpha, ref))
%   accumImg:   E{T o R o Img}_trans,alpha for forming class mean
%   accumPars:  E{accums)_X, alpha, ref, where
%         accums(1) = sigmaN estimate
%         accums(2) = re-est a
%         accums(3) = re-est sigmaC
%         accums(4) = re-est y-shift
%   pAlphas:    p(alpha|ref,X)  nAlphas
%   pTrans:     n x n x nAlphas p(trans | X, alpha, ref)

R2=ref(:)'*ref(:);
cfRef=conj(fftn(ref));

[n, n1, nAlphas]=size(fUnrotImgs);
nn=n*n1;

n0=-ceil((n-1)/2);
[x, y]=ndgrid(n0:n0+n-1);
r2=x.^2+y.^2;

if nargout>4
    pTrans=single(zeros(n,n,nAlphas));
end;
logProbAlpha=zeros(nAlphas,1);
fAccumImgs=zeros(nn,nAlphas);
accumsAlpha=zeros(5,nAlphas);  % [accumVarN, accumCC accumVarC, accumB, accumVarB, accumVarR]
for i=1:nAlphas
    %        Get img * ref
    uimg=fUnrotImgs(:,:,i);
    ccIR=real(fftshift(ifftn(uimg.*cfRef)));  % cross correlation    
    I2=uimg(:)'*uimg(:)/n^2;
    %         Get (I-aR)^2 as a function of w
    diffIR=(I2+a^2*R2-2*a*ccIR);%-ns*ns*log(sqrt(2*pi)*SigmaN)
    %         Get log(P(I|w,alpha,...))
    logProbI=-n^2*log(sigmaN)-diffIR/(2*sigmaN^2);
    %         Add in log(C|Z)
    logProbX=logProbI+logProbWC(:,:,i);  %P(X|t,ref)*P(t|ref)=P(X,t|ref)
    %         Avoiding underflow, sum over translations and normalize
    mxLogProbX=max(logProbX(:));
    sclProbX=exp(logProbX(:)-mxLogProbX);
    norm=sum(sclProbX(:));
    normProbX=sclProbX/norm; % P(X,t|ref)/P(X|ref)=P(t|X,alpha,ref)
    logProbAlpha(i)=mxLogProbX-log(norm); % sum_t(P(X,t|alpha,ref)=P(X|alpha,ref)
    %                                   =P(X,alpha|ref)/P(alpha)
    accumsAlpha(1:4,i)=normProbX(:)'*[diffIR(:)/n^2 ccIR(:)/R2 r2(:)/2 y(:)];
    %                                   =sum_t(P(t|X,alpha,ref)*accums)
    %                                   y is the y-coordinate for bobbing
    fAliImg=uimg.*conj(fftn(ifftshift(reshape(normProbX,n,n)))); % weighted and shifted image
    fAccumImgs(:,i)=fAliImg(:);
    
    pTrans(:,:,i)=reshape(normProbX,n,n);  % P(t|X,alpha,ref)
    % to get p(t|X):
    % (6) P(alpha,ref|X)=P(X,alpha,ref)/sum_alpha,ref(P(X, alpha,ref))
    % (7) P(t,alpha,ref|X)=P(t|X,alpha,ref)*P(alpha,ref|X)
    % (8) p(t|X)=sum_alpha,ref(P(t,alpha,ref|x))
end; % for iAlpha

mxLogProbAlpha=max(logProbAlpha);
sclProbAlpha=exp(logProbAlpha-mxLogProbAlpha);
norm=sum(sclProbAlpha); % =const * sum_alpha(P(X,alpha|ref))=P(X|ref)
% to get P(ref|X), (1) P(X,ref)=P(ref)*P(X|ref);  for now assume p(ref) = const
%                  (2) P(ref|X)=P(X,ref)/sum_ref(P(X,ref)
logP=mxLogProbAlpha+log(norm);  % log P(X|ref)
% to get P(alpha|X), (3) P(X,alpha,ref)=P(alpha|X,ref)/P(X,ref) from (1)
%                    (4) P(X,alpha)=sum_ref(P(X,alpha,ref))
%                    (5) P(alpha|X)=P(X,alpha)/sum_alpha(P(X,alpha))
pAlphas=sclProbAlpha/norm; % = P(X,alpha|ref)/P(X|ref)=P(alpha|X,ref)

accumImg=real(ifftn(reshape(fAccumImgs*pAlphas,n,n)));
accumPars=accumsAlpha*pAlphas;  % =sum_t,alpha(P(alpha|X,ref)*P(t|X,alpha,ref)*accums)
%                                   =sum_t,alpha(P(t,alpha|X,ref)*accums)
%                                 = E{accums}_X,ref
