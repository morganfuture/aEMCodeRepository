function mi=ReadMiText(filename,endName)
% Read a text file generated by WriteStructText or WriteMiText.
% If given, endName is the name of a root-level field after which reading is truncated.
% Comments can be added at the end of any line.  Blank lines or comments
% can be inserted anywhere, I think.  Beware of changing the number
% of fields
% in arrays or structs: you must update the size spec or get fatal errors.

iquant=4;
commentMarkers={'%' '!' '#'};
doubleFields={'identifier'};

if nargin<2
    endName=char(26); % by default, control-Z terminates reading
end;

% Pick up the contents of the file
f=fopen(filename);
j=0;
A=cell(0);
while ~feof(f)
    line=fgetl(f);
    while (~isa(line,'char') || numel(strtrim(line))<1) && ~feof(f)
        line=fgetl(f);
    end;
    if isa(line,'char')
        j=j+1;
        A{j}=line;
    end;
end;
fclose(f);
nLines=j;
P=0;  % pointer is set before the current line

% Assign values to the structure
mi=struct;
ok=true;
while ok
    [val,name,ok]=ReadField(0);
    if ok && numel(name)>0
        mi.(name)=val;
    end;
    ok=ok && ~strcmp(name,endName);
end;

    function [val,name,ok]=ReadField(level)
        %         try
        val=[];
        name=[];
        [line,ok]=GetLine;
        if ~ok
            return
        end;
        [name,rline]=strtok(line);
        %     Now see if we are doing direct evaluation or not.
        [op,sline]=strtok(rline);
        if numel(name)<1 || numel(op)<1  % skip lines with no operators.
            return
        end;
        switch op(1)
            case '='  % direct evaluation
                %                 Check if numeric, but first trim a trailing 'd'
                nline=deblank(sline);  % numeric line text
                if numel(nline)>1 && nline(end)=='d'  % end is marked with a d
                    val=(str2num(nline(1:end-1)));     % value is a double
                elseif any(strcmp(name,doubleFields))      % old special case: mi.identifier is a double.
                    val=str2num(nline);
                else
                    val=single(str2num(nline));
                end;
                %                 switch name
                %                     case 'identifier'  % special case for double value
                %                         %                         leave as double
                %                     otherwise
                %                         val=single(val);
                %                 end;
                
                if numel(val)<1  % no numeric value found
                    val=strtrim(sline(2:end));
                    if strcmp(val,'[]')  % does it mark an empty field?
                        val=zeros(0,0,'single');
                    end;
                end;
                return
            case '['  % size of an array
                [sz,cls,subCls,nf,transpose]=ReadSize(strtrim(rline));
                %                 strip colons
                %                 P currently points to the array name header
                if numel(cls)==0  % numeric has no case
                    if transpose % special case, we wrote the transpose
                        val=ReadNumericArray(flip(sz))';
                    else
                        val=ReadNumericArray(sz);
                    end;
                else
                    switch cls  % what kind of array is this?
                        case 'hex'
                            val=ReadHexArray(sz);
                        case 'struct'
                            val=ReadStructArray(level,sz,nf);
                        case 'cell'
                            val=ReadCellArray(level,subCls,sz);
                        otherwise
                            error(['Unrecognized class: ' cls]);
                    end;
                end;
        end;
        %         catch
        %             error(sprintf('Read error at line %d: %s',P,A{P}'));
        %         end;
    end

    function val=ReadCellArray(level,cls,sz)
        cls=strtrim(cls);
        ne=prod(sz);
        if numel(cls)==0
            cls='char';
        end;
        val=cell(ne,1);
        switch cls
            case 'char'  % we just read strings
                ne=prod(sz);
                for i=1:ne
                    val{i}=strtrim(GetLine);
                end;
            case {'single' 'double'}
                for i=1:ne
                    %                     element names have the same level
                    [val{i},name,ok]=ReadField(level);
                    if ~ok
                        error('Missing elements of cell array');
                    end;
                end;
            otherwise
                error(['Unrecognized cell element class: ' cls]);
        end;
        if ne>0
            val=reshape(val,sz);
        else
            val={};
        end;
    end

    function val=ReadStructArray(level,sz,nf)
        %         P points to the name-header line; level is its indentation level
        ne=prod(sz);
        if ne>1  % an actual array
            val=struct;
            for i=1:ne
                line=GetLine;
                %                 level=GetLevel(line);  % get its indentation level
                if i==1
                    val=ReadStructArray(level,1,nf);
                else
                    val(i,1)=ReadStructArray(level,1,nf);
                end;
            end;
        else
            ok=true;
            val=struct;
            line=GetLine;
            [flag,sline]=strtok(line);
            if strcmp(flag,'>>') % this is a header line, read as column
                val=ReadColFields(val,sline);
                nfc=numel(fieldnames(val));  % no. of fields read as columns
            else
                P=P-1;  % back up
                nfc=0;
            end;
            %         Are there more fields to read?
            for i=1:nf-nfc
                [x,fname,ok]=ReadField(level);
                if ok
                    val.(fname)=x;
                else
                    error(['missing field in:' A{P}]);
                end;
            end;
        end;
    end

    function val=ReadColFields(val,header)
        % decode the header and create fields, then read them
        ok=true;
        names=cell(0);
        sizes=zeros(0,2);
        nf=0;
        [nm,rest]=strtok(header);  % pick up the name
        [ss,rest]=strtok(rest);  % pick up the size
        ok=numel(ss)>0;
        while ok
            nf=nf+1;
            names{nf}=nm;
            sizes(nf,:)=ReadSize(ss);
            [nm,rest]=strtok(rest);  % pick up the name
            [ss,rest]=strtok(rest);  % pick up the size
            ok=numel(ss)>0;
        end;
        
        %          Create the fields
        %         for i=1:nf
        %             val.(names{i})=zeros(sizes(i,:),'single');
        %         end;
        nRows=sizes(1,1);
        nCols=sum(sizes(:,2));
        z=zeros(nRows,nCols,'single');  % big array to receive data
        for j=1:nRows
            rRow=GetLine;
            [indStr,rest]=strtok(rRow);
            ind=sscanf(indStr,'%f:');
            if ind ~=j
                error('out of order index');
            end;
            z(j,:)=sscanf(rest,'%f')';
            iRow=GetLine;
            [op,rest]=strtok(iRow);
            if strcmp(op,'+i') % imaginary part
                for i=1:nCols
                    [num,rest]=strtok(rest);
                    x=sscanf(num,'%f');
                    if numel(x)>0
                        z(j,i)=z(j,i)+1i*x;
                    end;
                end;
            else
                P=P-1;
                
            end;
        end;
        widths=sizes(:,2);
        ends=cumsum(widths);
        starts=ends-widths+1;
        for i=1:nf
            val.(names{i})=z(:,starts(i):ends(i));
        end;
    end

%         function [x,index]=ReadNumericRow(isImag)
%             IncP;
%             line=A{P};
%             %             Ignore the first field if it's an index number
%             [tok,rest]=strtok(line);
%             if tok(end)==':'  % an index entry
%                 index=sscanf(tok,'%f:');
%                 line=rest;
%             else
%                 index=0;
%             end;
%             if isImag
%                 x=single(sscanf(line,'%fi'));
%             else
%                 x=single(sscanf(line,'%f'));
%             end;
%         end


    function val=ReadNumericArray(sz)
        %             disp('Read Numeric');
        %             disp(A{P});
        ntot=prod(sz);  % total elements
        val=zeros(ntot,1,'single');
        nr=0;
        while nr<ntot
            [line,ok2]=GetLine;
            if ~ok2
                return
            end;
            %             Ignore the first field if it's an index number
            [tok,rest]=strtok(line);
            
            if tok(end)==':'  % an index entry
                line=rest;
            end;
            [x,nx]=sscanf(line,'%f');
            %                 Check for an imaginary part
            iRow=GetLine;
            [tok,rest]=strtok(iRow);
            if strcmp(tok,'+i') % imaginary part
                xi=sscanf(rest,'%f');
                if numel(xi)>0
                    x=x+1i*xi;
                end;
            else
                P=P-1;  % back up one line.
            end;
            val(nr+1:nr+nx)=x;
            nr=nr+nx;
        end; % while
        val=reshape(val,sz);
    end

    function val=ReadHexArray(sz)
        ntot=prod(sz);  % total elements
        val=zeros(ntot,1,'uint8');
        nr=0;
        while nr<ntot
            %             line=strtok(GetLine);  % skip whitespace
            line=strtrim(GetLine);  % skip whitespace
            nchars=numel(line);
            nx=nchars/2;  % better be even, or get error.
            x=uint8(hex2dec(reshape(line,2,nx)'));
            val(nr+1:nr+nx)=x;
            nr=nr+nx;
        end;
        val=reshape(val,sz);
    end

    function level=GetLevel(line)  % count spaces at the beginning
        p=regexp(line,'\S');
        if numel(p)>0
            level=round((p(1)-1)/iquant);
        else
            error('Blank line');
        end;
    end

    function [sz,cls,subCls,nFields,transpose]=ReadSize(str)
        %         Read a string such as '[1x2] cell:' or '[1x2;2] struct:'
        %         or '[2]:', etc. with or without the terminating colon.
        %       In the first case returns sz=[1 2], cls='struct', nFields=2.
        if str(1)~='['
            error(['Incorrect size entry: ' str]);
        end;
        cls='';
        subCls='';
        nFields=0;
        transpose=false;
        if strncmp(str,'[]',2)
            sz=[0 0];
            return
        end;
        cstr=strsplit(str(2:end),']');
        szStr=cstr{1};  % guaranteed to be at least one output
        [sz,~,~,ptr]=sscanf(szStr,'%fx');
        sz=sz';
        % %         handle blank fields
        %         if numel(sz)<1
        %             sz=[0 0];
        %         else  % shouldn't occur, but anyway
        %             sz=[1 sz];
        %         end;
        if ptr<numel(szStr) && szStr(ptr)==';' % found a fields size
            [nFields]=sscanf(szStr(ptr+1:end),'%f');
        end;
        %         following the ] should be the class
        if numel(cstr)>1 %  there was something following it
            rest=cstr{2};
            if numel(rest)>0 && rest(1)==''''  % check for transpose
                transpose=true;
                rest(1)=[];  % delete the character
            end;
            cCls=strsplit(rest,':'); % ignore terminating :
            [cls,subCls]=strtok(cCls{1});
            subCls=strtrim(subCls);
        end;
        %
        %         send=strfind(str,']');
        %         if numel(send)<1
        %             error(str);
        %         end;
        %         sz=sscanf(str(2:send-1),'%fx')';
        %         cls=strtok(str(send+1:end));
        %         term=strfind(cls,':');
        %         if numel(term)>1
        %             cls=cls(1:term(1)-1);
        %         end;
        
    end

%     function ok=IncP
%         P=P+1;
%         ok=(P<=nLines);
%         if nargout<1 && ~ok
%             error('End of file');
%         end;
%     end

    function [line,ok]=GetLine
        line=[];
        P=P+1;
        ok=(P<=nLines);
        if ok
            str=A{P};
            if isa(str,'char')
                p=numel(str)+1;
                for i=1:numel(commentMarkers)
                    q=strfind(str,commentMarkers{i});
                    if numel(q)>0
                        p=min(p,q(1));                       
                    end
                end;
                line=str(1:p-1);
            end;
            %             %             strsplit seems to be very slow...
            %             if isa(A{P},'char')
            %                 cline=strsplit(A{P},commentMarkers); % discard after comments
            %                 line=cline{1};
        elseif nargout<2
%            error('End of file');
        end;
    end
    

end