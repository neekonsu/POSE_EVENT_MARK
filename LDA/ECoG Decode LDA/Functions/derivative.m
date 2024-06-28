function der = derivative(x, dt, strfilt, winlength)
if(nargin<2)
    der = [];
else
    if(nargin<3)
        strfilt = 'filt';
    end
    if(nargin<4)
        winlength = 7;
    end

    [rows columns] = size(x);

    if(columns==1)
        if(numel(x)>=7)
            der(1,1) = (x(2)-x(1))/dt;
            der(2,1) = (x(3)-x(1))/(2*dt);
            der(rows-1,1) = (x(rows)-x(rows-2))/(2*dt);
            der(rows,1) = (x(rows)-x(rows-1))/dt;
            for i=3:rows-2
                der(i,1) = (-x(i+2)+8*x(i+1)-8*x(i-1)+x(i-2))/(12*dt);
            end
        else
            der = [0; diff(x)];
        end
        if(strcmp(strfilt,'filt'))
            der = sgolayfilt(der,3,winlength);
        end
    else if(rows==1)
            if(numel(x)>=7)
                der(1,1) = (x(2)-x(1))/dt;
                der(1,2) = (x(3)-x(1))/(2*dt);
                der(1,columns-1) = (x(columns)-x(columns-2))/(2*dt);
                der(1,columns) = (x(columns)-x(columns-1))/dt;
                for i=3:columns-2
                    der(1,i) = (-x(i+2)+8*x(i+1)-8*x(i-1)+x(i-2))/(12*dt);
                end
            else
                der = [0 diff(x)];
            end
            if(strcmp(strfilt,'filt'))
                der = sgolayfilt(der,3,winlength);
            end
        else
            display('Error: matrix derivatives not allowed')
            der=-1;
        end
    end
end

