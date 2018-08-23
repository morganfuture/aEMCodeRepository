function ok=Betafix2(C)
% function ok=Betafix2(C)
% To get an empty contingency struct, call C0=Betafix();
% Fields of contingency C
% bPrice     Betafix price
% volume     Volume of combination

if nargin<1
    C.bPrice=0;
    C.volume=0;
    ok=C;
else
    
%     50,000 at vol=1; 12,000 at 80
%     >80, 20,000 reducing to 10.5k at 500

    
    p1=50000;
    p80=12000;
    k1=1/80;
    p81=20000;
    p500=10500;
    k2=1/500;
    
    % Make a function that decays from 1 at volume=1 to 0 at volume = 80k
    if C.volume<=8e4
        f80=(exp(-k1*C.volume)-exp(-k1*8e4)) ...
            /(exp(-k1)-exp(-k1*8e4));
        minPrice=p80+f80*(p1-p80);
    else
        %     decays from 1 at volume =80k to 0 at volume = 500k
        f500=(exp(-k2*C.volume)-exp(-k2*5e5)) ...
            /exp(-k2*8e4)-exp(-k2*5e5);
        minPrice=p500+f500*(p81-p500);
    end;
    ok=C.bPrice>=minPrice && C.volume<=5e5; % not valid beyond 500k
    
end;